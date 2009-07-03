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
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <luaconf.h>
#include <stdio.h>
#include "common.h"

#ifndef NOJIT
static const luaL_Reg lualibs[] =
{
	{"", luaopen_base},
	{LUA_LOADLIBNAME, luaopen_package},
	{LUA_TABLIBNAME, luaopen_table},
	{LUA_IOLIBNAME, luaopen_io},
	{LUA_OSLIBNAME, luaopen_os},
	{LUA_STRLIBNAME, luaopen_string},
	{LUA_MATHLIBNAME, luaopen_math},
	{LUA_DBLIBNAME, luaopen_debug},
	{LUA_JITLIBNAME, luaopen_jit},
	{NULL, NULL}
};

LUALIB_API void luaL_openlibs (lua_State *L)
{
	const luaL_Reg *lib = lualibs;

	for( ; lib->func; lib++)
	{
		lua_pushcfunction(L, lib->func);
		lua_pushstring(L, lib->name);
		lua_call(L, 1, 0);
	}
}
#endif

int main(int argc, char **argv)
{
	int i, err;

	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	lua_newtable(L);
	for(i = 0; i < argc; i++)
	{
		lua_pushinteger(L, i + 1);
		lua_pushstring(L, argv[i]);
		lua_settable(L, -3);
	}
	lua_setglobal(L, "args");
	lua_settop(L, 0);
	if((err = luaL_dofile(L, "client")))
	{
		const char *message = lua_tostring(L, -1);
		fprintf(stderr, "Error: %s\n", message);
		return err;
	}
	lua_getglobal(L, "init");
	if((err = lua_pcall(L, 0, 0, 0)))
	{
		const char *message = lua_tostring(L, -1);

		fprintf(stderr, "Error: %s\n", message);

		return err;
	}

	return 0;
}
