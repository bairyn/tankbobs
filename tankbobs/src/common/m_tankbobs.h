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

#ifdef __cplusplus
extern "C"
{
#endif

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
int r_loadImage2D(lua_State *L);

/* m_math.c */
#define MATH_METATABLE "tankbobs.vec2Meta"

#ifdef __cplusplus
#define CHECKVEC(L, i) reinterpret_cast<vec2_t *>(luaL_checkudata(L, i, MATH_METATABLE))
#else
#define CHECKVEC(L, i) (vec2_t *) luaL_checkudata(L, i, MATH_METATABLE)
#endif

typedef struct vec2_s vec2_t;
struct vec2_s
{
	double x;
	double y;
	double R;
	double t;
};

#define SWAP_VEC2S(v0, v1) \
do \
{ \
	if(v0->x != v1->x || v0->y != v1->y) \
	{ \
		const vec2_t *tmp = v1; \
		v1 = v0; \
		v0 = tmp; \
	} \
} while(0)

#define CLOCKWISE 1
#define COUNTERCLOCKWISE 2

void m_orderVertices(const vec2_t *vertices[], int numVertices, int dir);

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
int m_vec2_normalto(lua_State *L);
int m_vec2_project(lua_State *L);

/* m_world.cpp */
int w_step(lua_State *L);
int w_newWorld(lua_State *L);
int w_freeWorld(lua_State *L);
int w_getTimeStep(lua_State *L);
int w_setTimeStep(lua_State *L);
int w_getIterations(lua_State *L);
int w_setIterations(lua_State *L);
int w_addBody(lua_State *L);
int w_removeBody(lua_State *L);
int w_bodies(lua_State *L);
int w_isBullet(lua_State *L);
int w_setBullet(lua_State *L);
int w_isStatic(lua_State *L);
int w_isDynamic(lua_State *L);
int w_isSleeping(lua_State *L);
int w_allowSleeping(lua_State *L);
int w_wakeUp(lua_State *L);
int w_getPosition(lua_State *L);
int w_getAngle(lua_State *L);
int w_setLinearVelocity(lua_State *L);
int w_getLinearVelocity(lua_State *L);
int w_setAngularVelocity(lua_State *L);
int w_getAngularVelocity(lua_State *L);
int w_setPosition(lua_State *L);
int w_setAngle(lua_State *L);
int w_applyForce(lua_State *L);
int w_applyTorque(lua_State *L);
int w_applyImpulse(lua_State *L);
int w_getCenterOfMass(lua_State *L);

#ifdef __cplusplus
}
#endif

#endif
