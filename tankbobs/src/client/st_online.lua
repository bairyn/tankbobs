--[[
Copyright (C) 2008 Byron James Johnson

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
st_online.lua

functions for playing online
--]]

local tankbobs = tankbobs
local gl = gl
local c_world_step = c_world_step
local gui_paint = gui_paint
local gui_button = gui_button
local gui_mouse = gui_mouse
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
local powerup_listBase
local wall_listBase
local healthbar_listBase
local healthbarBorder_listBase
local c_world_findClosestIntersection
local connection

local st_online_init
local st_online_done
local st_online_click
local st_online_button
local st_online_mouse
local st_online_step

local st_online_serverIP
local st_online_start

function st_online_init()
	-- localize frequently used globals
	tankbobs = _G.tankbobs
	gl = _G.gl
	c_world_step = _G.c_world_step
	gui_paint = _G.gui_paint
	gui_button = _G.gui_button
	gui_mouse = _G.gui_mouse
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
	powerup_listBase = _G.powerup_listBase
	wall_listBase = _G.wall_listBase
	healthbar_listBase = _G.healthbar_listBase
	healthbarBorder_listBase = _G.healthbarBorder_listBase
	connection = _G.connection
	c_world_findClosestIntersection = _G.c_world_findClosestIntersection

	-- initialize renderer stuff
	-- wall textures are initialized per level
	local listOffset = 0

	wall_listBase = gl.GenLists(c_tcm_current_map.walls_n)
	wall_textures = gl.GenTextures(c_tcm_current_map.walls_n)

	if wall_listBase == 0 then
		error "st_play_init: could not generate lists"
	end

	for k, v in pairs(c_tcm_current_map.walls) do
		v.m.list = wall_listBase + listOffset
		v.m.texture = wall_textures[k]

		gl.BindTexture("TEXTURE_2D", v.m.texture)
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
		tankbobs.r_loadImage2D(c_const_get("textures_dir") .. v.texture, c_const_get("textures_default"))

		-- TODO: use vertex buffers to render dynamic walls.  Dynamic walls will always be drawn as if they were in the same position
		gl.NewList(v.m.list, "COMPILE_AND_EXECUTE")
			gl.Color(1, 1, 1, 1)
			gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 1)
			gl.BindTexture("TEXTURE_2D", v.m.texture)
			gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

			gl.Begin("POLYGON")
				for i = 1, #v.p do
					gl.TexCoord(v.t[i].x, v.t[i].y)
					gl.Vertex(v.p[i].x, v.p[i].y)
				end
			gl.End()
		gl.EndList()

		listOffset = listOffset + 1
	end

	-- scores
	local function updateScores(widget)
		local length = 0

		widget.text = ""

		for k, v in pairs(c_world_getTanks()) do
			local name = tostring(c_config_get("config.game.player" .. tostring(k) .. ".name"))

			if #name > length then
				length = #name
			end
		end

		if length < 1 then
			length = 1
		end

		for k, v in pairs(c_world_getTanks()) do
			local name, between, score

			if widget.text:len() ~= 0 then
				widget.text = widget.text .. "\n"
			end

			name = tostring(c_config_get("config.game.player" .. tostring(k) .. ".name"))
			between = string.rep("  ", length - #name + 1)
			score = tostring(v.score)

			widget.text = widget.text .. name .. between .. score
		end
	end

	gui_addLabel(tankbobs.m_vec2(7.5, 92.5), "", updateScores, 0.5, c_config_get("config.game.scoresRed"), c_config_get("config.game.scoresGreen"), c_config_get("config.game.scoresBlue"), c_config_get("config.game.scoresAlpha"), c_config_get("config.game.scoresRed"), c_config_get("config.game.scoresGreen"), c_config_get("config.game.scoresGreen"), c_config_get("config.game.scoresAlpha"))

	-- fps counter
	local function updateFPS(widget)
		local fps = fps

		widget.text = tostring(fps - (fps % 1))
	end

	if c_config_get("config.game.fpsCounter") then
		gui_addLabel(tankbobs.m_vec2(92.5, 92.5), "", updateFPS, 0.5, c_config_get("config.game.fpsRed"), c_config_get("config.game.fpsGreen"), c_config_get("config.game.fpsBlue"), c_config_get("config.game.fpsAlpha"), c_config_get("config.game.fpsRed"), c_config_get("config.game.fpsGreen"), c_config_get("config.game.fpsGreen"), c_config_get("config.game.fpsAlpha"))
	end

	-- pause
	local function updatePause(widget)
		if c_world_getPaused() and not endOfGame then
			widget.text = "Paused"
			tankbobs.in_grabClear()
		else
			widget.text = ""
			if not tankbobs.in_isGrabbed() then
				tankbobs.in_grabMouse(c_config_get("config.renderer.width") / 2, c_config_get("config.renderer.height") / 2)
			end
		end
	end

	gui_addLabel(tankbobs.m_vec2(37.5, 50), "", updatePause, nil, c_config_get("config.game.pauseRed"), c_config_get("config.game.pauseGreen"), c_config_get("config.game.pauseBlue"), c_config_get("config.game.pauseAlpha"), c_config_get("config.game.pauseRed"), c_config_get("config.game.pauseGreen"), c_config_get("config.game.pauseBlue"), c_config_get("config.game.pauseAlpha"))

	-- create local world
TODO(assert(false))  -- TODO
end

function st_online_done()
	gui_finish()

	if connection.state > UNCONNECTED then
		-- abort the connection
		tankbobs.n_newPacket(33)
		tankbobs.n_writeToPacket(tankbobs.io_fromChar(0x04))
		tankbobs.n_sendPacket()
		tankbobs.n_sendPacket()
		tankbobs.n_sendPacket()
		tankbobs.n_sendPacket()
		tankbobs.n_sendPacket()
		tankbobs.n_quit()

		connection.state = UNCONNECTED
	end
end

function st_online_click(button, pressed, x, y)
	gui_click(button, pressed, x, y)
end

function st_online_button(button, pressed)
	if not gui_button(button, pressed) then
		if pressed then
			if button == 0x1B or button == c_config_get("config.key.exit") or button == c_config_get("config.key.quit") then
				c_state_advance()
			end
		end
	end
end

function st_online_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

function st_online_step(d)
	gui_paint(d)
end

online_state =
{
	name   = "online_state",
	init   = st_online_init,
	done   = st_online_done,
	next   = function () return title_state end,

	click  = st_online_click,
	button = st_online_button,
	mouse  = st_online_mouse,

	main   = st_online_step
}
