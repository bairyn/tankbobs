--[[
Script for official levels
--]]

c_mods_exitWorldFunction(c_mods_restoreFunctions)

if c_tcm_current_map.name == "arena" then
	c_const_set("powerup_pushStrength", 0)
	c_const_set("powerup_lifeTime", 0)
	c_const_set("powerup_restartTime", 2)
	c_const_set("wall_freezeTime", 1)

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

	local function resetWalls()
		tankbobs.w_setTimeStep(c_const_get("world_timeStep"))
		tankbobs.w_setIterations(c_const_get("world_iterations"))

		for _, v in pairs(c_tcm_current_map.walls) do
			if v.m.script_path then
				v.path = v.m.script_path[1]
			end
		end
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
		if c_world_getPowerupTypeByIndex(powerup.powerupType).name ~= "health" then
			c_tcm_current_map.powerupSpawnPoints[powerup.spawner].m.nextPowerupTime = tankbobs.t_getTicks() + c_world_timeMultiplier(c_const_get("powerup_restartTime"))
		end
	end

	c_mods_prependFunction("c_world_powerup_pickUp", resetSpawnTime)
end
