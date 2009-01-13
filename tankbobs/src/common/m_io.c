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

#define EOFERROR "EOF !#\\"

extern Uint8 init;

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
	int result, eof;
	unsigned char *p = (unsigned char *)(&result);
	FILE *fin = *((FILE **)lua_touserdata(L, -1));

	CHECKINIT(init, L);

	if(!fin)
	{
		lua_pushstring(L, "no or invalid file handle passed\n");
		lua_error(L);
	}

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[3] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[2] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)eof;
#else
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[2] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[3] = (unsigned char)eof;
#endif
	lua_pushinteger(L, (int)result);
	return 1;
}

int io_getShort(lua_State *L)
{
	int eof;
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
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)eof;
#else
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char)eof;
#endif
	lua_pushinteger(L, (int)result);
	return 1;
}

int io_getChar(lua_State *L)
{
	int eof;
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
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)eof;
#else
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)eof;
#endif
	lua_pushinteger(L, (int)result);
	return 1;
}

int io_getFloat(lua_State *L)
{
	int eof;
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
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[3] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[2] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)eof;
#else
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[2] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[3] = (unsigned char)eof;
#endif
	lua_pushnumber(L, (double)result);
	return 1;
}

int io_getDouble(lua_State *L)
{
	int eof;
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
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[7] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[6] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[5] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[4] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[3] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[2] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)eof;
#else
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[0] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[1] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[2] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[3] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[4] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[5] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[6] = (unsigned char)eof;
	eof = fgetc(fin);
	if(eof == EOF)
	{
		lua_pushstring(L, EOFERROR);
		return 1;
	}
	p[7] = (unsigned char)eof;
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
	int eof;
	unsigned char *result;
	int i, len = luaL_checkinteger(L, -1);
	FILE *fin = *((FILE **)lua_touserdata(L, -1));

	CHECKINIT(init, L);

	if(!fin)
	{
		lua_pushstring(L, "no or invalid file handle passed\n");
		lua_error(L);
	}

	result = malloc(len);

	for(i = 0; i < len; i++)
	{
		eof = fgetc(fin);
		result[i] = (unsigned char)eof;
		if(eof == EOF)
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
