--[[
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
--]]

--[[
c_world.lua

world and physics
--]]

local lastTime = 0

function c_world_init()
	c_const_set("world_time", 1000)  -- everything is relative to change and seconds.  A speed of 5 means 5 units per second

	c_const_set("tank_health", 100, 1)
	c_const_set("tank_hullx1", -7.5, 1)
	c_const_set("tank_hully1", +7.5, 1)
	c_const_set("tank_hullx2", -7.5, 1)
	c_const_set("tank_hully2", -7.5, 1)
	c_const_set("tank_hullx3", +7.5, 1)
	c_const_set("tank_hully3", -7.5, 1)
	c_const_set("tank_hullx4", +7.5, 1)
	c_const_set("tank_hully4", +7.5, 1)

	c_world_tanks = {}
end

function c_world_done()
end

c_world_tank =
{
	new = common_new,

	init = function (o)
		name = "UnnamedPlayer"
		o.p[1] = c_vec2:new()
		o.v[1] = c_vec2:new()
		o.h[1] = c_vec2:new()
		o.h[2] = c_vec2:new()
		o.h[3] = c_vec2:new()
		o.h[4] = c_vec2:new()
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
	forward = false,
	right = false,
	left = false
}

function c_world_tank_spawn(tank)
	tank.spawning = true
end

function c_world_tank_checkSpawn(tank)
	if not tank.spawning then
		return
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
			return
		end
	end

	-- spawn
	tank.v[1].R = 0  -- no velocity
	tank.p[1](playerSpawsPoint.p[1])
	tank.health = c_const_get("tank_health")
	tank.exists = true
end

function c_world_tank_canSpawn(tank)
	-- test if spawning interfere with another tank
	return true
end

function c_world_step()
	if lastTime == 0 then
		lastTime = tankbobs.t_getTicks()
		return
	end

	local d = (tankbobs.t_getTicks() - lastTime) / (c_const_get("world_time") * c_config_get("config.game.timescale))
	lastTime = tankbobs.t_getTicks()
end
