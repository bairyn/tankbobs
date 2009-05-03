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

function c_weapon_init()
	c_const_set("projectile_canSleep", false, 1)
	c_const_set("projectile_isBullet", true, 1)
	c_const_set("projectile_linearDamping", 0, 1)
	c_const_set("projectile_angularDamping", 0, 1)
	c_const_set("projectile_friction", 0, 1)

	c_world_projectiles = {}

	local weapon

	c_weapons = {}

	-- shotgun
	weapon = c_weapon:new()
	table.insert(c_weapons, weapon)

	weapon.name = "shotgun"
	weapon.altName = "default"  -- this is temporary since we only have one gun
	weapon.damage = 15  -- 5 hp per bullet
	weapon.pellets = 5
	weapon.speed = 1024
	weapon.spread = tankbobs.m_radians(12)  -- the angle between each pellet
	weapon.repeatRate = 0.5  -- twice a second
	weapon.knockback = 512  -- (per pellet)
	weapon.texture = "shotgun.png"
	weapon.launchDistance = 6  -- normally 3, but an extra unit to prevent the bullets from colliding before they spread

	weapon.texturer[1](0, 1)
	weapon.texturer[2](0, 0)
	weapon.texturer[3](1, 0)
	weapon.texturer[4](1, 1)
	weapon.render[1](0, 1)
	weapon.render[2](0, 0)
	weapon.render[3](1, 0)
	weapon.render[4](1, 1)

	weapon.projectileTexture = "shotgun-projectile.png"
	weapon.projectileDensity = 1
	weapon.projectileRestitution = 0.1

	weapon.projectileHull[1](0, 1)
	weapon.projectileHull[2](0, 0)
	weapon.projectileHull[3](1, 0)
	weapon.projectileHull[4](1, 1)
	weapon.projectileTexturer[1](0, 1)
	weapon.projectileTexturer[2](0, 0)
	weapon.projectileTexturer[3](1, 0)
	weapon.projectileTexturer[4](1, 1)
	weapon.projectileRender[1](0, 1)
	weapon.projectileRender[2](0, 0)
	weapon.projectileRender[3](1, 0)
	weapon.projectileRender[4](1, 1)
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

	name = "",
	altName = "",
	damage = 0,
	pellets = 0,
	spread = 0,
	repeatRate = 0,
	speed = 0,
	knockBack = 0,
	launchDistance = 0,

	texture = "",

	texturer = {},
	render = {},

	-- projectiles
	projectileDensity = 0,
	projectileRestitution = 0,

	projectileTexture = "",

	projectileHull = {},
	projectileTexturer = {},
	projectileRender = {},

	m = {}
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
	owner = nil,  -- tank which fired it

	m = {}
}

function c_weapon_getByName(name)
	for k, v in pairs(c_weapons) do
		if v.altName == name then
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

function c_weapon_fire(tank)
	local weapon = tank.weapon

	local angle = weapon.spread * (weapon.pellets - 1) / 2

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
		force.R = -weapon.knockback * c_const_get("tank_forceSpeedK")
		force.t = tankbobs.w_getAngle(tank.body)
		tankbobs.w_applyForce(tank.body, force, point)
	end
end

function c_weapon_clear()
	c_world_projectiles = {}

	for _, v in pairs(c_weapons) do
		v.m = {}
	end
end

function c_weapon_hit(tank, projectile)
	c_world_tankDamage(tank, projectile.weapon.damage)
end

function c_weapon_projectileRemove(projectile)
	for k, v in pairs(c_world_projectiles) do
		if v == projectile then
			table.remove(c_world_projectiles, k)
		end
	end
end
