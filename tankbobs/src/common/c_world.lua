--[[
Copyright (C) 2008-2009 Byron James Johnson

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

World and physics
--]]

local c_config_set            = c_config_set
local c_config_get            = c_config_get
local c_const_set             = c_const_set
local c_const_get             = c_const_get
local c_weapon_getProjectiles = c_weapon_getProjectiles
local common_FTM              = common_FTM
local common_lerp             = common_lerp
local c_weapon_fire           = c_weapon_fire
local tankbobs                = tankbobs
local t_w_setAngle            = nil
local t_w_getAngle            = nil
local t_w_getPosition         = nil
local t_w_getVertices         = nil
local t_t_getTicks            = nil
local t_t_clone               = nil
local t_m_vec2                = nil
local t_w_getLinearVelocity   = nil
local t_w_setLinearVelocity   = nil
local t_w_setAngularVelocity  = nil

local bit

local c_world_tank_checkSpawn
local c_world_tank_step
local c_world_wall_step
local c_world_projectile_step
local c_world_powerupSpawnPoint_step
local c_world_powerup_step
local c_world_controlPoint_step
local c_world_flag_step
local c_world_teleporter_step
local c_world_tanks
local c_world_powerups
local tank_acceleration
local tank_rotationSpeed
local tank_rotationSpecialSpeed
local tank_speedK
local tank_rotationChange
local tank_rotationChangeMinSpeed
local tank_worldFriction
local c_world_testBody
local behind

local worldTime = 0
local c_world_instagib = false
local lastPowerupSpawnTime
local nextPowerupSpawnPoint
local worldInitialized = false

local key = {}

function c_world_init()
	c_config_set            = _G.c_config_set
	c_config_get            = _G.c_config_get
	c_const_set             = _G.c_const_set
	c_const_get             = _G.c_const_get
	c_weapon_getProjectiles = _G.c_weapon_getProjectiles
	common_FTM              = _G.common_FTM
	common_lerp             = _G.common_lerp
	c_weapon_fire           = _G.c_weapon_fire
	tankbobs                = _G.tankbobs
	t_w_setAngle            = _G.tankbobs.w_setAngle
	t_w_getAngle            = _G.tankbobs.w_getAngle
	t_w_getPosition         = _G.tankbobs.w_getPosition
	t_w_getVertices         = _G.tankbobs.w_getVertices
	t_t_getTicks            = _G.tankbobs.t_getTicks
	t_t_clone               = _G.tankbobs.t_clone
	t_m_vec2                = _G.tankbobs.m_vec2
	t_w_getLinearVelocity   = _G.tankbobs.w_getLinearVelocity
	t_w_setLinearVelocity   = _G.tankbobs.w_setLinearVelocity
	t_w_setAngularVelocity  = _G.tankbobs.w_setAngularVelocity

	bit = c_module_load "bit"

	c_config_cheat_protect("game.timescale")

	c_const_set("world_time", 1000)  -- relative to change in seconds

	c_const_set("world_fps", 256)  -- TODO: make single changes to world_fps not affect game speeds
	--c_const_set("world_fps", c_config_get("game.worldFPS"))  -- physics FPS needs to be constant
	--c_const_set("world_timeStep", common_FTM(c_const_get("world_fps")))
	c_const_set("world_timeStep", 1 / 500)
	c_const_set("world_iterations", 16)

	c_const_set("wall_contentsMask", WALL, 1)
	c_const_set("wall_clipmask", WALL + POWERUP + TANK + PROJECTILE, 1)
	c_const_set("wall_isSensor", false, 1)
	c_const_set("powerup_contentsMask", POWERUP, 1)
	c_const_set("powerup_clipmask", WALL + TANK + POWERUP, 1)
	c_const_set("powerup_isSensor", false, 1)
	c_const_set("tank_contentsMask", TANK, 1)
	c_const_set("tank_clipmask", WALL + POWERUP + TANK + PROJECTILE, 1)
	c_const_set("tank_isSensor", false, 1)
	c_const_set("projectile_contentsMask", PROJECTILE, 1)
	c_const_set("projectile_clipmask", WALL + TANK + PROJECTILE, 1)
	c_const_set("projectile_isSensor", false, 1)

	c_const_set("world_behind", 5000, 1)  -- in ms (compared directly against SDL_GetTicks()
	behind = c_const_get("world_behind")

	c_const_set("world_timeWrapTest", -99999)

	c_const_set("world_lowerbound", t_m_vec2(-5, -5), 1)
	c_const_set("world_upperbound", t_m_vec2(5, 5), 1)

	c_const_set("world_gravityx", 0, 1) c_const_set("world_gravityy", 0, 1)
	c_const_set("world_allowSleep", true, 1)

	c_const_set("world_maxPowerups", 64, 1)

	c_const_set("teleporter_touchDistance", 6, 1)
	c_const_set("controlPoint_touchDistance", 4, 1)
	c_const_set("flag_touchDistance", 6, 1)

	c_const_set("powerup_lifeTime", 12, 1)
	c_const_set("powerup_density", 1E-5, 1)
	c_const_set("powerup_friction", 0, 1)
	c_const_set("powerup_restitution", 1, 1)
	c_const_set("powerup_canSleep", false, 1)
	c_const_set("powerup_isBullet", false, 1)
	c_const_set("powerup_linearDamping", 0, 1)
	c_const_set("powerup_angularDamping", 0, 1)
	c_const_set("powerup_pushStrength", 16, 1)
	c_const_set("powerup_pushAngle", math.pi / 4, 1)
	c_const_set("powerup_static", false, 1)

	c_const_set("game_chasePointTime", 10, 1)
	c_const_set("game_tagProtection", 0.2, 1)

	-- hull of tank facing right
	c_const_set("tank_hullx1", -2.0, 1) c_const_set("tank_hully1",  2.0, 1)
	c_const_set("tank_hullx2", -2.0, 1) c_const_set("tank_hully2", -2.0, 1)
	c_const_set("tank_hullx3",  2.0, 1) c_const_set("tank_hully3", -1.0, 1)
	c_const_set("tank_hullx4",  2.0, 1) c_const_set("tank_hully4",  1.0, 1)
	c_const_set("tank_health", 100, 1)
	c_const_set("tank_damageK", 4, 1)  -- damage relative to speed before a collision: 2 hp / 1 ups
	c_const_set("tank_damageMinSpeed", 6, 1)
	c_const_set("tank_intensityMaxSpeed", 6, 1)
	c_const_set("tank_collideMinDamage", 5, 1)
	c_const_set("tank_deceleration", 64 / 1000, 1)
	c_const_set("tank_decelerationMaxSpeed", 16, 1)
	c_const_set("tank_highHealth", 66, 1)
	c_const_set("tank_lowHealth", 33, 1)
	c_const_set("tank_acceleration",
	{
		{16 / 1000},
		{12 / 1000, 4},
	}, 1)
	tank_acceleration = c_const_get("tank_acceleration")
	c_const_set("tank_speedK", 5, 1)
	tank_speedK = c_const_get("tank_speedK")
	c_const_set("tank_density", 2, 1)
	c_const_set("tank_friction", 0.25, 1)
	c_const_set("tank_worldFriction", 2 / 1000, 1)  -- damping
	tank_worldFriction = c_const_get("tank_worldFriction")
	c_const_set("tank_restitution", 0.4, 1)
	c_const_set("tank_canSleep", false, 1)
	c_const_set("tank_isBullet", true, 1)
	c_const_set("tank_linearDamping", 0, 1)
	c_const_set("tank_angularDamping", 0, 1)
	c_const_set("tank_spawnTime", 0.75, 1)
	c_const_set("tank_static", false, 1)
	c_const_set("wall_density", 1, 1)
	c_const_set("wall_friction", 0.25, 1)  -- deceleration caused by friction (~speed *= 1 - friction)
	c_const_set("wall_restitution", 0.2, 1)
	c_const_set("wall_canSleep", false, 1)
	c_const_set("wall_isBullet", false, 1)
	c_const_set("wall_linearDamping", 0.75, 1)
	c_const_set("wall_angularDamping", 0.75, 1)
	c_const_set("tank_rotationChange", 0.005, 1)
	tank_rotationChange = c_const_get("tank_rotationChange")
	c_const_set("tank_rotationChangeMinSpeed", 0.5, 1)  -- if at least 24 ups
	tank_rotationChangeMinSpeed = c_const_get("tank_rotationChangeMinSpeed")
	c_const_set("tank_rotationSpeed", c_math_radians(510) / 1000, 1)
	tank_rotationSpeed = c_const_get("tank_rotationSpeed")
	c_const_set("tank_rotationSpecialSpeed", c_math_degrees(1) / 3.5, 1)
	tank_rotationSpecialSpeed = c_const_get("tank_rotationSpecialSpeed")
	c_const_set("tank_defaultRotation", c_math_radians(90), 1)  -- up
	c_const_set("tank_boostHealth", 60, 1)
	c_const_set("tank_boostShield", 25, 1)
	c_const_set("tank_shieldedDamage", 1 / 4, 1)
	c_const_set("tank_shieldDamage", 1 / 16, 1)
	c_const_set("tank_accelerationModifier", 3, 1)

	c_const_set("controlPoint_rate", 2, 1)

	c_const_set("powerup_hullx1",  0, 1) c_const_set("powerup_hully1",  1, 1)
	c_const_set("powerup_hullx2",  0, 1) c_const_set("powerup_hully2",  0, 1)
	c_const_set("powerup_hullx3",  1, 1) c_const_set("powerup_hully3",  0, 1)
	c_const_set("powerup_hullx4",  1, 1) c_const_set("powerup_hully4",  1, 1)

	-- powerups
	c_powerupTypes = {}

	-- weapons are bluish, weapon enhancements are yellowish, tank enhancements are greenish, extreme powerups are reddish

	-- machinegun
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 1
	powerupType.name = "machinegun"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.3, 0.6, 1, 1
	powerupType.instagib = false

	-- shotgun
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 2
	powerupType.name = "shotgun"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.25, 0.25, 0.75, 1
	powerupType.instagib = false

	-- railgun
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 3
	powerupType.name = "railgun"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0, 0, 1, 1
	powerupType.instagib = false

	-- coilgun
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 4
	powerupType.name = "coilgun"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.25, 0.25, 1, 0.875
	powerupType.instagib = false

	-- saw
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 5
	powerupType.name = "saw"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0, 0, 0.6, 0.875
	powerupType.instagib = false

	-- ammo
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 6
	powerupType.name = "ammo"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.05, 0.4, 0.1, 0.5
	powerupType.instagib = false

	-- aim aid
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 7
	powerupType.name = "aim-aid"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.5, 0.75, 0.1, 0.5
	powerupType.instagib = true

	-- health
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 8
	powerupType.name = "health"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.1, 0.85, 0.1, 0.8
	powerupType.instagib = true

	-- acceleration
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 9
	powerupType.name = "acceleration"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.25, 0.375, 0.05, 0.75
	powerupType.instagib = true

	-- shield
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 10
	powerupType.name = "shield"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.25, 0.5, 0.05, 0.755
	powerupType.instagib = false

	tankbobs.w_setTimeStep(c_const_get("world_timeStep"))
	tankbobs.w_setIterations(c_const_get("world_iterations"))
end

function c_world_done()
end

c_world_powerupType =
{
	new = c_class_new,
	index = 0,
	name = "",
	c = {r = 0, g = 0, b = 0, a = 0},
	instagib = false
}

c_world_powerup =
{
	new = c_class_new,

	p = tankbobs.m_vec2(),
	r = 0,  -- rotation
	spawner = 0,  -- index of psp
	collided = false,  -- whether it needs to be removed
	powerupType = nil,  -- index of type of powerup
	spawnTime = 0,  -- the time the powerup spawned

	m = {}
}

c_world_tank =
{
	new = c_class_new,
	init = function (o)
		o.name = c_const_get("defaultName")
		o.h[1].x = c_const_get("tank_hullx1")
		o.h[1].y = c_const_get("tank_hully1")
		o.h[2].x = c_const_get("tank_hullx2")
		o.h[2].y = c_const_get("tank_hully2")
		o.h[3].x = c_const_get("tank_hullx3")
		o.h[3].y = c_const_get("tank_hully3")
		o.h[4].x = c_const_get("tank_hullx4")
		o.h[4].y = c_const_get("tank_hully4")
		o.color.r = c_config_get("game.defaultTankRed")
		o.color.g = c_config_get("game.defaultTankGreen")
		o.color.b = c_config_get("game.defaultTankBlue")
	end,

	p = tankbobs.m_vec2(),
	h = {tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()},  -- physical box: four vectors of offsets for tanks
	r = 0,  -- tank's rotation
	name = "",
	exists = false,
	spawning = false,
	lastSpawnPoint = 0,
	state = 0,
	weapon = nil,
	lastFireTime = nil,
	body = nil,  -- physical body
	health = 0,
	nextSpawnTime = 0,
	killer = nil,
	score = 0,
	ammo = 0,
	clips = 0,
	reloading = false,
	shotgunReloadState = nil,
	red = false,
	color = {r = 0, g = 0, b = 0},
	tagged = false,
	lastAttackers = {},

	cd = {},  -- data cleared on death

	ai = {},
	bot = false,

	m = {p = {}}
}

c_world_team =
{
	new = c_class_new,

	red = false,
	score = 0
}

function c_world_getPowerupTypeByName(name)
	for _, v in pairs(c_powerupTypes) do
		if v.name == name then
			return v
		end
	end
end

function c_world_getPowerupTypeByIndex(index)
	return c_powerupTypes[index]

	--[[
	for _, v in pairs(c_powerupTypes) do
		if v.name == name then
			return v
		end
	end
	--]]
end

function c_world_newWorld()
	if worldInitialized then
		return
	end

	c_world_powerups = {}
	c_world_tanks = {}
	c_world_teams = {}

	local m = c_tcm_current_map
	if not c_tcm_current_map then
		return false
	end
	tankbobs.w_newWorld(c_const_get("world_lowerbound") + t_m_vec2(m.leftmost, m.lowermost), c_const_get("world_upperbound") + t_m_vec2(m.rightmost, m.uppermost), t_m_vec2(c_const_get("world_gravityx"), c_const_get("world_gravityy")), c_const_get("world_allowSleep"), c_world_contactListener, c_world_tank_step, c_world_wall_step, c_world_projectile_step, c_world_powerupSpawnPoint_step, c_world_powerup_step, c_world_controlPoint_step, c_world_flag_step, c_world_teleporter_step, c_world_tanks, c_tcm_current_map.walls, c_weapon_getProjectiles(), c_tcm_current_map.powerupSpawnPoints, c_world_powerups, c_tcm_current_map.controlPoints, c_tcm_current_map.flags, c_tcm_current_map.teleporters)

	-- set game type
	local switch = c_config_get("game.gameType")
	if switch == "deathmatch" then
		c_world_gameType = DEATHMATCH
	elseif switch == "chase" then
		c_world_gameType = CHASE
	elseif switch == "domination" then
		c_world_gameType = DOMINATION
	elseif switch == "capturetheflag" then
		c_world_gameType = CAPTURETHEFLAG
	else
		c_world_gameType = DEATHMATCH
	end

	-- teams
	local team
	team = c_world_team:new()
	c_world_redTeam = team
	table.insert(c_world_teams, team)
	team.red = true
	team.score = 0

	team = c_world_team:new()
	c_world_blueTeam = team
	table.insert(c_world_teams, team)
	team.red = false
	team.score = 0

	-- reset powerups
	lastPowerupSpawnTime = nil
	nextPowerupSpawnPoint = nil

	for k, v in pairs(c_tcm_current_map.walls) do
		local breaking = false repeat
			v.m.pos = t_t_clone(true, v.p)

			if v.detail then
				breaking = false break  -- the wall isn't part of the physical world
			end

			-- add wall to world
			local b = c_world_wallShape(v.p)
			v.m.body = tankbobs.w_addBody(b[1], 0, c_const_get("wall_canSleep"), c_const_get("wall_isBullet"), c_const_get("wall_linearDamping"), c_const_get("wall_angularDamping"), b[2], c_const_get("wall_density"), c_const_get("wall_friction"), c_const_get("wall_restitution"), not v.static, c_const_get("wall_contentsMask"), c_const_get("wall_clipmask"), c_const_get("wall_isSensor"), k)
			if not v.m.body then
				error "c_world_newWorld: could not add a wall to the physical world"
			end
		until true if breaking then break end
	end

	for k, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
		v.m.nextPowerupTime = t_t_getTicks() + c_world_timeMultiplier(v.initial)
		local enabled = false
		for k, vs in pairs(v.enabledPowerups) do
			if vs then
				enabled = true
				v.m.lastPowerup = k
			end
		end
		if not enabled then
			-- tankbobs assumes that at least one powerup is enabled, so remove the psp
			c_tcm_current_map.powerupSpawnPoints[k] = nil
		end
	end

	c_world_setPaused(false)  -- clear pause

	worldTime = t_t_getTicks()

	worldInitialized = true

	c_const_backup(key)

	if #c_tcm_current_map.script > 0 then
		-- see if script exists
		local filename = c_const_get("scripts_dir") .. c_tcm_current_map.script

		local fin, err = io.open(filename, "r")
		if not fin then
			common_printError(STOP, "c_world_newWorld: map needs script '" .. c_tcm_current_map.script .. "', which doesn't exist")
		else
			fin:close()

			local script, err = loadfile(filename)
			if not script then
				common_printError(STOP, "c_world_freeWorld: script '" .. c_tcm_current_map.script .. "' required by map could not compile: " .. err)
			end

			local status, err = pcall(script)
			if not status then
				common_printError(STOP, "c_world_freeWorld: script '" .. c_tcm_current_map.script .. "' required by map could not run: " .. err)
			end
		end
	end

	return true
end

function c_world_freeWorld()
	if not worldInitialized then
		return
	end

	c_const_restore(key)

	worldInitialized = false

	tankbobs.w_freeWorld()

	c_tcm_unload_extra_data(false)

	c_world_powerups = {}
	c_world_tanks = {}
end

function c_world_setGameType(gameType)
	if type(gameType) ~= "string" then
		c_world_gameType = gameType
	else
		local switch = gameType
		if switch == "deathmatch" then
			c_world_gameType = DEATHMATCH
		elseif switch == "domination" then
			c_world_gameType = DOMINATION
		elseif switch == "capturetheflag" then
			c_world_gameType = CAPTURETHEFLAG
		else
			c_world_gameType = DEATHMATCH
		end
	end
end

function c_world_getGameType()
	return c_world_gameType
end

function c_world_isTeamGameType(gameType)
	gameType = gameType or c_world_gameType

	if gameType == DEATHMATCH then
		return false
	elseif gameType == CHASE then
		return false
	elseif gameType == DOMINATION then
		return true
	elseif gameType == CAPTURETHEFLAG then
		return true
	else
		return false
	end
end

function c_world_setInstagib(state)
	c_world_instagib = state
end

function c_world_getInstagib(state)
	return c_world_instagib
end

function c_world_getGameTypeString(gameType)
	local gameType = "deathmatch"

	local switch = c_world_getGameType()
	if switch == DEATHMATCH then
		gameType = "deathmatch"
	elseif switch == CHASE then
		gameType = "chase"
	elseif switch == DOMINATION then
		gameType = "domination"
	elseif switch == CAPTURETHEFLAG then
		gameType = "capturetheflag"
	end

	return gameType
end

function c_world_testBody(ent)
	local p = ent.p

	if p.y > c_tcm_current_map.uppermost then
		ent.collided = true
	elseif p.y < c_tcm_current_map.lowermost then
		ent.collided = true
	elseif p.x < c_tcm_current_map.leftmost then
		ent.collided = true
	elseif p.x > c_tcm_current_map.rightmost then
		ent.collided = true
	end
end

function c_world_tank_spawn(tank)
	tank.spawning = true
end

function c_world_tank_die(tank, t)
	t = t or t_t_getTicks()

	if tank.exists and tank.body then
		tankbobs.w_removeBody(tank.body)
		tank.body = nil
	end

	c_ai_tankDie(tank)

	if tank.m.flag then
		-- drop flag
		tank.m.flag.m.pos = tankbobs.m_vec2(tank.p)
		tank.m.flag.m.dropped = true
		tank.m.flag.m.stolen = nil
		tank.m.flag = nil
	end

	tank.nextSpawnTime = t + c_world_timeMultiplier(c_const_get("tank_spawnTime"))
	if c_world_gameType == DEATHMATCH then
		if tank.killer and tank.killer ~= tank then
			tank.killer.score = tank.killer.score + 1
		else
			tank.score = tank.score - 1
		end
	end
	tank.shield = 0
	tank.killer = nil
	tank.exists = false
	tank.m.lastDieTime = t

	local tagged = false
	for _, v in pairs(c_world_tanks) do
		if v.tagged then
			tagged = true
			break
		end
	end

	if not tagged then
		-- reset timer
		for _, v in pairs(c_world_tanks) do
			tank.cd.lastChasePoint = t
		end

		-- tag the first person to die
		tank.tagged = true
	end

	c_world_tank_spawn(tank)

	tank.cd = {}
end

function c_world_tank_remove(tank)
	for k, v in pairs(c_world_tanks) do
		if v == tank then
			c_world_tanks[k] = nil
		end
	end
end

local function c_world_spawnTank(tank)
	tank.spawning = false
	tank.r = c_const_get("tank_defaultRotation")
	tank.health = c_const_get("tank_health")
	tank.shield = 0
	tank.weapon = c_weapon_getDefaultWeapon()
	tank.cd = {}

	-- find index
	local index = 1

	for k, v in pairs(c_world_tanks) do
		if v == tank then
			index = k
		end
	end

	if tank.body then
		tankbobs.w_removeBody(tank.body)
		tank.body = nil
	end

	local weapon = c_weapon_getWeapons()[tank.weapon]

	if weapon then
		tank.lastFireTime = tankbobs.t_getTicks() - c_world_timeMultiplier(weapon.repeatRate)
	else
		tank.lastFireTime = tankbobs.t_getTicks()
	end

	-- add a physical body
	tank.body = tankbobs.w_addBody(tank.p, tank.r, c_const_get("tank_canSleep"), c_const_get("tank_isBullet"), c_const_get("tank_linearDamping"), c_const_get("tank_angularDamping"), tank.h, c_const_get("tank_density"), c_const_get("tank_friction"), c_const_get("tank_restitution"), not c_const_get("tank_static"), c_const_get("tank_contentsMask"), c_const_get("tank_clipmask"), c_const_get("tank_isSensor"), index)

	c_ai_tankSpawn(tank)

	tank.exists = true
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

	-- TODO: method of preventing spawn blocking by killing blockers

	-- spawn
	tank.p(playerSpawnPoint.p)
	c_world_spawnTank(tank)

	c_world_spawnTank_misc(tank)
end

function c_world_spawnTank_misc(tank)
end

local p1a = {nil, nil, nil}
local p2a = {nil, nil, nil}
function c_world_intersection(d, p1, p2, v1, v2)
	-- test if two polygons can collide

	local p1h = {nil, nil, nil}
	local p2h = {nil, nil, nil}

	tankbobs.t_clone(p1, p1h)
	tankbobs.t_clone(p2, p2h)
	tankbobs.t_clone(p1h, p1a)
	tankbobs.t_clone(p2h, p2a)

	local lp1a = #p1a
	for k, v in pairs(p1a) do
		if k <= lp1a then
			v = v + d * v1
		else
			p1a[k] = nil
		end
	end
	local lp2a = #p2a
	for k, v in pairs(p2a) do
		if k <= lp2a then
			v = v + d * v2
		else
			p2a[k] = nil
		end
	end

	tankbobs.t_clone(p1a, p1h)
	tankbobs.t_clone(p2a, p2h)

	return tankbobs.m_polygon(p1h, p2h)
end

function c_world_pointInsideHull(p, hull)
	local c = false
	local j = #hull

	for i = 1, #hull do
		if ((hull[i].y <= p.y and p.y < hull[j].y) or (hull[j].y <= p.y and p.y < hull[i].y)) and (p.x < (hull[j].x - hull[i].x) * (p.y - hull[i].y) / (hull[j].y - hull[i].y) + hull[i].x) then
			c = not c
		end

		j = i
		i = i + 1
	end

	return c
end

function c_world_pointIntersects(p, ignoreType)
	local hull

	local function t()
		if c_world_pointInsideHull(p, hull) then
			return true
		else
			return false
		end
	end

	-- walls
	if ignoreType ~= "wall" then
		for _, v in pairs(c_tcm_current_map.walls) do
			if not v.detail then
				hull = v.m.pos

				if t() then
					return true
				end
			end
		end
	end

	-- tanks
	if ignoreType ~= "tanks" then
		for _, v in pairs(c_world_tanks) do
			if v.exists then
				hull = t_t_clone(c_world_tankHull(v))

				if t() then
					return true
				end
			end
		end
	end

	-- projectiles
	if ignoreType ~= "projectile" then
		for _, v in pairs(c_weapon_getProjectiles()) do
			if not v.collided then
				hull = c_world_projectileHull(v)

				if t() then
					return true
				end
			end
		end
	end

	-- powerups
	if ignoreType ~= "powerup" then
		for _, v in pairs(c_world_powerups) do
			if not v.collided then
				hull = c_world_powerupHull(v)

				if t() then
					return true
				end
			end
		end
	end

	return false
end

local c = nil
function c_world_tankHull(tank)
	if not c then
		c = {t_m_vec2(0, 0), t_m_vec2(0, 0), t_m_vec2(0, 0), t_m_vec2(0, 0)}
	end

	-- return a table of coordinates of tank's hull
	local p = tank.p

	for k, v in pairs(tank.h) do
		local h = t_m_vec2(v)
		h.t = h.t + tank.r
		h:add(p)
		c[k](h)
	end

	return c
end

local c = nil
function c_world_projectileHull(projectile)
	if not c then
		c = {t_m_vec2(0, 0), t_m_vec2(0, 0), t_m_vec2(0, 0), t_m_vec2(0, 0)}
	end

	local p = projectile.p

	for k, v in pairs(c_weapon_getWeapons()[projectile.weapon].projectileHull) do
		local h = t_m_vec2(v)
		h.t = h.t + projectile.r
		h:add(p)
		c[k](h)
	end

	return c
end

local c = nil
function c_world_powerupHull(powerup)
	if not c then
		c = {t_m_vec2(0, 0), t_m_vec2(0, 0), t_m_vec2(0, 0), t_m_vec2(0, 0)}
	end

	for i = 1, 4 do
		local h = t_m_vec2(c_const_get("powerup_hullx" .. tostring(i)), c_const_get("powerup_hully" .. tostring(i)))
		h.t = h.t + powerup.r
		c[i](h)
	end

	return c
end

local c = nil
function c_world_powerupSpawnPointHull(powerupSpawnPoint)
	if not c then
		c = {t_m_vec2(0, 0), t_m_vec2(0, 0), t_m_vec2(0, 0), t_m_vec2(0, 0)}
	end

	local p = powerupSpawnPoint.p

	for i = 1, 4 do
		local h = t_m_vec2(c_const_get("powerup_hullx" .. tostring(i)), c_const_get("powerup_hully" .. tostring(i)))
		--h.t = h.t
		h:add(p)
		c[i](h)
	end

	return c
end

local shape = nil
local average = nil
local offsets = nil
function c_world_wallShape(p)
	if not shape then
		shape = {t_m_vec2(0, 0), {t_m_vec2(0, 0), t_m_vec2(0, 0), t_m_vec2(0, 0), t_m_vec2(0, 0)}}

		average = shape[1]
		offsets = shape[2]
	end

	average(0, 0)

	-- walls can only have three or four vertices
	if p[4] then
		average:add(p[1])
		average:add(p[2])
		average:add(p[3])
		average:add(p[4])
		average:mul(0.25)
		if not offsets[4] then
			offsets[4] = t_m_vec2(0, 0)
		end
		offsets[1](p[1] - average)
		offsets[2](p[2] - average)
		offsets[3](p[3] - average)
		offsets[4](p[4] - average)
	else
		average:add(p[1])
		average:add(p[2])
		average:add(p[3])
		average:mul(0.3333333333333333)
		offsets[4] = nil
		offsets[1](p[1] - average)
		offsets[2](p[2] - average)
		offsets[3](p[3] - average)
	end

	return shape
end

function c_world_canPowerupSpawn(d, powerupSpawnPoint)
	-- make sure it doesn't interfere with another powerup or wall
	for _, v in pairs(c_tcm_current_map.walls) do
		if not v.detail then
			if c_world_intersection(d, c_world_powerupSpawnPointHull(powerupSpawnPoint), v.p, t_m_vec2(0, 0), v.static and t_m_vec2(0, 0) or t_w_getLinearVelocity(v.m.body)) then
				return false
			end
		end
	end

	for _, v in pairs(c_world_powerups) do
		if not v.collided then
			if c_world_intersection(d, c_world_powerupSpawnPointHull(powerupSpawnPoint), c_world_powerupHull(v), t_m_vec2(0, 0), not v.m.body and t_m_vec2(0, 0) or t_w_getLinearVelocity(v.m.body)) then
				return false
			end
		end
	end

	return true
end

function c_world_tank_canSpawn(d, tank)
	local t = t_t_getTicks()

	-- make sure the tank hasn't already spawned
	if tank.exists then
		return false
	end

	if tank.nextSpawnTime > t then
		return false
	end

	-- see if the spawn point exists
	if not c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint] then
		return false
	end

	-- set the tank's position for proper testing (this won't interfere with anything else since the exists flag isn't set)
	tank.p(c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint].p)

	-- test if spawning interferes with another tank
	for _, v in pairs(c_world_tanks) do
		if v.exists then
			if c_world_intersection(d, t_t_clone(true, c_world_tankHull(tank)), t_t_clone(c_world_tankHull(v)), t_m_vec2(0, 0), t_w_getLinearVelocity(v.body)) then
				return false
			end
		end
	end

	return true
end

function c_world_findClosestIntersection(start, endP, ignoreType)
	-- test against the world and find the closest intersection point
	-- returns false; or true, intersectionPoint, typeOfTarget, target
	local lastPoint, currentPoint = nil
	local minDistance, minIntersection, typeOfTarget, target
	local hull
	local b, intersection

	-- walls
	if ignoreType ~= "wall" then
		for _, v in pairs(c_tcm_current_map.walls) do
			if not v.detail then
				hull = v.m.pos
				local t = v
				for _, v in pairs(hull) do
					currentPoint = v
					if not lastPoint then
						lastPoint = hull[#hull]
					end

					b, intersection = tankbobs.m_edge(lastPoint, currentPoint, start, endP)
					if b and intersection then  -- FIXME: figure out why b can be true while intersection is nil
						if not minDistance then
							minIntersection = intersection
							minDistance = math.abs((intersection - start).R)
							typeOfTarget = "wall"
							target = t
						elseif math.abs((intersection - start).R) < minDistance then
							minIntersection = intersection
							minDistance = math.abs((intersection - start).R)
							typeOfTarget = "wall"
							target = t
						end
					end

					lastPoint = currentPoint
				end
				lastPoint = nil
			end
		end
	end

	-- tanks
	if ignoreType ~= "tank" then
		for _, v in pairs(c_world_tanks) do
			if v.exists then
				hull = t_t_clone(c_world_tankHull(v))
				local t = v
				for _, v in pairs(hull) do
					currentPoint = v
					if not lastPoint then
						lastPoint = hull[#hull]
					end

					b, intersection = tankbobs.m_edge(lastPoint, currentPoint, start, endP)
					if b then
						if not minDistance then
							minIntersection = intersection
							minDistance = math.abs((intersection - start).R)
							typeOfTarget = "tank"
							target = t
						elseif math.abs((intersection - start).R) < minDistance then
							minIntersection = intersection
							minDistance = math.abs((intersection - start).R)
							typeOfTarget = "tank"
							target = t
						end
					end

					lastPoint = currentPoint
				end
				lastPoint = nil
			end
		end
	end

	-- projectiles
	if ignoreType ~= "projectile" then
		for _, v in pairs(c_weapon_getProjectiles()) do
			if not v.collided then
				hull = c_world_projectileHull(v)
				local t = v
				for _, v in pairs(hull) do
					currentPoint = v
					if not lastPoint then
						lastPoint = hull[#hull]
					end

					b, intersection = tankbobs.m_edge(lastPoint, currentPoint, start, endP)
					if b then
						if not minDistance then
							minIntersection = intersection
							minDistance = math.abs((intersection - start).R)
							typeOfTarget = "projectile"
							target = t
						elseif math.abs((intersection - start).R) < minDistance then
							minIntersection = intersection
							minDistance = math.abs((intersection - start).R)
							typeOfTarget = "projectile"
							target = t
						end
					end

					lastPoint = currentPoint
				end
				lastPoint = nil
			end
		end
	end

	-- powerups

	return minDistance, minIntersection, typeOfTarget, target
end

-- note: client-side prediction probably doesn't belong here by itself, but this code is going to be shared in a server-side unlagged implementation in the future.

local tankStepAhead = nil
local record = true
local history = nil
local lastHistoryIndex = 0
function c_world_tank_setStepAhead(tank)
	tankStepAhead = tank

	if not history then
		history = {}  -- {time, state}

		for i = 1, c_config_get("client.histSize") do
			table.insert(history, {0, 0})
		end
	end
end

local ignoreTank = nil
function c_world_tank_setIgnore(tank)
	ignoreTank = tank
end

-- step ahead (ahead / forward only)
function c_world_tank_stepAhead(fromTime, toTime)
	local tank = tankStepAhead

	if not tank then
		return
	end

	if lastHistoryIndex < 1 then
		return
	end

	record = false

	local state = tank.state

	local from, to
	local i = lastHistoryIndex
	local test = lastHistoryIndex + 1

	if lastHistoryIndex == c_config_get("client.histSize") then
		test = i
		i = i - 1
	end

	while i ~= test do
		local h = history[i]

		if not to and h[1] <= toTime then
			to = i
		end

		if h[1] <= fromTime then
			from = i
		end

		if to and from then
			break
		end

		i = i - 1

		if i < 1 then
			i = c_config_get("client.histSize")
		end
	end

	if from and to then
		-- step tank from "from" to "to"
		i = from
		if i >= c_config_get("client.histSize") then
			i = 1
		end
		to = to - 1
		if to < 1 then
			to = c_config_get("client.histSize")
		end
		while(i ~= to) do
			local breaking = false repeat
				tank.state = history[i][2]
				local length = (history[i + 1][1] - history[i][1]) / (c_world_timeMultiplier())
				if length <= 0 then
					length = 1.0E-6  -- inaccurate guess
				end
				c_world_tank_step(length, tank)

				i = i + 1
				if i >= c_config_get("client.histSize") then
					if to ~= i then
						i = 1
					end
				end
			until true if breaking then break end
		end
	end


	tank.state = state

	record = true
end

function c_world_tank_step(d, tank)
	local t = t_t_getTicks()

	c_world_tank_checkSpawn(d, tank)

	if tank.collided then
		-- tank somehow escaped world bounds

		tank.collided = false

		return c_world_tank_die(tank)
	else
		--c_world_testBody(tank)
	end

	if not tank.exists then
		return
	end

	if tank.health <= 0 then
		return c_world_tank_die(tank, t)
	end

	if record and tank == tankStepAhead and history then
		-- don't record input multiple times in the same frame
		if lastHistoryIndex == 0 or t ~= history[lastHistoryIndex][1] then
			local h

			lastHistoryIndex = lastHistoryIndex + 1
			if lastHistoryIndex > c_config_get("client.histSize") then
				lastHistoryIndex = 1
			end

			h = history[lastHistoryIndex]

			h[1] = t
			h[2] = tank.state
		end
	end

	tank.p(t_w_getPosition(tank.body))

	if c_world_gameType == CHASE then
		-- search for another tagged player
		local tagged = false
		for _, v in pairs(c_world_tanks) do
			if v.tagged then
				tagged = true
				break
			end
		end

		if not tank.cd.lastChasePoint then
			tank.cd.lastChasePoint = t
		elseif tank.cd.lastChasePoint + c_world_timeMultiplier(c_const_get("game_chasePointTime")) <= t and not tank.tagged and tagged then
			-- reward a point every 10 seconds alive while not tagged
			tank.cd.lastChasePoint = t
			tank.score = tank.score + 1
		end
	end

	local vel = t_w_getLinearVelocity(tank.body)

	-- ignore movement for designated tanks
	local skip = false
	if tank == ignoreTank then
		if tank.cd.init then
			skip = true
		else
			tank.cd.init = true
		end
	end

	if not skip then
		if bit.band(tank.state, SPECIAL) ~= 0 then
			if bit.band(tank.state, LEFT) ~= 0 then
				if vel.R < 0 then  -- inverse rotation
					tank.r = tank.r - tank_rotationSpeed * vel.R / tank_rotationSpecialSpeed
				else
					tank.r = tank.r + tank_rotationSpeed * vel.R / tank_rotationSpecialSpeed
				end
			end

			if bit.band(tank.state, RIGHT) ~= 0 then
				if vel.R < 0 then  -- inverse rotation
					tank.r = tank.r + tank_rotationSpeed * vel.R / tank_rotationSpecialSpeed
				else
					tank.r = tank.r - tank_rotationSpeed * vel.R / tank_rotationSpecialSpeed
				end
			end

			vel.t = tank.r

			t_w_setLinearVelocity(tank.body, vel)

			if bit.band(tank.state, BACK) ~= 0 then
				tank.state = bit.bor(tank.state, REVERSE)
			else
				tank.state = bit.band(tank.state, bit.bnot(REVERSE))
			end
		else
			if bit.band(tank.state, FORWARD) ~= 0 or bit.band(tank.state, BACK) ~= 0 then
				if bit.band(tank.state, FORWARD) ~= 0 then
					-- determine the acceleration
					local acceleration
					local speedK = tank_speedK

					for _, v in pairs(tank_acceleration) do  -- local copy of table for optimization
						if v[2] then
							if vel.R >= v[2] * speedK then
								acceleration = v[1]
							end
						elseif not acceleration then
							acceleration = v[1] * speedK
						end
					end

					if tank.cd.acceleration then
						acceleration = acceleration * c_const_get("tank_accelerationModifier")
					end

					local newVel = t_m_vec2(vel)
					newVel.R = newVel.R + acceleration
					newVel.t = tank.r
					if vel.R >= tank_rotationChangeMinSpeed * speedK then
						-- interpolate in the correct direction
						vel.t    = math.fmod(vel.t, 2 * math.pi)
						newVel.t = math.fmod(newVel.t, 2 * math.pi)
						if        vel.t - newVel.t > math.pi then
							vel.t    =    vel.t - 2 * math.pi
						elseif newVel.t -    vel.t > math.pi then
							newVel.t = newVel.t - 2 * math.pi
						end
						newVel.t = common_lerp(vel.t, newVel.t, tank_rotationChange)
					end

					t_w_setLinearVelocity(tank.body, newVel)
					vel(newVel)
				end
				if bit.band(tank.state, BACK) ~= 0 then
					if bit.band(tank.state, REVERSE) ~= 0 and vel.R <= c_const_get("tank_decelerationMaxSpeed") then
						-- reverse

						local addVel = t_m_vec2()
						addVel.R = c_const_get("tank_deceleration")
						addVel.t = tank.r + math.pi
						vel:add(addVel)
						t_w_setLinearVelocity(tank.body, vel)
					else
						-- break

						local newVel = t_m_vec2(vel)

						if newVel.R > 0 then
							newVel.R = newVel.R - c_const_get("tank_deceleration")
						end

						t_w_setLinearVelocity(tank.body, newVel)
						vel(newVel)
					end
				else
					tank.state = bit.band(tank.state, bit.bnot(REVERSE))
				end
			else
				local v = t_w_getLinearVelocity(tank.body)

				v.R = v.R / (1 + tank_worldFriction)
				t_w_setLinearVelocity(tank.body, v)

				tank.state = bit.band(tank.state, bit.bnot(REVERSE))
			end

			if bit.band(tank.state, LEFT) ~= 0 then
				tank.r = tank.r + tank_rotationSpeed
			end

			if bit.band(tank.state, RIGHT) ~= 0 then
				tank.r = tank.r - tank_rotationSpeed
			end
		end
	end

	t_w_setAngle(tank.body, tank.r)

	t_w_setAngularVelocity(tank.body, 0)  -- reset the tank's angular velocity

	-- weapons
	c_weapon_fire(tank)

	if tank.bot then
		c_ai_tank_step(tank)
	end
end

function c_world_wall_step(d, wall)
	local t = t_t_getTicks()
	local paths = c_tcm_current_map.paths

	if wall.detail or not wall.m.body then
		return
	end

	if wall.static then
		-- test if the wall is linked to a path
		if wall.path then
			if not wall.m.pid then
				wall.m.pid = wall.pid
				wall.m.ppos = 0
				wall.m.startpos = t_m_vec2(c_world_wallShape(wall.m.pos)[1])
			else
				local path = paths[wall.m.pid + 1]

				if path and path.enabled then
					local prevPath = paths[wall.m.ppid]

					if prevPath then
						if prevPath.time == 0 then
							wall.m.ppos = 1
						else
							wall.m.ppos = math.min(1, wall.m.ppos + (d / prevPath.time))
						end
					end

					if wall.m.ppos < 1 and prevPath then
						tankbobs.w_setPosition(wall.m.body, common_lerp(wall.m.startpos, wall.m.startpos + path.p - prevPath.p, wall.m.ppos))
					else
						wall.m.ppid = wall.m.pid + 1
						prevPath = paths[wall.m.ppid]
						wall.m.startpos(c_world_wallShape(wall.m.pos)[1])
						wall.m.pid = path.t
						path = paths[wall.m.pid + 1]
						wall.m.ppos = 0

						tankbobs.w_setPosition(wall.m.body, wall.m.startpos + path.p - prevPath.p)
					end
				end
			end

			t_w_getVertices(wall.m.body, wall.m.pos)
			local offset = t_w_getPosition(wall.m.body)
			local angle = t_w_getAngle(wall.m.body)
			for _, v in pairs(wall.m.pos) do
				v.t = v.t + angle
				v:add(offset)
			end
		end
	else
		t_w_getVertices(wall.m.body, wall.m.pos)
		local offset = t_w_getPosition(wall.m.body)
		local angle = t_w_getAngle(wall.m.body)
		for _, v in pairs(wall.m.pos) do
			v.t = v.t + angle
			v:add(offset)
		end
	end
end

function c_world_projectile_step(d, projectile)
	if projectile.collided then
		tankbobs.w_removeBody(projectile.m.body)
		c_weapon_projectileRemove(projectile)
		return
	end

	c_world_testBody(projectile)

	projectile.p(t_w_getPosition(projectile.m.body))
	projectile.r = t_w_getAngle(projectile.m.body)
end

function c_world_spawnPowerup(powerup, index)
	powerup.m.body = tankbobs.w_addBody(powerup.p, 0, c_const_get("powerup_canSleep"), c_const_get("powerup_isBullet"), c_const_get("powerup_linearDamping"), c_const_get("powerup_angularDamping"), c_world_powerupHull(powerup), c_const_get("powerup_density"), c_const_get("powerup_friction"), c_const_get("powerup_restitution"), not c_const_get("powerup_static"), c_const_get("powerup_contentsMask"), c_const_get("powerup_clipmask"), c_const_get("powerup_isSensor"), index)
end

function c_world_powerupSpawnPoint_step(d, powerupSpawnPoint)
	local t = t_t_getTicks()
	local spawn = false

	if powerupSpawnPoint.linked then
		if not lastPowerupSpawnTime then
			lastPowerupSpawnTime = t + c_world_timeMultiplier(powerupSpawnPoint.initial) - c_world_timeMultiplier(powerupSpawnPoint["repeat"])
		end

		if not nextPowerupSpawnPoint or powerupSpawnPoint == nextPowerupSpawnPoint then
			if t >= lastPowerupSpawnTime + c_world_timeMultiplier(powerupSpawnPoint["repeat"]) then
				lastPowerupSpawnTime = t
				spawn = true

				local found   = false
				local current = false
				for k, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
					if current then
						nextPowerupSpawnPoint = v
						found = true

						break
					elseif v == powerupSpawnPoint then
						current = true
					end
				end
				if not found then
					nextPowerupSpawnPoint = c_tcm_current_map.powerupSpawnPoints[1] or powerupSpawnPoint  -- should never choose the latter, but better to be safe than break the system
				end
			end
		end
	else
		spawn = t >= powerupSpawnPoint.m.nextPowerupTime
	end

	if spawn then
		powerupSpawnPoint.m.nextPowerupTime = t + c_world_timeMultiplier(powerupSpawnPoint["repeat"])

		if c_world_canPowerupSpawn(d, powerupSpawnPoint) then
			-- make sure there's not too many powerups
			local count = #c_world_powerups
			local max = c_const_get("world_maxPowerups")

			if max and max > 0 then
				while count > max do
					count = count - 1

					local powerup = c_world_powerups[#c_world_powerups - count]
					if powerup then
						powerup.collided = true
					end
				end
			end

			-- spawn a powerup
			local powerup = c_world_powerup:new()

			local index = 0
			for k, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
				if v == index then
					index = k
				end
			end

			powerup.spawner = index

			powerup.powerupType = nil

			local found = false
			for k, v in pairs(powerupSpawnPoint.enabledPowerups) do
				if v then
					if found then
						if c_world_getPowerupTypeByName(k) and (not c_world_getInstagib() or c_world_getPowerupTypeByName(k).instagib) then
							powerupSpawnPoint.m.lastPowerup = k
							powerup.powerupType = c_world_getPowerupTypeByName(k).index
							break
						end
					end
	
					if k == powerupSpawnPoint.m.lastPowerup then
						found = true
					end
				end
			end
			if not powerup.powerupType then
				for k, v in pairs(powerupSpawnPoint.enabledPowerups) do
					if v then
						if found then
							if c_world_getPowerupTypeByName(k) and (not c_world_getInstagib() or c_world_getPowerupTypeByName(k).instagib) then
								powerupSpawnPoint.m.lastPowerup = k
								powerup.powerupType = c_world_getPowerupTypeByName(k).index 
								break
							end
						end
					end
				end
			end
			if not powerup.powerupType then
				return
			else
				table.insert(c_world_powerups, powerup)
			end

			powerup.spawnTime = t

			powerup.p(powerupSpawnPoint.p)

			-- find index
			local index = 1

			for k, v in pairs(c_world_powerups) do
				if v == powerup then
					index = k
				end
			end

			c_world_spawnPowerup(powerup, index)

			-- add some initial push to the powerup
			local push = t_m_vec2()
			push.R = c_const_get("powerup_pushStrength")
			push.t = c_const_get("powerup_pushAngle")
			t_w_setLinearVelocity(powerup.m.body, push)

			c_tcm_current_map.powerupSpawnPoints[1].m.lastSpawnTime = worldTime
		end
	end
end

function c_world_powerupRemove(powerup)
	for k, v in pairs(c_world_powerups) do
		if v == powerup then
			c_world_powerups[k] = nil
		end
	end
end

function c_world_powerup_pickUp(tank, powerup)
	if not powerup or powerup.collided then
		return
	end

	local t = t_t_getTicks()
	local powerupType = c_world_getPowerupTypeByIndex(powerup.powerupType)

	powerup.collided = true

	tank.m.lastPickupTime = t

	if powerupType.name == "machinegun" then
		c_weapon_pickUp(tank, powerupType.name)
	end
	if powerupType.name == "shotgun" then
		c_weapon_pickUp(tank, powerupType.name)
	end
	if powerupType.name == "railgun" then
		c_weapon_pickUp(tank, powerupType.name)
	end
	if powerupType.name == "coilgun" then
		c_weapon_pickUp(tank, powerupType.name)
	end
	if powerupType.name == "saw" then
		c_weapon_pickUp(tank, powerupType.name)
	end
	if powerupType.name == "ammo" then
		tank.clips = tank.clips + c_weapon_getWeapons()[tank.weapon].clips
	end
	if powerupType.name == "aim-aid" then
		tank.cd.aimAid = not tank.cd.aimAid
	end
	if powerupType.name == "health" then
		tank.health = tank.health + c_const_get("tank_boostHealth")
	end
	if powerupType.name == "acceleration" then
		tank.cd.acceleration = not tank.cd.acceleration
	end
	if powerupType.name == "shield" then
		tank.shield = tank.shield + c_const_get("tank_boostShield")
	end
end

function c_world_powerup_step(d, powerup)
	local t = t_t_getTicks()

	if powerup.collided then
		tankbobs.w_removeBody(powerup.m.body)
		c_world_powerupRemove(powerup)
		return
	end

	c_world_testBody(powerup)

	if t > powerup.spawnTime + c_world_timeMultiplier(c_const_get("powerup_lifeTime")) and c_const_get("powerup_lifeTime") > 0 then
		powerup.collided = true
	end

	powerup.p(t_w_getPosition(powerup.m.body))
	--t_w_setAngle(powerup.m.body, 0)  -- looks better with dynamic rotation
	powerup.r = t_w_getAngle(powerup.m.body)

	-- keep powerup velocity constant
	local vel = t_w_getLinearVelocity(powerup.m.body)
	vel.R = c_const_get("powerup_pushStrength")
	t_w_setLinearVelocity(powerup.m.body, vel)

	if c_config_get("game.ept") then
		for _, v in pairs(c_world_tanks) do
			if v.exists then
				if c_world_intersection(d, c_world_powerupHull(powerup), c_world_tankHull(v), t_m_vec2(0, 0), t_w_getLinearVelocity(v.body)) then
					c_world_powerup_pickUp(v, powerup)
				end
			end
		end
	end
end

function c_world_controlPoint_step(d, controlPoint)
	if c_world_gameType ~= DOMINATION then
		return
	end

	local t = t_t_getTicks()

	local balance = 0
	local num = 0

	for _, v in pairs(c_world_tanks) do
		if v.exists then
			-- inexpensive distance check
			if math.abs((v.p - controlPoint.p).R) <= c_const_get("controlPoint_touchDistance") then
				balance = balance + (v.red and (1) or (-1))
				num = num + 1
			end
		end
	end

	if balance > 0 then
		controlPoint.m.nextPointTime = nil

		controlPoint.m.team = "red"
	elseif balance < 0 then
		controlPoint.m.nextPointTime = nil

		controlPoint.m.team = "blue"
	elseif num > 0 then
		controlPoint.m.team = nil
	end

	if controlPoint.m.team then
		if controlPoint.m.nextPointTime then
			while t >= controlPoint.m.nextPointTime do
				if controlPoint.m.team == "red" then
					c_world_redTeam.score = c_world_redTeam.score + 1
				else
					c_world_blueTeam.score = c_world_blueTeam.score + 1
				end

				controlPoint.m.nextPointTime = controlPoint.m.nextPointTime + c_world_timeMultiplier(c_const_get("controlPoint_rate"))
			end
		else
			controlPoint.m.nextPointTime = t + c_world_timeMultiplier(c_const_get("controlPoint_rate"))
		end
	end
end

function c_world_flag_step(d, flag)
	if c_world_gameType ~= CAPTURETHEFLAG then
		return
	end

	local t = t_t_getTicks()

	local p = flag.m.dropped and flag.m.pos or flag.p
	for k, v in pairs(c_world_tanks) do
		if v.exists then
			-- inexpensive distance check
			if math.abs((v.p - p).R) <= c_const_get("flag_touchDistance") then
				if not flag.m.dropped then
					if not flag.m.stolen then
						if v.red ~= flag.red then
							-- flag was stolen

							v.m.flag = flag

							flag.m.stolen = k
							flag.m.dropped = false  -- redundant, but just in case

							flag.m.lastPickupTime = t
						elseif v.m.flag and v.red == flag.red then
							-- flag was captured

							if flag.red then
								c_world_redTeam.score = c_world_redTeam.score + 1
							else
								c_world_blueTeam.score = c_world_blueTeam.score + 1
							end

							flag.m.lastCaptureTime = t

							-- silently return flag
							v.m.flag.m.stolen = nil
							v.m.flag = nil
						end
					end
				else
					if v.red == flag.red then
						-- return flag

						flag.m.dropped = false
						flag.m.stolen = nil  -- redundant, but just in case

						flag.m.lastReturnTime = t
					else
						-- other player picked up flag

						v.m.flag = flag

						flag.m.dropped = false
						flag.m.stolen = k

						flag.m.lastPickupTime = t
					end
				end

				return
			end
		end
	end
end

function c_world_teleporter_step(d, teleporter)
	local teleporters = c_tcm_current_map.teleporters

	for _, v in pairs(c_world_tanks) do
		if v.exists then
			-- inexpensive distance check
			if math.abs((v.p - teleporter.p).R) <= c_const_get("teleporter_touchDistance") then
				local target = teleporters[teleporter.t + 1]

				if teleporter.enabled and target and v.m.target ~= teleporter.id then
					for _, v in pairs(c_world_tanks) do
						if v.exists then
							if math.abs((v.p - target.p).R) <= c_const_get("teleporter_touchDistance") then
								return
							end
						end
					end
					-- test for rest of world
					if c_world_pointIntersects(teleporter.p) then
						return
					end

					v.m.target = target.id
					v.m.lastTeleportTime = t_t_getTicks()
					tankbobs.w_setPosition(v.body, target.p)
					v.p(tankbobs.w_getPosition(v.body))
				end

				return
			elseif v.m.target == teleporter.id then
				v.m.target = nil
			end
		end
	end

	-- Don't handle powerups and projectiles
end

function c_world_isWall(body)
	if tankbobs.w_getContents(body) == WALL then
		return c_tcm_current_map.walls[tankbobs.w_getIndex(body)]
	end

	return nil
end

function c_world_isTank(body)
	if tankbobs.w_getContents(body) == TANK then
		return c_world_tanks[tankbobs.w_getIndex(body)]
	end

	return nil
end

function c_world_isProjectile(body)
	if tankbobs.w_getContents(body) == PROJECTILE then
		return c_weapon_getProjectiles()[tankbobs.w_getIndex(body)]
	end

	return nil
end

function c_world_isPowerup(body)
	if tankbobs.w_getContents(body) == POWERUP then
		return c_world_powerups[tankbobs.w_getIndex(body)]
	end

	return nil
end

function c_world_tankDamage(tank, damage)
	if tank.shield > 0 then
		tank.health = tank.health - c_const_get("tank_shieldedDamage") * damage
		tank.shield = tank.shield - c_const_get("tank_shieldDamage") * damage
	else
		tank.health = tank.health - damage
	end
end

local c_world_tankDamage = c_world_tankDamage
local function c_world_collide(tank, normal)
	local vel = t_w_getLinearVelocity(tank.body)
	local component = vel * -normal

	if not c_world_getInstagib() and tank.shield <= 0 then
		-- no collision damage in instagib mode or if any of the shield remains
		if component >= c_const_get("tank_damageMinSpeed") then
			local damage = c_const_get("tank_damageK") * (component - c_const_get("tank_damageMinSpeed"))

			if damage >= c_const_get("tank_collideMinDamage") then
				c_world_tankDamage(tank, damage)
			end
		end
	end

	tank.m.lastCollideTime = t_t_getTicks()
	tank.m.intensity = component / c_const_get("tank_intensityMaxSpeed")
	if tank.m.intensity > 1 then
		tank.m.intensity = 1
	end
end

function c_world_contactListener(shape1, shape2, body1, body2, position, separation, normal)
	local b, p
	local powerup = false

	if c_world_isPowerup(body1) or c_world_isPowerup(body2) then
		local tank = c_world_isTank(body1)
		local tank2 = c_world_isTank(body2)

		if tank then
			c_world_powerup_pickUp(tank, c_world_isPowerup(body2))
		elseif tank2 then
			c_world_powerup_pickUp(tank2, c_world_isPowerup(body1))
		end

		powerup = true
	end

	if c_world_isProjectile(body1) or c_world_isProjectile(body2) then
		-- remove the projectile
		local projectile, projectile2

		projectile = c_world_isProjectile(body1)
		projectile2 = c_world_isProjectile(body2)

		-- test if the projectile hit a tank
		local tank, tank2

		tank = c_world_isTank(body1)
		tank2 = c_world_isTank(body2)

		-- only one of them can be a tank (and if one of them is, only one them can be a projectile)
		if tank then
			if projectile then
				c_weapon_hit(tank, projectile)
			else
				c_weapon_hit(tank, projectile2)
			end
		elseif tank2 then
			if projectile then
				c_weapon_hit(tank2, projectile)
			else
				c_weapon_hit(tank2, projectile2)
			end
		end

		-- this must be after the weapon hits the tank
		if projectile then
			c_weapon_projectileCollided(projectile, body2)
		end

		if projectile2 then
			c_weapon_projectileCollided(projectile2, body1)
		end
	elseif c_world_isTank(body1) or c_world_isTank(body2) then
		local tank, tank2

		tank = c_world_isTank(body1)
		tank2 = c_world_isTank(body2)

		if not powerup then
			if tank then
				c_world_collide(tank, normal)
			end

			if tank2 then
				c_world_collide(tank2, normal)
			end
		end
	end

	if c_world_gameType == CHASE then
		-- tag another player
		if c_world_isTank(body1) and c_world_isTank(body2) then
			local tank, tank2 = c_world_isTank(body1), c_world_isTank(body2)

			local taggedTank, otherTank = nil, nil

			if tank.tagged then
				taggedTank, otherTank = tank, tank2
			elseif tank2.tagged then
				taggedTank, otherTank = tank2, tank
			end

			if taggedTank and otherTank then
				if not taggedTank.m.tagProtection or taggedTank.m.tagProtection < t_t_getTicks() then
					taggedTank.cd.lastChasePoint = t_t_getTicks()
					taggedTank.tagged = false
					otherTank.tagged = true
					otherTank.m.tagProtection = t_t_getTicks() + c_world_timeMultiplier(c_const_get("game_tagProtection"))
				end
			end
		end
	end
end

local function c_world_private_resetWorldTimers(t)
	t = t or t_t_getTicks()

	worldTime = t_t_getTicks()

	for _, v in pairs(c_world_tanks) do
		if v.lastFireTime then
			v.lastFireTime = t
		end

		if v.nextSpawnTime then
			v.nextSpawnTime = t + c_world_timeMultiplier(c_const_get("tank_spawnTime"))
		end

		if v.cd.lastChasePoint then
			v.cd.lastChasePoint = t
		end

		if v.bot then
			for _, v in pairs(v.ai.objectives) do
				if v.nextPathUpdateTime then
					v.nextPathUpdateTime = t
				end
			end

			v.ai.lastEnemySightedTime = t
		end
	end

	for _, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
		if v.m.nextPowerupTime then
			v.m.nextPowerupTime = t + c_world_timeMultiplier(c_const_get("powerupSpawnPoint_initialPowerupTime"))
		end
	end

	for _, v in pairs(c_world_powerups) do
		v.spawnTime = t
	end

	for _, v in pairs(c_tcm_current_map.controlPoints) do
		if v.m.nextPointTime then
			v.m.nextPointTime = t
		end
	end

	lastPowerupSpawnTime = nil
	nextPowerupSpawnPoint = nil
end

local function c_world_private_offsetWorldTimers(d)
	worldTime = t_t_getTicks()

	for _, v in pairs(c_world_tanks) do
		if v.lastFireTime then
			v.lastFireTime = v.lastFireTime + d
		end

		if v.nextSpawnTime then
			v.nextSpawnTime = v.nextSpawnTime + d
		end

		if v.cd.lastChasePoint then
			v.cd.lastChasePoint = v.cd.lastChasePoint + d
		end

		if v.bot then
			for _, v in pairs(v.ai.objectives) do
				if v.nextPathUpdateTime then
					v.nextPathUpdateTime = v.nextPathUpdateTime + d
				end
			end

			v.ai.lastEnemySightedTime = v.ai.lastEnemySightedTime + d
		end
	end

	for _, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
		if v.m.nextPowerupTime then
			v.m.nextPowerupTime = v.m.nextPowerupTime + d
		end
	end

	for _, v in pairs(c_world_powerups) do
		v.spawnTime = v.spawnTime + d
	end

	for _, v in pairs(c_tcm_current_map.controlPoints) do
		if v.m.nextPointTime then
			v.m.nextPointTime = v.m.nextPointTime + d
		end
	end

	if lastPowerupSpawnTime then
		lastPowerupSpawnTime = lastPowerupSpawnTime + d
	end
end

function c_world_timeWrapped()
	-- this is called whenever the time wraps
	return c_world_private_resetWorldTimers()
end

local paused = false

function c_world_setPaused(set)
	paused = set
end

function c_world_getPaused()
	return paused
end

function c_world_setTimeStep(x)
	tankbobs.w_setTimeStep(x)
end

function c_world_setTimeStep()
	return tankbobs.w_getTimeStep()
end

function c_world_setIterations(x)
	tankbobs.w_setIterations(x)
end

function c_world_setIterations()
	return tankbobs.w_getIterations()
end

local timeStep = 0
function c_world_step(d)
	local t = t_t_getTicks()
	local f = 1 / (c_world_timeMultiplier())
	local wd = common_FTM(c_const_get("world_fps")) * f

	worldTime = worldTime - timeStep
	timeStep = 0

	if worldInitialized then
		if paused then
			c_world_private_offsetWorldTimers(d * 1000)
		else
			while worldTime < t do
				if c_world_isBehind() then
					c_world_resetBehind()

					break
				end

				tankbobs.w_luaStep(wd)

				--[[
				for _, v in pairs(c_world_tanks) do
					c_world_tank_step(wd, v)
				end

				for _, v in pairs(c_tcm_current_map.walls) do
					c_world_wall_step(wd, v)
				end

				for _, v in pairs(c_weapon_getProjectiles()) do
					c_world_projectile_step(wd, v)
				end

				for _, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
					c_world_powerupSpawnPoint_step(wd, v)
				end

				for _, v in pairs(c_world_powerups) do
					c_world_powerup_step(wd, v)
				end

				for _, v in pairs(c_tcm_current_map.controlPoints) do
					c_world_controlPoint_step(wd, v)
				end

				for _, v in pairs(c_tcm_current_map.flags) do
					c_world_flag_step(wd, v)
				end

				for _, v in pairs(c_tcm_current_map.teleporters) do
					c_world_teleporter_step(wd, v)
				end
				--]]

				tankbobs.w_step()

				worldTime = worldTime + common_FTM(c_const_get("world_fps"))
			end
		end
	end
end

function c_world_getWorldTime()
end

function c_world_isBehind()
	if t_t_getTicks() - worldTime > behind then
		return true
	end
end

function c_world_resetBehind()
	worldTime = t_t_getTicks()
end

function c_world_stepTime(t)
	timeStep = t
end

function c_world_getTanks()
	return c_world_tanks
end

function c_world_getPowerups()
	return c_world_powerups
end

function c_world_timeMultiplier(v)
	if v then
		return c_const_get("world_time") * c_config_get("game.timescale") * v
	else
		return c_const_get("world_time") * c_config_get("game.timescale")
	end
end
