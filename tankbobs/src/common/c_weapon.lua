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
c_weapon.lua

Weapons
--]]

local c_world_tankDamage = c_world_tankDamage
local c_const_get = c_const_get
local tankbobs = tankbobs

local c_world_projectiles
local c_weapons

local bit

function c_weapon_init()
	c_world_tankDamage = _G.c_world_tankDamage
	c_const_get = _G.c_const_get
	tankbobs = _G.tankbobs

	bit = c_module_load "bit"

	c_const_set("projectile_canSleep", false, 1)
	c_const_set("projectile_isBullet", true, 1)
	c_const_set("projectile_linearDamping", 0, 1)
	c_const_set("projectile_angularDamping", 0, 1)
	c_const_set("projectile_friction", 0, 1)

	c_world_projectiles = {}

	local weapon

	c_weapons = {}

	-- weak machinegun
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.index = 1
	weapon.name = "weak-machinegun"
	weapon.altName = "default"
	weapon.damage = 4
	weapon.pellets = 1
	weapon.speed = 768
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 0.2

	weapon.knockback = 256
	weapon.texture = "weak-machinegun.png"
	weapon.fireSound = "weak-machinegun.wav"
	weapon.reloadSound = "reload.wav"
	weapon.launchDistance = 3
	weapon.aimAid = false
	weapon.capacity = 0
	weapon.clips = 0
	weapon.reloadTime = 0
	weapon.shotgunClips = false
	weapon.meleeRange = 0
	weapon.width = 0
	weapon.trail = 0
	weapon.trailWidth = 0

	weapon.texturer[2](0, 1)
	weapon.texturer[3](0, 0)
	weapon.texturer[4](1, 0)
	weapon.texturer[1](1, 1)
	weapon.render[1](-1, 1)
	weapon.render[2](-1, -1)
	weapon.render[3](1, -1)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "weak-machinegun-projectile.png"
	weapon.projectileDensity = 0.125
	weapon.projectileRestitution = 0.1
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-0.5,  0.5)
	weapon.projectileHull[2](-0.5, -0.5)
	weapon.projectileHull[3](0.5,  -0.5)
	weapon.projectileHull[4](0.5,   0.5)
	weapon.projectileTexturer[1](0, 1)
	weapon.projectileTexturer[2](0, 0)
	weapon.projectileTexturer[3](1, 0)
	weapon.projectileTexturer[4](1, 1)
	weapon.projectileRender[4](-0.5, 0.5)
	weapon.projectileRender[1](-0.5, -0.5)
	weapon.projectileRender[2](0.5, -0.5)
	weapon.projectileRender[3](0.5, 0.5)

	weapon.projectileIsCollideSound = true

	weapon.projectileExplode = false
	weapon.projectileExplodeDamage = 0
	weapon.projectileExplodeKnockback = 0
	weapon.projectileExplodeReduce = 0
	weapon.projectileExplodeRadius = 0
	weapon.projectileExplodeSound = ""
	weapon.projectileExplodeTime = 0

	-- machinegun
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.index = 2
	weapon.name = "machinegun"
	weapon.altName = "machinegun"
	weapon.damage = 4
	weapon.pellets = 1
	weapon.speed = 1536
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 0.2

	weapon.knockback = 384
	weapon.texture = "machinegun.png"
	weapon.fireSound = {"machinegun.wav", "machinegun2.wav"}
	weapon.reloadSound = "reload.wav"
	weapon.launchDistance = 3
	weapon.aimAid = true
	weapon.capacity = 15
	weapon.clips = 4
	weapon.reloadTime = 2
	weapon.shotgunClips = false
	weapon.meleeRange = 0
	weapon.width = 0
	weapon.trail = 0
	weapon.trailWidth = 0

	weapon.texturer[2](0, 1)
	weapon.texturer[3](0, 0)
	weapon.texturer[4](1, 0)
	weapon.texturer[1](1, 1)
	weapon.render[1](-1, 1)
	weapon.render[2](-1, -1)
	weapon.render[3](1, -1)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "machinegun-projectile.png"
	weapon.projectileDensity = 1.25
	weapon.projectileRestitution = 1
	weapon.projectileMaxCollisions = 1
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-0.5,  0.5)
	weapon.projectileHull[2](-0.5, -0.5)
	weapon.projectileHull[3](0.5,  -0.5)
	weapon.projectileHull[4](0.5,   0.5)
	weapon.projectileTexturer[1](0, 1)
	weapon.projectileTexturer[2](0, 0)
	weapon.projectileTexturer[3](1, 0)
	weapon.projectileTexturer[4](1, 1)
	weapon.projectileRender[4](-0.75, 0.75)
	weapon.projectileRender[1](-0.75, -0.75)
	weapon.projectileRender[2](0.75, -0.75)
	weapon.projectileRender[3](0.75, 0.75)

	weapon.projectileIsCollideSound = true

	weapon.projectileExplode = false
	weapon.projectileExplodeDamage = 0
	weapon.projectileExplodeKnockback = 0
	weapon.projectileExplodeReduce = 0
	weapon.projectileExplodeRadius = 0
	weapon.projectileExplodeSound = ""
	weapon.projectileExplodeTime = 0

	-- shotgun
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.index = 3
	weapon.name = "shotgun"
	weapon.altName = "shotgun"
	weapon.damage = 25
	weapon.pellets = 5
	weapon.speed = 1024
	weapon.spread = tankbobs.m_radians(12)  -- the angle between each pellet
	weapon.repeatRate = 1
	weapon.knockback = 512  -- (per pellet)
	weapon.texture = "shotgun.png"
	weapon.fireSound = "shotgun2.wav"
	weapon.reloadSound = {clip = "shotgun-reload.wav", initial = "shotgun-open.wav", final = "shotgun-close.wav"}
	weapon.launchDistance = 6  -- 3 extra units to prevent the bullets from colliding before they spread
	weapon.aimAid = false
	weapon.capacity = 4
	weapon.clips = 8
	weapon.reloadTime = {clip = 0.5, initial = 1, final = 1}
	weapon.shotgunClips = true
	weapon.meleeRange = 0
	weapon.width = 0
	weapon.trail = 0
	weapon.trailWidth = 0

	weapon.texturer[2](0, 1)
	weapon.texturer[3](0, 0)
	weapon.texturer[4](1, 0)
	weapon.texturer[1](1, 1)
	weapon.render[1](-1, 1)
	weapon.render[2](-1, -1)
	weapon.render[3](1, -1)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "shotgun-projectile.png"
	weapon.projectileDensity = 1
	weapon.projectileRestitution = 0.1
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-0.5,  0.5)
	weapon.projectileHull[2](-0.5, -0.5)
	weapon.projectileHull[3](0.5,  -0.5)
	weapon.projectileHull[4](0.5,   0.5)
	weapon.projectileTexturer[1](0, 1)
	weapon.projectileTexturer[2](0, 0)
	weapon.projectileTexturer[3](1, 0)
	weapon.projectileTexturer[4](1, 1)
	weapon.projectileRender[4](-0.66, 0.66)
	weapon.projectileRender[1](-0.66, -0.66)
	weapon.projectileRender[2](0.66, -0.66)
	weapon.projectileRender[3](0.66, 0.66)

	weapon.projectileIsCollideSound = true

	weapon.projectileExplode = false
	weapon.projectileExplodeDamage = 0
	weapon.projectileExplodeKnockback = 0
	weapon.projectileExplodeReduce = 0
	weapon.projectileExplodeRadius = 0
	weapon.projectileExplodeSound = ""
	weapon.projectileExplodeTime = 0

	-- railgun
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.index = 4
	weapon.name = "railgun"
	weapon.altName = "railgun"
	weapon.damage = 100
	weapon.pellets = 1
	weapon.speed = 524288
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 2

	weapon.knockback = 1024
	weapon.texture = "railgun.png"
	weapon.fireSound = {"railgun.wav", "railgun2.wav"}
	weapon.reloadSound = "railgun-reload.wav"
	weapon.launchDistance = 3.5  -- half unit to keep tank from shooting itself
	weapon.aimAid = false
	weapon.capacity = 2
	weapon.clips = 4
	weapon.reloadTime = 2
	weapon.shotgunClips = false
	weapon.meleeRange = 0
	weapon.width = 0
	weapon.trail = 1
	weapon.trailWidth = 2

	weapon.texturer[2](0, 1)
	weapon.texturer[3](0, 0)
	weapon.texturer[4](1, 0)
	weapon.texturer[1](1, 1)
	weapon.render[1](-1, 1)
	weapon.render[2](-1, -1)
	weapon.render[3](1, -1)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "railgun-projectile.png"
	weapon.projectileDensity = 12
	weapon.projectileRestitution = 0.1
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-1,  1)
	weapon.projectileHull[2](-1, -1)
	weapon.projectileHull[3](1,  -1)
	weapon.projectileHull[4](1,   1)
	weapon.projectileTexturer[1](0, 0)
	weapon.projectileTexturer[2](1, 0)
	weapon.projectileTexturer[3](0.5, 0.2)
	weapon.projectileTexturer[4](0, 0)
	weapon.projectileRender[4](0, 0)
	weapon.projectileRender[1](0, 0)
	weapon.projectileRender[2](0, 0)
	weapon.projectileRender[3](0, 0)

	weapon.projectileIsCollideSound = true

	weapon.projectileExplode = false
	weapon.projectileExplodeDamage = 0
	weapon.projectileExplodeKnockback = 0
	weapon.projectileExplodeReduce = 0
	weapon.projectileExplodeRadius = 0
	weapon.projectileExplodeSound = ""
	weapon.projectileExplodeTime = 0

	-- instagun
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.index = 5
	weapon.name = "instagun"
	weapon.altName = "instagun"
	weapon.damage = 100
	weapon.pellets = 1.5
	weapon.speed = 524288
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 2

	weapon.knockback = 1024
	weapon.texture = "railgun.png"
	weapon.fireSound = {"railgun.wav", "railgun2.wav"}
	weapon.reloadSound = "railgun-reload.wav"
	weapon.launchDistance = 3.5  -- half unit to keep tank from shooting itself
	weapon.aimAid = false
	weapon.capacity = 0
	weapon.clips = 0
	weapon.reloadTime = 0
	weapon.shotgunClips = false
	weapon.meleeRange = 0
	weapon.width = 0
	weapon.trail = 1
	weapon.trailWidth = 2

	weapon.texturer[2](0, 1)
	weapon.texturer[3](0, 0)
	weapon.texturer[4](1, 0)
	weapon.texturer[1](1, 1)
	weapon.render[1](-1, 1)
	weapon.render[2](-1, -1)
	weapon.render[3](1, -1)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "railgun-projectile.png"
	weapon.projectileDensity = 8
	weapon.projectileRestitution = 0.1
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-1,  1)
	weapon.projectileHull[2](-1, -1)
	weapon.projectileHull[3](1,  -1)
	weapon.projectileHull[4](1,   1)
	weapon.projectileTexturer[1](0, 0)
	weapon.projectileTexturer[2](1, 0)
	weapon.projectileTexturer[3](0.5, 0.2)
	weapon.projectileTexturer[4](0, 0)
	weapon.projectileRender[4](0, 0)
	weapon.projectileRender[1](0, 0)
	weapon.projectileRender[2](0, 0)
	weapon.projectileRender[3](0, 0)

	weapon.projectileIsCollideSound = true

	weapon.projectileExplode = false
	weapon.projectileExplodeDamage = 0
	weapon.projectileExplodeKnockback = 0
	weapon.projectileExplodeReduce = 0
	weapon.projectileExplodeRadius = 0
	weapon.projectileExplodeSound = ""
	weapon.projectileExplodeTime = 0

	-- coilgun
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.index = 6
	weapon.name = "coilgun"
	weapon.altName = "coilgun"
	weapon.damage = 85
	weapon.pellets = 1
	weapon.speed = 524288
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 2

	weapon.knockback = 8192
	weapon.texture = "coilgun.png"
	weapon.fireSound = {"coilgun.wav", "coilgun2.wav", "coilgun2.wav"}
	weapon.reloadSound = "reload.wav"
	weapon.launchDistance = 3.5  -- half unit to keep tank from shooting itself
	weapon.aimAid = true
	weapon.capacity = 2
	weapon.clips = 3
	weapon.reloadTime = 2
	weapon.shotgunClips = false
	weapon.meleeRange = 0
	weapon.width = 0
	weapon.trail = 0.25
	weapon.trailWidth = 1.5

	weapon.texturer[2](0, 1)
	weapon.texturer[3](0, 0)
	weapon.texturer[4](1, 0)
	weapon.texturer[1](1, 1)
	weapon.render[1](-1, 1)
	weapon.render[2](-1, -1)
	weapon.render[3](1, -1)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "railgun-projectile.png"
	weapon.projectileDensity = 4
	weapon.projectileRestitution = 0.1
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-1,  1)
	weapon.projectileHull[2](-1, -1)
	weapon.projectileHull[3](1,  -1)
	weapon.projectileHull[4](1,   1)
	weapon.projectileTexturer[1](0, 0)
	weapon.projectileTexturer[2](1, 0)
	weapon.projectileTexturer[3](0.5, 0.2)
	weapon.projectileTexturer[4](0, 0)
	weapon.projectileRender[4](0, 0)
	weapon.projectileRender[1](0, 0)
	weapon.projectileRender[2](0, 0)
	weapon.projectileRender[3](0, 0)

	weapon.projectileIsCollideSound = true

	weapon.projectileExplode = false
	weapon.projectileExplodeDamage = 0
	weapon.projectileExplodeKnockback = 0
	weapon.projectileExplodeReduce = 0
	weapon.projectileExplodeRadius = 0
	weapon.projectileExplodeSound = ""
	weapon.projectileExplodeTime = 0

	-- saw
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.index = 7
	weapon.name = "saw"
	weapon.altName = "saw"
	weapon.damage = 150 / 8
	weapon.pellets = 1
	weapon.speed = 0
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 0.125  -- 1 / 8

	weapon.knockback = 16384
	weapon.texture = "saw.png"
	weapon.fireSound = "saw.wav"
	weapon.reloadSound = "railgun-reload.wav"
	weapon.launchDistance = 2.6  -- launch at center
	weapon.aimAid = false
	weapon.capacity = 64  -- can be used for 8 seconds
	weapon.clips = 1
	weapon.reloadTime = 2
	weapon.shotgunClips = false
	weapon.meleeRange = 4.9
	weapon.width = 0.75
	weapon.trail = 0
	weapon.trailWidth = 0

	weapon.texturer[2](0, 1)
	weapon.texturer[3](0, 0)
	weapon.texturer[4](1, 0)
	weapon.texturer[1](1, 1)
	weapon.render[1](-1, 1)
	weapon.render[2](-1, -1)
	weapon.render[3](1, -1)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "saw-projectile.png"
	weapon.projectileDensity = 0
	weapon.projectileRestitution = 0.1
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-0.5,  0.5)
	weapon.projectileHull[2](-0.5, -0.5)
	weapon.projectileHull[3](0.5,  -0.5)
	weapon.projectileHull[4](0.5,   0.5)
	weapon.projectileTexturer[1](0, 1)
	weapon.projectileTexturer[2](0, 0)
	weapon.projectileTexturer[3](1, 0)
	weapon.projectileTexturer[4](1, 1)
	weapon.projectileRender[4](-0.2, 6)
	weapon.projectileRender[1](-0.2, 2)
	weapon.projectileRender[2](0.2, 2)
	weapon.projectileRender[3](0.2, 6)

	weapon.projectileIsCollideSound = true

	weapon.projectileExplode = false
	weapon.projectileExplodeDamage = 0
	weapon.projectileExplodeKnockback = 0
	weapon.projectileExplodeReduce = 0
	weapon.projectileExplodeRadius = 0
	weapon.projectileExplodeSound = ""
	weapon.projectileExplodeTime = 0

	-- rocket launcher
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.index = 8
	weapon.name = "rocket-launcher"
	weapon.altName = "rocket-launcher"
	weapon.damage = 20  -- 20 damage in addition to splash
	weapon.pellets = 1
	weapon.speed = 64
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 1

	weapon.knockback = 0  -- splash will take care of this
	weapon.texture = "rocket-launcher.png"
	weapon.fireSound = "rocket-launcher.wav"
	weapon.reloadSound = "railgun-reload.wav"
	weapon.launchDistance = 3.6  -- launch at center
	weapon.aimAid = false
	weapon.capacity = 4
	weapon.clips = 2
	weapon.reloadTime = 4
	weapon.shotgunClips = false
	weapon.meleeRange = 0
	weapon.width = 0
	weapon.trail = 0
	weapon.trailWidth = 0

	weapon.texturer[2](0, 1)
	weapon.texturer[3](0, 0)
	weapon.texturer[4](1, 0)
	weapon.texturer[1](1, 1)
	weapon.render[1](-1, 1)
	weapon.render[2](-1, -1)
	weapon.render[3](1, -1)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "rocket-launcher-projectile.png"
	weapon.projectileDensity = 1.25
	weapon.projectileRestitution = 1
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-0.5,  1)
	weapon.projectileHull[2](-0.5, -1)
	weapon.projectileHull[3](0.5,  -1)
	weapon.projectileHull[4](0.5,   1)
	weapon.projectileTexturer[1](0, 1)
	weapon.projectileTexturer[2](0, 0)
	weapon.projectileTexturer[3](1, 0)
	weapon.projectileTexturer[4](1, 1)
	weapon.projectileRender[4](-1, 1)
	weapon.projectileRender[1](-1, -1)
	weapon.projectileRender[2](1, -1)
	weapon.projectileRender[3](1, 1)

	weapon.projectileIsCollideSound = false

	weapon.projectileExplode = true
	weapon.projectileExplodeDamage = 120
	weapon.projectileExplodeKnockback = 56
	weapon.projectileExplodeReduce = 1.4
	weapon.projectileExplodeRadius = 30
	weapon.projectileExplodeSound = "rocket-launcher-projectile-explode.wav"
	weapon.projectileExplodeTime = 0.5
end

function c_weapon_done()
end

c_weapon =
{
	new = c_class_new,

	index = 0,
	name = "",
	altName = "",
	damage = 0,
	pellets = 0,
	spread = 0,
	repeatRate = 0,
	speed = 0,
	knockBack = 0,
	launchDistance = 0,
	aimAid = false,
	capacity = 0,
	clips = 0,  -- clips remaining
	reloadTime = 0,
	shotgunClips = false,
	meleeRange = 0,
	width = 0,
	trail = 0,
	trailWidth = 0,

	texture = "",
	fireSound = "",
	reloadSound = "",

	texturer = {tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()},
	render = {tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()},

	-- projectiles
	projectileDensity = 0,
	projectileRestitution = 0,
	projectileMaxCollisions = 0,
	projectileEndOnBody = false,

	projectileIsCollideSound = false,

	projectileTexture = "",

	projectileHull = {tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()},
	projectileTexturer = {tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()},
	projectileRender = {tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()},

	projectileExplode = false,
	projectileExplodeDamage = 0,
	projectileExplodeKnockback = 0,
	projectileExplodeReduce = 0,
	projectileExplodeRadius = 0,
	projectileExplodeSound = "",

	m = {p = {}}
}

c_weapon_projectile =
{
	new = c_class_new,

	p = tankbobs.m_vec2(),
	weapon = nil,  -- type of the weapon which created the bolt
	r = 0,  -- rotation
	collided = false,  -- whether it needs to be removed
	collisions = 0,
	owner = nil,  -- tank which fired it

	m = {p = {}}
}

function c_weapon_getByName(name)
	for _, v in pairs(c_weapons) do
		if v.name == name then
			return v
		end
	end
end

function c_weapon_getByAltName(name)
	for _, v in pairs(c_weapons) do
		if v.altName == name then
			return v
		end
	end
end

function c_weapon_outOfAmmo(tank)
	-- return to default weapon
	tank.weapon = c_weapon_getByAltName("default").index
end

function c_weapon_pickUp(tank, weaponName)
	local weapon

	weapon = c_weapon_getByName(weaponName)
	if not weapon then
		weapon = c_weapon_getByAltName(weaponName)
	end

	if not weapon then
		io.stderr:write("c_weapon_pickUp: weapon '", tostring(weaponName), "' doesn't exist\n")
		return
	end

	if weapon == c_weapons[tank.weapon] then
		-- add to clips
		if weapon.clips == 0 then
			tank.clips = tank.clips + 1
		else
			tank.clips = tank.clips + weapon.clips
		end

		return
	end

	tank.weapon = weapon.index
	tank.ammo = weapon.capacity
	tank.clips = weapon.clips
	tank.reloading = false
	tank.shotgunReloadState = nil
end

function c_weapon_fireMeleeWeapon(tank, weapon)
	local start, endP, tmp = tankbobs.m_vec2(tank.p), tankbobs.m_vec2(), tankbobs.m_vec2()

	tmp.t = tank.r
	tmp.R = weapon.launchDistance
	start:add(tmp)

	endP(start)
	tmp.R = weapon.meleeRange
	endP:add(tmp)

	local status, _, typeOfTarget, target = c_world_findClosestIntersection(start, endP)
	if status then
		if typeOfTarget == "tank" then
			c_weapon_meleeHit(target, tank)
		end
	end
end

function c_weapon_fire(tank)
	local t = tankbobs.t_getTicks()

	if not tank.weapon or not tank.exists then
		return
	end

	local weapon = c_weapons[tank.weapon]

	if not weapon then
		return
	end

	if tank.reloading then
		if weapon.shotgunClips then
			if not tank.shotgunReloadState then
				tank.reloading = t

				tank.shotgunReloadState = 0
			else
				if tank.shotgunReloadState == 0 then
					-- initial

					if t >= tank.reloading + (c_world_timeMultiplier(weapon.reloadTime.initial)) then
						tank.reloading = t

						tank.shotgunReloadState = 1

						tank.clips = tank.clips - 1
						tank.ammo = tank.ammo + 1
					end
				elseif tank.shotgunReloadState == 1 then
					-- clip

					if t >= tank.reloading + (c_world_timeMultiplier(weapon.reloadTime.clip)) then
						if tank.ammo < weapon.capacity and tank.clips > 0 and bit.band(tank.state, RELOAD) ~= 0 then
							tank.reloading = t

							tank.clips = tank.clips - 1
							tank.ammo = tank.ammo + 1
						else
							tank.reloading = t

							tank.shotgunReloadState = 2
						end
					end
				elseif tank.shotgunReloadState == 2 then
					-- final

					if t >= tank.reloading + (c_world_timeMultiplier(weapon.reloadTime.initial)) then
						tank.reloading = false

						tank.shotgunReloadState = nil
					end
				end
			end
		else
			if t >= tank.reloading + (c_world_timeMultiplier(weapon.reloadTime)) then
				tank.reloading = false

				tank.clips = tank.clips - 1
				tank.ammo = weapon.capacity
			end
		end

		tank.m.fired = false

		return
	end

	if not tank.lastFireTime or (tank.lastFireTime < t - (c_world_timeMultiplier(weapon.repeatRate))) then
		tank.lastFireTime = t - (c_world_timeMultiplier(weapon.repeatRate))

		if bit.band(tank.state, RELOAD) ~= 0 and not tank.reloading and tank.clips > 0 and tank.ammo < weapon.capacity then
			tank.reloading = t

			return
		end
	end

	if bit.band(tank.state, FIRING) == 0 then
		return
	end

	while t >= tank.lastFireTime + (c_world_timeMultiplier(weapon.repeatRate)) do
		tank.lastFireTime = tank.lastFireTime + (c_world_timeMultiplier(weapon.repeatRate))

		local angle = weapon.spread * (weapon.pellets - 1) / 2

		tank.m.empty = false
		tank.m.fired = false

		if tank.ammo <= 0 and weapon.capacity ~= 0 then
			--if not tank.reloading then  -- redundant
				if tank.clips <= 0 then
					tank.m.empty = true

					return c_weapon_outOfAmmo(tank)
				else
					tank.reloading = t

					return
				end
			--end
		end

		tank.m.fired = true

		if weapon.meleeRange ~= 0 then
			c_weapon_fireMeleeWeapon(tank, weapon)
		else
			for i = 1, weapon.pellets do
				local projectile = c_weapon_projectile:new()
				local vec = tankbobs.m_vec2()

				projectile.weapon = weapon.index

				vec.t = tank.r + angle
				vec.R = weapon.launchDistance
				projectile.p(tank.p + vec)

				local index = 0
				for k, v in pairs(c_world_getTanks()) do
					if v == tank then
						index = k
					end
				end

				projectile.owner = index

				projectile.r = vec.t

				projectile.m.body = tankbobs.w_addBody(projectile.p, projectile.r, c_const_get("projectile_canSleep"), c_const_get("projectile_isBullet"), c_const_get("projectile_linearDamping"), c_const_get("projectile_angularDamping"), weapon.projectileHull, weapon.projectileDensity, c_const_get("projectile_friction"), weapon.projectileRestitution, true, c_const_get("projectile_contentsMask"), c_const_get("projectile_clipmask"), c_const_get("projectile_isSensor"), #c_world_projectiles + 1)
				vec.R = weapon.speed
				tankbobs.w_setLinearVelocity(projectile.m.body, vec)

				table.insert(c_world_projectiles, projectile)

				angle = angle - weapon.spread

				-- apply knockback to the tank
				local point = tankbobs.w_getCenterOfMass(tank.body)
				local force = tankbobs.m_vec2()
				force.R = -weapon.knockback * c_const_get("tank_speedK")
				force.t = tankbobs.w_getAngle(tank.body)
				tankbobs.w_applyForce(tank.body, force, point)
			end
		end

		tank.ammo = tank.ammo - 1

		if tank.ammo < 0 then
			tank.ammo = 0
		end
	end
end

function c_weapon_clear(clearPersistant)
	c_world_projectiles = {}

	for _, v in pairs(c_weapons) do
		local pers = v.m.p
		v.m = {p = {}}
		if not clearPersistant then
			v.m.p = pers
		end
	end
end

function c_weapon_hit(tank, projectile)
	if not projectile.collided then
		c_world_tankDamage(tank, c_weapons[projectile.weapon].damage)

		if tank.health <= 0 then
			tank.killer = projectile.owner
		end

		c_ai_tankAttacked(tank, c_world_getTanks()[projectile.owner], c_weapons[projectile.weapon].damage)
	end
end

function c_weapon_meleeHit(tank, attacker)
	c_world_tankDamage(tank, c_weapons[attacker.weapon].damage)

	if tank.health <= 0 then
		for k, v in pairs(c_world_getTanks()) do
			if v == attacker then
				tank.killer = k
			end
		end
	end
end

function c_weapon_projectileRemove(projectile)
	for k, v in pairs(c_world_projectiles) do
		if v == projectile then
			c_world_projectiles[k] = nil
		end
	end
end

local function c_world_isTank(body)
	if tankbobs.w_getContents(body) == TANK then
		return c_world_getTanks()[tankbobs.w_getIndex(body)]
	end

	return nil
end

function c_weapon_projectileCollided(projectile, body)
	local weapon = c_weapons[projectile.weapon]

	if body ~= projectile.m.lastBody then
		projectile.m.lastBody = body

		projectile.collisions = projectile.collisions + 1

		local tank = c_world_isTank(body)
		if tank then
			tank.m.lastDamageTime = tankbobs.t_getTicks()
		end

		if weapon.projectileExplode then
			c_world_explosion(projectile.p, weapon.projectileExplodeDamage, weapon.projectileExplodeKnockback, weapon.projectileExplodeRadius, weapon.projectileExplodeReduce, c_world_getTanks()[projectile.owner])
		end

		if projectile.collisions > weapon.projectileMaxCollisions then
			projectile.collided = true
			return
		end

		if c_world_isTank(body) and weapon.projectileEndOnBody then
			projectile.collided = true
			return
		end
	end
end

function c_weapon_getProjectiles()
	return c_world_projectiles
end

function c_weapon_resetProjectiles()
	if not common_empty(c_world_projectiles) then
		for k, v in pairs(c_world_projectiles) do
			if not v.collided and v.m.body then
				tankbobs.w_removeBody(v.m.body)
				v.m.body = nil
			end
		end

		tankbobs.t_emptyTable(c_world_projectiles)
	end
end

function c_weapon_getWeapons()
	return c_weapons
end

function c_weapon_getDefaultWeapon()
	if c_world_getInstagib() then
		return c_weapon_getByAltName("instagun").index
	else
		return c_weapon_getByAltName("default").index
	end
end
