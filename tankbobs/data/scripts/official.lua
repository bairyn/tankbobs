--[[
Script for official levels
--]]

-- These two lines should appear in order at the beginning of every script.
c_mods_pushFunctions()
c_mods_exitWorldFunction(c_mods_popFunctions)

if c_tcm_current_map.name == "arena" then
	c_const_set("powerup_pushStrength", 0, -1)
	c_const_set("powerup_lifeTime", 0, -1)
	c_const_set("powerup_restartTime", 8, -1)
	c_const_set("powerup_health_restartTime", 30, -1)
	c_const_set("powerup_shield_restartTime", 30, -1)
	c_const_set("wall_freezeTime", 1, -1)
	c_const_set("arena_degeneration", 1 + (1/3), -1)

	local teleporter_touchDistance = c_const_get("teleporter_touchDistance")
	c_const_set("teleporter_touchDistance", -1)

	local function giveShield(tank)
		tank.shield = 99999999
	end

	c_mods_appendFunction("c_world_spawnTank_misc", giveShield)

	local degeneration = nil
	for _, v in pairs(c_tcm_current_map.walls) do
		if v.misc == "degeneration" then
			degeneration = v
		end
	end

	local function giveClips(d)
		for _, v in pairs(c_world_getTanks()) do

			if v.exists and v.weapon then
				local weapon = c_weapon_getWeapons()[v.weapon]

				if weapon and weapon.clips > 0 then
					v.clips = 1
				end

				if degeneration then
					if c_world_intersection(0, c_world_tankHull(v), degeneration.m.pos) then
						v.health = v.health - d * c_const_get("arena_degeneration")
					end
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

		-- teleporters can't be blocked
		local teleporters = c_tcm_current_map.teleporters

		for _, teleporter in pairs(c_tcm_current_map.teleporters) do
			for _, v in pairs(c_world_getTanks()) do
				local breaking = false
				repeat
					if v.exists then
						-- inexpensive distance check
						if math.abs((v.p - teleporter.p).R) <= teleporter_touchDistance then
							local target = teleporters[teleporter.t + 1]

							if teleporter.enabled and target and v.target ~= teleporter.id then
								--[[
								for _, v in pairs(c_world_getTanks()) do
									if v.exists then
										if math.abs((v.p - target.p).R) <= teleporter_touchDistance then
											return
										end
									end
								end
								-- test for rest of world
								if c_world_pointIntersects(target.p) then
									return
								end
								--]]
								if math.abs((v.p - target.p).R) <= teleporter_touchDistance then
									breaking = true break
								end

								v.target = target.id
								v.m.lastTeleportTime = tankbobs.t_getTicks()
								v.m.lastTeleportPosition = tankbobs.m_vec2(v.p)
								tankbobs.w_setPosition(v.m.body, target.p)
								v.p(tankbobs.w_getPosition(v.m.body))
							end

							--return
						elseif v.target == teleporter.id then
							v.target = nil
						end
					end
				until true
				if breaking then
					break
				end
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

	local function toggleWallPath(begin, fixtureA, fixtureB, bodyA, bodyB, position, normal)
		local projectile = c_world_isProjectile(fixtureA)

		if not projectile then
			projectile = c_world_isProjectile(fixtureB)
		end

		if projectile and not projectile.collided then
			local wall = c_world_isWall(fixtureA)
			if not wall then
				wall = c_world_isWall(fixtureB)
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
				local tank = c_world_isTank(fixtureA)
				if not tank then
					tank = c_world_isTank(fixtureB)
				end

				if tank and projectile.weapon ~= c_weapon_getDefaultWeapon() then
					tank.shield = 0  -- remove enemy shield
				end
			end
		end
	end

	local function meleeHit(tank, attacker)
		if attacker and attacker.weapon ~= c_weapon_getDefaultWeapon() then
			tank.shield = 0
		end
	end

	c_mods_appendFunction("c_weapon_meleeHit", meleeHit)

	tankbobs.w_setIterations(8)

	c_mods_prependFunction("c_world_contactListener", toggleWallPath)
	tankbobs.w_setContactListener(c_world_contactListener)

	local function resetSpawnTime(tank, powerup)
		local m = c_tcm_current_map.powerupSpawnPoints[powerup.spawner].m

		if powerup.powerupType then
			local powerupType = c_world_getPowerupTypeByIndex(powerup.powerupType)
			if powerup.powerupType then
				if powerupType.name == "health" then
					m.nextPowerupTime = tankbobs.t_getTicks() + c_world_timeMultiplier(c_const_get("powerup_health_restartTime"))

					return
				elseif powerupType.name == "shield" then
					m.nextPowerupTime = tankbobs.t_getTicks() + c_world_timeMultiplier(c_const_get("powerup_shield_restartTime"))

					return
				end
			end
		end

		m.nextPowerupTime = tankbobs.t_getTicks() + c_world_timeMultiplier(c_const_get("powerup_restartTime"))
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
	local laps = c_config_get(c_world_gameTypePointLimit())

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
			tankbobs.w_setPosition(tank.m.body, tank.p)
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
elseif c_tcm_current_map.name == "spree" then
	-- tanks don't bounce against walls with misc set to "powerup"

	local WALLPOWERUP = 0x8020

	c_const_set("powerup_clipmask", c_const_get("powerup_clipmask") + WALLPOWERUP)

	for _, v in pairs(c_tcm_current_map.walls) do
		if not v.detail and v.m.body then
			if v.misc == "powerup" then
				tankbobs.w_removeBody(v.m.body) v.m.body = nil v.m.fixture = nil

				local b = c_world_wallShape(v.p)
				v.m.body = tankbobs.w_addBody(b[1], 0, c_const_get("wall_canSleep"), c_const_get("wall_isBullet"), c_const_get("wall_linearDamping"), c_const_get("wall_angularDamping"), k)
				v.m.fixture = tankbobs.w_addPolygonalFixture(b[2], c_const_get("wall_density"), c_const_get("wall_friction"), c_const_get("wall_restitution"), c_const_get("wall_isSensor"), c_const_get("wall_contentsMask") + WALLPOWERUP, c_const_get("wall_clipmask"), v.m.body, not v.static)
			end
		end
	end

	-- map triggers

	local map_triggers
	do
		-- find paths that triggers are linked to
		local triggers = {}
		local triggered_ = {}
		for _, wall in pairs(c_tcm_current_map.walls) do
			if wall.misc:sub(1, 1) == 't' and #wall.misc > 1 then
				local match = wall.misc:sub(2)
				local trigger = {wall, {}}

				for k, path in pairs(c_tcm_current_map.paths) do
					if path.misc:find(match) then
						local linked = {}

						for _, wall_sub in pairs(c_tcm_current_map.walls) do
							if wall_sub.path and wall_sub.pid == k - 1 then
								table.insert(linked, wall_sub)
							end
						end

						if #linked > 0 then
							table.insert(trigger[2], {path, linked})
						end
					end
				end

				if #trigger[2] > 0 then
					table.insert(triggers, trigger)
				end
			end
		end

		local function triggered(trigger)
			for k, v in pairs(triggered_) do
				if v[1] == trigger then
					return k
				end
			end

			return false
		end

		local function find(t, v)
			for k, vs in pairs(t) do
				if vs == v then
					return k
				end
			end

			return nil
		end

		local function time(path)
			local time = 0
			local paths = {}
			local mpaths = c_tcm_current_map.paths

			while path and not find(paths, path) do
				table.insert(paths, path)

				time = time + path.time

				path = mpaths[path.t + 1]
			end

			return time
		end

		function map_triggers(d, min)
			local remove = nil

			for k, v in pairs(triggers) do
				if not min or k >= min then
					local triggeredk = triggered(v)

					if triggeredk then
						local triggered = triggered_[triggeredk]
						if triggered[2] then
							triggered[2] = triggered[2] - d
							if triggered[2] <= 0 then
								triggered_[triggeredk] = nil

								v[2][1][1].enabled = not v[2][1][1].enabled
							end
						end
					else
						for _, tank in pairs(c_world_getTanks()) do
							if c_world_intersection(d, c_world_tankHull(tank), v[1].p) then
								v[2][1][1].enabled = not v[2][1][1].enabled

								table.insert(triggered_, {v, time(v[2][1][1])})

								if client then
									tankbobs.a_playSound(c_const_get("globalAudio_dir") .. "pop.wav")
									tankbobs.a_setVolumeChunk(c_const_get("globalAudio_dir") .. "pop.wav", game_audioDistance(tank.p))
								end
							end
						end
					end
				end
			end
		end
	end

	c_mods_appendFunction("c_world_step", map_triggers)
elseif c_tcm_current_map.name == "tutorial" then
	-- don't do anything if running on server
	if server or not client then
		error "Cannot run tutorial level on server"

		return
	end

	c_world_setGameType(DEATHMATCH)
	if c_config_get("game.fragLimit") < 1 then
		c_config_set("game.fragLimit", 1)
	end

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

	-- enable collision damage
	c_world_setCollisionDamage(true)


	-- when a tank dies, set the respawn position to its waypoint, which is set by wall triggers
	local function die(tank, t)
		tank.m.respawnPos = tankbobs.m_vec2(c_tcm_current_map.wayPoints[tank.m.wayPoint and tank.m.wayPoint or 1].p)  -- never rely on the first waypoint
		tank.m.respawnRot = tank.r
	end
	c_mods_prependFunction("c_world_tank_die", die)

	-- when a tank respawns, spawn at its respawn position
	local function setPosition(tank)
		if tank.exists and tank.m.respawnPos then
			tank.p(tank.m.respawnPos)
			tankbobs.w_setPosition(tank.m.body, tank.p)
			tank.r = tank.m.respawnRot
		end
	end
	c_mods_appendFunction("c_world_spawnTank", setPosition)

	c_const_set("helperAudio_dir", c_const_get("globalAudio_dir") .. "tutorial_", -1)

	-- tanks don't bounce against walls with misc set to "powerup"

	local WALLPOWERUP = 0x8020

	c_const_set("powerup_clipmask", c_const_get("powerup_clipmask") + WALLPOWERUP)

	for _, v in pairs(c_tcm_current_map.walls) do
		if not v.detail and v.m.body then
			if v.misc == "powerup" then
				tankbobs.w_removeBody(v.m.body) v.m.body = nil v.m.fixture = nil

				local b = c_world_wallShape(v.p)
				v.m.body = tankbobs.w_addBody(b[1], 0, c_const_get("wall_canSleep"), c_const_get("wall_isBullet"), c_const_get("wall_linearDamping"), c_const_get("wall_angularDamping"), k)
				v.m.fixture = tankbobs.w_addPolygonalFixture(b[2], c_const_get("wall_density"), c_const_get("wall_friction"), c_const_get("wall_restitution"), c_const_get("wall_isSensor"), c_const_get("wall_contentsMask") + WALLPOWERUP, c_const_get("wall_clipmask"), v.m.body, not v.static)
			end
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

			local audioFile = nil

			for k, v in pairs(future) do
				if t >= v[1] then
					if updateHelperText then
						if v[2] then
							updateHelperText(v[2])
						end

						if client and not server and v[3] then
							local filename = c_const_get("helperAudio_dir") .. v[3][math.random(1, #v[3])]
							if tankbobs.fs_fileExists(filename) then
								if audioFile then
									tankbobs.a_setVolumeChunk(audioFile, 0)
									audioFile = nil
								end

								audioFile = filename
								tankbobs.a_playSound(audioFile)
								tankbobs.a_setVolumeChunk(audioFile, 1)
							end
						end

						if v[4] then
							v[4](v[2])
						end

						future[k] = nil
					end
				end
			end
		end

		local helper = gui_addLabel(tankbobs.m_vec2(15, 25), "", update, ALPHASCALE, 0, 0, 0, 1)
		function updateHelperText(text, audio)
			if helper then
				if text then
					helper.m.alphaTime = nil
					helper:setText(text)
				end

				if client and not server and audio then
					local filename = c_const_get("helperAudio_dir") .. audio[math.random(1, #audio)]
					if tankbobs.fs_fileExists(filename) then
						if audioFile then
							tankbobs.a_setVolumeChunk(audioFile, 0)
							audioFile = nil
						end

						audioFile = filename
						tankbobs.a_playSound(audioFile)
						tankbobs.a_setVolumeChunk(audioFile, 1)
					end
				end
			end
		end

		function setFutureHelperText(relativeTime, text, audio, callback)
			table.insert(future, {tankbobs.t_getTicks() + c_world_timeMultiplier(relativeTime), text, audio, callback})
		end

		local function offsetHelperText(d)
			for _, v in pairs(future) do
				v[1] = v[1] + d
			end
		end
		local function resetHelperText(d)
			t = t or tankbobs.t_getTicks()

			for _, v in pairs(future) do
				v[1] = t
			end
		end
		c_mods_prependFunction("c_world_offsetWorldTimers", offsetHelperText)
		c_mods_prependFunction("c_world_resetWorldTimers", resetHelperText)
	end

	-- everything else
	c_const_set("tutStep_sound", c_const_get("flagCapture_sound"), -1)
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
					for ks, vs in pairs(c_tcm_current_map.wayPoints) do
						if tonumber(vs.misc) == wayPoint then
							tank.m.wayPoint = ks
						end
					end
				end
			end
		end

		if f and tank and tank.exists then
			f(d, tank)
		end
	end

	c_mods_prependFunction("c_world_step", frame)

	local function preContactListener(begin, fixtureA, fixtureB, bodyA, bodyB, position, normal)
		local wall, tank = c_world_isWall(fixtureA), c_world_isTank(fixtureB)

		if not wall or not tank then
			wall, tank = c_world_isWall(fixtureB), c_world_isTank(fixtureA)
		end

		if wall and tank then
			if wall.misc:match("nodamage") then
				return true
			end
		end
	end

	c_mods_appendFunction("c_world_preContactListener", preContactListener)

	local function e(id, disable)
		id = tonumber(id)

		-- enable all path limited by an id, which is specified by the path's misc field.
		for _, v in pairs(c_tcm_current_map.paths) do
			if tonumber(v.misc) == id then
				v.m.enabled = not disable
			end
		end
	end

	local function p(id)
		id = tonumber(id)

		-- spawn powerups from powerup spawn points by an id
		for _, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
			if tonumber(v.misc) == id then
				v.m.nextPowerupTime = tankbobs.t_getTicks()
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
		tankbobs.w_setPosition(tank.m.body, tank.p)
		tankbobs.w_setLinearVelocity(tank.m.body, tankbobs.m_vec2(0, 0))

		-- disable rotation
		tank.r = c_const_get("tank_defaultRotation")
	end

	-- in the future, it might be good to explain the gametypes by spawning an unskilled bot and having the player try fighting against each of them.  It might also be good to explain the railgun-against-wall boost trick (nah; it's a "trickmove" / jump).

	local function updateWinStep()
		local tank = c_world_getTanks()[1]

		f = function (d, tank)
			for _, v in pairs(c_tcm_current_map.walls) do
				if v.misc == "win" then
					if c_world_intersection(0, c_world_tankHull(tank), v.p) then
						tank.score = c_config_get("game.fragLimit")
					end
				end
			end
		end

		tank.shield = tank.shield + c_const_get("tank_boostShield")
		updateHelperText("You have been given a shield.  Outside this\n tutorial, you would earn them by picking up\na type of green powerup.  A shield greatly\nprotects your tank,\nand completely protects against collisions.\nFollow the arrows to finish this tutorial.", {"21_1.wav"})
		e(9)
	end

	local function updateTeleporterStep()
		f = function (d, tank)
			for _, v in pairs(c_tcm_current_map.walls) do
				if v.misc == "shield" then
					if c_world_intersection(0, c_world_tankHull(tank), v.p) then
						if client and not server and step ~= 8 then
							step = 8
							tankbobs.a_playSound(c_const_get("tutStep_sound"))
						end

						updateWinStep()
					end
				end
			end
		end

		e(8)

		updateHelperText("Go left and into the teleporter.", {"20_1.wav"})
	end

	local function updateFirstWeaponStep()
		local function restore()
			c_mods_restoreFunction("c_weapon_fire")
		end

		local function noFire()
			c_mods_restoreFunction("c_weapon_fire")
			c_mods_prependFunction("c_weapon_fire", function (tank, d) if tank.clips > 0 or tank.ammo > 0 then tank.state = bit.band(tank.state, bit.bnot(FIRING)) end end)
			c_mods_appendFunction ("c_weapon_fire", function (tank, d) if tank.clips > 0 or tank.ammo > 0 then tank.m.lastFireTime = tank.lastFireTime end end)
		end

		local function noReload()
			c_mods_restoreFunction("c_weapon_fire")
			c_mods_prependFunction("c_weapon_fire", function (tank, d) if tank.clips > 0 or tank.ammo > 0 then tank.state = bit.band(tank.state, bit.bnot(RELOAD)) end end)
		end

		local function noFireOrReload()
			c_mods_restoreFunction("c_weapon_fire")
			c_mods_prependFunction("c_weapon_fire", function (tank, d) if tank.clips > 0 or tank.ammo > 0 then tank.state = bit.band(tank.state, bit.bnot(FIRING))  tank.state = bit.band(tank.state, bit.bnot(RELOAD)) end end)
			c_mods_appendFunction ("c_weapon_fire", function (tank, d) if tank.clips > 0 or tank.ammo > 0 then tank.m.lastFireTime = tank.lastFireTime end end)
		end

		local lostShotgun = false

		local STATENOTHING = 0
		local STATEBEGIN = 1
		local STATECOMPLETERELOADFIRE = 2
		local STATECOMPLETERELOAD = 3
		local STATEPARTIALRELOADFIRE = 4
		local STATEPARTIALRELOAD = 5
		local state = STATENOTHING

		f = function (d, tank)
			if tank.weapon == c_weapon_getByName("shotgun").index then
				local weapon = c_weapon_getWeapons()[tank.weapon]

				if not lostShotgun then
					-- first time picking up shotgun

					if client and not server and step ~= 5 then
						step = 5
						tankbobs.a_playSound(c_const_get("tutStep_sound"))
					end
				end
				lostShotgun = true

				if state == STATENOTHING then
					-- disable both firing and shooting
					noFireOrReload()
					updateHelperText("The shotgun is much more powerful than the\nweak machinegun.  Observe that there are\nnow two bars below your health bar.  The bar\nimmediately below your health bar, with a\n border, shows you how much you have loaded.\nThe bars below represent the\nnumber of clips or extra shells you have.", {"17_1.wav"})
					setFutureHelperText(12, "Go ahead and try firing your shotgun by pressing\nand holding '" .. key("fire") .. "'.\nWhen you finish firing your loaded ammo,\npress and hold your reload key, '" .. key("reload") .. "'\nto reload completely until it's full.", {"22_1.wav"}, function () state = STATECOMPLETERELOADFIRE noReload() end)

					state = STATEBEGIN
				elseif state == STATEBEGIN then
				elseif state == STATECOMPLETERELOADFIRE then
					if tank.ammo <= 0 then
						if tank.reloading <= 0 then
							if client and not server and step ~= 99 then
								step = 99
								updateHelperText("Now reload your shotgun completely ('" .. key("reload") .. "')", {"18_1.wav"})
							end

							noFire()
						else
							state = STATECOMPLETERELOAD
						end
					end
				elseif state == STATECOMPLETERELOAD then
					if tank.reloading <= 0 then
						if tank.ammo < weapon.capacity then
							noReload()
							state = STATECOMPLETERELOADFIRE
							updateHelperText("You didn't press and hold\nyour reload key, '" .. key("reload") .. "' long enough.\nFire the rest of your ammo, and then press and\nHOLD your reload key until you completely\nreload your weapon.", {"16_1.wav"})
						else
							if client and not server and step ~= 6 then
								step = 6
								tankbobs.a_playSound(c_const_get("tutStep_sound"))

								noReload()
								updateHelperText("Now, try reloading your shotgun partially.  Try\npressing and holding your reload key and\nreleasing before you reload completely.", {"15_1.wav"})
							end

							state = STATEPARTIALRELOADFIRE
						end
					end
				elseif state == STATEPARTIALRELOADFIRE then
					if tank.ammo <= 0 then
						if tank.reloading <= 0 then
							if client and not server and step ~= 97 then
								step = 97
								updateHelperText("Now try partially reloading your shotgun.", {"19_1.wav"})
							end

							noFire()
						else
							state = STATEPARTIALRELOAD
						end
					end
				elseif state == STATEPARTIALRELOAD then
					if tank.reloading <= 0 then
						if tank.ammo < weapon.capacity then
							if client and not server and step ~= 7 then
								step = 7
								tankbobs.a_playSound(c_const_get("tutStep_sound"))
							end

							noFireOrReload()

							state = STATEPARTIALRELOADFIRE

							updateHelperText("Good job.\nOutside of this tutorial, you can fire\nand reload shotguns at any time.", nil)
							setFutureHelperText(3, nil, nil, function () restore() updateTeleporterStep() end)
						else
							noReload()
							state = STATEPARTIALRELOADFIRE
							updateHelperText("You didn't release your\nreload key, '" .. key("reload") .. "' soon enough.\nFire the rest of your ammo, and then hold and\nRELEASE your reload key BEFORE you completely\nreload your weapon.", {"14_1.wav"})
						end
					end
				end
			elseif lostShotgun and state ~= STATENOTHING then
				-- re-spawn powerup and helper
				state = STATENOTHING
				p(7)

				updateHelperText("Oops!  You either ran out of ammo or died.\nGrab another shotgun and try again.", {"13_1.wav"})
			end
		end

		e(7)
		p(7)
	end

	local function switchArrows()
		-- change texture coordinates
		for _, v in pairs(c_tcm_current_map.walls) do
			if v.misc == "arrow" then
				for i = 1, v.p[4] and 4 or 3 do
					v.t[i].x = -v.t[i].x
					v.t[i].y = -v.t[i].y
				end
			end
		end
	end

	local function updateDownStep()
		local up = true

		f = function(d, tank)
			if up ~= "done" then
				if up then
					for _, v in pairs(c_tcm_current_map.walls) do
						for _, v in pairs(c_tcm_current_map.walls) do
							local path = c_tcm_current_map.paths[v.pid + 1]

							if v.pid >= 1 and path and tonumber(path.misc) == 5 then
								if not v.m.set5 then
									if v.m.ppid ~= v.pid + 1 then
										v.m.set5 = true
									end
								elseif v.m.ppid == v.pid + 1 then
									v.m.set5 = false

									path.m.enabled = false
								end
							end
						end

						if v.misc == "downSwitch" then
							if c_world_intersection(0, c_world_tankHull(tank), v.p) then
								up = false
								switchArrows()
								e(4)
								updateHelperText("The switch was activited!\nFollow the arrows downward!", {"9_1.wav", "9_2.wav"})
								setFutureHelperText(3, "Try practicing using special by\npressing the switch above and\ndriving down before the wall closes.\nIf you fail, push the switch again.\nIt is important to learn when to use special\nin a real game and to avoid crashing into walls.", {"10_1.wav"})
							end
						end
					end
				else
					for _, v in pairs(c_tcm_current_map.walls) do
						local path = c_tcm_current_map.paths[v.pid + 1]

						if v.pid >= 1 and path and tonumber(path.misc) == 4 then
							if not v.m.set4 then
								if v.m.ppid ~= v.pid + 1 then
									v.m.set4 = true
								end
							elseif v.m.ppid == v.pid + 1 then
								v.m.set4 = false

								if not up then
									up = true
									switchArrows()
									e(5)
								end
								path.m.enabled = false
								updateHelperText("The wall has closed.\nFollow the arrows up and try again.", {"11_1.wav", "11_2.wav"})
								setFutureHelperText(3, "Try practicing using special by\npressing the switch above and\ndriving down before the wall closes.\nIf you fail, push the switch again.\nIt is important to learn when to use special\nin a real game and to avoid crashing into walls.", {"10_1.wav"})
							end
						end
					end

					for _, v in pairs(c_tcm_current_map.walls) do
						if v.misc == "down" then
							if c_world_intersection(0, c_world_tankHull(tank), v.p) then
								if client and not server and step ~= 4 then
									step = 4
									tankbobs.a_playSound(c_const_get("tutStep_sound"))
								end

								up = "done"
								switchArrows()
								e(6)
								updateHelperText("Well done!\nThose movement skills will come in handy.", {"12_1.wav", "12_2.wav"})
								setFutureHelperText(3, "To use a different weapon,\nyou need to drive over a blue powerup.\nTry picking up that shotgun over there.\nPowerups normally disappear after a\ncertain amount of time, but in this tutorial,\npowerups won't disappear.", nil, function() updateFirstWeaponStep() end)
							end
						end
					end
				end
			end
		end
	end

	local function updateForwardStep()
		f = function(d, tank)
			for _, v in pairs(c_tcm_current_map.walls) do
				if v.misc == "goDown" then
					if c_world_intersection(0, c_world_tankHull(tank), v.p) then
						if client and not server and step ~= 3 then
							step = 3
							tankbobs.a_playSound(c_const_get("tutStep_sound"))
						end

						e(3)
						updateHelperText("Nice one!\nTry practicing using special by\npressing the switch above and\ndriving down before the wall closes.\nIf you fail, push the switch again.\nIt is important to learn when to use special\nin a real game and to avoid crashing into walls.", {"8_1.wav", "8_2.wav"})
						updateDownStep()
					end
				end
			end
		end

		setFutureHelperText(4, "Follow the arrows.\nNotice how the ground feels slick.\nPressing special, '" .. key("special") .. "', will prevent the tank\nfrom sliding.  You need to be moving\nwhile using special, or you won't be able to turn.\nAlso notice how you can't accelerate while\nusing special.", {"7_1.wav"})
	end

	local function updateShootWallStep()
		f = function(d, tank)
			-- prevent acceleration or deceleration
			if not tank.m.respawnPos then
				tank.m.respawnPos = tankbobs.m_vec2()
			end
			tank.m.respawnPos(c_tcm_current_map.playerSpawnPoints[1].p)
			tank.p(tank.m.respawnPos)
			tankbobs.w_setPosition(tank.m.body, tank.p)
			tankbobs.w_setLinearVelocity(tank.m.body, tankbobs.m_vec2(0, 0))

			-- listen for a collision of the wall and the giant switch.  Once a collision happens, enable the switch path (push the switch), and continue to the next step
			local oldc_world_contactListener = c_world_contactListener

			local function switchListener(begin, fixtureA, fixtureB, bodyA, bodyB, position, normal)
				local wall1, wall2 = c_world_isWall(fixtureA), c_world_isWall(fixtureB)

				if wall1 and wall2 then
					if wall2.misc == "shootWall" then
						wall1, wall2 = wall2, wall1
					end

					if wall1.misc == "shootWall" and wall2.misc == "shootTriggerWall" then
						c_world_contactListener = oldc_world_contactListener
						tankbobs.w_setContactListener(c_world_contactListener)

						if client and not server and step ~= 2 then
							step = 2
							tankbobs.a_playSound(c_const_get("tutStep_sound"))

							updateHelperText("Good job!", {"3_1.wav", "3_2.wav", "3_3.wav", "3_4.wav"})
							e(2)
							setFutureHelperText(3, "Now we're going to try moving.\nYour tank may be difficult to control initially.", {"6_1.wav"}, function () c_world_setZoom(1) updateForwardStep() end)
						end
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
			tankbobs.w_setPosition(tank.m.body, tank.p)
			tankbobs.w_setLinearVelocity(tank.m.body, tankbobs.m_vec2(0, 0))

			-- continue to next step of tutorial once tank has rotated > 90 degrees
			if math.abs(c_const_get("tank_defaultRotation") - tank.r) > (math.pi * 2) / 4 then
				if client and not server and step ~= 1 then
					step = 1
					tankbobs.a_playSound(c_const_get("tutStep_sound"))

					updateHelperText("Now, try firing your default weapon.", {"4_1.wav", "4_2.wav"})
					setFutureHelperText(3, "Press '" .. key("fire") .. "' to shoot the wall back to the switch.\nRotate your tank to aim.", {"5_1.wav", "5_2.wav"}, function () c_world_setZoom(0.33) e(1) updateShootWallStep() end)
				end
			end
		end
	end

	updateHelperText("Welcome to Tankbobs's tutorial!", {"1_1.wav", "1_2.wav"})
	setFutureHelperText(6, "Press '" .. key("left") .. "' to rotate left, and \n'" .. key("right") .. "' to rotate right.\n\nTry rotating your tank.", {"2_1.wav", "2_2.wav", "2_3.wav", "2_4.wav"}, updateRotateStep)

	-- pre-load helper sounds
	local function i(s)
		local filename = c_const_get("helperAudio_dir") .. s
		if tankbobs.fs_fileExists(filename) then
			tankbobs.a_initSound(filename)
		end
	end

	--i("1_1.wav") i("1_2.wav")  -- Don't re-initialise the first sound, which has already started playing
	i("2_1.wav") i("2_2.wav") i("2_3.wav") i("2_4.wav")
	i("3_1.wav") i("3_2.wav") i("3_3.wav") i("3_4.wav")
	i("4_1.wav") i("4_2.wav")
	i("5_1.wav") i("5_2.wav")
	i("6_1.wav")
	i("7_1.wav")
	i("8_1.wav") i("8_2.wav")
	i("9_1.wav") i("9_2.wav")
	i("10_1.wav")
	i("11_1.wav") i("11_2.wav")
	i("12_1.wav") i("12_2.wav")
	i("13_1.wav")
	i("14_1.wav")
	i("15_1.wav")
	i("16_1.wav")
	i("17_1.wav")
	i("18_1.wav")
	i("19_1.wav")
	i("20_1.wav")
	i("21_1.wav") i("21_2.wav")
	i("22_1.wav")

	-- set last map and last set to default
	c_config_set("game.lastMap", "small_1")
	c_config_set("game.lastSet", "small")
end
