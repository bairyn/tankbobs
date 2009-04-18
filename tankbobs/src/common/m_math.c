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

#define MATH_METATABLE "tankbobs.vec2Meta"

#define CHECKVEC(L, i) (vec2_t *) luaL_checkudata(L, i, MATH_METATABLE)

extern Uint8 init;

typedef struct vec2_s vec2_t;
struct vec2_s
{
	double x;
	double y;
	double R;
	double t;
};

static const struct luaL_Reg m_vec2_m[] =
{
	{"__index", m_vec2_index},
	{"__newindex", m_vec2_newindex},
	{"unify", m_vec2_unify},
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

int m_vec2(lua_State *L)
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
			v->t += 180;
		else if(v->x < 0.0)
			v->t += 90;
		else if(v->y < 0.0)
			v->t += 270;
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
	vec2_t *v;
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
				v->t += 180;
			else if(v->x < 0.0)
				v->t += 90;
			else if(v->y < 0.0)
				v->t += 270;

			return 0;
			break;

		case 'y':
			v->y = val;

			/* calculate polar coordinates */
			v->R = sqrt(v->x * v->x + v->y * v->y);
			v->t = atan(v->y / v->x);
			if(v->x < 0.0 && v->y < 0.0)
				v->t += 180;
			else if(v->x < 0.0)
				v->t += 90;
			else if(v->y < 0.0)
				v->t += 270;

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
	vec2_t *v, *v2;

	CHECKINIT(init, L);

	v = lua_newuserdata(L, sizeof(vec2_t));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v2 = CHECKVEC(L, 1);

	v->t = v2->t;
	v2->R = 1.0;

	/* calculate rectangular coordinates */
	v2->x = v2->R * cos(v2->t);
	v2->y = v2->R * sin(v2->t);

	return 1;
}

int m_vec2___add(lua_State *L)
{
	vec2_t *v, *v2, *v3;

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
		v->t += 180;
	else if(v->x < 0.0)
		v->t += 90;
	else if(v->y < 0.0)
		v->t += 270;

	return 1;
}

int m_vec2_add(lua_State *L)
{
	vec2_t *v, *v2;

	CHECKINIT(init, L);

	v = CHECKVEC(L, 1);
	v2 = CHECKVEC(L, 2);

	v->x += v2->x;
	v->y += v2->y;

	/* calculate polar coordinates */
	v->R = sqrt(v->x * v->x + v->y * v->y);
	v->t = atan(v->y / v->x);
	if(v->x < 0.0 && v->y < 0.0)
		v->t += 180;
	else if(v->x < 0.0)
		v->t += 90;
	else if(v->y < 0.0)
		v->t += 270;

	return 0;
}

int m_vec2___sub(lua_State *L)
{
	vec2_t *v, *v2, *v3;

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
		v->t += 180;
	else if(v->x < 0.0)
		v->t += 90;
	else if(v->y < 0.0)
		v->t += 270;

	return 1;
}

int m_vec2_sub(lua_State *L)
{
	vec2_t *v, *v2;

	CHECKINIT(init, L);

	v = CHECKVEC(L, 1);
	v2 = CHECKVEC(L, 2);

	v->x -= v2->x;
	v->y -= v2->y;

	/* calculate polar coordinates */
	v->R = sqrt(v->x * v->x + v->y * v->y);
	v->t = atan(v->y / v->x);
	if(v->x < 0.0 && v->y < 0.0)
		v->t += 180;
	else if(v->x < 0.0)
		v->t += 90;
	else if(v->y < 0.0)
		v->t += 270;

	return 0;
}

int m_vec2___mul(lua_State *L)
{
	vec2_t *v, *v2, *v3;
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
	vec2_t *v, *v2;
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
	vec2_t *v;

	CHECKINIT(init, L);

	v = CHECKVEC(L, 1);

	lua_pushnumber(L, v->R);

	return 1;
}

int m_vec2_call(lua_State *L)
{
	vec2_t *v, *v2;

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
	vec2_t *v, *v2;

	CHECKINIT(init, L);

	v2 = lua_newuserdata(L, sizeof(vec2_t));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v = CHECKVEC(L, 1);

	v2->x = -v->x;
	v2->y = -v->y;
	v2->R = -v->R;

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

static double m_private_determinant(double v1x, double v1y, double v2x, double v2y)
{
	return v1x * v2y - v1y * v2x;
}

int m_edge(lua_State *L)
{
	double det, t, u;
	vec2_t *l1p1, *l1p2, *l2p1, *l2p2, *v;

	CHECKINIT(init, L);

	l1p1 = CHECKVEC(L, 1);
	l1p2 = CHECKVEC(L, 2);
	l2p1 = CHECKVEC(L, 3);
	l2p2 = CHECKVEC(L, 4);

	det = m_private_determinant(l1p2->x - l1p1->x, l1p2->y - l1p1->y, l2p1->x - l2p2->x, l2p1->y - l2p2->y);
	t = m_private_determinant(l2p1->x - l1p1->x, l2p1->y - l1p1->y, l2p1->x - l2p2->x, l2p1->y - l2p2->y);
	u = m_private_determinant(l1p2->x - l1p1->x, l1p2->y - l1p1->y, l2p1->x - l1p1->x, l2p1->y - l1p1->y);

	if(t < 0 || t > 0 || u < 0 || u > 1)
	{
		lua_pushboolean(L, false);
		return 1;
	}

	lua_pushboolean(L, true);

	v = lua_newuserdata(L, sizeof(vec2_t));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v->x = (1 - t) * l1p1->x + t * l1p2->x;
	v->y = (1 - t) * l1p1->y + t * l1p2->y;
	v->R = sqrt(v->x * v->x + v->y * v->y);
	v->t = atan(v->y / v->x);
	if(v->x < 0.0 && v->y < 0.0)
		v->t += 180;
	else if(v->x < 0.0)
		v->t += 90;
	else if(v->y < 0.0)
		v->t += 270;

	return 2;
}

static int m_private_edge(vec2_t *l1p1, vec2_t *l1p2, vec2_t *l2p1, vec2_t *l2p2)  /* non-Lua version */
{
	double det, t, u;

	det = m_private_determinant(l1p2->x - l1p1->x, l1p2->y - l1p1->y, l2p1->x - l2p2->x, l2p1->y - l2p2->y);
	t = m_private_determinant(l2p1->x - l1p1->x, l2p1->y - l1p1->y, l2p1->x - l2p2->x, l2p1->y - l2p2->y);
	u = m_private_determinant(l1p2->x - l1p1->x, l1p2->y - l1p1->y, l2p1->x - l1p1->x, l2p1->y - l1p1->y);

	if(t < 0 || t > 0 || u < 0 || u > 1)
	{
		return false;
	}

	return true;
}

#define MAX_VERTICES 12

int m_polygon(lua_State *L)
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
				if(m_private_edge(p1[i - 1], p1[i], p2[j - 1], p2[j]))
				{
					lua_pushboolean(L, true);

					return 1;
				}
			}
		}

		if(num1 > sizeof(p1_b))
			free(p1);
		if(num2 > sizeof(p2_b))
			free(p2);
	}

	lua_pushboolean(L, false);

	return 1;
}
