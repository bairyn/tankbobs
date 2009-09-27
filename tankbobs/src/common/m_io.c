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
 * io.c
 *
 * integers are stored and transfered in little-endian order
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

#define XORSWAP(a, b) \
do \
{ \
	(a) ^= (b); \
	(b) ^= (a); \
	(a) ^= (b); \
} while(0)
#define CHARSWAP(a, b) \
do \
{ \
	io8t tmp = (a); \
	(a) = (b); \
	(b) = (a); \
} while(0)

void io_init(lua_State *L)
{
#define CHECKTIOSIZE(x, y) \
	if(1 != sizeof(io8t)) \
	{ \
		fprintf(stderr, "Warning: size of '" #y "' was expected to be %d byte%s, but it is %d byte%s wide instead\n", x, x == 1 ? "" : "s", (int) sizeof(y), sizeof(y) == 1 ? "" : "s"); \
	}

	CHECKTIOSIZE(1, io8t);
	CHECKTIOSIZE(2, io16t);
	CHECKTIOSIZE(4, io32t);
	CHECKTIOSIZE(8, io64t);
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
	int c;
	io32t integer;
	FILE *fin = *((FILE **) lua_touserdata(L, -1));

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
		lua_pushboolean(L, false);
		return 1;
	}
	integer.bytes[3] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	integer.bytes[2] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	integer.bytes[1] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	integer.bytes[0] = (unsigned char) c;
#else
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	integer.bytes[0] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	integer.bytes[1] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	integer.bytes[2] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	integer.bytes[3] = (unsigned char) c;
#endif
	lua_pushinteger(L, integer.integer);

	return 1;
}

int io_getShort(lua_State *L)
{
	int c;
	io16t integer;
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
		lua_pushboolean(L, false);
		return 1;
	}
	integer.bytes[1] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	integer.bytes[0] = (unsigned char) c;
#else
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	integer.bytes[0] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	integer.bytes[1] = (unsigned char) c;
#endif
	lua_pushinteger(L, integer.integer);

	return 1;
}

int io_getChar(lua_State *L)
{
	int c;
	io8t integer;
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
		lua_pushboolean(L, false);

		return 1;
	}
	integer = (unsigned char) c;
#else
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);

		return 1;
	}
	integer = (unsigned char) c;
#endif
	lua_pushinteger(L, integer);

	return 1;
}

int io_getFloat(lua_State *L)
{
	int c;
	io32t number;
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
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[3] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[2] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[1] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[0] = (unsigned char) c;
#else
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[0] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[1] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[2] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[3] = (unsigned char) c;
#endif
	lua_pushnumber(L, number.value);

	return 1;
}

int io_getDouble(lua_State *L)
{
	int c;
	io64t number;
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
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[7] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[6] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[5] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[4] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[3] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[2] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[1] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[0] = (unsigned char) c;
#else
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[0] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[1] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[2] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[3] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[4] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[5] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[6] = (unsigned char) c;
	c = fgetc(fin);
	if(c == EOF)
	{
		lua_pushboolean(L, false);
		return 1;
	}
	number.bytes[7] = (unsigned char) c;
#endif
	lua_pushnumber(L, number.value);

	return 1;
}

int io_getStr(lua_State *L)
{
	static io8t string[BUFSIZE];
	int i = 0;
	int c;
	FILE *fin = *((FILE **)lua_touserdata(L, -1));

	CHECKINIT(init, L);

	if(!fin)
	{
		lua_pushstring(L, "no or invalid file handle passed\n");
		lua_error(L);
	}

	while(i < BUFSIZE && (string[i++] = fgetc(fin)) > 0)
	{
		c = fgetc(fin);
#if EOF <= 0
		if(c <= 0) /* NULL bytes terminate */
#else
		if(c == 0x00 || string[i] == EOF)
#endif
			break;

		string[i++] = c;
	}
	if(i > 0 && string[i - 1] == EOF)
	{
		lua_pushboolean(L, false);

		return 1;
	}

	lua_pushlstring(L, (char *) string, i);

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
		result[i] = (unsigned char) c;
		if(c == EOF)
		{
			free(result);

			lua_pushboolean(L, false);

			return 1;
		}
	}

	lua_pushlstring(L, (char *) result, len);

	free(result);

	return 1;
}

int io_toInt(lua_State *L)
{
	io32t integer;

	CHECKINIT(init, L);

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	integer.integer = ((const io32t *) luaL_checkstring(L, 1))->integer;
	CHARSWAP(integer.bytes[0], integer.bytes[3]);
	CHARSWAP(integer.bytes[1], integer.bytes[2]);
#else
	integer.integer = ((const io32t *) luaL_checkstring(L, 1))->integer;
#endif

	lua_pushinteger(L, integer.integer);

	return 1;
}

int io_toShort(lua_State *L)
{
	io16t integer;

	CHECKINIT(init, L);

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	integer.integer = ((const io16t *) luaL_checkstring(L, 1))->integer;
	CHARSWAP(integer.bytes[0], integer.bytes[1]);
#else
	integer.integer = ((const io16t *) luaL_checkstring(L, 1))->integer;
#endif

	lua_pushinteger(L, integer.integer);

	return 1;
}

int io_toChar(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushinteger(L, *((const io8t *) luaL_checkstring(L, 1)));

	return 1;
}

int io_toFloat(lua_State *L)
{
	io32t number;

	CHECKINIT(init, L);

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	number.value = ((const io32t *) luaL_checkstring(L, 1))->value;
	CHARSWAP(integer.bytes[0], integer.bytes[3]);
	CHARSWAP(integer.bytes[1], integer.bytes[2]);
#else
	number.value = ((const io32t *) luaL_checkstring(L, 1))->value;
#endif

	lua_pushnumber(L, number.value);

	return 1;
}

int io_toDouble(lua_State *L)
{
	io64t number;

	CHECKINIT(init, L);

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	number.value = ((const io64t *) luaL_checkstring(L, 1))->value;
	CHARSWAP(integer.bytes[0], integer.bytes[7]);
	CHARSWAP(integer.bytes[1], integer.bytes[6]);
	CHARSWAP(integer.bytes[2], integer.bytes[5]);
	CHARSWAP(integer.bytes[3], integer.bytes[4]);
#else
	number.value = ((const io64t *) luaL_checkstring(L, 1))->value;
#endif

	lua_pushnumber(L, number.value);

	return 1;
}

int io_fromInt(lua_State *L)
{
	io32t integer;

	CHECKINIT(init, L);

	integer.integer = (io32tv) luaL_checkinteger(L, 1);

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	CHARSWAP(integer.bytes[0], integer.bytes[3]);
	CHARSWAP(integer.bytes[1], integer.bytes[2]);
#endif

	lua_pushlstring(L, ((const char *) &integer), sizeof(integer));

	return 1;
}

int io_fromShort(lua_State *L)
{
	io16t integer;

	CHECKINIT(init, L);

	integer.integer = (io32tv) luaL_checkinteger(L, 1);

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	CHARSWAP(integer_[0], integer_[1]);
#endif

	lua_pushlstring(L, ((const char *) &integer), sizeof(integer));

	return 1;
}

int io_fromChar(lua_State *L)
{
	io8t integer;

	CHECKINIT(init, L);

	integer = (io8t) luaL_checkinteger(L, 1);

	lua_pushlstring(L, ((const char *) &integer), sizeof(integer));

	return 1;
}

int io_fromFloat(lua_State *L)
{
	io32t number;

	CHECKINIT(init, L);

	number.value = (io32tv) luaL_checknumber(L, 1);

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	CHARSWAP(number.bytes[0], number.bytes[3]);
	CHARSWAP(number.bytes[1], number.bytes[2]);
#endif

	lua_pushlstring(L, ((const char *) &number), sizeof(number));

	return 1;
}

int io_fromDouble(lua_State *L)
{
	io64t number;

	CHECKINIT(init, L);

	number.value = (io64tv) luaL_checknumber(L, 1);

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	CHARSWAP(number.bytes[0], number.bytes[7]);
	CHARSWAP(number.bytes[1], number.bytes[6]);
	CHARSWAP(number.bytes[2], number.bytes[5]);
	CHARSWAP(number.bytes[3], number.bytes[4]);
#endif

	lua_pushlstring(L, ((const char *) &number), sizeof(number));
	return 1;
}

int io_intNL(io32tv integer)
{
	io32t integer_;

	integer_.integer = integer;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	CHARSWAP(integer_.bytes[0], integer_.bytes[3]);
	CHARSWAP(integer_.bytes[1], integer_.bytes[2]);
#endif

	return integer_.integer;
}

short io_shortNL(io16tv integer)
{
	io16t integer_;

	integer_.integer = integer;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	CHARSWAP(integer_.bytes[0], integer_.bytes[1]);
#endif

	return integer_.integer;
}

char io_charNL(io8t integer)
{
	return integer;
}

float io_floatNL(io32ft num)
{
	io32t number;

	number.value = num;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	CHARSWAP(number.bytes[0], number.bytes[3]);
	CHARSWAP(number.bytes[1], number.bytes[2]);
#endif

	return number.value;
}

double io_doubleNL(io64ft num)
{
	io64t number;

	number.value = num;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	CHARSWAP(number.bytes[0], number.bytes[7]);
	CHARSWAP(number.bytes[1], number.bytes[6]);
	CHARSWAP(number.bytes[2], number.bytes[5]);
	CHARSWAP(number.bytes[3], number.bytes[4]);
#endif

	return number.value;
}

/*
 * Offsets are given in bytes.
 */

int io_getIntNL(const char *base, const size_t offset)
{
	io32t integer;

	memcpy(integer.bytes, base + offset, sizeof(integer));

	return io_intNL(integer.integer);
}

short io_getShortNL(const char *base, const size_t offset)
{
	io16t integer;

	memcpy(integer.bytes, base + offset, sizeof(integer));

	return io_shortNL(integer.integer);
}

char io_getCharNL(const char *base, const size_t offset)
{
	io8t integer;

	integer = *(base + offset);

	return io_charNL(integer);
}

float io_getFloatNL(const char *base, const size_t offset)
{
	io32t number;

	memcpy(number.bytes, base + offset, sizeof(number));

	return io_floatNL(number.value);
}

double io_getDoubleNL(const char *base, const size_t offset)
{
	io64t number;

	memcpy(number.bytes, base + offset, sizeof(number));

	return io_doubleNL(number.value);
}

void io_setIntNL(char *base, const size_t offset, io32t integer)
{
	io32t integer_;

	integer_.integer = io_intNL(integer.integer);

	memcpy(base + offset, integer_.bytes, sizeof(io32t));
}

void io_setShortNL(char *base, const size_t offset, io16t integer)
{
	io16t integer_;

	integer_.integer = io_shortNL(integer.integer);

	memcpy(base + offset, integer_.bytes, sizeof(io16t));
}

void io_setCharNL(char *base, const size_t offset, io8t integer)
{
	integer = io_charNL(integer);

	*(base + offset) = integer;
}

void io_setFloatNL(char *base, const size_t offset, io32ft num)
{
	io32t number;

	number.value = io_floatNL(num);

	memcpy(base + offset, number.bytes, sizeof(io32t));
}

void io_setDoubleNL(char *base, const size_t offset, io64ft num)
{
	io64t number;

	number.value = io_doubleNL(num);

	memcpy(base + offset, number.bytes, sizeof(io64t));
}
