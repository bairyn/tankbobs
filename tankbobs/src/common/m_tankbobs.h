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

#define BUFSIZE 1024

extern int init;

/* m_tankbobs.c */
void t_init(lua_State *L);
int t_initialize(lua_State *L);
int t_quit(lua_State *L);
int t_quitSDL(lua_State *L);
int t_getTicks(lua_State *L);
int t_delay(lua_State *L);
int t_isDebug(lua_State *L);
int t_is64Bit(lua_State *L);
int t_isWindows(lua_State *L);
int t_implode(lua_State *L);
int t_explode(lua_State *L);
int t_clone(lua_State *L);
void t_emptyTable(lua_State *L, int tableIndex);

/* m_input.c */
void in_init(lua_State *L);
int in_getEvents(lua_State *L);
int in_getEventData(lua_State *L);
int in_nextEvent(lua_State *L);
int in_freeEvents(lua_State *L);
int in_grabClear(lua_State *L);
int in_grabMouse(lua_State *L);
int in_isGrabbed(lua_State *L);
int in_getKeys(lua_State *L);
int in_keyPressed(lua_State *L);

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
int io_toInt(lua_State *L);
int io_toShort(lua_State *L);
int io_toChar(lua_State *L);
int io_toFloat(lua_State *L);
int io_toDouble(lua_State *L);
int io_fromInt(lua_State *L);
int io_fromShort(lua_State *L);
int io_fromChar(lua_State *L);
int io_fromFloat(lua_State *L);
int io_fromDouble(lua_State *L);

int io_intNL(int integer);
short io_shortNL(short integer);
char io_charNL(char integer);
float io_floatNL(float number);
double io_doubleNL(double number);

/* m_renderer.c */
void r_init(lua_State *L);
int r_initialize(lua_State *L);
int r_checkRenderer(lua_State *L);
int r_newWindow(lua_State *L);
int r_ortho2D(lua_State *L);
int r_swapBuffers(lua_State *L);
int r_newFont(lua_State *L);
int r_selectFont(lua_State *L);
int r_fontName(lua_State *L);
int r_fontFilename(lua_State *L);
int r_fontSize(lua_State *L);
int r_drawString(lua_State *L);
int r_freeFont(lua_State *L);
int r_drawCharacter(lua_State *L);
void r_quitFont(void);
int r_loadImage2D(lua_State *L);

/* m_math.c */
#define MATH_METATABLE "tankbobs.vec2Meta"

#ifdef __cplusplus
#define CHECKVEC(L, i) reinterpret_cast<vec2_t *>(luaL_checkudata(L, i, MATH_METATABLE))
#else
#define CHECKVEC(L, i) (vec2_t *) luaL_checkudata(L, i, MATH_METATABLE)
#endif

#define ISVEC(L, i) (lua_touserdata(L, i) && (lua_getmetatable(L, i) ? (lua_getfield(L, LUA_REGISTRYINDEX, MATH_METATABLE), (lua_rawequal(L, -1, -2) ? (lua_pop(L, 2), true) : (lua_pop(L, 2), false))) : (lua_pop(L, 1), false)))

#define MATH_POLAR(v) \
do \
{ \
	(v).R = sqrt((v).x * (v).x + (v).y * (v).y); \
	if((v).x == 0.0 && (v).y == 0.0) \
		(v).t = m_radiansNL(0); \
	else \
		(v).t = atan2((v).y, (v).x); \
} while(0)

#define MATH_RECTANGULAR(v) \
do \
{ \
	(v).x = (v).R * cos((v).t); \
	(v).y = (v).R * sin((v).t); \
} while(0)

#define MATH_RECTANGLE

typedef struct vec2_s vec2_t;
struct vec2_s
{
	double x;
	double y;
	double R;
	double t;
};

#define CLOCKWISE 1
#define COUNTERCLOCKWISE 2

#ifndef M_PI
#define M_PI 3.1415926535897932
#endif

void m_orderVertices(const vec2_t *vertices[], int numVertices, int dir);
double m_degreesNL(double radians);
double m_radiansNL(double degrees);

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
void w_init(lua_State *L);
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
int w_scaleVelocity(lua_State *L);
int w_persistWorld(lua_State *L);
int w_unpersistWorld(lua_State *L);
int w_getVertices(lua_State *L);
int w_getContents(lua_State *L);
int w_getClipmask(lua_State *L);
int w_getIndex(lua_State *L);
int w_setIndex(lua_State *L);
int w_luaStep(lua_State *L);

/* m_console.c */
void c_initNL(lua_State *L);
int c_init(lua_State *L);
int c_quit(lua_State *L);
int c_input(lua_State *L);
int c_setTabFunction(lua_State *L);
int c_print(lua_State *L);
int c_setHistoryFile(lua_State *L);
int c_loadHistory(lua_State *L);
int c_saveHistory(lua_State *L);

/* m_audio.c */
void a_initNL(lua_State *L);
int a_init(lua_State *L);
int a_quit(lua_State *L);
int a_initSound(lua_State *L);
int a_freeSound(lua_State *L);
int a_startMusic(lua_State *L);
int a_pauseMusic(lua_State *L);
int a_stopMusic(lua_State *L);
int a_playSound(lua_State *L);
int a_setMusicVolume(lua_State *L);
int a_setVolume(lua_State *L);
int a_setVolumeChunk(lua_State *L);

/* m_net.c */
void n_initNL(lua_State *L);
int n_init(lua_State *L);
int n_quit(lua_State *L);
int n_newPacket(lua_State *L);
int n_writeToPacket(lua_State *L);
int n_setPort(lua_State *L);
int n_sendPacket(lua_State *L);
int n_readPacket(lua_State *L);

#ifdef __cplusplus
}
#endif

#endif
