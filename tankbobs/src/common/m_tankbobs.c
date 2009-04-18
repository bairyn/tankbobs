/*
Copyright (C) 2008 Byron James Johnson

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

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <SDL/SDL.h>
#include <SDL/SDL_image.h>
#include <SDL/SDL_mixer.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <luaconf.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <math.h>
#include <SDL/SDL_endian.h>
#include <zlib.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_GLYPH_H

#include "common.h"
#include "m_tankbobs.h"
#include "tstr.h"
#include "crossdll.h"

Uint8 init = false;

void t_init(lua_State *L)
{
}

int t_initialize(lua_State *L)
{
	int extra = lua_toboolean(L, -1);

	atexit(SDL_Quit);
	if(SDL_Init((extra ? (SDL_INIT_VIDEO | SDL_INIT_AUDIO) : 0) | SDL_INIT_TIMER) != 0)
	{
		tstr *message = CDLL_FUNCTION("tstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("tstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "Error initializing SDL: ");
		CDLL_FUNCTION("tstr", "tstr_cat", void(*)(tstr *, const char *))
			(message, SDL_GetError());
		CDLL_FUNCTION("tstr", "tstr_base_cat", void(*)(tstr *, const char *))
			(message, "\n");
		lua_pushstring(L, CDLL_FUNCTION("tstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("tstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	init = true;

	return 0;
}

int t_quit(lua_State *L)
{
	CHECKINIT(init, L);

	r_quitFreeType();

	return 0;
}

int t_getTicks(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushinteger(L, SDL_GetTicks());
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

static const struct luaL_Reg tankbobs[] =
{
	/* tankbobs.c */
	{"t_initialize", t_initialize}, /* initializes the module */
		/* init the module, return nothing, no args -  this must be called
			first */
	{"t_quit", t_quit}, /* clean up */
		/* no args, no returns, quits general module */
	{"t_getTicks", t_getTicks}, /* SDL_GetTicks() */
		/* no args, 1st and only return value is number of milliseconds since
			app start (note that this value may wrap over every week) */
	{"t_isDebug", t_isDebug}, /* if debugging is enabled, return true, if not, return false */

	/* input.c */
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

	/* io.c */
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

	/* renderer.c */
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
	{"r_newFont", r_newFont}, /* get a new font */
		/* 1st arg is string of ttf filename, only return
			is the font userdata */
	{"r_freeFont", r_freeFont}, /* free a font */
		/* no return, 1st and only arg is userdata of font */
	{"r_drawCharacter", r_drawCharacter}, /* render a character */
		/* first arg is x, 2nd y, 3rd w, 4th h, 5th is font, 6th is character to
			draw.  No returns */
	{"in_grabClear", in_grabClear}, /* frees and shows cursor */
		/* no args, no returns, frees and shows cursor */
	{"in_grabMouse", in_grabMouse}, /* grabs and hides cursor */
		/* 1st arg is width of window, 2nd arg is height, no returns, grabs and
			hides cursor */
	{"in_isGrabbed", in_isGrabbed}, /* is cursor grabbed */
		/* no args, 1 and only return is boolean of whether or not cursor is
			grabbed */

	/* math.c */
	{"m_vec2", m_vec2}, /* new vector */
		/* no arguments are passed; the vector is returned */
	{"m_radians", m_radians}, /* convert from degrees to radians */
		/* the 1st argument is the degrees; the radians is returned */
	{NULL, NULL}
};

int luaopen_tankbobs(lua_State *L)
{
	t_init(L);
	in_init(L);
	io_init(L);
	r_init(L);
	m_init(L);
	luaL_register(L, "tankbobs", tankbobs);
	return 1;
}
