--[[
Copyright (C) 2008-2010 Byron James Johnson

This file is part of Tankbobs.

	Tankbobs is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	Tankbobs is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
along with Tankbobs.  If not, see <http://www.gnu.org/licenses/>.
--]]

--[[
c_protocol.lua
Link after c_world.lua

Network protocol
--]]

local protocol_version = 1

-- Types

local DOUBLE    = 1
local FLOAT     = 2
local INT       = 3
local NILINT    = 4  -- MAGIC is nil
local SHORT     = 5
local CHAR      = 6
local BOOL      = 7
local STRING    = 8
local NILSTRING = 9  -- Empty string is nil
local VEC2      = 10

-- How value is referenced

local VT_FUNCTION = 0
local VT_STRING   = 1

local function identifier(id)
	if id < 0xFF then
		return id
	else
		local safe = 0
		local acc = 0xFF

		while acc <= id do
			safe = safe + 1
			if safe >= 100 then
				error("Infinite loop in function identifier()")
			end

			acc = bit.lshift(acc, 8)
		end

		return bit.bor(acc, id)
	end
end

local startIdentifier = 0
local nextIdentifier
local function increment()
	if not nextIdentifier then
		nextIdentifier = startIdentifier
	else
		nextIdentifier = nextIdentifier + 1
	end

	return nextIdentifier
end

local function resetIncrement()
	nextIdentifier = nil
end

local parseIndex = 1
local function nextParse(parse)
	parseIndex = parseIndex + 1

	return parse[parseIndex]
end

local function newParse(parse)
	if parse then
		parseIndex = 1

		return parse[parseIndex]
	else
		parseIndex = 0

		return
	end
end

local putIndex = 1
local putTable = nil
local function nextPut(value)
	putIndex = putIndex + 1

	putTable[putIndex] = value

	return
end

local function newPut(t, value)
	t = t or putTable
	putTable = t

	if value then
		putIndex = 1

		putTable[putIndex] = value
	else
		putIndex = 0
	end
end


local numProjectiles = nil
local function setNumProjectiles(num)
	numProjectiles = num

	c_weapon_resetProjectiles()
end

local function setNumTanks(num)
	local oldNum = #c_world_getTanks()

	for i = oldNum + 1, num do
		-- add tank
		local tank = c_world_tank:new()
		c_world_getTanks()[i] = tank
		c_world_tank_spawn(tank)
	end

	for i = oldNum, num + 1, -1 do
		-- remove tank
		local tank = c_world_getTanks()[i]
		if tank then
			c_world_tank_die(tank)
			c_world_removeTank(tank)
		end
	end
end

local function setNumCorpses(num)
	local oldNum = #c_world_getCorpses()

	for i = oldNum + 1, num do
		-- add corpse
		local corpse = c_world_addCorpse({i})
	end

	for i = oldNum, num + 1, -1 do
		-- remove corpse
		local corpse = c_world_getTanks()[i]
		if corpse then
			c_world_removeCorpse(corpse)
		end
	end
end

local function setNumPowerups(num)
	local oldNum = #c_world_getPowerups()

	for i = oldNum + 1, num do
		-- add powerup
		local powerup = c_world_powerup:new()
		table.insert(c_world_getPowerups(), powerup)
		powerup.spawnTime = tankbobs.t_getTicks()

		c_world_spawnPowerup(powerup)

		-- add some initial push to the powerup
		local push = tankbobs.m_vec2()
		push.R = c_const_get("powerup_pushStrength")
		push.t = c_const_get("powerup_pushAngle")
		tankbobs.w_setLinearVelocity(powerup.m.body, push)
	end

	for i = oldNum, num + 1, -1 do
		-- remove powerup
		local powerup = c_world_getPowerups()[i]
		if powerup then
			tankbobs.w_removeBody(powerup.m.body)
			c_world_powerupRemove(powerup)
		end
	end
end

local function setNumWalls(num)
	if num ~= #c_tcm_current_map.walls then
		-- silently ignore
	end
end

local function setNumControlPoints(num)
	if num ~= #c_tcm_current_map.controlPoints then
		-- silently ignore
	end
end

local function setNumFlags(num)
	if num ~= #c_tcm_current_map.flags then
		-- silently ignore
	end
end

resetIncrement()
protocol_unpersist =
{
	{DOUBLE, FLOAT, INT, NILINT, SHORT, CHAR, BOOL, STRING, NILSTRING, VEC2},
	{VT_FUNCTION, VT_STRING},

	{
		-- Timestamp
		{ identifier(increment())
		, nil  -- Always send and store this (function)
		, VT_STRING
		, "connection.serverTimestamp"
		, INT
		},
		-- Pause state
		{ identifier(increment())
		, nil  -- Always send and store this (function)
		, VT_FUNCTION
		, c_world_setPaused
		, BOOL
		},

		-- Scores
		{ identifier(increment())
		, c_world_gameTypeTeam
		, VT_STRING
		, "c_world_blueTeam.score"
		, INT
		},
		{ identifier(increment())
		, c_world_gameTypeTeam
		, VT_STRING
		, "c_world_redTeam.score"
		, INT
		},

		-- Set number of entities
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, setNumProjectiles
		, INT
		},
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, setNumTanks
		, INT
		},
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, setNumCorpses
		, INT
		},
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, setNumPowerups
		, INT
		},
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, setNumWalls
		, INT
		},
		{ identifier(increment())
		, function() return c_world_getGameType() == DOMINATION end
		, VT_FUNCTION
		, setNumControlPoints
		, INT
		},
		{ identifier(increment())
		, function() return c_world_getGameType() == CAPTURETHEFLAG end
		, VT_FUNCTION
		, setNumFlags
		, INT
		},

		-- projectiles
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, function(parse)
			-- Projectiles are reset and created
			local projectile = c_weapon_projectile:new()

			newParse()

			projectile.p(nextParse(parse))
			local velocity = nextParse(parse)
			local angularVelocity = nextParse(parse)
			projectile.weapon = nextParse(parse)
			projectile.r = nextParse(parse)
			projectile.collisions = nextParse(parse)
			projectile.owner = nextParse(parse)
			projectile.collided = nextParse(parse)

			if c_weapon_getWeapons()[projectile.weapon] then
				table.insert(c_weapon_getProjectiles(), projectile)

				projectile.m.body = tankbobs.w_addBody(projectile.p, projectile.r, c_const_get("projectile_canSleep"), c_const_get("projectile_isBullet"), c_const_get("projectile_linearDamping"), c_const_get("projectile_angularDamping"), #c_weapon_getProjectiles())
				projectile.m.fixture = tankbobs.w_addFixture(projectile.m.body, c_weapon_getWeapons()[projectile.weapon].m.p.fixtureDefinition, true)
				tankbobs.w_setLinearVelocity(projectile.m.body, velocity)
				tankbobs.w_setAngularVelocity(projectile.m.body, angularVelocity)
			end
		  end
		, { VEC2
		  , VEC2
		  , DOUBLE
		  , INT
		  , DOUBLE
		  , INT
		  , INT
		  , BOOL
		  }
		},

		-- tanks
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, function(parse)
			local tank = c_world_getTanks()[newParse(parse)]

			if not tank then
				return
			end

			tank.p(nextParse(parse))
			local velocity = nextParse(parse)
			local angularVelocity = nextParse(parse)
			tank.h[1](nextParse(parse))
			tank.h[2](nextParse(parse))
			tank.h[3](nextParse(parse))
			tank.h[4](nextParse(parse))
			tank.r = nextParse(parse)
			tank.name = nextParse(parse)
			local oldExists = tank.exists
			tank.exists = nextParse(parse)
			if not tank.exists and oldExists then
				tank.exists = true
				c_world_tank_die(tank)
			end
			tank.spawning = nextParse(parse)
			tank.lastSpawnPoint = nextParse(parse)
			tank.state = bit.tobit(nextParse(parse))
			tank.weapon = nextParse(parse)
			tank.health = nextParse(parse)
			tank.shield = nextParse(parse)
			tank.killer = nextParse(parse)
			tank.score = nextParse(parse)
			tank.ammo = nextParse(parse)
			tank.clips = nextParse(parse)
			tank.cd.acceleration = nextParse(parse)
			tank.cd.aimAid = nextParse(parse)
			tank.reloading = nextParse(parse)
			tank.shotgunReloadState = nextParse(parse)
			tank.red = nextParse(parse)
			tank.color.r = nextParse(parse)
			tank.color.g = nextParse(parse)
			tank.color.b = nextParse(parse)
			tank.tagged = nextParse(parse)
			tank.radiusFireTime = nextParse(parse)
			tank.megaTank = nextParse(parse)
			tank.target = nextParse(parse)
			local flag = nextParse(parse)

			if flag == 0 then
				tank.flag = nil
			else
				tank.flag = c_tcm_current_map.flags[flag]
			end

			if tank.exists and not tank.m.body then
				c_world_spawnTank(tank)
			elseif not tank.exists and tank.m.body then
				c_world_tank_die(tank)
			end

			if tank.exists and tank.m.body and tank.m.fixture then
				tankbobs.w_setPosition(tank.m.body, tank.p)
				tankbobs.w_setAngle(tank.m.body, tank.r)
				tankbobs.w_setLinearVelocity(tank.m.body, velocity)
				tankbobs.w_setAngularVelocity(tank.m.body, angularVelocity)
			end
		  end
		, { INT
		  , VEC2
		  , VEC2
		  , DOUBLE
		  , VEC2
		  , VEC2
		  , VEC2
		  , VEC2
		  , DOUBLE
		  , STRING
		  , BOOL
		  , BOOL
		  , INT
		  , INT
		  , NILINT
		  , DOUBLE
		  , DOUBLE
		  , NILINT
		  , INT
		  , INT
		  , INT
		  , BOOL
		  , BOOL
		  , DOUBLE
		  , NILINT
		  , BOOL
		  , DOUBLE
		  , DOUBLE
		  , DOUBLE
		  , BOOL
		  , DOUBLE
		  , NILINT
		  , NILINT
		  , INT
		  }
		},

		-- corpses
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, function(parse)
			local corpse = c_world_getCorpses()[newParse(parse)]

			if not corpse then
				return
			end

			corpse.timeTilExplode = nextParse(parse)
			corpse.color.r = nextParse(parse)
			corpse.color.g = nextParse(parse)
			corpse.color.b = nextParse(parse)
			corpse.red = nextParse(parse)
			corpse.p(nextParse(parse))
			corpse.r = nextParse(parse)
			corpse.h[1](nextParse(parse))
			corpse.h[2](nextParse(parse))
			corpse.h[3](nextParse(parse))
			corpse.h[4](nextParse(parse))
			local position = nextParse(parse)
			local angle = nextParse(parse)
			local velocity = nextParse(parse)
			local angularVelocity = nextParse(parse)
			corpse.name = nextParse(parse)
			if corpse.m.body then
				tankbobs.w_setPosition(corpse.m.body, position)
				tankbobs.w_setAngle(corpse.m.body, angle)
				tankbobs.w_setLinearVelocity(corpse.m.body, velocity)
				tankbobs.w_setAngularVelocity(corpse.m.body, angularVelocity)
			end
		  end
		, { INT
		  , DOUBLE
		  , DOUBLE
		  , DOUBLE
		  , DOUBLE
		  , BOOL
		  , VEC2
		  , DOUBLE
		  , VEC2
		  , VEC2
		  , VEC2
		  , VEC2
		  , VEC2
		  , DOUBLE
		  , VEC2
		  , DOUBLE
		  , STRING
		  }
		},

		-- powerups
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, function(parse)
			local powerup = c_world_getPowerups()[newParse(parse)]

			if not powerup then
				return
			end

			powerup.p(nextParse(parse))
			local angle = nextParse(parse)
			local velocity = nextParse(parse)
			local angularVelocity = nextParse(parse)
			powerup.r = nextParse(parse)
			powerup.spawner = nextParse(parse)
			powerup.collided = nextParse(parse)
			powerup.powerupType = nextParse(parse)

			if powerup.m.body and powerup.m.fixture then
				tankbobs.w_setPosition(powerup.m.body, powerup.p)
				tankbobs.w_setAngle(powerup.m.body, angle)
				tankbobs.w_setLinearVelocity(powerup.m.body, velocity)
				tankbobs.w_setAngularVelocity(powerup.m.body, angularVelocity)
			end
		  end
		, { INT
		  , VEC2
		  , DOUBLE
		  , VEC2
		  , DOUBLE
		  , DOUBLE
		  , INT
		  , BOOL
		  , INT
		  }
		},

		-- walls
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, function(parse)
			local wall = c_tcm_current_map.walls[newParse(parse)]

			if not wall then
				return
			end

			local q = nextParse(parse)
			--[[
			wall.p[1](nextParse(parse))
			wall.p[2](nextParse(parse))
			wall.p[3](nextParse(parse))
			if q then
				wall.p[4](nextParse(parse))
			else
				nextParse(parse)
			end
			wall.texture = nextParse(parse)
			wall.detail = nextParse(parse)
			wall.static = nextParse(parse)
			wall.t[1](nextParse(parse))
			wall.t[2](nextParse(parse))
			wall.t[3](nextParse(parse))
			if q then
				wall.t[4](nextParse(parse))
			else
				nextParse(parse)
			end
			--]]

			wall.m.pos[1](nextParse(parse))
			wall.m.pos[2](nextParse(parse))
			wall.m.pos[3](nextParse(parse))
			if q then
				wall.m.pos[4](nextParse(parse))
			else
				nextParse(parse)
			end

			local position = nextParse(parse)
			local angle = nextParse(parse)
			local velocity = nextParse(parse)
			local angularVelocity = nextParse(parse)

			wall.path = nextParse(parse)
			wall.pid = nextParse(parse)
			wall.m.pid = nextParse(parse)
			wall.m.ppid = nextParse(parse)
			wall.m.ppos = nextParse(parse)
			wall.m.startpos = nextParse(parse)

			if wall.m.body and wall.m.fixture then
				tankbobs.w_setPosition(wall.m.body, position)
				tankbobs.w_setAngle(wall.m.body, angle)
				tankbobs.w_setLinearVelocity(wall.m.body, velocity)
				tankbobs.w_setAngularVelocity(wall.m.body, angularVelocity)
			end
		  end
		, { INT
		  , BOOL

		  --[[
		  , VEC2
		  , VEC2
		  , VEC2
		  , VEC2
		  , STRING
		  , BOOL
		  , BOOL
		  , VEC2
		  , VEC2
		  , VEC2
		  , VEC2
		  --]]

		  , VEC2
		  , VEC2
		  , VEC2
		  , VEC2
		  , VEC2
		  , DOUBLE
		  , VEC2
		  , DOUBLE
		  , BOOL
		  , NILINT
		  , NILINT
		  , NILINT
		  , DOUBLE
		  , VEC2
		  }
		},

		-- control points
		{ identifier(increment())
		, function() return c_world_getGameType() == DOMINATION end
		, VT_FUNCTION
		, function(parse)
			local controlPoint = c_tcm_current_map.controlPoints[newParse(parse)]

			if not controlPoint then
				return
			end

			controlPoint.m.team = nextParse(parse)
		  end
		, { INT
		  , NILSTRING
		  }
		},

		-- flags
		{ identifier(increment())
		, function() return c_world_getGameType() == CAPTURETHEFLAG end
		, VT_FUNCTION
		, function(parse)
			local flag = c_tcm_current_map.flags[newParse(parse)]

			if not flag then
				return
			end

			flag.m.stolen = nextParse(parse)
			flag.m.dropped = nextParse(parse)
			flag.m.pos = nextParse(parse)
		  end
		, { INT
		  , NILINT
		  , BOOL
		  , VEC2
		  }
		}
	}
}

local function getNumProjectiles()
	return #c_weapon_getProjectiles()
end

local function getNumTanks()
	return #c_world_getTanks()
end

local function getNumCorpses()
	return #c_world_getCorpses()
end

local function getNumPowerups()
	return #c_world_getPowerups()
end

local function getNumWalls()
	return #c_tcm_current_map.walls
end

local function getNumControlPoints()
	return #c_tcm_current_map.controlPoints
end

local function getNumFlags()
	return #c_tcm_current_map.flags
end

resetIncrement()
protocol_persist =
{
	{DOUBLE, FLOAT, INT, NILINT, SHORT, CHAR, BOOL, STRING, NILSTRING, VEC2},
	{VT_FUNCTION, VT_STRING},

	{
		-- Timestamp
		{ identifier(increment())
		, nil  -- Always send and store this (function)
		, VT_FUNCTION
		, tankbobs.t_getTicks
		, INT
		},
		-- Pause state
		{ identifier(increment())
		, nil  -- Always send and store this (function)
		, VT_FUNCTION
		, c_world_getPaused
		, BOOL
		},

		-- Scores
		{ identifier(increment())
		, c_world_gameTypeTeam
		, VT_STRING
		, "c_world_blueTeam.score"
		, INT
		},
		{ identifier(increment())
		, c_world_gameTypeTeam
		, VT_STRING
		, "c_world_redTeam.score"
		, INT
		},

		-- Get number of entities
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, getNumProjectiles
		, INT
		},
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, getNumTanks
		, INT
		},
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, getNumCorpses
		, INT
		},
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, getNumPowerups
		, INT
		},
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, getNumWalls
		, INT
		},
		{ identifier(increment())
		, function() return c_world_getGameType() == DOMINATION end
		, VT_FUNCTION
		, getNumControlPoints
		, INT
		},
		{ identifier(increment())
		, function() return c_world_getGameType() == CAPTURETHEFLAG end
		, VT_FUNCTION
		, getNumFlags
		, INT
		},

		-- projectiles
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, function()
			local res = {}

			newPut(res)

			for _, v in pairs(c_weapon_getProjectiles()) do
				if not v.collided and v.m.body and v.m.fixture then
					nextPut(v.p)
					nextPut(tankbobs.w_getLinearVelocity(v.m.body))
					nextPut(tankbobs.w_getAngularVelocity(v.m.body))
					nextPut(v.weapon)
					nextPut(v.r)
					nextPut(v.collisions)
					nextPut(v.owner)
					nextPut(v.collided)
				end
			end

			return res
		  end
		, { VEC2
		  , VEC2
		  , DOUBLE
		  , INT
		  , DOUBLE
		  , INT
		  , INT
		  , BOOL
		  }
		},

		-- tanks
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, function()
			local res = {}

			newPut(res)

			for k, v in pairs(c_world_getTanks()) do
				nextPut(k)
				nextPut(v.p)
				nextPut(v.m.body and tankbobs.w_getLinearVelocity(v.m.body) or ZERO)
				nextPut(v.m.body and tankbobs.w_getAngularVelocity(v.m.body) or 0)
				nextPut(v.h[1])
				nextPut(v.h[2])
				nextPut(v.h[3])
				nextPut(v.h[4])
				nextPut(v.r)
				nextPut(v.name)
				nextPut(v.exists)
				nextPut(v.spawning)
				nextPut(v.lastSpawnPoint)
				nextPut(v.state)
				nextPut(v.weapon)
				nextPut(v.health)
				nextPut(v.shield)
				nextPut(v.killer)
				nextPut(v.score)
				nextPut(v.ammo)
				nextPut(v.clips)
				nextPut(v.cd.acceleration)
				nextPut(v.cd.aimAid)
				nextPut(v.reloading)
				nextPut(v.shotgunReloadState)
				nextPut(v.red)
				nextPut(v.color.r)
				nextPut(v.color.g)
				nextPut(v.color.b)
				nextPut(v.tagged)
				nextPut(v.radiusFireTime)
				nextPut(v.megaTank)
				nextPut(v.target)
				local index = 0
				if v.flag then
					for k, v in pairs(c_tcm_current_map.flags) do
						if v == flag then
							index = k

							break
						end
					end
				end
				nextPut(index)
			end

			return res
		  end
		, { INT
		  , VEC2
		  , VEC2
		  , DOUBLE
		  , VEC2
		  , VEC2
		  , VEC2
		  , VEC2
		  , DOUBLE
		  , STRING
		  , BOOL
		  , BOOL
		  , INT
		  , INT
		  , NILINT
		  , DOUBLE
		  , DOUBLE
		  , NILINT
		  , INT
		  , INT
		  , INT
		  , BOOL
		  , BOOL
		  , DOUBLE
		  , NILINT
		  , BOOL
		  , DOUBLE
		  , DOUBLE
		  , DOUBLE
		  , BOOL
		  , DOUBLE
		  , NILINT
		  , NILINT
		  , INT
		  }
		},

		-- corpses
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, function()
			local res = {}

			newPut(res)

			for k, v in pairs(c_world_getCorpses()) do
				if v.exists then
					nextPut(k)
					nextPut(v.timeTilExplode)
					nextPut(v.color.r)
					nextPut(v.color.g)
					nextPut(v.color.b)
					nextPut(v.red)
					nextPut(v.p)
					nextPut(v.r)
					nextPut(v.h[1])
					nextPut(v.h[2])
					nextPut(v.h[3])
					nextPut(v.h[4])
					nextPut(v.m.body and tankbobs.w_getPosition(v.m.body) or ZERO)
					nextPut(v.m.body and tankbobs.w_getAngle(v.m.body) or 0)
					nextPut(v.m.body and tankbobs.w_getLinearVelocity(v.m.body) or ZERO)
					nextPut(v.m.body and tankbobs.w_getAngularVelocity(v.m.body) or 0)
					nextPut(v.name)
				end
			end

			return res
		  end
		, { INT
		  , DOUBLE
		  , DOUBLE
		  , DOUBLE
		  , DOUBLE
		  , BOOL
		  , VEC2
		  , DOUBLE
		  , VEC2
		  , VEC2
		  , VEC2
		  , VEC2
		  , VEC2
		  , DOUBLE
		  , VEC2
		  , DOUBLE
		  , STRING
		  }
		},

		-- powerups
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, function()
			local res = {}

			newPut(res)

			for k, v in pairs(c_world_getPowerups()) do
				if not v.collided and v.m.body and v.m.fixture then
					nextPut(k)
					nextPut(v.p)
					nextPut(tankbobs.w_getAngle(v.m.body))
					nextPut(tankbobs.w_getLinearVelocity(v.m.body))
					nextPut(tankbobs.w_getAngularVelocity(v.m.body))
					nextPut(v.r)
					nextPut(v.spawner)
					nextPut(v.collided)
					nextPut(v.powerupType)
				end
			end

			return res
		  end
		, { INT
		  , VEC2
		  , DOUBLE
		  , VEC2
		  , DOUBLE
		  , DOUBLE
		  , INT
		  , BOOL
		  , INT
		  }
		},

		-- walls
		{ identifier(increment())
		, nil
		, VT_FUNCTION
		, function()
			local res = {}

			newPut(res)

			for k, v in pairs(c_tcm_current_map.walls) do
				nextPut(k)

				local q = not not v.p[4]
				nextPut(q)

				--[[
				nextPut(v.p[1])
				nextPut(v.p[2])
				nextPut(v.p[3])
				nextPut(q and v.p[4] or ZERO)
				nextPut(v.texture)
				nextPut(v.detail)
				nextPut(v.static)
				nextPut(v.t[1])
				nextPut(v.t[2])
				nextPut(v.t[3])
				nextPut(q and v.t[4] or ZERO)
				--]]

				nextPut(v.m.pos[1])
				nextPut(v.m.pos[2])
				nextPut(v.m.pos[3])
				nextPut(q and v.m.pos[4] or ZERO)

				nextPut(v.m.body and tankbobs.w_getPosition(v.m.body) or ZERO)
				nextPut(v.m.body and tankbobs.w_getAngle(v.m.body) or 0)
				nextPut(v.m.body and tankbobs.w_getLinearVelocity(v.m.body) or ZERO)
				nextPut(v.m.body and tankbobs.w_getAngularVelocity(v.m.body) or 0)

				nextPut(v.path)
				nextPut(v.pid)
				nextPut(v.m.pid)
				nextPut(v.m.ppid)
				nextPut(v.m.ppos or 0)
				nextPut(v.m.startpos or ZERO)
			end

			return res
		  end
		, { INT
		  , BOOL

		  --[[
		  , VEC2
		  , VEC2
		  , VEC2
		  , VEC2
		  , STRING
		  , BOOL
		  , BOOL
		  , VEC2
		  , VEC2
		  , VEC2
		  , VEC2
		  --]]

		  , VEC2
		  , VEC2
		  , VEC2
		  , VEC2
		  , VEC2
		  , DOUBLE
		  , VEC2
		  , DOUBLE
		  , BOOL
		  , NILINT
		  , NILINT
		  , NILINT
		  , DOUBLE
		  , VEC2
		  }
		},

		-- control points
		{ identifier(increment())
		, function() return c_world_getGameType() == DOMINATION end
		, VT_FUNCTION
		, function()
			local res = {}

			newPut(res)

			for k, v in pairs(c_tcm_current_map.controlPoints) do
				nextPut(k)
				nextPut(v.m.team)
			end

			return res
		  end
		, { INT
		  , NILSTRING
		  }
		},

		-- flags
		{ identifier(increment())
		, function() return c_world_getGameType() == CAPTURETHEFLAG end
		, VT_FUNCTION
		, function()
			local res = {}

			newPut(res)

			for k, v in pairs(c_tcm_current_map.flags) do
				nextPut(k)
				nextPut(v.m.stolen)
				nextPut(v.m.dropped)
				nextPut(v.m.pos)
			end

			return res
		  end
		, { INT
		  , NILINT
		  , BOOL
		  , VEC2
		  }
		}
	}
}

local unpersistProtocol = nil
local unpersist = nil
local types = nil
local vtypes = nil
local segments = nil

function c_protocol_setUnpersistProtocol(protocol)
	types = protocol[1]
	vtypes = protocol[2]
	segments = protocol[3]

	local function lookupSegment(identifier, first, last)
		if not first or not last then
			return lookupSegment(identifier, 1, #segments)
		elseif first > last then
			return nil
		else
			local k = math.floor((first + last) / 2)
			local middle = segments[k]
			if identifier == middle[1] then
				return middle
			elseif identifier < middle[1] then
				return lookupSegment(identifier, first, k - 1)
			elseif identifier > middle[1] then
				return lookupSegment(identifier, k + 1, last)
			end
		end
	end

	-- Check whether bytes is nil, not the value
	local valueParsers = {}
	valueParsers[DOUBLE]             = function(data)
										   local size = 8
										   if #data < size then
											   return nil, nil
										   else
											   return tankbobs.io_toDouble(data:sub(1, size)), size
										   end
									   end
	valueParsers[FLOAT]              = function(data)
										   local size = 4
										   if #data < size then
											   return nil, nil
										   else
											   return tankbobs.io_toFloat(data:sub(1, size)), size
										   end
									   end
	valueParsers[INT]                = function(data)
										   local size = 4
										   if #data < size then
											   return nil, nil
										   else
											   return tankbobs.io_toInt(data:sub(1, size)), size
										   end
									   end
	valueParsers[NILINT]             = function(data)
										   local size = 4
										   if #data < size then
											   return nil, nil
										   else
											   local value = tankbobs.io_toInt(data:sub(1, size))
											   if value == MAGIC then
												   return nil, size
											   else
												   return value, size
											   end
										   end
									   end
	valueParsers[SHORT]              = function(data)
										   local size = 2
										   if #data < size then
											   return nil, nil
										   else
											   return tankbobs.io_toShort(data:sub(1, size)), size
										   end
									   end
	valueParsers[CHAR]               = function(data)
										   local size = 1
										   if #data < size then
											   return nil, nil
										   else
											   return tankbobs.io_toChar(data:sub(1, size)), size
										   end
									   end
	valueParsers[BOOL]               = function(data)
										   local size = 1
										   if #data < size then
											   return nil, nil
										   else
											   return tankbobs.io_toChar(data:sub(1, size)) ~= 0, size
										   end
									   end
	valueParsers[STRING]             = function(data)
										   local pos = data:find("\0")

										   if pos then
											   return data:sub(1, pos - 1), pos
										   else
											   return data, #data
										   end
									   end
	valueParsers[NILSTRING]          = function(data)
										   local pos = data:find("\0")

										   if pos == 1 then
											   return nil, 1
										   elseif pos then
											   return data:sub(1, pos - 1), pos
										   else
											   return data, #data
										   end
									   end
	valueParsers[VEC2]               = function(data)
										   local size = 16
										   if #data < size then
											   return nil, nil
										   end

										   return tankbobs.m_vec2(tankbobs.io_toDouble(data:sub(1, math.floor(size / 2))), tankbobs.io_toDouble(data:sub(math.floor(size / 2) + 1, size))), size
									   end

	local function parseValue(valueType, value)
		return valueParsers[valueType](value)
	end

	local function parseSegment(grammar, data)
		if type(grammar) == "table" then
			local res = {}
			local size = 0

			newPut(res)

			for _, v in ipairs(grammar) do
				local value, bytes = parseValue(v, data)

				if not bytes then
					return nil, nil
				end

				nextPut(value)
				size = size + bytes
				data = data:sub(bytes + 1)
			end

			return res, size
		else
			return parseValue(grammar, data)
		end
	end

	unpersist = function (data)
		if #data < 4 then
			common_printError(0, "Warning: unpersist: disregarding small packet.\n")

			return
		end

		local version = tankbobs.io_toInt(data:sub(1, 4)) data = data:sub(5)
		if version ~= protocol_version then
			common_printError(0, "Warning: unpersist: protocol versions differ!  Not unpersisting from version '" .. version .. "' to '" .. protocol_version .. "'.\n")

			return
		end

		while(#data > 0) do
			-- TODO: Support identifiers larger than 254
			local identifierString = data:sub(1, 1) data = data:sub(2)
			local identifier = tankbobs.io_toChar(identifierString)

			local segment = lookupSegment(identifier)

			if not segment then
				common_printError(0, "Warning: unpersist: unrecognized segment identifier '" .. common_stringToHex("", "0x", identifierString) .. "' ('" .. identifier .. "')\n")

				break
			end

			local res, size = parseSegment(segment[5], data)

			if not size then
				common_printError(0, "Warning: unpersist: segment with identifier '" .. common_stringToHex("", "0x", identifierString) .. "' ended prematurely ('" .. #data .. "' bytes of post-identifier data left to parse)." .. common_stringToHex("", "0x", identifierString) .. "'\n")

				break
			end

			data = data:sub(size + 1)

			if not segment[2] or segment[2]() then
				if segment[3] == VT_STRING then
					local function setValue(value, key, t)
						t = t or _G

						local pos = key:find("%.")
						if pos then
							return setValue(value, key:sub(pos + 1), t[key:sub(1, pos - 1)])
						else
							t[key] = value
						end
					end

					setValue(res, segment[4])
				elseif segment[3] == VT_FUNCTION then
					segment[4](res)
				else
					error("Unrecognized value type ('" .. segment[3] .. "') in protocol segment with identifier '" .. common_stringToHex("", "0x", identifierString) .. "'.")
				end
			end
		end
	end

	unpersistProtocol = protocol
end

local persistProtocol = nil
local persist = nil
local types = nil
local vtypes = nil
local segments = nil

local nextSegment = nil

function c_protocol_setPersistProtocol(protocol)
	types = protocol[1]
	vtypes = protocol[2]
	segments = protocol[3]

	nextSegment = 1

	-- Check whether bytes is nil, not the value
	local valueParsers = {}
	valueParsers[DOUBLE]             = function(data)
										   local size = 8
										   return tankbobs.io_fromDouble(data), size
									   end
	valueParsers[FLOAT]              = function(data)
										   local size = 4
										   return tankbobs.io_fromFloat(data), size
									   end
	valueParsers[INT]                = function(data)
										   local size = 4
										   return tankbobs.io_fromInt(data), size
									   end
	valueParsers[NILINT]             = function(data)
										   local size = 4
										   return tankbobs.io_fromInt(data or MAGIC), size
									   end
	valueParsers[SHORT]              = function(data)
										   local size = 2
										   return tankbobs.io_fromShort(data), size
									   end
	valueParsers[CHAR]               = function(data)
										   local size = 1
										   return tankbobs.io_fromChar(data), size
									   end
	valueParsers[BOOL]               = function(data)
										   local size = 1
										   return tankbobs.io_fromChar(data and 1 or 0), size
									   end
	valueParsers[STRING]             = function(data)
										   local pos = data:find("\0")

										   if pos then
											   return data:sub(1, pos), pos
										   else
											   return data .. "\0", #data + 1
										   end
									   end
	valueParsers[NILSTRING]          = function(data)
										   if not data then
											   return "\0", 1
										   end

										   local pos = data:find("\0")

										   if pos then
											   return data:sub(1, pos - 1), pos
										   else
											   return data .. "\0", #data + 1
										   end
									   end
	valueParsers[VEC2]               = function(data)
										   local size = 16
										   return tankbobs.io_fromDouble(data.x) .. tankbobs.io_fromDouble(data.y), size
									   end

	local function parseValue(valueType, value)
		return valueParsers[valueType](value)
	end

	local parseIndex = nil
	local function parseSegment(grammar, data, identifier, maxSize)
		if type(grammar) == "table" then
			local max = #data
			do
				local acc = 0
				while acc < max do
					acc = acc + #grammar
				end
				max = acc
			end

			local res = ""
			local size = 0

			local new

			for i = parseIndex or 1, max do
				parseIndex = math.max(1, i - #grammar)

				if i % #grammar == 1 then
					if size > maxSize then
						return res, true
					elseif new then
						res = res .. new
					end

					new = identifier
					size = size + 1
				elseif parseIndex and size <= 0 then
					-- We screwed up somewhere.  FIXME: Why does this happen?
					parseIndex = 1

					return "", true
				end

				local value, bytes = parseValue(grammar[(i - 1) % #grammar + 1], data[i])

				if not bytes then
					return nil, nil
				end

				size = size + bytes

				new = new .. value
			end

			if size > maxSize then
				return res, true
			elseif size > 0 then
				res = res .. new
			end

			parseIndex = nil

			return res, false
		else
			return identifier .. parseValue(grammar, data)
		end
	end

	persist = function (max)
		local data = tankbobs.io_fromInt(protocol_version)

		local reachedFinal = false

		local reachedLast = false
		local pastLast = false

		local lastSegment = nextSegment - 1
		if lastSegment < 1 then
			lastSegment = #segments
		end

		while not pastLast do
			local v = segments[nextSegment]

			-- TODO: Support identifiers larger than 254
			local identifier = tankbobs.io_fromChar(v[1])

			if not v[2] or v[2]() then
				if v[3] == VT_STRING then
					local function getValue(key, t)
						t = t or _G

						local pos = key:find("%.")
						if pos then
							return getValue(key:sub(pos + 1), t[key:sub(1, pos - 1)])
						else
							return t[key]
						end
					end

					local res, end_ = parseSegment(v[5], getValue(v[4]), identifier, max - #data)
					data = data .. res
				elseif v[3] == VT_FUNCTION then
					local res, end_ = parseSegment(v[5], v[4](), identifier, max - #data)
					data = data .. res
				else
					error("Unrecognized value type ('" .. v[3] .. "') in protocol segment with identifier '" .. common_stringToHex("", "0x", identifier) .. "'.")
				end

				if end_ then
					break
				end
			end

			if nextSegment == #segments then
				reachedFinal = true
			end

			if reachedLast then
				pastLast = true
			end
			if nextSegment == lastSegment then
				reachedLast = true
			end

			nextSegment = nextSegment + 1
			if nextSegment > #segments then
				nextSegment = 1
			end
		end

		return data, reachedFinal
	end

	persistProtocol = protocol
end


function c_protocol_unpersist(data)
	if not unpersistProtocol then
		common_printError(2, "Warning: c_protocol_unpersist: no protocol set.\n")

		return
	end

	return unpersist(data)
end

function c_protocol_persist(max)
	if not persistProtocol then
		common_printError(2, "Warning: c_protocol_persist: no protocol set.\n")

		return
	end

	return persist(max)
end
