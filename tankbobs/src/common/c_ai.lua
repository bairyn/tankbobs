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
	c_const_set("ai_fps", 175)
	c_const_set("ai_fpsRelativeToSkill", 100)

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
	c_const_set("ai_minWayPointSpeed", 12)
	c_const_set("ai_minWayPointSpeedInstagib", 16)
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
	c_const_set("ai_recentAttackExpireTime", 4)
	c_const_set("ai_minAmmo", 0.4)
	c_const_set("ai_shotgunReloadMinHealth", 20)  -- don't keep reloading shotgun near enemies with a shotgun if health is below this
	c_const_set("ai_reloadEmptyWeaponFrequency", 24)  -- lower is more likely; chance of 1 / x for bots with skill level of 1
	c_const_set("ai_shotgunMinAmmo", 2)
	c_const_set("ai_enemySightedTime", 3)
	c_const_set("ai_meleeFireRange", 5.5)
	c_const_set("ai_meleeRangeSkill", 0.5)
	c_const_set("ai_enemyMeleeFireRange", 16)
	c_const_set("ai_enemyMeleeRangeSkill", -0.6)
	c_const_set("ai_meleeChaseTargetMinDistance", 5)
	c_const_set("ai_meleeChaseTargetMinSpecialSpeed", 32)
	c_const_set("ai_meleeChaseTargetMinSpecialSpeedInstagib", 44)
	c_const_set("ai_minHealth", 20)
	c_const_set("ai_minHealthInstagib", -1)
	c_const_set("ai_taggedAvoidMaxDistance", 50)
	c_const_set("ai_captureFlagMinHealth", 25)
	c_const_set("ai_flagRange", 50)

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
, "Ms. Durant"
, "Dude"
, "Shooter"
, "Aimer"
, "Robert'); DROP TABLE Students;--"
, "Ken Knot"
, "Tom Morrow"
, "Bob Wire"
, "Bobby Pin"
, "Brock Lee"
, "Will Wynn"
, "Summer Holiday"
, "Summer Beach"
, "Virginian Beach"
, "Dr. C. Good"
, "Candace Spencer"
, "Krabby Krap"
, "Jim Trainer"
, "Jim Socks"
, "Joe King"
}

-- follow type
local AVOID            = 0
local AVOIDINSIGHT     = 1
local NOTINSIGHT       = 2
local INSIGHT          = 3
local ALWAYS           = 4
local ALWAYSANDDESTROY = 5  -- shoot at nearby tanks (within ai_objectiveDistance units)

-- objective indexes (objective with lower index will likely override other objectives)
local ENEMYINDEX           = 5
local GENERICINDEX         = 4
local POWERUPINDEX         = 3
local AVOIDENEMYINDEX      = 2
local AVOIDENEMYMEELEINDEX = 1

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

		for _, v in pairs(c_world_getTanks()) do
			if v ~= tank then
				if v.red then
					balance = balance + 1
				else
					balance = balance - 1
				end
			end
		end

		if balance > 0 then 
			tank.red = false
		elseif balance < 0 then
			tank.red = true
		else
			if math.random(1, 2) == 1 then
				tank.red = true
			else
				tank.red = false
			end
		end
	end

	if ai then
		tankbobs.t_clone(ai, tank.ai)
	end

	-- nothing below should be able to be overwritten

	tank.ai.nextStepTime = tankbobs.t_getTicks()

	tank.ai.objectives = {}

	tank.ai.lastEnemySightedTime = tankbobs.t_getTicks() - c_const_get("ai_enemySightedTime") - 1

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

function c_ai_setTankStateFire(tank, fire)  -- 0 or false: no fire
	if fire and fire ~= 0 then
		tank.state = bit.bor(tank.state, FIRING)
	else
		tank.state = bit.band(tank.state, bit.bnot(FIRING))
	end
end

function c_ai_setTankStateSpecial(tank, special)  -- 0 or false: no special
	if special and special ~= 0 then
		tank.state = bit.bor(tank.state, SPECIAL)
	else
		tank.state = bit.band(tank.state, bit.bnot(SPECIAL))
	end
end

function c_ai_setTankStateReload(tank, reload)  -- 0 or false: no reload
	if reload and reload ~= 0 then
		tank.state = bit.bor(tank.state, RELOAD)
	else
		tank.state = bit.band(tank.state, bit.bnot(RELOAD))
	end
end

function c_ai_getTankStateReload(tank)
	if bit.band(tank.state, RELOAD) then
		return true, 1
	else
		return false, 0
	end
end

function c_ai_relativeTankSkill(tank)
	local s, m, l = c_const_get("ai_minSkill"), tank.ai.skill, c_const_get("ai_maxSkill")
	return (m - s) / (l - s)
end

function c_ai_findClosestEnemy(tank, filter)
	local enemies = {}

	for _, v in pairs(c_world_getTanks()) do
		if v.exists and tank ~= v and (not c_world_isTeamGameType() or tank.red ~= v.red) and (not filter or filter(v)) then
			table.insert(enemies, {v, (v.p - tank.p).R})
		end
	end

	table.sort(enemies, function (a, b) return a[2] < b[2] end)

	if enemies[1] then
		return enemies[1][1]
	else
		return nil
	end
end

local p1, p2, tmp = tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()
function c_ai_findClosestEnemyInSight(tank, filter)
	-- returns the closest tank that can be shot at, the angle at which the tank will need to be so that a bullet will shoot the enemy, the position of the future collision, and the time it takes for the projectile to reach the collision point, if its velocity is constant
	local tanks = {}
	local range = c_const_get("ai_botRange")
	local accuracy = 2 * c_const_get("ai_botAccuracy") * tank.ai.skill
	local dir = 0
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
			local time = 0
			local vel = tankbobs.w_getLinearVelocity(v.body)
			if weapon.meleeRange == 0 then
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
				time = (low + high) / 2
			else
				dir = (v.p - p1).t
			end

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

	tank.ai.objectives[index].p = tankbobs.m_vec2(pos)
	tank.ai.objectives[index].followType = followType or tank.ai.followType or INSIGHT
	tank.ai.objectives[index].objectiveType = objectiveType
	tank.ai.objectives[index].static = static
end

function c_ai_findClosestPowerup(tank)
	local powerups = tankbobs.t_clone(c_world_getPowerups())
	table.sort(powerups, function (a, b) if a and b then return (a.p - tank.p).R < (b.p - tank.p).R elseif a then return true else return false end end)
	return powerups[1]
end

function c_ai_isWeapon(tank, weaponString)
	local weapon = c_weapon_getByName(weaponString)
	if not weapon then
		weapon = c_weapon_getByAltName(weaponString)
	end

	if not weapon then
		return false
	end

	return tank.weapon == weapon.index
end

function c_ai_isMeleeWeapon(tank)
	-- this should work on all tanks

	if c_ai_isWeapon(tank, "saw") then
		return true
	end

	return false
end

function c_ai_tankWeaponStep(tank, enemyInSight)
	local t = tankbobs.t_getTicks()

	local weapon = c_weapon_getWeapons()[tank.weapon]

	if not enemyInSight and t > tank.ai.lastEnemySightedTime + c_const_get("ai_enemySightedTime") then
		if weapon.capacity > 0 and tank.clips > 0 and tank.ammo / weapon.capacity < c_const_get("ai_minAmmo") then
			c_ai_setTankStateReload(tank, 1)
		else
			c_ai_setTankStateReload(tank, 0)
		end

		if c_ai_isWeapon(tank, "shotgun") then
			c_ai_setTankStateReload(tank, 1)
		end
	else
		c_ai_setTankStateReload(tank, 0)

		if c_ai_isWeapon(tank, "shotgun") and c_ai_getTankStateReload(tank) then
			if tank.ammo < c_const_get("ai_shotgunMinAmmo") and tank.health >= c_const_get("ai_shotgunReloadMinHealth") then
				c_ai_setTankStateReload(tank, 1)
			end
		end
	end

	if tank.clips > 0 and tank.ammo <= 0 and math.random(1, tank.ai.skill * c_const_get("ai_reloadEmptyWeaponFrequency")) == 1 then
		c_ai_setTankStateReload(tank, 1)
	end
end

function c_ai_shootEnemies(tank, enemy, angle, pos, time)
	tank.ai.lastEnemySightedTime = tankbobs.t_getTicks()

	if not tank.ai.shootingEnemies then
		-- start shooting enemies
		c_ai_setTankStateSpecial(tank, false)

		local chaseEnemyChance = c_world_getInstagib() and c_const_get("ai_chaseEnemyChanceInstagib") or c_const_get("ai_chaseEnemyChance")
		if math.random(1, chaseEnemyChance) == 1 then
			c_ai_setTankStateForward(tank, 1)
		else
			c_ai_setTankStateForward(tank, 0)
		end

		if c_ai_isMeleeWeapon(tank) then
			c_ai_setTankStateForward(tank, 1)
		elseif c_ai_isWeapon(tank, "shotgun") then
			local chaseEnemyChance = c_world_getInstagib() and c_const_get("ai_chaseEnemyChanceInstagib") or c_const_get("ai_chaseEnemyChance")
			if math.random(1, chaseEnemyChance) ~= 1 then
				c_ai_setTankStateForward(tank, 1)
			else
				c_ai_setTankStateForward(tank, 0)
			end
		end
	end

	tank.ai.shootingEnemies = true

	tank.r, angle = c_ai_angleRange(tank.r, angle)

	if math.random(1000 * c_ai_relativeTankSkill(tank), 1000 * (1 + c_const_get("ai_skipUpdateRandomReduce"))) / 1000 < c_const_get("ai_skipUpdateRandom") then
		c_ai_setTankStateRotation(tank, tank.r - angle)
		if c_ai_isMeleeWeapon(tank) then
			if (enemy.p - tank.p).R < c_const_get("ai_meleeFireRange") + tank.ai.skill * c_const_get("ai_meleeRangeSkill") then
				c_ai_setTankStateFire(tank, 1)
			else
				c_ai_setTankStateFire(tank, 0)
			end
		else
			if tankbobs.t_getTicks() > tank.ai.noFireTime then
				c_ai_setTankStateFire(tank, math.abs(angle - tank.r) <= tank.ai.skill * c_const_get("ai_shootAngle"))
			else
				c_ai_setTankStateFire(tank, false)
			end
		end
	end

	-- randomly accelerate or reverse
	if c_ai_isMeleeWeapon(tank) then
		if (enemy.p - tank.p).R >= c_const_get("ai_meleeChaseTargetMinDistance") then
			tank.ai.chasingWithMeleeWeapon = true

			c_ai_setTankStateForward(tank, 1)

			local vel = tankbobs.w_getLinearVelocity(tank.body)
			local minSpeed = c_world_getInstagib() and c_const_get("ai_meleeChaseTargetMinSpecialSpeedInstagib") or c_const_get("ai_meleeChaseTargetMinSpecialSpeed")
			if vel.R < minSpeed then
				c_ai_setTankStateSpecial(tank, 0)
			else
				c_ai_setTankStateSpecial(tank, 1)
			end
		else
			c_ai_setTankStateForward(tank, 0)
			c_ai_setTankStateSpecial(tank, 0)
		end
	else
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
	if not tank.bot then
		return
	end

	local noFireTime = c_world_getInstagib() and c_const_get("ai_noFireSpawnTimeInstagib") or c_const_get("ai_noFireSpawnTime")
	tank.ai.noFireTime = tankbobs.t_getTicks() + c_world_timeMultiplier(noFireTime)
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

	for ks, vs in pairs(c_tcm_current_map.teleporters) do
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
			table.insert(w, {-ks, weight})
		end
	end

	table.sort(w, function (a, b) local pa if a[1] > 0 then pa = c_tcm_current_map.wayPoints[a[1]].p - pos else pa = c_tcm_current_map.teleporters[-a[1]].p end local pb if b[1] > 0 then pb = c_tcm_current_map.wayPoints[b[1]].p - pos else pb = c_tcm_current_map.teleporters[-b[1]].p end return (pa - pos).R < (pb - pos).R end)

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
		if not a then
			return false
		elseif not b then
			return true
		end

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

		return ga + ha < gb + hb
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
	while n[1] ~= goal do
		nodes = net[n[1]]
		table.sort(nodes, orderByWeight)

		table.insert(path, n[1])

		n = nodes[1]

		if not n or isClosed(n[1]) then
			break
		end

		table.insert(closed, n[1])
	end

	if not n or n[1] ~= goal then
		return nil
	end

	table.insert(path, n[1])  -- insert goal node

	return path
end

function c_ai_isFollowingObjective(tank, objectiveIndex)
	return tank.ai.objectives[objectiveIndex] and tank.ai.objectives[objectiveIndex].following
end

local p1, p2 = tankbobs.m_vec2(), tankbobs.m_vec2()
function c_ai_followObjective(tank, objective)
	if not objective or not objective.p then
		return
	end

	p2(objective.p)
	p2:sub(tank.p)

	p1.R = 3
	p1.t = p2.t
	p1:add(tank.p)

	p2(objective.p)

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

		objective.following = true

		tank.ai.followingObjective = true

		if objective.followType >= ALWAYSANDDESTROY then
			-- shoot at tanks near objective
			local enemy, angle, pos, time = c_ai_findClosestEnemyInSight(tank, function (x) return (x.p - objective.p).R <= c_const_get("ai_objectiveDistance") end)
			if enemy then
				c_ai_shootEnemies(tank, enemy, angle, pos, time)
			end
		end
	elseif objective.followType >= ALWAYS or objective.followType == NOTINSIGHT then
		if objective.followType == NOTINSIGHT and inSight then
			return
		end

		if not objective.path or not objective.path[objective.nextNode] or not objective.nextPathUpdateTime or tankbobs.t_getTicks() >= objective.nextPathUpdateTime then
			if objective.static then
				objective.nextPathUpdateTime = tankbobs.t_getTicks() + c_world_timeMultiplier(c_const_get("ai_staticPathUpdateTime"))
			else
				objective.nextPathUpdateTime = tankbobs.t_getTicks() + c_world_timeMultiplier(c_const_get("ai_pathUpdateTime"))
			end

			local start = c_ai_findClosestWayPoint(tank.p)
			local goal = c_ai_findClosestWayPoint(objective.p)
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

			local minSpeed = c_world_getInstagib() and c_const_get("ai_minWayPointSpeedInstagib") or c_const_get("ai_minWayPointSpeed")
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

			objective.following = true

			objective.followingObjective = true
		else
			-- special case for control points
			if objective.objectiveType == "controlPoint" then
				tank.ai.cc = nil
			end
		end
	elseif objective.followType <= AVOIDINSIGHT and inSight then
		-- go away from objective
		if not objective.path or not objective.path[objective.nextNode] or not objective.nextPathUpdateTime or tankbobs.t_getTicks() >= objective.nextPathUpdateTime then
			if objective.static then
				objective.nextPathUpdateTime = tankbobs.t_getTicks() + c_world_timeMultiplier(c_const_get("ai_staticPathUpdateTime"))
			else
				objective.nextPathUpdateTime = tankbobs.t_getTicks() + c_world_timeMultiplier(c_const_get("ai_pathUpdateTime"))
			end

			local start = c_ai_findClosestWayPoint(tank.p)
			if start then
				start = start[1]
			end

			-- first look for closest way point in opposite direction of enemy
			local goal

			p2(tank.p)
			p2:add(1 * (p2 - objective.p))

			goal = c_ai_findClosestWayPoint(p2)

			if not goal then
				-- look for a way point not visible by target
				for _, v in pairs(c_tcm_current_map.wayPoints) do
					p2(v.p)

					local s, _, t, _ = c_world_findClosestIntersection(p1, p2)
					if not s--[[ or t ~= "wall"--]] then
						goal = c_ai_findClosestWayPoint(p2)

						break
					end
				end
			end

			if goal then
				goal = goal[1]
			else
				-- go to a random node

				if math.random(1, 3) == 1 then
					-- teleporter
					if #c_tcm_current_map.teleporters >= 1 then
						goal = -math.random(1, #c_tcm_current_map.teleporters)
					end
				else
					-- way point
					if #c_tcm_current_map.wayPoints >= 1 then
						goal = math.random(1, #c_tcm_current_map.wayPoints)
					end
				end
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

			local minSpeed = c_world_getInstagib() and c_const_get("ai_minWayPointSpeedInstagib") or c_const_get("ai_minWayPointSpeed")
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

			objective.following = true

			objective.followingObjective = true
		end

		tank.ai.followingObjective = true
	elseif objective.followType <= AVOID then
		-- ignore until in sight
	end
end

function c_ai_followObjectives(tank, closest)
	tank.ai.followingObjective = false
	for _, v in pairs(tank.ai.objectives) do
		v.following = false
	end

	if closest then
		local t = {}

		for _, v in pairs(tank.ai.objectives) do
			table.insert(t, {v, (v.p - tank.p).R})
		end

		table.sort(t, function (a, b) return a[2] < b[2] end)

		for _, v in ipairs(t) do
			c_ai_followObjective(tank, v[1])
			if tank.ai.followingObjective then
				break
			end
		end
	else
		for _, v in ipairs(tank.ai.objectives) do
			c_ai_followObjective(tank, v)
			if tank.ai.followingObjective then
				break
			end
		end
	end
end

function c_ai_resetObjectivePathTimer(tank, index)
	index = index or GENERICINDEX

	if tank.ai.objectives[index] then
		tank.ai.objectives[index].nextPathUpdateTime = tankbobs.t_getTicks()
	end
end

function c_ai_hasRecentlyAttacked(tank, attacker)
	-- this should work for human-controlled tanks too

	local t = tankbobs.t_getTicks()

	if not tank.lastAttackers then
		tank.lastAttackers = {}
	end

	local reset = #tank.lastAttackers > 0
	for _, v in pairs(tank.lastAttackers) do
		if t < v[2] then
			reset = false
		end
	end

	if reset then
		tank.lastAttackers = {}
	end

	for _, v in pairs(tank.lastAttackers) do
		if v[1] == attacker and t < v[2] then
			return true
		end
	end

	return false
end

function c_ai_findTaggedTank()
	for _, v in pairs(c_world_getTanks()) do
		if v.exists then
			if v.tagged then
				return v
			end
		end
	end

	return nil
end

function c_ai_tankAttacked(tank, attacker, damage)
	-- this should work for human players too

	if not tank.lastAttackers then
		tank.lastAttackers = {}
	end

	table.insert(tank.lastAttackers, {attacker, tankbobs.t_getTicks() + c_world_timeMultiplier(c_const_get("ai_recentAttackExpireTime"))})
end

function c_ai_beginningOfChaseGame()
	if c_world_getGameType() ~= CHASE then
		return false
	end

	for _, v in pairs(c_world_getTanks()) do
		if v.tagged then
			return false
		end
	end

	return true
end

local p1, p2 = tankbobs.m_vec2(), tankbobs.m_vec2()
function c_ai_avoidIfAlmostDead(tank)
	if not tank.bot then
		return
	end

	if c_ai_isMeleeWeapon(tank) then
		c_ai_setObjective(tank, AVOIDENEMYINDEX, nil)

		return
	end

	local minHealth = c_world_getInstagib() and c_const_get("ai_minHealthInstagib") or c_const_get("ai_minHealth")
	if tank.health < minHealth then
		local s, _, p, _= c_ai_findClosestEnemyInSight(tank)
		if s then
			p:sub(0.05 * (p - tank.p))  -- make objective slightly closer to tank so that the closest objective will be avoided properly
			c_ai_setObjective(tank, AVOIDENEMYINDEX, p, ALWAYSANDDESTROY, "avoid enemy", false)
		else
			c_ai_setObjective(tank, AVOIDENEMYINDEX, nil)
		end
	else
		c_ai_setObjective(tank, AVOIDENEMYINDEX, nil)
	end
end

function c_ai_avoidMeleeEnemies(tank, filter)
	-- avoid enemies that have close range weapons in close range
	if not tank.bot then
		return
	end

	if c_ai_isMeleeWeapon(tank) then
		c_ai_setObjective(tank, AVOIDENEMYMEELEINDEX, nil)

		return
	end

	local range = c_const_get("ai_enemyMeleeFireRange") + tank.ai.skill * c_const_get("ai_enemyMeleeRangeSkill")

	local t = {}
	for _, v in pairs(c_world_getTanks()) do
		if v.exists and tank ~= v and (not c_world_isTeamGameType() or tank.red ~= v.red) and (not filter or filter(v)) then
			if c_ai_isMeleeWeapon(v) then
				local distance = (v.p - tank.p).R

				if distance <= range then
					table.insert(t, {v, distance})
				end
			end
		end
	end

	table.sort(t, function (a, b) return a[2] < b[2] end)

	if t[1] then
		local p = tankbobs.m_vec2(t[1].p)
		p:sub(0.05 * (p - tank.p))  -- make objective slightly closer to tank so that the closest objective will be avoided properly
		c_ai_setObjective(tank, AVOIDENEMYMEELEINDEX, t[1].p, AVOIDINSIGHT, "avoid enemy melee", false)  -- avoid enemies with mêlée weapons
	else
		c_ai_setObjective(tank, AVOIDENEMYMEELEINDEX, nil)
	end
end

function c_ai_avoid(tank)
	if not tank.bot then
		return
	end

	c_ai_avoidMeleeEnemies(tank)
	c_ai_avoidIfAlmostDead(tank)
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
		if not s--[[ or t ~= "wall"--]] then
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

function c_ai_tankRecentlyAttackedYourFlagCarrier(tank, enemy)
	if c_world_getGameType() ~= CAPTURETHEFLAG then
		return false
	end

	for _, v in pairs(c_tcm_current_map.flags) do
		if v.red ~= tank.red then
			if not v.m.stolen then
				return false
			end

			local friend = c_world_getTanks()[v.m.stolen]

			return c_ai_hasRecentlyAttacked(v, enemy)
		end
	end

	return false
end

function c_ai_tankHasYourFlag(tank, enemy)
	for _, v in pairs(c_tcm_current_map.flags) do
		if v.red == tank.red then
			if v.m.stolen and c_world_getTanks()[v.m.stolen] == enemy then
				return true
			end
		end
	end

	return false
end

function c_ai_yourTeamOffensive(tank)
	-- returns true when your flag is safe and the enemy flag is stolen (and neither is dropped)
	for _, v in pairs(c_tcm_current_map.flags) do
		if v.red == tank.red then
			if v.m.stolen or v.m.dropped then
				return false
			end
		elseif v.red ~= tank.red then
			if not v.m.stolen or v.m.dropped then
				return false
			end
		end
	end

	return true
end

local p1, p2 = tankbobs.m_vec2(), tankbobs.m_vec2()
function c_ai_tank_step(tank)
	local t = tankbobs.t_getTicks()

	if c_world_isBehind() then
		c_world_resetBehind()

		return
	end

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

	tank.ai.chasingWithMeleeWeapon = false

	if c_world_getGameType() == DEATHMATCH then
		-- shoot any nearby enemies
		local enemy, angle, pos, time = c_ai_findClosestEnemyInSight(tank)
		if enemy and not c_ai_isFollowingObjective(tank, POWERUPINDEX) then
			c_ai_shootEnemies(tank, enemy, angle, pos, time)

			c_ai_tankWeaponStep(tank, true)
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

			c_ai_tankWeaponStep(tank, false)
		end

		c_ai_avoid(tank)

		if not enemy or not c_ai_isMeleeWeapon(tank) then
			c_ai_followObjectives(tank, true)
		end

		local p = c_ai_findClosestEnemy(tank)
		if p then
			p = p.p
		end
		c_ai_setObjective(tank, AVOIDENEMYINDEX, p, ALWAYSANDDESTROY, "enemy", false)
	elseif c_world_getGameType() == CHASE then
		local function filter(x)
			if c_ai_beginningOfChaseGame() then
				return true
			end

			if tank.tagged then
				return false  -- shooting enemy tanks normally doesn't help tagged tanks much
			end

			if not x.tagged and not c_ai_hasRecentlyAttacked(tank, x) then
				return false
			end

			if x.tagged and (x.p - tank.p).R <= c_const_get("ai_taggedAvoidMaxDistance") then
				return false
			end

			return true
		end

		local enemy, angle, pos, time = c_ai_findClosestEnemyInSight(tank, filter)
		if enemy and not c_ai_isFollowingObjective(tank, POWERUPINDEX) then
			c_ai_shootEnemies(tank, enemy, angle, pos, time)

			c_ai_tankWeaponStep(tank, true)
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

			c_ai_tankWeaponStep(tank, false)
		end

		c_ai_avoid(tank)

		if c_ai_beginningOfChaseGame() or tank.tagged then
			local p = c_ai_findClosestEnemy(tank)
			if p then
				p = p.p
			end

			if tank.tagged then
				c_ai_setObjective(tank, GENERICINDEX, p, ALWAYS, "chaseTarget", false)
			else
				c_ai_setObjective(tank, GENERICINDEX, p, ALWAYSANDDESTROY, "shootFistTank", false)
			end
		else
			local x = c_ai_findTaggedTank()
			if x and (x.p - tank.p).R <= c_const_get("ai_taggedAvoidMaxDistance") then
				c_ai_setObjective(tank, GENERICINDEX, x.p, AVOID, "tagged", false)
			end
		end

		c_ai_followObjectives(tank, true)
	elseif c_world_getGameType() == DOMINATION then
		local function closeToControlPoint(ttank)
			if not tank.ai.cc then
				return true
			end

			for _, v in pairs(c_tcm_current_map.controlPoints) do
				if (v.p - ttank.p).R <= c_const_get("ai_enemyControlPointRange") then
					return true
				end
			end

			-- see if tank has recently attacked bot
			if c_ai_hasRecentlyAttacked(tank, ttank) then
				return true
			end

			return false
		end

		local enemy, angle, pos, time = c_ai_findClosestEnemyInSight(tank, closeToControlPoint)
		if enemy then
			c_ai_shootEnemies(tank, enemy, angle, pos, time)

			c_ai_tankWeaponStep(tank, true)
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

			c_ai_tankWeaponStep(tank, false)

			c_ai_followObjectives(tank, false)
		end

		c_ai_avoid(tank)

		-- look for closest control point
		if not tank.ai.cc or (tank.ai.cc.m.team == "red") == (tank.red == true) then
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
		else
			c_ai_setObjective(tank, GENERICINDEX, nil)
		end

		-- don't set enemies as objectives in domination since it doesn't always benefit the tank
	elseif c_world_getGameType() == CAPTURETHEFLAG then
		local function filter(x)
			if c_ai_yourTeamOffensive(tank) and not tank.m.flag then
				return true
			end

			if c_ai_tankRecentlyAttackedYourFlagCarrier(tank, x) or c_ai_tankHasYourFlag(tank, x) then
				return true
			end

			if c_ai_hasRecentlyAttacked(tank, x) then
				if not tank.m.flag or tank.health >= c_const_get("ai_captureFlagMinHealth") then
					return true
				end
			end

			return false
		end

		local enemy, angle, pos, time = c_ai_findClosestEnemyInSight(tank, filter)
		if enemy and not c_ai_isFollowingObjective(tank, POWERUPINDEX) then
			c_ai_shootEnemies(tank, enemy, angle, pos, time)

			c_ai_tankWeaponStep(tank, true)
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

			c_ai_tankWeaponStep(tank, false)

			c_ai_followObjectives(tank, false)
		end

		c_ai_avoid(tank)

		local yourFlagStolen = false  -- own flag stolen

		for _, v in pairs(c_tcm_current_map.flags) do
			if v.red == tank.red then
				if v.m.stolen then
					yourFlagStolen = tankbobs.m_vec2(c_world_getTanks()[v.m.stolen].p)
				elseif v.m.dropped then
					yourFlagStolen = tankbobs.m_vec2(v.m.pos)
				end
			elseif v.red ~= tank.red then
				-- set yourFlagStolen to 0 if the enemy flag isn't stolen and you're close to it, if you're close to the dropped flag
				if not v.m.stolen and not v.m.dropped and (v.p - tank.p).R <= c_const_get("ai_flagRange") then
					yourFlagStolen = false

					break  -- don't let yourFlagStolen be set
				elseif not v.m.stolen and v.m.dropped and (v.m.pos - tank.p).R <= c_const_get("ai_flagRange") then
					yourFlagStolen = false

					break  -- don't let yourFlagStolen be set
				end
			end
		end

		if yourFlagStolen then
			-- hunt down flag carrier
			c_ai_setObjective(tank, GENERICINDEX, yourFlagStolen, ALWAYSANDDESTROY, "enemyFlagCarrier", false)
		else
			if tank.m.flag then
				for _, v in pairs(c_tcm_current_map.flags) do
					if v.red == tank.red then
						c_ai_setObjective(tank, GENERICINDEX, tankbobs.m_vec2(v.p), ALWAYSANDDESTROY, "flagBase", true)
					end
				end
			else
				for _, v in pairs(c_tcm_current_map.flags) do
					if v.red ~= tank.red then
						if v.m.stolen then
							-- your team has stolen enemy flag and your own flag is safe, so go to teammate to protect him
							c_ai_setObjective(tank, GENERICINDEX, tankbobs.m_vec2(c_world_getTanks()[v.m.stolen].p), NOTINSIGHT, "flagCarrier", false)
						elseif v.m.dropped then
							c_ai_setObjective(tank, GENERICINDEX, tankbobs.m_vec2(v.m.pos), ALWAYSANDDESTROY, "enemyFlagWhichDropped", true)
						else
							-- go to enemy flag, which is safe
							c_ai_setObjective(tank, GENERICINDEX, tankbobs.m_vec2(v.p), ALWAYSANDDESTROY, "enemyFlag", true)
						end
					end
				end
			end
		end
	end

	-- look for powerups
	local c = c_ai_findClosestPowerup(tank, true)
	if c then
		c_ai_setObjective(tank, POWERUPINDEX, tankbobs.m_vec2(c.p), INSIGHT, "powerup")
	else
		c_ai_setObjective(tank, POWERUPINDEX, nil)
	end

	local maxSpeed = c_world_getInstagib() and c_const_get("ai_maxSpeedInstagib") or c_const_get("ai_maxSpeed")
	if vel.R > maxSpeed and not tank.ai.followingObjective and not tank.ai.chasingWithMeleeWeapon then
		c_ai_setTankStateSpecial(tank, false)
		c_ai_setTankStateForward(tank, -1)
	end
end
