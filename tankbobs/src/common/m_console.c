/*
Copyright (C) 2008-2009 Byron James Johnson

This file is part of Tankbobs.

	Tankbobs is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	Tankbobs is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
along with Tankbobs.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <SDL/SDL.h>
#include <SDL/SDL_image.h>
#include <SDL/SDL_endian.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <luaconf.h>
#include <math.h>

#include <curses.h>
#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WINDOWS__) || defined(__WINDOWS__)
#else
#include <sys/ioctl.h>
#endif
#include <signal.h>
#include <unistd.h>

#include "common.h"
#include "m_tankbobs.h"
#include "crossdll.h"
#include "tstr.h"

static int consoleInitialized = FALSE;

#define TITLE "---[TANKBOBS CONSOLE]---"
#define PROMPT "-> "
/*#define PROMPT "Prelude> "*/
#define LOG_LINES (LINES - 4)
#define LOG_COLS (COLS - 3)
#define LOG_BUF_SIZE 65535
#define INPUT_SCROLL (COLS - 6)
#define LOG_SCROLL 5
#define MAX_LOG_LINES 1024
#define MAX_HISTORY_FIELDS 512
#define HIST_PHYSFS

static WINDOW *win_border, *win_log, *win_input, *win_scroll;
static char logbuf[LOG_BUF_SIZE];
static char *insert = logbuf;
static int scrollLine = 0;
static int lastLine = 1;

#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WINDOWS__) || defined(__WINDOWS__)
#define SCRLBAR_CURSOR ACS_BLOCK
#define SCRLBAR_LINE ACS_VLINE
#define SCRLBAR_UP ACS_UARROW
#define SCRLBAR_DOWN ACS_DARROW
#else
#define SCRLBAR_CURSOR '#'
#define SCRLBAR_LINE ACS_VLINE
#define SCRLBAR_UP ACS_HLINE
#define SCRLBAR_DOWN ACS_HLINE
#endif

#ifdef HIST_PHYSFS
#include "physfs.h"
#endif

#define MAX_EDIT_LINE BUFSIZE
static struct
{
	int  cursor;
	int  scroll;
	int  widthInChars;
	char buffer[MAX_EDIT_LINE];
} input_field;
#define CLEARFIELD(x) \
do \
{ \
	memset((x).buffer, 0, MAX_EDIT_LINE); \
	(x).cursor = (x).scroll = 0; \
} while(0)

typedef struct historyField_s historyField_t;
struct historyField_s
{
	char text[MAX_EDIT_LINE];
};

static char historyFile[FILENAME_MAX] = {""};

static historyField_t history[MAX_HISTORY_FIELDS] = {{{0}}};
static int history_pos = 0; 
static int history_nextPos = 0;

static void c_private_addHistoryField(const char *text)
{
	if(history_nextPos >= MAX_HISTORY_FIELDS)
	{
		/* Remove the oldest history field for room for more */
		history_nextPos--;

		memmove(&history[0], &history[1], sizeof(historyField_t) * MAX_HISTORY_FIELDS - 1);
	}

	/* Add the field */
	strncpy(history[history_nextPos].text, text, sizeof(history[history_nextPos].text));

	history_pos = ++history_nextPos;
}

#define c_private_prevHistoryField c_private_previousHistoryField
static const char *c_private_previousHistoryField(void)
{
	const char *s;

	if(--history_pos < 0)
		history_pos = 0;

	s = history[history_pos].text;

	return s;
}

static const char *c_private_nextHistoryField(void)
{
	const char *s;

	history_pos++;

	if(history_pos >= MAX_HISTORY_FIELDS)
	{
		history_pos = history_nextPos - 1;

		return "";
	}
	else if(history_pos > history_nextPos)
	{
		history_pos = history_nextPos;
	}

	if(history_pos < 0)
		history_pos = 0;

	s = history[history_pos].text;

	return s;
}

#define CINIT_SUCCESS 0
#define CINIT_NOTTY   1
#define CINIT_NCERR   2
static int c_private_initConsole(void)
{
	void c_private_resize(int);
	void c_private_updateCursor(void);
	void c_private_drawScrollBar(void);

	int collumn;

#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WINDOWS__) || defined(__WINDOWS__)
#else
	/* Ignore these signals so that nothing goes wrong when the process runs in the background */
	signal(SIGTTIN, SIG_IGN);
	signal(SIGTTOU, SIG_IGN);
#endif

	if(!isatty(STDIN_FILENO) || !isatty(STDOUT_FILENO) || !isatty(STDERR_FILENO))
	{
		return CINIT_NOTTY;
	}

	if(!consoleInitialized)
	{
		SCREEN *test = newterm(NULL, stdout, stdin);

		if(!test)
		{
			return CINIT_NCERR;
		}

		endwin();
		delscreen(test);
		initscr();
		cbreak();
		noecho();
		nonl();
		keypad(stdscr, TRUE);
		intrflush(stdscr, FALSE);
		nodelay(stdscr, TRUE);
		wnoutrefresh(stdscr);
	}

	/* Create the border window */
	win_border = newwin(LOG_LINES + 2, LOG_COLS + 2, 1, 0);
	box(win_border, 0, 0);
	wnoutrefresh(win_border);

	/* Create the log window */
	win_log = newpad(MAX_LOG_LINES, LOG_COLS);
	scrollok(win_log, TRUE);
	idlok(win_log, TRUE);
	getyx(win_log, lastLine, collumn);
	if(collumn)
		lastLine++;
	scrollLine = lastLine - LOG_LINES;
	if(scrollLine < 0)
		scrollLine = 0;
	pnoutrefresh(win_log, scrollLine, 0, 2, 1, LOG_LINES + 1, LOG_COLS + 1);

	/* Create the scroll bar */
	win_scroll = newwin(LOG_LINES, 1, 2, COLS - 1);
	c_private_drawScrollBar();
	mvaddch(1, COLS - 1, SCRLBAR_UP);
	mvaddch(LINES - 2, COLS - 1, SCRLBAR_DOWN);

	/* Create the input field and window */
	win_input = newwin(1, COLS - strlen(PROMPT), LINES - 1, strlen(PROMPT));
	input_field.widthInChars = COLS - strlen(PROMPT) - 1;
	if(consoleInitialized)
	{
		if(input_field.cursor < input_field.scroll)
			input_field.scroll = input_field.cursor;
		else if(input_field.cursor >= input_field.scroll + input_field.widthInChars)
			input_field.scroll = input_field.cursor - input_field.widthInChars + 1;
		wprintw(win_input, "%s", input_field.buffer + input_field.scroll);
	}
	c_private_updateCursor();
	wnoutrefresh(win_input);

	/* Draw the initial screen */
	move(0, (COLS - strlen(TITLE)) / 2);
	wprintw(stdscr, "%s", TITLE);
	move(LINES - 1, 0);
	wprintw(stdscr, "%s", PROMPT);
	wnoutrefresh(stdscr);
	doupdate();

#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WINDOWS__) || defined(__WINDOWS__)
#else
	/* Catch window resizes */
	signal(SIGWINCH, c_private_resize);
#endif

	consoleInitialized = TRUE;

	return CINIT_SUCCESS;
}

void c_private_resize(int unused)
{
#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WINDOWS__) || defined(__WINDOWS__)
#else
	struct winsize ws = {0, };

	ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws);
	if (ws.ws_col < 12 || ws.ws_row < 5)
		return;
	resizeterm(ws.ws_row + 1, ws.ws_col + 1);
	resizeterm(ws.ws_row, ws.ws_col);
	delwin(win_log);
	delwin(win_border);
	delwin(win_input);
	delwin(win_scroll);
	erase();
	wnoutrefresh(stdscr);
	c_private_initConsole();
#endif
}

void c_private_drawScrollBar(void)
{
	int scroll;

	if (lastLine <= LOG_LINES)
		scroll = 0;
	else
		scroll = scrollLine * (LOG_LINES - 1) / (lastLine - LOG_LINES);

	werase(win_scroll);
	wbkgdset(win_scroll, ' ');
	mvwaddch(win_scroll, scroll, 0, SCRLBAR_CURSOR);
	wnoutrefresh(win_scroll);
}

void c_private_updateCursor(void)
{
#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WINDOWS__) || defined(__WINDOWS__)
	/* pdcurses uses a different mechanism to move the cursor than ncurses */
	move(LINES - 1, strlen(PROMPT) + input_field.cursor - input_field.scroll);
	wnoutrefresh(stdscr);
#else
	wmove(win_input, 0, input_field.cursor - input_field.scroll);
	wnoutrefresh(win_input);
#endif
}

void c_initNL(lua_State *L)
{
}

int c_init(lua_State *L)
{
	CHECKINIT(init, L);

	switch(c_private_initConsole())
	{
		tstr *message;

		case CINIT_NOTTY:
			message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
				();
			CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
				(message, "c_init: error initializing console: not on a TTY\n");
			lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
								(message));
			CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
				(message);
			lua_error(L);

			break;

		case CINIT_NCERR:
			message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
				();
			CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
				(message, "c_init: could not initialize ncurses\n");
			lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
								(message));
			CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
				(message);
			lua_error(L);

			break;

		default:
		case CINIT_SUCCESS:
			return 0;

			break;
	}

	/* we never get here */
	return 0;
}

int c_quit(lua_State *L)
{
	CHECKINIT(init, L);

	consoleInitialized = FALSE;

	endwin();

	return 0;
}

static char tfName[BUFSIZE] = {""};

int c_input(lua_State *L)
{
	int c, numChars = 0;
	static char text[MAX_EDIT_LINE];
	tstr *prompt;

	CHECKINIT(init, L);

	for(;;)
	{
		c = getch();
		numChars++;

		switch(c)
		{
			case ERR:
				if(numChars > 1)
				{
					/* no characters left in the queue */
					werase(win_input);

					if(input_field.scroll < input_field.cursor)
					{
						input_field.scroll = input_field.cursor - INPUT_SCROLL;
						if(input_field.scroll < 0)
							input_field.scroll = 0;
					}
					else if(input_field.cursor >= input_field.scroll + input_field.widthInChars)
					{
						input_field.scroll = input_field.cursor - input_field.widthInChars + INPUT_SCROLL;
					}
					wprintw(win_input, "%s", input_field.buffer + input_field.scroll);

#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WINDOWS__) || defined(__WINDOWS__)
					/* Avoid strange cursor movement */
					wrefresh(win_input);
#else
					wnoutrefresh(win_input);
#endif
					c_private_updateCursor();
					doupdate();
				}

				lua_pushnil(L);
				return 1;

			case '\n':
			case '\r':
			case KEY_ENTER:
				if(!input_field.buffer[0])
					continue;

				c_private_addHistoryField(input_field.buffer);
				strncpy(text, input_field.buffer, sizeof(text));
				CLEARFIELD(input_field);
				werase(win_input);
				wnoutrefresh(win_input);
				c_private_updateCursor();
				/*doupdate();*/

				/* Print the text */
				prompt = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
					();
				CDLL_FUNCTION("libtstr", "tstr_set", void(*)(tstr *, const char *))
					(prompt, PROMPT);
				CDLL_FUNCTION("libtstr", "tstr_cat", void(*)(tstr *, const char *))
					(prompt, text);
				CDLL_FUNCTION("libtstr", "tstr_base_cat", void(*)(tstr *, const char *))
					(prompt, "\n");
				lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
									(prompt));
				CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
					(prompt);
				c_print(L);
				lua_pop(L, 1);

				lua_pushstring(L, text);
				return 1;

			case '\t':
			case KEY_STAB:
				if(tfName[0])
				{
					lua_getfield(L, LUA_GLOBALSINDEX, tfName);
					lua_pushstring(L, input_field.buffer);
					lua_call(L, 1, 1);
					if(lua_isstring(L, -1))
					{
						const char *newText = lua_tostring(L, -1);
						strncpy(input_field.buffer, newText, sizeof(input_field.buffer));
						input_field.cursor = strlen(input_field.buffer);
					}
				}

				continue;

			case '\f':
				c_private_resize(1337);

				continue;

			case KEY_LEFT:
				if(input_field.cursor > 0)
					input_field.cursor--;

				continue;

			case KEY_RIGHT:
				if(input_field.cursor < strlen(input_field.buffer))
					input_field.cursor++;

				continue;

			case KEY_UP:
				strncpy(input_field.buffer, c_private_previousHistoryField(), sizeof(input_field.buffer));
				input_field.cursor = strlen(input_field.buffer);

				continue;

			case KEY_DOWN:
				strncpy(input_field.buffer, c_private_nextHistoryField(), sizeof(input_field.buffer));
				input_field.cursor = strlen(input_field.buffer);

				continue;

			case KEY_HOME:
				input_field.cursor = input_field.scroll = 0;

				continue;

			case KEY_END:
				input_field.cursor = strlen(input_field.buffer);

				continue;

			case KEY_NPAGE:
				if(lastLine > scrollLine + LOG_LINES)
				{
					scrollLine += LOG_SCROLL;
					if(scrollLine + LOG_LINES > lastLine)
						scrollLine = lastLine - LOG_LINES;

					pnoutrefresh(win_log, scrollLine, 0, 2, 1, LOG_LINES + 1, LOG_COLS + 1);
					c_private_drawScrollBar();
				}

				continue;

			case KEY_PPAGE:
				if(scrollLine > 0)
				{
					scrollLine -= LOG_SCROLL;
					if(scrollLine < 0)
						scrollLine = 0;

					pnoutrefresh(win_log, scrollLine, 0, 2, 1, LOG_LINES + 1, LOG_COLS + 1);
					c_private_drawScrollBar();
				}
				continue;

			case '\b':
			case 127:
			case KEY_BACKSPACE:
				if(input_field.cursor <= 0)
					continue;

				input_field.cursor--;
				/* cursor has backed up */
			case KEY_DC:
				if(input_field.cursor < strlen(input_field.buffer))
				{
					memmove(input_field.buffer + input_field.cursor,
							input_field.buffer + input_field.cursor + 1,
							strlen(input_field.buffer) - input_field.cursor);
				}

				continue;

			default:
				if(c >= 32 && c <= 0xFF && strlen(input_field.buffer) + 1 < sizeof(input_field.buffer))
				{
					/* Normal characters */
					memmove(input_field.buffer + input_field.cursor + 1,
							input_field.buffer + input_field.cursor,
							strlen(input_field.buffer) - input_field.cursor);
					input_field.buffer[input_field.cursor++] = c;
				}

				continue;
		}
	}

	/* refresh screen */
	refresh();

	return 1;
}

int c_setTabFunction(lua_State *L)
{
	CHECKINIT(init, L);

	strncpy(tfName, luaL_checkstring(L, 1), sizeof(tfName));

	return 0;
}

int c_print(lua_State *L)
{
	int collumn;
	int scroll = ((lastLine > scrollLine && lastLine <= scrollLine + LOG_LINES) ? (TRUE) : (FALSE));
	const char *print;

	CHECKINIT(init, L);

	print = luaL_checkstring(L, 1);
	lua_pop(L, 1);

	if(print)
	{
		/* Print the message in the log window */
		wprintw(win_log, "%s", print);

		getyx(win_log, lastLine, collumn);
		if(collumn)
			lastLine++;
		if(scroll) {
			scrollLine = lastLine - LOG_LINES;
			if (scrollLine < 0)
				scrollLine = 0;
			pnoutrefresh(win_log, scrollLine, 0, 2, 1, LOG_LINES + 1, LOG_COLS + 1);
		}

		/* Add the message to the log buffer */
		if(insert + strlen(print) >= logbuf + sizeof(logbuf))
		{
			memmove(logbuf, logbuf + sizeof(logbuf) / 2, sizeof(logbuf) / 2);
			memset(logbuf + sizeof(logbuf) / 2, 0, sizeof(logbuf) / 2);
			insert -= sizeof(logbuf) / 2;
		}
		strcpy(insert, print);
		insert += strlen(print);

		/* Update the scrollbar */
		c_private_drawScrollBar();

		/* Move the cursor back to the input field */
		c_private_updateCursor();
		doupdate();
	}

	return 0;
}

int c_setHistoryFile(lua_State *L)
{
	CHECKINIT(init, L);

	strncpy(historyFile, luaL_checkstring(L, 1), sizeof(historyFile));

	return 0;
}

int c_loadHistory(lua_State *L)
{
	CHECKINIT(init, L);

	if(historyFile[0])
	{
#ifndef HIST_PHYSFS
		FILE *fin = fopen(historyFile, "r");

		if(fin)
		{
			char line[MAX_EDIT_LINE] = {""};
			int i = 0;
			int c;
			int newline = TRUE;

			while((c = getc(fin)) != EOF)
			{
				if(c == 0)
				{
					/* ignore null bytes if they somehow get inside the file */

					newline = FALSE;
				}
				else if(c == '\n' || c == '\r')
				{
					if(!newline)
					{
						c_private_addHistoryField(line);

						line[0] = i = 0;
					}

					newline = TRUE;
				}
				else
				{
					line[i++] = c;
					line[i]   = 0;

					newline = FALSE;
				}
			}

			fclose(fin);
		}
#else
		PHYSFS_File *fin = PHYSFS_openRead(historyFile);

		if(fin)
		{
			char line[MAX_EDIT_LINE] = {""};
			int i = 0;
			char c;
			int newline = TRUE;
			int status;

			while((status = PHYSFS_read(fin, &c, 1, 1)) >= 1)
			{
				if(c == 0)
				{
					/* ignore null bytes if they somehow get inside the file */

					newline = FALSE;
				}
				else if(c == '\n' || c == '\r')
				{
					if(!newline)
					{
						c_private_addHistoryField(line);

						line[0] = i = 0;
					}

					newline = TRUE;
				}
				else
				{
					line[i++] = c;
					line[i]   = 0;

					newline = FALSE;
				}
			}

			status = PHYSFS_close(fin);
			if(!status)
			{
				lua_pushstring(L, PHYSFS_getLastError());
				lua_error(L);

				return 0;
			}
		}
#endif
		else
		{
			/* silently ignore */
		}
	}

	return 0;
}

int c_saveHistory(lua_State *L)
{
	CHECKINIT(init, L);

	if(historyFile[0])
	{
#ifndef HIST_PHYSFS
		FILE *fout = fopen(historyFile, "w");

		if(fout)
		{
			int i;
			historyField_t *historyField;

			for(i = 0, historyField = &history[0]; i < MAX_HISTORY_FIELDS; i++, historyField++)
			{
				if(historyField->text[0])
				{
					const char *p = historyField->text;

					while(*p) fputc(*p++, fout);

					putc('\n', fout);
				}
			}

			fclose(fout);
		}
#else
		PHYSFS_File *fout = PHYSFS_openWrite(historyFile);

		if(fout)
		{
			int i;
			int status;
			historyField_t *historyField;

			for(i = 0, historyField = &history[0]; i < MAX_HISTORY_FIELDS; i++, historyField++)
			{
				if(historyField->text[0])
				{
					const char *p = historyField->text;

					while(*p && status >= 1)
						PHYSFS_write(fout, p++, 1, 1);
					if(status <= 0)
					{
						lua_pushstring(L, PHYSFS_getLastError());
						lua_error(L);

						return 0;
					}

					PHYSFS_write(fout, "\n", 1, 1);
				}
			}

			PHYSFS_close(fout);
		}
#endif
		else
		{
			/* silently ignore */
		}
	}

	return 0;
}
