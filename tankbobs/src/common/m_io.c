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

#include "common.h"
#include "m_tankbobs.h"

#define EOFERROR "EOF !#\\"

void io_init(lua_State *l)
{
}

int io_getHomeDirectory(lua_State *L)
{
	const char *userdir;

	CHECKINIT(init, L);

#ifdef _WIN32
	userdir = getenv("APPDATA");
#else
	userdir = getenv("HOME");
#endif

	if(userdir)
	{
		lua_pushstring(L, userdir);
		return 1;
	}
	else
	{
		lua_pushnil(L);
		lua_pushstring(L, "error accessing user directory");
		return 2;
	}
}

int io_getInt(lua_State *L)
{
	int result, c;
	unsigned char *p = (unsigned char *)(&result);
	FILE *fin = *((FILE **)lua_touserdata(L, -1));

	CHECKINIT(init, L);

	if(!fin)
	{
		lua_pushstring(L, "no or invalid file handle passed\n");
		lua_error(L);
	}

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[3] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[2] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)c;
#else
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[2] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[3] = (unsigned char)c;
#endif
	lua_pushinteger(L, (int)result);
	return 1;
}

int io_getShort(lua_State *L)
{
	int c;
	short result;
	unsigned char *p = (unsigned char *)(&result);
	FILE *fin = *((FILE **)lua_touserdata(L, -1));

	CHECKINIT(init, L);

	if(!fin)
	{
		lua_pushstring(L, "no or invalid file handle passed\n");
		lua_error(L);
	}

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)c;
#else
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char)c;
#endif
	lua_pushinteger(L, (int)result);
	return 1;
}

int io_getChar(lua_State *L)
{
	int c;
	char result;
	unsigned char *p = (unsigned char *)(&result);
	FILE *fin = *((FILE **)lua_touserdata(L, -1));

	CHECKINIT(init, L);

	if(!fin)
	{
		lua_pushstring(L, "no or invalid file handle passed\n");
		lua_error(L);
	}

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);

		return 1;
	}
	p[0] = (unsigned char) c;
#else
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);

		return 1;
	}
	p[0] = (unsigned char) c;
#endif
	lua_pushinteger(L, (int) result);

	return 1;
}

int io_getFloat(lua_State *L)
{
	int c;
	float result;
	unsigned char *p = (unsigned char *)(&result);
	FILE *fin = *((FILE **)lua_touserdata(L, -1));

	CHECKINIT(init, L);

	if(!fin)
	{
		lua_pushstring(L, "no or invalid file handle passed\n");
		lua_error(L);
	}

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[3] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[2] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char) c;
#else
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[2] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[3] = (unsigned char) c;
#endif
	lua_pushnumber(L, (double) result);

	return 1;
}

int io_getDouble(lua_State *L)
{
	int c;
	double result;
	unsigned char *p = (unsigned char *)(&result);
	FILE *fin = *((FILE **)lua_touserdata(L, -1));

	CHECKINIT(init, L);

	if(!fin)
	{
		lua_pushstring(L, "no or invalid file handle passed\n");
		lua_error(L);
	}

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[7] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[6] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[5] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[4] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[3] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[2] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)c;
#else
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[2] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[3] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[4] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[5] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[6] = (unsigned char)c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[7] = (unsigned char)c;
#endif
	lua_pushnumber(L, (double)result);
	return 1;
}

int io_getStr(lua_State *L)
{
	int i = 0;
	unsigned char *result;
	FILE *fin = *((FILE **)lua_touserdata(L, -1));

	CHECKINIT(init, L);

	if(!fin)
	{
		lua_pushstring(L, "no or invalid file handle passed\n");
		lua_error(L);
	}

	result = malloc(10000);

	while(i < 10000 && (result[i++] = fgetc(fin)) > 0);
	if(result[--i] == EOF)  /* TODO: fix infinite loop if string doesn't terminate! */
	{
		free(result);
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	lua_pushstring(L, (char *)result);
	free(result);
	return 1;
}

int io_getStrL(lua_State *L)
{
	int c;
	unsigned char *result;
	int i, len = luaL_checkinteger(L, -1);
	FILE *fin = *((FILE **)lua_touserdata(L, -2));

	CHECKINIT(init, L);

	if(!fin)
	{
		lua_pushstring(L, "no or invalid file handle passed\n");
		lua_error(L);
	}

	result = malloc(len);

	for(i = 0; i < len; i++)
	{
		c = fgetc(fin);
		result[i] = (unsigned char)c;
		if(c == EOF)
		{
			free(result);
			lua_pushstring(L, EOFERROR);
			return 1;
		}
	}
	lua_pushlstring(L, (char *)result, len);
	free(result);
	return 1;
}

int io_toInt(lua_State *L)
{
	int integer;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	char *integer_ = (char *) &integer;

	CHECKINIT(init, L);

	integer = *((const int *) luaL_checkstring(L, 1));
	integer_[3] ^= integer_[0];
	integer_[0] ^= integer_[3];
	integer_[2] ^= integer_[1];
	integer_[1] ^= integer_[2];
#else
	CHECKINIT(init, L);

	integer = *((const int *) luaL_checkstring(L, 1));
#endif

	lua_pushinteger(L, integer);
	return 1;
}

int io_toShort(lua_State *L)
{
	short integer;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	char *integer_ = (char *) &integer;

	CHECKINIT(init, L);

	integer = *((const short *) luaL_checkstring(L, 1));
	integer_[0] ^= integer_[1];
	integer_[1] ^= integer_[0];
#else
	CHECKINIT(init, L);

	integer = *((const short *) luaL_checkstring(L, 1));
#endif

	lua_pushinteger(L, integer);
	return 1;

	CHECKINIT(init, L);
}

int io_toChar(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushinteger(L, *((const char *) luaL_checkstring(L, 1)));
	return 1;
}

int io_toFloat(lua_State *L)
{
	float number;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	char *number_ = (char *) &number;

	CHECKINIT(init, L);

	number = *((const float *) luaL_checkstring(L, 1));
	number_[3] ^= number_[0];
	number_[0] ^= number_[3];
	number_[2] ^= number_[1];
	number_[1] ^= number_[2];
#else
	CHECKINIT(init, L);

	number = *((const float *) luaL_checkstring(L, 1));
#endif

	lua_pushnumber(L, number);
	return 1;
}

int io_toDouble(lua_State *L)
{
	double number;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	char *number_ = (char *) &number;

	CHECKINIT(init, L);

	number = *((const double *) luaL_checkstring(L, 1));
	number_[7] ^= number_[0];
	number_[0] ^= number_[7];
	number_[6] ^= number_[1];
	number_[1] ^= number_[6];
	number_[5] ^= number_[2];
	number_[2] ^= number_[5];
	number_[4] ^= number_[3];
	number_[3] ^= number_[4];
#else
	CHECKINIT(init, L);

	number = *((const double *) luaL_checkstring(L, 1));
#endif

	lua_pushnumber(L, number);
	return 1;
}

int io_fromInt(lua_State *L)
{
	int integer;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	char *integer_ = &integer;

	CHECKINIT(init, L);

	integer = luaL_checkinteger(L, 1);
	integer_[3] ^= integer_[0];
	integer_[0] ^= integer_[3];
	integer_[2] ^= integer_[1];
	integer_[1] ^= integer_[2];
#else
	CHECKINIT(init, L);

	integer = luaL_checkinteger(L, 1);
#endif

	lua_pushlstring(L, ((const char *) &integer), sizeof(integer));
	return 1;
}

int io_fromShort(lua_State *L)
{
	short integer;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	char *integer_ = &integer;

	CHECKINIT(init, L);

	integer = luaL_checkinteger(L, 1);
	integer_[1] ^= integer_[0];
	integer_[0] ^= integer_[1];
#else
	CHECKINIT(init, L);

	integer = luaL_checkinteger(L, 1);
#endif

	lua_pushlstring(L, ((const char *) &integer), sizeof(integer));
	return 1;
}

int io_fromChar(lua_State *L)
{
	char integer;

	CHECKINIT(init, L);

	integer = luaL_checkinteger(L, 1);

	lua_pushlstring(L, ((const char *) &integer), sizeof(integer));
	return 1;
}

int io_fromFloat(lua_State *L)
{
	float number;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	char *number_ = &number;

	CHECKINIT(init, L);

	number = luaL_checknumber(L, 1);
	number_[3] ^= number_[0];
	number_[0] ^= number_[3];
	number_[2] ^= number_[1];
	number_[1] ^= number_[2];
#else
	CHECKINIT(init, L);
#endif

	lua_pushlstring(L, ((const char *) &number), sizeof(number));
	return 1;
}

int io_fromDouble(lua_State *L)
{
	double number;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	char *number_ = &number;

	CHECKINIT(init, L);

	number = luaL_checknumber(L, 1);
	number_[7] ^= number_[0];
	number_[0] ^= number_[7];
	number_[6] ^= number_[1];
	number_[1] ^= number_[6];
	number_[5] ^= number_[2];
	number_[2] ^= number_[5];
	number_[4] ^= number_[3];
	number_[3] ^= number_[4];
#else
	CHECKINIT(init, L);

	number = luaL_checknumber(L, 1);
#endif

	lua_pushlstring(L, ((const char *) &number), sizeof(number));
	return 1;
}

int io_intNL(int integer)
{
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	char *integer_ = &integer;

	integer_[3] ^= integer_[0];
	integer_[0] ^= integer_[3];
	integer_[2] ^= integer_[1];
	integer_[1] ^= integer_[2];
#endif

	return integer;
}

short io_shortNL(short integer)
{
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	char *integer_ = &integer;

	integer_[1] ^= integer_[0];
	integer_[0] ^= integer_[1];
#endif

	return integer;
}

char io_charNL(char integer)
{
	return integer;
}

float io_floatNL(float number)
{
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	char *number_ = &number;

	number_[3] ^= number_[0];
	number_[0] ^= number_[3];
	number_[2] ^= number_[1];
	number_[1] ^= number_[2];
#endif

	return number;
}

double io_doubleNL(double number)
{
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	char *number_ = &number;

	number_[7] ^= number_[0];
	number_[0] ^= number_[7];
	number_[6] ^= number_[1];
	number_[1] ^= number_[6];
	number_[5] ^= number_[2];
	number_[2] ^= number_[5];
	number_[4] ^= number_[3];
	number_[3] ^= number_[4];
#endif

	return number;
}
