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

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <SDL/SDL.h>
#include <SDL/SDL_image.h>
#include <SDL/SDL_mixer.h>
#include <SDL/SDL_endian.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <luaconf.h>
#include <math.h>

#include "common.h"
#include "m_tankbobs.h"
#include "tstr.h"
#include "crossdll.h"

extern Uint8 init;

static const struct luaL_Reg m_vec2_m[] =
{
	{"__index", m_vec2_index},
	{"__newindex", m_vec2_newindex},
	{"unify", m_vec2_unify},
		{"normalize", m_vec2_unify},
	{"unit", m_vec2_unit},
	{"__add", m_vec2___add},
	{"add", m_vec2_add},
	{"__sub", m_vec2___sub},
	{"sub", m_vec2_sub},
	{"__mul", m_vec2___mul},
	{"mul", m_vec2_mul},
	{"__div", m_vec2___div},
	{"div", m_vec2_div},
	{"__len", m_vec2_len},
	{"__call", m_vec2_call},
	{"__unm", m_vec2_unm},
	{"inv", m_vec2_inv},
	{"normalto", m_vec2_normalto},  /* returns a new vector; the vector returned is a normalised vector */
		{"normalof", m_vec2_normalto},
	{"project", m_vec2_project},  /* takes two vectors as arguments and returns a new vector.  Like before, the original vectors passed remain unmodified.  The second argument might be used as a wall against which the first vector is projected */
	{NULL, NULL}
};

void m_init(lua_State *L)
{
	if(!(luaL_newmetatable(L, MATH_METATABLE)))
	{
		tstr *message = CDLL_FUNCTION("tstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("tstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "Error setting vector userdata metatable: ");
		CDLL_FUNCTION("tstr", "tstr_cat", void(*)(tstr *, const char *))
			(message, MATH_METATABLE);
		CDLL_FUNCTION("tstr", "tstr_base_cat", void(*)(tstr *, const char *))
			(message, "\n");
		lua_pushstring(L, CDLL_FUNCTION("tstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("tstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	luaL_register(L, NULL, m_vec2_m);
}

double m_degreesNL(double radians)
{
	return radians * 180 / M_PI;
}

double m_radiansNL(double degrees)
{
	return degrees * M_PI / 180;
}

int m_vec2(lua_State *L)  /* similar to c_math.lua's vec2:new() but can take arguments for initialization */
{
	vec2_t *v;

	CHECKINIT(init, L);

	if(lua_isnumber(L, 1) && lua_isnumber(L, 2))
	{
		/* new vec2 with rectangular coordinates */
		v = lua_newuserdata(L, sizeof(vec2_t));

		v->x = lua_tonumber(L, 1);
		v->y = lua_tonumber(L, 2);
		v->R = sqrt(v->x * v->x + v->y * v->y);
		v->t = atan(v->y / v->x);
		if(v->x < 0.0 && v->y < 0.0)
			v->t += m_radiansNL(180);
		else if(v->x < 0.0)
			v->t += m_radiansNL(90);
		else if(v->y < 0.0)
			v->t += m_radiansNL(270);
	}
	else if(lua_isuserdata(L, 1))
	{
		/* new vec2 - clone of another */
		vec2_t *v2 = CHECKVEC(L, 1);

		v = lua_newuserdata(L, sizeof(vec2_t));

		v->x = v2->x;
		v->y = v2->y;
		v->R = v2->R;
		v->t = v2->t;
	}
	else
	{
		/* new vec2 */
		v = lua_newuserdata(L, sizeof(vec2_t));

		v->x = 0.0;
		v->y = 0.0;
		v->R = 0.0;
		v->t = 0.0;
	}

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	return 1;
}

int m_radians(lua_State *L)
{
	lua_pushnumber(L, luaL_checknumber(L, 1) * M_PI / 180);

	return 1;
}

int m_degrees(lua_State *L)
{
	lua_pushnumber(L, luaL_checknumber(L, 1) * 180 / M_PI);

	return 1;
}

int m_vec2_index(lua_State *L)
{
	const vec2_t *v;
	char index;
	const char *index_s;
	tstr *message;

	CHECKINIT(init, L);

	v = CHECKVEC(L, 1);
	index_s = luaL_checkstring(L, 2);
	index = *index_s;
	if(index == 'v')
		index = *(index_s + 1);

	switch(index)
	{
		case 'x':
			lua_pushnumber(L, v->x);
			return 1;
			break;

		case 'y':
			lua_pushnumber(L, v->y);
			return 1;
			break;

		case 'R':
			lua_pushnumber(L, v->R);
			return 1;
			break;

		case 't':
			lua_pushnumber(L, v->t);
			return 1;
			break;

		default:
			luaL_getmetatable(L, MATH_METATABLE);
			lua_getfield(L, -1, index_s);
			lua_remove(L, -2);
			if(!lua_isnoneornil(L, -1))
			{
				return 1;
			}
			else
			{
				lua_pop(L, 1);
				message = CDLL_FUNCTION("tstr", "tstr_new", tstr *(*)(void))
					();
				CDLL_FUNCTION("tstr", "tstr_base_set", void(*)(tstr *, const char *))
					(message, "m_vec2_index: invalid index for vec2: ");
				CDLL_FUNCTION("tstr", "tstr_cat", void(*)(tstr *, const char *))
					(message, index_s);
				CDLL_FUNCTION("tstr", "tstr_base_cat", void(*)(tstr *, const char *))
					(message, "\n");
				lua_pushstring(L, CDLL_FUNCTION("tstr", "tstr_cstr", const char *(*)(tstr *))
					(message));
				CDLL_FUNCTION("tstr", "tstr_free", void(*)(tstr *))
					(message);
				lua_error(L);
			}
			break;
	}

	return 0;
}

int m_vec2_newindex(lua_State *L)
{
	vec2_t *v;
	char index;
	double val;
	tstr *message;

	CHECKINIT(init, L);

	v = CHECKVEC(L, 1);
	index = *luaL_checkstring(L, 2);
	val = luaL_checknumber(L, 3);
	if(index == 'v')
		index = *(luaL_checkstring(L, 2) + 1);

	switch(index)
	{
		case 'x':
			v->x = val;

			/* calculate polar coordinates */
			v->R = sqrt(v->x * v->x + v->y * v->y);
			v->t = atan(v->y / v->x);
			if(v->x < 0.0 && v->y < 0.0)
				v->t += m_radiansNL(180);
			else if(v->x < 0.0)
				v->t += m_radiansNL(90);
			else if(v->y < 0.0)
				v->t += m_radiansNL(270);

			return 0;
			break;

		case 'y':
			v->y = val;

			/* calculate polar coordinates */
			v->R = sqrt(v->x * v->x + v->y * v->y);
			v->t = atan(v->y / v->x);
			if(v->x < 0.0 && v->y < 0.0)
				v->t += m_radiansNL(180);
			else if(v->x < 0.0)
				v->t += m_radiansNL(90);
			else if(v->y < 0.0)
				v->t += m_radiansNL(270);

			return 0;
			break;

		case 'R':
			v->R = val;

			/* calculate rectangular coordinates */
			v->x = v->R * cos(v->t);
			v->y = v->R * sin(v->t);

			return 0;
			break;

		case 't':
			v->t = val;

			/* calculate rectangular coordinates */
			v->x = v->R * cos(v->t);
			v->y = v->R * sin(v->t);

			return 0;
			break;

		default:
			message = CDLL_FUNCTION("tstr", "tstr_new", tstr *(*)(void))
				();
			CDLL_FUNCTION("tstr", "tstr_base_set", void(*)(tstr *, const char *))
				(message, "m_vec2_newindex: invalid index for vec2: ");
			CDLL_FUNCTION("tstr", "tstr_cat", void(*)(tstr *, const char *))
				(message, luaL_checkstring(L, 2));
			CDLL_FUNCTION("tstr", "tstr_base_cat", void(*)(tstr *, const char *))
				(message, "\n");
			lua_pushstring(L, CDLL_FUNCTION("tstr", "tstr_cstr", const char *(*)(tstr *))
				(message));
			CDLL_FUNCTION("tstr", "tstr_free", void(*)(tstr *))
				(message);
			lua_error(L);
			break;
	}

	return 0;
}

int m_vec2_unify(lua_State *L)
{
	vec2_t *v;

	CHECKINIT(init, L);

	v = CHECKVEC(L, 1);

	v->R = 1.0;

	/* calculate rectangular coordinates */
	v->x = v->R * cos(v->t);
	v->y = v->R * sin(v->t);

	return 0;
}

int m_vec2_unit(lua_State *L)
{
	vec2_t *v;
	const vec2_t *v2;

	CHECKINIT(init, L);

	v = lua_newuserdata(L, sizeof(vec2_t));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v2 = CHECKVEC(L, 1);

	v->t = v2->t;
	v->R = 1.0;

	/* calculate rectangular coordinates */
	v->x = v->R * cos(v2->t);
	v->y = v->R * sin(v2->t);

	return 1;
}

int m_vec2___add(lua_State *L)
{
	vec2_t *v;
	const vec2_t *v2, *v3;

	CHECKINIT(init, L);

	v2 = CHECKVEC(L, 1);
	v3 = CHECKVEC(L, 2);

	v = lua_newuserdata(L, sizeof(vec2_t));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v->x = v2->x + v3->x;
	v->y = v2->y + v3->y;

	/* calculate polar coordinates */
	v->R = sqrt(v->x * v->x + v->y * v->y);
	v->t = atan(v->y / v->x);
	if(v->x < 0.0 && v->y < 0.0)
		v->t += m_radiansNL(180);
	else if(v->x < 0.0)
		v->t += m_radiansNL(90);
	else if(v->y < 0.0)
		v->t += m_radiansNL(270);

	return 1;
}

int m_vec2_add(lua_State *L)
{
	vec2_t *v;
	const vec2_t *v2;

	CHECKINIT(init, L);

	v = CHECKVEC(L, 1);
	v2 = CHECKVEC(L, 2);

	v->x += v2->x;
	v->y += v2->y;

	/* calculate polar coordinates */
	v->R = sqrt(v->x * v->x + v->y * v->y);
	v->t = atan(v->y / v->x);
	if(v->x < 0.0 && v->y < 0.0)
		v->t += m_radiansNL(180);
	else if(v->x < 0.0)
		v->t += m_radiansNL(90);
	else if(v->y < 0.0)
		v->t += m_radiansNL(270);

	return 0;
}

int m_vec2___sub(lua_State *L)
{
	vec2_t *v;
	const vec2_t *v2, *v3;

	CHECKINIT(init, L);

	v2 = CHECKVEC(L, 1);
	v3 = CHECKVEC(L, 2);

	v = lua_newuserdata(L, sizeof(vec2_t));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v->x = v2->x - v3->x;
	v->y = v2->y - v3->y;

	/* calculate polar coordinates */
	v->R = sqrt(v->x * v->x + v->y * v->y);
	v->t = atan(v->y / v->x);
	if(v->x < 0.0 && v->y < 0.0)
		v->t += m_radiansNL(180);
	else if(v->x < 0.0)
		v->t += m_radiansNL(90);
	else if(v->y < 0.0)
		v->t += m_radiansNL(270);

	return 1;
}

int m_vec2_sub(lua_State *L)
{
	vec2_t *v;
	const vec2_t *v2;

	CHECKINIT(init, L);

	v = CHECKVEC(L, 1);
	v2 = CHECKVEC(L, 2);

	v->x -= v2->x;
	v->y -= v2->y;

	/* calculate polar coordinates */
	v->R = sqrt(v->x * v->x + v->y * v->y);
	v->t = atan(v->y / v->x);
	if(v->x < 0.0 && v->y < 0.0)
		v->t += m_radiansNL(180);
	else if(v->x < 0.0)
		v->t += m_radiansNL(90);
	else if(v->y < 0.0)
		v->t += m_radiansNL(270);

	return 0;
}

int m_vec2___mul(lua_State *L)
{
	vec2_t *v;
	const vec2_t *v2, *v3;
	double scalar;

	CHECKINIT(init, L);

	if(lua_isnumber(L, 1))
	{
		/* scalar multiplication */
		v2 = CHECKVEC(L, 2);
		scalar = lua_tonumber(L, 1);

		v = lua_newuserdata(L, sizeof(vec2_t));

		luaL_getmetatable(L, MATH_METATABLE);
		lua_setmetatable(L, -2);

		v->x = v2->x * scalar;
		v->y = v2->y * scalar;
		v->R = v2->R * scalar;
	}
	else if(lua_isnumber(L, 2))
	{
		/* scalar multiplication */
		v2 = CHECKVEC(L, 1);
		scalar = lua_tonumber(L, 2);

		v = lua_newuserdata(L, sizeof(vec2_t));

		luaL_getmetatable(L, MATH_METATABLE);
		lua_setmetatable(L, -2);

		v->x = v2->x * scalar;
		v->y = v2->y * scalar;
		v->R = v2->R * scalar;
	}
	else
	{
		/* dot product */
		v2 = CHECKVEC(L, 1);
		v3 = CHECKVEC(L, 2);
		lua_pushnumber(L, v2->x * v3->x + v2->y * v3->y);
	}

	return 1;
}

int m_vec2_mul(lua_State *L)
{
	vec2_t *v;
	double scalar;

	CHECKINIT(init, L);

	/* scalar multiplication only */
	v = CHECKVEC(L, 1);
	scalar = luaL_checknumber(L, 2);

	v->x *= scalar;
	v->y *= scalar;
	v->R *= scalar;

	return 0;
}

int m_vec2___div(lua_State *L)
{
	vec2_t *v;
	const vec2_t *v2;
	double scalar;

	CHECKINIT(init, L);

	/* scalar division only */
	if(lua_isnumber(L, 1))
	{
		v2 = CHECKVEC(L, 2);
		scalar = lua_tonumber(L, 1);

		v = lua_newuserdata(L, sizeof(vec2_t));

		luaL_getmetatable(L, MATH_METATABLE);
		lua_setmetatable(L, -2);

		v->x = v2->x * scalar;
		v->y = v2->y * scalar;
		v->R = v2->R * scalar;
	}
	else
	{
		v2 = CHECKVEC(L, 1);
		scalar = lua_tonumber(L, 2);

		v = lua_newuserdata(L, sizeof(vec2_t));

		luaL_getmetatable(L, MATH_METATABLE);
		lua_setmetatable(L, -2);

		v->x = v2->x * scalar;
		v->y = v2->y * scalar;
		v->R = v2->x * scalar;
	}

	return 1;
}

int m_vec2_div(lua_State *L)
{
	vec2_t *v;
	double scalar;

	CHECKINIT(init, L);

	/* scalar division only */
	v = CHECKVEC(L, 1);
	scalar = luaL_checknumber(L, 2);

	v->x /= scalar;
	v->y /= scalar;
	v->R /= scalar;

	return 0;
}

int m_vec2_len(lua_State *L)
{
	const vec2_t *v;

	CHECKINIT(init, L);

	v = CHECKVEC(L, 1);

	lua_pushnumber(L, v->R);

	return 1;
}

int m_vec2_call(lua_State *L)
{
	vec2_t *v;
	const vec2_t *v2;

	CHECKINIT(init, L);

	v = CHECKVEC(L, 1);

	if(lua_isnumber(L, 3))
	{
		/* set rectangular coordinates */
		v->x = luaL_checknumber(L, 2);
		v->y = lua_tonumber(L, 3);
	}
	else
	{
		/* clone / assignment */
		v2 = CHECKVEC(L, 2);

		v->x = v2->x;
		v->y = v2->y;
		v->R = v2->R;
		v->t = v2->t;
	}

	return 0;
}

int m_vec2_unm(lua_State *L)
{
	vec2_t *v;
	const vec2_t *v2;

	CHECKINIT(init, L);

	v2 = lua_newuserdata(L, sizeof(vec2_t));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v = CHECKVEC(L, 1);

	v->x = -v2->x;
	v->y = -v2->y;
	v->R = -v2->R;

	return 1;
}

int m_vec2_inv(lua_State *L)
{
	vec2_t *v;

	CHECKINIT(init, L);

	v = CHECKVEC(L, 1);

	v->x = -v->x;
	v->y = -v->y;
	v->R = -v->R;

	return 0;
}

#define TM_CW 1
#define TM_CCW -1

static inline int m_edge_triDir(const vec2_t *p1, const vec2_t *p2, const vec2_t *p3)
{
	double dir = (p2->x - p1->x) * (p3->y - p1->y) - (p3->x - p1->x) * (p2->y - p1->y);
	if(dir > 0) return TM_CW;
	if(dir < 0) return TM_CCW;
	return 0;
}

static inline int m_private_line(const vec2_t *l1p1, const vec2_t *l1p2, const vec2_t *l2p1, const vec2_t *l2p2)  /* non-Lua version */
{
	if(m_edge_triDir(l1p1, l1p2, l2p1) != m_edge_triDir(l1p1, l1p2, l2p2))  /* && */
	if(m_edge_triDir(l2p1, l2p2, l1p1) != m_edge_triDir(l2p1, l2p2, l1p2))
		return 1;

	return 0;
}

int m_line(lua_State *L)  /* algorithm, by Christopher Barlett, at http://angelfire.com/fl/houseofbarlett/solutions/lineinter2d.html */
{
	const vec2_t *l1p1, *l1p2, *l2p1, *l2p2;

	CHECKINIT(init, L);

	l1p1 = CHECKVEC(L, 1);
	l1p2 = CHECKVEC(L, 2);
	l2p1 = CHECKVEC(L, 3);
	l2p2 = CHECKVEC(L, 4);

	/* don't accept any 0-length lines */
	if((l1p1->x == l1p2->x && l1p1->y == l1p2->y) || (l2p1->x == l2p2->x && l2p1->y == l2p2->y))
	{
		lua_pushboolean(L, false);
		return 1;
	}

	if(m_edge_triDir(l1p1, l1p2, l2p1) != m_edge_triDir(l1p1, l1p2, l2p2))  /* && */
	if(m_edge_triDir(l2p1, l2p2, l1p1) != m_edge_triDir(l2p1, l2p2, l1p2))
	{
		lua_pushboolean(L, true);
		return 1;
	}

	lua_pushboolean(L, false);
	return 1;
}

int m_edge(lua_State *L)  /* algorithm, by Darel Rex Finley, 2006, can be found at http://alienryderflex.com/intersect/ */
{
	vec2_t *v;
	const vec2_t *l1p1, *l1p2, *l2p1, *l2p2;
	double l1p1x, l1p1y;
	double l1p2x, l1p2y;
	double l2p1x, l2p1y;
	double l2p2x, l2p2y;
	double l1c, l1s;
	double l1d;
	double x;
	double intersection;

	CHECKINIT(init, L);

	l1p1 = CHECKVEC(L, 1);
	l1p2 = CHECKVEC(L, 2);
	l2p1 = CHECKVEC(L, 3);
	l2p2 = CHECKVEC(L, 4);

	l1p1x = l1p1->x; l1p1y = l1p1->y;
	l1p2x = l1p2->x; l1p2y = l1p2->y;
	l2p1x = l2p1->x; l2p1y = l2p1->y;
	l2p2x = l2p2->x; l2p2y = l2p2->y;

	/* don't accept any 0-length lines */
	if((l1p1x == l1p2x && l1p1y == l1p2y) || (l2p1x == l2p2x && l2p1y == l2p2y))
	{
		lua_pushboolean(L, false);
		return 1;
	}

	/* algorithm might run into issues if we don't test for shared vertices */
	if(l1p1x == l2p1x && l1p1y == l2p1y)
	{
		v = lua_newuserdata(L, sizeof(vec2_t));

		luaL_getmetatable(L, MATH_METATABLE);
		lua_setmetatable(L, -2);

		v->x = l1p1x;
		v->y = l1p1y;
		v->R = sqrt(v->x * v->x + v->y * v->y);
		v->t = atan(v->y / v->x);
		if(v->x < 0.0 && v->y < 0.0)
			v->t += m_radiansNL(180);
		else if(v->x < 0.0)
			v->t += m_radiansNL(90);
		else if(v->y < 0.0)
			v->t += m_radiansNL(270);

		return 1;
	}
	else if(l1p1x == l2p2x && l1p1y == l2p2y)
	{
		v = lua_newuserdata(L, sizeof(vec2_t));

		luaL_getmetatable(L, MATH_METATABLE);
		lua_setmetatable(L, -2);

		v->x = l1p1x;
		v->y = l1p1y;
		v->R = sqrt(v->x * v->x + v->y * v->y);
		v->t = atan(v->y / v->x);
		if(v->x < 0.0 && v->y < 0.0)
			v->t += m_radiansNL(180);
		else if(v->x < 0.0)
			v->t += m_radiansNL(90);
		else if(v->y < 0.0)
			v->t += m_radiansNL(270);

		return 1;
	}
	else if(l1p2x == l2p1x && l1p2y == l2p1y)
	{
		v = lua_newuserdata(L, sizeof(vec2_t));

		luaL_getmetatable(L, MATH_METATABLE);
		lua_setmetatable(L, -2);

		v->x = l1p2x;
		v->y = l1p2y;
		v->R = sqrt(v->x * v->x + v->y * v->y);
		v->t = atan(v->y / v->x);
		if(v->x < 0.0 && v->y < 0.0)
			v->t += m_radiansNL(180);
		else if(v->x < 0.0)
			v->t += m_radiansNL(90);
		else if(v->y < 0.0)
			v->t += m_radiansNL(270);

		return 1;
	}
	else if(l1p2x == l2p2x && l1p2y == l2p2y)
	{
		v = lua_newuserdata(L, sizeof(vec2_t));

		luaL_getmetatable(L, MATH_METATABLE);
		lua_setmetatable(L, -2);

		v->x = l1p2x;
		v->y = l1p2y;
		v->R = sqrt(v->x * v->x + v->y * v->y);
		v->t = atan(v->y / v->x);
		if(v->x < 0.0 && v->y < 0.0)
			v->t += m_radiansNL(180);
		else if(v->x < 0.0)
			v->t += m_radiansNL(90);
		else if(v->y < 0.0)
			v->t += m_radiansNL(270);

		return 1;
	}

	/* no shared vertices */

	/* translate the lines so that l1p1 is on the origin */
	/* note that l1p1 itself isn't changed */
	l1p2x -= l1p1x; l1p2y -= l1p1y;
	l2p1x -= l1p1x; l2p1y -= l1p1y;
	l2p2x -= l1p1x; l2p2y -= l1p1y;

	/* find the sine and cosine of the line to prepare for rotation */
	l1d = sqrt(l1p2x * l1p2x + l1p2y * l1p2y);
	l1c = l1p2x / l1d;
	l1s = l1p2y / l1d;

	/* rotate the lines so that l1p2 lies on positive side of the X axis */
	x = l1c * l2p1x + l1s * l2p1y;
	l2p1y = l1c * l2p1y - l1s * l2p1x;
	l2p1x = x;
	x = l1c * l2p2x + l1s * l2p2y;
	l2p2y = l1c * l2p2y - l1s * l2p2x;
	l2p2x = x;
	/* save some speed by ignoring l1p2 because it isn't used in this function after this */

	/* if line 2 doesn't cross the X axis, then they don't intersect */
	if((l2p1y < 0.0 && l2p2y < 0.0) || (l2p1y > 0.0 && l2p2y > 0.0))
	{
		lua_pushboolean(L, false);
		return 1;
	}

	/* find the intersection along the X axis */
	intersection = l2p2x + (l2p1x - l2p2x) * l2p2y / (l2p2y - l2p1y);

	/* make sure the second line intersects the first line */
	if(intersection < 0.0 || intersection > l1d)
	{
		lua_pushboolean(L, false);
		return 1;
	}

	/* the lines intersect.  Push a vector of the coordinates of the intersection in the original coordinate system */

	lua_pushboolean(L, true);

	v = lua_newuserdata(L, sizeof(vec2_t));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	/* coordinates of intersection (remember that l1p1 remains untranslated) */
	v->x = l1p1x + l1c * intersection;
	v->y = l1p1y + l1s * intersection;

	/* calculate polar coordinates */
	v->R = sqrt(v->x * v->x + v->y * v->y);
	v->t = atan(v->y / v->x);
	if(v->x < 0.0 && v->y < 0.0)
		v->t += m_radiansNL(180);
	else if(v->x < 0.0)
		v->t += m_radiansNL(90);
	else if(v->y < 0.0)
		v->t += m_radiansNL(270);

	/* coordinates of intersection in transformed system */
	v = lua_newuserdata(L, sizeof(vec2_t));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v->y = v->t = 0.0;
	v->x = v->R = intersection;

	return 3;
}

#define MAX_VERTICES 12

int m_polygon(lua_State *L)  /* brute force line test; will NOT detect an intersection if one polygon lies entirely inside the other polygon */
{
	int i, j;

	CHECKINIT(init, L);

	{
		int num1 = ((lua_objlen(L, 1)) > (1) ? (lua_objlen(L, 1)) : (1));
		int num2 = ((lua_objlen(L, 2)) > (1) ? (lua_objlen(L, 2)) : (1));
		vec2_t *p1_b[MAX_VERTICES];
		vec2_t *p2_b[MAX_VERTICES];
		vec2_t **p1 = &p1_b[0];
		vec2_t **p2 = &p2_b[0];

		if(num1 > sizeof(p1_b))
			p1 = malloc(num1 * sizeof(vec2_t *));
		if(num2 > sizeof(p2_b))
			p2 = malloc(num2 * sizeof(vec2_t *));

		i = 0;
		lua_pushnil(L);
		while(lua_next(L, 1))
		{
			p1[i++] = CHECKVEC(L, -1);

			lua_pop(L, 1);
		}

		i = 0;
		lua_pushnil(L);
		while(lua_next(L, 2))
		{
			p2[i++] = CHECKVEC(L, -1);

			lua_pop(L, 1);
		}

		for(i = 1; i < num1; i++)
		{
			for(j = 1; j < num2; j++)
			{
				if(m_private_line(p1[i - 1], p1[i], p2[j - 1], p2[j]))
				{
					lua_pushboolean(L, true);

					return 1;
				}
			}
		}

		/* test the last line */
		if(m_private_line(p1[num1 - 1], p1[0], p2[num2 - 1], p2[0]))
		{
			lua_pushboolean(L, true);

			return 1;
		}

		if(num1 > sizeof(p1_b))
			free(p1);
		if(num2 > sizeof(p2_b))
			free(p2);
	}

	lua_pushboolean(L, false);

	return 1;
}

int m_vec2_normalto(lua_State *L)
{
	vec2_t *v;
	const vec2_t *v2;

	CHECKINIT(init, L);

	v2 = CHECKVEC(L, 1);

	v = lua_newuserdata(L, sizeof(vec2_t));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v->x = -v2->y / v2->R;
	v->y = v2->x / v2->R;
	v->R = 1.0;
	v->t = atan(v->y / v->x);
	if(v->x < 0.0 && v->y < 0.0)
		v->t += m_radiansNL(180);
	else if(v->x < 0.0)
		v->t += m_radiansNL(90);
	else if(v->y < 0.0)
		v->t += m_radiansNL(270);

	return 1;
}

int m_vec2_project(lua_State *L)
{
	vec2_t *v;
	const vec2_t *v2, *v3;
	double dot;

	CHECKINIT(init, L);

	v2 = CHECKVEC(L, 1);
	v3 = CHECKVEC(L, 2);

	v = lua_newuserdata(L, sizeof(vec2_t));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	/* r = (-(L1) * L2) * L2 */
	dot = (-v2->x * v3->x) + (-v2->y * v3->y);

	v->x = v3->x * dot;
	v->y = v3->y * dot;
	v->R = v3->R * dot;
	v->t = atan(v->y / v->x);
	if(v->x < 0.0 && v->y < 0.0)
		v->t += m_radiansNL(180);
	else if(v->x < 0.0)
		v->t += m_radiansNL(90);
	else if(v->y < 0.0)
		v->t += m_radiansNL(270);

	return 1;
}

// this function assumes that the vertices are already ordered either in a clockwise order or a counterclockwise order.  This function alsa assumes that the polygon is convex
void m_orderVertices(const vec2_t *vertices[], int numVertices, int dir)
{
	vec2_t v0, v1;
	int currentDir;
	int i;

	if(numVertices < 3)
		return;

	v0.x = vertices[0]->x - vertices[1]->x; v0.y = vertices[0]->y - vertices[1]->y;
	v0.R = sqrt(v0.x * v0.x + v0.y * v0.y);
	v0.t = atan(v0.y / v0.x);
	if(v0.x < 0.0 && v0.y < 0.0)
		v0.t += m_radiansNL(180);
	else if(v0.x < 0.0)
		v0.t += m_radiansNL(90);
	else if(v0.y < 0.0)
		v0.t += m_radiansNL(270);

	v1.x = vertices[1]->x - vertices[2]->x; v1.y = vertices[1]->y - vertices[2]->y;
	v1.R = sqrt(v1.x * v1.x + v1.y * v1.y);
	v1.t = atan(v1.y / v1.x);
	if(v1.x < 0.0 && v1.y < 0.0)
		v1.t += m_radiansNL(180);
	else if(v1.x < 0.0)
		v1.t += m_radiansNL(90);
	else if(v1.y < 0.0)
		v1.t += m_radiansNL(270);

	if(v1.t < v0.t)
		currentDir = CLOCKWISE;
	else
		currentDir = COUNTERCLOCKWISE;

	if(currentDir != dir)
	{
		// reverse order of vertices
		for(i = 0; i < numVertices / 2; i++)
		{
			const vec2_t *tmp = vertices[i];
			vertices[i] = vertices[numVertices - i - 1];
			vertices[numVertices - i - 1] = tmp;
		}
	}
}
