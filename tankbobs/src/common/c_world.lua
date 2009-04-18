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

	-- hull of tank facing right
	c_const_set("tank_health", 100, 1)
	c_const_set("tank_hullx1", -2.0, 1)
	c_const_set("tank_hully1",  2.0, 1)
	c_const_set("tank_hullx2", -2.0, 1)
	c_const_set("tank_hully2", -2.0, 1)
	c_const_set("tank_hullx3",  2.0, 1)
	c_const_set("tank_hully3", -1.0, 1)
	c_const_set("tank_hullx4",  2.0, 1)
	c_const_set("tank_hully4",  1.0, 1)
	c_const_set("tank_deceleration", -1.75, 1)
	c_const_set("tank_acceleration1", 16, 1)
	c_const_set("tank_acceleration2", 4, 1)
	c_const_set("tank_acceleration3", 2, 1)  -- acceleration 1 unit / second
	c_const_set("tank_acceleration3Speed", 4, 1)
	c_const_set("tank_acceleration2Speed", 2, 1)
	c_const_set("tank_friction", 0.75, 1)  -- deceleration caused by friction (~speed *= 1 - friction)
	c_const_set("tank_rotationVelocitySpeed", 0.75, 1)  -- for every second, velocity matches 3/4 rotation
	c_const_set("tank_rotationSpeed", c_math_radians(135), 1)  -- 135 degrees per second
	c_const_set("tank_rotationSpecialSpeed", c_math_degrees(1) / 3.5, 1)
	c_const_set("tank_defaultRotation", c_math_radians(90), 1)  -- up

	c_world_tanks = {}
end

function c_world_done()
end

c_world_tank =
{
	new = common_new,

	init = function (o)
		name = "UnnamedPlayer"
		o.p[1] = tankbobs.m_vec2()
		o.v[1] = tankbobs.m_vec2()
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
	v = {},
	h = {},  -- physical box: four vectors of offsets for tanks
	r = 0,  -- tank's rotation
	name = "",
	exists = false,
	spawning = false,
	lastSpawnPoint = 0,
	state = nil,
	health = 0
}

c_world_tank_state =
{
	new = common_new,

	forward = false,
	back = false,
	right = false,
	left = false,
	special = false  -- special causes stronger turning but prevent acceleration or deceleration
}

function c_world_tank_spawn(tank)
	tank.spawning = true
end

function c_world_tank_checkSpawn(tank)
	if not tank.spawning then
		return
	end

	if tank.lastSpawnPoint == 0 then
		tank.lastSpawnPoint = 1
	end

	local sp = tank.lastSpawnPoint
	local playerSpawnPoint = c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint]

	while not c_world_tank_canSpawn(tank) do
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
	tank.v[1].t = c_const_get("tank_defaultRotation")
	tank.v[1].R = 0  -- no velocity
	tank.p[1](playerSpawnPoint.p[1])
	tank.health = c_const_get("tank_health")
	tank.exists = true
	return true
end

function c_world_intersection(p1, p2)
	-- test if two polygons intersect.  p1 and p2 both must be convex.  p1's and p2's points are represented by vectors in their table
end

function c_world_tank_hull(tank)
	-- return a table of coordinates of tank's hull
	local c = {}

	for _, v in ipairs(tank.h) do
		local v = tankbobs.m_vec2()
		v(tank.p[1].x + v.x, tank.p[1].y + v.y)
		table.insert(c, v)
	end

	return c
end

function c_world_tank_canSpawn(tank)
	-- see if the spawn point exists
	if not c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint] then
		return false
	end

	-- test if spawning interferes with another tank
	for _, v in pairs(c_world_tanks) do
		if c_world_intersection(c_world_tank_hull(tank), c_world_tank_hull(v)) then
			return false
		end
	end

	return true
end

function c_world_tank_step(d, tank)
	if tank.state.special then
		if tank.state.left then
			tank.r = tank.r + d * c_const_get("tank_rotationSpeed") * tank.v[1].R / c_const_get("tank_rotationSpecialSpeed")
		end

		if tank.state.right then
			tank.r = tank.r - d * c_const_get("tank_rotationSpeed") * tank.v[1].R / c_const_get("tank_rotationSpecialSpeed")  -- turns are related to the velocity of the tank in special mode
		end

		tank.v[1].t = tank.r
	else
		if tank.state.forward then
			if tank.v[1].R >= c_const_get("tank_acceleration3Speed") then
				tank.v[1].R = tank.v[1].R + d * c_const_get("tank_acceleration3")
			elseif tank.v[1].R >= c_const_get("tank_acceleration2Speed") then
				tank.v[1].R = tank.v[1].R + d * c_const_get("tank_acceleration2")
			else
				tank.v[1].R = tank.v[1].R + d * c_const_get("tank_acceleration1")
			end
		elseif tank.state.back then
			tank.v[1].R = tank.v[1].R + d * c_const_get("tank_deceleration")
		else
			-- deceleration is really only caused when the tank isn't accelerating or decelerating.  If it seems strange, you should realize that the tanks have an anti-friction system built into them ;) - note that if friction was always applied then tanks would have a maximum speed
			tank.v[1].R = tank.v[1].R / (1 + d * (1 - c_const_get("tank_friction")))
		end

		if tank.state.left then
			tank.r = tank.r + d * c_const_get("tank_rotationSpeed")
		end

		if tank.state.right then
			tank.r = tank.r - d * c_const_get("tank_rotationSpeed")
		end

		tank.v[1].t = tank.v[1].t - d * c_const_get("tank_rotationVelocitySpeed") * (tank.v[1].t - tank.r)
	end

	tank.p[1]:add(tank.v[1] * d)
end

function c_world_step()
	if lastTime == 0 then
		lastTime = tankbobs.t_getTicks()
		return
	end

	local d = (tankbobs.t_getTicks() - lastTime) / (c_const_get("world_time") * c_config_get("config.game.timescale"))
	lastTime = tankbobs.t_getTicks()

	-- check for tanks needing spawn
	for _, v in pairs(c_world_tanks) do
		c_world_tank_checkSpawn(v)
		c_world_tank_step(d, v)
	end
end
