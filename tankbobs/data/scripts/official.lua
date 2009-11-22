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

	-- prevent AI in preview; all functions that me modify using c_mods_* will be restored on exit so that other levels or even the same level can function properly
	c_mods_replaceFunction("c_ai_initTank", common_nil)


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
elseif c_tcm_current_map.name == "tutorial" then
	-- disable AI
	local backupComputers = c_config_get("game.computers")
	c_config_set("game.computers", 0)

	local function resetAI()
		c_config_set("game.computers", backupComputers)
	end

	c_mods_exitWorldFunction(resetAI)

	-- prevent AI in preview
	c_mods_replaceFunction("c_ai_initTank", common_nil)

	-- one player and one player only
	local backupPlayers = c_config_get("game.players")
	c_config_set("game.players", 1)

	local function resetPlayers()
		c_config_set("game.players", backupPlayers)
	end

	c_mods_exitWorldFunction(resetPlayers)

	-- disable instagib
	c_world_setInstagib(false)


	-- when a tank dies, set the respawn position to its waypoint, which is set by wall triggers
	local function die(tank, t)
		tank.m.respawnPos = tankbobs.m_vec2(c_tcm_current_map.wayPoints[tank.m.wayPoint and tank.m.wayPoint or 1].p)  -- never rely on the first waypoint
		tank.m.respawnRot = tank.r
	end

	-- when a tank respawns, spawn at its respawn position
	local function setPosition(tank)
		if tank.exists and tank.m.respawnPos then
			tank.p(tank.m.respawnPos)
			tankbobs.w_setPosition(tank.body, tank.p)
			tank.r = tank.m.respawnRot
		end
	end

	-- helper label
	local updateHelperText
	local setFutureHelperText
	do
		local future = {}

		local ALPHADROP = 1 / 3  -- loses a third of its alpha value every second
		local ALPHAFULLTIME = 2  -- will be completely opaque for 2 seconds before fading
		local ALPHAMIN = 2 / 3   -- alpha is always at least this
		local ALPHASCALE = 1 / 2  -- scale of label
		local function update(widget, d)
			local t = tankbobs.t_getTicks()

			if not widget.m.alphaTime then
				widget.m.alphaTime = ALPHADROP * (ALPHAFULLTIME + 1)
			else
				widget.m.alphaTime = widget.m.alphaTime - d * ALPHADROP
			end
			if widget.m.alphaTime < ALPHAMIN then
				widget.m.alphaTime = ALPHAMIN
			end

			widget.color.a = math.min(1, widget.m.alphaTime)

			for k, v in pairs(future) do
				if t >= v[1] then
					if updateHelperText then
						if v[2] then
							updateHelperText(v[2])
						end

						if v[3] then
							v[3](v[2])
						end

						future[k] = nil
					end
				end
			end
		end

		local helper = gui_addLabel(tankbobs.m_vec2(15, 25), "", update, ALPHASCALE)
		function updateHelperText(text)
			if helper then
				helper.m.alphaTime = nil
				helper:setText(text)
			end
		end

		function setFutureHelperText(relativeTime, text, callback)
			table.insert(future, {tankbobs.t_getTicks() + c_world_timeMultiplier(relativeTime), text, callback})
		end

		local function offsetHelperText(d)
			for _, v in pairs(future) do
				v[1] = v[1] + d
			end
		end
		local function resetHelperText(d)
			t = t or t_t_getTicks()

			for _, v in pairs(future) do
				v[1] = t
			end
		end
		c_mods_prependFunction("c_world_offsetWorldTimers", offsetHelperText)
		c_mods_prependFunction("c_world_resetWorldTimers", resetHelperText)
	end

	-- everything else
	c_const_set("powerup_lifeTime", 0, -1)

	local f
	local function setf(f_)
		f = f_

		return f
	end

	local function frame(d)
		local tank = c_world_getTanks()[1]

		assert(tank)

		for _, v in pairs(c_tcm_current_map.walls) do
			local wayPoint = v.misc:match("^[\n\t ]*[Ww][Aa][Yy][Pp][Oo][Ii][Nn][Tt][\n\t ]*([%d]+)[\n\t ]*$")
			if wayPoint and tonumber(wayPoint) then
				wayPoint = tonumber(wayPoint)

				if c_world_intersection(nil, c_world_tankHull(tank), v.p) then
					tank.m.wayPoint = wayPoint
				end
			else
			end
		end

		if f and tank and tank.exists then
			f(d, tank)
		end
	end

	c_mods_prependFunction("c_world_step", frame)

	local function e(id, disable)
		id = tonumber(id)

		-- enable all path limited by an id, which is specified by the path's misc field.
		for _, v in pairs(c_tcm_current_map.paths) do
			if tonumber(v.misc) == id then
				v.m.enabled = not disable
			end
		end
	end

	local function key(name)
		return gui_char(c_config_keyLayoutGet(c_config_get("client.key.player1." .. name)))
	end

	-- initially disable tank movement
	f = function (d, tank)
		-- prevent acceleration or deceleration
		if not tank.m.respawnPos then
			tank.m.respawnPos = tankbobs.m_vec2()
		end
		tank.m.respawnPos(c_tcm_current_map.playerSpawnPoints[1].p)
		tank.p(tank.m.respawnPos)
		tankbobs.w_setPosition(tank.body, tank.p)
		tankbobs.w_setLinearVelocity(tank.body, tankbobs.m_vec2(0, 0))

		-- disable rotation
		tank.r = c_const_get("tank_defaultRotation")
	end

	local function updateForwardStep()
		f = function()
		end
	end

	local function updateShootWallStep()
		f = function(d, tank)
			-- prevent acceleration or deceleration
			if not tank.m.respawnPos then
				tank.m.respawnPos = tankbobs.m_vec2()
			end
			tank.m.respawnPos(c_tcm_current_map.playerSpawnPoints[1].p)
			tank.p(tank.m.respawnPos)
			tankbobs.w_setPosition(tank.body, tank.p)
			tankbobs.w_setLinearVelocity(tank.body, tankbobs.m_vec2(0, 0))

			-- listen for a collision of the wall and the giant switch.  Once a collision happens, enable the switch path (push the switch), and continue to the next step
			local oldc_world_contactListener = c_world_contactListener

			local function switchListener(shape1, shape2, body1, body2, position, separation, normal)
				local wall1, wall2 = c_world_isWall(body1), c_world_isWall(body2)

				if wall1 and wall2 then
					if wall2.misc == "shootWall" then
						wall1, wall2 = wall2, wall1
					end

					if wall1.misc == "shootWall" and wall2.misc == "shootTriggerWall" then
						c_world_contactListener = oldc_world_contactListener
						tankbobs.w_setContactListener(c_world_contactListener)

						updateHelperText("Good job!")
						e(2)
						setFutureHelperText(3, "Now we're going to try moving.\nYour tank can be difficult to control initially.\nThis is the end as of yet; more to come!", function () c_world_setZoom(1) updateForwardStep() end)
					end
				end
			end

			c_mods_prependFunction("c_world_contactListener", switchListener)
			tankbobs.w_setContactListener(c_world_contactListener)
		end
	end

	local function updateRotateStep()
		f = function(d, tank)
			-- prevent acceleration or deceleration
			if not tank.m.respawnPos then
				tank.m.respawnPos = tankbobs.m_vec2()
			end
			tank.m.respawnPos(c_tcm_current_map.playerSpawnPoints[1].p)
			tank.p(tank.m.respawnPos)
			tankbobs.w_setPosition(tank.body, tank.p)
			tankbobs.w_setLinearVelocity(tank.body, tankbobs.m_vec2(0, 0))

			-- continue to next step of tutorial once tank has rotated > 90 degrees
			if math.abs(c_const_get("tank_defaultRotation") - tank.r) > (math.pi * 2) / 4 then
				updateHelperText("Now, you'll want to try firing your default weapon.")
				setFutureHelperText(3, "Press '" .. key("fire") .. "' to shoot the wall back into the switch.\nRotate the tank to aim.", function () c_world_setZoom(0.33) e(1) updateShootWallStep() end)
			end
		end
	end

	updateHelperText("Welcome to Tankbobs's tutorial!\nThis tutorial is not yet finished.")
	setFutureHelperText(6, "Press '" .. key("left") .. "' to rotate left, and \n'" .. key("right") .. "' to rotate right.\n\nTry rotating your tank.", updateRotateStep)
end
