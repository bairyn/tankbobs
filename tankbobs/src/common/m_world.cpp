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

#include <string>
#include <iostream>
#include <SDL.h>
#include <SDL_image.h>
#include <SDL_endian.h>
#include <cmath>

#ifndef MIN
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

extern "C"
{
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <luaconf.h>

#include "common.h"
#include "m_tankbobs.h"
#include "tstr.h"
#include "crossdll.h"
}

#include "Box2D.h"

#define CHECKWORLD(world, L) \
do \
{ \
	if(!world) \
	{ \
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void)) \
			(); \
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *)) \
			(message, "world is uninitialized\n"); \
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *)) \
							(message)); \
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *)) \
			(message); \
		lua_error(L); \
	} \
} while(0)

#define WORLDBUFSIZE BUFSIZE - 6

static double unitScale = 1.0;  // The unit scale from game to physics

static b2World *world = NULL;
static b2AABB worldAABB;
static b2Vec2 worldGravity;
static bool allowSleep;

static double timeStep = 1.0 / 128.0;
static int iterations = 24;

static int clFunction;
static lua_State *clState = NULL;

static int tankFunction;
static int wallFunction;
static int projectileFunction;
static int powerupSpawnPointFunction;
static int powerupFunction;
static int controlPointFunction;
static int flagFunction;
static int teleporterFunction;
static int corpseFunction;
static int tankTable;
static int wallTable;
static int projectileTable;
static int powerupSpawnPointTable;
static int powerupTable;
static int controlPointTable;
static int flagTable;
static int teleporterTable;
static int corpseTable;

static const b2MassData staticMassData = { 0
                                         , b2Vec2(0, 0)
                                         , 0
                                         };

class w_private_worldListener : public b2ContactListener
{
	public:
	void BeginContact(b2Contact *contact)
	{
		if(clState)
		{
			b2Fixture *fixtureA = contact->GetFixtureA();
			b2Fixture *fixtureB = contact->GetFixtureB();

			if(fixtureA && fixtureB && fixtureA->GetBody() && fixtureB->GetBody())
			{
				b2Body *bodyA = fixtureA->GetBody();
				b2Body *bodyB = fixtureB->GetBody();
				b2WorldManifold man;
				contact->GetWorldManifold(&man);
				b2Vec2 normal = man.m_normal;

				b2Vec2 *point = &man.m_points[0];
				for(int i = 0; i < contact->GetManifold()->m_pointCount; point = &man.m_points[++i])
				{
					lua_rawgeti(clState, LUA_REGISTRYINDEX, clFunction);
					lua_pushboolean(clState, true);
					lua_pushlightuserdata(clState, fixtureA);
					lua_pushlightuserdata(clState, fixtureB);
					lua_pushlightuserdata(clState, bodyA);
					lua_pushlightuserdata(clState, bodyB);

					vec2_t *v = reinterpret_cast<vec2_t *> (lua_newuserdata(clState, sizeof(vec2_t)));
					luaL_getmetatable(clState, MATH_METATABLE);
					lua_setmetatable(clState, -2);
					v->x = point->x * unitScale;
					v->y = point->y * unitScale;
					MATH_POLAR(*v);

					v = reinterpret_cast<vec2_t *> (lua_newuserdata(clState, sizeof(vec2_t)));
					luaL_getmetatable(clState, MATH_METATABLE);
					lua_setmetatable(clState, -2);
					v->x = normal.x;
					v->y = normal.y;
					MATH_POLAR(*v);

					lua_call(clState, 7, 0);
				}
			}
		}
	}

	void EndContact(b2Contact *contact)
	{
		if(clState)
		{
			b2Fixture *fixtureA = contact->GetFixtureA();
			b2Fixture *fixtureB = contact->GetFixtureB();

			if(fixtureA && fixtureB && fixtureA->GetBody() && fixtureB->GetBody())
			{
				b2Body *bodyA = fixtureA->GetBody();
				b2Body *bodyB = fixtureB->GetBody();
				b2WorldManifold man;
				contact->GetWorldManifold(&man);
				b2Vec2 normal = man.m_normal;

				b2Vec2 *point = &man.m_points[0];
				for(int i = 0; i < contact->GetManifold()->m_pointCount; point = &man.m_points[++i])
				{
					lua_rawgeti(clState, LUA_REGISTRYINDEX, clFunction);
					lua_pushboolean(clState, false);
					lua_pushlightuserdata(clState, fixtureA);
					lua_pushlightuserdata(clState, fixtureB);
					lua_pushlightuserdata(clState, bodyA);
					lua_pushlightuserdata(clState, bodyB);

					vec2_t *v = reinterpret_cast<vec2_t *> (lua_newuserdata(clState, sizeof(vec2_t)));
					luaL_getmetatable(clState, MATH_METATABLE);
					lua_setmetatable(clState, -2);
					v->x = point->x * unitScale;
					v->y = point->y * unitScale;
					MATH_POLAR(*v);

					v = reinterpret_cast<vec2_t *> (lua_newuserdata(clState, sizeof(vec2_t)));
					luaL_getmetatable(clState, MATH_METATABLE);
					lua_setmetatable(clState, -2);
					v->x = normal.x * unitScale;
					v->y = normal.y * unitScale;
					MATH_POLAR(*v);

					lua_call(clState, 7, 0);
				}
			}
		}
	}
};

static w_private_worldListener w_private_contactListener;

void w_init(lua_State *L)
{
}

int w_setUnitScale(lua_State *L)
{
	CHECKINIT(init, L);

	unitScale = luaL_checknumber(L, 1);

	return 0;
}

int w_newWorld(lua_State *L)
{
	CHECKINIT(init, L);

	const vec2_t *lower = CHECKVEC(L, 1);
	const vec2_t *upper = CHECKVEC(L, 2);
	const vec2_t *gravity = CHECKVEC(L, 3);
	allowSleep = lua_toboolean(L, 4);

	worldAABB.lowerBound.Set(lower->x * unitScale, lower->y * unitScale);
	worldAABB.upperBound.Set(upper->x * unitScale, upper->y * unitScale);

	worldGravity = b2Vec2(gravity->x * unitScale, gravity->y * unitScale);

	if(world)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_newWorld: memory leak detected: world wasn't freed properly\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	world = new b2World(worldAABB, worldGravity, allowSleep);

	world->SetContactListener(&w_private_contactListener);

	lua_pushvalue(L, 5);
	clFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	clState = L;

	if(!(lua_isfunction(L, 5) && lua_isfunction(L, 6) && lua_isfunction(L, 7) && lua_isfunction(L, 8) && lua_isfunction(L, 9) && lua_isfunction(L, 10) && lua_isfunction(L, 11) && lua_isfunction(L, 12) && lua_isfunction(L, 13) && lua_istable(L, 14) && lua_istable(L, 15) && lua_istable(L, 16) && lua_istable(L, 17) && lua_istable(L, 18) && lua_istable(L, 19) && lua_istable(L, 20) && lua_istable(L, 21) && lua_istable(L, 22)))
	{
		lua_pushliteral(L, "w_newWorld: invalid arguments passed for step\n");
		lua_error(L);
	}

	corpseTable = luaL_ref(L, LUA_REGISTRYINDEX);
	teleporterTable = luaL_ref(L, LUA_REGISTRYINDEX);
	flagTable = luaL_ref(L, LUA_REGISTRYINDEX);
	controlPointTable = luaL_ref(L, LUA_REGISTRYINDEX);
	powerupTable = luaL_ref(L, LUA_REGISTRYINDEX);
	powerupSpawnPointTable = luaL_ref(L, LUA_REGISTRYINDEX);
	projectileTable = luaL_ref(L, LUA_REGISTRYINDEX);
	wallTable = luaL_ref(L, LUA_REGISTRYINDEX);
	tankTable = luaL_ref(L, LUA_REGISTRYINDEX);
	corpseFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	teleporterFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	flagFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	controlPointFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	powerupFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	powerupSpawnPointFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	projectileFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	wallFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	tankFunction = luaL_ref(L, LUA_REGISTRYINDEX);

	lua_pop(L, 7);

	return 0;
}

int w_freeWorld(lua_State *L)
{
	CHECKINIT(init, L);

	if(!world)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_freeWorld: freeing unitialized world\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	delete world;
	world = NULL;

	luaL_unref(clState, LUA_REGISTRYINDEX, clFunction);
	clState = NULL;

	luaL_unref(L, LUA_REGISTRYINDEX, tankFunction);
	luaL_unref(L, LUA_REGISTRYINDEX, wallFunction);
	luaL_unref(L, LUA_REGISTRYINDEX, projectileFunction);
	luaL_unref(L, LUA_REGISTRYINDEX, powerupSpawnPointFunction);
	luaL_unref(L, LUA_REGISTRYINDEX, powerupFunction);
	luaL_unref(L, LUA_REGISTRYINDEX, controlPointFunction);
	luaL_unref(L, LUA_REGISTRYINDEX, flagFunction);
	luaL_unref(L, LUA_REGISTRYINDEX, teleporterFunction);
	luaL_unref(L, LUA_REGISTRYINDEX, corpseFunction);
	luaL_unref(L, LUA_REGISTRYINDEX, tankTable);
	luaL_unref(L, LUA_REGISTRYINDEX, wallTable);
	luaL_unref(L, LUA_REGISTRYINDEX, projectileTable);
	luaL_unref(L, LUA_REGISTRYINDEX, powerupSpawnPointTable);
	luaL_unref(L, LUA_REGISTRYINDEX, powerupTable);
	luaL_unref(L, LUA_REGISTRYINDEX, controlPointTable);
	luaL_unref(L, LUA_REGISTRYINDEX, flagTable);
	luaL_unref(L, LUA_REGISTRYINDEX, teleporterTable);
	luaL_unref(L, LUA_REGISTRYINDEX, corpseTable);

	return 0;
}

int w_setTimeStep(lua_State *L)
{
	CHECKINIT(init, L);

	timeStep = luaL_checknumber(L, 1);

	return 0;
}

int w_getTimeStep(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushnumber(L, timeStep);

	return 1;
}

int w_setIterations(lua_State *L)
{
	CHECKINIT(init, L);

	iterations = luaL_checkinteger(L, 1);

	return 0;
}

int w_getIterations(lua_State *L)
{
	CHECKINIT(init, L);

	lua_pushinteger(L, iterations);

	return 1;
}

int w_step(lua_State *L)
{
	CHECKINIT(init, L);

	world->Step(timeStep, iterations, iterations);

	return 0;
}

int w_addBody(lua_State *L)
{
	const vec2_t *v;

	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2BodyDef bodyDefinition;
	v = CHECKVEC(L, 1);
	bodyDefinition.position.Set(v->x * unitScale, v->y * unitScale);
	bodyDefinition.angle = luaL_checknumber(L, 2);
	bodyDefinition.allowSleep = lua_toboolean(L, 3);
	bodyDefinition.isBullet = lua_toboolean(L, 4);
	bodyDefinition.linearDamping = luaL_checknumber(L, 5);
	bodyDefinition.angularDamping = luaL_checknumber(L, 6);

	b2Body *body = world->CreateBody(&bodyDefinition);

	body->SetUserData(reinterpret_cast<void *> (luaL_checkinteger(L, 7)));

	lua_pop(L, 7);  /* balance stack */

	lua_pushlightuserdata(L, body);

	return 1;
}

int w_getBody(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Fixture *fixture = reinterpret_cast<b2Fixture *> (lua_touserdata(L, 1));
	if(!fixture)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_getBody: invalid fixture passed (has it been freed and reset?)\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	b2Body *body = fixture->GetBody();

	lua_pushlightuserdata(L, body);

	return 1;
}

int w_addFixture(lua_State *L)
{
	b2Body       *body;
	b2Fixture    *fixture;
	b2FixtureDef *fixtureDefinition;

	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));
	fixtureDefinition = reinterpret_cast<b2FixtureDef *> (lua_touserdata(L, 2));

	if(!body)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_addFixture: invalid body passed\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}
	if(!fixtureDefinition)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_addFixture: invalid fixture definition passed\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	fixture = body->CreateFixture(fixtureDefinition);
	if(!fixture)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_addFixture: could not add fixture\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	if(lua_toboolean(L, 3))
		body->SetMassFromShapes();  /* Dynamic */
	else
		body->SetMassData(&staticMassData);  /* Static */

	lua_pushlightuserdata(L, fixture);

	return 1;
}

int w_addFixtureFinal(lua_State *L)
{
	b2Body       *body;
	b2Fixture    *fixture;
	b2FixtureDef *fixtureDefinition;

	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));
	fixtureDefinition = reinterpret_cast<b2FixtureDef *> (lua_touserdata(L, 2));

	if(!body)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_addFixtureFinal: invalid body passed\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}
	if(!fixtureDefinition)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_addFixtureFinal: invalid fixture definition passed\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	fixture = body->CreateFixture(fixtureDefinition);
	if(!fixture)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_addFixtureFinal: could not add fixture\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	delete fixtureDefinition;

	if(lua_toboolean(L, 3))
		body->SetMassFromShapes();  /* Dynamic */
	else
		body->SetMassData(&staticMassData);  /* Static */

	lua_pushlightuserdata(L, fixture);

	return 1;
}

int w_addPolygonalFixture(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	if((!lua_istable(L, 1)) || !(lua_objlen(L, 1) > 0))
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_addPolygonalFixture: invalid polygon table\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	int numVertices = lua_objlen(L, 1);
	const vec2_t **vertices = reinterpret_cast<const vec2_t **>(calloc(numVertices, sizeof(vec2_t *)));
	int i = 0;
	lua_pushnil(L);
	while(lua_next(L, 1))
	{
		vertices[i++] = CHECKVEC(L, -1);

		lua_pop(L, 1);
	}

	m_orderVertices(vertices, numVertices, COUNTERCLOCKWISE);

	b2PolygonDef fixtureDefinition;
	fixtureDefinition.vertexCount = numVertices;
	for(int i = 0; i < numVertices; i++)
	{
		fixtureDefinition.vertices[i].Set(vertices[i]->x * unitScale, vertices[i]->y * unitScale);
	}

	free(vertices);

	fixtureDefinition.density = luaL_checknumber(L, 2);
	fixtureDefinition.friction = luaL_checknumber(L, 3);
	fixtureDefinition.restitution = luaL_checknumber(L, 4);

	fixtureDefinition.isSensor = lua_toboolean(L, 5);

	fixtureDefinition.filter.categoryBits = luaL_checkinteger(L, 6);
	fixtureDefinition.filter.maskBits = luaL_checkinteger(L, 7);

	b2FixtureDef *def = dynamic_cast<b2FixtureDef *>(&fixtureDefinition);

	if(!def)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_addPolygonalFixture: could not dynamically cast fixtureDefinition from type b2PolygonDef * to b2FixtureDef *\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 8));
	if(!body)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_addPolygonalFixture: invalid body passed\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	b2Fixture *fixture = body->CreateFixture(def);
	if(!fixture)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_addPolygonalFixture: could not add fixture to body\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	if(lua_toboolean(L, 9))
		body->SetMassFromShapes();  /* Dynamic */
	else
		body->SetMassData(&staticMassData);  /* Static */

	lua_pushlightuserdata(L, fixture);

	return 1;
}

int w_removeDefinition(lua_State *L)
{
	CHECKINIT(init, L);

	b2FixtureDef *fixtureDefinition = reinterpret_cast<b2FixtureDef *> (lua_touserdata(L, 1));
	if(!fixtureDefinition)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_removeDefinition: invalid fixture definition passed (was it already freed?)\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	delete fixtureDefinition;

	return 0;
}

int w_addPolygonDefinition(lua_State *L)
{
	CHECKINIT(init, L);

	if((!lua_istable(L, 1)) || !(lua_objlen(L, 1) > 0))
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_addPolygonDefinition: invalid polygon table\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	int numVertices = lua_objlen(L, 1);
	const vec2_t **vertices = reinterpret_cast<const vec2_t **>(calloc(numVertices, sizeof(vec2_t *)));
	int i = 0;
	lua_pushnil(L);
	while(lua_next(L, 1))
	{
		vertices[i++] = CHECKVEC(L, -1);

		lua_pop(L, 1);
	}

	m_orderVertices(vertices, numVertices, COUNTERCLOCKWISE);

	b2PolygonDef fixtureDefinition;
	fixtureDefinition.vertexCount = numVertices;
	for(int i = 0; i < numVertices; i++)
	{
		fixtureDefinition.vertices[i].Set(vertices[i]->x * unitScale, vertices[i]->y * unitScale);
	}

	free(vertices);

	fixtureDefinition.density = luaL_checknumber(L, 2);
	fixtureDefinition.friction = luaL_checknumber(L, 3);
	fixtureDefinition.restitution = luaL_checknumber(L, 4);

	fixtureDefinition.isSensor = lua_toboolean(L, 5);

	fixtureDefinition.filter.categoryBits = luaL_checkinteger(L, 6);
	fixtureDefinition.filter.maskBits = luaL_checkinteger(L, 7);

	b2FixtureDef *def = dynamic_cast<b2FixtureDef *>(new b2PolygonDef(fixtureDefinition));

	lua_pushlightuserdata(L, def);

	return 1;
}

int w_addCircularDefinition(lua_State *L)
{
	CHECKINIT(init, L);

	b2CircleDef fixtureDefinition;

	const vec2_t *v = CHECKVEC(L, 1);
	fixtureDefinition.localPosition = b2Vec2(v->x * unitScale, v->y * unitScale);
	fixtureDefinition.radius = luaL_checknumber(L, 2);

	fixtureDefinition.density = luaL_checknumber(L, 3);
	fixtureDefinition.friction = luaL_checknumber(L, 4);
	fixtureDefinition.restitution = luaL_checknumber(L, 5);

	fixtureDefinition.filter.categoryBits = luaL_checkinteger(L, 7);
	fixtureDefinition.filter.maskBits = luaL_checkinteger(L, 8);

	fixtureDefinition.isSensor = lua_toboolean(L, 9);

	b2FixtureDef *def = dynamic_cast<b2FixtureDef *>(new b2CircleDef(fixtureDefinition));

	lua_pushlightuserdata(L, def);

	return 1;
}

int w_fixtures(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));
	lua_pop(L, 1);
	if(!body)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_fixtures: invalid body passed\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	lua_newtable(L);
	b2Fixture *fixture = body->GetFixtureList();
	for(int i = 0; fixture; ++i, fixture = fixture->GetNext())
	{
		lua_pushinteger(L, i + 1);
		lua_pushlightuserdata(L, fixture);
		lua_settable(L, -3);
	}

	return 1;
}

int w_removeBody(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	world->DestroyBody(body);

	return 0;
}

int w_bodies(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	lua_createtable(L, world->GetBodyCount(), 0);

	int count = 1;
	for(b2Body *body = world->GetBodyList(); body; body = body->GetNext(), count++)
	{
		lua_pushinteger(L, count);
		lua_pushlightuserdata(L, body);
		lua_settable(L, -3);
	}

	return 1;
}

int w_isBullet(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	lua_pushboolean(L, body->IsBullet());

	return 1;
}

int w_setBullet(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	body->SetBullet(lua_toboolean(L, 2));
	lua_pushboolean(L, body->IsBullet());

	return 0;
}

int w_isStatic(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	lua_pushboolean(L, body->IsStatic());

	return 1;
}

int w_isDynamic(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	lua_pushboolean(L, body->IsDynamic());

	return 1;
}

int w_isSleeping(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	lua_pushboolean(L, body->IsSleeping());

	return 1;
}

int w_allowSleeping(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	body->AllowSleeping(lua_toboolean(L, 2));

	return 0;
}

int w_wakeUp(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	body->WakeUp();

	return 0;
}

int w_getPosition(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	b2Vec2 pos = body->GetPosition();

	vec2_t *v = reinterpret_cast<vec2_t *> (lua_newuserdata(L, sizeof(vec2_t)));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v->x = pos.x / unitScale;
	v->y = pos.y / unitScale;
	MATH_POLAR(*v);

	return 1;
}

int w_getAngle(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	double angle = body->GetAngle();

	lua_pushnumber(L, angle);

	return 1;
}

int w_setLinearVelocity(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	const vec2_t *v = CHECKVEC(L, 2);

	body->SetLinearVelocity(b2Vec2(v->x * unitScale, v->y * unitScale));

	return 0;
}

int w_getLinearVelocity(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	b2Vec2 vel = body->GetLinearVelocity();

	vec2_t *v = reinterpret_cast<vec2_t *> (lua_newuserdata(L, sizeof(vec2_t)));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v->x = vel.x / unitScale;
	v->y = vel.y / unitScale;
	MATH_POLAR(*v);

	if(isnan(v->x) || isnan(v->y) || isnan(v->R) || isnan(v->t) || isinf(v->x) || isinf(v->y) || isinf(v->R) || isinf(v->t) || isinf(-v->x) || isinf(-v->y) || isinf(-v->R) || isinf(-v->t))
	{
		v->x = v->y = v->R = v->t = 0;
	}

	return 1;
}

int w_setAngularVelocity(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	body->SetAngularVelocity(luaL_checknumber(L, 2));

	return 0;
}

int w_getAngularVelocity(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	double v = body->GetAngularVelocity();

	lua_pushnumber(L, v);

	return 1;
}

int w_setPosition(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	const vec2_t *v = CHECKVEC(L, 2);

	body->SetXForm(b2Vec2(v->x * unitScale, v->y * unitScale), body->GetAngle());

	return 0;
}

int w_setAngle(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	body->SetXForm(body->GetPosition(), luaL_checknumber(L, 2));

	return 0;
}

int w_applyForce(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	const vec2_t *force = CHECKVEC(L, 2);
	const vec2_t *point = CHECKVEC(L, 3);

	body->ApplyForce(b2Vec2(force->x * unitScale, force->y * unitScale), b2Vec2(point->x * unitScale, point->y * unitScale));

	return 0;
}

int w_applyTorque(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	double torque = luaL_checknumber(L, 2);

	body->ApplyTorque(torque);

	return 0;
}

int w_applyImpulse(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	const vec2_t *impulse = CHECKVEC(L, 2);
	const vec2_t *point = CHECKVEC(L, 3);

	body->ApplyImpulse(b2Vec2(impulse->x * unitScale, impulse->y * unitScale), b2Vec2(point->x * unitScale, point->y * unitScale));

	return 0;
}

int w_getCenterOfMass(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	b2Vec2 vec = body->GetWorldCenter();

	vec2_t *v = reinterpret_cast<vec2_t *> (lua_newuserdata(L, sizeof(vec2_t)));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v->x = vec.x / unitScale; v->y = vec.y / unitScale;
	MATH_POLAR(*v);

	return 1;
}

int w_scaleVelocity(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	auto double scale = luaL_checknumber(L, 1);

	for(b2Body *b = world->GetBodyList(); b; b = b->GetNext())
	{
		b->SetLinearVelocity(scale * b->GetLinearVelocity());
		b->SetAngularVelocity(scale * b->GetAngularVelocity());
	}

	return 0;
}

int w_getNumVertices(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Fixture *fixture = reinterpret_cast<b2Fixture *> (lua_touserdata(L, 1));
	lua_pop(L, 1);
	if(!fixture)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_getNumVertices: invalid fixture passed (has it been freed and reset?)\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	int num = 0;
	switch(fixture->GetType())
	{
		case b2_polygonShape:
		{
			const b2PolygonShape *shape = dynamic_cast<const b2PolygonShape *>(fixture->GetShape());
			num = shape->GetVertexCount();
			break;
		}

		default:
			num = 0;
			break;
	}

	lua_pushinteger(L, num);

	return 1;
}

int w_getVertices(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Fixture *fixture = reinterpret_cast<b2Fixture *> (lua_touserdata(L, 1));
	lua_remove(L, 1);
	if(!fixture)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_getVertices: invalid fixture passed (has it been freed and reset?)\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	if(!lua_istable(L, -1))
	{
		lua_pushliteral(L, "w_getVertices: no vertex table passed\n");
		lua_error(L);
	}

	int i = 0;
	switch(fixture->GetType())
	{
		case b2_polygonShape:
		{
			const b2PolygonShape *shape = dynamic_cast<const b2PolygonShape *>(fixture->GetShape());
			const b2Vec2 *vertices = shape->m_vertices;
			for(int j = 0; j < shape->GetVertexCount(); j++)
			{
				lua_pushinteger(L, ++i);
				lua_gettable(L, -2);
				vec2_t *v = CHECKVEC(L, -1);
				lua_pop(L, 1);

				v->x = vertices[j].x / unitScale;
				v->y = vertices[j].y / unitScale;
				MATH_POLAR(*v);
			}
			break;
		}

		default:
			break;
	}

	lua_pop(L, 1);

	return 0;
}

int w_getContents(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Fixture *fixture = reinterpret_cast<b2Fixture *> (lua_touserdata(L, 1));
	lua_pop(L, 1);
	if(!fixture)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_getContents: invalid fixture passed (has it been freed and reset?)\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	lua_pushinteger(L, fixture->GetFilterData().categoryBits);

	return 1;
}

int w_getClipmask(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Fixture *fixture = reinterpret_cast<b2Fixture *> (lua_touserdata(L, 1));
	lua_pop(L, 1);
	if(!fixture)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_getClipmask: invalid fixture passed (has it been freed and reset?)\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	lua_pushinteger(L, fixture->GetFilterData().maskBits);

	return 1;
}

int w_getBodyNumVertices(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));
	lua_pop(L, 1);

	int num = 0;
	for(b2Fixture *fixture = body->GetFixtureList(); fixture; fixture = fixture->GetNext())
	{
		switch(fixture->GetType())
		{
			case b2_polygonShape:
			{
				const b2PolygonShape *shape = dynamic_cast<const b2PolygonShape *>(fixture->GetShape());
				num += shape->GetVertexCount();
				break;
			}

			default:
				break;
		}
	}

	lua_pushinteger(L, num);

	return 1;
}

int w_getBodyVertices(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));
	lua_remove(L, 1);

	if(!lua_istable(L, -1))
	{
		lua_pushliteral(L, "w_getBodyVertices: no vertex table passed\n");
		lua_error(L);
	}

	int i = 0;
	for(b2Fixture *fixture = body->GetFixtureList(); fixture; fixture = fixture->GetNext())
	{
		switch(fixture->GetType())
		{
			case b2_polygonShape:
			{
				const b2PolygonShape *shape = dynamic_cast<const b2PolygonShape *>(fixture->GetShape());
				const b2Vec2 *vertices = shape->m_vertices;
				for(int j = 0; j < shape->GetVertexCount(); j++)
				{
					lua_pushinteger(L, ++i);
					lua_gettable(L, -2);
					vec2_t *v = CHECKVEC(L, -1);
					lua_pop(L, 1);

					v->x = vertices[j].x / unitScale;
					v->y = vertices[j].y / unitScale;
					MATH_POLAR(*v);
				}
				break;
			}

			default:
				break;
		}
	}

	lua_pop(L, 1);

	return 0;
}

int w_getBodyContents(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));
	lua_remove(L, 1);

	for(b2Fixture *fixture = body->GetFixtureList(); fixture; fixture = fixture->GetNext())
	{
		lua_pushinteger(L, fixture->GetFilterData().categoryBits);

		return 1;
	}

	lua_pushnil(L);

	return 1;
}

int w_getBodyClipmask(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));
	lua_remove(L, 1);

	for(b2Fixture *fixture = body->GetFixtureList(); fixture; fixture = fixture->GetNext())
	{
		lua_pushinteger(L, fixture->GetFilterData().maskBits);

		return 1;
	}

	lua_pushnil(L);

	return 1;
}

int w_getIndex(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));
	lua_settop(L, 0);

	lua_pushinteger(L, reinterpret_cast<long> (body->GetUserData()));

	return 1;
}

int w_setIndex(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *> (lua_touserdata(L, 1));

	body->SetUserData(reinterpret_cast<void *> (luaL_checkinteger(L, 2)));

	return 0;
}

#define STEP(function, table, d) \
do \
{ \
	lua_rawgeti(L, LUA_REGISTRYINDEX, function); \
	lua_rawgeti(L, LUA_REGISTRYINDEX, table); \
	lua_pushnil(L); \
	while(lua_next(L, 2)) \
	{ \
		lua_pushvalue(L, 1); \
		lua_pushnumber(L, d); \
		lua_pushvalue(L, -3); \
		lua_call(L, 2, 0); \
 \
		lua_pop(L, 1); \
	} \
	lua_pop(L, 2); \
} while(0)
int w_luaStep(lua_State *L)
{
	double d;

	CHECKINIT(init, L);

	CHECKWORLD(world, L);
	
	d = luaL_checknumber(L, 1);
	lua_pop(L, 1);

	STEP(tankFunction, tankTable, d);
	STEP(wallFunction, wallTable, d);
	STEP(projectileFunction, projectileTable, d);
	STEP(powerupSpawnPointFunction, powerupSpawnPointTable, d);
	STEP(powerupFunction, powerupTable, d);
	STEP(controlPointFunction, controlPointTable, d);
	STEP(flagFunction, flagTable, d);
	STEP(teleporterFunction, teleporterTable, d);
	STEP(corpseFunction, corpseTable, d);

	return 0;
}

int w_setContactListener(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	luaL_unref(clState, LUA_REGISTRYINDEX, clFunction);
	clState = NULL;

	lua_pushvalue(L, 1);
	clFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	clState = L;

	return 0;
}
