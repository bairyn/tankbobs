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

	shapeDefinition.isSensor = lua_toboolean(L, 14);

	body->CreateShape(&shapeDefinition);
	if(lua_toboolean(L, 11))
		body->SetMassFromShapes();

	body->SetUserData(reinterpret_cast<void *>(luaL_checkinteger(L, 15)));

	lua_pop(L, 15);  /* "balance" stack */

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
	char   buf[BUFSIZE] = {""};
	char   *bufpos = &buf[0];
	short  numProjectiles, numTanks, numPowerups;
	int    numWalls, numControlPoints, numFlags;
	int    order;
	const  vec2_t *v;
	const  b2Body *body;
	b2Vec2 vel;

	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	order = 0;

	numProjectiles   = lua_objlen(L, ++order); *((short *) bufpos) = io_shortNL(numProjectiles); bufpos += sizeof(short);
	numTanks         = lua_objlen(L, ++order); *((short *) bufpos) = io_shortNL(numTanks);       bufpos += sizeof(short);
	numPowerups      = lua_objlen(L, ++order); *((short *) bufpos) = io_shortNL(numPowerups);    bufpos += sizeof(short);
	numWalls         = lua_objlen(L, ++order);  /* number of walls is constant */
	numControlPoints = lua_objlen(L, ++order);  /* number of control points is constant */
	numFlags         = lua_objlen(L, ++order);  /* number of flags is constant */

	order = 0;

	/* projectiles */
	/* char weaponTypeIndex; float rotation; float x; float y; float velX; float velY; float angularVelocity; */
	++order;
	lua_pushnil(L);
	while(lua_next(L, order))
	{
		lua_getfield(L, -1, "collided");
		if(!lua_toboolean(L, -1) &&
				bufpos + 1 * sizeof(char) + 6 * sizeof(float) < buf + sizeof(buf))
		{
			lua_pop(L, 1);

			/* set weaponIndex */
			lua_getfield(L, -1, "weapon");
			*((char *) bufpos) = io_charNL(lua_tonumber(L, -1)); bufpos += sizeof(char);
			lua_pop(L, 1);

			/* set rotation */
			lua_getfield(L, -1, "r");
			*((float *) bufpos) = io_floatNL(lua_tonumber(L, -1)); bufpos += sizeof(float);
			lua_pop(L, 1);

			/* set x and y */
			lua_getfield(L, -1, "p");
			v = CHECKVEC(L, -1);
			*((float *) bufpos) = io_floatNL(v->x); bufpos += sizeof(float);
			*((float *) bufpos) = io_floatNL(v->y); bufpos += sizeof(float);
			lua_pop(L, 1);

			/* velocity */
			lua_getfield(L, -1, "m");
			lua_getfield(L, -1, "body");
			body = reinterpret_cast<b2Body *>(lua_touserdata(L, -1));
			lua_pop(L, 2);
			vel = body->GetLinearVelocity();
			*((float *) bufpos) = io_floatNL(vel.x); bufpos += sizeof(float);
			*((float *) bufpos) = io_floatNL(vel.y); bufpos += sizeof(float);

			/* angular velocity */
			*((float *) bufpos) = io_floatNL(body->GetAngularVelocity()); bufpos += sizeof(float);
		}
		else
		{
			lua_pop(L, 1);

			*(((short *) &buf[0]) + order - 1) = --numProjectiles;
		}

		lua_pop(L, 1);
	}

	/* tanks */
	/* char index; char name[21]; float rotation; float x; float y; float velX; float velY; short input; */
	++order;
	lua_pushnil(L);
	while(lua_next(L, order))
	{
		lua_getfield(L, -1, "exists");
		if(lua_toboolean(L, -1) &&
				1 * sizeof(char) + bufpos + 5 * sizeof(float) + 1 * sizeof(short) < buf + sizeof(buf))
		{
			static char name[21];

			lua_pop(L, 1);

			/* set index */
			*((char *) bufpos) = io_charNL((unsigned int) lua_tonumber(L, -2)); bufpos += sizeof(char);

			/* set name */
			lua_getfield(L, -1, "name");
			strncpy(name, lua_tostring(L, -1), sizeof(name));
			lua_pop(L, 1);
			memcpy(bufpos, name, sizeof(name)); bufpos += sizeof(name);

			/* set rotation */
			lua_getfield(L, -1, "r");
			*((float *) bufpos) = io_floatNL(lua_tonumber(L, -1)); bufpos += sizeof(float);
			lua_pop(L, 1);

			/* set x and y */
			lua_getfield(L, -1, "p");
			v = CHECKVEC(L, -1);
			*((float *) bufpos) = io_floatNL(v->x); bufpos += sizeof(float);
			*((float *) bufpos) = io_floatNL(v->y); bufpos += sizeof(float);
			lua_pop(L, 1);

			/* velocity */
			lua_getfield(L, -1, "body");
			body = reinterpret_cast<b2Body *>(lua_touserdata(L, -1));
			lua_pop(L, 1);
			vel = body->GetLinearVelocity();
			*((float *) bufpos) = io_floatNL(vel.x); bufpos += sizeof(float);
			*((float *) bufpos) = io_floatNL(vel.y); bufpos += sizeof(float);

			/* input */
			lua_getfield(L, -1, "state");
			*((short *) bufpos) = io_shortNL(lua_tointeger(L, -1)); bufpos += sizeof(short);
			lua_pop(L, 1);
		}
		else
		{
			lua_pop(L, 1);

			*(((short *) &buf[0]) + order - 1) = --numTanks;
		}

		lua_pop(L, 1);
	}

	/* powerups */
	/* char index; char powerupTypeIndex; float rotation; float x; float y; float velX; float velY; float angularVelocity; */
	++order;
	lua_pushnil(L);
	while(lua_next(L, order))
	{
		lua_getfield(L, -1, "collided");
		if(!lua_toboolean(L, -1) &&
				bufpos + 2 * sizeof(char) + 6 * sizeof(float) < buf + sizeof(buf))
		{
			lua_pop(L, 1);

			/* set index */
			*((char *) bufpos) = io_charNL((unsigned int) lua_tonumber(L, -2)); bufpos += sizeof(char);

			/* set weaponIndex */
			lua_getfield(L, -1, "weapon");
			lua_getfield(L, -1, "index");
			*((char *) bufpos) = io_charNL(lua_tonumber(L, -1)); bufpos += sizeof(char);
			lua_pop(L, 2);

			/* set rotation */
			lua_getfield(L, -1, "r");
			*((float *) bufpos) = io_floatNL(lua_tonumber(L, -1)); bufpos += sizeof(float);
			lua_pop(L, 1);

			/* set x and y */
			lua_getfield(L, -1, "p");
			v = CHECKVEC(L, -1);
			*((float *) bufpos) = io_floatNL(v->x); bufpos += sizeof(float);
			*((float *) bufpos) = io_floatNL(v->y); bufpos += sizeof(float);
			lua_pop(L, 1);

			/* velocity */
			lua_getfield(L, -1, "m");
			lua_getfield(L, -1, "body");
			body = reinterpret_cast<b2Body *>(lua_touserdata(L, -1));
			lua_pop(L, 2);
			vel = body->GetLinearVelocity();
			*((float *) bufpos) = io_floatNL(vel.x); bufpos += sizeof(float);
			*((float *) bufpos) = io_floatNL(vel.y); bufpos += sizeof(float);

			/* angular velocity */
			*((float *) bufpos) = io_floatNL(body->GetAngularVelocity()); bufpos += sizeof(float);
		}
		else
		{
			lua_pop(L, 1);

			*(((short *) &buf[0]) + order - 1) = --numPowerups;
		}

		lua_pop(L, 1);
	}

	/* walls */
	/* float (x|y); float angle; float velX; float velY; float angularVelocity; float pathID; float previousPathID; float startpos(x|y); float pathPos; */
	++order;
	lua_pushnil(L);
	while(lua_next(L, order))
	{
		if(bufpos + 6 * sizeof(float) + 2 * sizeof(char) + 3 * sizeof(float) < buf + sizeof(buf))
		{
			/* set x and y */
			/* (get body) */
			lua_getfield(L, -1, "m");
			lua_getfield(L, -1, "body");
			body = reinterpret_cast<b2Body *>(lua_touserdata(L, -1));
			if(!body)
			{
				/*
				*((char *) bufpos) = io_charNL(0x00); bufpos += sizeof(char);
				*((char *) bufpos) = io_charNL(0x00); bufpos += sizeof(char);
				*((float *) bufpos) = io_floatNL(0x00); bufpos += sizeof(float);
				*/

				bufpos += 2 * sizeof(char) + 1 * sizeof(float);

				lua_pop(L, 3);

				continue;
			}
			lua_pop(L, 1);  /* keep m on the stack */
			*((float *) bufpos) = io_floatNL(body->GetPosition().x); bufpos += sizeof(float);
			*((float *) bufpos) = io_floatNL(body->GetPosition().y); bufpos += sizeof(float);

			/* set angle */
			*((float *) bufpos) = io_floatNL(body->GetAngle()); bufpos += sizeof(float);

			/* velocity */
			vel = body->GetLinearVelocity();
			*((float *) bufpos) = io_floatNL(vel.x); bufpos += sizeof(float);
			*((float *) bufpos) = io_floatNL(vel.y); bufpos += sizeof(float);

			/* angular velocity */
			*((float *) bufpos) = io_floatNL(body->GetAngularVelocity()); bufpos += sizeof(float);

			/* path information */
			lua_getfield(L, -1, "pid");
			if(lua_toboolean(L, -1))
			{
				*((char *) bufpos) = io_charNL(lua_tonumber(L, -1)); bufpos += sizeof(char);
				lua_pop(L, 1);

				lua_getfield(L, -1, "ppid");
				*((char *) bufpos) = io_charNL(lua_tonumber(L, -1)); bufpos += sizeof(char);
				lua_pop(L, 1);

				lua_getfield(L, -1, "startpos");
				v = CHECKVEC(L, -1);
				*((float *) bufpos) = io_floatNL(v->x); bufpos += sizeof(float);
				*((float *) bufpos) = io_floatNL(v->y); bufpos += sizeof(float);
				lua_pop(L, 1);

				lua_getfield(L, -1, "ppos");
				*((float *) bufpos) = io_floatNL(lua_tonumber(L, -1)); bufpos += sizeof(float);
				lua_pop(L, 1);
			}
			else
			{
				/*
				*((char *) bufpos) = io_charNL(0x00); bufpos += sizeof(char);
				*((char *) bufpos) = io_charNL(0x00); bufpos += sizeof(char);
				*((float *) bufpos) = io_floatNL(0x00); bufpos += sizeof(float);
				*/

				bufpos += 2 * sizeof(char) + 1 * sizeof(float);

				lua_pop(L, 1);
			}

			/* pop 'm' */
			lua_pop(L, 1);
		}
		else
		{
			*(((short *) &buf[0]) + order - 1) = --numWalls;
		}

		lua_pop(L, 1);
	}

	/* control points */
	/* char team;  -- team will be 0 if it's not captured, 1 if red, and 2 if blue */
	++order;
	lua_pushnil(L);
	while(lua_next(L, order))
	{
		if(bufpos + 1 * sizeof(char) < buf + sizeof(buf))
		{
			/* set team */
			lua_getfield(L, -1, "m");
			lua_getfield(L, -1, "team");
			if(lua_isnoneornil(L, -1))
			{
				*((char *) bufpos) = io_charNL(0x00); bufpos += sizeof(char);
			}
			else if(strcmp(lua_tostring(L, -1), "red"))
			{
				*((char *) bufpos) = io_charNL(0x01); bufpos += sizeof(char);
			}
			else
			{
				*((char *) bufpos) = io_charNL(0x02); bufpos += sizeof(char);
			}
			lua_pop(L, 2);
		}
		else
		{
			*(((short *) &buf[0]) + order - 1) = --numControlPoints;
		}

		lua_pop(L, 1);
	}

	/* flags */
	/* char state; char stolenIndex; float droppedPos[2]; */
	lua_pushnil(L);
	++order;
	while(lua_next(L, order))
	{
		if(bufpos + 2 * sizeof(char) + 2 * sizeof(float) < buf + sizeof(buf))
		{
			unsigned char state = 0;
			unsigned char stolenIndex;
			float droppedPos[2];

			/* set stolen */
			lua_getfield(L, -1, "m");
			lua_getfield(L, -1, "stolen");
			if(lua_toboolean(L, -1))
			{
				state &= 0x01;
				stolenIndex = lua_tonumber(L, -1);
			}
			lua_pop(L, 1);
			/* set dropped */
			lua_getfield(L, -1, "dropped");
			if(lua_toboolean(L, -1))
			{
				lua_pop(L, 1);
				state &= 0x02;
				lua_getfield(L, -1, "pos");
				const vec2_t *v = CHECKVEC(L, -1);
				droppedPos[0] = v->x;
				droppedPos[1] = v->y;
			}
			lua_pop(L, 2);
			*((char *) bufpos) = io_charNL(state); bufpos += sizeof(char);
			*((char *) bufpos) = io_charNL(stolenIndex); bufpos += sizeof(char);
			*((float *) bufpos) = io_floatNL(droppedPos[0]); bufpos += sizeof(float);
			*((float *) bufpos) = io_floatNL(droppedPos[1]); bufpos += sizeof(float);
		}
		else
		{
			*(((short *) &buf[0]) + order - 1) = --numFlags;
		}

		lua_pop(L, 1);
	}

	lua_pushlstring(L, buf, bufpos - buf);

	return 1;
}

int w_unpersistWorld(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	vec2_t *v;

	static const unsigned int preArgs = 2;

	const char *data = lua_tostring(L, 1);

	unsigned int projectileBodyLen = lua_objlen(L, 13 + preArgs);

	unsigned int numProjectiles    = io_shortNL(*((short *) data)); data += sizeof(short);
	unsigned int numTanks          = io_shortNL(*((short *) data)); data += sizeof(short);
	unsigned int numPowerups       = io_shortNL(*((short *) data)); data += sizeof(short);
	unsigned int numWalls          = lua_objlen(L, 5);
	unsigned int numControlPoints  = lua_objlen(L, 6);
	unsigned int numFlags          = lua_objlen(L, 7);

	/* remove projectiles before unpersisting */
	/*lua_pushvalue(L, 1);*/
	/*t_emptyTable(L, -1);*/
	/*lua_pop(L, 1);*/
	/* this should already be taken care of in the game logic */

	/* Projectiles */
	for(int i = 0; i < numProjectiles; i++)
	{
		lua_pushvalue(L, 7 + preArgs);
		lua_pushvalue(L, 10 + preArgs);
		lua_call(L, 1, 1);
		lua_pushinteger(L, i + 1);
		lua_pushvalue(L, -2);
		lua_settable(L, 1 + preArgs);

		/* weapon */
		lua_pushinteger(L, io_charNL(*((char *) data))); data += sizeof(char);
		lua_setfield(L, -2, "weapon");

		/* rotation */
		lua_pushinteger(L, io_floatNL(*((float *) data))); data += sizeof(float);
		lua_setfield(L, -2, "r");

		/* push addBody function */
		lua_pushcfunction(L, w_addBody);

		/* position */
		v = reinterpret_cast<vec2_t *>(lua_newuserdata(L, sizeof(vec2_t)));

		luaL_getmetatable(L, MATH_METATABLE);
		lua_setmetatable(L, -2);

		v->x = io_floatNL(*((float *) data)); data += sizeof(float);
		v->y = io_floatNL(*((float *) data)); data += sizeof(float);
		MATH_POLAR(*v);

		lua_pushvalue(L, -1);  /* keep position on stack for body */
		lua_setfield(L, -4, "p");

		/* add body before popping position vector */
		/* position on top of stack */
		lua_getfield(L, -3, "r");
		lua_getglobal(L, "unpack");
		lua_pushvalue(L, 13 + preArgs);
		lua_call(L, 1, projectileBodyLen);
		lua_call(L, projectileBodyLen + 2, 1);
		b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, -1));

		/* velocity */
		b2Vec2 vel;
		vel.x = io_floatNL(*((float *) data)); data += sizeof(float);
		vel.y = io_floatNL(*((float *) data)); data += sizeof(float);
		body->SetLinearVelocity(vel);

		/* angular velocity */
		body->SetAngularVelocity(io_floatNL(*((float *) data))); data += sizeof(float);

		lua_getfield(L, -2, "m");
		lua_pushvalue(L, -2);
		lua_setfield(L, -2, "body");

		/* pop 'm' and projectile */
		lua_pop(L, 2);
	}

	/* Tanks */
	for(int i = 0; i < numTanks; i++)
	{
		unsigned int index = io_charNL(*((char *) data)); data += sizeof(char);

		lua_pushinteger(L, index);
		lua_gettable(L, 2 + preArgs);
		if(lua_isnoneornil(L, -1))
		{
			lua_pop(L, 1);

			/* add the tank */
			lua_pushvalue(L, 8 + preArgs);
			lua_pushvalue(L, 11 + preArgs);
			lua_call(L, 1, 1);
			lua_pushinteger(L, index);
			lua_pushvalue(L, -2);
			lua_settable(L, 2 + preArgs);

			/* spawn the tank */
			lua_pushvalue(L, 14 + preArgs);
			lua_pushvalue(L, -2);
			lua_call(L, 1, 0);
		}

		/* get body */
		lua_getfield(L, -1, "body");
		b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, -1));
		lua_pop(L, 1);

		/* name */
		static char name[21];
		strncpy(name, data, sizeof(name)); data += 21 * sizeof(char);
		lua_pushstring(L, name);
		lua_setfield(L, -2, "name");

		double rotation = io_floatNL(*((float *) data)); data += sizeof(float);
		/* rotation */
		lua_pushnumber(L, rotation);
		lua_setfield(L, -2, "r");

		/* position */
		lua_getfield(L, -1, "p");
		v = CHECKVEC(L, -1);
		v->x = io_floatNL(*((float *) data)); data += sizeof(float);
		v->y = io_floatNL(*((float *) data)); data += sizeof(float);
		MATH_POLAR(*v);
		/* set body */
		body->SetXForm(b2Vec2(v->x, v->y), rotation);
		lua_pop(L, 1);

		/* velocity */
		b2Vec2 vel;
		vel.x = io_floatNL(*((float *) data)); data += sizeof(float);
		vel.y = io_floatNL(*((float *) data)); data += sizeof(float);
		body->SetLinearVelocity(vel);

		/* input */
		lua_pushinteger(L, io_shortNL(*((short *) data))); data += sizeof(short);
		lua_setfield(L, -2, "state");

		lua_pop(L, 1);
	}

	/* Powerups */
	for(int i = 0; i < numPowerups; i++)
	{
		unsigned int index = io_charNL(*((char *) data)); data += sizeof(char);

		lua_pushinteger(L, index);
		lua_gettable(L, 3 + preArgs);
		if(lua_isnoneornil(L, -1))
		{
			lua_pop(L, 1);

			/* add the powerup */
			lua_pushvalue(L, 9 + preArgs);
			lua_pushvalue(L, 12 + preArgs);
			lua_call(L, 1, 1);
			lua_pushinteger(L, index);
			lua_pushvalue(L, -2);
			lua_settable(L, 3 + preArgs);

			/* spawn the powerup */
			lua_pushvalue(L, 15 + preArgs);
			lua_pushvalue(L, -2);
			lua_pushinteger(L, index);
			lua_call(L, 2, 0);
		}

		/* get body */
		lua_getfield(L, -1, "m");
		lua_getfield(L, -1, "body");
		b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, -1));
		lua_pop(L, 2);

		/* type */
		lua_pushinteger(L, io_charNL(*((char *) data))); data += sizeof(char);
		lua_setfield(L, -2, "type");

		double rotation = io_floatNL(*((float *) data)); data += sizeof(float);
		/* rotation */
		lua_pushnumber(L, rotation);
		lua_setfield(L, -2, "r");

		/* position */
		lua_getfield(L, -1, "p");
		v = CHECKVEC(L, -1);
		v->x = io_floatNL(*((float *) data)); data += sizeof(float);
		v->y = io_floatNL(*((float *) data)); data += sizeof(float);
		MATH_POLAR(*v);
		/* set body */
		body->SetXForm(b2Vec2(v->x, v->y), rotation);
		lua_pop(L, 1);

		/* velocity */
		b2Vec2 vel;
		vel.x = io_floatNL(*((float *) data)); data += sizeof(float);
		vel.y = io_floatNL(*((float *) data)); data += sizeof(float);
		body->SetLinearVelocity(b2Vec2(v->x, v->y));

		/* angular velocity */
		body->SetAngularVelocity(io_floatNL(*((float *) data))); data += sizeof(float);

		lua_pop(L, 1);
	}

	/* Walls */
	for(int i = 0; i < numWalls; i++)
	{
		lua_pushinteger(L, i + 1);
		lua_gettable(L, 4 + preArgs);
		if(lua_isnoneornil(L, -1))
		{
			/* This should never happen, but play safe anyway */
			data += 6 * sizeof(float) + 2 * sizeof(char) + 3 * sizeof(float);

			lua_pop(L, 1);
		}
		else
		{
			lua_getfield(L, -1, "static");
			lua_getfield(L, -2, "path");
			if(lua_toboolean(L, -1) || !lua_toboolean(L, -2))
			{
				lua_pop(L, 2);

				/* get body */
				lua_getfield(L, -1, "m");
				lua_getfield(L, -1, "body");
				b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, -1));
				lua_pop(L, 2);

				/* position */
				b2Vec2 pos;
				pos.x = io_floatNL(*((float *) data)); data += sizeof(float);
				pos.y = io_floatNL(*((float *) data)); data += sizeof(float);

				/* angle */
				double angle = io_floatNL(*((float *) data)); data += sizeof(float);

				body->SetXForm(pos, angle);

				/* velocity */
				b2Vec2 vel;
				vel.x = io_floatNL(*((float *) data)); data += sizeof(float);
				vel.y = io_floatNL(*((float *) data)); data += sizeof(float);
				body->SetLinearVelocity(vel);

				/* angular velocity */
				body->SetAngularVelocity(luaL_checknumber(L, 2));

				/* path ID */
				lua_getfield(L, -1, "m");
				lua_pushnumber(L, io_floatNL(*((float *) data)));
				lua_setfield(L, -2, "pid");
				/* keep 'm' on stack */

				/* previous path ID */
				lua_pushnumber(L, io_floatNL(*((float *) data)));
				lua_setfield(L, -2, "ppid");

				/* set startpos */
				lua_getfield(L, -1, "startpos");
				if(lua_isnoneornil(L, -1))
				{
					lua_pop(L, 1);

					v = reinterpret_cast<vec2_t *>(lua_newuserdata(L, sizeof(vec2_t)));

					luaL_getmetatable(L, MATH_METATABLE);
					lua_setmetatable(L, -2);

					lua_pushvalue(L, -1);
					lua_setfield(L, -3, "startpos");
				}
				else
				{
					v = CHECKVEC(L, -1);
				}
				v->x = io_floatNL(*((float *) data)); data += sizeof(float);
				v->y = io_floatNL(*((float *) data)); data += sizeof(float);
				MATH_POLAR(*v);
				lua_pop(L, 1);

				/* path position */
				lua_pushnumber(L, io_floatNL(*((float *) data)));
				lua_setfield(L, -2, "ppos");

				/* pop both path and wall */
				lua_pop(L, 2);
			}
			else
			{
				/* Save processing */
				data += 6 * sizeof(float) + 2 * sizeof(char) + 3 * sizeof(float);

				lua_pop(L, 3);
			}
		}
	}

	/* Control Points */
	for(int i = 0; i < numControlPoints; i++)
	{
		lua_pushinteger(L, i + 1);
		lua_gettable(L, 5  + preArgs);
		if(lua_isnoneornil(L, -1))
		{
			/* This should never happen, but play safe anyway */
			data += 1 * sizeof(char);

			lua_pop(L, 1);
		}
		else
		{
			unsigned char team = io_charNL(*((char *) data)); data += sizeof(char);

			lua_getfield(L, -1, "m");

			switch(team)
			{
				default:
				case 0x00:
					lua_pushnil(L);
					lua_setfield(L, -2, "team");

				case 0x01:
					lua_pushliteral(L, "red");
					lua_setfield(L, -2, "team");

				case 0x02:
					lua_pushliteral(L, "blue");
					lua_setfield(L, -2, "team");
			}

			/* pop m and control point */
			lua_pop(L, 2);
		}
	}

	/* Flags */
	for(int i = 0; i < numFlags; i++)
	{
		lua_pushinteger(L, i + 1);
		lua_gettable(L, 6  + preArgs);
		if(lua_isnoneornil(L, -1))
		{
			/* This should never happen, but play safe anyway */
			data += 2 * sizeof(char) + 1 * sizeof(int) + 2 * sizeof(float);

			lua_pop(L, 1);
		}
		else
		{
			unsigned char state = io_charNL(*((char *) data)); data += sizeof(char);
			unsigned char stolenIndex = io_charNL(*((char *) data)); data += sizeof(char);
			float droppedPosx = io_floatNL(*((float *) data)); data += sizeof(float);
			float droppedPosy = io_floatNL(*((float *) data)); data += sizeof(float);

			lua_getfield(L, -1, "m");

			/* stolen */
			if(state & 0x01)
			{
				lua_pushinteger(L, stolenIndex);
				lua_setfield(L, -2, "stolen");
			}
			else
			{
				lua_pushnil(L);
				lua_setfield(L, -2, "stolen");
			}

			/* dropped */
			if(state & 0x02)
			{
				lua_getfield(L, -1, "stolen");
				if(!lua_toboolean(L, -1))
				{
					lua_pop(L, 1);

					v = reinterpret_cast<vec2_t *>(lua_newuserdata(L, sizeof(vec2_t)));

					luaL_getmetatable(L, MATH_METATABLE);
					lua_setmetatable(L, -2);

					v->x = droppedPosx;
					v->y = droppedPosy;
					MATH_POLAR(*v);
				}
				else
				{
					v = CHECKVEC(L, -1);
					v->x = droppedPosx;
					v->y = droppedPosy;
					MATH_POLAR(*v);
				}
				lua_setfield(L, -2, "stolen");
			}
			else
			{
				lua_pushnil(L);
				lua_setfield(L, -2, "stolen");
			}

			/* pop m and control point */
			lua_pop(L, 2);
		}
	}

	return 0;
}

int w_getVertices(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));
	lua_remove(L, 1);

	if(!lua_istable(L, -1))
	{
		lua_pushliteral(L, "no table passed to w_getVertices\n");
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

int w_getContents(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));
	lua_remove(L, 1);

	for(b2Shape *bshape = body->GetShapeList(); bshape; bshape = bshape->GetNext())
	{
		lua_pushinteger(L, bshape->GetFilterData().categoryBits);

		return 1;
	}

	lua_pushnil(L);

	return 1;
}

int w_getClipmask(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));
	lua_remove(L, 1);

	for(b2Shape *bshape = body->GetShapeList(); bshape; bshape = bshape->GetNext())
	{
		lua_pushinteger(L, bshape->GetFilterData().maskBits);

		return 1;
	}

	lua_pushnil(L);

	return 1;
}

int w_getIndex(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));
	lua_settop(L, 0);

	lua_pushinteger(L, reinterpret_cast<long>(body->GetUserData()));

	return 1;
}

int w_setIndex(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKWORLD(world, L);

	b2Body *body = reinterpret_cast<b2Body *>(lua_touserdata(L, 1));
	lua_settop(L, 0);

	body->SetUserData(reinterpret_cast<void *>(luaL_checkinteger(L, 2)));

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
