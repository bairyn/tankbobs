--[[
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
--]]

--[[
c_ai.lua

Bot AI
--]]

function c_ai_init()
	c_const_set("ai_fps", 50)
	c_const_set("ai_fpsRelativeToSkill", 150)

	c_const_set("ai_minSkill", 1)  -- most difficult to fight against
	c_const_set("ai_maxSkill", 16)  -- least difficult to fight against
	c_const_set("ai_maxSkillInstagib", 8)

	c_const_set("ai_botRange", 200)
	c_const_set("ai_botAccuracy", 0.08)  -- accuracy of most skilled bot; lower is better (can be up to x secs off)
	c_const_set("ai_shootAngle", (math.pi * 2) / 64)  -- (Tankbobs uses radians)
	c_const_set("ai_maxSpeed", 12)  -- brake if above this speed, even if attacking
	c_const_set("ai_maxSpeedInstagib", 56)  -- brake if above this speed, even if attacking
	c_const_set("ai_minSpecialSpeed", 8)
	c_const_set("ai_minSpecialSpeedInstagib", 32)
	c_const_set("ai_minObjectiveSpeed", 24)
	c_const_set("ai_minObjectiveSpeedInstagib", 24)
	c_const_set("ai_objectiveDistance", 25)
	c_const_set("ai_accelerateNearEnemyFrequency", 32)  -- lower is more
	c_const_set("ai_skipUpdateRandomReduce", 0.5)
	c_const_set("ai_skipUpdateRandom", 1.35)
	c_const_set("ai_chaseEnemyChance", 6)  -- lower is more likely (chance of 1 / x)
	c_const_set("ai_chaseEnemyChanceInstagib", 2)
	c_const_set("ai_noFireSpawnTime", -1)
	c_const_set("ai_noFireSpawnTimeInstagib", 0.8)

	c_const_set("ai_followRandom", (math.pi * 2) / 64)  -- +- x radians when least skilled bot is following an objective
	c_const_set("ai_stopCloseSpeed", 2)
	c_const_set("ai_coastMinSpeed", 8)
	c_const_set("ai_reverseChance", 3)
	c_const_set("ai_closeWallVerySmall", 5)
	c_const_set("ai_closeWallSmall", 25)
	c_const_set("ai_closeWallBig", 50)
	c_const_set("ai_pathUpdateTime", 2)
	c_const_set("ai_staticPathUpdateTime", 8)
	c_const_set("ai_nextNodeDistance", 3)

	c_const_set("ai_enemyControlPointRange", 15)
end

function c_ai_done()
end

local names =
{ "Ripper"
, "Bartholomew"
, "Botter"
, "Ms. Durban"
, "Dude"
, "Shooter"
, "Aimer"
}

-- follow type
local AVOID            = 0
local AVOIDINSIGHT     = 0
local INSIGHT          = 2
local ALWAYS           = 3
local ALWAYSANDDESTROY = 4  -- shoot at nearby tanks (within ai_objectiveDistance units)

-- objective indexes (objective with higher index will override other objectives)
local GENERICINDEX = 1
local POWERUPINDEX = 2

function c_ai_angleRange(a, b)
	while math.abs(a - b) > math.pi + 0.001 do
		if a > b then
			if a > 0 then
				a = a - 2 * math.pi
			else
				b = b + 2 * math.pi
			end
		else
			if a < 0 then
				a = a + 2 * math.pi
			else
				b = b - 2 * math.pi
			end
		end
	end

	return a, b
end

function c_ai_initTank(tank, ai)
	tank.bot = true
	tank.ai = {}

	local maxSkillRandom = c_world_getInstagib() and c_const_get("ai_maxSkillInstagib") or c_const_get("ai_maxSkill")
	tank.ai.skill = math.random(c_const_get("ai_minSkill"), maxSkillRandom)

	tank.color.r = c_config_get("game.bot.color.r")
	tank.color.g = c_config_get("game.bot.color.g")
	tank.color.b = c_config_get("game.bot.color.b")

	if c_world_isTeamGameType() then
		-- place bot randomly on the team with fewest players
		local balance = 0  -- -: blue; +: red

		for k, v in pairs(c_world_getTanks()) do
			if v.red then
				balance = balance + 1
			else
				balance = balance - 1
			end
		end

		if balance > 0 then 
			tank.red = false
		elseif balance < 0 then
			tank.red = true
		else
			tank.red = math.random(0, 1) == 1 and false or true
		end
	end

	if ai then
		tankbobs.t_clone(ai, tank.ai)
	end

	tank.ai.nextStepTime = tankbobs.t_getTicks()

	tank.ai.objectives = {}

	tank.name = "[BOT] (" .. tostring(tank.ai.skill) .. ") " .. names[math.random(1, #names)]
end

function c_ai_setTankStateRotation(tank, rot)  -- positive is right
	if rot > 0 then
		tank.state = bit.band(tank.state, bit.bnot(LEFT))
		tank.state = bit.bor(tank.state, RIGHT)
	elseif rot < 0 then
		tank.state = bit.bor(tank.state, LEFT)
		tank.state = bit.band(tank.state, bit.bnot(RIGHT))
	else
		tank.state = bit.band(tank.state, bit.bnot(LEFT))
		tank.state = bit.band(tank.state, bit.bnot(RIGHT))
	end
end

function c_ai_setTankStateForward(tank, s)  -- 0: nothing; 1: forward; -1: break; -2: reverse
	if s == 0 then
		tank.state = bit.band(tank.state, bit.bnot(FORWARD))
		tank.state = bit.band(tank.state, bit.bnot(BACK))
		tank.state = bit.band(tank.state, bit.bnot(REVERSE))
	elseif s == 1 then
		tank.state = bit.bor(tank.state, FORWARD)
		tank.state = bit.band(tank.state, bit.bnot(BACK))
		tank.state = bit.band(tank.state, bit.bnot(REVERSE))
	elseif s == -1 then
		tank.state = bit.band(tank.state, bit.bnot(FORWARD))
		tank.state = bit.bor(tank.state, BACK)
		tank.state = bit.band(tank.state, bit.bnot(REVERSE))
	elseif s == -2 then
		tank.state = bit.band(tank.state, bit.bnot(FORWARD))
		tank.state = bit.band(tank.state, bit.bnot(BACK))
		tank.state = bit.bor(tank.state, REVERSE)
	end
end

function c_ai_getTankStateForward(tank)
	if bit.band(tank.state, FORWARD) then
		return 1
	elseif bit.band(tank.state, BACK) then
		return -1
	elseif bit.band(tank.state, REVERSE) then
		return -2
	else
		return 0
	end
end

function c_ai_setTankStateFire(tank, fire)  -- 0 or false; no fire
	if fire and fire ~= 0 then
		tank.state = bit.bor(tank.state, FIRING)
	else
		tank.state = bit.band(tank.state, bit.bnot(FIRING))
	end
end

function c_ai_setTankStateSpecial(tank, special)  -- 0 or false; no special
	if special and special ~= 0 then
		tank.state = bit.bor(tank.state, SPECIAL)
	else
		tank.state = bit.band(tank.state, bit.bnot(SPECIAL))
	end
end

function c_ai_relativeTankSkill(tank)
	local s, m, l = c_const_get("ai_minSkill"), tank.ai.skill, c_const_get("ai_maxSkill")
	return (m - s) / (l - s)
end

local p1, p2, tmp = tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()
function c_ai_closestEnemyInSite(tank, filter)
	-- returns the closest tank that can be shot at, the angle at which the tank will need to be so that a bullet will shoot the tank, the position of the collision, and the time it takes for the projectile to reach the collision point, if its velocity is constant
	local tanks = {}
	local range = c_const_get("ai_botRange")
	local accuracy = 2 * c_const_get("ai_botAccuracy") * tank.ai.skill
	local dir
	local weapon = c_weapon_getWeapons()[tank.weapon]

	if not weapon then
		return
	end

	for _, v in pairs(c_world_getTanks()) do
		if v.exists and tank ~= v and (not c_world_isTeamGameType() or tank.red ~= v.red) and (not filter or filter(v)) then
			-- set first point to initial position of projectile
			p1.R = weapon.launchDistance
			p1.t = tank.r
			p1:add(tank.p)

			-- find the angle at which the tank will need to be to shoot the enemy
			local vel = tankbobs.w_getLinearVelocity(v.body)
			local low, high = 0, (range * weapon.speed + range * vel.R) / (range * range)
			while high - low > accuracy do
				local time = (low + high) / 2
				local projectileDistance = time * weapon.speed
				dir = ((v.p + time * vel) - p1).t
				tmp.R = weapon.speed
				tmp.t = dir
				local distanceToTarget = ((v.p + time * vel) - (p1 + time * tmp)).R

				if projectileDistance < distanceToTarget then
					low = time
				elseif projectileDistance > distanceToTarget then
					high = time
				else
					break  -- unlikely to happen
				end
			end
			local time = (low + high) / 2

			-- test if anything intersects between the tank and this point
			p2(v.p + time * vel)
			tmp.R = 2.1
			tmp.t = (p2 - p1).t
			p2:sub(tmp)

			local s, _, t, _ = c_world_findClosestIntersection(p1, p2)
			if not s or t == "tank" then
				table.insert(tanks, {v, dir, v.p + time * vel, time})
			end
		end
	end

	table.sort(tanks, function (a, b) return (a[3] - tank.p).R < (b[3] - tank.p).R end)

	if tanks[1] then
		return unpack(tanks[1])
	end
end

function c_ai_setObjective(tank, index, pos, followType, objectiveType, static)
	if not tank.ai.objectives[index] then
		tank.ai.objectives[index] = {}
	end

	tank.ai.objectives[index].objective = tankbobs.m_vec2(pos)
	tank.ai.objectives[index].followType = followType or tank.ai.followType or INSIGHT
	tank.ai.objectives[index].objectiveType = objectiveType
	tank.ai.objectives[index].static = static
end

function c_ai_findClosestPowerup(tank)
	-- nothing depends on order of powerup table, so we sort it directly
	table.sort(c_world_getPowerups(), function (a, b) if a and b then return (a.p - tank.p).R < (b.p - tank.p).R elseif a then return true else return false end end)
	return c_world_getPowerups()[1]
end

function c_ai_shootEnemies(tank, enemy, angle, pos, time)
	if not tank.ai.shootingEnemies then
		-- start shooting enemies
		c_ai_setTankStateSpecial(tank, false)

		local chaseEnemyChance = c_world_getInstagib() and c_const_get("ai_chaseEnemyChanceInstagib") or c_const_get("ai_chaseEnemyChance")
		if math.random(1, chaseEnemyChance) == 1 then
			c_ai_setTankStateForward(tank, 1)
		else
			c_ai_setTankStateForward(tank, 0)
		end
	end

	tank.ai.shootingEnemies = true

	tank.r, angle = c_ai_angleRange(tank.r, angle)

	if math.random(1000 * c_ai_relativeTankSkill(tank), 1000 * (1 + c_const_get("ai_skipUpdateRandomReduce"))) / 1000 < c_const_get("ai_skipUpdateRandom") then
		-- randomly skip updates to rotation depending on skill level
		c_ai_setTankStateRotation(tank, tank.r - angle)
		if tankbobs.t_getTicks() > tank.ai.noFireTime then
			c_ai_setTankStateFire(tank, math.abs(angle - tank.r) <= tank.ai.skill * c_const_get("ai_shootAngle"))
		else
			c_ai_setTankStateFire(tank, false)
		end

		-- randomly accelerate or reverse
		if math.random(1, c_const_get("ai_accelerateNearEnemyFrequency") * tank.ai.skill) == 1 then
			local s = c_ai_getTankStateForward(tank)
			if s > 0 then
				c_ai_setTankStateForward(tank, math.random(1, c_const_get("ai_reverseChance")) == 1 and -2 or 0)
			elseif s < 0 then
				c_ai_setTankStateForward(tank, math.random(1, c_const_get("ai_reverseChance")) == 1 and 0 or 1)
			else
				c_ai_setTankStateForward(tank, math.random(1, c_const_get("ai_reverseChance")) == 1 and -2 or 1)
			end
		end
	end
end

function c_ai_tankSpawn(tank)
	local noFireTime = c_world_getInstagib() and c_const_get("ai_noFireSpawnTimeInstagib") or c_const_get("ai_noFireSpawnTime")
	tank.ai.noFireTime = tankbobs.t_getTicks() + c_config_get("game.timescale") * c_const_get("world_time") * noFireTime
end

function c_ai_tankDie(tank)
	tank.ai.turning = nil
	tank.ai.close = false
end

function c_ai_findClosestWayPoint(pos)
	-- returns the closest way point to and the weight of traveling from a position
	local lastPoint, currentPoint = nil
	local hull
	local w = {}

	for ks, vs in pairs(c_tcm_current_map.wayPoints) do
		local intersection = false
		local weight = (vs.p - pos).R

		for _, vss in pairs(c_tcm_current_map.walls) do
		if not vss.detail and vss.static then  -- ignore dynamic walls when testing for intersections
			--hull = vss.m.pos
			hull = vss.p
				local t = v
				for _, vsss in pairs(hull) do
					currentPoint = vsss
					if not lastPoint then
						lastPoint = hull[#hull]
					end

					if tankbobs.m_edge(lastPoint, currentPoint, pos, vs.p) then
						intersection = true
						break
					end

					lastPoint = currentPoint
				end
				lastPoint = nil
			end
		end

		if not intersection then
			table.insert(w, {ks, weight})
		end
	end

	table.sort(w, function (a, b) return (c_tcm_current_map.wayPoints[a[1]].p - pos).R < (c_tcm_current_map.wayPoints[b[1]].p - pos).R end)

	return w[1]
end

function c_ai_weightOfPosToWayPoint(pos, wayPoint)
	return (pos - wayPoint.p).R
end

function c_ai_findClosestPath(start, goal)
	if not start or not goal then
		return nil
	end

	local net = c_tcm_current_map.wayPointNetwork

	local path = {}
	local closed = {}

	local goalPos
	if goal > 0 then
		goalPos = c_tcm_current_map.wayPoints[goal].p
	else
		goalPos = c_tcm_current_map.teleporters[-goal].p
	end

	local function orderByWeight(a, b)
		for _, v in pairs(closed) do
			if v == a[1] then
				return false  -- a is closed, b first
			elseif v == b[1] then
				return true  -- b is closed, a first
			end
		end

		-- TODO: better method of calculating heuristic
		local ga, gb
		local ha, hb

		ga = a[2]
		if a[1] > 0 then
			ha = (c_tcm_current_map.wayPoints[a[1]].p - goalPos).R
		else
			ha = (c_tcm_current_map.teleporters[c_tcm_current_map.teleporters[-a[1]].t].p - goalPos).R
		end

		gb = b[2]
		if b[1] > 0 then
			hb = (c_tcm_current_map.wayPoints[b[1]].p - goalPos).R
		else
			hb = (c_tcm_current_map.teleporters[c_tcm_current_map.teleporters[-b[1]].t].p - goalPos).R
		end

		return ga + ha < gb + gb
	end

	local function isClosed(n)
		for _, v in pairs(closed) do
			if v == n then
				return true
			end
		end

		return false
	end

	local function isGoal(ns)
		for _, v in pairs(ns) do
			if v == goal then
				return true
			end
		end

		return false
	end

	local nodes
	local n = {start, 0}
	while n ~= goal do
		nodes = net[n[1]]
		table.sort(nodes, orderByWeight)

		table.insert(path, n[1])

		n = nodes[1]

		if not n or isClosed(n[1]) then
			break
		end

		table.insert(closed, n[1])
	end

	if n ~= goal then
		return nil
	end

	table.insert(path, n)  -- insert goal node

	return path
end

local p1, p2 = tankbobs.m_vec2(), tankbobs.m_vec2()
function c_ai_followObjective(tank, objective)
	if not objective then
		tank.ai.followingObjective = false

		return
	end

	p1.R = 2.1
	p1.t = tank.r
	p1:add(tank.p)

	p2(objective.objective)

	local s, _, t, _ = c_world_findClosestIntersection(p1, p2)
	local inSight = not s or t ~= "wall"

	p1(tank.p)

	if objective.followType >= INSIGHT and inSight then
		-- the objective is in sight, so chase it

		local vel = tankbobs.w_getLinearVelocity(tank.body)

		local minSpeed = c_world_getInstagib() and c_const_get("ai_minObjectiveSpeedInstagib") or c_const_get("ai_minObjectiveSpeed")
		if vel.R < minSpeed then
			c_ai_setTankStateForward(tank, 1)
			c_ai_setTankStateSpecial(tank, false)
		else
			c_ai_setTankStateForward(tank, 0)
			c_ai_setTankStateSpecial(tank, true)
		end

		local angle = (p2 - p1).t + ((1 - c_ai_relativeTankSkill(tank)) * (math.random(-c_const_get("ai_followRandom") * 1000, c_const_get("ai_followRandom") * 1000) / 1000))
		tank.r, angle = c_ai_angleRange(tank.r, angle)
		c_ai_setTankStateRotation(tank, tank.r - angle)

		tank.ai.followingObjective = true

		if objective.followType >= ALWAYSANDDESTROY then
			-- shoot at tanks near objective
			local enemy, angle, pos, time = c_ai_closestEnemyInSite(tank, function (x) return (x.p - objective.objective).R <= c_const_get("ai_objectiveDistance") end)
			if enemy then
				c_ai_shootEnemies(tank, enemy, angle, pos, time)
			end
		end
	elseif objective.followType >= ALWAYS then
		if not objective.path or not objective.path[objective.nextNode] or not objective.nextPathUpdateTime or tankbobs.t_getTicks() >= objective.nextPathUpdateTime then
			if tank.static then
				objective.nextPathUpdateTime = tankbobs.t_getTicks() + c_const_get("world_time") * c_config_get("game.timescale") * c_const_get("ai_staticPathUpdateTime")
			else
				objective.nextPathUpdateTime = tankbobs.t_getTicks() + c_const_get("world_time") * c_config_get("game.timescale") * c_const_get("ai_pathUpdateTime")
			end

			local start = c_ai_findClosestWayPoint(tank.p)
			local goal = c_ai_findClosestWayPoint(objective.objective)
			if start then
				start = start[1]
			end
			if goal then
				goal = goal[1]
			end
			objective.path = c_ai_findClosestPath(start, goal)

			objective.nextNode = 1
		end

		if objective.path and objective.path[objective.nextNode] then
			-- go to the next node
			local vel = tankbobs.w_getLinearVelocity(tank.body)

			local n = objective.path[objective.nextNode]

			if n > 0 then
				p2(c_tcm_current_map.wayPoints[n].p)
			else
				p2(c_tcm_current_map.teleporters[-n].p)
			end

			local minSpeed = c_world_getInstagib() and c_const_get("ai_minObjectiveSpeedInstagib") or c_const_get("ai_minObjectiveSpeed")
			if vel.R < minSpeed then
				c_ai_setTankStateForward(tank, 1)
				c_ai_setTankStateSpecial(tank, false)
			else
				c_ai_setTankStateForward(tank, 0)
				c_ai_setTankStateSpecial(tank, true)
			end

			local angle = (p2 - p1).t + ((1 - c_ai_relativeTankSkill(tank)) * (math.random(-c_const_get("ai_followRandom") * 1000, c_const_get("ai_followRandom") * 1000) / 1000))
			tank.r, angle = c_ai_angleRange(tank.r, angle)
			c_ai_setTankStateRotation(tank, tank.r - angle)

			if (p2 - p1).R <= c_const_get("ai_nextNodeDistance") then
				objective.nextNode = objective.nextNode + 1
			end

			objective.followingObjective = true
		end
	elseif objective.followType <= AVOIDINSIGHT and inSight then
		-- go away from objective

		-- TODO
		--tank.ai.followingObjective = true
	elseif objective.followType <= AVOID then
		-- ignore until in sight

		tank.ai.followingObjective = false
	end
end

function c_ai_followObjectives(tank)
	for _, v in ipairs(tank.ai.objectives) do
		c_ai_followObjective(tank, v)
	end
end

function c_ai_resetObjectivePathTimer(tank, index)
	index = index or GENERICINDEX

	if tank.ai.objectives[index] then
		tank.ai.objectives[index].nextPathUpdateTime = tankbobs.t_getTicks()
	end
end

local p1, p2 = tankbobs.m_vec2(), tankbobs.m_vec2()
function c_ai_cruise(tank)
	local vel = tankbobs.w_getLinearVelocity(tank.body)

	if tank.ai.turning and not tank.ai.close then
		local minSpecialSpeed = c_world_getInstagib() and c_const_get("ai_minSpecialSpeedInstagib") or c_const_get("ai_minSpecialSpeed")
		if vel.R >= minSpecialSpeed then
			c_ai_setTankStateSpecial(tank, true)
		end
		c_ai_setTankStateRotation(tank, tank.ai.turning)

		-- check for no walls
		p1.R = 2.1
		p1.t = tank.r
		p1:add(tank.p)

		p2.R = c_const_get("ai_closeWallBig")
		p2.t = tank.r
		p2:add(p1)

		local s, _, t, _ = c_world_findClosestIntersection(p1, p2)
		if not s or t ~= "wall" then
			tank.ai.turning = nil
		end

		-- check for very close walls
		p2.R = c_const_get("ai_closeWallVerySmall")
		--p2.t = tank.r  -- already set
		p2:add(p1)

		local s, _, t, _ = c_world_findClosestIntersection(p1, p2)
		if s and t == "wall" then
			tank.ai.close = true
		end

		if vel.R < c_const_get("ai_coastMinSpeed") then
			tank.ai.close = true
		end
	elseif not tank.ai.close then
		c_ai_setTankStateSpecial(tank, false)
		c_ai_setTankStateForward(tank, 1)

		-- check for walls
		p1.R = 2.1
		p1.t = tank.r
		p1:add(tank.p)

		p2.R = c_const_get("ai_closeWallSmall")
		p2.t = tank.r
		p2:add(p1)

		local s, _, t, _ = c_world_findClosestIntersection(p1, p2)
		if s and t == "wall" then
			if math.random(1, 2) == 1 then
				tank.ai.turning = 1
			else
				tank.ai.turning = -1
			end
		end
	else
		c_ai_setTankStateForward(tank, -1)
		c_ai_setTankStateSpecial(tank, false)

		if vel.R <= c_const_get("ai_stopCloseSpeed") then
			tank.ai.close = false
		end
	end
end

local p1, p2 = tankbobs.m_vec2(), tankbobs.m_vec2()
function c_ai_tank_step(tank)
	local t = tankbobs.t_getTicks()

	if not tank.exists then
		return
	end

	if not tank.bot then
		return
	end

	-- skip if thinking during same frame
	if t < tank.ai.nextStepTime then
		return
	end
	tank.ai.nextStepTime = t + common_FTM(c_const_get("ai_fps")) + (1 - c_ai_relativeTankSkill(tank)) * common_FTM(c_const_get("ai_fpsRelativeToSkill"))

	local vel = tankbobs.w_getLinearVelocity(tank.body)

	if c_world_gameType == DEATHMATCH then
		-- shoot any nearby enemies
		local enemy, angle, pos, time = c_ai_closestEnemyInSite(tank)
		if enemy then
			c_ai_shootEnemies(tank, enemy, angle, pos, time)
		else
			if tank.ai.shootingEnemies then
				tank.ai.shootingEnemies = false

				-- tank has stopped shooting enemies
				c_ai_setTankStateFire(tank, 0)
				c_ai_setTankStateRotation(tank, 0)
				c_ai_setTankStateForward(tank, 0)
				tank.ai.turning = nil
			end

			c_ai_cruise(tank)
		end

		c_ai_followObjectives(tank)  -- bots will follow powerups even when an enemy is in sight
	elseif c_world_gameType == DOMINATION then
		local function closeToControlPoint(tank)
			if not tank.ai.followingObjective then
				return true
			end

			for _, v in pairs(c_tcm_current_map.controlPoints) do
				if (v.p - tank.p).R <= c_const_get("ai_enemyControlPointRange") then
					return true
				end
			end

			return false
		end

		local enemy, angle, pos, time = c_ai_closestEnemyInSite(tank)
		if enemy then
			c_ai_shootEnemies(tank, enemy, angle, pos, time)
		else
			if tank.ai.shootingEnemies then
				tank.ai.shootingEnemies = false

				-- tank has stopped shooting enemies
				c_ai_setTankStateFire(tank, 0)
				c_ai_setTankStateRotation(tank, 0)
				c_ai_setTankStateForward(tank, 0)
				tank.ai.turning = nil
			end

			if not tank.ai.followingObjective then
				c_ai_cruise(tank)
			end

			c_ai_followObjectives(tank)  -- bots will follow powerups even when an enemy is in sight
		end

		-- look for closest control point
		if not tank.ai.cc or (tank.ai.cc.m.team == "red") == (tank.red == true) or not tank.ai.cc.m.team then
			local smallestDistance
			for _, v in pairs(c_tcm_current_map.controlPoints) do
				if (v.m.team == "red") ~= (tank.red == true) or not v.m.team then
					local distance = (v.p - tank.p).R
					if not smallestDistance or distance < smallestDistance then
						smallestDistance = distance
						tank.ai.cc = v
					end
				end
			end

			if not smallestDistance then
				tank.ai.cc = nil
			else
				c_ai_resetObjectivePathTimer(tank, GENERICINDEX)
			end
		end

		if tank.ai.cc then
			c_ai_setObjective(tank, GENERICINDEX, tank.ai.cc.p, ALWAYSANDDESTROY, "controlPoint", true)  -- ALWAYSANDDESTROY to shoot nearby tanks (tanks on the same team don't destroy each other)
		end
	end

	-- look for powerups
	local c = c_ai_findClosestPowerup(tank)
	if c then
		c_ai_setObjective(tank, POWERUPINDEX, c.p, INSIGHT, "powerup")
	else
		c_ai_setObjective(tank, POWERUPINDEX, nil)
	end

	local maxSpeed = c_world_getInstagib() and c_const_get("ai_maxSpeedInstagib") or c_const_get("ai_maxSpeed")
	if vel.R > maxSpeed and not tank.ai.followingObjective then
		c_ai_setTankStateSpecial(tank, false)
		c_ai_setTankStateForward(tank, -1)
	end
end
