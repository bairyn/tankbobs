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
st_internet.lua

Server connection screen
--]]

local st_internet_init
local st_internet_done
local st_internet_click
local st_internet_button
local st_internet_mouse
local st_internet_step

local st_internet_serverIP
local st_internet_start

local UNITIIALIZED = 0
local UNCONNECTED  = 1
local REQUESTING   = 2  -- client sent initial packet
local RESPONDED    = 3  -- server responded to connection packet
local CONNECTED    = 4  -- connected to server

function st_internet_init()
	connection = {state = UNCONNECTED, proceeding = false, lastRequestTime, challenge = 0, address = c_config_get("config.client.serverIP"), ip = "", port = nil, ui = ""}

	if connection.address:find(":") then
		connection.port = tonumber(connection.address:sub(connection.address:find(":") + 1))
		connection.ip = connection.address:sub(1, connection.address:find(":"))
	else
		connection.port = nil
		connection.ip = connection.address
	end

	c_const_set("server_timeout", 6000, -1)

	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	local function updateStatus(widget)
		local switch = connection.state
			if switch == UNINITIALIZED then
				widget.text = "Could not initialize"
		elseif switch == UNCONNECTED then
			if connection.lastRequestTime then
				widget.text = "Connection timed out"
			else
				widget.text = "Not connected"
			end
		elseif switch == REQUESTING then
			widget.text = "Attempting connection . . ."
		elseif siwtch == RESPONDED then
			widget.text = "Accepting challenge . . ."
		elseif switch == CONNECTED then
			widget.text = "Connected"
		end
	end

	gui_addLabel(tankbobs.m_vec2(50,  81), "", updateStatus, 2 / 3)
	gui_addLabel(tankbobs.m_vec2(50, 75), "IP", nil, 2 / 3) gui_addInput(tankbobs.m_vec2(55, 75), tostring(connection.address), nil, st_internet_serverIP, false, 64)
	gui_addAction(tankbobs.m_vec2(55, 69), "Connect", nil, st_internet_start)

	local ui = ""
	local fin = io.open(c_const_get("ui_file"), "rb")
	if fin then
		ui = fin:read("*a")
	end
	if #ui ~= 32 then
		math.randomseed(os.time())
		ui = ""
		for i = 1, 32 do
			ui = ui .. string.char(math.random(0x00, 0x7F))
		end
		local fout = io.open(c_const_get("ui_file"), "wb")
		if fout then
			fout:write(ui)

			if c_const_get("debug") then
				io.stdout:write("Generating GUID\n")
			end
		else
			if c_const_get("debug") then
				io.stderr:write("Warning: could not write GUID to '", c_const_get("ui_file"), "'\n")
			end
		end
	end

	connection.ui = ui
end

function st_internet_done()
	gui_finish()

	if connection.state > UNCONNECTED and not connection.proceeding then
		-- abort the connection
		tankbobs.n_newPacket(33)
		tankbobs.n_writeToPacket(tankbobs.io_fromChar(0x04))
		tankbobs.n_sendPacket()
		tankbobs.n_sendPacket()
		tankbobs.n_sendPacket()
		tankbobs.n_sendPacket()
		tankbobs.n_sendPacket()
	end
end

function st_internet_click(button, pressed, x, y)
	gui_click(button, pressed, x, y)
end

function st_internet_button(button, pressed)
	if not gui_button(button, pressed) then
		if pressed then
			if button == 0x1B or button == c_config_get("config.key.exit") or button == c_config_get("config.key.quit") then
				c_state_advance()
			end
		end
	end
end

function st_internet_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

function st_internet_step(d)
	gui_paint(d)

	if connection.state == CONNECTED then
		connection.proceeding = true
		c_state_new(online_state)
	elseif connection.state == RESPONDED then
		local status, ip, port, data

		repeat
			status, ip, port, data = tankbobs.n_readPacket()

			if status then
				local switch = data:sub(1, 1) data = data:sub(2)
				if switch == nil then
				elseif switch == 0xA1 then
					connection.state = CONNECTED
				end
			end
		until not status
	elseif connection.state == REQUESTING then
		local status, ip, port, data

		repeat
			status, ip, port, data = tankbobs.n_readPacket()

			if status then
print("SANOTEUHNATSOHU")
				local switch = data:sub(1, 1) data = data:sub(2)
				if switch == nil then
				elseif switch == 0xA0 then
					local challenge = tankbobs.t_toInt(data:sub(1, 4)) data = data:sub(5)
					local set = data:sub(data:find(tankbobs.fromChar(0x00))) data = data:sub(data:find(tankbobs.fromChar(0x00)) + 1)
					local map = data:sub(data:find(tankbobs.fromChar(0x00))) data = data:sub(data:find(tankbobs.fromChar(0x00)) + 1)

					c_tcm_select_set(set)
					c_tcm_select_set(map)

					-- send the server the challenge response
					tankbobs.n_newPacket(37)
					tankbobs.n_writeToPacket(tankbobs.t_fromChar(0x01))
					tankbobs.n_writeToPacket(connection.ui)
					tankbobs.n_writeToPacket(tankbobs.t_fromInt(challenge))
					tankbobs.n_sendPacket()

					connection.lastRequestTime = tankbobs.t_getTicks()
					connection.state = RESPONDED
				end
			end
		until not status

		if tankbobs.t_getTicks() >= connection.lastRequestTime + c_const_get("server_timeout") then
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
	end
end

function st_internet_serverIP(widget, text)
	c_config_set("config.client.serverIP", text)
	connection.address = text

	if connection.address:find(":") then
		connection.port = tonumber(connection.address:sub(connection.address:find(":") + 1))
		connection.ip = connection.address:sub(1, connection.address:find(":"))
	else
		connection.port = nil
		connection.ip = connection.address
	end
end

function st_internet_start(widget)
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
	end

	local status, err = tankbobs.n_init(c_config_get("config.client.port", nil, true))
	if not status then
		io.stderr:write(err)

		connection.state = UNINITIALIZED

		return
	end
	if connection.port then
		tankbobs.n_setPort(connection.port)
	else
		tankbobs.n_setPort(c_const_get("default_connectPort"))
	end
	tankbobs.n_newPacket(80)
	tankbobs.n_writeToPacket(tankbobs.io_fromChar(0x00))
	if not c_config_get("config.game.player1", nil, true) or not c_config_get("config.game.player1.name", nil, true) or not c_config_get("config.game.player1.color", nil, true) or not c_config_get("config.game.player1.color.r", nil, true) or not c_config_get("config.game.player1.color.g", nil, true) or not c_config_get("config.game.player1.color.b", nil, true) then
		-- forward player to configuration if player 1 isn't set up
		c_state_new(options_state)

		return
	end
	local name = c_config_get("config.game.player1.name")
	if #name > 20 then
		tankbobs.n_writeToPacket(tankbobs.io_fromChar(20))
		tankbobs.n_writeToPacket(name, tankbobs.io_fromChar(20))
	else
		tankbobs.n_writeToPacket(tankbobs.io_fromChar(#name))
		tankbobs.n_writeToPacket(name)
		tankbobs.n_writeToPacket(string.rep(tankbobs.io_fromChar(0x00), 20 - #name))
	end
	local r, g, b = c_config_get("config.game.player1.color.r"), c_config_get("config.game.player1.color.g"), c_config_get("config.game.player1.color.b")
	tankbobs.n_writeToPacket(tankbobs.io_fromDouble(r))
	tankbobs.n_writeToPacket(tankbobs.io_fromDouble(g))
	tankbobs.n_writeToPacket(tankbobs.io_fromDouble(b))
	tankbobs.n_writeToPacket(connection.ui)
	tankbobs.n_sendPacket(connection.ip)

	connection.lastRequestTime = tankbobs.t_getTicks()
	connection.state = REQUESTING
end

internet_state =
{
	name   = "internet_state",
	init   = st_internet_init,
	done   = st_internet_done,
	next   = function () return title_state end,

	click  = st_internet_click,
	button = st_internet_button,
	mouse  = st_internet_mouse,

	main   = st_internet_step
}
