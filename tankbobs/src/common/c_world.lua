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

local lastTime = 0

function c_world_init()
	c_config_cheat_protect("config.game.timescale")

	c_const_set("world_time", 1000)  -- everything is relative to change and seconds.  A speed of 5 means 5 units per second

	c_const_set("world_timeWrapTest", -99999)

	c_const_set("world_lowerBoundx", -9999, 1) c_const_set("world_lowerBoundy", -9999, 1)
	c_const_set("world_upperBoundx",  9999, 1) c_const_set("world_upperBoundy",  9999, 1)
	c_const_set("world_gravityx", 0, 1) c_const_set("world_gravityy", 0, 1)
	c_const_set("world_allowSleep", true, 1)

	c_const_set("tank_maxCollisionVectorLength", 975)  -- 975 units

	-- hull of tank facing right
	c_const_set("tank_hullx1", -2.0, 1) c_const_set("tank_hully1",  2.0, 1)
	c_const_set("tank_hullx2", -2.0, 1) c_const_set("tank_hully2", -2.0, 1)
	c_const_set("tank_hullx3",  2.0, 1) c_const_set("tank_hully3", -1.0, 1)
	c_const_set("tank_hullx4",  2.0, 1) c_const_set("tank_hully4",  1.0, 1)
	c_const_set("tank_health", 100, 1)
	c_const_set("tank_damageK", 2, 1)  -- damage relative to speed before a collision: 2 hp / 1 ups
	c_const_set("tank_damageMinSpeed", 20, 1)
	c_const_set("tank_collideMinDamage", 5, 1)
	c_const_set("tank_deceleration", -24, 1)
	c_const_set("tank_decelerationMinSpeed", -4, 1)
	c_const_set("tank_acceleration",
	{
		{64},  -- acceleration of 64 units per second by default
		{48, 8},  -- unless the tank's speed is at least 8 units per second, in which case the acceleration is dropped to 48
		{32, 12},
		{16, 16},
		{8, 24},
		{4, 32},
		{2, 48},
		{1.75, 50},
		{1.5, 55}
	}, 1)
	c_const_set("tank_forceSpeedK", 5, 1)
	c_const_set("tank_density", 2, 1)
	c_const_set("tank_friction", 0.25, 1)
	c_const_set("tank_worldFriction", 0.25, 1)  -- damping
	c_const_set("tank_restitution", 0.4, 1)
	c_const_set("tank_canSleep", true, 1)
	c_const_set("tank_isBullet", true, 1)
	c_const_set("tank_linearDamping", 0, 1)
	c_const_set("tank_angularDamping", 0, 1)
	c_const_set("tank_accelerationVectorPointTest", -90, 1)  -- the origin of acceleration force
	c_const_set("tank_decelerationVectorPointTest", 90, 1)
	c_const_set("tank_spawnTime", 0.75, 1)
	c_const_set("wall_density", 1, 1)
	c_const_set("wall_friction", 0.25, 1)  -- deceleration caused by friction (~speed *= 1 - friction)
	c_const_set("wall_restitution", 0.2, 1)
	c_const_set("wall_canSleep", true, 1)
	c_const_set("wall_isBullet", true, 1)
	c_const_set("wall_linearDamping", 0, 1)
	c_const_set("wall_angularDamping", 0, 1)
	c_const_set("tank_rotationVelocitySpeed", 0.75, 1)  -- for every second, velocity matches 3/4 rotation  -- FIXME: the actual rotation turning speed is about a quarter of this
	c_const_set("tank_rotationVelocityMinSpeed", 24, 1)  -- if at least 24 ups
	c_const_set("tank_rotationVelocityCatchUpSpeed", 0.875, 1)  -- FIXME: as well
	c_const_set("tank_rotationSpeed", c_math_radians(135), 1)  -- 135 degrees per second
	c_const_set("tank_rotationSpecialSpeed", c_math_degrees(1) / 3.5, 1)
	c_const_set("tank_defaultRotation", c_math_radians(90), 1)  -- up

	c_world_tanks = {}
end

function c_world_done()
end

function c_world_newWorld()
	tankbobs.w_newWorld(tankbobs.m_vec2(c_const_get("world_lowerBoundx"), c_const_get("world_lowerBoundy")), tankbobs.m_vec2(c_const_get("world_upperBoundx"), c_const_get("world_upperBoundy")), tankbobs.m_vec2(c_const_get("world_gravityx"), c_const_get("world_gravityy")), c_const_get("world_allowSleep"), "c_world_contactListener")

	for _, v in pairs(c_tcm_current_map.walls) do
		if v.detail then
			return  -- the wall isn't part of the physical world
		end

		-- add wall to world
		local b = c_world_wallShape(v)
		v.m.body = tankbobs.w_addBody(b[1], 0, c_const_get("wall_canSleep"), c_const_get("wall_isBullet"), c_const_get("wall_linearDamping"), c_const_get("wall_angularDamping"), b[2], c_const_get("wall_density"), c_const_get("wall_friction"), c_const_get("wall_restitution"), not v.static)
		if not v.m.body then
			error "c_world_newWorld: could not add a wall to the physical world"
		end
	end
end

function c_world_freeWorld()
	tankbobs.w_freeWorld()
end

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
		o.state = c_world_tank_state:new()
	end,

	p = {},
	h = {},  -- physical box: four vectors of offsets for tanks
	r = 0,  -- tank's rotation
	w = 0,  -- tank's rotation
	name = "",
	exists = false,
	spawning = false,
	lastSpawnPoint = 0,
	state = nil,
	weapon = nil,
	lastFireTime = 0,
	body = nil,  -- physical body
	health = 0,
	nextSpawnTime = 0
}

c_world_tank_state =
{
	new = common_new,

	firing = false,
	forward = false,
	back = false,
	right = false,
	left = false,
	special = false  -- special causes stronger turning but prevent acceleration or deceleration and the damage from a collision is increased
}

function c_world_tank_spawn(tank)
	tank.spawning = true
end

function c_world_tank_die(tank)
	-- this function is called when a tank dies.  Don't call this function if the tank hasn't spawned yet.
	tank.exists = false
	tankbobs.w_removeBody(tank.body)
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
	tank.w = tank.r
	tank.p[1](playerSpawnPoint.p[1])
	tank.health = c_const_get("tank_health")
	tank.weapon = c_weapon_getByAltName("default")
	tank.exists = true

	-- add a physical body
	tank.body = tankbobs.w_addBody(tank.p[1], tank.r, c_const_get("tank_canSleep"), c_const_get("tank_isBullet"), c_const_get("tank_linearDamping"), c_const_get("tank_angularDamping"), tank.h, c_const_get("tank_density"), c_const_get("tank_friction"), c_const_get("tank_restitution"), true)
	return true
end

function c_world_intersection(d, p1, p2, v1, v2)
	-- detects if two polygons ever collide

	local p1h = {}
	local p2h = {}
	local p1a = {}
	local p2a = {}

	common_clone(p1, p1h)
	common_clone(p2, p2h)
	common_clone(p1h, p1a)
	common_clone(p2h, p2a)

	for _, v in pairs(p1a) do
		v = v + d * v1
	end
	for _, v in pairs(p2a) do
		v = v + d * v2
	end

	common_clone(p1a, p1h)
	common_clone(p2a, p2h)

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

function c_world_tank_step(d, tank)
	local w = tank.w
	local t = tankbobs.t_getTicks()

	if not tank.exists then
		return
	end

	if tank.health <= 0 then
		tankbobs.w_removeBody(tank.body)
		tank.nextSpawnTime = t + c_const_get("world_time") * c_config_get("config.game.timescale") * c_const_get("tank_spawnTime")
		tank.exists = false
		tank.spawning = true
		return
	end

	tank.p[1] = tankbobs.w_getPosition(tank.body)

	local vel = tankbobs.w_getLinearVelocity(tank.body).R

	if tank.state.special then
		if tank.state.left then
			if vel < 0 then  -- inverse rotation
				tank.r = tank.r - d * c_const_get("tank_rotationSpeed") * vel / c_const_get("tank_rotationSpecialSpeed")
			else
				tank.r = tank.r + d * c_const_get("tank_rotationSpeed") * vel / c_const_get("tank_rotationSpecialSpeed")
			end
		end

		if tank.state.right then
			if vel < 0 then  -- inverse rotation
				tank.r = tank.r + d * c_const_get("tank_rotationSpeed") * vel / c_const_get("tank_rotationSpecialSpeed")
			else
				tank.r = tank.r - d * c_const_get("tank_rotationSpeed") * vel / c_const_get("tank_rotationSpecialSpeed")
			end
		end

		tank.w = tank.r

		local v = tankbobs.m_vec2()
		v.R = vel
		v.t = tank.w

		tankbobs.w_setLinearVelocity(tank.body, v)
	else
		if tank.state.forward then
			-- determine the degree of acceleration
			local acceleration

			for _, v in pairs(c_const_get("tank_acceleration")) do
				if v[2] then
					if vel >= v[2] * c_const_get("tank_forceSpeedK") then
						acceleration = v[1]
					end
				elseif not acceleration then
					acceleration = v[1] * c_const_get("tank_forceSpeedK")
				end
			end

			-- apply a force
			local point = tankbobs.w_getCenterOfMass(tank.body)
			local force = tankbobs.m_vec2()
			force.R = vel + acceleration
			force.t = tankbobs.w_getAngle(tank.body)
			tankbobs.w_applyForce(tank.body, force, point)
		elseif tank.state.back then
			-- apply deceleration to the tank
			local point = tankbobs.w_getCenterOfMass(tank.body)
			local force = tankbobs.m_vec2()
			force.R = c_const_get("tank_deceleration") * c_const_get("tank_forceSpeedK")
			force.t = tankbobs.w_getAngle(tank.body)
			tankbobs.w_applyForce(tank.body, force, point)
		else
			-- deceleration is really only caused when the tank isn't accelerating or decelerating.  If it seems strange, you should realize that the tanks have an anti-friction system built into them ;) - note that if friction was always applied then tanks would have a maximum speed limit.
			local v = tankbobs.m_vec2(tankbobs.w_getLinearVelocity(tank.body))
			--v.R = v.R / (1 + d * c_const_get("tank_worldFriction"))  -- FIXME: fix deceleration
			tankbobs.w_setLinearVelocity(tank.body, v)
		end

		if tank.state.left then
			tank.r = tank.r + d * c_const_get("tank_rotationSpeed")
		end

		if tank.state.right then
			tank.r = tank.r - d * c_const_get("tank_rotationSpeed")
		end

		if vel >= c_const_get("tank_rotationVelocityMinSpeed") * c_const_get("tank_forceSpeedK") then
			tank.w = w - ((w - tank.r) * d * c_const_get("tank_rotationVelocitySpeed"))
		else
			tank.w = w - ((w - tank.r) * d * c_const_get("tank_rotationVelocityCatchUpSpeed"))
		end
	end

	tankbobs.w_setAngle(tank.body, tank.w)

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

function c_world_isTank(body)
	for _, v in pairs(c_world_tanks) do
		if v.body == body then
			return true, v
		end
	end

	return false
end

function c_world_isProjectile(body)
	for _, v in pairs(c_world_projectiles) do
		if v.m.body == body then
			return true, v
		end
	end

	return false
end

function c_world_tankDamage(tank, damage)
	tank.health = tank.health - damage
end

function c_world_collide(tank, normal)
	local vel = tankbobs.w_getLinearVelocity(tank.body).R

	if vel >= c_const_get("tank_damageMinSpeed") then
		local damage = c_const_get("tank_damageK") * (vel - c_const_get("tank_damageMinSpeed"))

		damage = damage / (1 + math.abs(normal.t - tank.w) / tankbobs.m_radians(180))

		if damage >= c_const_get("tank_collideMinDamage") then
			c_world_tankDamage(tank, damage)
		end
	end
end

function c_world_contactListener(shape1, shape2, body1, body2, position, separation, normal)
	local b, p

	if c_world_isProjectile(body1) or c_world_isProjectile(body2) then
		-- remove the projectile
		local projectile, projectile2

		projectile = select(2, c_world_isProjectile(body1))
		projectile2 = select(2, c_world_isProjectile(body2))

		if projectile then
			projectile.collided = true
		end

		if projectile2 then
			projectile2.collided = true
		end

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
	elseif c_world_isTank(body1) or c_world_isTank(body2) then
		local tank, tank2

		tank = select(2, c_world_isTank(body1))
		tank2 = select(2, c_world_isTank(body2))

		if tank then
			c_world_collide(tank, normal)
		end

		if tank2 then
			c_world_collide(tank2, normal)
		end
	end
end

function c_world_step()
	if lastTime == 0 then
		lastTime = tankbobs.t_getTicks()
		return
	end

	if c_config_get("config.server.minFrameLatency") < c_const_get("server_mlf") then
		c_config_set("config.server.minFrameLatency", c_const_get("server_mlf"))
	end

	if tankbobs.t_getTicks() - lastTime < c_const_get("world_timeWrapTest") then
		--handle time wrap here
		lastTime = tankbobs.t_getTicks()
		return;
	end

	if tankbobs.t_getTicks() - lastTime < c_config_get("config.server.minFrameLatency") then
		return;
	end

	local d = (tankbobs.t_getTicks() - lastTime) / (c_const_get("world_time") * c_config_get("config.game.timescale"))
	lastTime = tankbobs.t_getTicks()

	if d == 0 then
		d = 1.0E-6  -- make an inaccurate accurate guess
	end

	-- check for tanks needing spawn
	for _, v in pairs(c_world_tanks) do
		c_world_tank_checkSpawn(d, v)
		c_world_tank_step(d, v)
	end

	for _, v in pairs(c_world_projectiles) do
		c_world_projectile_step(d, v)
	end

	tankbobs.w_setTimeStep(d)
	tankbobs.w_step()
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
