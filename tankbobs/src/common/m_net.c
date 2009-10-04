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

#define PACKETQUEUESIZE 1024

static char      lastHostName[BUFSIZE] = {""};
static UDPpacket *currentPacket   = NULL;
static UDPpacket *currentPacketQ  = NULL;
static UDPpacket *listenPacket    = NULL;
static UDPpacket *listenPacketQ   = NULL;
static UDPsocket currentSocket    = NULL;
static Uint16    currentPort      = DEFAULTPORT;

#if PACKETQUEUESIZE < 1
#error PACKETQUEUESIZE must be positive
#endif /* PACKETQUEUESIZE < 1 */
typedef struct packetQueue_s packetQueue_t;
static struct packetQueue_s
{
	int timestamp;
	IPaddress address;
	int len;
	char data[MAXPACKETSIZE];
} sendQueue[PACKETQUEUESIZE] = {{0}}, receiveQueue[PACKETQUEUESIZE];
static packetQueue_t * const sq = &sendQueue[0];
static packetQueue_t * const rq = &receiveQueue[0];

static int lastSentPacket = -1;
static int lastReceivedPacket = -1;
static int queueTime;

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

	listenPacket = SDLNet_AllocPacket(MAXPACKETSIZE);
	listenPacketQ = SDLNet_AllocPacket(MAXPACKETSIZE);
	currentPacketQ = SDLNet_AllocPacket(MAXPACKETSIZE);

	lua_pushboolean(L, TRUE);
	return 1;
}

static void n_sendOldestPacket(void)
{
	/* Note: error checking needs to be done before calling this function */
	currentPacketQ->len = sq->len;
	memcpy(currentPacketQ->data, sq->data, sq->len);
	memcpy(&currentPacketQ->address, &sq->address, sizeof(currentPacketQ->address));
	SDLNet_UDP_Send(currentSocket, -1, currentPacketQ);
	memmove(sq, sq + 1, sizeof(sendQueue) - sizeof(sendQueue[0]));
	--lastSentPacket;
}

int n_quit(lua_State *L)
{
	CHECKINIT(init, L);

	while(lastSentPacket >= 0)
	{
		/* send queued packets before closing */
		n_sendOldestPacket();
	}

	if(currentPacket)
	{
		SDLNet_FreePacket(currentPacket);
		currentPacket = NULL;
	}

	if(currentPacketQ)
	{
		SDLNet_FreePacket(currentPacketQ);
		currentPacket = NULL;
	}

	if(listenPacket)
	{
		SDLNet_FreePacket(listenPacket);
		listenPacket = NULL;
	}

	if(listenPacket)
	{
		SDLNet_FreePacket(listenPacketQ);
		listenPacket = NULL;
	}

	if(currentSocket)
	{
		SDLNet_UDP_Close(currentSocket);
		currentSocket = NULL;
	}

	SDLNet_Quit();

	return 0;
}

int n_setQueueTime(lua_State *L)
{
	CHECKINIT(init, L);

	queueTime = luaL_checkinteger(L, 1);

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

	currentPort = luaL_checkinteger(L, 1) & (0x0000FFFF);

	return 0;
}

static void n_sendQueuedPackets(void)
{
	packetQueue_t *p = sq;
	int t;

	if(!queueTime)
		return;

	t = SDL_GetTicks();

	while(lastSentPacket >= 0 && p->timestamp + queueTime <= t)
	{
		n_sendOldestPacket();
	}
}

static void n_addPacketToSendQueue(void)
{
	int t;
	packetQueue_t *p;

	if(!currentPacket)
		return;

	t = SDL_GetTicks();

	if(++lastSentPacket >= sizeof(sendQueue) / sizeof(sendQueue[0]))
	{
		/* send the oldest packet */
		fprintf(stderr, "Warning: n_addPacketToSendQueue: no room left in queue for packet (%d); sending oldest packet (queued %dms ago, was going to send %dms into the future)\n", PACKETQUEUESIZE, t - sq->timestamp, sq->timestamp + queueTime - t);
		n_sendOldestPacket();
	}

	p = &sendQueue[lastSentPacket];

	p->timestamp = t;
	p->len = currentPacket->len;
	memcpy(p->data, currentPacket->data, p->len);
	memcpy(&p->address, &currentPacket->address, sizeof(p->address));
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

	if(queueTime)
	{
		n_addPacketToSendQueue();

		n_sendQueuedPackets();
	}
	else
	{
		SDLNet_UDP_Send(currentSocket, -1, currentPacket);
	}

	return 0;
}

static void n_addPacketToReceiveQueue(void)
{
	int t;
	packetQueue_t *p;

	if(!listenPacket)
		return;

	t = SDL_GetTicks();

	if(++lastReceivedPacket >= sizeof(receiveQueue) / sizeof(receiveQueue[0]))
	{
		/* remove the oldest packet */
		fprintf(stderr, "Warning: n_addPacketToReceiveQueue: no room left in queue for packet (%d); REMOVING oldest packet (queued %dms ago, was going to send %dms into the future)\n", PACKETQUEUESIZE, t - rq->timestamp, rq->timestamp + queueTime - t);
		memmove(rq, rq + 1, sizeof(receiveQueue) - sizeof(receiveQueue[0]));
	}

	p = &receiveQueue[lastReceivedPacket];

	p->timestamp = t;
	p->len = listenPacket->len;
	memcpy(p->data, listenPacket->data, p->len);
	memcpy(&p->address, &listenPacket->address, sizeof(p->address));
}

static int n_receiveQueue(void)
{
	packetQueue_t *p = rq;
	int t;

	if(!queueTime)
		return false;

	t = SDL_GetTicks();

	if(lastReceivedPacket >= 0 && p->timestamp + queueTime <= t)
	{
		listenPacketQ->len = p->len;
		memcpy(listenPacketQ->data, p->data, p->len);
		memcpy(&listenPacketQ->address, &p->address, sizeof(listenPacketQ->address));
		memmove(rq, rq + 1, sizeof(receiveQueue) - sizeof(receiveQueue[0]));
		--lastReceivedPacket;

		return true;
	}

	return false;
}

int n_readPacket(lua_State *L)
{
	UDPpacket *p = NULL;

	CHECKINIT(init, L);

	if(!currentSocket || !listenPacket)
	{
		return 0;
	}

	/* check for packets that need to be sent */
	n_sendQueuedPackets();

	if(SDLNet_UDP_Recv(currentSocket, listenPacket))
	{
		if(!queueTime)
			p = listenPacket;
		else
			n_addPacketToReceiveQueue();
	}

	if(queueTime && n_receiveQueue())
	{
		p = listenPacketQ;
	}

	if(p)
	{
		Uint16 port = p->address.port;
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
#else
		unsigned char *port_ = (unsigned char *) &port;
#endif
		static char ip[BUFSIZE];

		/* ip = SDLNet_PresentIP(&p->address); */
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
		sprintf(ip, "%d.%d.%d.%d", (p->address.host >> 24) & 0x000000FF, (p->address.host >> 16) & 0x000000FF, (p->address.host >> 8) & 0x000000FF, (p->address.host >> 0) & 0x000000FF);
#else
		sprintf(ip, "%d.%d.%d.%d", (p->address.host >> 0) & 0x000000FF, (p->address.host >> 8) & 0x000000FF, (p->address.host >> 16) & 0x000000FF, (p->address.host >> 24) & 0x000000FF);
#endif

		lua_pushboolean(L, TRUE);

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
#else
		port_[0] ^= port_[1];
		port_[1] ^= port_[0];
		port_[0] ^= port_[1];
#endif

		lua_pushstring(L, ip);
		lua_pushinteger(L, port);
		lua_pushlstring(L, (const char *) p->data, p->len);

		return 4;
	}

	lua_pushboolean(L, FALSE);

	return 1;
}
