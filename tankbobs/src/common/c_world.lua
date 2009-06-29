--[[
Copyright (C) 2008 Byron James Johnson

This file is part of Tankbobs.

	Tankbobs is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	Tankbobs is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
along with Tankbobs.  If not, see <http://www.gnu.org/licenses/>.
--]]

--[[
c_world.lua

world and physics
--]]

--TODO: knockback and damage for hitting world.  A powerup will protect the front.  another will protect the back and sides.  Each will do so in exchange for a slight decrease in acceleration.
--TODO: damage is noticeably higher in special mode.

local c_config_set            = c_config_set
local c_config_get            = c_config_get
local c_const_set             = c_const_set
local c_const_get             = c_const_get
local c_weapon_getProjectiles = c_weapon_getProjectiles
local common_FTM              = common_FTM
local common_lerp             = common_lerp
local c_weapon_fire           = c_weapon_fire
local tankbobs                = tankbobs

local c_world_tank_checkSpawn
local c_world_tank_step
local c_world_projectile_step
local c_world_powerupSpawnPoint_step
local c_world_powerup_step
local c_world_tanks
local c_world_powerups

local worldTime = 0
local tank_acceleration

function c_world_init()
	c_config_set            = _G.c_config_set
	c_config_get            = _G.c_config_get
	c_const_set             = _G.c_const_set
	c_const_get             = _G.c_const_get
	c_weapon_getProjectiles = _G.c_weapon_getProjectiles
	common_FTM              = _G.common_FTM
	common_lerp             = _G.common_lerp
	c_weapon_fire           = _G.c_weapon_fire
	tankbobs                = _G.tankbobs

	c_config_cheat_protect("config.game.timescale")

	c_const_set("world_time", 1000)  -- relative to change in seconds

	c_const_set("world_fps", 256)
	--c_const_set("world_timeStep", common_FTM(c_const_get("world_fps")))
	c_const_set("world_timeStep", 1 / 500)
	c_const_set("world_iterations", 16)

	c_const_set("world_timeWrapTest", -99999)

	c_const_set("world_lowerBoundx", -9999, 1) c_const_set("world_lowerBoundy", -9999, 1)
	c_const_set("world_upperBoundx",  9999, 1) c_const_set("world_upperBoundy",  9999, 1)
	c_const_set("world_gravityx", 0, 1) c_const_set("world_gravityy", 0, 1)
	c_const_set("world_allowSleep", true, 1)

	c_const_set("world_maxPowerups", 64, 1)

	c_const_set("powerupSpawnPoint_initialPowerupTime", 30, 1)
	c_const_set("powerupSpawnPoint_powerupTime", 30, 1)
	c_const_set("powerupSpawnPoints_linked", true, 1)

	c_const_set("powerup_lifeTime", 6000, 1)
	c_const_set("powerup_density", 1E-5, 1)
	c_const_set("powerup_friction", 0, 1)
	c_const_set("powerup_restitution", 1, 1)
	c_const_set("powerup_canSleep", false, 1)
	c_const_set("powerup_isBullet", true, 1)
	c_const_set("powerup_linearDamping", 0, 1)
	c_const_set("powerup_angularDamping", 0, 1)
	c_const_set("powerup_pushStrength", 16, 1)
	c_const_set("powerup_pushAngle", math.pi / 4, 1)
	c_const_set("powerup_static", false, 1)

	-- hull of tank facing right
	c_const_set("tank_hullx1", -2.0, 1) c_const_set("tank_hully1",  2.0, 1)
	c_const_set("tank_hullx2", -2.0, 1) c_const_set("tank_hully2", -2.0, 1)
	c_const_set("tank_hullx3",  2.0, 1) c_const_set("tank_hully3", -1.0, 1)
	c_const_set("tank_hullx4",  2.0, 1) c_const_set("tank_hully4",  1.0, 1)
	c_const_set("tank_health", 100, 1)
	c_const_set("tank_damageK", 4, 1)  -- damage relative to speed before a collision: 2 hp / 1 ups
	c_const_set("tank_damageMinSpeed", 6, 1)
	c_const_set("tank_intensityMaxSpeed", 6, 1)
	c_const_set("tank_collideMinDamage", 5, 1)
	c_const_set("tank_deceleration", 32 / 1000, 1)
	c_const_set("tank_decelerationMinSpeed", -1, 1)
	c_const_set("tank_highHealth", 66, 1)
	c_const_set("tank_lowHealth", 33, 1)
	c_const_set("tank_acceleration",
	{
		{16 / 1000},  -- acceleration of 16 by default
		{12 / 1000, 3},  -- unless the tank's speed is at least 8 units per second, in which case the acceleration is dropped to 48
		{6 / 1000, 4},
		{4 / 1000, 8},
		{2 / 1000, 12},
		{1 / 1000, 16},
		{0.5 / 1000, 24},
		{0.4 / 1000, 32},
		{(1 / 3) / 1000, 48}
	}, 1)
	tank_acceleration = c_const_get("tank_acceleration")
	c_const_set("tank_speedK", 5, 1)
	c_const_set("tank_density", 2, 1)
	c_const_set("tank_friction", 0.25, 1)
	c_const_set("tank_worldFriction", 0.75 / 1000, 1)  -- damping
	c_const_set("tank_restitution", 0.4, 1)
	c_const_set("tank_canSleep", false, 1)
	c_const_set("tank_isBullet", true, 1)
	c_const_set("tank_linearDamping", 0, 1)
	c_const_set("tank_angularDamping", 0, 1)
	c_const_set("tank_accelerationVectorPointTest", -90, 1)  -- the origin of acceleration force
	c_const_set("tank_decelerationVectorPointTest", 90, 1)
	c_const_set("tank_spawnTime", 0.75, 1)
	c_const_set("tank_static", false, 1)
	c_const_set("wall_density", 1, 1)
	c_const_set("wall_friction", 0.25, 1)  -- deceleration caused by friction (~speed *= 1 - friction)
	c_const_set("wall_restitution", 0.2, 1)
	c_const_set("wall_canSleep", true, 1)
	c_const_set("wall_isBullet", true, 1)
	c_const_set("wall_linearDamping", 0, 1)
	c_const_set("wall_angularDamping", 0, 1)
	c_const_set("tank_rotationChange", 0.005, 1)
	c_const_set("tank_rotationChangeMinSpeed", 0.5, 1)  -- if at least 24 ups
	c_const_set("tank_rotationSpeed", c_math_radians(450) / 1000, 1)  -- 135 degrees per second
	c_const_set("tank_rotationSpecialSpeed", c_math_degrees(1) / 3.5, 1)
	c_const_set("tank_defaultRotation", c_math_radians(90), 1)  -- up
	c_const_set("tank_boostHealth", 60, 1)

	c_const_set("powerup_hullx1",  0, 1) c_const_set("powerup_hully1",  1, 1)
	c_const_set("powerup_hullx2",  0, 1) c_const_set("powerup_hully2",  0, 1)
	c_const_set("powerup_hullx3",  1, 1) c_const_set("powerup_hully3",  0, 1)
	c_const_set("powerup_hullx4",  1, 1) c_const_set("powerup_hully4",  1, 1)

	-- powerups
	c_powerupTypes = {}

	-- weapons are bluish, weapon enhancements are yellowish, tank enhancements are greenish, extreme powerups are reddish

	-- machinegun
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 1
	powerupType.name = "machinegun"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.3, 0.6, 1, 1

	-- shotgun
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 2
	powerupType.name = "shotgun"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.25, 0.25, 0.75, 1

	-- railgun
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 3
	powerupType.name = "railgun"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0, 0, 1, 1

	-- coilgun
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 4
	powerupType.name = "coilgun"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.25, 0.25, 1, 0.875

	-- saw
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 5
	powerupType.name = "saw"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0, 0, 0.6, 0.875

	-- ammo
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 6
	powerupType.name = "ammo"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.05, 0.4, 0.1, 0.5

	-- aim aid
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 7
	powerupType.name = "aim-aid"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.5, 0.75, 0.1, 0.5

	-- health
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 8
	powerupType.name = "health"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.1, 0.85, 0.1, 0.8

	tankbobs.w_setTimeStep(c_const_get("world_timeStep"))
	tankbobs.w_setIterations(c_const_get("world_iterations"))
end

function c_world_done()
end

local worldInitialized = false

c_world_powerupType =
{
	new = common_new,

	index = 0,
	name = "",
	c = {r = 0, g = 0, b = 0, a = 0},
}

c_world_powerup =
{
	new = common_new,

	init = function (o)
		o.p[1] = tankbobs.m_vec2()
	end,

	p = {},
	r = 0,  -- rotation
	collided = false,  -- whether it needs to be removed
	type = nil,  -- the type of powerup (shotgun, ammo, speed enhancement, etc)
	spawnTime = 0,  -- the time the powerup spawned

	m = {}
}

c_world_tank =
{
	new = common_new,

	init = function (o)
		name = "UnnamedPlayer"
		o.p[1] = tankbobs.m_vec2()
		o.h[1] = tankbobs.m_vec2()
		o.h[2] = tankbobs.m_vec2()
		o.h[3] = tankbobs.m_vec2()
		o.h[4] = tankbobs.m_vec2()
		o.h[1].x = c_const_get("tank_hullx1")
		o.h[1].y = c_const_get("tank_hully1")
		o.h[2].x = c_const_get("tank_hullx2")
		o.h[2].y = c_const_get("tank_hully2")
		o.h[3].x = c_const_get("tank_hullx3")
		o.h[3].y = c_const_get("tank_hully3")
		o.h[4].x = c_const_get("tank_hullx4")
		o.h[4].y = c_const_get("tank_hully4")
		o.color.r = c_config_get("config.game.defaultTankRed")
		o.color.g = c_config_get("config.game.defaultTankGreen")
		o.color.b = c_config_get("config.game.defaultTankBlue")
		o.state = c_world_tank_state:new()
	end,

	p = {},
	h = {},  -- physical box: four vectors of offsets for tanks
	r = 0,  -- tank's rotation
	name = "",
	exists = false,
	spawning = false,
	lastSpawnPoint = 0,
	state = nil,
	weapon = nil,
	lastFireTime = 0,
	body = nil,  -- physical body
	health = 0,
	nextSpawnTime = 0,
	killer = nil,
	score = 0,
	ammo = 0,
	color = {},

	cd = {},  -- data cleared on death

	m = {p = {}}
}

c_world_tank_state =
{
	new = common_new,

	firing = false,
	forward = false,
	back = false,
	right = false,
	left = false,
	special = false
}

function c_world_getPowerupTypeByName(name)
	for k, v in pairs(c_powerupTypes) do
		if v.name == name then
			return v
		end
	end
end

function c_world_newWorld()
	if worldInitialized then
		return
	end

	local t = tankbobs.t_getTicks()

	wordTime = t

	tankbobs.w_newWorld(tankbobs.m_vec2(c_const_get("world_lowerBoundx"), c_const_get("world_lowerBoundy")), tankbobs.m_vec2(c_const_get("world_upperBoundx"), c_const_get("world_upperBoundy")), tankbobs.m_vec2(c_const_get("world_gravityx"), c_const_get("world_gravityy")), c_const_get("world_allowSleep"), "c_world_contactListener")

	for _, v in pairs(c_tcm_current_map.walls) do
		if v.detail then
			break  -- the wall isn't part of the physical world
		end

		-- add wall to world
		local b = c_world_wallShape(v)
		v.m.body = tankbobs.w_addBody(b[1], 0, c_const_get("wall_canSleep"), c_const_get("wall_isBullet"), c_const_get("wall_linearDamping"), c_const_get("wall_angularDamping"), b[2], c_const_get("wall_density"), c_const_get("wall_friction"), c_const_get("wall_restitution"), not v.static)
		if not v.m.body then
			error "c_world_newWorld: could not add a wall to the physical world"
		end
	end

	for k, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
		v.m.nextPowerupTime = t + c_const_get("world_time") * c_config_get("config.game.timescale") * c_const_get("powerupSpawnPoint_initialPowerupTime")
		local enabled = false
		for k, vs in pairs(v.enabledPowerups) do
			if vs then
				enabled = true
				v.m.lastPowerup = k
			end
		end
		if not enabled then
			-- tankbobs assumes that at least one powerup is enabled, so remove the psp
			c_tcm_current_map.powerupSpawnPoints[k] = nil
		end
	end

	c_world_setPaused(false)  -- clear pause

	c_world_powerups = {}
	c_world_tanks = {}

	worldInitialized = true
end

function c_world_freeWorld()
	if not worldInitialized then
		return
	end

	worldInitialized = false

	tankbobs.w_freeWorld()

	c_world_powerups = {}
	c_world_tanks = {}
end

function c_world_tank_spawn(tank)
	tank.spawning = true
end

function c_world_tank_die(tank)
	if not tank.exists then
		tank.exists = false
		tankbobs.w_removeBody(tank.body)
	end
end

function c_world_tank_checkSpawn(d, tank)
	if not tank.spawning then
		return
	end

	if tank.lastSpawnPoint == 0 then
		tank.lastSpawnPoint = 1
	end

	local sp = tank.lastSpawnPoint
	local playerSpawnPoint = c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint]

	while not c_world_tank_canSpawn(d, tank) do
		tank.lastSpawnPoint = tank.lastSpawnPoint + 1

		playerSpawnPoint = c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint]

		if not playerSpawnPoint then
			tank.lastSpawnPoint = 1
			playerSpawnPoint = c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint]

			if not playerSpawnPoint then
				-- no spawn points
				error "No spawn points for map"
			end
		end

		if tank.lastSpawnPoint == sp then
			-- no spawn points can be used
			return false
		end
	end

	-- spawn
	tank.spawning = false
	tank.r = c_const_get("tank_defaultRotation")
	tank.p[1](playerSpawnPoint.p[1])
	tank.health = c_const_get("tank_health")
	tank.weapon = c_weapon_getByAltName("default")
	tank.exists = true
	tank.cd = {}

	-- add a physical body
	tank.body = tankbobs.w_addBody(tank.p[1], tank.r, c_const_get("tank_canSleep"), c_const_get("tank_isBullet"), c_const_get("tank_linearDamping"), c_const_get("tank_angularDamping"), tank.h, c_const_get("tank_density"), c_const_get("tank_friction"), c_const_get("tank_restitution"), not c_const_get("tank_static"))
	return true
end

function c_world_intersection(d, p1, p2, v1, v2)
	-- detects if two polygons ever collide

	local p1h = {}
	local p2h = {}
	local p1a = {}
	local p2a = {}

	tankbobs.t_clone(p1, p1h)
	tankbobs.t_clone(p2, p2h)
	tankbobs.t_clone(p1h, p1a)
	tankbobs.t_clone(p2h, p2a)

	for _, v in pairs(p1a) do
		v = v + d * v1
	end
	for _, v in pairs(p2a) do
		v = v + d * v2
	end

	tankbobs.t_clone(p1a, p1h)
	tankbobs.t_clone(p2a, p2h)

	return tankbobs.m_polygon(p1h, p2h)
end

function c_world_tankHull(tank)
	-- return a table of coordinates of tank's hull
	local c = {}
	local p = tank.p[1]

	for _, v in ipairs(tank.h) do  -- ipairs to make sure of proper order
		local h = tankbobs.m_vec2(v)
		h.t = h.t + tank.r
		table.insert(c, p + h)
	end

	return c
end

function c_world_projectileHull(projectile)
	local c = {}
	local p = projectile.p[1]

	for _, v in ipairs(projectile.weapon.projectileHull) do  -- ipairs to make sure of proper order
		local h = tankbobs.m_vec2(v)
		h.t = h.t + projectile.r
		table.insert(c, p + h)
	end

	return c
end

function c_world_powerupHull(powerup)
	local c = {}

	for i = 1, 4 do
		local h = tankbobs.m_vec2(c_const_get("powerup_hullx" .. tostring(i)), c_const_get("powerup_hully" .. tostring(i)))
		h.t = h.t + powerup.r
		table.insert(c, h)
	end

	return c
end

function c_world_powerupSpawnPointHull(powerupSpawnPoint)
	local c = {}
	local p = powerupSpawnPoint.p[1]

	for i = 1, 4 do
		local h = tankbobs.m_vec2(c_const_get("powerup_hullx" .. tostring(i)), c_const_get("powerup_hully" .. tostring(i)))
		--h.t = h.t
		table.insert(c, p + h)
	end

	return c
end

function c_world_wallShape(wall)
	local average = tankbobs.m_vec2()
	local offsets = {}

	for _, v in pairs(wall.p) do
		average = average + v
	end
	average = average / #wall.p

	for _, v in ipairs(wall.p) do
		table.insert(offsets, v - average)
	end

	return {average, offsets}
end

function c_world_canPowerupSpawn(d, powerupSpawnPoint)
	-- make sure it doesn't interfere with another powerup or wall
	for _, v in pairs(c_tcm_current_map.walls) do
		if not v.detail then
			if c_world_intersection(d, c_world_powerupSpawnPointHull(powerupSpawnPoint), v.p, tankbobs.m_vec2(0, 0), v.static and tankbobs.m_vec2(0, 0) or tankbobs.w_getLinearVelocity(v.m.body)) then
				return false
			end
		end
	end

	for _, v in pairs(c_world_powerups) do
		if not v.collided then
			if c_world_intersection(d, c_world_powerupSpawnPointHull(powerupSpawnPoint), c_world_powerupHull(v), tankbobs.m_vec2(0, 0), not v.m.body and tankbobs.m_vec2(0, 0) or tankbobs.w_getLinearVelocity(v.m.body)) then
				return false
			end
		end
	end

	return true
end

function c_world_tank_canSpawn(d, tank)
	local t = tankbobs.t_getTicks()

	-- make sure the tank hasn't already spawned
	if tank.exists then
		return false
	end

	if tank.nextSpawnTime > t then
		return false
	end

	-- see if the spawn point exists
	if not c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint] then
		return false
	end

	-- set the tank's position for proper testing (this won't interfere with anything else since the exists flag isn't set)
	tank.p[1](c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint].p[1])

	-- test if spawning interferes with another tank
	for _, v in pairs(c_world_tanks) do
		if v.exists then
			if c_world_intersection(d, c_world_tankHull(tank), c_world_tankHull(v), tankbobs.m_vec2(0, 0), tankbobs.w_getLinearVelocity(v.body)) then
				return false
			end
		end
	end

	return true
end

function c_world_findClosestIntersection(start, endP)
	-- test against the world and find the closest intersection point
	-- returns false; or true, intersectionPoint, typeOfTarget, target
	local lastPoint, currentPoint = nil
	local minDistance, minIntersection, typeOfTarget, target
	local hull
	local b, intersection

	-- walls
	for _, v in pairs(c_tcm_current_map.walls) do
		if not v.detail then
			hull = v.p
			local t = v
			for _, v in pairs(hull) do
				currentPoint = v
				if not lastPoint then
					lastPoint = hull[#hull]
				end

				b, intersection = tankbobs.m_edge(lastPoint, currentPoint, start, endP)
				if b then
					if not minDistance then
						minIntersection = intersection
						minDistance = math.abs((intersection - start).R)
						typeOfTarget = "wall"
						target = t
					elseif math.abs((intersection - start).R) < minDistance then
						minIntersection = intersection
						minDistance = math.abs((intersection - start).R)
						typeOfTarget = "wall"
						target = t
					end
				end

				lastPoint = currentPoint
			end
			lastPoint = nil
		end
	end

	-- tanks
	for _, v in pairs(c_world_tanks) do
		if v.exists then
			hull = c_world_tankHull(v)
			local t = v
			for _, v in pairs(hull) do
				currentPoint = v
				if not lastPoint then
					lastPoint = hull[#hull]
				end

				b, intersection = tankbobs.m_edge(lastPoint, currentPoint, start, endP)
				if b then
					if not minDistance then
						minIntersection = intersection
						minDistance = math.abs((intersection - start).R)
						typeOfTarget = "tank"
						target = t
					elseif math.abs((intersection - start).R) < minDistance then
						minIntersection = intersection
						minDistance = math.abs((intersection - start).R)
						typeOfTarget = "tank"
						target = t
					end
				end

				lastPoint = currentPoint
			end
			lastPoint = nil
		end
	end

	-- projectiles
	for _, v in pairs(c_weapon_getProjectiles()) do
		if not v.collided then
			hull = c_world_projectileHull(v)
			local t = v
			for _, v in pairs(hull) do
				currentPoint = v
				if not lastPoint then
					lastPoint = hull[#hull]
				end

				b, intersection = tankbobs.m_edge(lastPoint, currentPoint, start, endP)
				if b then
					if not minDistance then
						minIntersection = intersection
						minDistance = math.abs((intersection - start).R)
						typeOfTarget = "projectile"
						target = t
					elseif math.abs((intersection - start).R) < minDistance then
						minIntersection = intersection
						minDistance = math.abs((intersection - start).R)
						typeOfTarget = "projectile"
						target = t
					end
				end

				lastPoint = currentPoint
			end
			lastPoint = nil
		end
	end

	-- teleporters

	-- powerups

	return minDistance, minIntersection, typeOfTarget, target
end

function c_world_tankDie(d, tank, t)
	tankbobs.w_removeBody(tank.body)
	tank.nextSpawnTime = t + c_const_get("world_time") * c_config_get("config.game.timescale") * c_const_get("tank_spawnTime")
	if tank.killer then
		tank.killer.score = tank.killer.score + 1
	else
		tank.score = tank.score - 1
	end
	tank.killer = nil
	tank.exists = false
	tank.spawning = true
	tank.m.lastDieTime = t

	tank.cd = {}
end

function c_world_tank_step(d, tank)
	local t = tankbobs.t_getTicks()

	c_world_tank_checkSpawn(d, tank)

	if not tank.exists then
		return
	end

	if tank.health <= 0 then
		return c_world_tankDie(d, tank, t)
	end

	tank.p[1] = tankbobs.w_getPosition(tank.body)

	local vel = tankbobs.w_getLinearVelocity(tank.body)

	if tank.state.special then
		if tank.state.left then
			if vel.R < 0 then  -- inverse rotation
				tank.r = tank.r - c_const_get("tank_rotationSpeed") * vel.R / c_const_get("tank_rotationSpecialSpeed")
			else
				tank.r = tank.r + c_const_get("tank_rotationSpeed") * vel.R / c_const_get("tank_rotationSpecialSpeed")
			end
		end

		if tank.state.right then
			if vel.R < 0 then  -- inverse rotation
				tank.r = tank.r + c_const_get("tank_rotationSpeed") * vel.R / c_const_get("tank_rotationSpecialSpeed")
			else
				tank.r = tank.r - c_const_get("tank_rotationSpeed") * vel.R / c_const_get("tank_rotationSpecialSpeed")
			end
		end

		local v = tankbobs.m_vec2()
		v.R = vel.R
		v.t = tank.r

		tankbobs.w_setLinearVelocity(tank.body, v)
	else
		if tank.state.forward then
			-- determine the acceleration
			local acceleration

			for _, v in pairs(tank_acceleration) do  -- local copy of table for optimization
				if v[2] then
					if vel.R >= v[2] * c_const_get("tank_speedK") then
						acceleration = v[1]
					end
				elseif not acceleration then
					acceleration = v[1] * c_const_get("tank_speedK")
				end
			end

			local newVel = tankbobs.m_vec2(vel)
			newVel.R = newVel.R + acceleration
			newVel.t = tank.r
			if vel.R >= c_const_get("tank_rotationChangeMinSpeed") * c_const_get("tank_speedK") then
				-- interpolate in the right direction
				vel.t    = math.fmod(vel.t, 2 * math.pi)
				newVel.t = math.fmod(newVel.t, 2 * math.pi)
				if        vel.t - newVel.t > math.pi then
					vel.t    =    vel.t - 2 * math.pi
				elseif newVel.t - vel.t    > math.pi then
					newVel.t = newVel.t - 2 * math.pi
				end
				newVel.t = common_lerp(vel.t, newVel.t, c_const_get("tank_rotationChange"))
			end

			tankbobs.w_setLinearVelocity(tank.body, newVel)
			vel(newVel)
		elseif tank.state.back then
			if vel.R >= c_const_get("tank_decelerationMinSpeed") then
				local newVel = tankbobs.m_vec2(vel)

				if newVel.R > 0 then
					newVel.R = newVel.R - c_const_get("tank_deceleration")
				end

				tankbobs.w_setLinearVelocity(tank.body, newVel)
				vel(newVel)
			end
		else
			local v = tankbobs.w_getLinearVelocity(tank.body)

			v.R = v.R / (1 + c_const_get("tank_worldFriction"))
			tankbobs.w_setLinearVelocity(tank.body, v)
		end

		if tank.state.left then
			tank.r = tank.r + c_const_get("tank_rotationSpeed")
		end

		if tank.state.right then
			tank.r = tank.r - c_const_get("tank_rotationSpeed")
		end
	end

	tankbobs.w_setAngle(tank.body, tank.r)

	tankbobs.w_setAngularVelocity(tank.body, 0)  -- reset the tank's angular velocity

	-- weapons
	if tank.state.firing then
		if t >= tank.lastFireTime + (c_const_get("world_time") * c_config_get("config.game.timescale") * tank.weapon.repeatRate) then
			tank.lastFireTime = t

			-- fire weapon
			c_weapon_fire(tank)
		end
	end
end

function c_world_projectile_step(d, projectile)
	-- TODO: projectiles can go through teleporters
	if projectile.collided then
		tankbobs.w_removeBody(projectile.m.body)
		c_weapon_projectileRemove(projectile)
		return
	end

	projectile.p[1] = tankbobs.w_getPosition(projectile.m.body)
	projectile.r = tankbobs.w_getAngle(projectile.m.body)
end

local lastPowerupSpawnTime
local nextPowerupSpawnPoint
function c_world_powerupSpawnPoint_step(d, powerupSpawnPoint)
	local t = tankbobs.t_getTicks()
	local spawn = false

	if not lastPowerupSpawnTime then
		lastPowerupSpawnTime = t + c_const_get("world_time") * c_config_get("config.game.timescale") * c_const_get("powerupSpawnPoint_initialPowerupTime") - c_const_get("world_time") * c_config_get("config.game.timescale") * c_const_get("powerupSpawnPoint_powerupTime")
	end

	if c_const_get("powerupSpawnPoints_linked") then
		if not nextPowerupSpawnPoint or powerupSpawnPoint == nextPowerupSpawnPoint then
			if t >= lastPowerupSpawnTime + c_const_get("world_time") * c_config_get("config.game.timescale") * c_const_get("powerupSpawnPoint_powerupTime") then
				lastPowerupSpawnTime = t
				spawn = true

				local found   = false
				local current = false
				for k, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
					if current then
						nextPowerupSpawnPoint = v
						found = true

						break
					elseif v == powerupSpawnPoint then
						current = true
					end
				end
				if not found then
					nextPowerupSpawnPoint = c_tcm_current_map.powerupSpawnPoints[1] or powerupSpawnPoint  -- should never choose the latter, but better to be safe than break the system
				end
			end
		end
	else
		spawn = t >= powerupSpawnPoint.m.nextPowerupTime
	end

	if spawn then
		powerupSpawnPoint.m.nextPowerupTime = t + c_const_get("world_time") * c_config_get("config.game.timescale") * c_const_get("powerupSpawnPoint_powerupTime")

		if c_world_canPowerupSpawn(d, powerupSpawnPoint) then
			-- make sure there's not too many powerups
			local count = #c_world_powerups
			local max = c_const_get("world_maxPowerups")

			if max and max > 0 then
				while count > max do
					count = count - 1

					local powerup = c_world_powerups[#c_world_powerups - count]
					if powerup then
						powerup.collided = true
					end
				end
			end

			-- spawn a powerup
			local powerup = c_world_powerup:new()

			table.insert(c_world_powerups, powerup)

			powerup.typeName = nil

			local found = false
			for k, v in pairs(powerupSpawnPoint.enabledPowerups) do
				if v then
					if found then
						powerupSpawnPoint.m.lastPowerup = k
						powerup.typeName = k
						break
					end
	
					if k == powerupSpawnPoint.m.lastPowerup then
						found = true
					end
				end
			end
			if not powerup.typeName then
				for k, v in pairs(powerupSpawnPoint.enabledPowerups) do
					if v then
						if found then
							powerupSpawnPoint.m.lastPowerup = k
							powerup.typeName = k
							break
						end
					end
				end
			end

			powerup.spawnTime = t

			powerup.p[1](powerupSpawnPoint.p[1])

			powerup.m.body = tankbobs.w_addBody(powerup.p[1], 0, c_const_get("powerup_canSleep"), c_const_get("powerup_isBullet"), c_const_get("powerup_linearDamping"), c_const_get("powerup_angularDamping"), c_world_powerupHull(powerup), c_const_get("powerup_density"), c_const_get("powerup_friction"), c_const_get("powerup_restitution"), not c_const_get("powerup_static"))
			-- add some initial push to the powerup
			local push = tankbobs.m_vec2()
			push.R = c_const_get("powerup_pushStrength")
			push.t = c_const_get("powerup_pushAngle")
			tankbobs.w_setLinearVelocity(powerup.m.body, push)

			c_tcm_current_map.powerupSpawnPoints[1].m.lastSpawnTime = worldTime
		end
	end
end

function c_world_powerupRemove(powerup)
	for k, v in pairs(c_world_powerups) do
		if v == powerup then
			c_world_powerups[k] = nil
		end
	end
end

function c_world_powerup_pickUp(tank, powerup)
	local t = tankbobs.t_getTicks()
	local powerupType = c_world_getPowerupTypeByName(powerup.typeName)

	if powerup.collided then
		return
	end

	powerup.collided = true

	tank.m.lastPickupTime = t

	if powerupType.name == "machinegun" then
		c_weapon_pickUp(tank, powerupType.name)
	end
	if powerupType.name == "shotgun" then
		c_weapon_pickUp(tank, powerupType.name)
	end
	if powerupType.name == "railgun" then
		c_weapon_pickUp(tank, powerupType.name)
	end
	if powerupType.name == "coilgun" then
		c_weapon_pickUp(tank, powerupType.name)
	end
	if powerupType.name == "saw" then
		c_weapon_pickUp(tank, powerupType.name)
	end
	if powerupType.name == "ammo" then
		tank.ammo = tank.ammo + tank.weapon.capacity
	end
	if powerupType.name == "aim-aid" then
		tank.cd.aimAid = not tank.cd.aimAid
	end
	if powerupType.name == "health" then
		tank.health = tank.health + c_const_get("tank_boostHealth")
	end
end

function c_world_powerup_step(d, powerup)
	local t = tankbobs.t_getTicks()

	if powerup.collided then
		tankbobs.w_removeBody(powerup.m.body)
		c_world_powerupRemove(powerup)
		return
	end

	if t > powerup.spawnTime + c_const_get("powerup_lifeTime") and c_const_get("powerup_lifeTime") > 0 then
		powerup.collided = true
	end

	powerup.p[1] = tankbobs.w_getPosition(powerup.m.body)
	--tankbobs.w_setAngle(powerup.m.body, 0)  -- looks better with dynamic rotation
	powerup.r = tankbobs.w_getAngle(powerup.m.body)

	-- keep powerup velocity constant
	local vel = tankbobs.w_getLinearVelocity(powerup.m.body)
	vel.R = c_const_get("powerup_pushStrength")
	tankbobs.w_setLinearVelocity(powerup.m.body, vel)

	for _, v in pairs(c_world_tanks) do
		if v.exists then
			if c_world_intersection(d, c_world_powerupHull(powerup), c_world_tankHull(v), tankbobs.m_vec2(0, 0), tankbobs.w_getLinearVelocity(v.body)) then
				c_world_powerup_pickUp(v, powerup)
			end
		end
	end
end

local function c_world_isTank(body)
	for _, v in pairs(c_world_tanks) do
		if v.body == body then
			return true, v
		end
	end

	return false
end

local function c_world_isProjectile(body)
	for _, v in pairs(c_weapon_getProjectiles()) do
		if v.m.body == body then
			return true, v
		end
	end

	return false
end

local function c_world_isPowerup(body)
	for _, v in pairs(c_world_powerups) do
		if v.m.body == body then
			return true, v
		end
	end

	return false
end

function c_world_tankDamage(tank, damage)
	tank.health = tank.health - damage
end

local c_world_tankDamage = c_world_tankDamage
local function c_world_collide(tank, normal)
	local vel = tankbobs.w_getLinearVelocity(tank.body)
	local component = vel * -normal

	if component >= c_const_get("tank_damageMinSpeed") then
		local damage = c_const_get("tank_damageK") * (component - c_const_get("tank_damageMinSpeed"))

		if damage >= c_const_get("tank_collideMinDamage") then
			c_world_tankDamage(tank, damage)
		end
	end

	tank.m.lastCollideTime = tankbobs.t_getTicks()
	tank.m.intensity = component / c_const_get("tank_intensityMaxSpeed")
	if tank.m.intensity > 1 then
		tank.m.intensity = 1
	end
end

function c_world_contactListener(shape1, shape2, body1, body2, position, separation, normal)
	local b, p
	local powerup = false

	if c_world_isPowerup(body1) or c_world_isPowerup(body2) then
		local tank = select(2, c_world_isTank(body1))
		local tank2 = select(2, c_world_isTank(body2))

		if tank then
			c_world_powerup_pickUp(tank, select(2, c_world_isPowerup(body2)))
		elseif tank2 then
			c_world_powerup_pickUp(tank2, select(2, c_world_isPowerup(body1)))
		end

		powerup = true
	end

	if c_world_isProjectile(body1) or c_world_isProjectile(body2) then
		-- remove the projectile
		local projectile, projectile2

		projectile = select(2, c_world_isProjectile(body1))
		projectile2 = select(2, c_world_isProjectile(body2))

		-- test if the projectile hit a tank
		local tank, tank2

		tank = select(2, c_world_isTank(body1))
		tank2 = select(2, c_world_isTank(body2))

		-- only one of them can be a tank (and if one of them is, only one them can be a projectile)
		if tank then
			if projectile then
				c_weapon_hit(tank, projectile)
			else
				c_weapon_hit(tank, projectile2)
			end
		elseif tank2 then
			if projectile then
				c_weapon_hit(tank2, projectile)
			else
				c_weapon_hit(tank2, projectile2)
			end
		end

		-- this must be after the weapon hits the tank
		if projectile then
			c_weapon_projectileCollided(projectile, body2)
		end

		if projectile2 then
			c_weapon_projectileCollided(projectile2, body1)
		end
	elseif c_world_isTank(body1) or c_world_isTank(body2) then
		local tank, tank2

		tank = select(2, c_world_isTank(body1))
		tank2 = select(2, c_world_isTank(body2))

		if not powerup then
			if tank then
				c_world_collide(tank, normal)
			end

			if tank2 then
				c_world_collide(tank2, normal)
			end
		end
	end
end

local function c_world_private_resetWorldTimers()
	local t = tankbobs.t_getTicks()

	worldTime = tankbobs.t_getTicks()

	for _, v in pairs(c_world_tanks) do
		v.lastFireTime = t
		v.nextSpawnTime = t + c_const_get("world_time") * c_config_get("config.game.timescale") * c_const_get("tank_spawnTime")
	end

	for _, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
		v.m.nextPowerupTime = t + c_const_get("world_time") * c_config_get("config.game.timescale") * c_const_get("powerupSpawnPoint_initialPowerupTime")
	end
end

function c_world_timeWrapped()
	-- this is called whenever the time wraps
	return c_world_private_resetWorldTimers()
end

local paused = false

function c_world_setPaused(set)
	paused = set
end

function c_world_getPaused()
	return paused
end

function c_world_setTimeStep(x)
	tankbobs.w_setTimeStep(x)
end

function c_world_setTimeStep()
	return tankbobs.w_getTimeStep()
end

function c_world_setIterations(x)
	tankbobs.w_setIterations(x)
end

function c_world_setIterations()
	return tankbobs.w_getIterations()
end

function c_world_step(d)
	local t = tankbobs.t_getTicks()

	if worldInitialized then
		if paused then
			c_world_private_resetWorldTimers()
		else
			while worldTime < t do
				for _, v in pairs(c_world_tanks) do
					c_world_tank_step(common_FTM(c_const_get("world_fps")), v)
				end

				for _, v in pairs(c_weapon_getProjectiles()) do
					c_world_projectile_step(common_FTM(c_const_get("world_fps")), v)
				end

				for _, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
					c_world_powerupSpawnPoint_step(common_FTM(c_const_get("world_fps")), v)
				end

				for _, v in pairs(c_world_powerups) do
					c_world_powerup_step(common_FTM(c_const_get("world_fps")), v)
				end

				tankbobs.w_step()

				worldTime = worldTime + common_FTM(c_const_get("world_fps"))
			end
		end
	end
end

function c_world_getTanks()
	return c_world_tanks
end

function c_world_getPowerups()
	return c_world_powerups
end
