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
#define ALIGNMENT 4

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

#define io8_t io8t
typedef uint8_t io8t;

#define io64_t io64t
typedef uint64_t io64tv;
typedef union io64u io64t;
union io64u
{
	io8t bytes[8];
	io64tv integer;
	double value;

#ifdef __cplusplus
	io64u(const io64tv& d)
	{
		this->integer = d;
	}
#endif
};

#define io32_t io32t
typedef uint32_t io32tv;
typedef union io32u io32t;
union io32u
{
	io8t bytes[4];
	io32tv integer;
	float value;

#ifdef __cplusplus
	io32u(const io32tv& d)
	{
		this->integer = d;
	}
#endif
};

#define io16_t io16t
typedef uint16_t io16tv;
typedef union io16u io16t;
union io16u
{
	io8t bytes[2];
	io16tv integer;

#ifdef __cplusplus
	io16u(const io16tv& d)
	{
		this->integer = d;
	}
#endif
};

int io_fromFloat(lua_State *L);
int io_fromDouble(lua_State *L);

int io_intNL(io32t integer);
short io_shortNL(io16t integer);
char io_charNL(io8t integer);
float io_floatNL(io32t number);
double io_doubleNL(io64t number);

int io_getIntNL(const void *base, const size_t offset);
short io_getShortNL(const void *base, const size_t offset);
char io_getCharNL(const void *base, const size_t offset);
float io_getFloatNL(const void *base, const size_t offset);
double io_getDoubleNL(const void *base, const size_t offset);
void io_setIntNL(const void *base, const size_t offset, io32t integer);
void io_setShortNL(const void *base, const size_t offset, io16t integer);
void io_setCharNL(const void *base, const size_t offset, io8t integer);
void io_setFloatNL(const void *base, const size_t offset, io32t number);
void io_setDoubleNL(const void *base, const size_t offset, io64t number);

/* macros to avoid casts */
#ifdef __cplusplus
#define IO_SETINTNL(a, b, c)   io_setIntNL((a), (b), static_cast<io32t> (static_cast<io32tv> (c)))
#define IO_SETSHORTNL(a, b, c)  io_setShortNL((a), (b), static_cast<io16t> (static_cast<io16tv> (c)))
#define IO_SETCHARNL(a, b, c)   io_setCharNL((a), (b), (io8t) (c))
#define IO_SETFLOATNL(a, b, c)  io_setFloatNL((a), (b), static_cast<io32t> (static_cast<io32tv> (c)))
#define IO_SETDOUBLENL(a, b, c) io_setDoubleNL((a), (b), static_cast<io64t> (static_cast<io64tv> (c)))
#else
#define IO_SETINTNL(a, b, c)   io_setIntNL((a), (b), (io32t) ((io32tv) (c)))
#define IO_SETSHORTNL(a, b, c)  io_setShortNL((a), (b), (io16t) ((io16tv) (c)))
#define IO_SETCHARNL(a, b, c)   io_setCharNL((a), (b), (io8t) (c))
#define IO_SETFLOATNL(a, b, c)  io_setFloatNL((a), (b), (io32t) ((io32tv) (c)))
#define IO_SETDOUBLENL(a, b, c) io_setDoubleNL((a), (b), (io64t) ((io64tv) (c)))
#endif
/* keep things consistent */
#define IO_GETINTNL io_getIntNL
#define IO_GETSHORTNL io_getShortNL
#define IO_GETCHARNL io_getCharNL
#define IO_GETFLOATNL io_getFloatNL
#define IO_GETDOUBLENL io_getDoubleNL

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
#define C_PRINTNL(L, s) \
do \
{ \
	lua_pushcfunction((L), c_print); \
	lua_pushstring((L), (s)); \
	lua_call((L), 1, 0); \
} while(0)
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
