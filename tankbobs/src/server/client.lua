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
client.lua

Clients
--]]

--[[
The first byte of a packet indicates its type.

Packets beginning with 0x00 are connection request packets
0x01 are packets signaling that the client has finished loading data (the client is connected and will receive data from the server)

The server receives packets beginning with 0x00-0x0F
	- 0x00 is a connection request packet
	- 0x01 is the second connection packet
	- 0x02 are input snapshot packets
	- 0x03 is the head of a tick offset response packet
	- 0x04 is the head of a disconnect packet
	- 0x0A is the head of an event response packet
Clients receives packets beginning with 0xA0-0xAF
	- 0xA0 is a connection response packet
	- 0xA1 is the confirmation that the server accepted the client's connection request
	- 0xA2 is the head of a snapshot sent from the server
	- 0xA3 is a tick offset request packet
	- 0xA4 is the head of a disconnect packet
	- 0xA5 is a tick offset packet
	- 0xA6 is the head of a banned packet
	- 0xAA is the head of an event packet, in which a fixed amount of bytes always follow

The first byte after the ID of an event identifies the type of event.
	- 0x00 is a win event.  The next four bytes give the ID of the tank that won in a non-team gametype; otherwise, if any of the next four bytes are non-zero, the red team won.
--]]

local tankbobs

local bit

function client_init()
	tankbobs = _G.tankbobs

	bit = c_module_load "bit"

	c_const_set("client_connectFlood", 2000, 1)
	c_const_set("client_ticksCheck", 5000, 1)
	c_const_set("client_maxInactiveTime", 120000, 1)  -- drop after 2 minutes of no packets
	c_const_set("client_connectingMaxInactiveTime", 3000, 1)
	c_const_set("client_maxChallengeAttempts", 3, 1)  -- this is best at at least 2 so that the first incorrect challenge attempt can be seen on server console
end

function client_done()
end

client =
{
	new = c_class_new,

	init = function (o)
		o.tank = c_world_tank:new()
	end,

	tank = nil,
	ticksOffset = nil,  -- number
	ping = 0,
	ip = "",
	port = 0,
	connecting = false,
	challengeAttempts = 0,
	lastAliveTime = nil,  -- number
	lastTickSendTime = nil,   -- number
	lastTickRequestTime = nil,   -- number (this one doesn't get reset when tick is received; used to keep track of when the server needs to update ping
	lastPTime = nil,
	ui = "",  -- unique identifier
	events = {},  -- number id, string event
	lastEventID = 0
}

ban =
{
	new = c_class_new,

	ip = "",
	ui = "",

	name = "",
	reason = "",
	banner = "",
	banTime = 0,
}


local client_class = client

local clients = {}
local bans = {}

function client_begin()
	client_saveBans(c_const_get("bans_file"))

	clients = {}
end

function client_finish()
	client_loadBans(c_const_get("bans_file"))

	clients = nil
end

local function client_banCheck(client)
	if not client or not client.tank then
		return
	end

	for _, v in pairs(bans) do
		local banned = false

		if client.ip == v.ip then
			banned = true
		elseif client.ui == v.ui then
			banned = true
		end

		if banned then
			return v.reason, v.banner
		end
	end

	return
end

function client_loadBans(filename)
	bans = {}

	local fin = tankbobs.fs_openRead(filename)

	local i, line = 0
	local function readLine()
		i = i + 1
		line = tankbobs.fs_getStr(fin, '\n')
		if not line then
			tankbobs.fs_close(fin)

			error("client_loadBans: unexpected end of file on line " .. tostring(i))
		end
		return line
	end
	line = tankbobs.fs_getStr(fin, '\n')
	while line do
		local ban = ban:new()
		table.insert(bans, ban)

		ban.ip = readLine()
		ban.ui = readLine()

		ban.name = readLine()
		ban.reason = readLine()
		ban.banner = readLine()
		ban.banTime = readLine()

		i = i + 2
		tankbobs.fs_getStr(fin, '\n')  -- extra newline
		line = tankbobs.fs_getStr(fin, '\n')
	end

	tankbobs.fs_close(fin)
end

function client_saveBans(filename)
	local fout = tankbobs.fs_openWrite(filename)

	local first = true
	for k, v in pairs(bans) do
		if first then
			fout:write("[ban #", tostring(k), "] - ip, ui, name, reason, banner, banTime", "\n")
		else
			fout:write("[ban #", tostring(k), "]", "\n")
		end
		first = false

		tankbobs.fs_write(fout, v.ip .. "\n")
		tankbobs.fs_write(fout, v.ui .. "\n")

		tankbobs.fs_write(fout, v.name .. "\n")
		tankbobs.fs_write(fout, v.reason .. "\n")
		tankbobs.fs_write(fout, v.banner .. "\n")
		tankbobs.fs_write(fout, v.banTime .. "\n")

		tankbobs.fs_write(fout, "\n")
	end

	tankbobs.fs_close(fout)
end

function client_banClient(client, reason, banner)
	-- check for identical ban
	for _, v in pairs(bans) do
		if ban.ip == client.ip and
			ban.ui == common_stringToHex("", "", client.ui) then
			s_printnl("client_banClient: '", ban.name, "' is already banned.  Nothing changed.")
		end
	end

	local ban = ban:new()
	table.insert(bans, ban)

	ban.ip = client.ip
	ban.ui = common_stringToHex("", "", client.ui)

	ban.name = client.tank.name
	ban.reason = reason
	ban.banner = banner
	ban.banTime = os.time()

	if c_config_get("server.writeFileOnBan") then
		client_saveBans(c_const_get("bans_file"))
	end

	s_printnl("client_banClient: added ban '", ban.name, "' at '", ban.ip, "'")
end

function client_unban(banID)
	bans[banID] = nil
	if bans[banID] then
		bans[banID] = nil
	end

	if c_config_get("server.writeFileOnBan") then
		client_saveBans(c_const_get("bans_file"))
	end
end

function client_getBans(range, filter)
	local result = {}

	if range and type(range[1]) == "number" and type(range[2]) == "number" then
		local ban

		for i = range[1], range[2], ((range[1] < range[2]) and (1) or (-1)) do
			ban = bans[i]

			if ban then
				if not filter or ban.name:find(filter) or ban.ui:find(filter) or ban.ip:find(filter) then
					table.insert(result, {i, ban})
				end
			end
		end
	else
		for k, v in pairs(bans) do
			if not filter or v.name:find(filter) or v.ui:find(filter) or v.ip:find(filter) then
				table.insert(result, {k, v})
			end
		end
	end

	return result
end

local function client_sanitizeName(name)
	local sanitizedName = ""

	if #name >= 1 then
		for i = 1, math.min(#name, c_const_get("max_nameLength")) do
			if string.byte(name:sub(i)) >= 32 and string.byte(name:sub(i)) < 127 then
				sanitizedName = sanitizedName .. name:sub(i, i)
			end
		end
	else
		sanitizedName = c_const_get("defaultName")
	end

	return sanitizedName
end

local function sendToClient(client)
	if client.port and client.ip then
		tankbobs.n_setPort(client.port)
		tankbobs.n_sendPacket(client.ip)
	end
end

local function client_getByIP(ip)
	for k, v in pairs(clients) do
		if v.ip == ip then
			return v
		end
	end
end

local function client_askForTick(client)
	local t = tankbobs.t_getTicks()

	if not client.lastTickSendTime then
		client.lastTickSendTime = t
	end
	client.lastTickRequestTime = t
	tankbobs.n_newPacket(1)
	tankbobs.n_writeToPacket(tankbobs.io_fromChar(0xA3))
	sendToClient(client)
end

local function client_validate(client, ui)
	if not client.banned then
		return client.ui == ui
	else
		return false
	end
end

local function client_disconnect(client, reason)
	tankbobs.n_newPacket(#reason + 2)
	tankbobs.n_writeToPacket(tankbobs.io_fromChar(0xA4))
	tankbobs.n_writeToPacket(reason)
	tankbobs.n_writeToPacket(tankbobs.io_fromChar(0x00))
	sendToClient(client)
	sendToClient(client)
	sendToClient(client)
	sendToClient(client)
	sendToClient(client)

	s_printnl("'", client.tank.name, "' disconnected from ", client.ip, ":", client.port, "; reason: ", reason)

	for k, v in pairs(clients) do
		if v == client then
			-- remove tank from world
			c_world_tank_die(v.tank)
			c_world_removeTank(v.tank)

			-- remove client
			clients[k] = nil

			return
		end
	end
end

function client_boot(client, reason)
	client_disconnect(client, reason)
end

local lastConnectTime
local guidLen = 6
function client_step(d)
	local t = tankbobs.t_getTicks()

	-- make sure a set and map is selected
	if not c_tcm_current_set or not c_tcm_current_map then
		return
	end

	local status, ip, port, data
	repeat
		status, ip, port, data = tankbobs.n_readPacket()
		local client = client_getByIP(ip)

		if status then
			local switch = string.byte(data, 1) data = data:sub(2)
			if switch == nil then
			elseif switch == 0x00 then
				if #data >= 78 then  -- connection request packet needs to be at least 78 bytes, so ignore it if it's not
					if not client then
						if not lastConnectTime or t > lastConnectTime + c_const_get("client_connectFlood") then
							lastConnectTime = t

							-- client wants to connect
							-- initialize new client
							local client = client_class:new()
							table.insert(clients, client)

							client.ip = ip
							client.port = port
							client.lastAliveTime = t
							client.connecting = true

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

							-- the tank's team
							client.tank.red = tankbobs.io_toChar(data) ~= 0 and true or false data = data:sub(2)

							-- the last 32 bytes are the client's unique identifier
							client.ui = data:sub(1, 32) data = data:sub(33)

							local reason, banner = client_banCheck(client)

							if reason then
								client.banned = true

								client_banClient(client)

								s_printnl("Banned player '", client.tank.name, "' attempted to connect from ", ip, ":", port, "; GUID: *", common_stringToHex("", "", client.ui:sub(-guidLen, -1)))

								local message = string.format("Banned by '%s'; reason: '%s'", banner, reason)
								tankbobs.n_newPacket(#message + 2)
								tankbobs.n_writeToPacket(tankbobs.io_fromChar(0xA6))
								tankbobs.n_writeToPacket(message)
								tankbobs.n_writeToPacket(tankbobs.io_fromChar(0x00))
								sendToClient(client)
								sendToClient(client)
								sendToClient(client)
								sendToClient(client)
								sendToClient(client)
							else
								local instagib = 0

								local switch = c_world_getInstagib()
								if     switch == true then
									instagib = 0x02
								elseif switch == "semi" then
									instagib = 0x01
								elseif switch == false then
									instagib = 0x00
								end

								client.banned = false

								s_printnl("'", client.tank.name, "' connected from ", ip, ":", port)

								-- send the challenge number, instagib, spawnType, set, map and game type
								tankbobs.n_newPacket(256)
								tankbobs.n_writeToPacket(tankbobs.io_fromChar(0xA0))
								client.challenge = math.random(0x00000000, 0x7FFFFFFF)
								tankbobs.n_writeToPacket(tankbobs.io_fromInt(client.challenge))
								tankbobs.n_writeToPacket(tankbobs.io_fromChar(instagib))
								tankbobs.n_writeToPacket(tankbobs.io_fromChar(c_world_getSpawnMode()))
								-- set and map as a NULL-terminated string
								tankbobs.n_writeToPacket(c_tcm_current_set.name .. string.char(0x00))
								tankbobs.n_writeToPacket(c_tcm_current_map.name .. string.char(0x00))
								tankbobs.n_writeToPacket(tankbobs.io_fromInt(c_world_getGameType()))

								sendToClient(client)
							end
						end
					end
				end
			elseif switch == 0x01 then
				if #data >= 36 then
					if client then
						if client_validate(client, data:sub(1, 32)) then
							data = data:sub(33)

							if client.connecting then
								local challenge = tankbobs.io_toInt(data:sub(1, 4)) data = data:sub(5)

								challenge = bit.tobit(challenge)
								client.challenge = bit.tobit(client.challenge)

								if challenge == client.challenge then
									client.connecting = false
									table.insert(c_world_getTanks(), client.tank)
									c_world_tank_spawn(client.tank)

									tankbobs.n_newPacket(1)
									tankbobs.n_writeToPacket(tankbobs.io_fromChar(0xA1))
									sendToClient(client)

									-- unpause the world when the first client connects
									if(client_connectedClients() == 1) then
										if c_world_getPaused() then
											s_printnl("The game has been un-paused automatically")
											c_world_setPaused(false)
										end
									end

									s_printnl("'", client.tank.name, "' entered the game from ", client.ip, ":", client.port)
								else
									client.challengeAttempts = client.challengeAttempts + 1

									if client.challengeAttempts > c_const_get("client_maxChallengeAttempts") then
										client_disconnect(client, "too many challenge attempts")
									else
										s_printnl("'", client.tank.name, "' tried to connect with invalid challenge '", challenge, "' (", bit.tohex(challenge), ") against '", client.challenge, "' (", bit.tohex(client.challenge), ")")
									end
								end
							end
						end
					end
				end
			elseif switch == 0x02 then
				if #data >= 34 then
					if client then
						if client_validate(client, data:sub(1, 32)) then
							data = data:sub(33)

							local input = tankbobs.io_toShort(data) data = data:sub(3)

							client.tank.state = bit.tobit(input)
						end
					end
				end
			elseif switch == 0x03 then
				if #data >= 36 then
					if client then
						if client_validate(client, data:sub(1, 32)) and client.lastTickSendTime then
							data = data:sub(33)

							-- tick response
							local ticks

							ticks = tankbobs.io_toInt(data) data = data:sub(5)

							client.ping = t - client.lastTickSendTime
							client.ticksOffset = ticks - t - (client.ping / 2)

							-- send the client his ping
							tankbobs.n_newPacket(9)
							tankbobs.n_writeToPacket(tankbobs.io_fromChar(0xA5))
							tankbobs.n_writeToPacket(tankbobs.io_fromInt(client.ping))
							tankbobs.n_writeToPacket(tankbobs.io_fromInt(client.ticksOffset))
							sendToClient(client)

							client.lastTickSendTime = nil
						end
					end
				end
			elseif switch == 0x04 then
				if #data >= 32 then
					if client then
						if client_validate(client, data:sub(1, 32)) then
							client_disconnect(client, "voluntary disconnect")
						end
					end
				end
			elseif switch == 0x0A then
				if #data >= 36 then
					if client then
						if client_validate(client, data:sub(1, 32)) then
							-- client got the event
							data = data:sub(33)

							local id = tankbobs.io_toInt(data:sub(1, 4)) data = data:sub(5)
							local toRemove

							for k, v in pairs(client.events) do
								if v[1] == id then
									toRemove = k

									break
								end
							end

							if toRemove then
								table.remove(client.events, toRemove)

								if client.events[toRemove] then
									client.events[toRemove] = nil
								end
							end

							-- don't do anything if the client responded to an event that doesn't exist or has already been removed
						end
					end
				end
			end

			if client then
				client.lastAliveTime = t
			end
		end
	until not status

	-- iterate through each client
	local tanks = c_world_getTanks()
	local numTanks = math.min(#tanks, 255)
	for k, v in pairs(clients) do
		if not v.banned then
			if v.connecting then
				if v.lastAliveTime and t > v.lastAliveTime + c_const_get("client_connectingMaxInactiveTime") then
					client_disconnect(v, "timed out")
				end
			else
				if v.ping and v.ticksOffset and v.lastTickRequestTime then
					--if p then
					if v.lastPTime ~= lastPTime then
						v.lastPTime = lastPTime
						-- send the client a snapshot of the world
						for _, vs in pairs(p) do
							tankbobs.n_newPacket(#vs + 9)
							tankbobs.n_writeToPacket(tankbobs.io_fromChar(0xA2))
							tankbobs.n_writeToPacket(tankbobs.io_fromInt(tankbobs.t_getTicks() + v.ticksOffset))
							tankbobs.n_writeToPacket(tankbobs.io_fromInt(k))
							tankbobs.n_writeToPacket(vs)
							sendToClient(v)
						end
					end

					if t <= v.lastTickRequestTime + c_const_get("client_ticksCheck") then
						client_askForTick(v)
					end
				else
					client_askForTick(v)
				end

				if v.lastAliveTime and t > v.lastAliveTime + c_const_get("client_maxInactiveTime") then
					client_disconnect(v, "timed out")
				end

				for _, vs in pairs(v.events) do
					tankbobs.n_newPacket(1024)
					tankbobs.n_writeToPacket(tankbobs.io_fromChar(0xAA))
					tankbobs.n_writeToPacket(tankbobs.io_fromInt(vs[1]))
					tankbobs.n_writeToPacket(vs[2])
					sendToClient(v)
				end
			end
		end
	end
end

function client_connectedClients()
	local num = 0

	for _, v in pairs(clients) do
		if not v.connecting and not v.banned then
			num = num + 1
		end
	end

	return num
end

function client_getClients()
	return clients
end

function client_getClientsByIdentifier(identifier, idOnly)
	identifier = identifier or ""
	idOnly = idOnly or false

	local allClients = clients

	local clients = {}

	for k, v in pairs(allClients) do
		-- if identifier is a single number, return on first result if it matches a client's ID

		if tonumber(identifier) and k == tonumber(identifier) then
			return {v}
		end

		if not idOnly then
			-- test for GUID next
			if common_stringToHex("", "", v.ui):find(identifier) then
				table.insert(clients, v)
			end

			-- IP:port
			if v.ip .. ":" .. v.port == identifier then
				table.insert(clients, v)
			end

			-- name
			if v.tank.name:find(identifier) then
				table.insert(clients, v)
			end
		end
	end

	return clients
end

function client_sendEvent(client, event)
	if not client then
		for _, v in pairs(clients) do
			client_sendEvent(v, event)
		end

		return
	end

	client.lastEventID = client.lastEventID + 1
	table.insert(client.events, {client.lastEventID, event})
end
client_addEvent = client_sendEvent

function client_getByTank(tank)
	for _, v in pairs(clients) do
		if v.tank == tank then
			return v
		end
	end

	return nil
end

function client_kick(client, reason)
	client_disconnect(client, "kicked: " .. reason)
end
