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
client.lua

clients
--]]

--[[
The first byte of a packet indicates its type.

Packets beginning with 0x00 are connection request packets
0x01 are packets signaling that the client has finished loading data (the client is connected and will receive data from the server)

0x10 are input packets

0x20 is the head of a tick offset response packet

The server receives packets beginning with 0x00-0x0F
	- 0x00 is a connection request packet
	- 0x01 is the second request packet
	- 0x02 are input snapshot packets
	- 0x03 is the head of a tick offset response packet
	- 0x04 is the head of a disconnect packet
Clients receives packets beginning with 0xA0-0xAF
	- 0xA0 is a connection response packet
	- 0xA2 is the head of a snapshot sent from the server
	- 0xA3 is a tick offset request packet
	- 0x04 is the head of a disconnect packet
--]]

local tankbobs

function client_init()
	tankbobs = _G.tankbobs

	c_const_get("client_connectFlood", 2000, 1)
	c_const_get("client_ticksCheck", 5000, 1)
	c_const_get("client_maxInactiveTime", 12000, 1)  -- drop after 2 minutes of no packets
	c_const_get("client_maxChallengeAttempts", 3, 1)
end

function client_done()
end

client =
{
	new = common_new,

	init = function (o)
		o.tank = c_world_tank:new()
	end,

	tank = nil,
	ticksOffset = nil,  -- number
	lastOffsetCheckTime = nil,  -- number
	ping = 0,
	ip = "",
	port = 0,
	connecting = false,
	lastAliveTime = nil,  -- number
	lastTickSendTime = nil,   -- number
	ui = ""  -- unique identifier
}

local clients = {}

local lastConnectTime

local function client_sanitizeName(name)
	local sanitizedName = ""

	if #name >= 1 then
		for i = 1, math.min(#name, c_const_get("max_nameLength")) do
			if char(name:sub(i)) >= 32 and char(name:sub(i)) < 127 then
				sanitizedName = sanitizedName .. name:sub(i)
			end
		end
	end

	return sazitizedName
end

local function client_getByIP(ip)
	for k, v in pairs(client) do
		if v.ip == ip then
			return v
		end
	end
end

local function client_askForTick(client)
	local t = tankbobs.t_getTicks()

	if client.lastTickSendTime then
		return  -- still requesting the tick
	end

	client.lastTickSendTime = t
	tankbobs.n_newPacket(1)
	tankbobs.n_writeToPacket(string.char(0x20))
	tankbobs.n_sendPacket(client.ip)
end

local function client_validate(client, ui)
	return client.ui == ui
end

local function client_disconnect(client, reason)
	tankbobs.n_newPacket(#reason + 1)
	tankbobs.n_writeToPacket(string.char(0x01))
	tankbobs.n_writeToPacket(reason)
	-- send the packet a few times
	tankbobs.n_sendPacket(client.ip)
	tankbobs.n_sendPacket(client.ip)
	tankbobs.n_sendPacket(client.ip)
	tankbobs.n_sendPacket(client.ip)
	tankbobs.n_sendPacket(client.ip)

	s_print("'", client.tank.name, "' disconnected from ", client.ip, ":", client.port, "; reason: ", reason, "\n")

	for k, v in pairs(clients) do
		if v == client then
			-- remove tank from world
			c_world_tank_die(client.tank)

			-- remove client
			table.remove(clients, k)

			return
		end
	end
end

function client_boot(client, reason)
	client_disconnect(client, reason)
end

function client_step(d)
	local t = tankbobs.t_getTicks()

	local status, ip, port, data
	repeat
		status, ip, port, data = n_readPacket()
		local client = client_getByIP(ip)

		local switch = data:sub(1, 1)
		data = data:sub(2)
		if switch == nil then
		elseif switch == 0x00 then
			if #data >= 51 then  -- connection request packet expects to be at least 51 bytes, so ignore it if it's not
				if not client then
					if not lastConnectTime or t > lastConnectTime + c_const_get("client_connectFlood") then
						lastConnectTime = t

						-- client wants to connect
						-- initialize new client
						local client = client:new()
						table.insert(clients, client)

						client.ip = ip
						client.port = port
						client.lastAliveTime = t

						-- the 2nd byte specifies the length of the name in the next 20 bytes (bytes 3-23)
						local len = tankbobs.io_toChar(data)
						data = data:sub(2)
						if len > 20 then
							len = 20
						end
						client.tank.name = client_sanitizeName(data:sub(1, len))
						data = data:sub(21)

						-- the next 8 * 3 (24) bytes gives the tank's chosen color
						client.tank.color.r = tankbobs.io_toDouble(data) data = data:sub(9)
						client.tank.color.g = tankbobs.io_toDouble(data) data = data:sub(9)
						client.tank.color.b = tankbobs.io_toDouble(data) data = data:sub(9)

						s_print("'", client.tank.name, "' connected from ", ip, ":", port, "\n")

						-- the last 4 bytes are the client's unique identifier
						client.ui = data:sub(1, 4) data = data:sub(5)

						-- send the challenge number
						client.challenge = tankbobs.t_fromInt(math.random(0x00000000, 0xFFFFFFFF))
					end
				end
			end
		elseif switch == 0x01 then
			if #data >= 4 then
				if client then
					if client_validate(client, data:sub(1, 4)) then
						data = data:sub(5)

						if client.connecting then
							local challenge = tankbobs.t_toInt(data:sub(1, 4)) data = data:sub(5)

							if challenge = client.challenge then
								client.connecting = false
								c_world_tank_spawn(client.tank)

								s_print("'", client.tank.name, "' entered the game from ", client.ip, ":", client.port, "\n")
							else
								client.challengeAttempts = client.challengeAttempts + 1

								if client.challengeAttempts > c_const_get("client_maxChallengeAttempts") then
									client_disconnect(client, "too many challenge attempts")
								end
							end
						end
					end
				end
			end
		elseif switch == 0x02 then
			if #data >= 5 then
				if client then
					if client_validate(client, data:sub(1, 4)) then
						data = data:sub(5)

						local input = tankbobs.io_toChar(data)

						client.tank.state.firing  = tankbobs.t_testAND(input, 0x01)
						client.tank.state.forward = tankbobs.t_testAND(input, 0x02)
						client.tank.state.back    = tankbobs.t_testAND(input, 0x04)
						client.tank.state.right   = tankbobs.t_testAND(input, 0x08)
						client.tank.state.left    = tankbobs.t_testAND(input, 0x10)
						client.tank.state.special = tankbobs.t_testAND(input, 0x20)

						data = data:sub(2)
					end
				end
			end
		elseif switch == 0x03 then
			if #data >= 8 then
				if client then
					if client_validate(client, data:sub(1, 4)) then
						data = data:sub(5)

						-- tick response
						local ticks

						ticks = tankbobs.io_toInt(data) data = data:sub(5)

						client.ping = t - client.lastTickSendTime
						client.ticksOffset = ticks - t - client.ping / 2
					end
				end
			end
		elseif switch == 0x04 then
			if #data >= 4 then
				if client then
					if client_validate(client, data:sub(1, 4)) then
						client_disconnect(client, "voluntary disconnect")
					end
				end
			end
		end

		if client then
			client.lastAliveTime = t
		end
	until not status

	-- iterate over each client
	local tanks = c_world_getTanks()
	local numTanks = math.min(#tanks, 255)
	for k, v in pairs(clients) do
		if v.connecting then
		else
			if v.ticksOffset and v.lastOffsetCheckTime and t >= v.lastOffsetCheckTime + c_const_get("client_ticksCheck") then
				local f = tankbobs.t_AND

				-- send the client a snapshot of the world
				tankbobs.n_newPacket(1024)
				tankbobs.n_writeToPacket(tankbobs.t_fromInt(t + v.ticksOffset))
				-- send the client's own ID
				tankbobs.n_writeToPacket(tankbobs.t_fromChar(k))
				-- send the number of tanks
				tankbobs.n_writeToPacket(tankbobs.t_fromChar(numTanks))
				-- send the state of the first 18 tanks
				for i = 1, 18 do
					local v = tanks[k]

					if v then
						local input = 0

						if v.tank.state.firing  then input = tankbobs.t_testAND(input, 0x01) end
						if v.tank.state.forward then input = tankbobs.t_testAND(input, 0x02) end
						if v.tank.state.back    then input = tankbobs.t_testAND(input, 0x04) end
						if v.tank.state.right   then input = tankbobs.t_testAND(input, 0x08) end
						if v.tank.state.left    then input = tankbobs.t_testAND(input, 0x10) end
						if v.tank.state.special then input = tankbobs.t_testAND(input, 0x20) end

						tankbobs.n_writeToPacket(tankbobs.t_fromChar(input))
					else
						tankbobs.n_writeToPacket(tankbobs.t_fromChar(0x00))
					end
				end
				-- send a snapshot of the world in the 1000 remaining bytes
				tankbobs.n_writeToPacket(tankbobs.w_persistWorld(c_weapon_getProjectiles(), c_world_getTanks(), c_world_getPowerups(), c_tcm_current_map.walls))
				tankbobs.n_sendPacket(client.ip)
			else
				client_askForTick(v)
			end
		end

		if v.lastAliveTime and t > v.lastAliveTime + c_const_get("client_maxInactiveTime") then
			client_disconnect(client, "timed out")
		end
	end
end

function client_connectedClients()
	local num = 0

	for _, v in pairs(client) do
		if not v.connecting then
			num = num + 1
		end
	end

	return num
end
