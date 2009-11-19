--[[
Copyright (C) 2008-2009 Byron James Johnson

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
st_background.lua

Background
--]]

local tankbobs = tankbobs
local gl = gl
local c_world_getPowerups = c_world_getPowerups
local c_weapon_getProjectiles = c_weapon_getProjectiles
local c_world_getTanks = c_world_getTanks
local c_world_getPaused = c_world_getPaused
local c_const_get = c_const_get
local c_const_set = c_const_set
local c_config_get = c_config_get
local c_config_set = c_config_set
local c_weapon_getWeapons = c_weapon_getWeapons
local tank_listBase
local tankBorder_listBase
local powerup_listBase
local healthbar_listBase
local healthbarBorder_listBase
local c_world_findClosestIntersection
local common_lerp

local st_background_init
local st_background_done
local st_background_step

local endOfGame

local bit

function st_background_init()
	-- localize frequently used globals
	tankbobs = _G.tankbobs
	gl = _G.gl
	c_world_getPowerups = _G.c_world_getPowerups
	c_weapon_getProjectiles = _G.c_weapon_getProjectiles
	c_world_getTanks = _G.c_world_getTanks
	c_world_getPaused = _G.c_world_getPaused
	c_const_get = _G.c_const_get
	c_const_set = _G.c_const_set
	c_config_get = _G.c_config_get
	c_config_set = _G.c_config_set
	c_weapon_getWeapons = _G.c_weapon_getWeapons
	tank_listBase = _G.tank_listBase
	tankBorder_listBase = _G.tankBorder_listBase
	powerup_listBase = _G.powerup_listBase
	healthbar_listBase = _G.healthbar_listBase
	healthbarBorder_listBase = _G.healthbarBorder_listBase
	c_world_findClosestIntersection = _G.c_world_findClosestIntersection
	common_lerp = _G.common_lerp

	bit = c_module_load "bit"

	endOfGame = false

	online = false

	math.randomseed(os.time())

	-- load last played level
	c_tcm_select_set(c_config_get("game.lastSet"))
	c_tcm_select_map(c_config_get("game.lastMap"))

	if not c_tcm_current_map then
		if backgroundState then
			backgroundState = nil
		end

		c_state_backgroundStop(c_state_getCurrentState())

		return
	end

	game_new()

	gui_addLabel(tankbobs.m_vec2(37.5, 50), "", updatePause, nil, c_config_get("client.renderer.pauseRed"), c_config_get("client.renderer.pauseGreen"), c_config_get("client.renderer.pauseBlue"), c_config_get("client.renderer.pauseAlpha"), c_config_get("client.renderer.pauseRed"), c_config_get("client.renderer.pauseGreen"), c_config_get("client.renderer.pauseBlue"), c_config_get("client.renderer.pauseAlpha"))

	-- initialize the world
	c_world_newWorld()

	-- set instagib state
	c_world_setInstagib(c_config_get("game.instagib"))

	-- spawn two bots
	local tank1 = c_world_tank:new()
	local tank2 = c_world_tank:new()
	table.insert(c_world_getTanks(), tank1)
	table.insert(c_world_getTanks(), tank2)
	c_ai_initTank(tank1)
	c_ai_initTank(tank2)
	c_world_tank_spawn(tank1)
	c_world_tank_spawn(tank2)
end

function st_background_done()
	-- if we didn't initialize, don't close
	if not backgroundState then
		return
	end

	-- reset texenv
	gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

	-- end game
	game_end()

	-- free the world
	c_world_freeWorld()
end

local function background_testEnd()
	-- test for end of game
	if endOfGame then
		c_world_setPaused(true)
	end

	local switch = c_world_gameType
	if switch == DEATHMATCH then
		local fragLimit = c_config_get("game.fragLimit")

		if fragLimit > 0 then
			for k, v in pairs(c_world_getTanks()) do
				if v.score >= fragLimit then
					c_world_setPaused(true)

					if not endOfGame then
						--[[
						tankbobs.a_playSound(c_const_get("win_sound"))

						local name = tostring(v.name)
						gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, v.color.r, v.color.g, v.color.b, 0.75, v.color.r, v.color.g, v.color.b, 0.8)
						--]]
					end

					endOfGame = true
				end
			end
		end
	elseif switch == CHASE then
		local chaseLimit = c_config_get("game.chaseLimit")

		if chaseLimit > 0 then
			for k, v in pairs(c_world_getTanks()) do
				if v.score >= chaseLimit then
					c_world_setPaused(true)

					if not endOfGame then
						--[[
						local name = tostring(v.name)
						gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, v.color.r, v.color.g, v.color.b, 0.75, v.color.r, v.color.g, v.color.b, 0.8)

						tankbobs.a_playSound(c_const_get("win_sound"))
						--]]
					end

					endOfGame = true
				end
			end
		end
	elseif switch == DOMINATION then
		local pointLimit = c_config_get("game.pointLimit")

		if pointLimit > 0 then
			if c_world_redTeam.score >= pointLimit then
				c_world_setPaused(true)

				if not endOfGame then
					--[[
					local name = "Red"
					local color = c_const_get("color_red")
					gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, color[1], color[2], color[3], 0.75, color[1], color[2], color[3], 0.8)

					tankbobs.a_playSound(c_const_get("win_sound"))
					--]]
				end

				endOfGame = true
			elseif c_world_blueTeam.score >= pointLimit then
				c_world_setPaused(true)

				if not endOfGame then
					--[[
					local name = "Blue"
					local color = c_const_get("color_blue")
					gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, color[1], color[2], color[3], 0.75, color[1], color[2], color[3], 0.8)

					tankbobs.a_playSound(c_const_get("win_sound"))
					--]]
				end

				endOfGame = true
			end
		end
	elseif switch == CAPTURETHEFLAG then
		local captureLimit = c_config_get("game.captureLimit")

		if captureLimit > 0 then
			if c_world_redTeam.score >= captureLimit then
				c_world_setPaused(true)

				if not endOfGame then
					--[[
					local name = "Red"
					local color = c_const_get("color_red")
					gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, color[1], color[2], color[3], 0.75, color[1], color[2], color[3], 0.8)

					tankbobs.a_playSound(c_const_get("win_sound"))
					--]]
				end

				endOfGame = true
			elseif c_world_blueTeam.score >= captureLimit then
				c_world_setPaused(true)

				if not endOfGame then
					--[[
					local name = "Blue"
					local color = c_const_get("color_blue")
					gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, color[1], color[2], color[3], 0.75, color[1], color[2], color[3], 0.8)

					tankbobs.a_playSound(c_const_get("win_sound"))
					--]]
				end

				endOfGame = true
			end
		end
	end

	if endOfGame then
		c_state_backgroundAdvance(c_state_getCurrentState())
	end
end

function st_background_step(d)
	-- test for end of game
	background_testEnd()

	c_world_step(d)

	game_step(d)
end

background_state =
{
	name   = "background_state",
	init   = st_background_init,
	done   = st_background_done,
	next   = function () return background_state end,

	click  = nil,
	button = nil,
	mouse  = nil,

	main   = st_background_step
}