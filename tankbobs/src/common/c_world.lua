--[[
Copyright (C) 2008-2010 Byron James Johnson

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
local tankbobs                = tankbobs
local t_w_setAngle            = nil
local t_w_getAngle            = nil
local t_w_getPosition         = nil
local t_w_getVertices         = nil
local t_w_getContents         = nil
local t_w_getBodyVertices     = nil
local t_w_getBodyContents     = nil
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
local c_world_corpse_step
local c_world_tanks
local c_world_powerups
local c_world_corpses
local tank_acceleration
local tank_rotationSpeed
local tank_slowRotationSpeed
local tank_rotationSpecialFactor
local tank_slowRotationSpecialFactor
local tank_rotationChange
local tank_rotationChangeMinSpeed
local tank_worldFriction
local c_world_testBody
local behind

local worldTime = 0
local lastWorldTime = 0
local c_world_instagib = false
local lastPowerupSpawnTime
local nextPowerupSpawnPoint
local worldInitialized = false
local zoom = 0

local key = {}

function c_world_init()
	c_config_set            = _G.c_config_set
	c_config_get            = _G.c_config_get
	c_const_set             = _G.c_const_set
	c_const_get             = _G.c_const_get
	c_weapon_getProjectiles = _G.c_weapon_getProjectiles
	common_FTM              = _G.common_FTM
	common_lerp             = _G.common_lerp
	tankbobs                = _G.tankbobs
	t_w_setAngle            = _G.tankbobs.w_setAngle
	t_w_getAngle            = _G.tankbobs.w_getAngle
	t_w_getPosition         = _G.tankbobs.w_getPosition
	t_w_getVertices         = _G.tankbobs.w_getVertices
	t_w_getContents         = _G.tankbobs.w_getContents
	t_w_getBodyVertices     = _G.tankbobs.w_getBodyVertices
	t_w_getBodyContents     = _G.tankbobs.w_getBodyContents
	t_t_getTicks            = _G.tankbobs.t_getTicks
	t_t_clone               = _G.tankbobs.t_clone
	t_m_vec2                = _G.tankbobs.m_vec2
	t_w_getLinearVelocity   = _G.tankbobs.w_getLinearVelocity
	t_w_setLinearVelocity   = _G.tankbobs.w_setLinearVelocity
	t_w_setAngularVelocity  = _G.tankbobs.w_setAngularVelocity

	bit = c_module_load "bit"

	c_config_cheat_protect("game.timescale")

	c_const_set("world_time", 1000)  -- relative to change in seconds
	c_const_set("world_unitScale", 1)
	c_const_set("world_speed", 1)

	c_const_set("world_fps", c_config_get("game.worldFPS"))  -- physics FPS needs to be constant
	c_const_set("world_timeStep", 1 / c_const_get("world_fps"))
	c_const_set("world_iterations", 16)

	c_const_set("wall_contentsMask", WALL, 1)
	c_const_set("wall_clipmask",          WALL + POWERUP + TANK + PROJECTILE + CORPSE, 1)
	c_const_set("wall_isSensor", false, 1)
	c_const_set("powerup_contentsMask", POWERUP, 1)
	c_const_set("powerup_clipmask",       WALL + TANK + POWERUP, 1)
	c_const_set("powerup_isSensor", false, 1)
	c_const_set("tank_contentsMask", TANK, 1)
	c_const_set("tank_clipmask",          WALL + POWERUP + TANK + PROJECTILE + CORPSE, 1)
	c_const_set("tank_isSensor", false, 1)
	c_const_set("projectile_contentsMask", PROJECTILE, 1)
	c_const_set("projectile_clipmask" ,   WALL + TANK + PROJECTILE + CORPSE, 1)
	c_const_set("projectile_isSensor", false, 1)
	c_const_set("corpse_contentsMask",  CORPSE, 1)
	c_const_set("corpse_clipmask",        WALL + POWERUP + TANK + PROJECTILE + CORPSE, 1)
	c_const_set("corpse_isSensor", false, 1)

	c_const_set("world_behind", 5000, 1)  -- in ms (compared directly against SDL_GetTicks()
	behind = c_const_get("world_behind")

	c_const_set("world_timeWrapTest", -99999)

	c_const_set("world_lowerbound", t_m_vec2(-5, -5), 1)
	c_const_set("world_upperbound", t_m_vec2(5, 5), 1)

	c_const_set("world_gravityx", 0, 1) c_const_set("world_gravityy", 0, 1)
	c_const_set("world_allowSleep", true, 1)

	c_const_set("world_maxPowerups", 64, 1)

	c_const_set("world_corpseTime", 3, 1)
	c_const_set("world_corpsePostTime", 0.5, 1)  -- corpses exists for some time after explosion
	c_const_set("world_minimumCorpseTimeForDeathNoiseAndStuff", 0.2, 1)  -- don't play noise if corpses explode before this value
	c_const_set("world_corpseExplodeDamage", 80, 1)
	c_const_set("world_corpseExplodeKnockback", 64, 1)
	c_const_set("world_corpseExplodeRadius", 25, 1)
	c_const_set("world_corpseExplodeRadiusReduce", 1.2, 1)

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
	c_const_set("powerup_pushStrength", 32, 1)
	c_const_set("powerup_pushAngle", CIRCLE / 8, 1)
	c_const_set("powerup_static", false, 1)

	c_const_set("game_chasePointTime", 10, 1)
	c_const_set("game_tagProtection", 0.2, 1)

	-- hull of tank facing right
	c_const_set("tank_hullx1", -2.0, 1) c_const_set("tank_hully1",  2.0, 1)
	c_const_set("tank_hullx2", -2.0, 1) c_const_set("tank_hully2", -2.0, 1)
	c_const_set("tank_hullx3",  2.0, 1) c_const_set("tank_hully3", -1.0, 1)
	c_const_set("tank_hullx4",  2.0, 1) c_const_set("tank_hully4",  1.0, 1)
	c_const_set("tank_health", 100, 1)
	c_const_set("tank_damageK", 2, 1)  -- damage relative to speed before a collision: 2 hp / 1 ups after 
	c_const_set("tank_damageMinSpeed", 12, 1)
	c_const_set("tank_intensityMaxSpeed", 6, 1)
	c_const_set("tank_collideMinDamage", 5, 1)
	c_const_set("tank_reverse", 16, 1)
	c_const_set("tank_deceleration", 64, 1)
	c_const_set("tank_decelerationMaxSpeed", 48, 1)
	c_const_set("tank_highHealth", 66, 1)
	c_const_set("tank_lowHealth", 33, 1)
	c_const_set("tank_acceleration",
	{
		{48},
		{16, 32},
		{12, 48},
	}, 1)
	tank_acceleration = c_const_get("tank_acceleration")
	tank_speedK = c_const_get("tank_speedK")
	c_const_set("tank_density", 2, 1)
	c_const_set("tank_friction", 0.25, 1)
	c_const_set("tank_worldFriction", 0.5, 1)  -- damping
	tank_worldFriction = c_const_get("tank_worldFriction")
	c_const_set("tank_restitution", 0.4, 1)
	c_const_set("tank_canSleep", false, 1)
	c_const_set("tank_isBullet", true, 1)
	c_const_set("tank_linearDamping", 0, 1)
	c_const_set("tank_angularDamping", 0, 1)
	c_const_set("tank_spawnTime", 0.75, 1)
	c_const_set("tank_static", false, 1)
	c_const_set("corpse_restitution", 0.6, 1)
	c_const_set("corpse_canSleep", false, 1)
	c_const_set("corpse_isBullet", true, 1)
	c_const_set("corpse_linearDamping", 0, 1)
	c_const_set("corpse_angularDamping", 0, 1)
	c_const_set("corpse_spawnTime", 0.75, 1)
	c_const_set("corpse_static", false, 1)
	c_const_set("corpse_density", 2, 1)
	c_const_set("corpse_friction", 0.25, 1)
	c_const_set("corpse_worldFriction", 2, 1)  -- damping
	c_const_set("corpse_speedIncrease", 0.9, 1)
	c_const_set("corpse_rotationIncrease", 1, 1)
	c_const_set("wall_density", 1, 1)
	c_const_set("wall_friction", 0.25, 1)  -- deceleration caused by friction (~speed *= 1 - friction)
	c_const_set("wall_restitution", 0.2, 1)
	c_const_set("wall_canSleep", false, 1)
	c_const_set("wall_isBullet", false, 1)
	c_const_set("wall_linearDamping", 0.75, 1)
	c_const_set("wall_angularDamping", 0.75, 1)
	c_const_set("tank_rotationChange", 1, 1)
	tank_rotationChange = c_const_get("tank_rotationChange")
	c_const_set("tank_rotationChangeMinSpeed", 4, 1)
	tank_rotationChangeMinSpeed = c_const_get("tank_rotationChangeMinSpeed")
	c_const_set("tank_rotationSpeed", 2 * CIRCLE / 5, 1)  -- two fifths of a circle each second
	c_const_set("tank_slowRotationSpeed", 1 * CIRCLE / 10, 1)  -- one tenth of a circle each second
	tank_rotationSpeed = c_const_get("tank_rotationSpeed")
	tank_slowRotationSpeed = c_const_get("tank_slowRotationSpeed")
	c_const_set("tank_rotationSpecialFactor", (CIRCLE / 2) / 30, 1)  -- extent of rotation per second per unit per second; one half circle per 30 units per second
	c_const_set("tank_slowRotationSpecialFactor", (CIRCLE / 2) / 120, 1)  -- extent of rotation per second per unit per second; one half circle per 120 units per second
	tank_rotationSpecialFactor = c_const_get("tank_rotationSpecialFactor")
	tank_slowRotationSpecialFactor = c_const_get("tank_slowRotationSpecialFactor")
	c_const_set("tank_defaultRotation", c_math_radians(90), 1)  -- up
	c_const_set("tank_boostHealth", 60, 1)
	c_const_set("tank_boostShield", 25, 1)
	c_const_set("tank_shieldMinCollide", 4, 1)
	c_const_set("tank_maxShield", 50, 1)
	c_const_set("tank_shieldedDamage", 1 / 4, 1)
	c_const_set("tank_shieldDamage", 1 / 16, 1)
	c_const_set("tank_accelerationModifier", 3, 1)

	c_const_set("controlPoint_rate", 2, 1)

	c_const_set("powerup_hullx1",  0, 1) c_const_set("powerup_hully1",  1, 1)
	c_const_set("powerup_hullx2",  0, 1) c_const_set("powerup_hully2",  0, 1)
	c_const_set("powerup_hullx3",  1, 1) c_const_set("powerup_hully3",  0, 1)
	c_const_set("powerup_hullx4",  1, 1) c_const_set("powerup_hully4",  1, 1)

	c_const_set("world_megaTankSuicideTimePenalty", 8, 1)  -- tank won't be given any shield or health for this many seconds, in addition to world_megaTankBonusAttackTime
	c_const_set("world_megaTankBonusAttackTime", 8, 1)
	c_const_set("world_megaTankHealthRegenerate", 60, 1)
	c_const_set("world_megaTankBonusHealthGain", 20, 1)
	c_const_set("world_megaTankBeyondCapBonusHealthGain", 1, 1)
	c_const_set("world_megaTankHealthGainCap", 200, 1)
	c_const_set("world_megaTankShieldRegenerate", 0.25, 1)
	c_const_set("world_megaTankBonusShieldGain", 0, 1)
	c_const_set("world_megaTankKillBonus", 2, 1)

	c_const_set("world_plagueDecayRate", 3.875, 1)
	c_const_set("world_plagueSpawnTime", 2.9, 1)  -- this is *not* in addition to anything  -- spawning right after corpses explode make the game funner by adding more strategy to it
	c_const_set("world_plagueSurvivePlayerFactor", 10, 1)
	c_const_set("world_plagueSurviveBonusReward", 5, 1)  -- number of points rewarded to survives in plague mode in addition to the number of players
	c_const_set("world_plagueInfectReward", 5, 1)

	c_const_set("world_plagueRoundNoFireTime", 4.5, 1)  -- relative to the start time of fire
	c_const_set("world_survivorRoundNoFireTime", 1.75, 1)  -- relative to the start time of fire
	c_const_set("world_teamSurvivorRoundNoFireTime", 1.75, 1)  -- relative to the start time of fire

	-- powerups
	c_powerupTypes = {}

	-- weapons are bluish; weapon enhancements are yellowish; tank enhancements are greenish; unique or different powerups are reddish (TODO FIXME XXX unique powerups)

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
	powerupType.instagib = "no-semi"

	-- rocket-launcher
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 11
	powerupType.name = "rocket-launcher"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.15, 0.1, 0.4, 0.333
	powerupType.instagib = false

	-- laser-gun
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 12
	powerupType.name = "laser-gun"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.4, 0.4, 0.8, 0.666
	powerupType.instagib = false

	-- plasma gun
	local powerupType = c_world_powerupType:new()

	table.insert(c_powerupTypes, powerupType)

	powerupType.index = 13
	powerupType.name = "plasma-gun"
	powerupType.c.r, powerupType.c.g, powerupType.c.b, powerupType.c.a = 0.15, 0.4, 0.6, 1
	powerupType.instagib = false


	tankbobs.w_setUnitScale(c_const_get("world_unitScale"))
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
	fixture = nil,  -- physical fixture
	health = 0,
	nextSpawnTime = 0,
	killer = 0,
	score = 0,
	ammo = 0,
	clips = 0,
	reloading = false,
	shotgunReloadState = nil,
	red = false,
	color = {r = 0, g = 0, b = 0},
	tagged = false,
	lastAttackers = {},
	notFireReset = false,
	radiusFireTime = 0,
	megaTank = nil,
	lastAttackedTime = 0,

	cd = {},  -- data cleared on death

	ai = {},
	bot = false,

	m = {p = {}}
}

c_world_corpse =
{
	new = c_class_new,
	base = c_world_tank,

	explodeTime = 0,
	explode = nil,
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
	local t = t_t_getTicks()

	if worldInitialized then
		return
	end

	c_world_powerups = {}
	c_world_tanks = {}
	c_world_teams = {}
	c_world_corpses = {}

	zoom = 1

	local m = c_tcm_current_map
	if not c_tcm_current_map then
		return false
	end

	tankbobs.w_newWorld(c_const_get("world_lowerbound") + t_m_vec2(m.leftmost, m.lowermost), c_const_get("world_upperbound") + t_m_vec2(m.rightmost, m.uppermost), t_m_vec2(c_const_get("world_gravityx"), c_const_get("world_gravityy")), c_const_get("world_allowSleep"), c_world_tank_step, c_world_wall_step, c_world_projectile_step, c_world_powerupSpawnPoint_step, c_world_powerup_step, c_world_controlPoint_step, c_world_flag_step, c_world_teleporter_step, c_world_corpse_step, c_world_tanks, c_tcm_current_map.walls, c_weapon_getProjectiles(), c_tcm_current_map.powerupSpawnPoints, c_world_powerups, c_tcm_current_map.controlPoints, c_tcm_current_map.flags, c_tcm_current_map.teleporters, c_world_corpses)
	tankbobs.w_setContactListener(c_world_contactListener)

	-- set game type
	c_world_setGameType(c_config_get("game.gameType"))

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
			v.m.body = tankbobs.w_addBody(b[1], 0, c_const_get("wall_canSleep"), c_const_get("wall_isBullet"), c_const_get("wall_linearDamping"), c_const_get("wall_angularDamping"), k)
			v.m.fixture = tankbobs.w_addPolygonalFixture(b[2], c_const_get("wall_density"), c_const_get("wall_friction"), c_const_get("wall_restitution"), c_const_get("wall_isSensor"), c_const_get("wall_contentsMask"), c_const_get("wall_clipmask"), v.m.body, not v.static)
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
	lastWorldTime = t_t_getTicks()

	worldInitialized = true

	-- game type specific stuff
	local switch = c_world_getGameType()
	if switch == PLAGUE or
	   switch == SURVIVOR or
	   switch == TEAMSURVIVOR then
		roundStartTime = t
	end

	c_const_backup(key)

	if #c_tcm_current_map.script > 0 then
		-- see if script exists
		local filename = c_const_get("scripts_dir") .. c_tcm_current_map.script

		if not tankbobs.fs_fileExists(filename) then
			common_printError(STOP, "c_world_newWorld: map needs script '" .. c_tcm_current_map.script .. "', which doesn't exist")
		else
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
	c_world_teams = {}
	c_world_corpses = {}
end

function c_world_getZoom()
	return zoom
end

function c_world_setZoom(x)
	zoom = x
end

function c_world_setInstagib(state)
	c_world_instagib = state
end

function c_world_getInstagib()
	return c_world_instagib
end

function c_world_getGameType()
	return c_world_gameType
end

-- Game types
-- A table of {constant, string, human string, team, pointLimitKey, pointLimitLabel}'s
do
local gameTypes = { {DEATHMATCH,     "deathmatch",     "Deathmatch",       false, "game.fragLimit",              "Frag limit"}
                  , {TEAMDEATHMATCH, "teamdeathmatch", "Team Deathmatch",  true,  "game.teamFragLimit",          "Frag limit"}
                  , {SURVIVOR,       "survivor",       "Survivor",         false, "game.survivorPointLimit",     "Point limit"}
                  , {TEAMSURVIVOR,   "teamsurvivor",   "Team Survivor",    true,  "game.teamSurvivorPointLimit", "Point limit"}
                  , {MEGATANK,       "megatank",       "Megatank",         false, "game.megaPointLimit",         "Point limit"}
                  , {CHASE,          "chase",          "Chase",            false, "game.chaseLimit",             "Point limit"}
                  , {PLAGUE,         "plague",         "Plague",           false, "game.plaguePointLimit",       "Point limit"}
                  , {DOMINATION,     "domination",     "Domination",       true,  "game.controlLimit",           "Point limit"}
                  , {CAPTURETHEFLAG, "capturetheflag", "Capture the Flag", true,  "game.captureLimit",           "Capture limit"}
                  }
local c_world_gameType = DEATHMATCH

function c_world_getGameType(gameType)
	gameType = gameType or c_world_gameType
	gameType = c_world_gameTypeConstant(gameType) or gameType

	return gameType
end

function c_world_setGameType(gameType)
	gameType = gameType or c_world_gameType
	gameType = c_world_gameTypeConstant(gameType) or gameType

	c_world_gameType = gameType
end

function c_world_getGameTypes()
	return gameTypes
end

function c_world_gameTypeConstant(gameType)
	gameType = gameType or c_world_gameType
	--gameType = c_world_gameTypeConstant(gameType) or gameType

	if type(gameType) == "string" then
		gameType = gameType:lower()
	end

	for _, v in pairs(gameTypes) do
		if v[1] == gameType or v[2]:lower() == gameType or v[3]:lower() == gameType then
			return v[1]
		end
	end

	common_printError(0, "Warning: c_world_gameTypeConstant: gameType '" .. gameType .. "' not found\n")

	return nil
end

function c_world_gameTypeString(gameType)
	gameType = gameType or c_world_gameType
	gameType = c_world_gameTypeConstant(gameType) or gameType

	for _, v in pairs(gameTypes) do
		if v[1] == gameType then
			return v[2]
		end
	end

	common_printError(0, "Warning: c_world_gameTypeString: gameType '" .. gameType .. "' not found\n")

	return nil
end

function c_world_gameTypeHumanString(gameType)
	gameType = gameType or c_world_gameType
	gameType = c_world_gameTypeConstant(gameType) or gameType

	for _, v in pairs(gameTypes) do
		if v[1] == gameType then
			return v[3]
		end
	end

	common_printError(0, "Warning: c_world_gameTypeHumanString: gameType '" .. gameType .. "' not found\n")

	return nil
end

function c_world_gameTypeTeam(gameType)
	gameType = gameType or c_world_gameType
	gameType = c_world_gameTypeConstant(gameType) or gameType

	for _, v in pairs(gameTypes) do
		if v[1] == gameType then
			return v[4]
		end
	end

	common_printError(0, "Warning: c_world_gameTypeTeam: gameType '" .. gameType .. "' not found\n")

	return nil
end

function c_world_gameTypePointLimit(gameType)
	gameType = gameType or c_world_gameType
	gameType = c_world_gameTypeConstant(gameType) or gameType

	for _, v in pairs(gameTypes) do
		if v[1] == gameType then
			return v[5]
		end
	end

	common_printError(0, "Warning: c_world_gameTypePointLimit: gameType '" .. gameType .. "' not found\n")

	return nil
end

function c_world_gameTypePointLimitLabel(gameType)
	gameType = gameType or c_world_gameType
	gameType = c_world_gameTypeConstant(gameType) or gameType

	for _, v in pairs(gameTypes) do
		if v[1] == gameType then
			return v[6]
		end
	end

	common_printError(0, "Warning: c_world_gameTypePointLimitLabel: gameType '" .. gameType .. "' not found\n")

	return nil
end
end


function c_world_hasWon()
	-- returns either the winning tank or the winning team, a bool that is true when the game-type is a team game-type, and a value that is nil when the game-type is a team game-type but otherwise is the index of the winning individual player

	local limit = c_config_get(c_world_gameTypePointLimit())
	if limit > 0 and #c_world_tanks > 0 then
		if c_world_gameTypeTeam() then
			-- team game-type
			if c_world_redTeam.score ~= c_world_blueTeam.score then
				if     c_world_redTeam. score >= limit then
					return c_world_redTeam, true, nil
				elseif c_world_blueTeam.score >= limit then
					return c_world_blueTeam, true, nil
				end
			end
		else
			local maxScore = nil
			for _, v in pairs(c_world_tanks) do
				if not maxScore or v.score > maxScore then
					maxScore = v.score
				end
			end

			if maxScore >= limit then
				local numMax   = 0
				local lastMaxK = nil
				local lastMaxV = nil
				for k, v in pairs(c_world_tanks) do
					if v.score == maxScore then
						numMax   = numMax + 1
						lastMaxK = K
						lastMaxV = v
					end
				end

				if numMax == 1 then
					return lastMaxV, false, lastMaxK
				end
			end
		end
	end

	return nil, nil, nil
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

function c_world_addCorpse(tank, vel, index)
	local corpse = c_world_corpse:new()  -- FIXME: t_clone() segfaults when overwriting a value?

	local corpseIndex = 1
	for k, v in pairs(c_world_corpses) do
		if v == corpse then
			corpseIndex = k
		end
	end

	local FIXMETODOtmpLastAttackers = tank.lastAttackers  -- HACK: work around segfault
	tank.lastAttackers = {}  -- FIXME TODO: t_clone() segfaults when this isn't set?

	t_t_clone(true, tank, corpse)

	tank.lastAttackers = FIXMETODOtmpLastAttackers

	corpse.explodeTime = t_t_getTicks() + c_world_timeMultiplier(c_const_get("world_corpseTime"))
	corpse.body = tankbobs.w_addBody(corpse.p, corpse.r, c_const_get("corpse_canSleep"), c_const_get("corpse_isBullet"), c_const_get("corpse_linearDamping"), c_const_get("corpse_angularDamping"), index)
	tankbobs.w_addPolygonalFixture(corpse.h, c_const_get("corpse_density"), c_const_get("corpse_friction"), c_const_get("corpse_restitution"), c_const_get("corpse_isSensor"), c_const_get("corpse_contentsMask"), c_const_get("corpse_clipmask"), corpse.body, not c_const_get("corpse_static"))
	t_w_setLinearVelocity(corpse.body, vel)

	corpse.exists = true

	table.insert(c_world_corpses, corpse)
end

function c_world_tank_die(tank, t)
	t = t or t_t_getTicks()

	if tank.exists and tank.body then
		-- things that can't be done more than once
		local vel = t_w_getLinearVelocity(tank.body)
		local index = tankbobs.w_getIndex(tank.body)

		tankbobs.w_removeBody(tank.body) tank.body = nil tank.fixture = nil

		local switch = c_world_getGameType()
		if switch == PLAGUE or
	   	   switch == SURVIVOR or
	   	   switch == TEAMSURVIVOR then
			if not roundEnd and not endingRound then
				c_world_addCorpse(tank, vel, index)
			end
		else
			c_world_addCorpse(tank, vel, index)
		end
	end

	c_ai_tankDie(tank)

	if tank.m.flag then
		-- drop flag
		tank.m.flag.m.pos = tankbobs.m_vec2(tank.p)
		tank.m.flag.m.dropped = true
		tank.m.flag.m.stolen = nil
		tank.m.flag = nil
	end

	local killer = nil
	if tank.killer then
		killer = c_world_tanks[tank.killer]
	end
	tank.killer = nil

	tank.shield = 0
	tank.exists = false
	tank.m.lastDieTime = t

	tank.nextSpawnTime = t + c_world_timeMultiplier(c_const_get("tank_spawnTime"))

	-- game type things
	local switch = c_world_getGameType()
	if switch == DEATHMATCH then
		if killer and killer ~= tank then
			killer.score = killer.score + 1
		else
			if c_config_get("game.punish") then
				tank.score = tank.score - 1
			end
		end

		c_world_tank_spawn(tank)
	elseif switch == TEAMDEATHMATCH then
		if killer and killer ~= tank and tank.red ~= killer.red then
			if killer.red then
				c_world_redTeam.score = c_world_redTeam.score + 1
			else
				c_world_blueTeam.score = c_world_blueTeam.score + 1
			end
		else
			if c_config_get("game.punish") then
				if tank.red then
					c_world_redTeam.score = c_world_redTeam.score - 1
				else
					c_world_blueTeam.score = c_world_blueTeam.score - 1
				end
			end
		end

		c_world_tank_spawn(tank)
	elseif switch == MEGATANK then
		if #c_world_tanks > 0 then
			if killer and killer ~= tank then
				killer.score = killer.score + 1

				if c_world_tanks[tank.megaTank] == tank then
					-- new megatank
					killer.score = killer.score + c_const_get("world_megaTankKillBonus")

					for _, v in pairs(c_world_tanks) do
						v.megaTank = c_world_tankIndex(killer)
					end

					-- don't give the killer temporary protection
				end
			else
				if c_config_get("game.punish") then
					tank.score = tank.score - 1
				end
			end

			if tank.tagged then
				tank.tagged = false

				local num = 0
				local lastTagged = c_world_tanks[#c_world_tanks]
				for k, v in pairs(c_world_tanks) do
					if v.tagged then
						num = num + 1
						lastTagged = k
					end
				end

				if num <= 1 then
					local last = c_world_tanks[lastTagged]

					last.tagged = false

					for _, v in pairs(c_world_tanks) do
						v.megaTank = lastTagged
					end
				end
			end
		end

		c_world_tank_spawn(tank)
	elseif switch == CHASE then
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
	elseif switch == SURVIVOR then
		if not endingRound then
			local numExists = 0
			local lastExists = nil
			for _, v in pairs(c_world_tanks) do
				if v.exists then
					numExists = numExists + 1
					lastExists = v
				end
			end

			if numExists == 0 then
				c_world_survivor_endRound()
			elseif numExists == 1 then
				lastExists.score = lastExists.score + 1

				win = {lastExists.name, lastExists.color}

				c_world_survivor_endRound()
			end
		end
	elseif switch == TEAMSURVIVOR then
		if not endingRound then
			local redExists = false
			local blueExists = false
			for _, v in pairs(c_world_tanks) do
				if v.exists then
					if v.red then
						redExists = true
					else
						blueExists = true
					end
				end
			end

			if not redExists or not blueExists then
				if not blueExists then
					c_world_redTeam.score = c_world_redTeam.score + 1

					local c = c_const_get("color_red")
					local color = {r = c[1], g = c[2], b = c[3], a = c[4]}
					win = {"Red", color}
				end
				if not redExists then
					c_world_blueTeam.score = c_world_blueTeam.score + 1

					local c = c_const_get("color_blue")
					local color = {r = c[1], g = c[2], b = c[3], a = c[4]}
					win = {"Blue", color}
				end

				c_world_survivor_endRound()
			end
		end
	elseif switch == PLAGUE then
		if not endingRound then  -- don't handle anything game type related if the round is ending; we'd fall into an infinite call loop
			if killer and killer ~= tank then
				killer.score = killer.score + 1
			else
				if c_config_get("game.punish") then
					tank.score = tank.score - 1
				end
			end

			local tagged     = false
			local untagged   = false
			for _, v in pairs(c_world_tanks) do
				if v.tagged then
					tagged   = true
				else
					untagged = true
				end
			end

			local taggedExists = false
			for _, v in pairs(c_world_tanks) do
				if v.tagged and (v.exists or v.spawning) then
					taggedExists = true

					break
				end
			end

			local untaggedExists = false
			for _, v in pairs(c_world_tanks) do
				if not v.tagged and (v.exists or v.spawning) then
					untaggedExists = true

					break
				end
			end

			if not tagged then
				-- start the next round and with this tank tagged
				tank.tagged = true

				c_world_plague_endRound()
			end

			if not taggedExists then
				if untagged then
					if tagged then
						-- reward all surviving tanks if this isn't the first round (or the round after tanks were reset)
						for _, v in pairs(c_world_tanks) do
							if not v.tagged and v.exists then
								v.score = v.score + c_const_get("world_plagueSurvivePlayerFactor") * #c_world_tanks + c_const_get("world_plagueSurviveBonusReward")
							end
						end
					end
				end

				-- end the round
				c_world_plague_endRound()
			end

			if not untaggedExists then
				if not untagged then
					-- all tanks have been infected; untag all tanks
					for _, v in pairs(c_world_tanks) do
						v.tagged = false
					end
				end

				-- end the round
				c_world_plague_endRound()
			end
		end
	else
		c_world_tank_spawn(tank)
	end

	tank.cd = {}
end

function c_world_removeTank(tank)
	for k, v in pairs(c_world_tanks) do
		if v == tank then
			if v.exists and v.body then
				tankbobs.w_removeBody(v.body)
				v.body = nil v.fixture = nil
			end

			c_world_tanks[k] = nil
		end
	end
end

-- this is only called when a tank spawns immediately; this should not normally be called outside of this file!
function c_world_spawnTank(tank)
	local t = t_t_getTicks()
	tank.spawning = false
	tank.r = c_const_get("tank_defaultRotation")
	tank.health = c_const_get("tank_health")
	tank.shield = 0
	tank.weapon = c_weapon_getDefaultWeapon()
	tank.cd = {}
	tank.lastAttackedTime = t

	-- find index
	local index = 1

	for k, v in pairs(c_world_tanks) do
		if v == tank then
			index = k
		end
	end

	if tank.body then
		tankbobs.w_removeBody(tank.body)
		tank.body = nil v.fixture = nil
	end

	local weapon = tank.weapon and c_weapon_getWeapons()[tank.weapon]

	if weapon then
		tank.lastFireTime = tankbobs.t_getTicks() - c_world_timeMultiplier(weapon.repeatRate)
	else
		tank.lastFireTime = tankbobs.t_getTicks()
	end

	-- game type stuff
	local switch = c_world_getGameType()
	if switch == MEGATANK then
		tank.lastAttackedTime = t + c_world_timeMultiplier(c_const_get("world_megaTankSuicideTimePenalty"))
	end

	-- add a physical body
	tank.body = tankbobs.w_addBody(tank.p, tank.r, c_const_get("tank_canSleep"), c_const_get("tank_isBullet"), c_const_get("tank_linearDamping"), c_const_get("tank_angularDamping"), index)
	tankbobs.w_addPolygonalFixture(tank.h, c_const_get("tank_density"), c_const_get("tank_friction"), c_const_get("tank_restitution"), c_const_get("tank_isSensor"), c_const_get("tank_contentsMask"), c_const_get("tank_clipmask"), tank.body, not c_const_get("tank_static"))

	c_ai_tankSpawn(tank)

	tank.exists = true
end

function c_world_tank_checkSpawn(d, tank)
	local t = t_t_getTicks()

	if tank.exists or not tank.spawning or t < tank.nextSpawnTime then
		return
	end

	if tank.lastSpawnPoint == 0 then
		tank.lastSpawnPoint = 1
	end

	local sp = tank.lastSpawnPoint
	local playerSpawnPoint = c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint]

	local switch = c_config_get("game.spawnStyle")
	if switch == ALTERNATING then
		while not c_world_tank_canSpawn(d, tank) do
			tank.lastSpawnPoint = tank.lastSpawnPoint + 1
			playerSpawnPoint = c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint]

			if not playerSpawnPoint then
				tank.lastSpawnPoint = 1
				playerSpawnPoint = c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint]

				if not playerSpawnPoint then
					error "No working spawn points in map"
				end
			end

			if tank.lastSpawnPoint == sp then
				-- no spawn points can be used
				return false
			end
		end
	elseif switch == BLOCKABLE then
		if #c_tcm_current_map.playerSpawnPoints <= 0 then
			error "No spawn points in map"
		end

		tank.lastSpawnPoint = tank.lastSpawnPoint + 1
		playerSpawnPoint = c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint]

		if not playerSpawnPoint then
			tank.lastSpawnPoint = 1
			playerSpawnPoint = c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint]

			if not playerSpawnPoint then
				error "No working spawn points in map"
			end
		end

		-- see if next spawn point can be spawned from
		local numIntersections = 0
		tank.p(playerSpawnPoint.p)
		for _, v in pairs(c_world_tanks) do
			if v.exists then
				if c_world_intersection(d, t_t_clone(true, c_world_tankHull(tank)), t_t_clone(c_world_tankHull(v)), t_m_vec2(0, 0), t_w_getLinearVelocity(v.body)) then
					numIntersections = numIntersections + 1
				end
			end
		end

		if numIntersections >= 1 then
			local intersections = {}
			for k, v in pairs(c_tcm_current_map.playerSpawnPoints) do
				local thisIntersections = 0

				tank.p(v.p)

				for _, vs in pairs(c_world_tanks) do
					if vs.exists then
						if c_world_intersection(d, t_t_clone(true, c_world_tankHull(tank)), t_t_clone(c_world_tankHull(vs)), t_m_vec2(0, 0), t_w_getLinearVelocity(vs.body)) then
							thisIntersections = thisIntersections + 1
						end
					end
				end

				table.insert(intersections, {k, thisIntersections})
			end

			-- first spawn point with least intersection
			table.sort(intersections, function (a, b) return a[2] < b[2] end)

			tank.lastSpawnPoint = intersections[1][1]
			playerSpawnPoint = c_tcm_current_map.playerSpawnPoints[tank.lastSpawnPoint]
		end
	end

	-- spawn
	tank.p(playerSpawnPoint.p)
	c_world_spawnTank(tank)

	c_world_spawnTank_misc(tank)
end

function c_world_spawnTank_misc(tank)
end

function c_world_tank_canSpawn(d, tank)
	-- test if a tank can spawn from a specific spawn point
	local t = t_t_getTicks()

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

function c_world_plague_endRound()
	-- end the round without rewarding any points

	local t = t_t_getTicks()

	roundEnd = true
	roundStartTime = t

	-- we do this by killing all of the tanks
	endingRound = true
	for _, v in pairs(c_world_tanks) do
		c_world_tank_die(v)

		if v.tagged then
			v.nextSpawnTime = t + c_world_timeMultiplier(c_const_get("world_plagueSpawnTime"))
		else
			v.nextSpawnTime = t + c_world_timeMultiplier(c_const_get("tank_spawnTime"))
		end

		v.spawning = true
	end
	endingRound = false
end

function c_world_survivor_endRound()
	local t = t_t_getTicks()

	roundEnd = true
	roundStartTime = t

	-- we do this by killing all of the tanks
	endingRound = true
	for _, v in pairs(c_world_tanks) do
		c_world_tank_die(v)

		v.spawning = true
	end
	endingRound = false
end

local p1a = {nil, nil, nil}
local p2a = {nil, nil, nil}
function c_world_intersection(d, p1, p2, v1, v2)
	-- test if two polygons can collide

	d  = d  or 0
	v1 = v1 or tankbobs.m_vec2(0, 0)
	v2 = v2 or tankbobs.m_vec2(0, 0)

	local p1h = {nil, nil, nil}
	local p2h = {nil, nil, nil}

	tankbobs.t_clone(true, p1, p1h)
	tankbobs.t_clone(true, p2, p2h)
	tankbobs.t_clone(true, p1h, p1a)
	tankbobs.t_clone(true, p2h, p2a)

	local lp1a = #p1a
	for k, v in ipairs(p1a) do
		if k <= lp1a then
			v = v + d * v1
		else
			p1a[k] = nil
		end
	end
	local lp2a = #p2a
	for k, v in ipairs(p2a) do
		if k <= lp2a then
			v = v + d * v2
		else
			p2a[k] = nil
		end
	end

	tankbobs.t_clone(true, p1a, p1h)
	tankbobs.t_clone(true, p2a, p2h)

	if tankbobs.m_polygon(p1h, p2h) then
		return true
	else
		-- test if either polygon lies completely inside of the other
		if c_world_pointInsideHull(p1h[1], p2h) or
		   c_world_pointInsideHull(p2h[1], p1h) then
		   return true
		end
	end

	return false
end
c_world_hullIntersectsHull = c_world_intersection

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

function c_world_pointIntersects(p, ignoreTypes)
	ignoreTypes = ignoreTypes or ""

	local hull

	local function t()
		if c_world_pointInsideHull(p, hull) then
			return true
		else
			return false
		end
	end

	-- walls
	if not ignoreTypes:find("wall") then
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
	if not ignoreTypes:find("tanks") then
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
	if not ignoreTypes:find("projectile") then
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
	if not ignoreTypes:find("powerup") then
		for _, v in pairs(c_world_powerups) do
			if not v.collided then
				hull = c_world_powerupHull(v)

				if t() then
					return true
				end
			end
		end
	end

	-- corpses
	if not ignoreTypes:find("corpse") then
		for _, v in pairs(c_world_corpses) do
			if not v.collided then
				hull = c_world_corpseHull(v)

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
function c_world_corpseHull(corpse)
	if not c then
		c = {t_m_vec2(0, 0), t_m_vec2(0, 0), t_m_vec2(0, 0), t_m_vec2(0, 0)}
	end

	-- return a table of coordinates of tank's hull
	local p = corpse.p

	for k, v in pairs(corpse.h) do
		local h = t_m_vec2(v)
		h.t = h.t + corpse.r
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

	local hull = c_weapon_getWeapons()[projectile.weapon].projectileHull
	if hull then
		for k, v in pairs(hull) do
			local h = t_m_vec2(v)
			h.t = h.t + projectile.r
			h:add(p)
			c[k](h)
		end
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

function c_world_lineIntersectsHull(start, endP, hull)
	local rb, rintersection
	local lastPoint, currentPoint = nil
	local distance, minDistance

	start = tankbobs.m_vec2(start)
	endP  = tankbobs.m_vec2(endP)

	-- test if the start lies completely inside of the hull
	if c_world_pointInsideHull(start, hull) then
		-- return the closest intersection from the start point
		return true, start
	end

	for _, v in ipairs(hull) do
		currentPoint = tankbobs.m_vec2(v)
		if not lastPoint then
			lastPoint = tankbobs.m_vec2(hull[#hull])
		end

		local b, intersection = tankbobs.m_edge(lastPoint, currentPoint, start, endP)
		if b and intersection then  -- FIXME: figure out why b can be true while intersection is nil
			distance = math.abs((intersection - start).R)

			if not minDistance or distance < minDistance then
				minDistance = distance

				rb, rintersection = b, tankbobs.m_vec2(intersection)
			end
		end

		lastPoint = currentPoint
	end

	return rb, rintersection
end

function c_world_findClosestIntersection(start, endP, ignoreTypes)
	-- test against the world and find the closest intersection point
	-- returns false; or true, intersectionPoint, typeOfTarget, target
	local minDistance, minIntersection, typeOfTarget, target
	local b, intersection

	ignoreTypes = ignoreTypes or ""

	-- walls
	if not ignoreTypes:find("wall") then
		for _, v in ipairs(c_tcm_current_map.walls) do
			if not v.detail then
				if (not v.static or not ignoreTypes:find("static")) and (v.static or not ignoreTypes:find("dynamic")) then
					b, intersection = c_world_lineIntersectsHull(start, endP, v.m.pos)
					if b and intersection then  -- FIXME: figure out why b can be true while intersection is nil
						if not minDistance then
							minIntersection = intersection
							minDistance = math.abs((intersection - start).R)
							typeOfTarget = "wall"
							target = v
						elseif math.abs((intersection - start).R) < minDistance then
							minIntersection = intersection
							minDistance = math.abs((intersection - start).R)
							typeOfTarget = "wall"
							target = v
						end
					end
				end
			end
		end
	end

	-- tanks
	if not ignoreTypes:find("tank") then
		for _, v in ipairs(c_world_tanks) do
			if v.exists then
				b, intersection = c_world_lineIntersectsHull(start, endP, c_world_tankHull(v))
				if b then
					if not minDistance then
						minIntersection = intersection
						minDistance = math.abs((intersection - start).R)
						typeOfTarget = "tank"
						target = v
					elseif math.abs((intersection - start).R) < minDistance then
						minIntersection = intersection
						minDistance = math.abs((intersection - start).R)
						typeOfTarget = "tank"
						target = v
					end
				end
			end
		end
	end

	-- projectiles
	if not ignoreTypes:find("projectile") then
		for _, v in ipairs(c_weapon_getProjectiles()) do
			if not v.collided then
				b, intersection = c_world_lineIntersectsHull(start, endP, c_world_projectileHull(v))
				if b then
					if not minDistance then
						minIntersection = intersection
						minDistance = math.abs((intersection - start).R)
						typeOfTarget = "projectile"
						target = v
					elseif math.abs((intersection - start).R) < minDistance then
						minIntersection = intersection
						minDistance = math.abs((intersection - start).R)
						typeOfTarget = "projectile"
						target = v
					end
				end
			end
		end
	end

	-- powerups
	if not ignoreTypes:find("powerup") then
		for _, v in ipairs(c_world_powerups) do
			if v.exists then
				b, intersection = c_world_lineIntersectsHull(start, endP, c_world_powerupHull(v))
				if b then
					if not minDistance then
						minIntersection = intersection
						minDistance = math.abs((intersection - start).R)
						typeOfTarget = "powerup"
						target = v
					elseif math.abs((intersection - start).R) < minDistance then
						minIntersection = intersection
						minDistance = math.abs((intersection - start).R)
						typeOfTarget = "powerup"
						target = v
					end
				end
			end
		end
	end

	-- corpses
	if not ignoreTypes:find("corpse") then
		for _, v in ipairs(c_world_corpses) do
			if v.exists then
				b, intersection = c_world_lineIntersectsHull(start, endP, c_world_corpseHull(v))
				if b then
					if not minDistance then
						minIntersection = intersection
						minDistance = math.abs((intersection - start).R)
						typeOfTarget = "corpse"
						target = v
					elseif math.abs((intersection - start).R) < minDistance then
						minIntersection = intersection
						minDistance = math.abs((intersection - start).R)
						typeOfTarget = "corpse"
						target = v
					end
				end
			end
		end
	end

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

	if c_world_getGameType() == CHASE then
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
			local add = 0

			if bit.band(tank.state, SLOW) ~= 0 then
				if bit.band(tank.state, LEFT) ~= 0 then
					if vel.R < 0 then
						-- inverse rotation
						add = -tank_slowRotationSpecialFactor * vel.R
					else
						add =  tank_slowRotationSpecialFactor * vel.R
					end
				end

				if bit.band(tank.state, RIGHT) ~= 0 then
					if vel.R < 0 then  -- inverse rotation
						add =  tank_slowRotationSpecialFactor * vel.R
					else
						add = -tank_slowRotationSpecialFactor * vel.R
					end
				end
			else
				if bit.band(tank.state, LEFT) ~= 0 then
					if vel.R < 0 then  -- inverse rotation
						add = -tank_rotationSpecialFactor * vel.R
					else
						add =  tank_rotationSpecialFactor * vel.R
					end
				end

				if bit.band(tank.state, RIGHT) ~= 0 then
					if vel.R < 0 then  -- inverse rotation
						add =  tank_rotationSpecialFactor * vel.R
					else
						add = -tank_rotationSpecialFactor * vel.R
					end
				end
			end

			tank.r = tank.r + d * add

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

					for _, v in pairs(tank_acceleration) do  -- local copy of table for optimization
						if not acceleration then
							acceleration = v[1]
						elseif vel.R >= v[2] then
							acceleration = math.min(v[1], acceleration)
						end
					end

					if tank.cd.acceleration then
						acceleration = acceleration * c_const_get("tank_accelerationModifier")
					end

					local newVel = t_m_vec2(vel)
					newVel.R = newVel.R + d * acceleration
					newVel.t = tank.r
					if vel.R >= tank_rotationChangeMinSpeed then
						-- interpolate in the correct direction
						vel.t    = math.fmod(vel.t, CIRCLE)
						newVel.t = math.fmod(newVel.t, CIRCLE)
						if     vel.t    - newVel.t > CIRCLE / 2 then
							vel.t    = vel.t    - CIRCLE
						elseif newVel.t - vel.t    > CIRCLE / 2 then
							newVel.t = newVel.t - CIRCLE
						end
						newVel.t = common_lerp(vel.t, newVel.t, d * tank_rotationChange)
					end

					t_w_setLinearVelocity(tank.body, newVel)
					vel(newVel)
				end
				if bit.band(tank.state, BACK) ~= 0 then
					if bit.band(tank.state, REVERSE) ~= 0 and vel.R <= c_const_get("tank_decelerationMaxSpeed") then
						-- reverse

						local subVel = t_m_vec2()
						subVel.R = d * c_const_get("tank_reverse")
						subVel.t = tank.r
						vel:sub(subVel)
						t_w_setLinearVelocity(tank.body, vel)
					else
						-- break

						local newVel = t_m_vec2(vel)

						newVel.R = math.max(0, newVel.R - d * c_const_get("tank_deceleration"))

						t_w_setLinearVelocity(tank.body, newVel)
						vel(newVel)
					end
				else
					tank.state = bit.band(tank.state, bit.bnot(REVERSE))
				end
			else
				local v = t_w_getLinearVelocity(tank.body)

				v.R = v.R / (1 + d * tank_worldFriction)
				t_w_setLinearVelocity(tank.body, v)

				tank.state = bit.band(tank.state, bit.bnot(REVERSE))
			end

			if bit.band(tank.state, SLOW) ~= 0 then
				if bit.band(tank.state, LEFT) ~= 0 then
					tank.r = tank.r + d * tank_slowRotationSpeed
				end

				if bit.band(tank.state, RIGHT) ~= 0 then
					tank.r = tank.r - d * tank_slowRotationSpeed
				end
			else
				if bit.band(tank.state, LEFT) ~= 0 then
					tank.r = tank.r + d * tank_rotationSpeed
				end

				if bit.band(tank.state, RIGHT) ~= 0 then
					tank.r = tank.r - d * tank_rotationSpeed
				end
			end
		end
	end

	t_w_setAngle(tank.body, tank.r)

	t_w_setAngularVelocity(tank.body, 0)  -- reset the tank's angular velocity

	-- weapons
	c_weapon_fire(tank, d)

	if tank.bot then
		c_ai_tank_step(tank, d)
	end

	-- game type stuff
	local switch = c_world_getGameType()
	if switch == MEGATANK then
		--if #c_world_tanks > 1 then  -- this is redundant, since this function couldn't be called with an empty table.  If it could, this check would be necessary.
			-- set all tanks as tagged if the last tank hasn't been initialised (the length operator will always point to an existing tank if the table isn't empty)
			if not tank.m.megaTankInitialised then
				for _, v in pairs(c_world_tanks) do
					tank.m.megaTankInitialised = true

					tank.tagged = true
					tank.megaTank = nil
				end
			end

			if tank.megaTank and c_world_tanks[tank.megaTank] == tank then
				tank.clips = 1

				if t >= tank.lastAttackedTime + c_const_get("world_megaTankBonusAttackTime") then
					if tank.health <= c_const_get("tank_health") then
						tank.health = tank.health + d * c_const_get("world_megaTankHealthRegenerate")
					elseif tank.health <= c_const_get("world_megaTankHealthGainCap") then
						tank.health = tank.health + d * c_const_get("world_megaTankBonusHealthGain")
					else
						tank.health = tank.health + d * c_const_get("world_megaTankBeyondCapBonusHealthGain")
					end
					if tank.shield <= c_const_get("tank_boostShield") then
						tank.shield = tank.shield + d * c_const_get("world_megaTankShieldRegenerate")
					else
						tank.shield = tank.shield + d * c_const_get("world_megaTankBonusShieldGain")
					end
				end
			end
		--end
	elseif switch == PLAGUE then
		if tank.tagged then
			-- tank is plagued

			c_world_tankDamage(tank, d * c_const_get("world_plagueDecayRate"), tank)
		end
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
				wall.m.ppid = wall.pid + 1
				wall.m.pid = paths[wall.pid + 1]
				if wall.m.pid then
					wall.m.pid = wall.m.pid.t + 1
				end
				wall.m.ppos = 0
				wall.m.startpos = t_m_vec2(c_world_wallShape(wall.m.pos)[1])
			else
				local path = paths[wall.m.pid]
				local prevPath = paths[wall.m.ppid]

				if path and (prevPath.enabled or prevPath.m.enabled) then
					if prevPath.time == 0 then
						wall.m.ppos = 1
					else
						wall.m.ppos = math.min(1, wall.m.ppos + (d / prevPath.time))
					end

					tankbobs.w_setPosition(wall.m.body, common_lerp(wall.m.startpos, wall.m.startpos + path.p - prevPath.p, wall.m.ppos))
					if wall.m.ppos >= 1 then
						wall.m.ppid = wall.m.pid
						wall.m.startpos:add(path.p - prevPath.p)
						prevPath = paths[wall.m.ppid]
						wall.m.pid = path.t + 1
						path = paths[wall.m.pid]
						wall.m.ppos = 0
					end
				end
			end

			t_w_getVertices(wall.m.fixture, wall.m.pos)
			local offset = t_w_getPosition(wall.m.body)
			local angle = t_w_getAngle(wall.m.body)
			for _, v in pairs(wall.m.pos) do
				v.t = v.t + angle
				v:add(offset)
			end
		end
	else
		t_w_getVertices(wall.m.fixture, wall.m.pos)
		local offset = t_w_getPosition(wall.m.body)
		local angle = t_w_getAngle(wall.m.body)
		for _, v in pairs(wall.m.pos) do
			v.t = v.t + angle
			v:add(offset)
		end
	end
end

function c_world_projectile_step(d, projectile)
	local t = t_t_getTicks()

	local weapon = c_weapon_getWeapons()[projectile.weapon]

	if not weapon then
		if projectile.m.body then
			tankbobs.w_removeBody(projectile.m.body) projectile.m.body = nil projectile.m.fixture = nil
		end
		c_weapon_removeProjectile(projectile)
		return
	end

	if projectile.collided then
		if projectile.m.body then
			tankbobs.w_removeBody(projectile.m.body) projectile.m.body = nil projectile.m.fixture = nil
		end

		-- if explosive projectile, don't remove immediately
		if weapon.projectileExplode then
			if not projectile.m.collideTime then
				projectile.m.collideTime = t + c_world_timeMultiplier(weapon.projectileExplodeTime)
			end

			if t > projectile.m.collideTime then
				-- remove projectile

				c_weapon_removeProjectile(projectile)

				return
			end
		else
			c_weapon_removeProjectile(projectile)

			return
		end
	else
		c_world_testBody(projectile)

		-- Projectiles can look quite silly when they don't point in the direction in which they're traveling
		t_w_setAngle(projectile.m.body, t_w_getLinearVelocity(projectile.m.body).t)

		projectile.p(t_w_getPosition(projectile.m.body))
		projectile.r = t_w_getAngle(projectile.m.body)
	end
end

function c_world_spawnPowerup(powerup, index)
	powerup.m.body = tankbobs.w_addBody(powerup.p, 0, c_const_get("powerup_canSleep"), c_const_get("powerup_isBullet"), c_const_get("powerup_linearDamping"), c_const_get("powerup_angularDamping"), index)
	tankbobs.w_addPolygonalFixture(c_world_powerupHull(powerup), c_const_get("powerup_density"), c_const_get("powerup_friction"), c_const_get("powerup_restitution"), c_const_get("powerup_isSensor"), c_const_get("powerup_contentsMask"), c_const_get("powerup_clipmask"), powerup.m.body, not c_const_get("powerup_static"))
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
				if v == powerupSpawnPoint then
					index = k
				end
			end

			powerup.spawner = index

			powerup.powerupType = nil

			local found = false
			for k, v in pairs(powerupSpawnPoint.enabledPowerups) do
				if v then
					if found then
						if c_world_getPowerupTypeByName(k) then
							if (c_world_getPowerupTypeByName(k).instagib == false and c_world_getInstagib() == false) or
								c_world_getPowerupTypeByName(k).instagib == true                                      or
								c_world_getPowerupTypeByName(k).instagib == "no-semi" and c_world_getInstagib() ~= "semi" then
								powerupSpawnPoint.m.lastPowerup = k
								powerup.powerupType = c_world_getPowerupTypeByName(k).index
								break
							end
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
		tank.shield = tank.shield + math.min(c_const_get("tank_boostShield"), math.max(0, c_const_get("tank_maxShield") - tank.shield))
	end
	if powerupType.name == "rocket-launcher" then
		c_weapon_pickUp(tank, powerupType.name)
	end
	if powerupType.name == "laser-gun" then
		c_weapon_pickUp(tank, powerupType.name)
	end
	if powerupType.name == "plasma-gun" then
		c_weapon_pickUp(tank, powerupType.name)
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

function c_world_removeCorpse(corpse)
	for k, v in pairs(c_world_corpses) do
		if v == corpse then
			if v.body then
				tankbobs.w_removeBody(v.body) v.body = nil v.fixture = nil
			end

			c_world_corpses[k] = nil
		end
	end
end

function c_world_explosion(pos, damage, force, radius, log, attacker)
	if radius <= 0.001 then
		return
	end

	log = log or 1

	-- iterate over tanks
	for _, v in pairs(c_world_tanks) do
		if v.exists and v.body then
			if (pos - v.p).R <= radius then
				local s, _, t, _ = c_world_findClosestIntersection(pos, v.p, "tank, projectile, powerup, corpse, dynamic")

				if not s then
					local d = (1 - (pos - v.p).R / radius) ^ log

					-- force
					local vel = t_w_getLinearVelocity(v.body)
					local offset = t_m_vec2()
					offset.R = d * force
					offset.t = (v.p - pos).t
					vel:add(offset)
					t_w_setLinearVelocity(v.body, vel)

					-- damage
					c_world_tankDamage(v, d * damage, attacker)

					if v.health <= 0 then
						v.killer = attacker
					end
				end
			end
		end
	end

	-- iterate over walls
	for _, v in pairs(c_tcm_current_map.walls) do
		if not v.static and v.m.body then
			local p = c_world_wallShape(v.m.pos)[1]
			if (pos - p).R <= radius then
				local s, _, _, _ = c_world_findClosestIntersection(pos, p, "tank, projectile, powerup, corpse, dynamic")

				if not s then
					local d = (1 - (pos - p).R / radius) ^ log

					-- force
					local vel = t_w_getLinearVelocity(v.m.body)
					local offset = t_m_vec2()
					offset.R = d * force
					offset.t = (p - pos).t
					vel:add(offset)
					t_w_setLinearVelocity(v.m.body, vel)

					-- angular velocity
                    local angle = tankbobs.w_getAngularVelocity(v.m.body)
	                angle = angle - d * (p - pos).t
					t_w_setAngularVelocity(v.m.body, angle)
				end
			end
		end
	end
end

function c_world_corpse_step(d, corpse)
	local t = t_t_getTicks()

	if not corpse.exists then
		c_world_removeCorpse(corpse)

		return
	end

	if corpse.body then
		local vel = t_w_getLinearVelocity(corpse.body)
		local ang = tankbobs.w_getAngularVelocity(corpse.body)

		ang = ang + (d * c_const_get("corpse_rotationIncrease") * ang)
		vel.R = vel.R + (d * c_const_get("corpse_speedIncrease") * vel.R)

		t_w_setLinearVelocity(corpse.body, vel)
		t_w_setAngularVelocity(corpse.body, ang)

		corpse.p(t_w_getPosition(corpse.body))
		corpse.r = t_w_getAngle(corpse.body)
	end

	if t >= corpse.explodeTime + c_world_timeMultiplier(c_const_get("world_corpsePostTime")) then
		-- remove corpse
		corpse.exists = false

		c_world_removeCorpse(corpse)
	elseif t >= corpse.explodeTime then
		-- explode corpse
		if not corpse.explode then
			corpse.explode = c_const_get("world_corpsePostTime")

			c_world_explosion(corpse.p, c_const_get("world_corpseExplodeDamage"), c_const_get("world_corpseExplodeKnockback"), c_const_get("world_corpseExplodeRadius"), c_const_get("world_corpseExplodeRadiusReduce"), tankbobs.w_getIndex(corpse.body))
		end

		if corpse.body then
			tankbobs.w_removeBody(corpse.body) corpse.body = nil corpse.fixture = nil
		end

		corpse.explode = corpse.explode - d
	end
end

function c_world_controlPoint_step(d, controlPoint)
	if c_world_getGameType() ~= DOMINATION then
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
	if c_world_getGameType() ~= CAPTURETHEFLAG then
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
					if c_world_pointIntersects(target.p) then
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

function c_world_isWall(fixture)
	if t_w_getContents(fixture) == WALL then
		return c_tcm_current_map.walls[tankbobs.w_getIndex(tankbobs.w_getBody(fixture))]
	end

	return nil
end

function c_world_isTank(fixture)
	if t_w_getContents(fixture) == TANK then
		return c_world_tanks[tankbobs.w_getIndex(tankbobs.w_getBody(fixture))]
	end

	return nil
end

function c_world_isProjectile(fixture)
	if t_w_getContents(fixture) == PROJECTILE then
		return c_weapon_getProjectiles()[tankbobs.w_getIndex(tankbobs.w_getBody(fixture))]
	end

	return nil
end

function c_world_isPowerup(fixture)
	if t_w_getContents(fixture) == POWERUP then
		return c_world_powerups[tankbobs.w_getIndex(tankbobs.w_getBody(fixture))]
	end

	return nil
end

function c_world_isBodyWall(body)
	if t_w_getBodyContents(body) == WALL then
		return c_tcm_current_map.walls[tankbobs.w_getIndex(body)]
	end

	return nil
end

function c_world_isBodyTank(body)
	if t_w_getBodyContents(body) == TANK then
		return c_world_tanks[tankbobs.w_getIndex(body)]
	end

	return nil
end

function c_world_isBodyProjectile(body)
	if t_w_getBodyContents(body) == PROJECTILE then
		return c_weapon_getProjectiles()[tankbobs.w_getIndex(body)]
	end

	return nil
end

function c_world_isBodyPowerup(body)
	if t_w_getBodyContents(body) == POWERUP then
		return c_world_powerups[tankbobs.w_getIndex(body)]
	end

	return nil
end

function c_world_tankDamage(tank, damage, attacker)
	local t = t_t_getTicks()

	tank.lastAttackedTime = math.max(tank.lastAttackedTime, t)  -- last attacked may have been set ahead

	local switch = c_world_getGameType()
	if switch == MEGATANK then
		if c_world_tanks[tank.megaTank] == tank and tank == attacker then
			-- megatank can't damage himself.  If he could, who would become megatank when he killed himself?  Would he unfairly remain megatank?  (Another way would be to respawn the megatank with an arbitrary amount of low health such that one single shot of any weapon would kill him, but being protected from self damage is funner, I think)
			-- Actually, they can.  When the respawn, they won't have any shield or bonus (for x seconds) and will only have default weapon.
			if tank.shield > 0 then
				tank.health = tank.health - c_const_get("tank_shieldedDamage") * damage
				tank.shield = tank.shield - c_const_get("tank_shieldDamage") * damage
			else
				tank.health = tank.health - damage
			end
		else
			if tank.shield > 0 then
				tank.health = tank.health - c_const_get("tank_shieldedDamage") * damage
				tank.shield = tank.shield - c_const_get("tank_shieldDamage") * damage
			else
				tank.health = tank.health - damage
			end
		end

		if tank.health <= 0 and attacker then
			tank.killer = attacker
		end
	else
		if tank.shield > 0 then
			tank.health = tank.health - c_const_get("tank_shieldedDamage") * damage
			tank.shield = tank.shield - c_const_get("tank_shieldDamage") * damage
		else
			tank.health = tank.health - damage
		end

		if tank.health <= 0 and attacker then
			tank.killer = attacker
		end
	end
end

function c_world_tankIndex(tank)
	for k, v in pairs(c_world_tanks) do
		if tank == v then
			return k
		end
	end

	return nil
end

local function c_world_collide(tank, normal, attacker)
	local vel = t_w_getLinearVelocity(tank.body)
	local component = vel * -normal

	if c_world_getInstagib() ~= "semi" and tank.shield < c_const_get("tank_shieldMinCollide") then
		-- no collision damage in semi-instagib mode or if any of the shield remains
		if component >= c_const_get("tank_damageMinSpeed") then
			local damage = c_const_get("tank_damageK") * (component - c_const_get("tank_damageMinSpeed"))

			if damage >= c_const_get("tank_collideMinDamage") then
				c_world_tankDamage(tank, damage, c_world_tankIndex(attacker))
			end
		end
	end

	tank.m.lastCollideTime = t_t_getTicks()
	tank.m.intensity = component / c_const_get("tank_intensityMaxSpeed")
	if tank.m.intensity > 1 then
		tank.m.intensity = 1
	end
end

function c_world_preContactListener(begin, fixtureA, fixtureB, bodyA, bodyB, position, normal)
	return false
end

function c_world_contactListener(begin, fixtureA, fixtureB, bodyA, bodyB, position, normal)
	if c_world_preContactListener(begin, fixtureA, fixtureB, bodyA, bodyB, position, normal) then
		return
	end

	if begin then
		local b, p
		local powerup = false

		if c_world_isBodyPowerup(bodyA) or c_world_isBodyPowerup(bodyB) then
			local tank = c_world_isBodyTank(bodyA)
			local tank2 = c_world_isBodyTank(bodyB)

			if tank then
				c_world_powerup_pickUp(tank, c_world_isBodyPowerup(bodyB))
			elseif tank2 then
				c_world_powerup_pickUp(tank2, c_world_isBodyPowerup(bodyA))
			end

			powerup = true
		end

		if c_world_isProjectile(fixtureA) or c_world_isProjectile(fixtureB) then
			local projectile, projectile2

			projectile = c_world_isProjectile(fixtureA)
			projectile2 = c_world_isProjectile(fixtureB)

			-- test if the projectile hit a tank
			local tank, tank2

			tank = c_world_isBodyTank(bodyA)
			tank2 = c_world_isBodyTank(bodyB)

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
				c_weapon_projectileCollided(projectile, bodyB)
			end

			if projectile2 then
				c_weapon_projectileCollided(projectile2, bodyA)
			end
		elseif c_world_isBodyTank(bodyA) or c_world_isBodyTank(bodyB) then
			local tank, tank2

			tank = c_world_isBodyTank(bodyA)
			tank2 = c_world_isBodyTank(bodyB)

			if not powerup then
				if tank then
					c_world_collide(tank, normal, tank2)
				end

				if tank2 then
					c_world_collide(tank2, normal, tank)
				end
			end
		end

		-- game type stuff
		local switch = c_world_getGameType()
		if switch == CHASE then
			-- tag another player
			if c_world_isBodyTank(bodyA) and c_world_isBodyTank(bodyB) then
				local tank, tank2 = c_world_isBodyTank(bodyA), c_world_isBodyTank(bodyB)

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
		elseif switch == PLAGUE then
			-- infect another player
			if c_world_isBodyTank(bodyA) and c_world_isBodyTank(bodyB) then
				local tank, tank2 = c_world_isBodyTank(bodyA), c_world_isBodyTank(bodyB)

				local taggedTank, otherTank = nil, nil

				if tank.tagged and not tank2.tagged then
					taggedTank, otherTank = tank, tank2
				elseif tank2.tagged and not tank.tagged then
					taggedTank, otherTank = tank2, tank
				end

				if taggedTank and otherTank then
					otherTank.tagged = true
					taggedTank.score = taggedTank.score + c_const_get("world_plagueInfectReward")
				end
			end
		end
	end

	if c_world_postContactListener(begin, fixtureA, fixtureB, bodyA, bodyB, position, normal) then
		return
	end
end

function c_world_postContactListener(begin, fixtureA, fixtureB, bodyA, bodyB, position, normal)
	return false
end

function c_world_resetWorldTimers(t)
	t = t or t_t_getTicks()

	worldTime = t_t_getTicks()
	lastWorldTime = t_t_getTicks()

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

		v.lastAttackedTime = t

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

	for _, v in pairs(c_world_corpses) do
		v.explodeTime = t + c_world_timeMultiplier(c_const_get("world_corpseTime"))
	end

	for _, v in pairs(c_weapon_getProjectiles()) do
		if v.m.collideTime then
			v.m.collideTime = t + c_world_timeMultiplier(c_const_get("world_corpsePostTime"))
		end
	end

	for _, v in pairs(c_tcm_current_map.controlPoints) do
		if v.m.nextPointTime then
			v.m.nextPointTime = t
		end
	end

	lastPowerupSpawnTime = nil
	nextPowerupSpawnPoint = nil
end

function c_world_offsetWorldTimers(d)
	worldTime = t_t_getTicks()
	lastWorldTime = t_t_getTicks()

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

		v.lastAttackedTime = v.lastAttackedTime + d

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

	for _, v in pairs(c_world_corpses) do
		v.explodeTime = v.explodeTime + d
	end

	for _, v in pairs(c_weapon_getProjectiles()) do
		if v.m.collideTime then
			v.m.collideTime = v.m.collideTime + d
		end
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
	return c_world_resetWorldTimers()
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
	return tankbobs.w_setTimeStep()
end

function c_world_setIterations(x)
	tankbobs.w_setIterations(x)
end

function c_world_setIterations()
	return tankbobs.w_getIterations()
end

local timeStep = 0
local f
function c_world_step(d)
	local t = t_t_getTicks()
	if not f then
		f = c_const_get("world_time") * c_const_get("world_speed") / (c_world_timeMultiplier())
	end
	local wd = f * c_const_get("world_timeStep")

	worldTime = worldTime - timeStep
	timeStep = 0

	if worldInitialized then
		if paused then
			c_world_offsetWorldTimers(d * c_const_get("world_time"))
		else
			while worldTime < t do
				if c_world_isBehind() then
					c_world_resetBehind()

					break
				end

				--wd = worldTime - lastWorldTime / c_world_timeMultiplier()

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

				for _, v in pairs(c_world_corpses) do
					c_world_corpse_step(wd, v)
				end
				--]]

				tankbobs.w_step()

				lastWorldTime = worldTime
				worldTime = worldTime + c_world_timeMultiplier(c_const_get("world_timeStep"))
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
	local f = c_const_get("world_speed") / (c_world_timeMultiplier())
	local wd = f * common_FTM(c_const_get("world_fps"))
	lastWorldTime = t_t_getTicks() - wd
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

function c_world_getCorpses()
	return c_world_corpses
end

function c_world_timeMultiplier(v)
	if v then
		return c_const_get("world_time") * c_config_get("game.timescale") * v
	else
		return c_const_get("world_time") * c_config_get("game.timescale")
	end
end
