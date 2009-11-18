--[[
Script for official levels
--]]

c_mods_exitWorldFunction(c_mods_restoreFunctions)

if c_tcm_current_map.name == "arena" then
	c_const_set("powerup_pushStrength", 0, -1)
	c_const_set("powerup_lifeTime", 0, -1)
	c_const_set("powerup_restartTime", 8, -1)
	c_const_set("wall_freezeTime", 1, -1)

	local function giveShield(tank)
		tank.shield = 99999999
	end

	c_mods_appendFunction("c_world_spawnTank_misc", giveShield)

	local function giveClips()
		for _, v in pairs(c_world_getTanks()) do

			if v.exists and v.weapon then
				local weapon = c_weapon_getWeapons()[v.weapon]

				if weapon and weapon.clips > 0 then
					v.clips = 1
				end
			end
		end

		-- unfreeze walls on paths
		for _, v in pairs(c_tcm_current_map.walls) do
			if v.m.unfreezeTime and tankbobs.t_getTicks() > v.m.unfreezeTime then
				v.unfreezeTime = nil
				v.path = true
			end
		end
	end

	c_mods_prependFunction("c_world_step", giveClips)

	local backupComputers = c_config_get("game.computers")
	c_config_set("game.computers", 0)

	local function resetWalls()
		tankbobs.w_setTimeStep(c_const_get("world_timeStep"))
		tankbobs.w_setIterations(c_const_get("world_iterations"))

		for _, v in pairs(c_tcm_current_map.walls) do
			if v.m.script_path then
				v.path = v.m.script_path[1]
			end
		end

		c_config_set("game.computers", backupComputers)
	end

	c_mods_exitWorldFunction(resetWalls)

	local function toggleWallPath(shape1, shape2, body1, body2, position, separation, normal)
		local projectile = c_world_isProjectile(body1)

		if not projectile then
			projectile = c_world_isProjectile(body2)
		end

		if projectile and not projectile.collided then
			local wall = c_world_isWall(body1)
			if not wall then
				wall = c_world_isWall(body2)
			end

			if wall and (wall.path or wall.m.script_path) then
				if not wall.m.script_path then
					wall.m.script_path = {wall.path}
				end

				--wall.path = not wall.path
				-- temporarily freeze wall instead of toggling, if the tank has non-default weapon
				if projectile.weapon ~= c_weapon_getDefaultWeapon() then
					wall.path = false
					wall.m.unfreezeTime = tankbobs.t_getTicks() + c_world_timeMultiplier(c_const_get("wall_freezeTime"))
				end
			end

			if not wall then
				local tank = c_world_isTank(body1)
				if not tank then
					tank = c_world_isTank(body2)
				end

				if tank and projectile.weapon ~= c_weapon_getDefaultWeapon() then
					tank.shield = 0  -- remove enemy shield
				end
			end
		end
	end

	tankbobs.w_setIterations(4)
	tankbobs.w_setTimeStep(1 / 250)

	c_mods_prependFunction("c_world_contactListener", toggleWallPath)
	tankbobs.w_setContactListener(c_world_contactListener)

	local function resetSpawnTime(tank, powerup)
		c_tcm_current_map.powerupSpawnPoints[powerup.spawner].m.nextPowerupTime = tankbobs.t_getTicks() + c_world_timeMultiplier(c_const_get("powerup_restartTime"))
	end

	c_mods_prependFunction("c_world_powerup_pickUp", resetSpawnTime)
elseif c_tcm_current_map.name == "race-track" then
	-- disable AI
	local backupComputers = c_config_get("game.computers")
	c_config_set("game.computers", 0)

	local function resetAI()
		c_config_set("game.computers", backupComputers)
	end

	-- when the world exits, call resetAI
	c_mods_exitWorldFunction(resetAI)

	-- zoom out
	c_world_setZoom(0.66)

	-- first look for number of laps by score limit
	local laps

	local switch = c_world_getGameType()
	if switch == DEATHMATCH then
		laps = c_config_get("game.fragLimit")
	elseif switch == CHASE then
		laps = c_config_get("game.chaseLimit")
	elseif switch == DOMINATION then
		laps = c_config_get("game.pointLimit")
	elseif switch == CAPTURETHEFLAG then
		laps = c_config_get("game.captureLimit")
	end

	-- set internal gametype to deathmatch, fragLimit to laps, and restore fragLimit on exit
	c_world_setGameType(DEATHMATCH)

	local backupFragLimit = c_config_get("game.fragLimit")
	c_config_set("game.fragLimit", laps)

	local function resetFragLimit()
		c_config_set("game.fragLimit", backupFragLimit)
	end

	-- when the world exits, also call resetFragLimit
	c_mods_exitWorldFunction(resetFragLimit)

	-- killing players doesn't reward points
	local function die(tank, t)
		t = t or tankbobs.t_getTicks()

		if tank.killer and c_world_getTanks()[tank.killer] and tank.killer ~= tank then
			local killer = c_world_getTanks()[tank.killer]
			killer.score = killer.score - 1
		else
			tank.score = tank.score + 1
		end
	end

	-- when c_world_tank_die is called, call our local function "die" first with the same arguments
	c_mods_prependFunction("c_world_tank_die", die)

	-- find race walls; they will be designated by having a number in the misc field
	local raceWalls = {true, true, true}
	for _, v in pairs(c_tcm_current_map.walls) do
		if v.misc:len() > 0 and tonumber(v.misc) and raceWalls[tonumber(v.misc)] then
			raceWalls[tonumber(v.misc)] = v
		end
	end

	-- check if all three race walls exist
	for _, v in pairs(raceWalls) do
		if v == true and type(v) ~= "table" then
			common_error "map doesn't have all three race walls!"
		end
	end

	-- when a tank dies, set the respawn position to the nearest waypoint
	local function die(tank, t)
		t = t or tankbobs.t_getTicks()

		--[[
		local p = c_ai_findClosestWayPoint(tank.p)
		if p then
			 p = p[1]
		end

		if not p then
			p = tankbobs.m_vec2(tank.p)
		elseif p > 0 then
			p = tankbobs.m_vec2(c_tcm_current_map.wayPoints[p].p)
		else
			p = tankbobs.m_vec2(c_tcm_current_map.teleport_sound[-p].p)
		end
		--]]
		-- instead of respawning at the nearest way point, spawn at the position at which the tank was when it died
		local p = tankbobs.m_vec2(tank.p)

		tank.m.respawnPos = p
		tank.m.respawnRot = tank.r
	end

	-- we redefined "die" to another function.  Our second "die" function will be called, and then the first, and then the real c_world_tank_die.
	c_mods_prependFunction("c_world_tank_die", die)

	-- when a tank respawns, spawn at its respawn position
	local function setPosition(tank)
		if tank.exists and tank.m.respawnPos then
			tank.p(tank.m.respawnPos)
			tankbobs.w_setPosition(tank.body, tank.p)
			tank.r = tank.m.respawnRot
		end
	end

	-- here, instead of prepending a function, we append a function.  Our local function will be called after c_world_spawnTank.
	c_mods_appendFunction("c_world_spawnTank", setPosition)

	-- powerups are stationary and never disappear
	c_const_set("powerup_pushStrength", 0, -1)
	c_const_set("powerup_lifeTime", 0, -1)

	-- when a powerup is picked up, reset its spawn timer
	c_const_set("powerup_restartTime", 8, -1)

	local function resetSpawnTime(tank, powerup)
		c_tcm_current_map.powerupSpawnPoints[powerup.spawner].m.nextPowerupTime = tankbobs.t_getTicks() + c_world_timeMultiplier(c_const_get("powerup_restartTime"))
	end

	c_mods_prependFunction("c_world_powerup_pickUp", resetSpawnTime)

	-- race mechanism
	c_const_set("lap_sound", c_const_get("flagCapture_sound"), -1)
	local function frame(d)
		for _, v in pairs(c_world_getTanks()) do
			if v.exists then
				if not v.m.nextRace then
					v.m.nextRace = 1
				end

				local wall = raceWalls[v.m.nextRace]
				assert(wall)

				if v.m.nextRace == 1 then
					-- the tank needs to intersect the first race wall
					if c_world_intersection(0, c_world_tankHull(v), wall.p) then
						v.m.nextRace = 2
					end
				elseif v.m.nextRace == 2 then
					-- the tank needs to intersect the second race wall
					if c_world_intersection(0, c_world_tankHull(v), wall.p) then
						v.m.nextRace = 3
					end
				elseif v.m.nextRace == 3 then
					-- the tank needs to intersect the final race wall
					if c_world_intersection(0, c_world_tankHull(v), wall.p) then
						v.m.nextRace = 1

						-- increment score
						v.score = v.score + 1

						-- play lap sound
						if client and not server then
							tankbobs.a_playSound(c_const_get("lap_sound"))
						end
					end
				end
			end
		end
	end

	c_mods_prependFunction("c_world_step", frame)
elseif c_tcm_current_map.name == "large 1" then
end
