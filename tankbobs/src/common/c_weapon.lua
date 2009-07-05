--[[
Copyright (C) 2008 Byron James Johnson

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

weapons
--]]

local c_world_tankDamage = c_world_tankDamage
local c_const_get = c_const_get
local tankbobs = tankbobs

local c_world_projectiles
local c_weapons

function c_weapon_init()
	c_world_tankDamage = _G.c_world_tankDamage
	c_const_get = _G.c_const_get
	tankbobs = _G.tankbobs

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
	weapon.launchDistance = 3
	weapon.aimAid = false
	weapon.capacity = 0
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

	weapon.projectileHull[1](0, 1)
	weapon.projectileHull[2](0, 0)
	weapon.projectileHull[3](1, 0)
	weapon.projectileHull[4](1, 1)
	weapon.projectileTexturer[1](0, 1)
	weapon.projectileTexturer[2](0, 0)
	weapon.projectileTexturer[3](1, 0)
	weapon.projectileTexturer[4](1, 1)
	weapon.projectileRender[2](-0.75, 0.75)
	weapon.projectileRender[3](-0.75, -0.75)
	weapon.projectileRender[4](0.75, -0.75)
	weapon.projectileRender[1](0.75, -0.75)

	-- strong machinegun
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
	weapon.launchDistance = 3
	weapon.aimAid = true
	weapon.capacity = 64
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

	weapon.projectileHull[1](0, 1)
	weapon.projectileHull[2](0, 0)
	weapon.projectileHull[3](1, 0)
	weapon.projectileHull[4](1, 1)
	weapon.projectileTexturer[1](0, 1)
	weapon.projectileTexturer[2](0, 0)
	weapon.projectileTexturer[3](1, 0)
	weapon.projectileTexturer[4](1, 1)
	weapon.projectileRender[2](-1, 1)
	weapon.projectileRender[3](-1, -1)
	weapon.projectileRender[4](1, -1)
	weapon.projectileRender[1](1, -1)

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
	weapon.launchDistance = 6  -- normally 3, but an extra unit to prevent the bullets from colliding before they spread
	weapon.aimAid = false
	weapon.capacity = 6
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

	weapon.projectileHull[1](0, 1)
	weapon.projectileHull[2](0, 0)
	weapon.projectileHull[3](1, 0)
	weapon.projectileHull[4](1, 1)
	weapon.projectileTexturer[1](0, 1)
	weapon.projectileTexturer[2](0, 0)
	weapon.projectileTexturer[3](1, 0)
	weapon.projectileTexturer[4](1, 1)
	weapon.projectileRender[2](-0.8, 0.8)
	weapon.projectileRender[3](-0.8, -0.8)
	weapon.projectileRender[4](0.8, -0.8)
	weapon.projectileRender[1](0.8, -0.8)

	-- railgun
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.index = 4
	weapon.name = "railgun"
	weapon.altName = "railgun"
	weapon.damage = 70
	weapon.pellets = 1
	weapon.speed = 524288
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 2

	weapon.knockback = 1024
	weapon.texture = "railgun.png"
	weapon.fireSound = {"railgun.wav", "railgun2.wav"}
	weapon.launchDistance = 3
	weapon.aimAid = false
	weapon.capacity = 3
	weapon.meleeRange = 0
	weapon.width = 0
	weapon.trail = 4
	weapon.trailWidth = 0.5

	weapon.texturer[2](0, 1)
	weapon.texturer[3](0, 0)
	weapon.texturer[4](1, 0)
	weapon.texturer[1](1, 1)
	weapon.render[1](-25, 1)
	weapon.render[2](-25, -25)
	weapon.render[3](25, -25)
	weapon.render[4](25, 25)

	weapon.projectileTexture = "railgun-projectile.png"
	weapon.projectileDensity = 12
	weapon.projectileRestitution = 0.1
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](0, 1)
	weapon.projectileHull[2](0, 0)
	weapon.projectileHull[3](1, 0)
	weapon.projectileHull[4](1, 1)
	weapon.projectileTexturer[1](0, 1)
	weapon.projectileTexturer[2](0, 0)
	weapon.projectileTexturer[3](1, 0)
	weapon.projectileTexturer[4](1, 1)
	weapon.projectileRender[2](-0.5, 0.5)
	weapon.projectileRender[3](-0.5, -0.5)
	weapon.projectileRender[4](0.5, -0.5)
	weapon.projectileRender[1](0.5, -0.5)

	-- coilgun
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.index = 5
	weapon.name = "coilgun"
	weapon.altName = "coilgun"
	weapon.damage = 69
	weapon.pellets = 1
	weapon.speed = 524288
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 2

	weapon.knockback = 16384
	weapon.texture = "coilgun.png"
	weapon.fireSound = {"coilgun.wav", "coilgun2.wav", "coilgun2.wav"}
	weapon.launchDistance = 3
	weapon.aimAid = true
	weapon.capacity = 3
	weapon.meleeRange = 0
	weapon.width = 0
	weapon.trail = 0.25
	weapon.trailWidth = 0.25

	weapon.texturer[2](0, 1)
	weapon.texturer[3](0, 0)
	weapon.texturer[4](1, 0)
	weapon.texturer[1](1, 1)
	weapon.render[1](-20, 20)
	weapon.render[2](-20, -20)
	weapon.render[3](20, -20)
	weapon.render[4](20, 20)

	weapon.projectileTexture = "coilgun-projectile.png"
	weapon.projectileDensity = 4
	weapon.projectileRestitution = 0.1
	weapon.projectileMaxCollisions = 0
	weapon.projectileEndOnBody = true

	weapon.projectileHull[1](0, 1)
	weapon.projectileHull[2](0, 0)
	weapon.projectileHull[3](1, 0)
	weapon.projectileHull[4](1, 1)
	weapon.projectileTexturer[1](0, 1)
	weapon.projectileTexturer[2](0, 0)
	weapon.projectileTexturer[3](1, 0)
	weapon.projectileTexturer[4](1, 1)
	weapon.projectileRender[2](-0.5, 0.5)
	weapon.projectileRender[3](-0.5, -0.5)
	weapon.projectileRender[4](0.5, -0.5)
	weapon.projectileRender[1](0.5, -0.5)

	-- saw
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.index = 6
	weapon.name = "saw"
	weapon.altName = "saw"
	weapon.damage = 69
	weapon.pellets = 1
	weapon.speed = 0
	weapon.spread = tankbobs.m_radians(0)
	weapon.repeatRate = 0.125  -- 1 / 8

	weapon.knockback = 16384
	weapon.texture = "saw.png"
	weapon.fireSound = "saw.mav"
	weapon.launchDistance = 3
	weapon.aimAid = true
	weapon.capacity = 64  -- can be used for 8 seconds
	weapon.meleeRange = 2
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

	weapon.projectileHull[1](0, 1)
	weapon.projectileHull[2](0, 0)
	weapon.projectileHull[3](1, 0)
	weapon.projectileHull[4](1, 1)
	weapon.projectileTexturer[1](0, 1)
	weapon.projectileTexturer[2](0, 0)
	weapon.projectileTexturer[3](1, 0)
	weapon.projectileTexturer[4](1, 1)
	weapon.projectileRender[2](0, 1)
	weapon.projectileRender[3](0, 0)
	weapon.projectileRender[4](1, 0)
	weapon.projectileRender[1](1, 1)
end

function c_weapon_done()
end

c_weapon =
{
	new = common_new,

	init = function (o)
		o.texturer[1] = tankbobs.m_vec2()
		o.texturer[2] = tankbobs.m_vec2()
		o.texturer[3] = tankbobs.m_vec2()
		o.texturer[4] = tankbobs.m_vec2()
		o.render[1] = tankbobs.m_vec2()
		o.render[2] = tankbobs.m_vec2()
		o.render[3] = tankbobs.m_vec2()
		o.render[4] = tankbobs.m_vec2()
		o.projectileHull[1] = tankbobs.m_vec2()
		o.projectileHull[2] = tankbobs.m_vec2()
		o.projectileHull[3] = tankbobs.m_vec2()
		o.projectileHull[4] = tankbobs.m_vec2()
		o.projectileTexturer[1] = tankbobs.m_vec2()
		o.projectileTexturer[2] = tankbobs.m_vec2()
		o.projectileTexturer[3] = tankbobs.m_vec2()
		o.projectileTexturer[4] = tankbobs.m_vec2()
		o.projectileRender[1] = tankbobs.m_vec2()
		o.projectileRender[2] = tankbobs.m_vec2()
		o.projectileRender[3] = tankbobs.m_vec2()
		o.projectileRender[4] = tankbobs.m_vec2()
	end,

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
	meleeRange = 0,
	width = 0,
	trail = 0,
	trailWidth = 0,

	texture = "",
	fireSound = "",

	texturer = {},
	render = {},

	-- projectiles
	projectileDensity = 0,
	projectileRestitution = 0,
	projectileMaxCollisions = 0,
	projectileEndOnBody = false,

	projectileTexture = "",

	projectileHull = {},
	projectileTexturer = {},
	projectileRender = {},

	m = {p = {}}
}

c_weapon_projectile =
{
	new = common_new,

	init = function (o)
		o.p[1] = tankbobs.m_vec2()
	end,

	p = {},
	weapon = nil,  -- type of the weapon which created the bolt
	r = 0,  -- rotation
	collided = false,  -- whether it needs to be removed
	collisions = 0,
	owner = nil,  -- tank which fired it

	m = {p = {}}
}

function c_weapon_getByName(name)
	for k, v in pairs(c_weapons) do
		if v.name == name then
			return v
		end
	end
end

function c_weapon_getByAltName(name)
	for k, v in pairs(c_weapons) do
		if v.altName == name then
			return v
		end
	end
end

function c_weapon_outOfAmmo(tank)
	-- return to default weapon
	tank.weapon = c_weapon_getByAltName("default")
end

function c_weapon_pickUp(tank, weaponName)
	local weapon

	tank.weapon = nil

	weapon = c_weapon_getByName(weaponName)
	if not weapon then
		weapon = c_weapon_getByAltName(weaponName)
	end

	if not weapon then
		io.stderr:write("c_weapon_pickUp: weapon '", tostring(weaponName), "' doesn't exist\n")
		return
	end

	tank.weapon = weapon
	tank.ammo = weapon.capacity
end

function c_weapon_fireMeleeWeapon(tank)
	print("TODO")
end

function c_weapon_fire(tank)
	local weapon = tank.weapon

	local angle = weapon.spread * (weapon.pellets - 1) / 2

	tank.m.empty = true

	if tank.ammo <= 0 and weapon.capacity ~= 0 then
		return c_weapon_outOfAmmo(tank)
	end

	tank.m.empty = false

	if weapon.meleeRange ~= 0 then
		return c_weapon_fireMeleeWeapon(tank)
	end

	for i = 1, weapon.pellets do
		local projectile = c_weapon_projectile:new()
		local vec = tankbobs.m_vec2()

		projectile.weapon = weapon

		vec.t = tank.r + angle
		vec.R = weapon.launchDistance
		projectile.p[1](tank.p[1] + vec)

		projectile.owner = tank

		projectile.r = vec.t

		projectile.m.body = tankbobs.w_addBody(projectile.p[1], projectile.r, c_const_get("projectile_canSleep"), c_const_get("projectile_isBullet"), c_const_get("projectile_linearDamping"), c_const_get("projectile_angularDamping"), weapon.projectileHull, weapon.projectileDensity, c_const_get("projectile_friction"), weapon.projectileRestitution, true)
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

	tank.ammo = tank.ammo - 1

	if tank.ammo < 0 then
		tank.ammo = 0
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
		c_world_tankDamage(tank, projectile.weapon.damage)

		if tank.health <= 0 then
			tank.killer = projectile.owner
		end
	end
end

function c_weapon_projectileRemove(projectile)
	for k, v in pairs(c_world_projectiles) do
		if v == projectile then
			table.remove(c_world_projectiles, k)
		end
	end
end

local function c_world_isTank(body)
	for _, v in pairs(c_world_getTanks()) do
		if v.body == body then
			return true, v
		end
	end

	return false
end

function c_weapon_projectileCollided(projectile, body)
	if body ~= projectile.m.lastBody then
		projectile.m.lastBody = body

		projectile.collisions = projectile.collisions + 1

		local tank = select(2, c_world_isTank(body))
		if tank then
			tank.m.lastDamageTime = tankbobs.t_getTicks()
		end

		if projectile.collisions > projectile.weapon.projectileMaxCollisions then
			projectile.collided = true
			return
		end

		if c_world_isTank(body) and projectile.weapon.projectileEndOnBody then
			projectile.collided = true
			return
		end
	end
end

function c_weapon_getProjectiles()
	return c_world_projectiles
end

function c_weapon_getWeapons()
	return c_weapons
end
