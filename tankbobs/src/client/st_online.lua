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

	game_new()

	-- create local world
TODO(assert(false) or "TODO")  -- TODO
end

function st_online_done()
	gui_finish()

	game_done()

	if connection.state > REQUESTING then
		-- abort the connection
		tankbobs.n_newPacket(33)
		tankbobs.n_writeToPacket(tankbobs.io_fromChar(0x04))
		tankbobs.n_writeToPacket(connection.ui)
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
			if button == 0x1B or button == c_config_get("client.key.exit") or button == c_config_get("client.key.quit") then
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

	game_step(d)

	-- step world relative to half-ping
	-- TODO: change c_world_step to allow this to happen
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
