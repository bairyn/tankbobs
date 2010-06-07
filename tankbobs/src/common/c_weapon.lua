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
c_weapon.lua

Weapons
--]]

local c_world_tankDamage = c_world_tankDamage
local c_const_get = c_const_get
local tankbobs = tankbobs

local c_world_projectiles = {}
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
	c_const_set("projectile_max", 16384, 1)

	local weapon

	c_weapons = {}

	local kn = 12

	-- weak machinegun
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.name = "weak-machinegun"
	weapon.altName = "default"
	weapon.damage = 4
	weapon.pellets = 1
	weapon.speed = 512
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 0.2
	weapon.sa = false

	weapon.knockback = 256 / kn
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

	weapon.textureR[2](0, 1)
	weapon.textureR[3](0, 0)
	weapon.textureR[4](1, 0)
	weapon.textureR[1](1, 1)
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
	weapon.projectileRadius = false
	weapon.projectiletextureR[1](0, 1)
	weapon.projectiletextureR[2](0, 0)
	weapon.projectiletextureR[3](1, 0)
	weapon.projectiletextureR[4](1, 1)
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

	weapon.name = "machinegun"
	weapon.altName = "machinegun"
	weapon.damage = 12
	weapon.pellets = 1
	weapon.speed = 512
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 0.2
	weapon.sa = false

	weapon.knockback = 384 / kn
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

	weapon.textureR[2](0, 1)
	weapon.textureR[3](0, 0)
	weapon.textureR[4](1, 0)
	weapon.textureR[1](1, 1)
	weapon.render[1](-1, 1)
	weapon.render[2](-1, -1)
	weapon.render[3](1, -1)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "machinegun-projectile.png"
	weapon.projectileDensity = 0.5
	weapon.projectileRestitution = 1
	weapon.projectileMaxCollisions = 1
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-0.5,  0.5)
	weapon.projectileHull[2](-0.5, -0.5)
	weapon.projectileHull[3](0.5,  -0.5)
	weapon.projectileHull[4](0.5,   0.5)
	weapon.projectileRadius = 0.5
	weapon.projectiletextureR[1](0, 1)
	weapon.projectiletextureR[2](0, 0)
	weapon.projectiletextureR[3](1, 0)
	weapon.projectiletextureR[4](1, 1)
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

	weapon.name = "shotgun"
	weapon.altName = "shotgun"
	weapon.damage = 25
	weapon.pellets = 5
	weapon.speed = 512
	weapon.spread = tankbobs.m_radians(11)  -- the angle between each pellet
	weapon.repeatRate = 1
	weapon.sa = false

	weapon.knockback = 512 / kn  -- (per pellet)
	weapon.texture = "shotgun.png"
	weapon.fireSound = "shotgun2.wav"
	weapon.reloadSound = {clip = "shotgun-reload.wav", initial = "shotgun-open.wav", final = "shotgun-close.wav"}
	weapon.launchDistance = 6  -- 3 extra units to prevent the bullets from colliding before they spread
	weapon.aimAid = false
	weapon.capacity = 8
	weapon.clips = 10
	weapon.reloadTime = {clip = 0.5, initial = 1, final = 1}
	weapon.shotgunClips = true
	weapon.meleeRange = 0
	weapon.width = 0
	weapon.trail = 0
	weapon.trailWidth = 0

	weapon.textureR[2](0, 1)
	weapon.textureR[3](0, 0)
	weapon.textureR[4](1, 0)
	weapon.textureR[1](1, 1)
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
	weapon.projectileRadius = false
	weapon.projectiletextureR[1](0, 1)
	weapon.projectiletextureR[2](0, 0)
	weapon.projectiletextureR[3](1, 0)
	weapon.projectiletextureR[4](1, 1)
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

	weapon.name = "railgun"
	weapon.altName = "railgun"
	weapon.damage = 100
	weapon.pellets = 1
	weapon.speed = 4000
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 2
	weapon.sa = false

	weapon.knockback = 1024 / kn
	weapon.texture = "railgun.png"
	weapon.fireSound = {"railgun.wav", "railgun2.wav"}
	weapon.reloadSound = "railgun-reload.wav"
	weapon.launchDistance = 3.5  -- half unit to keep tank from shooting itself
	weapon.aimAid = false
	weapon.capacity = 3
	weapon.clips = 2
	weapon.reloadTime = 2
	weapon.shotgunClips = false
	weapon.meleeRange = 0
	weapon.width = 0
	weapon.trail = 1
	weapon.trailWidth = 2

	weapon.textureR[2](0, 1)
	weapon.textureR[3](0, 0)
	weapon.textureR[4](1, 0)
	weapon.textureR[1](1, 1)
	weapon.render[1](-1, 1)
	weapon.render[2](-1, -1)
	weapon.render[3](1, -1)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "railgun-projectile.png"
	weapon.projectileDensity = 0.3
	weapon.projectileRestitution = 0.03
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-1,  1)
	weapon.projectileHull[2](-1, -1)
	weapon.projectileHull[3](1,  -1)
	weapon.projectileHull[4](1,   1)
	weapon.projectileRadius = false
	weapon.projectiletextureR[1](0, 0)
	weapon.projectiletextureR[2](1, 0)
	weapon.projectiletextureR[3](0.5, 0.2)
	weapon.projectiletextureR[4](0, 0)
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

	-- semi-instagun
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.name = "semi-instagun"
	weapon.altName = "semi-instagun"
	weapon.damage = 100
	weapon.pellets = 1
	weapon.speed = 4000
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 2
	weapon.sa = false

	weapon.knockback = 1024 / kn
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

	weapon.textureR[2](0, 1)
	weapon.textureR[3](0, 0)
	weapon.textureR[4](1, 0)
	weapon.textureR[1](1, 1)
	weapon.render[1](-1, 1)
	weapon.render[2](-1, -1)
	weapon.render[3](1, -1)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "railgun-projectile.png"
	weapon.projectileDensity = 1
	weapon.projectileRestitution = 0.1
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-1,  1)
	weapon.projectileHull[2](-1, -1)
	weapon.projectileHull[3](1,  -1)
	weapon.projectileHull[4](1,   1)
	weapon.projectileRadius = false
	weapon.projectiletextureR[1](0, 0)
	weapon.projectiletextureR[2](1, 0)
	weapon.projectiletextureR[3](0.5, 0.2)
	weapon.projectiletextureR[4](0, 0)
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

	weapon.name = "instagun"
	weapon.altName = "instagun"
	weapon.damage = 1000000
	weapon.pellets = 1
	weapon.speed = 4000
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 2
	weapon.sa = false

	weapon.knockback = 1024 / kn
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

	weapon.textureR[2](0, 1)
	weapon.textureR[3](0, 0)
	weapon.textureR[4](1, 0)
	weapon.textureR[1](1, 1)
	weapon.render[1](-1, 1)
	weapon.render[2](-1, -1)
	weapon.render[3](1, -1)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "railgun-projectile.png"
	weapon.projectileDensity = 1
	weapon.projectileRestitution = 0.1
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-1,  1)
	weapon.projectileHull[2](-1, -1)
	weapon.projectileHull[3](1,  -1)
	weapon.projectileHull[4](1,   1)
	weapon.projectileRadius = false
	weapon.projectiletextureR[1](0, 0)
	weapon.projectiletextureR[2](1, 0)
	weapon.projectiletextureR[3](0.5, 0.2)
	weapon.projectiletextureR[4](0, 0)
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

	weapon.name = "coilgun"
	weapon.altName = "coilgun"
	weapon.damage = 34
	weapon.pellets = 1
	weapon.speed = 4000
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 0.25
	weapon.sa = true

	weapon.knockback = 2048 / kn
	weapon.texture = "coilgun.png"
	weapon.fireSound = {"coilgun.wav", "coilgun2.wav", "coilgun2.wav"}
	weapon.reloadSound = "coilgun-reload.wav"
	weapon.launchDistance = 3.5  -- half unit to keep tank from shooting itself
	weapon.aimAid = true
	weapon.capacity = 12
	weapon.clips = 2
	weapon.reloadTime = 1
	weapon.shotgunClips = false
	weapon.meleeRange = 0
	weapon.width = 0
	weapon.trail = 0.25
	weapon.trailWidth = 1.5

	weapon.textureR[2](0, 1)
	weapon.textureR[3](0, 0)
	weapon.textureR[4](1, 0)
	weapon.textureR[1](1, 1)
	weapon.render[1](-1, 1)
	weapon.render[2](-1, -1)
	weapon.render[3](1, -1)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "railgun-projectile.png"
	weapon.projectileDensity = 0.05
	weapon.projectileRestitution = 0.03
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-1,  1)
	weapon.projectileHull[2](-1, -1)
	weapon.projectileHull[3](1,  -1)
	weapon.projectileHull[4](1,   1)
	weapon.projectileRadius = false
	weapon.projectiletextureR[1](0, 0)
	weapon.projectiletextureR[2](1, 0)
	weapon.projectiletextureR[3](0.5, 0.2)
	weapon.projectiletextureR[4](0, 0)
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

	weapon.name = "saw"
	weapon.altName = "saw"
	weapon.damage = 150 / 8  -- 150 per second
	weapon.pellets = 0
	weapon.speed = 0
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 0.125  -- 1 / 8
	weapon.sa = false

	weapon.knockback = 0 / kn
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

	weapon.textureR[2](0, 1)
	weapon.textureR[3](0, 0)
	weapon.textureR[4](1, 0)
	weapon.textureR[1](1, 1)
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
	weapon.projectileRadius = false
	weapon.projectiletextureR[1](0, 1)
	weapon.projectiletextureR[2](0, 0)
	weapon.projectiletextureR[3](1, 0)
	weapon.projectiletextureR[4](1, 1)
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

	weapon.name = "rocket-launcher"
	weapon.altName = "rocket-launcher"
	weapon.damage = 20  -- 20 damage in addition to splash
	weapon.pellets = 1
	weapon.speed = 128
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 1
	weapon.sa = false

	weapon.knockback = 4096 / kn  -- splash will take care of this
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

	weapon.textureR[2](0, 1)
	weapon.textureR[3](0, 0)
	weapon.textureR[4](1, 0)
	weapon.textureR[1](1, 1)
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
	weapon.projectileRadius = false
	weapon.projectiletextureR[1](0, 1)
	weapon.projectiletextureR[2](0, 0)
	weapon.projectiletextureR[3](1, 0)
	weapon.projectiletextureR[4](1, 1)
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

	-- laser-gun
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.name = "laser-gun"
	weapon.altName = "laser-gun"
	weapon.damage = 60 / 8
	weapon.pellets = 0
	weapon.speed = 0
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 0.125  -- 1 / 8
	weapon.sa = false

	weapon.knockback = 0 / kn
	weapon.texture = "laser-gun.png"
	weapon.fireSound = "laser-gun.wav"
	weapon.reloadSound = "railgun-reload.wav"
	weapon.launchDistance = 2.6  -- launch at center
	weapon.aimAid = false
	weapon.capacity = 64  -- can be used for 8 seconds
	weapon.clips = 1
	weapon.reloadTime = 2
	weapon.shotgunClips = false
	weapon.meleeRange = 50
	weapon.width = 1.5
	weapon.trail = 0
	weapon.trailWidth = 0

	weapon.textureR[2](0, 1)
	weapon.textureR[3](0, 0)
	weapon.textureR[4](1, 0)
	weapon.textureR[1](1, 1)
	weapon.render[1](-1, 1)
	weapon.render[2](-1, -1)
	weapon.render[3](1, -1)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "laser-gun-projectile.png"
	weapon.projectileDensity = 0
	weapon.projectileRestitution = 0.1
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-0.5,  0.5)
	weapon.projectileHull[2](-0.5, -0.5)
	weapon.projectileHull[3](0.5,  -0.5)
	weapon.projectileHull[4](0.5,   0.5)
	weapon.projectileRadius = false
	weapon.projectiletextureR[1](0, 1)
	weapon.projectiletextureR[2](0, 0)
	weapon.projectiletextureR[3](1, 0)
	weapon.projectiletextureR[4](1, 1)
	weapon.projectileRender[4](-0.75, 50)
	weapon.projectileRender[1](-0.75, 2)
	weapon.projectileRender[2](0.75, 2)
	weapon.projectileRender[3](0.75, 50)

	weapon.projectileIsCollideSound = true

	weapon.projectileExplode = false
	weapon.projectileExplodeDamage = 0
	weapon.projectileExplodeKnockback = 0
	weapon.projectileExplodeReduce = 0
	weapon.projectileExplodeRadius = 0
	weapon.projectileExplodeSound = ""
	weapon.projectileExplodeTime = 0

	-- plasma gun
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.name = "plasma-gun"
	weapon.altName = "plasma-gun"
	weapon.damage = 60 / 8
	weapon.pellets = 0
	weapon.speed = 0
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 0.125  -- 1 / 8
	weapon.sa = false

	weapon.knockback = 0 / kn
	weapon.texture = "plasma-gun.png"
	weapon.fireSound = "plasma-gun.wav"
	weapon.reloadSound = "plasma-gun-reload.wav"
	weapon.launchDistance = 2.6  -- launch at center
	weapon.aimAid = false
	weapon.capacity = 64  -- can be used for 8 seconds
	weapon.clips = 2
	weapon.reloadTime = 4
	weapon.shotgunClips = false
	weapon.meleeRange = -12.5 / 8
	weapon.width = 1.5
	weapon.trail = 0
	weapon.trailWidth = 0

	weapon.textureR[2](0, 1)
	weapon.textureR[3](0, 0)
	weapon.textureR[4](1, 0)
	weapon.textureR[1](1, 1)
	weapon.render[1](-0.5, 0.5)
	weapon.render[2](-0.5, -0.5)
	weapon.render[3](0.5, -0.5)
	weapon.render[4](0.5, 0.5)

	weapon.projectileTexture = "plasma-gun-projectile.png"
	weapon.projectileDensity = 0
	weapon.projectileRestitution = 0.1
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](-0.5,  0.5)
	weapon.projectileHull[2](-0.5, -0.5)
	weapon.projectileHull[3](0.5,  -0.5)
	weapon.projectileHull[4](0.5,   0.5)
	weapon.projectileRadius = false
	weapon.projectiletextureR[1](0, 1)
	weapon.projectiletextureR[2](0, 0)
	weapon.projectiletextureR[3](1, 0)
	weapon.projectiletextureR[4](1, 1)
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

	for k, v in pairs(c_weapons) do
		v.index = k

		if c_weapon_doesShootProjectiles(k) then
			if v.projectileRadius then
				if not v.projectileHull then
					common_printError(0, "Warning: c_weapon_init: weapon '" .. v.name .. "' ('" .. v.altName .. "') of index " .. k .. " has a circular radius, '" .. v.projectileRadius .. "' but no approximate hull.\n")
				end

				v.m.p.fixtureDefinition = tankbobs.w_addCircularDefinition(tankbobs.m_vec2(0, 0), v.projectileRadius, v.projectileDensity, c_const_get("projectile_friction"), v.projectileRestitution, true, c_const_get("projectile_contentsMask"), c_const_get("projectile_clipmask"), c_const_get("projectile_isSensor"))
			elseif v.projectileHull then
				v.m.p.fixtureDefinition = tankbobs.w_addPolygonDefinition(v.projectileHull, v.projectileDensity, c_const_get("projectile_friction"), v.projectileRestitution, c_const_get("projectile_isSensor"), c_const_get("projectile_contentsMask"), c_const_get("projectile_clipmask"))
			else
				error("c_weapon_init: weapon '" .. v.name .. "' ('" .. v.altName .. "') of index " .. k .. " has neither a hull nor a radius!")
			end
		end
	end
end

function c_weapon_done()
	for _, v in pairs(c_weapons) do
		if v.m.p.fixtureDefinition then
			tankbobs.w_removeDefinition(v.m.p.fixtureDefinition) v.m.p.fixtureDefinition = nil
		end
	end

	c_weapon_clear(true)
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
	sa = false,
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

	textureR = {tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()},
	render = {tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()},

	-- projectiles
	projectileDensity = 0,
	projectileRestitution = 0,
	projectileMaxCollisions = 0,
	projectileEndOnBody = false,

	projectileIsCollideSound = false,

	projectileTexture = "",

	projectileHull = {tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()},
	projectileRadius = 0,

	projectiletextureR = {tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()},
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
	collisions = 0,
	owner = nil,  -- tank which fired it
	collided = false,  -- whether it needs to be removed

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
		stderr:write("c_weapon_pickUp: weapon '", tostring(weaponName), "' doesn't exist\n")
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
	if weapon.meleeRange > 0 then
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
	elseif weapon.meleeRange < 0 then
		for _, v in pairs(c_world_getTanks()) do
			if v.exists and v ~= tank then
				if (v.p - tank.p).R <= tank.radiusFireTime + 2 then
					c_weapon_meleeHit(v, tank)
				end
			end
		end
	end
end

function c_weapon_canFireInMode()
	local t = tankbobs.t_getTicks()

	if not roundStartTime then
		return true
	end

	local switch = c_world_getGameType()
	if switch == PLAGUE then
		if t < roundStartTime + c_world_timeMultiplier(c_const_get("world_plagueRoundNoFireTime")) then
			return false
		end
	elseif switch == SURVIVOR then
		if t < roundStartTime + c_world_timeMultiplier(c_const_get("world_survivorRoundNoFireTime")) then
			return false
		end
	elseif switch == TEAMSURVIVOR then
		if t < roundStartTime + c_world_timeMultiplier(c_const_get("world_teamSurvivorRoundNoFireTime")) then
			return false
		end
	end

	return true
end

function c_weapon_fire(tank, d)
	local t = tankbobs.t_getTicks()

	tank.m.firing = false

	if not tank.weapon or not tank.exists then
		return
	end

	if not c_weapon_canFireInMode() then
		return
	end

	local weapon = c_weapons[tank.weapon]

	if not weapon then
		return
	end

	if weapon.meleeRange < 0 then
		tank.radiusFireTime = math.max(0, tank.radiusFireTime - d * math.abs(weapon.meleeRange))
	else
		tank.radiusFireTime = 0
	end

	local function ret()
		-- damage tanks for some weapons even when not firing
		if weapon.meleeRange < 0 then
			while t >= tank.lastFireTime + (c_world_timeMultiplier(weapon.repeatRate)) and not tank.notFireReset do
				tank.lastFireTime = tank.lastFireTime + (c_world_timeMultiplier(weapon.repeatRate))

				c_weapon_fireMeleeWeapon(tank, weapon)
			end
		end
	end

	if not (bit.band(tank.state, FIRING) ~= 0) and (not tank.lastFireTime or t >= tank.lastFireTime + c_world_timeMultiplier(weapon.repeatRate)) then
		tank.notFireReset = false
	elseif tank.notFireReset then
		ret()

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

		ret()

		return
	end

	if not tank.lastFireTime or (tank.lastFireTime < t - (c_world_timeMultiplier(weapon.repeatRate))) then
		tank.lastFireTime = t - (c_world_timeMultiplier(weapon.repeatRate))

		if bit.band(tank.state, RELOAD) ~= 0 and not tank.reloading and tank.clips > 0 and tank.ammo < weapon.capacity then
			tank.reloading = t

			ret()

			return
		end
	end

	if bit.band(tank.state, FIRING) == 0 then
		ret()

		return
	end

	if weapon.meleeRange < 0 then
		tank.radiusFireTime = tank.radiusFireTime + 2 * d * math.abs(weapon.meleeRange)
	end

	tank.m.firing = true

	while t >= tank.lastFireTime + (c_world_timeMultiplier(weapon.repeatRate)) and not tank.notFireReset do
		tank.lastFireTime = tank.lastFireTime + (c_world_timeMultiplier(weapon.repeatRate))

		if weapon.sa then
			bit.band(tank.state, bit.bnot(FIRING))
			tank.notFireReset = true
		end

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
				local projectileIndex = #c_world_projectiles + 1
				--[[
				-- This is redundant, as "the length of a table t is defined to be any integer index n such that t[n] is not nil and t[n+1] is nil; moreover, if t[1] is nil, n can be zero."
				local reset = false
				while c_world_projectiles[index] do
					if index == #c_world_projectiles or #c_world_projectiles > c_const_get("projectile_max") then
						reset = true
					end

					index = index + 1

					if not reset and index > c_const_get("projectile_max") / 2 then
						index = -c_const_get("projectile_max") / 2
					end
				end
				--]]

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

				projectile.m.body = tankbobs.w_addBody(projectile.p, projectile.r, c_const_get("projectile_canSleep"), c_const_get("projectile_isBullet"), c_const_get("projectile_linearDamping"), c_const_get("projectile_angularDamping"), projectileIndex)
				projectile.m.fixture = tankbobs.w_addFixture(projectile.m.body, weapon.m.p.fixtureDefinition, true)
				vec.R = weapon.speed
				tankbobs.w_setLinearVelocity(projectile.m.body, vec)

				c_world_projectiles[projectileIndex] = projectile

				angle = angle - weapon.spread

				-- apply knockback impulse to the tank
				local point = tankbobs.w_getCenterOfMass(tank.m.body)
				local force = tankbobs.m_vec2()
				force.R = -weapon.knockback
				force.t = tankbobs.w_getAngle(tank.m.body)
				tankbobs.w_applyImpulse(tank.m.body, force, point)
			end
		end

		tank.ammo = tank.ammo - 1

		if tank.ammo < 0 then
			tank.ammo = 0
		end
	end
end

function c_weapon_clear(clearPersistant)
	-- don't call this function when world exists, since projectiles is set to a new table
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
		c_world_tankDamage(tank, c_weapons[projectile.weapon].damage, projectile.owner)

		c_ai_tankAttacked(tank, c_world_getTanks()[projectile.owner], c_weapons[projectile.weapon].damage)
	end
end

function c_weapon_meleeHit(tank, attacker)
	c_world_tankDamage(tank, c_weapons[attacker.weapon].damage, c_world_tankIndex(attacker))
end

function c_weapon_removeProjectile(projectile)
	for k, v in pairs(c_world_projectiles) do
		if v == projectile then
			--if not v.collided and v.m.body then
			if v.m.body then
				tankbobs.w_removeBody(v.m.body) v.m.body = nil v.m.fixture = nil
			end

			c_world_projectiles[k] = nil

			return
		end
	end

	common_printError(0, "Warning: c_weapon_removeProjectile: projectile from weapon '" .. c_weapons[projectile.weapon].name .. "' ('" .. c_weapons[projectile.weapon].altName .. "') couldn't be found in projectile table!\n")
end

function c_weapon_projectileCollided(projectile, body)
	local weapon = c_weapons[projectile.weapon]

	if body ~= projectile.m.lastBody then
		projectile.m.lastBody = body

		projectile.collisions = projectile.collisions + 1

		local tank = c_world_isBodyTank(body)
		if tank then
			tank.m.lastDamageTime = tankbobs.t_getTicks()
		end

		if weapon.projectileExplode then
			c_world_explosion(projectile.p, weapon.projectileExplodeDamage, weapon.projectileExplodeKnockback, weapon.projectileExplodeRadius, weapon.projectileExplodeReduce, projectile.owner)
		end

		if projectile.collisions > weapon.projectileMaxCollisions then
			projectile.collided = true
			return
		end

		if c_world_isBodyTank(body) and weapon.projectileEndOnBody then
			projectile.collided = true
			return
		end
	end
end

function c_weapon_doesShootProjectiles(weapon)
	return not c_weapon_isMeleeWeapon(weapon)
end

function c_weapon_isMeleeWeapon(weapon)
	if c_weapons[weapon].meleeRange ~= 0 then
		return true
	end

	return false
end

function c_weapon_getProjectiles()
	return c_world_projectiles
end

function c_weapon_resetProjectiles()
	if not common_empty(c_world_projectiles) then
		for k, v in pairs(c_world_projectiles) do
			if not v.collided and v.m.body then
				tankbobs.w_removeBody(v.m.body) v.m.body = nil v.m.fixture = nil
			end
		end

		tankbobs.t_emptyTable(c_world_projectiles)
	end
end

function c_weapon_getWeapons()
	return c_weapons
end

function c_weapon_getDefaultWeapon()
	local switch = c_world_getInstagib()
	if switch == true then
		return c_weapon_getByAltName("instagun").index
	elseif switch == "semi" then
		return c_weapon_getByAltName("semi-instagun").index
	else
		return c_weapon_getByAltName("default").index
	end
end
