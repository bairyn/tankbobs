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
local online_readPackets

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

	connected = true

	game_new()

	-- pause label

	-- pause
	local function updatePause(widget)
		if c_world_getPaused() and not endOfGame and not quitScreen then
			widget.text = "Paused"
			tankbobs.in_grabClear()
		else
			widget.text = ""

			if quitScreen then
				tankbobs.in_grabClear()
			elseif not tankbobs.in_isGrabbed() then
				tankbobs.in_grabMouse(c_config_get("client.renderer.width") / 2, c_config_get("client.renderer.height") / 2)
			end
		end
	end

	gui_addLabel(tankbobs.m_vec2(37.5, 50), "", updatePause, nil, c_config_get("client.renderer.pauseRed"), c_config_get("client.renderer.pauseGreen"), c_config_get("client.renderer.pauseBlue"), c_config_get("client.renderer.pauseAlpha"), c_config_get("client.renderer.pauseRed"), c_config_get("client.renderer.pauseGreen"), c_config_get("client.renderer.pauseBlue"), c_config_get("client.renderer.pauseAlpha"))

	-- create local world
	c_world_newWorld()
end

function st_online_done()
	gui_finish()

	game_done()

	c_world_freeWorld()

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

function online_readPackets()  -- local
	local status, ip, port, data
	repeat
		status, ip, port, data = tankbobs.n_readPacket()
		local client = client_getByIP(ip)

		if status then
			local switch = string.byte(data, 1) data = data:sub(2)
			if switch == nil then
			elseif switch == 0xA2 then
				if #data >= 1024 - 937 then
					if connection.ping then
						-- snapshot received from server
						-- TODO
						--
						-- unpersist and step world relative to half-ping (XXX REMINDER: remove all local projectiles before unpersisting
					end
				end
			elseif switch == 0xA3 then
				if #data >= 0 then
					-- server wants our tick
					tankbobs.n_newPacket(37)
					tankbobs.n_writeToPacket(tankbobs.io_fromChar(0x03))
					tankbobs.n_writeToPacket(connection.ui)
					tankbobs.n_writeToPacket(tankbobs.io_fromInt(tankbobs.t_getTicks()))
					tankbobs.n_sendPacket()
				end
			elseif switch == 0xA4 then
				if #data >= 1 then
					-- disconnected from server
					local reason = data:sub(1, data:find(tankbobs.io_fromChar(0x00)) - 1) data = data:sub(data:find(tankbobs.io_fromChar(0x00)) + 1)

					gui_addLabel(tankbobs.m_vec2(20, 55), "You were disconnected from the server", nil, 2 / 3)
					gui_addLabel(tankbobs.m_vec2(20, 30), "Reason: " .. reason, nil, 1 / 3)
			elseif switch == 0xA5 then
				if #data >= 4 then
					-- server sent us our ping
					connection.ping = tankbobs.io_toInt(data:sub(1, 4)) data = data:sub(5)
				end
			end
		end
	until not status
end

function st_online_click(button, pressed, x, y)
	gui_click(button, pressed, x, y)
end

local quitLabel, yesAction, noAction
local function continue()
	if quitScreen then
		gui_removeWidget(quitLabel)
		gui_removeWidget(yesAction)
		gui_removeWidget(noAction)
		--c_world_setPaused(not c_world_getPaused())
		quitScreen = false
	end
end
function st_play_button(button, pressed)
	if not gui_button(button, pressed) then
		if pressed then
			if button == 0x0D and endOfGame then
				c_state_new(play_state)
			elseif button == c_config_get("client.key.pause") then
				--if not endOfGame and not quitScreen then
					--c_world_setPaused(not c_world_getPaused())
				--end
			elseif button == 0x1B or button == c_config_get("client.key.quit") then
				if endOfGame then
					c_state_new(play_state)
				elseif quitScreen then
					continue()
				elseif c_world_getPaused() then
					--c_world_setPaused(not c_world_getPaused())
				else
					--c_world_setPaused(true)
					quitLabel = gui_addLabel(tankbobs.m_vec2(35.0, 60), "Really Quit?", nil, nil, c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"), c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"))
					yesAction = gui_addAction(tankbobs.m_vec2(35.0, 40), "Yes", nil, c_state_advance, nil, c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"), c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"))
					noAction = gui_addAction(tankbobs.m_vec2(65.0, 40), "No", nil, continue, nil, c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"), c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"))
					quitScreen = true
				end
			elseif button == c_config_get("client.key.exit") then
				c_state_new(exit_state)
			end
		end

		local c_world_tanks = c_world_getTanks()

		--for i = 1, c_config_get("game.players") do
		for i = 1, 1 do
			if not (c_config_get("client.key.player" .. tostring(i) .. ".fire", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".fire", false)
			end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".forward", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".forward", false)
			end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".back", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".back", false)
			end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".right", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".right", false)
			end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".left", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".left", false)
			end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".special", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".special", false)
			end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".reload", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".reload", false)
			end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".reverse", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".reverse", false)
			end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".mod", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".mod", false)
			end

			if button == c_config_get("client.key.player" .. tostring(i) .. ".fire") then
				c_world_tanks[i].state.firing = pressed
			end
			if button == c_config_get("client.key.player" .. tostring(i) .. ".forward") then
				c_world_tanks[i].state.forward = pressed
			end
			if button == c_config_get("client.key.player" .. tostring(i) .. ".back") then
				c_world_tanks[i].state.back = pressed
			end
			if button == c_config_get("client.key.player" .. tostring(i) .. ".left") then
				c_world_tanks[i].state.left = pressed
			end
			if button == c_config_get("client.key.player" .. tostring(i) .. ".right") then
				c_world_tanks[i].state.right = pressed
			end
			if button == c_config_get("client.key.player" .. tostring(i) .. ".special") then
				c_world_tanks[i].state.special = pressed
			end
			if button == c_config_get("client.key.player" .. tostring(i) .. ".reload") then
				c_world_tanks[i].state.reload = pressed
			end
			--if button == c_config_get("client.key.player" .. tostring(i) .. ".reverse") then
				--c_world_tanks[i].state.reverse = reverse
			--end
			if button == c_config_get("client.key.player" .. tostring(i) .. ".mod") then
				c_world_tanks[i].state.mod = pressed
			end
		end
	end

	game_refreshKeys()
end

function st_online_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

function st_online_step(d)
	gui_paint(d)

	online_readPackets()

	if not connection.ping then
		return
	end

	game_step(d)

	c_world_step(d)
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
