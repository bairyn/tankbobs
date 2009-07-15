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
#include <SDL/SDL.h>
#include <SDL/SDL_image.h>
#include <SDL/SDL_endian.h>
#include <cmath>

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
static int tankTable;
static int wallTable;
static int projectileTable;
static int powerupSpawnPointTable;
static int powerupTable;
static int controlPointTable;
static int flagTable;
static int teleporterTable;

class w_private_worldListener : public b2ContactListener
{
	public:
	void Add(const b2ContactPoint *point)
	{
		if(clState)
		{
			if(point->shape1->GetBody() && point->shape2->GetBody())
			{
				lua_rawgeti(clState, LUA_REGISTRYINDEX, clFunction);
				lua_pushlightuserdata(clState, point->shape1);
				lua_pushlightuserdata(clState, point->shape2);
				lua_pushlightuserdata(clState, point->shape1->GetBody());
				lua_pushlightuserdata(clState, point->shape2->GetBody());
				vec2_t *v = reinterpret_cast<vec2_t *>(lua_newuserdata(clState, sizeof(vec2_t)));

				luaL_getmetatable(clState, MATH_METATABLE);
				lua_setmetatable(clState, -2);
				v->x = point->position.x;
				v->y = point->position.y;
				MATH_POLAR(*v);
				lua_pushnumber(clState, point->separation);

				v = reinterpret_cast<vec2_t *>(lua_newuserdata(clState, sizeof(vec2_t)));

				luaL_getmetatable(clState, MATH_METATABLE);
				lua_setmetatable(clState, -2);
				v->x = point->normal.x;
				v->y = point->normal.y;
				MATH_POLAR(*v);

				lua_call(clState, 7, 0);
			}
		}
	}

	void Persist(const b2ContactPoint *point)
	{
		if(clState)
		{
		}
	}

	void Remove(const b2ContactPoint *point)
	{
		if(clState)
		{
		}
	}

	void Result(const b2ContactPoint *point)
	{
		if(clState)
		{
		}
	}
};

static w_private_worldListener w_private_contactListener;

void w_init(lua_State *L)
{
}

int w_newWorld(lua_State *L)
{
	CHECKINIT(init, L);

	const vec2_t *lower = CHECKVEC(L, 1);
	const vec2_t *upper = CHECKVEC(L, 2);
	const vec2_t *gravity = CHECKVEC(L, 3);
	allowSleep = lua_toboolean(L, 4);

	worldAABB.lowerBound.Set(lower->x, lower->y);
	worldAABB.upperBound.Set(upper->x, upper->y);

	worldGravity = b2Vec2(gravity->x, gravity->y);

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

	if(!(lua_isfunction(L, 6) && lua_isfunction(L, 7) && lua_isfunction(L, 8) && lua_isfunction(L, 9), lua_isfunction(L, 10) && lua_isfunction(L, 11) && lua_isfunction(L, 12) && lua_isfunction(L, 13) && lua_istable(L, 14) && lua_istable(L, 15) && lua_istable(L, 16) && lua_istable(L, 17) && lua_istable(L, 18) && lua_istable(L, 19) && lua_istable(L, 20) && lua_istable(L, 21)))
	{
		lua_pushliteral(L, "w_newWorld: invalid arguments passed for step\n");
		lua_error(L);
	}

	teleporterTable = luaL_ref(L, LUA_REGISTRYINDEX);
	flagTable = luaL_ref(L, LUA_REGISTRYINDEX);
	controlPointTable = luaL_ref(L, LUA_REGISTRYINDEX);
	powerupTable = luaL_ref(L, LUA_REGISTRYINDEX);
	powerupSpawnPointTable = luaL_ref(L, LUA_REGISTRYINDEX);
	projectileTable = luaL_ref(L, LUA_REGISTRYINDEX);
	wallTable = luaL_ref(L, LUA_REGISTRYINDEX);
	tankTable = luaL_ref(L, LUA_REGISTRYINDEX);
	teleporterFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	flagFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	controlPointFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	powerupFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	powerupSpawnPointFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	projectileFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	wallFunction = luaL_ref(L, LUA_REGISTRYINDEX);
	tankFunction = luaL_ref(L, LUA_REGISTRYINDEX);

	lua_pop(L, 5);

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
	luaL_unref(L, LUA_REGISTRYINDEX, tankTable);
	luaL_unref(L, LUA_REGISTRYINDEX, wallTable);
	luaL_unref(L, LUA_REGISTRYINDEX, projectileTable);
	luaL_unref(L, LUA_REGISTRYINDEX, powerupSpawnPointTable);
	luaL_unref(L, LUA_REGISTRYINDEX, powerupTable);
	luaL_unref(L, LUA_REGISTRYINDEX, controlPointTable);
	luaL_unref(L, LUA_REGISTRYINDEX, flagTable);
	luaL_unref(L, LUA_REGISTRYINDEX, teleporterTable);

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

	world->Step(timeStep, iterations);

	return 0;
}

int w_addBody(lua_State *L)
{
	const vec2_t *v;

	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2BodyDef bodyDefinition;
	v = CHECKVEC(L, 1);
	bodyDefinition.position.Set(v->x, v->y);
	bodyDefinition.angle = luaL_checknumber(L, 2);
	bodyDefinition.allowSleep = lua_toboolean(L, 3);
	bodyDefinition.isBullet = lua_toboolean(L, 4);
	bodyDefinition.linearDamping = luaL_checknumber(L, 5);
	bodyDefinition.angularDamping = luaL_checknumber(L, 6);

	b2Body *body = world->CreateBody(&bodyDefinition);

	if((!lua_istable(L, 7)) || !(lua_objlen(L, 7) > 0))
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_addBody: invalid polygon table\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	int numVertices = lua_objlen(L, 7);
	const vec2_t *vertices[numVertices];
	int i = 0;
	lua_pushnil(L);
	while(lua_next(L, 7))
	{
		vertices[i++] = CHECKVEC(L, -1);

		lua_pop(L, 1);
	}

	m_orderVertices(vertices, numVertices, COUNTERCLOCKWISE);

	b2PolygonDef shapeDefinition;
	shapeDefinition.vertexCount = numVertices;
	for(int i = 0; i < numVertices; i++)
	{
		shapeDefinition.vertices[i].Set(vertices[i]->x, vertices[i]->y);
	}

	shapeDefinition.density = luaL_checknumber(L, 8);
	shapeDefinition.friction = luaL_checknumber(L, 9);
	shapeDefinition.restitution = luaL_checknumber(L, 10);

	shapeDefinition.filter.categoryBits = luaL_checkinteger(L, 12);
	shapeDefinition.filter.maskBits = luaL_checkinteger(L, 13);

	body->CreateShape(&shapeDefinition);
	if(lua_toboolean(L, 11))
		body->SetMassFromShapes();

	lua_pushlightuserdata(L, body);

	return 1;
}

int w_removeBody(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

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

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	lua_pushboolean(L, body->IsBullet());

	return 1;
}

int w_setBullet(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	body->SetBullet(lua_toboolean(L, 2));
	lua_pushboolean(L, body->IsBullet());

	return 0;
}

int w_isStatic(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	lua_pushboolean(L, body->IsStatic());

	return 1;
}

int w_isDynamic(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	lua_pushboolean(L, body->IsDynamic());

	return 1;
}

int w_isSleeping(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	lua_pushboolean(L, body->IsSleeping());

	return 1;
}

int w_allowSleeping(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	body->AllowSleeping(lua_toboolean(L, 2));

	return 0;
}

int w_wakeUp(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	body->WakeUp();

	return 0;
}

int w_getPosition(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	b2Vec2 pos = body->GetPosition();

	vec2_t *v = reinterpret_cast<vec2_t *>(lua_newuserdata(L, sizeof(vec2_t)));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v->x = pos.x;
	v->y = pos.y;
	MATH_POLAR(*v);

	return 1;
}

int w_getAngle(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	double angle = body->GetAngle();

	lua_pushnumber(L, angle);

	return 1;
}

int w_setLinearVelocity(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	const vec2_t *v = CHECKVEC(L, 2);

	body->SetLinearVelocity(b2Vec2(v->x, v->y));

	return 0;
}

int w_getLinearVelocity(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	b2Vec2 vel = body->GetLinearVelocity();

	vec2_t *v = reinterpret_cast<vec2_t *>(lua_newuserdata(L, sizeof(vec2_t)));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v->x = vel.x;
	v->y = vel.y;
	MATH_POLAR(*v);

	return 1;
}

int w_setAngularVelocity(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	body->SetAngularVelocity(luaL_checknumber(L, 2));

	return 0;
}

int w_getAngularVelocity(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	double v = body->GetAngularVelocity();

	lua_pushnumber(L, v);

	return 1;
}

int w_setPosition(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	const vec2_t *v = CHECKVEC(L, 2);

	body->SetXForm(b2Vec2(v->x, v->y), body->GetAngle());

	return 0;
}

int w_setAngle(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	body->SetXForm(body->GetPosition(), luaL_checknumber(L, 2));

	return 0;
}

int w_applyForce(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	const vec2_t *force = CHECKVEC(L, 2);
	const vec2_t *point = CHECKVEC(L, 3);

	body->ApplyForce(b2Vec2(force->x, force->y), b2Vec2(point->x, point->y));

	return 0;
}

int w_applyTorque(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	double torque = luaL_checknumber(L, 2);

	body->ApplyTorque(torque);

	return 0;
}

int w_applyImpulse(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	const vec2_t *impulse = CHECKVEC(L, 2);
	const vec2_t *point = CHECKVEC(L, 3);

	body->ApplyImpulse(b2Vec2(impulse->x, impulse->y), b2Vec2(point->x, point->y));

	return 0;
}

int w_getCenterOfMass(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));

	b2Vec2 vec = body->GetWorldCenter();

	vec2_t *v = reinterpret_cast<vec2_t *>(lua_newuserdata(L, sizeof(vec2_t)));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v->x = vec.x; v->y = vec.y;
	MATH_POLAR(*v);

	return 1;
}

int w_scaleVelocity(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	double scale = luaL_checknumber(L, 1);

	for(b2Body *b = world->GetBodyList(); b; b = b->GetNext())
	{
		b->SetLinearVelocity(scale * b->GetLinearVelocity());
		b->SetAngularVelocity(scale * b->GetAngularVelocity());
	}

	return 0;
}

int w_persistWorld(lua_State *L)
{
	char buf[BUFSIZE] = {""};
	char *bufpos = &buf[0];
	int numProjectiles, numTanks, numPowerups, numWalls;
	const vec2_t *v;
	const b2Body *body;
	b2Vec2 vel;

	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	/* 16-byte header */
	numProjectiles = lua_objlen(L, 1); *((int *) bufpos) = io_intNL(numProjectiles); bufpos += sizeof(int);
	numTanks       = lua_objlen(L, 2); *((int *) bufpos) = io_intNL(numTanks);       bufpos += sizeof(int);
	numPowerups    = lua_objlen(L, 3); *((int *) bufpos) = io_intNL(numPowerups);    bufpos += sizeof(int);
	numWalls       = lua_objlen(L, 4); *((int *) bufpos) = io_intNL(numWalls);       bufpos += sizeof(int);

	/* world */

	/* projectiles */
	lua_pushnil(L);
	while(lua_next(L, 1))
	{
		/* projectiles are described as: */
		/* int key (the client will generate a new body if projectiles[key] is nil); int weaponTypeIndex; double rotation; double x; double y; double velX; double velY; */
		lua_getfield(L, -1, "collided");
		if(lua_toboolean(L, -1) &&
		   bufpos + 2 * sizeof(int) + 4 * sizeof(double) < buf + sizeof(buf))
		{
			lua_pop(L, 1);

			/* set key */
			*((int *) bufpos) = io_intNL(luaL_checkinteger(L, -2)); bufpos += sizeof(int);

			/* set weaponIndex */
			lua_getfield(L, -1, "weapon");
			lua_getfield(L, -1, "index");
			*((int *) bufpos) = io_intNL(luaL_checkinteger(L, -1)); bufpos += sizeof(int);
			lua_pop(L, 2);

			/* set rotation */
			lua_getfield(L, -1, "r");
			*((double *) bufpos) = io_doubleNL(luaL_checknumber(L, -1)); bufpos += sizeof(double);
			lua_pop(L, 1);

			/* set x and y */
			lua_getfield(L, -1, "p");
			lua_pushinteger(L, 1);
			lua_gettable(L, -1);
			v = CHECKVEC(L, -1);
			*((double *) bufpos) = io_doubleNL(v->x); bufpos += sizeof(double);
			*((double *) bufpos) = io_doubleNL(v->y); bufpos += sizeof(double);
			lua_pop(L, 2);

			/* velocity */
			lua_getfield(L, -1, "m");
			lua_getfield(L, -1, "body");
			body = reinterpret_cast<b2Body *>(lua_touserdata(L, -1));
			vel = body->GetLinearVelocity();
			lua_pop(L, 2);
			*((double *) bufpos) = io_doubleNL(vel.x); bufpos += sizeof(double);
			*((double *) bufpos) = io_doubleNL(vel.y); bufpos += sizeof(double);

			lua_pop(L, 1);
		}
		else
		{
			lua_pop(L, 2);

			/* decrement the number of projectiles */
			*(((int *) &buf[0]) + 0) = --numProjectiles;
		}
	}

	/* tanks */
	lua_pushnil(L);
	while(lua_next(L, 1))
	{
		/* tanks are described as: */
		/* int key (the client will generate a new body if projectiles[key] is nil); int weaponTypeIndex; double rotation; double x; double y; double velX; double velY; double h[xy][1-4]; double r; double g; double b; double health; */
		lua_getfield(L, -1, "exists");
		if(lua_toboolean(L, -1) &&
		   bufpos + 2 * sizeof(int) + 17 * sizeof(double) + 1 * sizeof(int) < buf + sizeof(buf))
		{
			lua_pop(L, 1);

			/* set key */
			*((int *) bufpos) = io_intNL(luaL_checkinteger(L, -2)); bufpos += sizeof(int);

			/* set weaponIndex */
			lua_getfield(L, -1, "weapon");
			lua_getfield(L, -1, "index");
			*((int *) bufpos) = io_intNL(luaL_checkinteger(L, -1)); bufpos += sizeof(int);
			lua_pop(L, 2);

			/* set rotation */
			lua_getfield(L, -1, "r");
			*((double *) bufpos) = io_doubleNL(luaL_checknumber(L, -1)); bufpos += sizeof(double);
			lua_pop(L, 1);

			/* set x and y */
			lua_getfield(L, -1, "p");
			lua_pushinteger(L, 1);
			lua_gettable(L, -1);
			v = CHECKVEC(L, -1);
			*((double *) bufpos) = io_doubleNL(v->x); bufpos += sizeof(double);
			*((double *) bufpos) = io_doubleNL(v->y); bufpos += sizeof(double);
			lua_pop(L, 2);

			/* velocity */
			lua_getfield(L, -1, "m");
			lua_getfield(L, -1, "body");
			body = reinterpret_cast<b2Body *>(lua_touserdata(L, -1));
			vel = body->GetLinearVelocity();
			lua_pop(L, 2);
			*((double *) bufpos) = io_doubleNL(vel.x); bufpos += sizeof(double);
			*((double *) bufpos) = io_doubleNL(vel.y); bufpos += sizeof(double);

			/* hull */
			lua_getfield(L, -1, "h");
			lua_pushinteger(L, 1);
			lua_gettable(L, -1);
			v = CHECKVEC(L, -1);
			*((double *) bufpos) = io_doubleNL(v->x); bufpos += sizeof(double);
			*((double *) bufpos) = io_doubleNL(v->y); bufpos += sizeof(double);
			lua_pop(L, 1);
			lua_pushinteger(L, 2);
			lua_gettable(L, -1);
			v = CHECKVEC(L, -1);
			*((double *) bufpos) = io_doubleNL(v->x); bufpos += sizeof(double);
			*((double *) bufpos) = io_doubleNL(v->y); bufpos += sizeof(double);
			lua_pop(L, 1);
			lua_pushinteger(L, 3);
			lua_gettable(L, -1);
			v = CHECKVEC(L, -1);
			*((double *) bufpos) = io_doubleNL(v->x); bufpos += sizeof(double);
			*((double *) bufpos) = io_doubleNL(v->y); bufpos += sizeof(double);
			lua_pop(L, 1);
			lua_pushinteger(L, 4);
			lua_gettable(L, -1);
			v = CHECKVEC(L, -1);
			*((double *) bufpos) = io_doubleNL(v->x); bufpos += sizeof(double);
			*((double *) bufpos) = io_doubleNL(v->y); bufpos += sizeof(double);
			lua_pop(L, 2);

			/* color */
			lua_getfield(L, -1, "color");
			lua_getfield(L, -1, "r");
			*((double *) bufpos) = io_doubleNL(lua_tonumber(L, -1)); bufpos += sizeof(double);
			lua_pop(L, 1);
			lua_getfield(L, -1, "g");
			*((double *) bufpos) = io_doubleNL(lua_tonumber(L, -1)); bufpos += sizeof(double);
			lua_pop(L, 1);
			lua_getfield(L, -1, "b");
			*((double *) bufpos) = io_doubleNL(lua_tonumber(L, -1)); bufpos += sizeof(double);
			lua_pop(L, 2);

			/* health */
			lua_getfield(L, -1, "health");
			*((double *) bufpos) = io_doubleNL(lua_tonumber(L, -1)); bufpos += sizeof(double);
			lua_pop(L, 1);

			/* score */
			lua_getfield(L, -1, "score");
			*((int *) bufpos) = io_intNL(luaL_checkinteger(L, -1)); bufpos += sizeof(int);
			lua_pop(L, 1);

			lua_pop(L, 1);
		}
		else
		{
			lua_pop(L, 2);

			/* decrement the number of tanks */
			*(((int *) &buf[0]) + 1) = --numTanks;
		}
	}

	/* powerups */
	lua_pushnil(L);
	while(lua_next(L, 1))
	{
		/* powerups are described as: */
		/* int key (the client will generate a new body if projectiles[key] is nil); int poweuprTypeIndex; double rotation; double x; double y; double velX; double velY; double h[xy][1-4]; */
		lua_getfield(L, -1, "exists");
		if(lua_toboolean(L, -1) &&
		   bufpos + 2 * sizeof(int) + 8 * sizeof(double) < buf + sizeof(buf))
		{
			lua_pop(L, 1);

			/* set key */
			*((int *) bufpos) = io_intNL(luaL_checkinteger(L, -2)); bufpos += sizeof(int);

			/* set weaponIndex */
			lua_getfield(L, -1, "type");
			lua_getfield(L, -1, "index");
			*((int *) bufpos) = io_intNL(luaL_checkinteger(L, -1)); bufpos += sizeof(int);
			lua_pop(L, 2);

			/* set rotation */
			lua_getfield(L, -1, "r");
			*((double *) bufpos) = io_doubleNL(luaL_checknumber(L, -1)); bufpos += sizeof(double);
			lua_pop(L, 1);

			/* set x and y */
			lua_getfield(L, -1, "p");
			lua_pushinteger(L, 1);
			lua_gettable(L, -1);
			v = CHECKVEC(L, -1);
			*((double *) bufpos) = io_doubleNL(v->x); bufpos += sizeof(double);
			*((double *) bufpos) = io_doubleNL(v->y); bufpos += sizeof(double);
			lua_pop(L, 2);

			/* velocity */
			lua_getfield(L, -1, "m");
			lua_getfield(L, -1, "body");
			body = reinterpret_cast<b2Body *>(lua_touserdata(L, -1));
			vel = body->GetLinearVelocity();
			lua_pop(L, 2);
			*((double *) bufpos) = io_doubleNL(vel.x); bufpos += sizeof(double);
			*((double *) bufpos) = io_doubleNL(vel.y); bufpos += sizeof(double);

			/* color */
			lua_getfield(L, -1, "color");
			lua_getfield(L, -1, "r");
			*((double *) bufpos) = io_doubleNL(lua_tonumber(L, -1)); bufpos += sizeof(double);
			lua_pop(L, 1);
			lua_getfield(L, -1, "g");
			*((double *) bufpos) = io_doubleNL(lua_tonumber(L, -1)); bufpos += sizeof(double);
			lua_pop(L, 1);
			lua_getfield(L, -1, "b");
			*((double *) bufpos) = io_doubleNL(lua_tonumber(L, -1)); bufpos += sizeof(double);
			lua_pop(L, 2);

			lua_pop(L, 1);
		}
		else
		{
			lua_pop(L, 2);

			/* decrement the number of powerups */
			*(((int *) &buf[0]) + 2) = --numPowerups;
		}
	}

	/* walls */
	lua_pushnil(L);
	while(lua_next(L, 1))
	{
		/* walls are described as: */
		/* int key; char fourVertices; double p[xy][1-4]; double bodyRotation; double angularVelocity; double linearVelocity[xy]; */
		lua_getfield(L, -1, "m");
		lua_getfield(L, -1, "body");
		if(lua_toboolean(L, -1) &&
		   bufpos + 1 * sizeof(int) + 1 * sizeof(char) + 12 * sizeof(double) < buf + sizeof(buf))
		{
			vec2_t *tmp;
			b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, -1));
			lua_pop(L, 2);

			/* set key */
			*((int *) bufpos) = io_intNL(luaL_checkinteger(L, -2)); bufpos += sizeof(int);

			/* see if p[4] exists */
			lua_getfield(L, -1, "p");
			lua_pushinteger(L, 4);
			lua_gettable(L, -2);
			if(lua_isnoneornil(L, -1))
			{
				tmp = NULL;

				*bufpos++ = io_charNL(FALSE);
			}
			else
			{
				tmp = CHECKVEC(L, -1);

				*bufpos++ = io_charNL(TRUE);
			}
			lua_pop(L, 1);

			/* set p[1-4] (client should ignore these for static walls, even if they are linked to a path) */
			/* p is still on the stack */
			lua_pushinteger(L, 1);
			lua_gettable(L, -2);
			v = CHECKVEC(L, -1);
			*((double *) bufpos) = io_doubleNL(v->x); bufpos += sizeof(double);
			*((double *) bufpos) = io_doubleNL(v->y); bufpos += sizeof(double);
			lua_pop(L, 1);
			lua_pushinteger(L, 2);
			lua_gettable(L, -2);
			v = CHECKVEC(L, -1);
			*((double *) bufpos) = io_doubleNL(v->x); bufpos += sizeof(double);
			*((double *) bufpos) = io_doubleNL(v->y); bufpos += sizeof(double);
			lua_pop(L, 1);
			lua_pushinteger(L, 3);
			lua_gettable(L, -2);
			v = CHECKVEC(L, -1);
			*((double *) bufpos) = io_doubleNL(v->x); bufpos += sizeof(double);
			*((double *) bufpos) = io_doubleNL(v->y); bufpos += sizeof(double);
			lua_pop(L, 2);
			if(tmp)
			{
				*((double *) bufpos) = io_doubleNL(tmp->x); bufpos += sizeof(double);
				*((double *) bufpos) = io_doubleNL(tmp->y); bufpos += sizeof(double);
			}
			else
			{
				/* *((double *) bufpos) = 0x00; bufpos += sizeof(double); */
				/* *((double *) bufpos) = 0x00; bufpos += sizeof(double); */

				/* These two bytes are ignored by the client, but they need to be filled */
				bufpos += 2 * sizeof(double);
			}

			/* set body's rotation */
			*((double *) bufpos) = io_doubleNL(body->GetAngle()); bufpos += sizeof(double);

			/* angular velocity */
			*((double *) bufpos) = io_doubleNL(body->GetAngularVelocity()); bufpos += sizeof(double);

			/* linear velocity */
			vel = body->GetLinearVelocity();
			*((double *) bufpos) = io_doubleNL(vel.x); bufpos += sizeof(double);
			*((double *) bufpos) = io_doubleNL(vel.y); bufpos += sizeof(double);

			/* TODO: send path info */

			lua_pop(L, 1);
		}
		else
		{
			lua_pop(L, 3);

			/* decrement the number of walls */
			*(((int *) &buf[0]) + 3) = --numWalls;
		}
	}

	lua_pushlstring(L, buf, bufpos - buf);

	return 1;
}

int w_getVertices(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));
	lua_remove(L, 1);

	if(!lua_istable(L, -1))
	{
		lua_pushliteral(L, "no table passed to \n");
		lua_error(L);
	}

	for(b2Shape *bshape = body->GetShapeList(); bshape; bshape = bshape->GetNext())
	{
		b2PolygonShape *shape = static_cast<b2PolygonShape *>(bshape);

		const b2Vec2 *vertices = shape->GetVertices();
		for(int i = 0; i < shape->GetVertexCount(); i++)
		{
			lua_pushinteger(L, i + 1);
			lua_gettable(L, -2);
			vec2_t *v = CHECKVEC(L, -1);
			lua_pop(L, 1);

			v->x = vertices[i].x;
			v->y = vertices[i].y;
			MATH_POLAR(*v);
		}
	}

	lua_pop(L, 1);

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

	return 0;
}
