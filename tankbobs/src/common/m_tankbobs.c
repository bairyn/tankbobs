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

/*
 * tankbobs module
 */

#include "common.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <SDL.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <luaconf.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <math.h>
#include <SDL_endian.h>
#include <signal.h>

#include "m_tankbobs.h"
#include "tstr.h"
#include "crossdll.h"

#define VERSION "0.1.0"
#define VERSIONSUFFIX "-dev"

int init = false;
Uint32 sdlFlags;

int t_t(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushboolean(L, true);

	return 1;
}

int t_in(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushboolean(L, true);

	return 1;
}

int t_io(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushboolean(L, true);

	return 1;
}

int t_r(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushboolean(L, true);

	return 1;
}

int t_m(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushboolean(L, true);

	return 1;
}

int t_w(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushboolean(L, true);

	return 1;
}

int t_c(lua_State *L)
{
	CHECKINIT(init, L);

#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WINDOWS__) || defined(__WINDOWS__)
	lua_pushboolean(L, false);
#else
	lua_pushboolean(L, true);
#endif

	return 1;
}

int t_a(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushboolean(L, true);

	return 1;
}

int t_n(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushboolean(L, true);

	return 1;
}

int t_fs(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushboolean(L, true);

	return 1;
}

void t_init(lua_State *L)
{
}

static char siName[BUFSIZE] = {""};
static lua_State *siState = NULL;

static void t_private_interrupt(int unused)
{
	if(siName[0] && siState)
	{
		lua_getfield(siState, LUA_GLOBALSINDEX, siName);
		lua_call(siState, 0, 0);
	}
}

int t_initialize(lua_State *L)
{
	int extra = lua_toboolean(L, 2);
	const char *sif;
	static int initialized = false;

	if(lua_isstring(L, 1))
	{
		sif = lua_tostring(L, 1);

		strncpy(siName, sif, sizeof(siName));

		siState = L;
	}

	if(initialized)
	{
		SDL_Quit();
	}
	else
	{
		if(siName[0] && siState)
		{
			signal(SIGINT, t_private_interrupt);
		}
	}

	initialized = true;

	atexit(SDL_Quit);
	if(SDL_Init((extra ? (SDL_INIT_VIDEO | SDL_INIT_AUDIO) : 0) | SDL_INIT_TIMER) != 0)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "Error initializing SDL: ");
		CDLL_FUNCTION("libtstr", "tstr_cat", void(*)(tstr *, const char *))
			(message, SDL_GetError());
		CDLL_FUNCTION("libtstr", "tstr_base_cat", void(*)(tstr *, const char *))
			(message, "\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	init = true;

	return 0;
}

int t_quit(lua_State *L)
{
	CHECKINIT(init, L);

	r_quitFont();

	/* free temporary files */
	fs_freeTemporaryFilesNL();

	return 0;
}

int t_quitSDL(lua_State *L)
{
	CHECKINIT(init, L);

	SDL_Quit();

	return 0;
}

int t_getVersion(lua_State *L)
{
	const char *v = VERSION;
	const char *s = VERSIONSUFFIX;
	char buf[BUFSIZE] = {""};
	int i = 0, j = 0;

	lua_newtable(L);

	while(*v && i < sizeof(buf) - 1)
	{
		char c = *v++;

		if(c == '.' || i >= sizeof(buf) - 1)
		{
			int n;

			sscanf(buf, "%d", &n);

			lua_pushinteger(L, ++j);
			lua_pushinteger(L, n);
			lua_settable(L, -3);

			i = buf[0] = 0;
		}
		else
		{
			buf[i++] = c;
			buf[i]   = 0;
		}
	}

	if(buf[0])
	{
		int n;

		sscanf(buf, "%d", &n);

		lua_pushinteger(L, ++j);
		lua_pushinteger(L, n);
		lua_settable(L, -3);

		i = buf[0] = 0;
	}

	if(*s)
	{
		lua_pushinteger(L, ++j);
		lua_pushstring(L, s);
		lua_settable(L, -3);
	}

	return 1;
}

int t_getTicks(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushinteger(L, SDL_GetTicks());
	return 1;
}

int t_delay(lua_State *L)
{
	CHECKINIT(init, L);

	SDL_Delay(luaL_checkinteger(L, 1));
	return 1;
}

int t_isDebug(lua_State *L)
{
	CHECKINIT(init, L);

#ifdef TDEBUG
	lua_pushboolean(L, true);
#else
	lua_pushboolean(L, false);
#endif
	return 1;
}

int t_is64Bit(lua_State *L)
{
	CHECKINIT(init, L);

#if defined(__x86_64) || defined(__x86_64__) || defined(__ia64) || defined(__ia64__) || defined(__IA64) || defined(__IA64__) || defined(__M_IA64) || defined(__M_IA64__) || defined(_WIN64)
	lua_pushboolean(L, true);
#else
	lua_pushboolean(L, false);
#endif
	return 1;
}

int t_isWindows(lua_State *L)
{
	CHECKINIT(init, L);

#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WINDOWS__) || defined(__WINDOWS__)
	lua_pushboolean(L, true);
#else
	lua_pushboolean(L, false);
#endif
	return 1;
}

int t_implode(lua_State *L)
{
	int i;
	const char *glue = "";
	char str[BUFSIZE] = {""};

	CHECKINIT(init, L);

	if(lua_isstring(L, 2))
		glue = lua_tostring(L, 2);

	i = 0;
	lua_pushnil(L);
	while(lua_next(L, 1))
	{
		if(lua_isstring(L, -1))
			strncat(str, lua_tostring(L, -1), sizeof(str) - strlen(str) - 1);

		if(*glue)
			strncat(str, glue, sizeof(str) - strlen(str) - 1);

		lua_pop(L, 1);
	}

	lua_pushstring(L, str);

	return 1;
}

static int t_private_isDelimiter(const char c, const char *delimiters)
{
	while(*delimiters)
		if(c == *delimiters++)
			return TRUE;

	return FALSE;
}

int t_explode(lua_State *L)
{
	int i = 0, j = 0;
	int ignoringDelimiterInQuotes = FALSE;  /* this variable has a different name from ignoreDelimiterInQuotes */
	const char *delimiters;
	const char *string;
	static char lineBuf[BUFSIZE];
	char *line;
	int noEmptyElements;
	int ignoreDelimitersInQuotes;  /* this variable has a different name from ignoringDelimiterInQuotes */
	int escapeSequences;
	int stringLen;
	int lastArgumentEmpty;

	CHECKINIT(init, L);

	string = luaL_checkstring(L, 1);
	stringLen = strlen(string);
	delimiters = luaL_checkstring(L, 2);
	noEmptyElements = lua_toboolean(L, 3);
	ignoreDelimitersInQuotes = lua_toboolean(L, 4);
	escapeSequences = lua_toboolean(L, 5);
	lastArgumentEmpty = lua_toboolean(L, 6);

	if(stringLen >= BUFSIZE)
		line = malloc((strlen(string) + 1) * sizeof(char));
	else
		line = &lineBuf[0];

	*line = 0;

	lua_newtable(L);

	while(*string)
	{
		if(!ignoringDelimiterInQuotes && t_private_isDelimiter(*string, delimiters))
		{
			if(!noEmptyElements || line[0])
			{
				lua_pushinteger(L, ++i);
				lua_pushstring(L, line);
				lua_settable(L, -3);
			}

			*line = j = 0;

			/* do string++; while(noEmptyElements && t_private_isDelimiter(*string, delimiters); */
			string++;

			if(noEmptyElements)
			{
				while(*string && t_private_isDelimiter(*string, delimiters)) string++;
			}
		}
		else if(ignoreDelimitersInQuotes && *string == '"')
		{
			ignoringDelimiterInQuotes =! ignoringDelimiterInQuotes;

			string++;
		}
		else
		{
			if(escapeSequences && *string == '\\')
			{
				string++;

				if(*string != '"' && *string != '\\')
					string--;

				line[j++] = *string++;
				line[j]   = 0;
			}
			else
			{
				line[j++] = *string++;
				line[j]   = 0;
			}
		}
	}

	if(!noEmptyElements || lastArgumentEmpty || line[0])
	{
		lua_pushinteger(L, ++i);
		lua_pushstring(L, line);
		lua_settable(L, -3);
	}

	if(stringLen >= BUFSIZE)
		free(line);

	return 1;
}

#define TABLESIZE 1024 * 1024  // FIXME: fix segfault when dynamic memory is used when cloning large tables, and then lower this value

typedef struct table_s table_t;
struct table_s
{
	const void *address;

	table_t *next;
} moreTraversedTables;

static const void *traversedTables[TABLESIZE];
static const void **nextTable;
static table_t *lastDynTable;
static int tableDynMem = FALSE;

static void t_cloneTable(lua_State *L, int copyVectors)
{
	/* see if any of the tables has already been traversed to avoid circular references */

	/* add the input and output tables to the list of already traversed tables */
	if(!tableDynMem)
	{
		*nextTable++ = lua_topointer(L, -2);
		if(nextTable - traversedTables >= sizeof(traversedTables) / sizeof(traversedTables[0]))
		{
			memset(&moreTraversedTables, 0, sizeof(moreTraversedTables));
			lastDynTable = NULL;
			tableDynMem = TRUE;
		}
	}
	else
	{
		table_t *newTable;

		if(moreTraversedTables.address)
		{
			newTable = malloc(sizeof(table_t));
			lastDynTable->next = newTable;
			lastDynTable = newTable;
		}
		else
		{
			newTable = lastDynTable = &moreTraversedTables;
		}

		memset(newTable, 0, sizeof(table_t));

		newTable->address = lua_topointer(L, -1);
	}

	if(!tableDynMem)
	{
		*nextTable++ = lua_topointer(L, -1);
		if(nextTable - traversedTables >= sizeof(traversedTables) / sizeof(traversedTables[0]))
		{
			memset(&moreTraversedTables, 0, sizeof(moreTraversedTables));
			lastDynTable = NULL;
			tableDynMem = TRUE;
		}
	}
	else
	{
		table_t *newTable;

		if(moreTraversedTables.address)
		{
			newTable = malloc(sizeof(table_t));
			lastDynTable->next = newTable;
			lastDynTable = newTable;
		}
		else
		{
			newTable = lastDynTable = &moreTraversedTables;
		}

		memset(newTable, 0, sizeof(table_t));

		newTable->address = lua_topointer(L, -1);
	}

	/* iterate over each element of the input table */
	lua_pushnil(L);
	while(lua_next(L, -3))
	{
		if(lua_istable(L, -1))
		{
			const void **i;
			const void *p = lua_topointer(L, -1);
			int found = FALSE;

			/* skip if either of the tables have been traversed */
			for(i = &traversedTables[0]; i < nextTable && i < traversedTables + sizeof(traversedTables) / sizeof(traversedTables[0]); i++)
			{
				if(*i == p)
				{
					found = TRUE;

					break;
				}
			}

			if(!found && tableDynMem && lastDynTable)
			{
				table_t *i;

				for(i = &moreTraversedTables; i; i = i->next)
				{
					if(i->address == p)
					{
						found = TRUE;

						break;
					}
				}
			}

			if(found)
			{
				lua_pop(L, 1);

				continue;
			}

			/* copy the table */
			lua_pushvalue(L, -2);
			lua_gettable(L, -4);
			if(!lua_istable(L, -1))
			{
				lua_pop(L, 1);
				lua_newtable(L);
				lua_pushvalue(L, -3);
				lua_pushvalue(L, -2);
				lua_settable(L, -6);
			}
			else
			{
				/* skip if either of the tables have been traversed */
				p = lua_topointer(L, -1);

				for(i = &traversedTables[0]; i < nextTable && i < traversedTables + sizeof(traversedTables) / sizeof(traversedTables[0]); i++)
				{
					if(*i == p)
					{
						found = TRUE;

						break;
					}
				}

				if(!found && tableDynMem && lastDynTable)
				{
					table_t *i;

					for(i = &moreTraversedTables; i; i = i->next)
					{
						if(i->address == p)
						{
							found = TRUE;

							break;
						}
					}
				}

				if(found)
				{
					lua_pop(L, 3);

					continue;
				}
			}
			t_cloneTable(L, copyVectors);
			lua_pop(L, 2);
		}
		else
		{
			if(copyVectors && ISVEC(L, -1))
			{
				vec2_t *v;
				const vec2_t *v2;

				v2 = CHECKVEC(L, -1);
				lua_pop(L, 1);

				v = lua_newuserdata(L, sizeof(vec2_t));

				luaL_getmetatable(L, MATH_METATABLE);
				lua_setmetatable(L, -2);

				memcpy(v, v2, sizeof(vec2_t));

				lua_pushvalue(L, -2);
				lua_pushvalue(L, -2);
				lua_settable(L, -5);
				lua_pop(L, 1);
			}
			else
			{
				lua_pushvalue(L, -2);
				lua_pushvalue(L, -2);
				lua_settable(L, -5);
				lua_pop(L, 1);
			}
		}
	}

	/* leave the input and output table on the stack */
}

int t_clone(lua_State *L)
{
	int copyVectors = FALSE;

	CHECKINIT(init, L);

	if(lua_isboolean(L, 1))
	{
		copyVectors = lua_toboolean(L, 1);

		lua_remove(L, 1);
	}

	if(!lua_istable(L, 1))
	{
		lua_pushnil(L);
		return 1;
	}

	if(!lua_istable(L, 2))
	{
		lua_settop(L, 1);

		/* create the output table if it doesn't exist */
		lua_newtable(L);
	}

	lua_settop(L, 2);

	nextTable = &traversedTables[0];

	t_cloneTable(L, copyVectors);

	if(tableDynMem)
	{
		table_t *i, *tmp;

		for(i = moreTraversedTables.next; i; i = tmp)
		{
			tmp = i->next;

			free(i);
		}
	}

	lua_remove(L, -2);

	return 1;
}

int t_emptyTable(lua_State *L)
{
	CHECKINIT(init, L);

	/* nil-iffies table */
	while(lua_pushnil(L), lua_next(L, -2))
	{
		lua_pop(L, 1);
		lua_pushnil(L);
		lua_settable(L, -3);
	}

	return 1;
}

static const struct luaL_Reg tankbobs[] =
{
	/* m_tankbobs.c */
	/* export functions to test which submodules have been implemented on various platforms */
	{"t_t", t_t},
	{"t_in", t_in},
	{"t_io", t_io},
	{"t_r", t_r},
	{"t_m", t_m},
	{"t_w", t_w},
	{"t_c", t_c},
	{"t_a", t_a},
	{"t_n", t_n},
	{"t_fs", t_fs},
	{"t_initialize", t_initialize}, /* initialize the module */
		/* Nothing is returned.  If the first argument is a string,
			the string is the number of the function to be called when
			SIGINT is emitted.  If the second argument is true, the extra
			sub-systems of SDL are initialized (AUDIO and VIDEO). */
	{"t_quit", t_quit}, /* clean up */
		/* no args, no returns, quits Tankbobs module */
	{"t_quitSDL", t_quitSDL}, /* quit SDL */
	{"t_getVersion", t_getVersion}, /* get libmtankbobs's version */
	    /* Nothing is passed to this function.  A version table is returned. */
	{"t_getTicks", t_getTicks}, /* SDL_GetTicks() */
		/* no args, 1st and only return value is number of milliseconds since
			app start */
	{"t_delay", t_delay}, /* SDL_Delay() */
		/* 1st arg is the ms to delay.  Nothing is returned. */
	{"t_isDebug", t_isDebug}, /* if debugging is enabled, return true, if not, return false */
	{"t_is64Bit", t_is64Bit}, /* if the machine is running 64-bit, return true, if not, return false */
	{"t_isWindows", t_isWindows}, /* if the machine is running Windows, return true, if not, return false */
	{"t_implode", t_implode}, /* implode a passed table of strings and return an imploded string */
		/* The first argument passed is a table of strings, and the optional, second argument passed is
			a string to insert between each imploded element */
	{"t_explode", t_explode}, /* explode the first string argument into a table of substrings which are returned */
		/* the second argument is a string of delimiters
			If the third argument is true, no empty strings will be passed.
			If the fourth argument passed is true, any delimiters between "'s will be ignored.
			If the fifth argument passed is true, two escape sequences will be recognized:
			\\ -> \; \" -> ".  This is useful if you want unhandled "'s in the passed string.
			The sixth argument passed will determine whether a final argument will be added if the string has
			extra whitespace. */
	{"t_clone", t_clone}, /* clone the first passed table into the second passed table */
		/* If the first argument is a boolean, it determines whether all vectors are copied */
	{"t_emptyTable", t_emptyTable}, /* empty a table by setting all elements to nil */
		/* Sets everything in the passed table to nil (doesn't really fields with numerical keys).  Returns nothing. */

	/* m_input.c */
	{"in_getResolutions", in_getResolutions}, /* get a table of resolutions */
		/* Nothing is passed.  Returns a table of resolutions.  Example:
			{{800, 600}, {1024, 768}}.  Nil is returned if something else happened. */
	{"in_getEvents", in_getEvents}, /* store events in a userdata */
		/* if there are no events to be queued, nil is returned - otherwise,
			the number of events processed and a userdatum pointing to the event
			queue is returned, function takes no arguments */
	{"in_getEventData", in_getEventData}, /* retrieve data from an event */
		/* first arg is the event queue, second is a string formatted to which
			argument, if the requested data cannot be retrieved, nil is returned
			, else the requested data is returned of type string for "type" or
			xDatay for the yth value (0-4) of type x for int:number,
			double:number, or str:string (note that xArgy and event are also
			supported)
			;
			Events:
			SDL_NOEVENT -
				type: "nothing"
			SDL_ACTIVEEVENT -
				type: "focus"
				intData0: 0 if loss or 1 if gain
			SDL_KEYDOWN -
				type: "keydown"
				intData0: the numerical value of the key pressed, eg decimal 96
					for the letter 'a'
				strData0: the string value of the key pressed, eg "a" for the
					letter 'a'
			SDL_KEYUP -
				type: "keyup"
				intData0: the numerical value of the key pressed, eg decimal 96
					for the letter 'a'
				strData0: the string value of the key pressed, eg "a" for the
					letter 'a'
			SDL_MOUSEMOTION
				type: "mousemove"
				intData0: x absolute cursor position
				intData1: y absolute cursor position
				intData2: x position relative to previous x position; will
					probably also capture any mouse movements exceeding screen
					limits
				intData3: y position relative to previous y position; will
					probably also capture any mouse movements exceeding screen
					limits
				intData4: bool result of several OR flags
					0x00000001: mask for state is non-NULL
					0x00000010: mask for mouse has moved away from left of
						screen
					0x00000100: mask for mouse has moved up from bottom of
						screen
			SDL_MOUSEBUTTONDOWN:
				type: "mousedown"
				intData0: which button was pressed:
					0: unknown or unhandled
					1: left mouse button
					2: right mouse button
					3: middle mouse button
					4: mouse wheel down
					5: mouse wheel up
				intData1: absolute x position when button was pressed
				intData2: absolute y position when button was pressed
				intData3: raw button value
			SDL_MOUSEBUTTONUP:
				type: "mouseup"
				intData0: which button was released:
					0: unknown or unhandled
					1: left mouse button
					2: right mouse button
					3: middle mouse button
					4: mouse wheel down
					5: mouse wheel up
				intData1: absolute x position when button was pressed
				intData2: absolute y position when button was pressed
				intData3: raw button value
			SDL_JOYAXISMOTION:
				type: "joyaxis"
				intData0: axis index (typically 0 for x, 1 for y)
				intData1: absolute axis position
				intData2: device index (which joystick)
				doubleData0: percentage of axis (-100 to 100)
			SDL_JOYBALLMOTION:
				type: "joyball"
				intData0: x position relative to previous position
				intData1: y position relative to previous position
				intData2: which ball
				intData3: which joystick
			SDL_JOYHATMOTION:
				type: "joyhat"
				intData0: which hat
				intData1: which joystick
				intData2: hat position:
					0: unknown or unhandled
					1: center
					2: upright
					3: leftdown
					4: leftup
					5: rightdown
					6: left
					7: up
					8: down
					9: right
				intData3: raw hat value
			SDL_JOYBUTTONDOWN
				type: "joydown"
				intData0: which button
				intData1: which joystick
			SDL_JOYBUTTONUP
				type: "joyup"
				intData0: which button
				intData1: which joystick
			SDL_VIDEORESIZE
				type: "video"
				intData0: width
				intData1: height
			SDL_VIDEOEXPOSE
				type: "videofocus"
			SDL_QUIT
				type: "quit"
			SDL_USEREVENT
				type: "user"
				intData0: user defined code (TODO: handle other two data)
			SDL_SYSWMEVENT
				type: "wm"
			 */
	{"in_nextEvent", in_nextEvent}, /* grab the next event */
		/* first and only argument is the event queue.  returns the next event
			if there is one, or nil if there isn't */
	{"in_freeEvents", in_freeEvents}, /* free an event queue */
		/* first and only arg is event queue to be freed, must be called after
			processing a queue */
	{"in_grabClear", in_grabClear}, /* frees and shows cursor */
		/* no args, no returns, frees and shows cursor */
	{"in_grabMouse", in_grabMouse}, /* grabs and hides cursor */
		/* 1st arg is width of window, 2nd arg is height, no returns, grabs and
			hides cursor */
	{"in_isGrabbed", in_isGrabbed}, /* is cursor grabbed */
		/* no args, 1 and only return is boolean of whether or not cursor is
			grabbed */
	{"in_getKeys", in_getKeys}, /* grab array of SDL keys */
		/* Nothing is passed or returned. */
	{"in_keyPressed", in_keyPressed}, /* see if a key is pressed */
		/* The key is the only value passed.  in_getKeys must be called before any call to this function. */

	/* m_io.c */
	{"io_toInt", io_toInt}, /* returns the integer generated by the first four bytes of the string passed */
		/* The arguments are not checked */
	{"io_toShort", io_toShort}, /* returns the integer generated by the first two bytes of the string passed */
		/* The arguments are not checked */
	{"io_toChar", io_toChar}, /* returns the integer generated by the first byte of the string passed */
		/* The arguments are not checked */
	{"io_toFloat", io_toFloat}, /* returns the number generated by the first four bytes of the string passed */
		/* The arguments are not checked */
	{"io_toDouble", io_toDouble}, /* returns the number generated by the first eight bytes of the string passed */
		/* The arguments are not checked */
	{"io_fromInt", io_fromInt}, /* returns the string generated by the first four bytes of the integer passed */
		/* The arguments are not checked */
	{"io_fromShort", io_fromShort}, /* returns the string generated by the first two bytes of the integer passed */
		/* The arguments are not checked */
	{"io_fromChar", io_fromChar}, /* returns the string generated by the first byte of the integer passed */
		/* The arguments are not checked */
	{"io_fromFloat", io_fromFloat}, /* returns the string generated by the first four bytes of the number passed */
		/* The arguments are not checked */
	{"io_fromDouble", io_fromDouble}, /* returns the string generated by the first eight bytes of the number passed */
		/* The arguments are not checked */
	/* These functions are deprecated.  Use fs_* instead. */
	{"io_getHomeDirectory", io_getHomeDirectory},  /* function to retrieve the user directory, eg /home/user */
		/* returns a string of the users directory, or nil plus an error
			message, no args */
	{"io_getInt", io_getInt}, /* get int */
		/* returns an int read from the file or -1 on EOF, first arg is file handle */
	{"io_getShort", io_getShort}, /* get short */
		/* returns a short read from the file or -1 on EOF, first arg is file handle */
	{"io_getChar", io_getChar}, /* get char */
		/* returns a byte (number) read from the file or -1 on EOF, first arg is file handle */
	{"io_getFloat", io_getFloat}, /* get float */
		/* returns a float read from the file or -1 on EOF, first arg is file handle */
	{"io_getDouble", io_getDouble}, /* get double */
		/* returns a double read from the file or -1 on EOF, first arg is file handle */
	{"io_getStr", io_getStr}, /* get null-terminated string */
		/* returns a null-terminated string of up to 10000 read from the file or -1 on EOF, first arg is file handle */
	{"io_getStrL", io_getStrL}, /* get string */
		/* returns a string read from the file or -1 on EOF, first arg is file handle, second is number(integer) of number of bytes to read */

	/* m_renderer.c */
	{"r_initialize", r_initialize}, /* init SDL video */
		/* init the video, return nothing, no args */
	{"r_checkRenderer", r_checkRenderer}, /* warn the user of weak rendering */
		/* report weak hardware but do not terminate, return nothing, no args */
	{"r_newWindow", r_newWindow}, /* new window */
		/* new window, return nothing, first arg is an integeral width value,
			second is height, third is boolean fullscreen, fourth is title,
			fifth is icon */
	{"r_ortho2D", r_ortho2D}, /* gluOrtho2d */
		/* double arguments to match the function, no return, 4 args */
	{"r_swapBuffers", r_swapBuffers}, /* swap the double buffer */
		/* no args, no rets, interface to swap display buffers */
	{"r_newFont", r_newFont}, /* create a new font */
		/* Nothing is returned.  The first argument is the font's name.
			The second argument is the font's filenames.  The third is its size
			(ptsize). */
	{"r_selectFont", r_selectFont}, /* select a font to use */
		/* Nothing is returned.  The only argument passed is the name of the  font to be selected. */
	{"r_fontName", r_fontName}, /* get the current font's name */
		/* This function takes no arguments.  The currently selected font's name is returned. */
	{"r_fontFilename", r_fontFilename}, /* get the current font's filename */
		/* This function takes no arguments.  The currently selected font's filename is returned. */
	{"r_fontSize", r_fontSize}, /* get the current font's Size */
		/* This function takes no arguments.  The currently selected font's Size is returned. */
	{"r_drawString", r_drawString}, /* draw a string */
		/* The first argument is the string to be drawn.  The second is the position (lower
			left.  The third is the red, fourth green, fifth blue, and sixth alpha.  The seventh
			argument is the x scale of the text, and the eighth is the y scale.  The ninth argument
			is a boolean of whether the cache should be prioritized.  The position
			of the upper right corner is returned. */
	{"r_freeFont", r_freeFont}, /* free a font */
		/* no return, 1st and only arg is name of the font */
	{"r_loadImage2D", r_loadImage2D}, /* load an image into the currently bound 2D texture */
		/* the first argument passed is the filename of the image to be loaded.  The second
			argument is the filename of the default image to load if the first image
			couldn't be loaded.  Nothing is returned */

	/* m_math.c */
	{"m_vec2", m_vec2}, /* new vector */
		/* no arguments are passed; the vector is returned */
	{"m_radians", m_radians}, /* convert from degrees to radians */
		/* the 1st argument is the degrees; the radians is returned */
	{"m_degrees", m_degrees}, /* convert from radians to degrees */
		/* the 1st argument is the radians; the degrees is returned */
	{"m_edge", m_edge}, /* test if and where two lines intersect */
		/* the first two arguments passed are vectors of the coordinates of the first line */
		/* and the third and fourth are the second line (l1p1, l1p2, l2p1, l2p2). */
		/* If they do not intersect, false is returned.  If they do, */
		/* true and the point of intersection is returned. */
	{"m_line", m_line}, /* test if two lines intersect */
		/* same as above but doesn't return the point of intersection. */
		/* this function is faster and should be used wherever possible */
	{"m_polygon", m_polygon}, /* test if two polygons intersect */
		/* the first argument is a table of coordinates for the first polygon, second for the second polygon */
		/* returns a boolean only. */

	/* m_world.c */
	{"w_step", w_step}, /* world step */
		/* Nothing is returned or passed */
	{"w_newWorld", w_newWorld}, /* initialize a new world */
		/* nothing is returned; the first argument is a vector of the lower bounds.  The second
			argument is of the upper bounds.  The third argument is the gravity vector (should always
			be a zero-factor.  The fourth argument is a boolean of whether bodies can sleep.
			The fifth argument is the function to call on contact (f(shape1, shape2, body1, body2, position, separation, normal)).  The sixth, seventh, eighth, ninth, tenth, eleventh, twelfth, and the thirteenth arguments are step functions of the tanks, walls, projectiles, powerupSpawnPoints, powerups, controlPoints, flags, and teleporters.  Arguments fourteen-twenty-one are the tables of them. */
	{"w_freeWorld", w_freeWorld}, /* free the current world */
		/* no arguments are passed and nothing is returned.  The current world is freed. */
	{"w_getTimeStep", w_getTimeStep}, /* get time step */
		/* returns the time step */
	{"w_setTimeStep", w_getTimeStep}, /* set time step */
		/* sets the time step to the first argument */
	{"w_getIterations", w_getIterations}, /* get iterations */
		/* returns the iterations */
	{"w_setIterations", w_getIterations}, /* set iterations */
		/* sets the iterations to the first argument */
	{"w_addBody", w_addBody}, /* add a body to the world */
		/* The first argument is the position of the body represented by a vector.
			The second argument is the body's rotation in radians
			The third argument is whether the body can sleep.  The fourth argument is
			whether the body is a bullet.  The fifth and sixth arguments are the body's
			linear and angular damping.
			The seventh argument is a table of the vertices *relative to the position
			of the body.  The eighth argument is the shape's density.  The ninth is the friction.
			The tenth is the restitution.  The eleventh argument is whether the body to be added is static.
			A pointer to the body to use for other functions is the only value returned.
			The returned value can be safely ignored.  The twelfth and thirteenth arguments
			are the contents and clipmask of the body.  The fourteenth argument a boolean of whether the body
			is a sensor.  The fifteenth argument is the initial index of the body passed as an integer. */
	{"w_removeBody", w_removeBody}, /* remove a body from the world */
		/* Nothing is returned.  The first argument is the pointer to the body returned from w_addBody. */
	{"w_bodies", w_bodies}, /* generate a table of pointers to bodies */
		/* nothing is passed.  A table of bodies is generated. */
	{"w_isBullet", w_isBullet}, /* whether the body is a bullet */
		/* The body is the only value passed.  A boolean is returned. */
	{"w_setBullet", w_setBullet}, /* set a body as bullet or not */
		/* The body is the first value passed.  The second argument is the value of whether the body is a
			bullet.  Nothing is returned. */
	{"w_isStatic", w_isBullet}, /* whether the body is static */
		/* The body is the only value passed.  A boolean is returned. */
	{"w_isDynamic", w_isDynamic}, /* whether the body is dynamic */
		/* The body is the only value passed.  A boolean is returned. */
	{"w_isSleeping", w_isSleeping}, /* whether the body is sleeping */
		/* The body is the only value passed.  A boolean is returned. */
	{"w_allowSleeping", w_allowSleeping}, /* whether the body is sleeping */
		/* The body is the first value passed.  The second argument is whether the body will ever sleep. */
	{"w_wakeUp", w_wakeUp}, /* wake a body up */
		/* The body is the only value passed.  Nothing is returned. */
	{"w_getPosition", w_getPosition}, /* get a body's position */
		/* The body is the first argument passed.  The returned value is a vector of the body's position */
	{"w_getAngle", w_getAngle}, /* get a body's angle */
		/* The body is the first argument passed.  The returned value is the body's angle */
	{"w_setLinearVelocity", w_setLinearVelocity}, /* set a body's linear velocity */
		/* The body is the first argument passed.  The second argument is the linear velocity to be set (in a vector). */
	{"w_getLinearVelocity", w_getLinearVelocity}, /* get a body's linear velocity */
		/* The body is the first argument passed.  The returned value is the body's linear velocity (in a vector) */
	{"w_setAngularVelocity", w_setAngularVelocity}, /* set a body's angular velocity */
		/* The body is the first argument passed.  The second argument is the angular velocity to be set. */
	{"w_getAngularVelocity", w_getAngularVelocity}, /* get a body's angular velocity */
		/* The body is the first argument passed.  The returned value is the body's angular velocity */
	{"w_setPosition", w_setPosition}, /* set a body's position without simulation */
		/* The body is the first argument, and the position is the second argument */
	{"w_setAngle", w_setAngle}, /* set a body's angle without simulation */
		/* The body is the first argument, and the angle is the second argument */
	{"w_applyForce", w_applyForce}, /* apply a force to a body */
		/* The first argument is the body.  The second argument is the force to apply, and the third
			argument is the point of the force. */
	{"w_applyTorque", w_applyTorque}, /* apply a torque to a body */
		/* The first argument is the body.  The second argument is the torque to apply, and the third
			argument is the point of the torque. */
	{"w_applyImpulse", w_applyImpulse}, /* apply an impulse to a body */
		/* The first argument is the body.  The second argument is the impulse to apply, and the third
			argument is the point of the impulse. */
	{"w_getCenterOfMass", w_getCenterOfMass}, /* get a body's center of mass */
		/* The first and only argument is the body.  A vector of the position of the body's
			center of mass is returned */
	{"w_scaleVelocity", w_scaleVelocity}, /* scale the velocities of all bodies in the world */
		/* The scalar is passed as a number.  Nothing is returned. */
	{"w_persistWorld", w_persistWorld}, /* generate a string of the world */
		/* A string containing the data of the world is returned.  The first argument passed
			is the projectiles of the world.  The second argument passed are the tanks of the world.
			The third argument is a table of the powerups.  The fourth argument passed is a table of
			the walls.  The fifth and sixth arguments are the control points and flags */
	{"w_unpersistWorld", w_unpersistWorld}, /* unpersist the world */
		/* Nothing is returned.  The first argument passed is the data of the persisted world.  The rest of the arguments are the same arguments that would passed to w_persistWorld.  After these arguments, the function to be called for new projectiles is passed, the function for tanks, the function for powerups, the projectile class, and then the tank class, and the powerup class.  Next, all but the first and second arguments which would be passed to w_addBody for projectiles is passed *in a table*.  Then, the function which will be called when a tank is spawned is passed, and then the same for a powerup. */
	{"w_getVertices", w_getVertices}, /* Get the vertices of a table */
		/* The body is the first argument passed.  The table of vertices to be set is also passed.  A table of
			vertices is returned. */
	{"w_getContents", w_getContents}, /* Get the contents of a body */
		/* Return the passed body's contents, or nil if no shapes are attached */
	{"w_getClipmask", w_getClipmask}, /* Get the clipmask of a body */
		/* Return the passed body's clipmask, or nil if no shapes are attached */
	{"w_getIndex", w_getIndex}, /* Get the body's index */
		/* Return the passed body's index */
	{"w_setIndex", w_setIndex}, /* Set the body's index */
		/* Set the passed body's index to the second argument, which is passed as an integer */
	{"w_luaStep", w_luaStep}, /* the only argument passed is the delta value */
	{"w_setContactListener", w_setContactListener}, /* Set contact listener function */
		/* Set contact listener function to argument passed.  Nothing is returned. */

	/* m_console.c */
#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WINDOWS__) || defined(__WINDOWS__)
#else
	{"c_init", c_init}, /* initialize an ncurses console */
		/* Nothing is returned; nothing is passed. */
	{"c_quit", c_quit}, /* close the ncurses console */
		/* Nothing is returned; nothing is passed. */
	{"c_input", c_input}, /* test for input from the console */
		/* nil is returned when no input has been applied.
			If there is input (the user pressed enter), the input is retutrned as a string. */
	{"c_setTabFunction", c_setTabFunction}, /* set the auto-complete function name to be called when the user presses tab */
		/* Nothing is returned.  The name of the function is passed as a string.
			When the user presses tab, this function is called with the current input text passed as
			a string.  If the function returns a string, the input is set to the string */
	{"c_print", c_print}, /* print a string to the console */
		/* Nothing is returned.  The string to print to the console is passed. */
	{"c_setHistoryFile", c_setHistoryFile}, /* set the history file for the console */
		/* Nothing is returned.  The filename of the history file to be used by the console
			is passed as a string. */
	{"c_loadHistory", c_loadHistory}, /* load the history file */
		/* Nothing is returned; nothing is passed. */
	{"c_saveHistory", c_saveHistory}, /* save the history file */
		/* Nothing is returned; nothing is passed. */
#endif

	/* m_audio.c */
	{"a_init", a_init}, /* initialize the audio */
		/* Nothing is returned; nothing is passed. */
	{"a_quit", a_quit}, /* close the audio device */
		/* Nothing is returned; nothing is passed. */
	{"a_initSound", a_initSound}, /* initialize a sound */
		/* The filename of the sound is passed.  Nothing is returned.
			This function initializes the music */
	{"a_freeSound", a_freeSound}, /* free a sound from cache */
		/* This function does not need to be called to free a sound from
			memory.  This function frees the filename passed as a string
			from cache.  a_quit() will free the sounds */
	{"a_startMusic", a_startMusic}, /* start or continued paused music */
		/* The filename of the music is passed; nothing is returned */
	{"a_pauseMusic", a_pauseMusic}, /* pause the music */
		/* The filename of the music is passed; nothing is returned */
	{"a_stopMusic", a_stopMusic}, /* stop the music (by fading out) */
		/* Nothing is returned; nothing is passed. */
	{"a_playSound", a_playSound}, /* play a sound */
		/* The filename of the sound is passed; nothing is returned.
			The second argument can optionally be passed to override the
			default number of loops: 0. */
	{"a_setMusicVolume", a_setMusicVolume}, /* set the music volume */
		/* The argument passed is the volume from 0 to 1.  Nothing is returned. */
	{"a_setVolume", a_setVolume}, /* set the volume */
		/* The argument passed is the volume from 0 to 1.  Nothing is returned. */
	{"a_setVolumeChunk", a_setVolumeChunk}, /* set the volume of an audio chunk */
		/* The first argument is the filename of the sound.  The second argument passed is the volume from 0 to 1.  Nothing is returned. */

	/* m_net.c */
	{"n_init", n_init}, /* initialize */
		/* If initialization is successful, true is returned.   If not, false and the error message is returned.  The port can optionally be passed. */
	{"n_quit", n_quit}, /* quit */
		/* Nothing is returned; nothing is passed. */
	{"n_setQueueTime", n_setQueueTime}, /* set packet queue time */
		/* The packet queue time is passed as an integer.  Nothing is returned. */
	{"n_newPacket", n_newPacket}, /* allocate a new packet (if the current packet hasn't been sent yet, it will be replaced) */
		/* Nothing is returned.  The size of the packet is passed */
	{"n_writeToPacket", n_writeToPacket}, /* write to the currently allocated packet */
		/* The bytes to write to the currently allocated packet is passed as a string; nothing is returned */
	{"n_setPort", n_setPort}, /* set the destination port */
		/* The port is passed; nothing is returned */
	{"n_sendPacket", n_sendPacket}, /* send the current packet to a specified host */
		/* The host can optionally be passed as a string; if not, the last host passed will be used.  Always pass the host at least once.  Nothing is returned */
	{"n_readPacket", n_readPacket}, /* read a packet from anywhere */
		/* Nothing is passed to this function.  If no packets are to be read, false is returned.
			If a packet is to be read; true, the packet's IP, port, and the data are returned separately as a string. */

	/* m_fs.c */
	{"fs_setArgv0_", fs_setArgv0}, /* set the first element of the command line" */
		/* This should be called before fs_init.  Pass the first element of the command line to this function.
			Nothing is returned.  This function can be called before initialization. */
	{"fs_init", fs_init}, /* initialize the filesystem */
		/* Initializes PhysicsFS.   Nothing is returned.  fs_setArgv0 should be called before this, even though the
		    command line will be attempt to be read automatically if it hasn't been called.  The optional first argument
			will determine whether or not symbolic links are permitted. */
	{"fs_quit", fs_quit}, /* de-initialize the filesystem */
		/* De-initializes PhysicsFS.  Nothing is returned; nothing is passed. */
	{"fs_getRawDirectorySeparator", fs_getRawDirectorySeparator}, /* get the raw directory separator */
		/* Nothing is passed.  A string of the directory separator is returned.  This should only be used when setting up the
			search or write paths; otherwise, use the platform-independent directory separator of '/' */
	{"fs_getCDDirectories", fs_getCDDirectories}, /* get a table of directories of accessible CD's */
		/* Nothing is passed.  A table of strings of directories of inserted disc media is returned. */
	{"fs_getBaseDirectory", fs_getBaseDirectory}, /* get the base directory */
		/* Returns the directory from which the program is run.  Nothing is passed. */
	{"fs_getUserDirectory", fs_getUserDirectory}, /* get the user directory */
		/* Returns the user directory.  Nothing is passed. */
	{"fs_getWriteDirectory", fs_getWriteDirectory}, /* get the current write directory */
		/* Nothing is passed.  The current write directory is returned, but if none is yet specified or it doesn't
			exist, then nil is returned. */
	{"fs_setWriteDirectory", fs_setWriteDirectory}, /* set the write directory */
		/* Set the write directory to the string passed.  Nothing is returned.  */
	{"fs_getSearchPath", fs_getSearchPath}, /* get the search path */
		/* Nothing is passed.  A table of strings of the directories of the current search path is returned. */
	{"fs_mkdir", fs_mkdir}, /* make a directory */
		/* Nothing is returned.  A directory according to the string passed relative to the write directory is made. */
	{"fs_remove", fs_remove}, /* remove a file or directory */
		/* Nothing is returned.  A file or directory according to the string passed relative to the write directory is removed. */
	{"fs_which", fs_which}, /* get the real path for a file or directory */
		/* A string representing the path relative to the search path is passed.  The archive or directory which contains the
			given file or directory is returned as a string if it exists, else nil is returned. */
	{"fs_listFiles", fs_listFiles}, /* list the files of a directory */
		/* A table of strings of filenames of the directory given by the string passed is returned. */
	{"fs_fileExists", fs_fileExists}, /* test if a file exists */
		/* Returns whether the passed filename exists and is a file. */
	{"fs_directoryExists", fs_directoryExists}, /* test if a directory exists */
		/* Returns whether the passed filename exists and is a directory. */
	{"fs_symbolicLinkExists", fs_symbolicLinkExists}, /* test if a symbolic link exists */
		/* Returns whether the passed filename exists and is a symbolic link. */
	{"fs_getModificationTime", fs_getModificationTime}, /* get modification time of a file */
		/* The filename is passed.  The modtime is returned as a number of seconds since the epoch (Jan 1, 1970)." */
	{"fs_openWrite", fs_openWrite}, /* open a file for writing */
		/* The filename passed is returned and the file handle for the new, truncated file is passed.
			Don't use fs_* file handles with normal file handles.  If a failure happens when opening a file through any fs_open*
			call, execution will stop, and the error will be printed.  You do not need to check errors yourself; errors are handled automatically. */
	{"fs_openAppend", fs_openAppend}, /* open a file for appending */
		/* The filename passed is returned and the file handle for the file to be appended is passed.
			Don't use fs_* file handles with normal file handles. */
	{"fs_openRead", fs_openRead}, /* open a file for reading */
		/* The filename passed is returned and the file handle for the file to be appended is passed.
			Don't use fs_* file handles with normal file handles. */
	{"fs_close", fs_close}, /* close an open file */
		/* The file handles by the passed handle is closed.  Nothing is returned. */
	{"fs_read", fs_read}, /* read an arbitrary number of bytes from a file */
		/* The file handle and the number of bytes to be read is passed.  The data that was able to be read is returned as a string, and a boolean
			is returned.  The boolean is set to true if EOF was reached. */
	{"fs_write", fs_write}, /* write data to a file */
		/* Nothing is returned.  The file handle and the string to write is passed. */
	{"fs_tell", fs_tell}, /* get the current file position */
		/* Returns the current position of the file of the passed file handle offset in bytes from start of file as an integer */
	{"fs_seekFromStart", fs_seekFromStart}, /* seek to a position */
		/* Set the file position of the passed file handle to the offset, which is passed as an integer.  Nothing is returned. */
	{"fs_fileLength", fs_fileLength}, /* get a file's length */
		/* Returns the length of the file of the file handle passed */
	{"fs_getInt", fs_getInt}, /* read an integer from a file */
		/* The file handle is passed.  The integer is returned, or nil if EOF is reached. */
	{"fs_getShort", fs_getShort}, /* read a short */
		/* Reads a short. */
	{"fs_getChar", fs_getChar}, /* read a char */
		/* Reads a char. */
	{"fs_getDouble", fs_getDouble}, /* read a double */
		/* Reads a double. */
	{"fs_getFloat", fs_getFloat}, /* read a float */
		/* Reads a float. */
	{"fs_getStr", fs_getStr}, /* read a NULL-terminated string */
		/* The file handle is passed, and optionally a single character passed as a string can be passed as a string.  The NULL-terminated string is returned, or nil is returned if EOF is reached before the NULL terminator.  Additionally, a third argument may optionally be passed as a boolean.  If this boolean is true, then nil is not returned on EOF, and instead the accumulated strings are returned. */
	{"fs_putInt", fs_putInt}, /* write an integer to a file */
		/* The file handle and number is passed. */
	{"fs_putShort", fs_putShort}, /* write a short */
		/* Writes a short. */
	{"fs_putChar", fs_putChar}, /* write a char */
		/* Writes a char. */
	{"fs_putDouble", fs_putDouble}, /* write a double */
		/* Writes a double. */
	{"fs_putFloat", fs_putFloat}, /* write a float */
		/* Writes a float. */
	{"fs_mount", fs_mount}, /* mount a directory or archive */
		/* Nothing is returned.  The first argument passed is the absolute directory to add to the search path.  The second argument is a string that represents the mount point; an empty mount point is analogous to "/'.  The third argument is a boolean that specifies whether the path should be appended to the search path; if this boolean is false, then the path will be prepended. */
	{"fs_loadfile", fs_loadfile}, /* replacement for standard library function */
		/* Replacement for standard library function. */
	{"fs_permitSymbolicLinks", fs_permitSymbolicLinks}, /* permit or deny symbolic links */
		/* A boolean is passed.  Nothing is returned. */

	{NULL, NULL}
};

CDLL_PREFIX int luaopen_libmtankbobs(lua_State *L)
{
	t_init(L);
	in_init(L);
	io_init(L);
	r_init(L);
	m_init(L);
	w_init(L);
#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WINDOWS__) || defined(__WINDOWS__)
#else
	c_initNL(L);
#endif
	a_initNL(L);
	n_initNL(L);
	fs_initNL(L);
	luaL_register(L, "tankbobs", tankbobs);
	return 1;
}
