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

UNINITIALIZED       = 0
UNCONNECTED         = 1
BANNED              = 2  -- banned from server
REQUESTING          = 3  -- client sent initial packet
RESPONDED           = 4  -- server responded to connection packet
CONNECTED           = 5  -- connected to server
local UNINITIALIZED = UNINITIALIZED
local UNCONNECTED   = UNCONNECTED
local BANNED        = BANNED
local REQUESTING    = REQUESTING
local RESPONDED     = RESPONDED
local CONNECTED     = CONNECTED

function st_internet_init()
	connection = {state = UNCONNECTED, proceeding = false, lastRequestTime, challenge = 0, address = c_config_get("client.serverIP"), ip = "", port = nil, ui = "", ping = nil, offset = nil, gameType = nil, t = nil, banMessage = ""}

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
		elseif switch == BANNED then
			widget.text = string.format("%s", connection.banMessage)
		elseif switch == REQUESTING then
			widget.text = "Attempting connection . . ."
		elseif switch == RESPONDED then
			widget.text = "Accepting challenge . . ."
		elseif switch == CONNECTED then
			widget.text = "Connected"
		end
	end

	gui_addLabel(tankbobs.m_vec2(50,  81), "", updateStatus, 1 / 3)
	gui_addLabel(tankbobs.m_vec2(50, 78), "IP", nil, 1 / 3) gui_addInput(tankbobs.m_vec2(55, 78), tostring(connection.address), nil, st_internet_serverIP, false, 64, 1 / 3)
	gui_addAction(tankbobs.m_vec2(55, 72), "Connect", nil, st_internet_start, 2 / 3)

	local ui = ""
	if tankbobs.fs_fileExists(c_const_get("ui_file")) then
		local fin = tankbobs.fs_openRead(c_const_get("ui_file"))
		ui = tankbobs.fs_read(fin, 32)
		tankbobs.fs_close(fin)
	end
	if #ui ~= 32 then
		math.randomseed(os.time())
		ui = ""
		for i = 1, 32 do
			ui = ui .. string.char(math.random(0x00, 0x7F))
		end
		local fout = tankbobs.fs_openWrite(c_const_get("ui_file"))
		tankbobs.fs_write(fout, ui)
		tankbobs.fs_close(fout)

		--if c_const_get("debug") then
			common_print(2, "New GUID generated\n")
		--end
	end

	connection.ui = ui
end

function st_internet_done()
	gui_finish()

	if connection.state > REQUESTING and not connection.proceeding then
		-- abort the connection
		tankbobs.n_newPacket(33)
		tankbobs.n_writeToPacket(tankbobs.io_fromChar(0x04))
		tankbobs.n_writeToPacket(connection.ui)
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
			if button == 0x1B or button == c_config_get("client.key.exit") or button == c_config_get("client.key.quit") then
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
		c_state_goto(online_state)
	elseif connection.state == RESPONDED then
		local status, ip, port, data

		repeat
			status, ip, port, data = tankbobs.n_readPacket()

			if status then
				local switch = string.byte(data, 1) data = data:sub(2)
				if switch == nil then
				elseif switch == 0xA1 then
					connection.state = CONNECTED
				elseif switch == 0xA6 then
					local message = data:sub(1, data:find(tankbobs.io_fromChar(0x00)) - 1) data = data:sub(data:find(tankbobs.io_fromChar(0x00)) + 1)
					connection.state = BANNED
					connection.banMessage = message
				end
			end
		until not status
	elseif connection.state == REQUESTING then
		local status, ip, port, data

		repeat
			status, ip, port, data = tankbobs.n_readPacket()

			if status then
				local switch = string.byte(data, 1) data = data:sub(2)
				if switch == nil then
				elseif switch == 0xA0 then
					local challenge = tankbobs.io_toInt(data:sub(1, 4)) data = data:sub(5)
					local instagib = tankbobs.io_toChar(data:sub(1, 1)) data = data:sub(2)
					local set = data:sub(1, data:find(tankbobs.io_fromChar(0x00)) - 1) data = data:sub(data:find(tankbobs.io_fromChar(0x00)) + 1)
					local map = data:sub(1, data:find(tankbobs.io_fromChar(0x00)) - 1) data = data:sub(data:find(tankbobs.io_fromChar(0x00)) + 1)
					local gameType = data:sub(1, data:find(tankbobs.io_fromChar(0x00)) - 1) data = data:sub(data:find(tankbobs.io_fromChar(0x00)) + 1)

					c_tcm_select_set(set)
					c_tcm_select_map(map)

					c_world_setGameType(gameType)

					c_world_setInstagib(instagib ~= 0x00 and true or false)

					-- send the server the challenge response
					tankbobs.n_newPacket(37)
					tankbobs.n_writeToPacket(tankbobs.io_fromChar(0x01))
					tankbobs.n_writeToPacket(connection.ui)
					tankbobs.n_writeToPacket(tankbobs.io_fromInt(challenge))
					tankbobs.n_sendPacket()

					connection.lastRequestTime = tankbobs.t_getTicks()
					connection.state = RESPONDED
				elseif switch == 0xA6 then
					local message = data:sub(1, data:find(tankbobs.io_fromChar(0x00)) - 1) data = data:sub(data:find(tankbobs.io_fromChar(0x00)) + 1)
					connection.state = BANNED
					connection.banMessage = message
				end
			end
		until not status

		if tankbobs.t_getTicks() >= connection.lastRequestTime + c_const_get("server_timeout") then
			if connection.state > UNCONNECTED then
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
	end
end

function st_internet_serverIP(widget, text)
	c_config_set("client.serverIP", text)
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

	local status, err = tankbobs.n_init(c_config_get("client.port", true))
	if not status then
		stderr:write(err)

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
	if not c_config_get("game.player1.name", true) or not c_config_get("game.player1.color.r", true) or not c_config_get("game.player1.color.g", true) or not c_config_get("game.player1.color.b", true) then
		-- forward player to configuration if player 1 isn't set up
		c_state_goto(options_state)

		return
	end
	local name = c_config_get("game.player1.name")
	if #name > 20 then
		tankbobs.n_writeToPacket(tankbobs.io_fromChar(20))
		tankbobs.n_writeToPacket(name, tankbobs.io_fromChar(20))
	else
		tankbobs.n_writeToPacket(tankbobs.io_fromChar(#name))
		tankbobs.n_writeToPacket(name)
		tankbobs.n_writeToPacket(string.rep(tankbobs.io_fromChar(0x00), 20 - #name))
	end
	local r, g, b = c_config_get("game.player1.color.r"), c_config_get("game.player1.color.g"), c_config_get("game.player1.color.b")
	tankbobs.n_writeToPacket(tankbobs.io_fromDouble(r))
	tankbobs.n_writeToPacket(tankbobs.io_fromDouble(g))
	tankbobs.n_writeToPacket(tankbobs.io_fromDouble(b))
	tankbobs.n_writeToPacket(tankbobs.io_fromChar((c_config_get("game.player1.team") == "red") and 0x01 or 0x00))
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
