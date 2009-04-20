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

#ifndef TANKBOBS_H
#define TANKBOBS_H

#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <luaconf.h>
#include <stdio.h>

#include "common.h"

#if defined(__FILE) && defined(__LINE) && defined(TDEBUG)
#define CHECKINIT(i, L)                                                            \
do                                                                                 \
{                                                                                  \
	if(!i)                                                                         \
	{                                                                              \
		char buf[1024];                                                            \
		sprintf(buf, "module used before module initialization on line %d of %s.", \
			__LINE, __FILE);                                                       \
		lua_pushstring(L, buf);                                                    \
		lua_error(L);                                                              \
	}                                                                              \
} while(0)
#elif defined(__FILE__) && defined(__LINE__) && defined(TDEBUG)
#define CHECKINIT(i, L)                                                            \
do                                                                                 \
{                                                                                  \
	if(!i)                                                                         \
	{                                                                              \
		char buf[1024];                                                            \
		sprintf(buf, "module used before module initialization on line %d of %s.", \
			__LINE__, __FILE__);                                                   \
		lua_pushstring(L, buf);                                                    \
		lua_error(L);                                                              \
	}                                                                              \
} while(0)
#else
#define CHECKINIT(i, L)                                                            \
do                                                                                 \
{                                                                                  \
	if(!i)                                                                         \
	{                                                                              \
		lua_pushstring(L, "module used before module initialization.");            \
		lua_error(L);                                                              \
	}                                                                              \
} while(0)
#endif

/* m_tankbobs.c */
void t_init(lua_State *L);
int t_initialize(lua_State *L);
int t_quit(lua_State *L);
int t_getTicks(lua_State *L);

/* m_input.c */
void in_init(lua_State *L);
int in_getEvents(lua_State *L);
int in_getEventData(lua_State *L);
int in_nextEvent(lua_State *L);
int in_freeEvents(lua_State *L);
int in_grabClear(lua_State *L);
int in_grabMouse(lua_State *L);
int in_isGrabbed(lua_State *L);

/* m_io.c */
void io_init(lua_State *L);
int io_getHomeDirectory(lua_State *L);
int io_getInt(lua_State *L);
int io_getShort(lua_State *L);
int io_getChar(lua_State *L);
int io_getFloat(lua_State *L);
int io_getDouble(lua_State *L);
int io_getStr(lua_State *L);
int io_getStrL(lua_State *L);

/* m_renderer.c */
void r_init(lua_State *L);
int r_initialize(lua_State *L);
int r_checkRenderer(lua_State *L);
int r_newWindow(lua_State *L);
int r_ortho2D(lua_State *L);
int r_swapBuffers(lua_State *L);
int r_newFont(lua_State *L);
int r_freeFont(lua_State *L);
int r_drawCharacter(lua_State *L);
void r_quitFreeType(void);

/* m_math.c */
void m_init(lua_State *L);
int m_vec2(lua_State *L);
int m_vec2_index(lua_State *L);
int m_vec2_newindex(lua_State *L);
int m_vec2_unify(lua_State *L);
int m_vec2_unit(lua_State *L);
int m_vec2___add(lua_State *L);
int m_vec2_add(lua_State *L);
int m_vec2___sub(lua_State *L);
int m_vec2_sub(lua_State *L);
int m_vec2___mul(lua_State *L);
int m_vec2_mul(lua_State *L);
int m_vec2___div(lua_State *L);
int m_vec2_div(lua_State *L);
int m_vec2_unm(lua_State *L);
int m_vec2_len(lua_State *L);
int m_vec2_call(lua_State *L);
int m_vec2_inv(lua_State *L);
int m_radians(lua_State *L);
int m_degrees(lua_State *L);
int m_edge(lua_State *L);
int m_line(lua_State *L);
int m_polygon(lua_State *L);

#endif
