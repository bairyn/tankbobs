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

	c_const_set("tank_maxCollisionVectorLength", 975)  -- 975 units

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
	c_const_set("tank_friction", 0.75, 1)  -- deceleration caused by friction (~speed *= 1 - friction)
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
	special = false  -- special causes stronger turning but prevent acceleration or deceleration and the damage from a collision is increased
}

function c_world_tank_spawn(tank)
	tank.spawning = true
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
	tank.v[1].t = c_const_get("tank_defaultRotation")
	tank.v[1].R = 0  -- no velocity
	tank.health = c_const_get("tank_health")
	tank.exists = true
	return true
end

function c_world_intersection(d, p1, p2, v1, v2)
	-- test if two polygons intersect.  p1 and p2 both must be convex.  p1's and p2's points are represented by vectors in a table
	-- returns false if no intercection or collision will occur, or true, normal, point of collision

	-- TODO
	return tankbobs.m_polygon(p1, p2)
end

function c_world_tank_hull(tank)
	-- return a table of coordinates of tank's hull
	local c = {}
	local p = tank.p[1]

	for _, v in pairs(tank.h) do
		local h = tankbobs.m_vec2(v)
		h.t = h.t + tank.r
		table.insert(c, p + h)
	end

	return c
end

function c_world_tank_canSpawn(d, tank)
	-- make sure the tank hasn't already spawned
	if tank.exists then
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
			if c_world_intersection(d, c_world_tank_hull(tank), c_world_tank_hull(v), tankbobs.m_vec2(0, 0), v.v[1]) then
				return false
			end
		end
	end

	return true
end

function c_world_tank_testWorld(d, tank)  -- test tanks against the world
	-- generate polygon covering the hull of the tank before and after it's veloctiy movement
	local hull = {}

	-- test the hull for an intersection against each wall.  When a wall is found, run a line of the velocity of the tank from its position and find all the edges that intersect this line.  The edge whose intersection point is closest on the line is used.  The new velocity is set.  The bigger the angle is of the original angle of velocity in comparison to the new angle of velocity, the less damage and knockback there is (the tank could be scraping against the side of a wall)

	common_clone(c_world_tank_hull(tank), hull)

	-- HACK: temporarily update tank and then add future points
	tank.p[1]:add(d * tank.v[1])

	common_clone(c_world_tank_hull(tank), hull)

	-- reset tank
	tank.p[1]:sub(d * tank.v[1])

	-- test against every wall
	for _, v in pairs(c_tcm_current_map.walls) do
		if tankbobs.m_polygon(hull, v.p) then
			-- find which edge of the wall
			local l = {p1, p2}
			local di
			local llp

			for _, v in pairs(v.p) do
				local clp = v

				if llp then
					local vec = tankbobs.m_vec2()
					vec.R = c_const_get("tank_maxCollisionVectorLength")
					vec.t = tank.v[1].t
					if tank.v[1].R < 0 then
						vec:inv()
					end
					local li, lt = tankbobs.m_edge(tank.p[1], vec, clp, llp)

					if li then
						if not l.p1 or not l.p2 or not di or math.abs((lt - tank.p[1]).R) < d then
							di = math.abs((lt - tank.p[1]).R)
							l.p1 = clp
							l.p2 = llp
						end
					end
--print(tank.p[1].x, tank.p[1].y, vec.x, vec.y, clp.x, clp.y, llp.x, llp.y)
				end

				llp = clp
			end

			-- check the last edge
			if llp and llp ~= v.p[1] then
				local vec = tankbobs.m_vec2()
				vec.R = c_const_get("tank_maxCollisionVectorLength")
				vec.t = tank.v[1].t
				if tank.v[1].R < 0 then
					vec:inv()
				end
				local li, lt = tankbobs.m_edge(tank.p[1], tank.p[1] + vec, llp, v.p[1])

				if li then
					if not l.p1 or not l.p2 or not di or math.abs((lt - tank.p[1]).R) < d then
						di = math.abs((lt - tank.p[1]).R)
						l.p1 = llp
						l.p2 = v.p[1]
					end
				end
--print(tank.p[1].x, tank.p[1].y, vec.x, vec.y, llp.x, llp.y, v.p[1].x, v.p[1].y)
			end

			if not l.p1 or not l.p2 then
				-- reset tank's velocity
				tank.v[1].R = 0

				if c_const_get("debug") then
					io.stderr:write("c_world_testWorld: Warning: no edge detected for collision\n")
				end
			else
				local p = tank.v[1]:project((l.p1 - l.p2):normalof())
				tank.v[1]:add(2 * p)
			end
		end
	end
end

function c_world_tank_step(d, tank)
	local vel = tank.v[1].R

	if tank.state.special then
		if tank.state.left then
			if vel < 0 then  -- rotation needs to be inversed if the tank is traveling backwards to stay conistent
				tank.r = tank.r - d * c_const_get("tank_rotationSpeed") * tank.v[1].R / c_const_get("tank_rotationSpecialSpeed")
			else
				tank.r = tank.r + d * c_const_get("tank_rotationSpeed") * tank.v[1].R / c_const_get("tank_rotationSpecialSpeed")
			end
		end

		if tank.state.right then
			if vel < 0 then
				tank.r = tank.r + d * c_const_get("tank_rotationSpeed") * tank.v[1].R / c_const_get("tank_rotationSpecialSpeed")  -- turns are related to the velocity of the tank in special mode
			else
				tank.r = tank.r - d * c_const_get("tank_rotationSpeed") * tank.v[1].R / c_const_get("tank_rotationSpecialSpeed")  -- turns are related to the velocity of the tank in special mode
			end
		end

		tank.v[1].t = tank.r
	else
		if tank.state.forward then
			local acceleration

			for _, v in pairs(c_const_get("tank_acceleration")) do
				if v[2] then
					if vel >= v[2] then
						acceleration = v[1]
					end
				elseif not acceleration then
					acceleration = v[1]
				end
			end

			tank.v[1].R = vel + d * acceleration
		elseif tank.state.back then
			if tank.v[1].R >= c_const_get("tank_decelerationMinSpeed") then
				tank.v[1].R = tank.v[1].R + d * c_const_get("tank_deceleration")
			end
		else
			-- deceleration is really only caused when the tank isn't accelerating or decelerating.  If it seems strange, you should realize that the tanks have an anti-friction system built into them ;) - note that if friction was always applied then tanks would have a maximum speed limit.
			tank.v[1].R = tank.v[1].R / (1 + d * (1 - c_const_get("tank_friction")))
		end

		if tank.state.left then
			tank.r = tank.r + d * c_const_get("tank_rotationSpeed")
		end

		if tank.state.right then
			tank.r = tank.r - d * c_const_get("tank_rotationSpeed")
		end

		if tank.v[1].R >= c_const_get("tank_rotationVelocityMinSpeed") then
			tank.v[1].t = tank.v[1].t - ((tank.v[1].t - tank.r) * d * c_const_get("tank_rotationVelocitySpeed"))
		else
			tank.v[1].t = tank.v[1].t - ((tank.v[1].t - tank.r) * d * c_const_get("tank_rotationVelocityCatchUpSpeed"))
		end
	end

	c_world_tank_testWorld(d, tank)

	tank.p[1]:add(tank.v[1] * d)
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
		d = 1.0E-6  -- make a very inaccurate accurate guess
	end

	-- check for tanks needing spawn
	for _, v in pairs(c_world_tanks) do
		c_world_tank_checkSpawn(d, v)
		c_world_tank_step(d, v)
	end
end
