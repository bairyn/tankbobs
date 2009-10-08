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
	c_const_set("ai_fpsRelativeToSkill", 175)

	c_const_set("ai_minSkill", 1)  -- most difficult to fight against
	c_const_set("ai_maxSkill", 16)  -- least difficult to fight against
	c_const_set("ai_maxSkillInstagib", 8)

	c_const_set("ai_botRange", 200)
	c_const_set("ai_botAccuracy", 0.08)  -- accuracy of most skilled bot; lower is better (can be up to x secs off)
	c_const_set("ai_shootAngle", (math.pi * 2) / 64)  -- (Tankbobs uses radians)
	c_const_set("ai_maxSpeed", 1)  -- brake if above this speed, even if attacking
	c_const_set("ai_maxSpeedInstagib", 4)  -- brake if above this speed, even if attacking
	c_const_set("ai_maxSpecialSpeed", 2)
	c_const_set("ai_minObjectiveSpeed", 0.9)
	c_const_set("ai_minObjectiveSpeedInstagib", 3)
	c_const_set("ai_accelerateByEnemyFrequency", 32)  -- lower is more
	c_const_set("ai_skipUpdateRandomReduce", 0.5)
	c_const_set("ai_skipUpdateRandom", 1.35)
	c_const_set("ai_chaseEnemyChance", 6)  -- lower is more likely (chance of 1 / x)
	c_const_set("ai_chaseEnemyChanceInstagib", 2)
	c_const_set("ai_noFireSpawnTime", -1)
	c_const_set("ai_noFireSpawnTimeInstagib", 0.8)

	c_const_set("ai_followRandom", (math.pi * 2) / 8)  -- +- x radians when least skilled bot is following an objective
	c_const_set("ai_stopCloseSpeed", 0.1)
	c_const_set("ai_coastMinSpeed", 0.5)
	c_const_set("ai_reverseChance", 3)
	c_const_set("ai_closeWallVerySmall", 5)
	c_const_set("ai_closeWallSmall", 25)
	c_const_set("ai_closeWallBig", 50)
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
local AVOID        = 0
local AVOIDINSIGHT = 0
local INSIGHT      = 2
local ALWAYS       = 3

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
			if tank.red then
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
	return common_lerp(c_const_get("ai_maxSkill"), c_const_get("ai_minSkill"), tank.ai.skill)
end

local p1, p2, tmp = tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()
function c_ai_closestEnemyInSite(tank)
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
		if v.exists and tank ~= v then
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

function c_ai_setObjective(tank, pos, followType, objectiveType)
	tank.ai.objective = pos
	tank.ai.followType = followType or tank.ai.followType or INSIGHT
	tank.ai.objectiveType = objectiveType
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
		if math.random(1, c_const_get("ai_accelerateByEnemyFrequency") * tank.ai.skill) == 1 then
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
	local noFireTime = c_world_getInstagib() and c_const_get("ai_noFireSpawnTimeInstagib") or c_config_get("ai_noFireSpawnTime")
	tank.ai.noFireTime = tankbobs.t_getTicks() + c_config_get("game.timescale") * c_const_get("world_time") * noFireTime
end

function c_ai_tankDie(tank)
	tank.ai.turning = nil
	tank.ai.close = false
end

local p1, p2 = tankbobs.m_vec2(), tankbobs.m_vec2()
function c_ai_followObective(tank)
	if not tank.ai.objective then
		return
	end

	p1.R = 2.1
	p1.t = tank.r
	p1:add(tank.p)

	p2(tank.ai.objective)

	local s, _, t, _ = c_world_findClosestIntersection(p1, p2)
	local inSight = not s or t ~= "wall"
	if tank.ai.followType >= INSIGHT and inSight then
		local vel = tankbobs.w_getLinearVelocity(tank.body)

		-- the objective is in sight, so chase it

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
	elseif tank.ai.followType >= ALWAYS then
		-- look for shortest path to objective using the A* algorithm and waypoints

		-- TODO
	elseif tank.ai.followType <= AVOIDINSIGHT and inSight then
		-- go away from objective

		-- TODO
	elseif tank.ai.followType <= AVOID then
		-- ignore until in sight
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

			if tank.ai.turning and not tank.ai.close then
				if vel.R <= c_const_get("ai_maxSpecialSpeed") then
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

		c_ai_followObective(tank)  -- bots will follow powerups even when an enemy is in sight

		-- in deathmatch, only powerups can be objectives,
		-- so if there aren't any, reset objective
		if not c_ai_findClosestPowerup(tank) then
			c_ai_setObjective(tank, nil)
		end
	end

	-- look for powerups
	local c = c_ai_findClosestPowerup(tank)
	if c then
		c_ai_setObjective(tank, c.p, INSIGHT, "powerup")
	end

	local maxSpeed = c_world_getInstagib() and c_const_get("ai_maxSpeedInstagib") or c_const_get("ai_maxSpeed")
	if vel.R > maxSpeed then
		c_ai_setTankStateForward(-1)
	end
end
