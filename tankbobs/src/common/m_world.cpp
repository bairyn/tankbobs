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

#include <string>
#include <iostream>
#include <SDL/SDL.h>
#include <SDL/SDL_image.h>
#include <SDL/SDL_mixer.h>
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
		tstr *message = CDLL_FUNCTION("tstr", "tstr_new", tstr *(*)(void)) \
			(); \
		CDLL_FUNCTION("tstr", "tstr_base_set", void(*)(tstr *, const char *)) \
			(message, "world is unintialized\n"); \
		lua_pushstring(L, CDLL_FUNCTION("tstr", "tstr_cstr", const char *(*)(tstr *)) \
							(message)); \
		CDLL_FUNCTION("tstr", "tstr_free", void(*)(tstr *)) \
			(message); \
		lua_error(L); \
	} \
} while(0)

extern Uint8 init;

static b2World *world = NULL;
static b2AABB worldAABB;
static b2Vec2 worldGravity;
static bool allowSleep;

static double timeStep = 1.0 / 128.0;
static int iterations = 24;

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
		tstr *message = CDLL_FUNCTION("tstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("tstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_newWorld: memory leak detected: world wasn't freed properly\n");
		lua_pushstring(L, CDLL_FUNCTION("tstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("tstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	world = new b2World(worldAABB, worldGravity, allowSleep);

	return 0;
}

int w_freeWorld(lua_State *L)
{
	CHECKINIT(init, L);

	if(!world)
	{
		tstr *message = CDLL_FUNCTION("tstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("tstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_freeWorld: freeing unitialized world\n");
		lua_pushstring(L, CDLL_FUNCTION("tstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("tstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	delete world;
	world = NULL;

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
		tstr *message = CDLL_FUNCTION("tstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("tstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "w_addBody: invalid polygon table\n");
		lua_pushstring(L, CDLL_FUNCTION("tstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("tstr", "tstr_free", void(*)(tstr *))
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

	lua_newtable(L);

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
	v->R = sqrt(v->x * v->x + v->y * v->y);
	v->t = atan(v->y / v->x);
	if(v->x < 0.0 && v->y < 0.0)
		v->t += 180;
	else if(v->x < 0.0)
		v->t += 90;
	else if(v->y < 0.0)
		v->t += 270;

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
	v->R = sqrt(v->x * v->x + v->y * v->y);
	v->t = atan(v->y / v->x);
	if(v->x < 0.0 && v->y < 0.0)
		v->t += 180;
	else if(v->x < 0.0)
		v->t += 90;
	else if(v->y < 0.0)
		v->t += 270;

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
	v->R = sqrt(v->x * v->x + v->y * v->y);
	v->t = atan(v->y / v->x);
	if(v->x < 0.0 && v->y < 0.0)
		v->t += 180;
	else if(v->x < 0.0)
		v->t += 90;
	else if(v->y < 0.0)
		v->t += 270;

	return 1;
}
