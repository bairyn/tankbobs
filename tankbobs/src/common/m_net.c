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
#include <SDL/SDL_endian.h>
#include <SDL/SDL_net.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <luaconf.h>
#include <math.h>

#include "common.h"
#include "m_tankbobs.h"
#include "tstr.h"
#include "crossdll.h"

#define DEFAULTPORT   43210
#define MAXPACKETSIZE 1024
#define NUMBER        0xABADB011

static char      lastHostName[BUFSIZE] = {""};
static UDPpacket *currentPacket   = NULL;
static UDPsocket currentSocket    = NULL;
static Uint16    currentPort      = DEFAULTPORT;

void n_initNL(lua_State *L)
{
}

int n_init(lua_State *L)
{
	tstr *message;

	CHECKINIT(init, L);

	currentPort = DEFAULTPORT;

	if(lua_isnumber(L, 1))
	{
		currentPort = lua_tonumber(L, 1);
	}

	if(SDLNet_Init() < 0)
	{
		lua_pushboolean(L, FALSE);

		message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "Warning: could not initialize SDL_net: ");
		CDLL_FUNCTION("libtstr", "tstr_cat", void(*)(tstr *, const char *))
			(message, SDLNet_GetError());
		CDLL_FUNCTION("libtstr", "tstr_base_cat", void(*)(tstr *, const char *))
			(message, "\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);

		return 2;
	}

	currentSocket = SDLNet_UDP_Open(currentPort);
	if(!currentSocket)
	{
		lua_pushboolean(L, FALSE);

		message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "Warning: Could not open socket: ");
		CDLL_FUNCTION("libtstr", "tstr_cat", void(*)(tstr *, const char *))
			(message, SDLNet_GetError());
		CDLL_FUNCTION("libtstr", "tstr_base_cat", void(*)(tstr *, const char *))
			(message, "\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);

		return 2;
	}

	lua_pushboolean(L, TRUE);
	return 1;
}

int n_quit(lua_State *L)
{
	CHECKINIT(init, L);

	if(currentPacket)
	{
		SDLNet_FreePacket(currentPacket);
		currentPacket = NULL;
	}

	if(currentSocket)
	{
		SDLNet_UDP_Close(currentSocket);
		currentSocket = NULL;
	}

	SDLNet_Quit();

	return 0;
}

int n_newPacket(lua_State *L)
{
	int size;

	CHECKINIT(init, L);

	if(currentPacket)
	{
		SDLNet_FreePacket(currentPacket);
		currentPacket = NULL;
	}

	size = luaL_checknumber(L, 1);
	if(size > MAXPACKETSIZE)
		size = MAXPACKETSIZE;
	if(size < 1)
		size = 1;

	currentPacket = SDLNet_AllocPacket(size);

	if(currentPacket)
	{
		currentPacket->len = 0;
	}

	return 0;
}

int n_writeToPacket(lua_State *L)
{
	size_t len;
	const char *data;

	CHECKINIT(init, L);

	if(!currentPacket)
	{
		return 0;
	}

	data = lua_tolstring(L, 1, &len);

	if(len > currentPacket->maxlen - currentPacket->len)
	{
		len = currentPacket->maxlen - currentPacket->len;
	}
	if(len <= 0)
	{
		return 0;
	}

	memcpy(currentPacket->data + currentPacket->len, data, len);

	currentPacket->len += len;

	return 0;
}

int n_setPort(lua_State *L)
{
	CHECKINIT(init, L);

	currentPort = luaL_checkinteger(L, 1);

	return 0;
}

int n_sendPacket(lua_State *L)
{
	const char *hostName;

	CHECKINIT(init, L);

	if(!currentPacket || !currentSocket)
	{
		return 0;
	}

	if(lua_isstring(L, 1))
	{
		hostName = lua_tostring(L, 1);
		strncpy(lastHostName, hostName, sizeof(lastHostName));
	}
	else
	{
		hostName = lastHostName;
	}

	SDLNet_ResolveHost(&currentPacket->address, hostName, currentPort);

	SDLNet_UDP_Send(currentSocket, -1, currentPacket);

	return 0;
}

int n_readPacket(lua_State *L)
{
	UDPpacket *packet;

	CHECKINIT(init, L);

	if(!currentSocket)
	{
		return 0;
	}

	if((packet = SDLNet_AllocPacket(MAXPACKETSIZE)))
	{
		if(SDLNet_UDP_Recv(currentSocket, packet))
		{
			static char ip[BUFSIZE];

			/* ip = SDLNet_PresentIP(&packet->address); */
/*#if SDL_BYTEORDER == SDL_BIG_ENDIAN*/
			/*sprintf(ip, "%d.%d.%d.%d", (packet->address.host >> 24) & 0x000000FF, (packet->address.host >> 16) & 0x000000FF, (packet->address.host >> 8) & 0x000000FF, (packet->address.host >> 0) & 0x000000FF);*/
/*#else*/
			sprintf(ip, "%d.%d.%d.%d", (packet->address.host >> 0) & 0x000000FF, (packet->address.host >> 8) & 0x000000FF, (packet->address.host >> 16) & 0x000000FF, (packet->address.host >> 24) & 0x000000FF);
/*#endif*/

			lua_pushboolean(L, TRUE);

			lua_pushstring(L, ip);
			lua_pushinteger(L, packet->address.port);
			lua_pushlstring(L, (const char *) packet->data, packet->len);

			SDLNet_FreePacket(packet);

			return 4;
		}
		else
		{
			SDLNet_FreePacket(packet);
		}
	}

	lua_pushboolean(L, FALSE);

	return 1;
}
