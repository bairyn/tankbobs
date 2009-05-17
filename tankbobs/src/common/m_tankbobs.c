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

	r_quitFreeType();

	return 0;
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

#if defined (_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WINDOWS__) || defined(__WINDOWS__)
	lua_pushboolean(L, true);
#else
	lua_pushboolean(L, false);
#endif
	return 1;
}

int t_testAND(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushboolean(L, (luaL_checkinteger(L, 1)) & (luaL_checkinteger(L, 2)));
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
			app start */
	{"t_delay", t_delay}, /* SDL_Delay() */
		/* 1st arg is the ms to delay.  Nothing is returned. */
	{"t_isDebug", t_isDebug}, /* if debugging is enabled, return true, if not, return false */
	{"t_testAND", t_testAND}, /* test two integers (both are arguments) and return the bool of & */
	{"t_is64Bit", t_is64Bit}, /* if the machine is running 64-bit, return true, if not, return false */
	{"t_isWindows", t_isWindows}, /* if the machine is running Windows, return true, if not, return false */

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
	{"in_grabClear", in_grabClear}, /* frees and shows cursor */
		/* no args, no returns, frees and shows cursor */
	{"in_grabMouse", in_grabMouse}, /* grabs and hides cursor */
		/* 1st arg is width of window, 2nd arg is height, no returns, grabs and
			hides cursor */
	{"in_isGrabbed", in_isGrabbed}, /* is cursor grabbed */
		/* no args, 1 and only return is boolean of whether or not cursor is
			grabbed */

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
	{"r_loadImage2D", r_loadImage2D}, /* load an image into the currently bound 2D texture */
		/* the first argument passed is the filename of the image to be loaded.  The second
			argument is the filename of the default image to load if the first image
			couldn't be loaded.  Nothing is returned */

	/* math.c */
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

	/* world.c */
	{"w_step", w_step}, /* world step */
		/* Nothing is returned or passed */
	{"w_newWorld", w_newWorld}, /* initialize a new world */
		/* nothing is returned; the first argument is a vector of the lower bounds.  The second
			argument is of the upper bounds.  The third argument is the gravity vector (should always
			be a zero-factor.  The fourth argument is a boolean of whether bodies can sleep.
			The fifth argument is the function to call on contact (f(shape1, shape2, body1, body2, position, separation, normal)). */
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
			linear and angular daming.
			The seventh argument is a table of the vertices *relative to the position
			of the body.  The eighth argument is the shape's density.  The ninth is the friction.
			The tenth is the restitution.  The eleventh argument is whether the body to be added is static.
			A pointer to the body to use for other functions is the only value returned.
			The returned value can be safely ignored. */
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

	{NULL, NULL}
};

int luaopen_libmtankbobs(lua_State *L)
{
	t_init(L);
	in_init(L);
	io_init(L);
	r_init(L);
	m_init(L);
	luaL_register(L, "tankbobs", tankbobs);
	return 1;
}
