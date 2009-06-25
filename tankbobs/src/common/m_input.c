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

#define JOY_MIN_AXIS   32767
#define JOY_MAX_AXIS  -32768

typedef struct
{
	char  *type;
	int    intArg0;
	int    intArg1;
	int    intArg2;
	int    intArg3;
	int    intArg4;
	char  *strArg0;
	char  *strArg1;
	char  *strArg2;
	char  *strArg3;
	char  *strArg4;
	double doubleArg0;
	double doubleArg1;
	double doubleArg2;
	double doubleArg3;
	double doubleArg4;
	void  *next;
} in_sdlevent;

void in_init(lua_State *L)
{
}

/* TODO: remove unnecessary triple and double pointers */
static void in_private_sdleventInit(in_sdlevent ***pE)
{
	in_sdlevent *e = **pE;

	e->type = NULL;
	e->intArg0 = 0;
	e->intArg1 = 0;
	e->intArg2 = 0;
	e->intArg3 = 0;
	e->intArg4 = 0;
	e->strArg0 = NULL;
	e->strArg1 = NULL;
	e->strArg2 = NULL;
	e->strArg3 = NULL;
	e->strArg4 = NULL;
	e->doubleArg0 = 0.0f;
	e->doubleArg1 = 0.0f;
	e->doubleArg2 = 0.0f;
	e->doubleArg3 = 0.0f;
	e->doubleArg4 = 0.0f;
	e->next = NULL;
}

static void in_private_freeEvents(in_sdlevent **event)
{
	in_sdlevent *e = *event;

	if(e->next)
		in_private_freeEvents(((in_sdlevent **)(&e->next)));

	if(e->strArg0)
		free(e->strArg0);

	if(e->strArg1)
		free(e->strArg1);

	if(e->strArg2)
		free(e->strArg2);

	if(e->strArg3)
		free(e->strArg3);

	if(e->strArg4)
		free(e->strArg4);

	free(e);
}

int in_getEvents(lua_State *L)
{
	SDL_Event event;
	in_sdlevent *e = malloc(sizeof(in_sdlevent));
	in_sdlevent *l = NULL;
	in_sdlevent **pE = &e;
	register int results = 0;
	in_private_sdleventInit(&pE);

	CHECKINIT(init, L);

	while(SDL_PollEvent(&event))
	{
		results++;

		switch(event.type)
		{
			case SDL_NOEVENT:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "nothing";
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_ACTIVEEVENT:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "focus";
					n->intArg0 = event.active.gain;
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_KEYDOWN:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					char *tmp = malloc(2);
					tmp[1] = 0;
					tmp[0] = event.key.keysym.sym;
					n->type = "keydown";
					n->intArg0 = event.key.keysym.sym;
					n->strArg0 = tmp;
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_KEYUP:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					char *tmp = malloc(2);
					tmp[1] = 0;
					tmp[0] = event.key.keysym.sym;
					n->type = "keyup";
					n->intArg0 = event.key.keysym.sym;
					n->strArg0 = tmp;
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_MOUSEMOTION:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "mousemove";
					n->intArg0 = event.motion.x;
					n->intArg1 = event.motion.y;
					n->intArg2 = event.motion.xrel;
					n->intArg3 = event.motion.yrel;
					n->intArg4 = 0;
					n->intArg4 |= ((event.motion.state) ? (0x00000001) : (0));
					n->intArg4 |= (((Uint32)event.motion.xrel & event.motion.x) ? (0x00000010) : (0));
					n->intArg4 |= (((Uint32)event.motion.yrel & event.motion.y) ? (0x00000100) : (0));
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_MOUSEBUTTONDOWN:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "mousedown";
					n->intArg0 = 0;
					switch(event.button.button)
					{
						case SDL_BUTTON_LEFT:
							n->intArg0 = 1;
							break;
						case SDL_BUTTON_MIDDLE:
							n->intArg0 = 3;
							break;
						case SDL_BUTTON_RIGHT:
							n->intArg0 = 2;
							break;
						case SDL_BUTTON_WHEELUP:
							n->intArg0 = 5;
							break;
						case SDL_BUTTON_WHEELDOWN:
							n->intArg0 = 4;
							break;
						default:
							break;
					}
					n->intArg1 = event.button.x;
					n->intArg2 = event.button.y;
					n->intArg3 = event.button.button;
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_MOUSEBUTTONUP:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "mouseup";
					n->intArg0 = 0;
					switch(event.button.button)
					{
						case SDL_BUTTON_LEFT:
							n->intArg0 = 1;
							break;
						case SDL_BUTTON_MIDDLE:
							n->intArg0 = 3;
							break;
						case SDL_BUTTON_RIGHT:
							n->intArg0 = 2;
							break;
						case SDL_BUTTON_WHEELUP:
							n->intArg0 = 5;
							break;
						case SDL_BUTTON_WHEELDOWN:
							n->intArg0 = 4;
							break;
						default:
							break;
					}
					n->intArg1 = event.button.x;
					n->intArg2 = event.button.y;
					n->intArg3 = event.button.button;
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_JOYAXISMOTION:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "joyaxis";
					n->intArg0 = event.jaxis.axis;
					n->intArg1 = event.jaxis.value;
					n->intArg2 = event.jaxis.which;
					n->doubleArg0 = ((double)event.jaxis.value - (double)JOY_MIN_AXIS) / ((double)JOY_MAX_AXIS - (double)JOY_MIN_AXIS) * 100.0f;

				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_JOYBALLMOTION:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "joyball";
					n->intArg0 = event.jball.xrel;
					n->intArg1 = event.jball.yrel;
					n->intArg2 = event.jball.ball;
					n->intArg3 = event.jball.which;
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_JOYHATMOTION:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "joyhat";
					n->intArg0 = event.jhat.hat;
					n->intArg1 = event.jhat.which;
					n->intArg2 = 0;
					if(event.jhat.value | SDL_HAT_CENTERED)
						n->intArg2 = 1;
					else if(event.jhat.value | SDL_HAT_RIGHTUP)
						n->intArg2 = 2;
					else if(event.jhat.value | SDL_HAT_LEFTDOWN)
						n->intArg2 = 3;
					else if(event.jhat.value | SDL_HAT_LEFTUP)
						n->intArg2 = 4;
					else if(event.jhat.value | SDL_HAT_RIGHTDOWN)
						n->intArg2 = 5;
					else if(event.jhat.value | SDL_HAT_LEFT)
						n->intArg2 = 6;
					else if(event.jhat.value | SDL_HAT_UP)
						n->intArg2 = 7;
					else if(event.jhat.value | SDL_HAT_DOWN)
						n->intArg2 = 8;
					else if(event.jhat.value | SDL_HAT_RIGHT)
						n->intArg2 = 9;
					n->intArg3 = event.jhat.value;
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_JOYBUTTONDOWN:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "joydown";
					n->intArg0 = event.jbutton.button;
					n->intArg1 = event.jbutton.which;
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_JOYBUTTONUP:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "joyup";
					n->intArg0 = event.jbutton.button;
					n->intArg1 = event.jbutton.which;
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_VIDEORESIZE:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "video";
					n->intArg0 = event.resize.w;
					n->intArg1 = event.resize.h;
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_VIDEOEXPOSE:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "videofocus";
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_QUIT:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "quit";
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_USEREVENT:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "user";
					n->intArg0 = event.user.code;
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			case SDL_SYSWMEVENT:
			{
				in_sdlevent *n = malloc(sizeof(in_sdlevent));
				{
					in_sdlevent **tmp = &n;
					in_private_sdleventInit(&tmp);
				}
				{
					n->type = "wm";
				}
				if(!e->type)
				{
					e = l = n;
				}
				else
				{
					if(!e->next)
						e->next = (void *)n;
					l->next = n;
					l = n;
				}
				break;
			}

			default:
			{
				fprintf(stderr, "Warning: event %d not handled\n", event.type);
				break;
			}
		}
	}

	if(results)
	{
		lua_pushinteger(L, results);
		lua_pushlightuserdata(L, e);
		return 2;
	}

	in_private_freeEvents(&e);
	lua_pushnil(L);
	return 1;
}

int in_getEventData(lua_State *L)
{
	const char *arg = luaL_checkstring(L, -1);
	in_sdlevent *e = lua_touserdata(L, -2);

	CHECKINIT(init, L);

	if(!e || !arg)
	{
		lua_pushstring(L, "invalid arguments passed");
		lua_error(L);
	}

	lua_pushnil(L);

	if(!strcmp(arg, "event") || !strcmp(arg, "type"))
	{
		lua_pop(L, 1);
		lua_pushlstring(L, e->type, strlen(e->type));
	}
	else if(!strcmp(arg, "intData0") || !strcmp(arg, "intArg0"))
	{
		lua_pop(L, 1);
		lua_pushinteger(L, e->intArg0);
	}
	else if(!strcmp(arg, "intData1") || !strcmp(arg, "intArg1"))
	{
		lua_pop(L, 1);
		lua_pushinteger(L, e->intArg1);
	}
	else if(!strcmp(arg, "intData2") || !strcmp(arg, "intArg2"))
	{
		lua_pop(L, 1);
		lua_pushinteger(L, e->intArg2);
	}
	else if(!strcmp(arg, "intData3") || !strcmp(arg, "intArg3"))
	{
		lua_pop(L, 1);
		lua_pushinteger(L, e->intArg3);
	}
	else if(!strcmp(arg, "intData4") || !strcmp(arg, "intArg4"))
	{
		lua_pop(L, 1);
		lua_pushinteger(L, e->intArg4);
	}
	else if(!strcmp(arg, "strData0") || !strcmp(arg, "strArg0"))
	{
		lua_pop(L, 1);
		lua_pushlstring(L, e->strArg0, strlen(e->strArg0));
	}
	else if(!strcmp(arg, "strData1") || !strcmp(arg, "strArg1"))
	{
		lua_pop(L, 1);
		lua_pushlstring(L, e->strArg1, strlen(e->strArg1));
	}
	else if(!strcmp(arg, "strData2") || !strcmp(arg, "strArg"))
	{
		lua_pop(L, 1);
		lua_pushlstring(L, e->strArg2, strlen(e->strArg2));
	}
	else if(!strcmp(arg, "strData3") || !strcmp(arg, "strArg"))
	{
		lua_pop(L, 1);
		lua_pushlstring(L, e->strArg3, strlen(e->strArg3));
	}
	else if(!strcmp(arg, "strData4") || !strcmp(arg, "strArg"))
	{
		lua_pop(L, 1);
		lua_pushlstring(L, e->strArg4, strlen(e->strArg4));
	}
	else if(!strcmp(arg, "doubleData0") || !strcmp(arg, "doubleArg0"))
	{
		lua_pop(L, 1);
		lua_pushnumber(L, e->doubleArg0);
	}
	else if(!strcmp(arg, "doubleData1") || !strcmp(arg, "doubleArg1"))
	{
		lua_pop(L, 1);
		lua_pushnumber(L, e->doubleArg1);
	}
	else if(!strcmp(arg, "doubleData2") || !strcmp(arg, "doubleArg2"))
	{
		lua_pop(L, 1);
		lua_pushnumber(L, e->doubleArg2);
	}
	else if(!strcmp(arg, "doubleData3") || !strcmp(arg, "doubleArg3"))
	{
		lua_pop(L, 1);
		lua_pushnumber(L, e->doubleArg3);
	}
	else if(!strcmp(arg, "doubleData4") || !strcmp(arg, "doubleArg4"))
	{
		lua_pop(L, 1);
		lua_pushnumber(L, e->doubleArg4);
	}

	return 1;
}

int in_nextEvent(lua_State *L)
{
	in_sdlevent *e = (in_sdlevent *)lua_touserdata(L, -1);

	CHECKINIT(init, L);

	if(!e || !e->type)
	{
		lua_pushstring(L, "invalid arguments passed");
		lua_error(L);
	}

	if(!e->next)
		lua_pushnil(L);
	else
		lua_pushlightuserdata(L, e->next);

	return 1;
}

int in_freeEvents(lua_State *L)
{
	in_sdlevent *e = (in_sdlevent *)lua_touserdata(L, -1);

	CHECKINIT(init, L);

	if(!e)
	{
		lua_pushstring(L, "invalid arguments passed");
		lua_error(L);
	}

	in_private_freeEvents(&e);

	return 0;
}

int in_grabClear(lua_State *L)
{
	CHECKINIT(init, L);

	SDL_WM_GrabInput(SDL_GRAB_OFF);
	SDL_ShowCursor(SDL_ENABLE);

	return 0;
}

int in_grabMouse(lua_State *L)
{
	CHECKINIT(init, L);

	if(luaL_checkinteger(L, -1) > 0 && luaL_checkinteger(L, -2) > 0)
	{
		SDL_EventState(SDL_MOUSEMOTION, SDL_IGNORE);
		SDL_WarpMouse(luaL_checkinteger(L, -2) / 2, luaL_checkinteger(L, -1) / 1);
		SDL_EventState(SDL_MOUSEMOTION, SDL_ENABLE);
	}

	SDL_WM_GrabInput(SDL_GRAB_ON);
	SDL_ShowCursor(SDL_DISABLE);

	return 0;
}

int in_isGrabbed(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushboolean(L, !SDL_ShowCursor(SDL_QUERY));

	return 1;
}
