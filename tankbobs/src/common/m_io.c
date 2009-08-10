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

	integer.integer = luaL_checkinteger(L, 1);

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

	integer.integer = luaL_checkinteger(L, 1);

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

	integer = luaL_checkinteger(L, 1);

	lua_pushlstring(L, ((const char *) &integer), sizeof(integer));

	return 1;
}

int io_fromFloat(lua_State *L)
{
	io32t number;

	CHECKINIT(init, L);

	number.value = luaL_checknumber(L, 1);

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

	number.value = luaL_checknumber(L, 1);

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	CHARSWAP(number.bytes[0], number.bytes[7]);
	CHARSWAP(number.bytes[1], number.bytes[6]);
	CHARSWAP(number.bytes[2], number.bytes[5]);
	CHARSWAP(number.bytes[3], number.bytes[4]);
#endif

	lua_pushlstring(L, ((const char *) &number), sizeof(number));
	return 1;
}

int io_intNL(io32t integer)
{
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	CHARSWAP(integer.bytes[0], integer.bytes[3]);
	CHARSWAP(integer.bytes[1], integer.bytes[2]);
#endif

	return integer.integer;
}

short io_shortNL(io16t integer)
{
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	CHARSWAP(integer.bytes[0], integer.bytes[1]);
#endif

	return integer.integer;
}

char io_charNL(io8t integer)
{
	return integer;
}

float io_floatNL(io32t number)
{
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	CHARSWAP(number.bytes[0], number.bytes[3]);
	CHARSWAP(number.bytes[1], number.bytes[2]);
#endif

	return number.value;
}

double io_doubleNL(io64t number)
{
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

int io_getIntNL(const void *base, const size_t offset)
{
	io32t integer;
	int alignment = offset % ALIGNMENT;

	if(alignment == 0)
	{
		integer.integer = ((io32t *) (((io8t *) base) + offset))->integer;
	}
	else
	{
		integer.integer =
			((io32tv) (*(((io8t *) base) + offset - alignment) << (8 * sizeof(io8t) * alignment))) |
			((io32tv) (*(((io8t *) base) + offset + 0 + ALIGNMENT - alignment) >> (0 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment)))) |
			((io32tv) (*(((io8t *) base) + offset + 1 + ALIGNMENT - alignment) >> (1 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment)))) |
			((io32tv) (*(((io8t *) base) + offset + 2 + ALIGNMENT - alignment) >> (2 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment)))) |
			((io32tv) (*(((io8t *) base) + offset + 3 + ALIGNMENT - alignment) >> (3 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment))));
	}

	return io_intNL(integer);
}

short io_getShortNL(const void *base, const size_t offset)
{
	io16t integer;
	int alignment = offset % ALIGNMENT;

	if(alignment == 0)
	{
		integer.integer = ((io16t *) (((io8t *) base) + offset))->integer;
	}
	else
	{
		integer.integer =
			((io16tv) (*(((io8t *) base) + offset - alignment) << (8 * sizeof(io8t) * alignment))) |
			((io16tv) (*(((io8t *) base) + offset + 0 + ALIGNMENT - alignment) >> (0 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment)))) |
			((io16tv) (*(((io8t *) base) + offset + 1 + ALIGNMENT - alignment) >> (1 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment))));
	}

	return io_shortNL(integer);
}

char io_getCharNL(const void *base, const size_t offset)
{
	io8t integer;
	int alignment = offset % ALIGNMENT;

	if(alignment == 0)
	{
		integer = *((io8t *) (((io8t *) base) + offset));
	}
	else
	{
		integer =
			((io8t) (*(((io8t *) base) + offset - alignment) << (8 * sizeof(io8t) * alignment))) |
			((io8t) (*(((io8t *) base) + offset + 0 + ALIGNMENT - alignment) >> (0 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment))));
	}

	return io_charNL(integer);
}

float io_getFloatNL(const void *base, const size_t offset)
{
	io32t number;
	int alignment = offset % ALIGNMENT;

	if(alignment == 0)
	{
		number.integer = ((io32t *) (((io8t *) base) + offset))->integer;
	}
	else
	{
		number.integer =
			((io32tv) (*(((io8t *) base) + offset - alignment) << (8 * sizeof(io8t) * alignment))) |
			((io32tv) (*(((io8t *) base) + offset + 0 + ALIGNMENT - alignment) >> (0 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment)))) |
			((io32tv) (*(((io8t *) base) + offset + 1 + ALIGNMENT - alignment) >> (1 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment)))) |
			((io32tv) (*(((io8t *) base) + offset + 2 + ALIGNMENT - alignment) >> (2 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment)))) |
			((io32tv) (*(((io8t *) base) + offset + 3 + ALIGNMENT - alignment) >> (3 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment))));
	}

	return io_floatNL(number);
}

double io_getDoubleNL(const void *base, const size_t offset)
{
	io64t number;
	int alignment = offset % ALIGNMENT;

	if(alignment == 0)
	{
		number.integer = ((io64t *) (((io8t *) base) + offset))->integer;
	}
	else
	{
		number.integer =
			((io64tv) (*(((io8t *) base) + offset - alignment) << (8 * sizeof(io8t) * alignment))) |
			((io64tv) (*(((io8t *) base) + offset + 0 + ALIGNMENT - alignment) >> (0 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment)))) |
			((io64tv) (*(((io8t *) base) + offset + 1 + ALIGNMENT - alignment) >> (1 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment)))) |
			((io64tv) (*(((io8t *) base) + offset + 2 + ALIGNMENT - alignment) >> (2 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment)))) |
			((io64tv) (*(((io8t *) base) + offset + 3 + ALIGNMENT - alignment) >> (3 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment)))) |
			((io64tv) (*(((io8t *) base) + offset + 4 + ALIGNMENT - alignment) >> (4 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment)))) |
			((io64tv) (*(((io8t *) base) + offset + 5 + ALIGNMENT - alignment) >> (5 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment)))) |
			((io64tv) (*(((io8t *) base) + offset + 6 + ALIGNMENT - alignment) >> (6 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment)))) |
			((io64tv) (*(((io8t *) base) + offset + 7 + ALIGNMENT - alignment) >> (7 * sizeof(io8t) + 8 * sizeof(io8t) * (sizeof(io8t) - alignment))));
	}

	return io_doubleNL(number);
}

void io_setIntNL(const void *base, const size_t offset, io32t integer)
{
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	io_setCharNL(base, offset + 3 * sizeof(io8t), (io8t) integer.bytes[3]);
	io_setCharNL(base, offset + 2 * sizeof(io8t), (io8t) integer.bytes[2]);
	io_setCharNL(base, offset + 1 * sizeof(io8t), (io8t) integer.bytes[1]);
	io_setCharNL(base, offset + 0 * sizeof(io8t), (io8t) integer.bytes[0]);
#else
	io_setCharNL(base, offset + 0 * sizeof(io8t), (io8t) integer.bytes[0]);
	io_setCharNL(base, offset + 1 * sizeof(io8t), (io8t) integer.bytes[1]);
	io_setCharNL(base, offset + 2 * sizeof(io8t), (io8t) integer.bytes[2]);
	io_setCharNL(base, offset + 3 * sizeof(io8t), (io8t) integer.bytes[3]);
#endif
}

void io_setShortNL(const void *base, const size_t offset, io16t integer)
{
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	io_setCharNL(base, offset + 1 * sizeof(io8t), (io8t) integer.bytes[1]);
	io_setCharNL(base, offset + 0 * sizeof(io8t), (io8t) integer.bytes[0]);
#else
	io_setCharNL(base, offset + 0 * sizeof(io8t), (io8t) integer.bytes[0]);
	io_setCharNL(base, offset + 1 * sizeof(io8t), (io8t) integer.bytes[1]);
#endif
}

void io_setCharNL(const void *base, const size_t offset, io8t integer)
{
	int alignment = offset % ALIGNMENT;

	integer = io_charNL(integer);

	if(alignment == 0)
	{
		*((char *) (((unsigned char *) base) + offset)) = integer;
	}
	else
	{
		*((char *) (((unsigned char *) base) + offset - alignment)) &= 0xFF << 8 * (ALIGNMENT - alignment);
		*((char *) (((unsigned char *) base) + offset - alignment)) |= integer >> 8 * alignment;
		*((char *) (((unsigned char *) base) + offset + ALIGNMENT - alignment)) &= 0xFF >> 8 * alignment;
		*((char *) (((unsigned char *) base) + offset + ALIGNMENT - alignment)) |= integer << 8 * (ALIGNMENT - alignment);
	}
}

void io_setFloatNL(const void *base, const size_t offset, io32t number)
{
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	io_setCharNL(base, offset + 3 * sizeof(io8t), (io8t) number.bytes[3]);
	io_setCharNL(base, offset + 2 * sizeof(io8t), (io8t) number.bytes[2]);
	io_setCharNL(base, offset + 1 * sizeof(io8t), (io8t) number.bytes[1]);
	io_setCharNL(base, offset + 0 * sizeof(io8t), (io8t) number.bytes[0]);
#else
	io_setCharNL(base, offset + 0 * sizeof(io8t), (io8t) number.bytes[0]);
	io_setCharNL(base, offset + 1 * sizeof(io8t), (io8t) number.bytes[1]);
	io_setCharNL(base, offset + 2 * sizeof(io8t), (io8t) number.bytes[2]);
	io_setCharNL(base, offset + 3 * sizeof(io8t), (io8t) number.bytes[3]);
#endif
}

void io_setDoubleNL(const void *base, const size_t offset, io64t number)
{
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	io_setCharNL(base, offset + 7 * sizeof(io8t), (io8t) number.bytes[7]);
	io_setCharNL(base, offset + 6 * sizeof(io8t), (io8t) number.bytes[6]);
	io_setCharNL(base, offset + 5 * sizeof(io8t), (io8t) number.bytes[5]);
	io_setCharNL(base, offset + 4 * sizeof(io8t), (io8t) number.bytes[4]);
	io_setCharNL(base, offset + 3 * sizeof(io8t), (io8t) number.bytes[3]);
	io_setCharNL(base, offset + 2 * sizeof(io8t), (io8t) number.bytes[2]);
	io_setCharNL(base, offset + 1 * sizeof(io8t), (io8t) number.bytes[1]);
	io_setCharNL(base, offset + 0 * sizeof(io8t), (io8t) number.bytes[0]);
#else
	io_setCharNL(base, offset + 0 * sizeof(io8t), (io8t) number.bytes[0]);
	io_setCharNL(base, offset + 1 * sizeof(io8t), (io8t) number.bytes[1]);
	io_setCharNL(base, offset + 2 * sizeof(io8t), (io8t) number.bytes[2]);
	io_setCharNL(base, offset + 3 * sizeof(io8t), (io8t) number.bytes[3]);
	io_setCharNL(base, offset + 4 * sizeof(io8t), (io8t) number.bytes[4]);
	io_setCharNL(base, offset + 5 * sizeof(io8t), (io8t) number.bytes[5]);
	io_setCharNL(base, offset + 6 * sizeof(io8t), (io8t) number.bytes[6]);
	io_setCharNL(base, offset + 7 * sizeof(io8t), (io8t) number.bytes[7]);
#endif
}
