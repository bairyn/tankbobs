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
commands.lua

Server console commands
--]]

local tankbobs

local command
local commands

local lastCommand = ""

function commands_init()
	tankbobs = _G.tankbobs

	tankbobs.c_setTabFunction("commands_autoComplete")

	for _, v in pairs(commands) do
		v.name                 = v[1]
		v.f                    = v[2]
		v.autoCompleteFunction = v[3]
		v.description          = v[4]

		v.matched              = false
	end
end

function commands_done()
end

function commands_setSelected()
	c_tcm_current_map = nil

	s_restart()

	s_printnl("Selected level set '", c_tcm_current_set.name, "' (", c_tcm_current_set.title, ")")
end
local commands_setSelected = commands_setSelected

function commands_mapSelected()
	s_restart()

	s_printnl("Selected level '", c_tcm_current_map.name, "' (", c_tcm_current_map.title, ")")
end
local commands_mapSelected = commands_mapSelected

function commands_args(line)
	return tankbobs.t_explode(line, " \t", true, true, true, true)
end
local commands_args = commands_args

function commands_concatArgs(line, startArg)
	if #commands_args(line) < startArg then
		return ""
	else
		return line:match("[ \t]*" .. string.rep("[^ \t]*[ \t]*", startArg - 1) .. "(.*)")
	end
end
local commands_concatArgs = commands_concatArgs

function commands_upToArg(line, endArg, noWhitespace)  -- inclusive
	noWhitespace = noWhitespace or false

	if #commands_args(line) < endArg then
		endArg = #commands_args(line)
	end

	if noWhitespace then
		return line:match("([ \t]*[^ \t]*" .. string.rep("[ \t]*[^ \t]*", endArg - 1) .. ").*")
	else
		return line:match("([ \t]*" .. string.rep("[^ \t]*[ \t]*", endArg) .. ").*")
	end
end
local commands_upToArg = commands_upToArg

function commands_command(line)
	local args = commands_args(line)

	lastCommand = line

	if #args >= 1 then
		for _, v in pairs(commands) do
			local match = false

			if type(v.name) == "string" then
				match = v.name == args[1]
			elseif type(v.name) == "table" then
				for _, v in pairs(v.name) do
					if v == args[1] then
						match = true

						break
					end
				end
			end

			if match then
				if v.f then
					return v.f(line)
				end

				return
			end
		end

		-- not found, so try a case-insensitive search
		for _, v in pairs(commands) do
			local match = false

			if type(v.name) == "string" then
				match = v.name:lower() == args[1]:lower()
			elseif type(v.name) == "table" then
				for _, v in pairs(v.name) do
					if v:lower() == args[1]:lower() then
						match = true

						break
					end
				end
			end

			if match then
				if v.f then
					return v.f(line)
				end

				return
			end
		end

		-- none found
		s_printnl("Unknown command: ", args[1])
	end
end

function commands_autoComplete(line)
	local args = commands_args(line)

	if #args > 1 then
		for _, v in pairs(commands) do
			local match = false

			if type(v.name) == "string" then
				match = v.name == args[1]
			elseif type(v.name) == "table" then
				for _, v in pairs(v.name) do
					if v == args[1] then
						match = true

						break
					end
				end
			end

			if match then
				if v.autoCompleteFunction then
					return v.autoCompleteFunction(line)
				end

				return
			end
		end

		-- not found, so try a case-insensitive search
		for _, v in pairs(commands) do
			local match = false

			if type(v.name) == "string" then
				match = v.name:lower() == args[1]:lower()
			elseif type(v.name) == "table" then
				for _, v in pairs(v.name) do
					if v:lower() == args[1]:lower() then
						match = true

						break
					end
				end
			end

			if match then
				if v.autoCompleteFunction then
					return v.autoCompleteFunction(line)
				end

				return
			end
		end
	--elseif #args == 1 then
	else
		for _, v in pairs(commands) do
			if type(v.name) == "table" then
				table.sort(v.name)
				v.matched = false
			end
		end

		local names = {}

		args[1] = args[1] or ""

		for _, v in pairs(commands) do
			local match = false

			if type(v.name) == "string" then
				if v.name:upper():find("^" .. args[1]:upper()) then
					match = v.name
				end
			elseif type(v.name) == "table" and not v.matched then
				for _, vs in pairs(v.name) do
					if vs:upper():find("^" .. args[1]:upper()) then
						match = vs
						v.matched = true  -- set the matched flag so that multiple aliases are not listed

						break
					end
				end
			end

			if match then
				table.insert(names, match)
			end
		end

		if not common_empty(names) then
			if #names > 1 then
				table.sort(names)

				-- print options to console
				for _, v in pairs(names) do
					s_printnl("  - ", v)
				end

				s_printnl()

				return common_commonStartString(names) .. line:match("[ \t]*[^ \t]*([ \t]*)")
			else
				return names[1] .. line:match("[ \t]*[^ \t]*([ \t]*)")
			end
		end
	end
end

command =
{
	new = common_new,

	name = "",  -- if name is a table, all strings after the first are aliases for the command
	f = nil,  -- function
	autoCompleteFunction = nil,
	description = "",

	matched = false
}

local help, exec, eval, exit, set, map, listSets, listMaps, echo, pause, restart, port, gameType, clientList, kick, ban, kickban, banList, unban, saveBans, loadBans, instagib, c_set, c_get
local helpT, execT, evalT, exitT, setT, mapT, listSetsT, listMapsT, echoT, pauseT, restartT, portT, gameTypeT, clientListT, kickT, banT, kickbanT, banListT, unbanT, saveBansT, loadBansT, instagibT, c_setT, c_getT

function help(line)
	local args = commands_args(line)

	if #args > 1 then
		if args[2] == "-l" then
			-- list all commands
			return commands_autoComplete("")
		else
			for _, v in pairs(commands) do
				local match = false

				if type(v.name) == "string" then
					match = v.name == args[2]
				elseif type(v.name) == "table" then
					for _, v in pairs(v.name) do
						if v == args[2] then
							match = true

							break
						end
					end
				end

				if match then
					s_print(v.description, "\n")

					return
				end
			end

			s_print("Unknown command: ", args[2], "\n")

			return
		end
	else
		s_printnl(
			"help can give the description of a command or list all\n" ..
			" available commands.  All options (those starting with '-')\n" ..
			" must be passed before the rest of the arguments after a command.\n" ..
			" For example, \"command foo -bar\" is not valid, whereas\n" ..
			" \"command -quux foo\" is.  Single-character options begin\n" ..
			" with a single '-', and multiple-character options begin with multiple '-'s\n" ..
			" GUID, GID, and UI are used interchangeably.\n" ..
			"\n" ..
			"Some common commands:\n" ..
			" -help\n" ..
			" -set\n" ..
			" -map\n" ..
			" -listMaps\n" ..
			" -listSets\n" ..
			" -gameType\n" ..
			" -instagib\n" ..
			" -exec\n" ..
			" -eval\n" ..
			" -clientList\n" ..
			" -kickban\n" ..
			" -banList\n" ..
			" -unban\n" ..
			"\n" ..
			"See \"help help\" for usage"
		)
	end
end

function helpT(line)
	local args = commands_args(line)

	if args[2] == "-l" then
		return
	end

	if #args > 1 then
		local names = {}

		for _, v in pairs(commands) do
			if type(v.name) == "table" then
				table.sort(v.name)
				v.matched = false
			end
		end

		for _, v in pairs(commands) do
			local match = false

			if type(v.name) == "string" then
				if v.name:find("^" .. common_escape(args[2])) then
					match = v.name
				end
			elseif type(v.name) == "table" and not v.matched then
				for _, vs in pairs(v.name) do
					if vs:find("^" .. common_escape(args[2])) then
						match = vs
						v.matched = true  -- set the matched flag so that multiple aliases are not listed

						break
					end
				end
			end

			if not match then
				-- case-insensitive search
				if type(v.name) == "string" then
					if v.name:lower():find("^" .. args[2]:lower()) then
						match = v.name
					end
				elseif type(v.name) == "table" and not v.matched then
					for _, vs in pairs(v.name) do
						if vs:lower():find("^" .. args[2]:lower()) then
							match = vs
							v.matched = true  -- set the matched flag so that multiple aliases are not listed
	
							break
						end
					end
				end
			end

			if match then
				table.insert(names, match)
			end
		end

		if not common_empty(names) then
			if #names > 1 then
				table.sort(names)

				-- print options to console
				for _, v in pairs(names) do
					s_printnl("  - " .. v)
				end

				s_printnl()
			end

			return commands_upToArg(line, 1) .. common_commonStartString(names)
		end
	end
end

function exit(line)
	local args = commands_args(line)

	done = true
end

-- no auto completion for exit

function exec(line)
	local args = commands_args(line)

	if #args > 1 then
		local execString = commands_concatArgs(line, 2)
		local toExec, err = loadstring(execString)

		if not toExec then
			s_printnl("exec: could not compile '", execString, "': ", err)
		else
			local results = {pcall(toExec)}

			if not results[1] then
				s_printnl("exec: could not run '", execString, "': ", results[2])
			else
				results[1] = nil
				-- give the user the output
				s_printnl("exec: code returned '", #results, "' results")
				for _, v in pairs(results) do
					if type(v) == "table" then
						s_printnl(" ", tostring(v))
						if #v > 4 then
							s_printnl("   too many elements")
						else
							for k, v in pairs(v) do
								s_printnl("   ", k, " ", v)
							end
						end
					elseif type(v) == "string" or type(v) == "boolean" or type(v) == "nil" or type(v) == "number"  then
						-- printable types
						s_printnl(" ", type(v), ": ", tostring(v))
					else
						s_printnl(" ", tostring(v))
					end
				end
			end
		end
	else
		return help("help exec")
	end
end

-- no auto completion for exec

function eval(line)
	local args = commands_args(line)
	local commands = tankbobs.t_explode(commands_concatArgs(line, 2, true), ";", false, true, true, true)

	for _, v in pairs(commands) do
		commands_command(v)
	end
end

-- no auto completion for eval

function listSets(line)
	local args = commands_args(line)
	local description = args[2] == "-d"
	local beginsWith = ""

	if description then
		if #args > 2 then
			beginsWith = commands_concatArgs(line, 3)
		end
	else
		if #args > 1 then
			beginsWith = commands_concatArgs(line, 2)
		end
	end

	if #c_tcm_current_sets > 0 then
		s_printnl(string.format("             name - %16s", "title"))

		for k, v in pairs(c_tcm_current_sets) do
			if v.name:find("^" .. common_escape(beginsWith)) or v.title:find("^" .. common_escape(beginsWith)) then
				s_printnl(string.format(" %16s - %16s", v.name, v.title))

				if description then
					s_printnl("    Description: ", v.description)
				end
			end
		end
	end
end

function listSetsT(line)
	local args = commands_args(line)
	local description = args[2] == "-d"
	local beginsWith = ""

	if description then
		if #args > 2 then
			beginsWith = commands_concatArgs(line, 3)
		end
	else
		if #args > 1 then
			beginsWith = commands_concatArgs(line, 2)
		end
	end

	if #args > 1 then
		local names = {}

		for k, v in pairs(c_tcm_current_sets) do
			if v.name:find("^" .. common_escape(beginsWith)) then
				table.insert(names, v.name)
			elseif v.title:find("^" .. common_escape(beginsWith)) then
				table.insert(names, v.name)
			end
		end

		if not common_empty(names) then
			if #names > 1 then
				table.sort(names)

				-- print options to console
				for _, v in pairs(names) do
					s_printnl("  - ", v)
				end

				s_printnl()
			end

			return commands_upToArg(line, description and 2 or 1) .. common_commonStartString(names)
		end
	end
end

function listMaps(line)
	local args = commands_args(line)
	local description = args[2] == "-d"
	local beginsWith = ""

	if c_tcm_current_set then
		s_printnl(" listMaps: listing levels of level set '", c_tcm_current_set.name, "' (", c_tcm_current_set.title, ")")
	else
		s_printnl(" listMaps: please select a level set.\n See \"help set\" for more information.")

		return
	end

	if description then
		if #args > 2 then
			beginsWith = commands_concatArgs(line, 3)
		end
	else
		if #args > 1 then
			beginsWith = commands_concatArgs(line, 2)
		end
	end

	if #c_tcm_current_set.maps > 0 then
		s_printnl(string.format("             name - %16s", "title"))

		for k, v in pairs(c_tcm_current_set.maps) do
			if v.name:find("^" .. common_escape(beginsWith)) or v.title:find("^" .. common_escape(beginsWith)) then
				s_printnl(string.format(" %16s - %16s", v.name, v.title))

				if description then
					s_printnl("    Authors:     ", v.authors)
					s_printnl("    Description: ", v.description)
				end
			end
		end
	end
end

function listMapsT(line)
	local args = commands_args(line)
	local description = args[2] == "-d"
	local beginsWith = ""

	if not c_tcm_current_set then
		return
	end

	if description then
		if #args > 2 then
			beginsWith = commands_concatArgs(line, 3)
		else
			return
		end
	else
		if #args > 1 then
			beginsWith = commands_concatArgs(line, 2)
		else
			return
		end
	end

	if #c_tcm_current_set.maps > 0 then
		local names = {}

		for k, v in pairs(c_tcm_current_set.maps) do
			if v.name:find("^" .. common_escape(beginsWith)) then
				table.insert(names, v.name)
			elseif v.title:find("^" .. common_escape(beginsWith)) then
				table.insert(names, v.name)
			end
		end

		if not common_empty(names) then
			if #names > 1 then
				table.sort(names)

				-- print options to console
				for _, v in pairs(names) do
					s_printnl("  - ", v)
				end

				s_printnl()
			end

			return commands_upToArg(line, description and 2 or 1) .. common_commonStartString(names)
		end
	end
end

function set(line)
	local args = commands_args(line)
	local byTitle = args[2] == "-t"
	local minArgs = byTitle and 2 and 1

	if #args > 1 then
		local this, that

		if byTitle then
			this = commands_concatArgs(line, 3)
		else
			this = commands_concatArgs(line, 2)
		end

		for k, v in pairs(c_tcm_current_sets) do
			if byTitle then
				that = v.title
			else
				that = v.name
			end

			if this == that then
				c_tcm_current_set = v
				commands_setSelected()

				return
			end
		end

		s_printnl("set: no such set '", this, "' found")
	else
		return help("help set")
	end
end

function setT(line)
	local args = commands_args(line)
	local byTitle = args[2] == "-t"
	local beginsWith = ""

	if byTitle then
		if #args > 2 then
			beginsWith = commands_concatArgs(line, 3)
		else
			return
		end
	else
		if #args > 1 then
			beginsWith = commands_concatArgs(line, 2)
		else
			return
		end
	end

	if #args > 1 then
		local names = {}

		for k, v in pairs(c_tcm_current_sets) do
			if not byTitle and v.name:find("^" .. common_escape(beginsWith)) then
				table.insert(names, v.name)
			elseif byTitle and v.title:find("^" .. common_escape(beginsWith)) then
				table.insert(names, v.title)
			end
		end

		if not common_empty(names) then
			if #names > 1 then
				table.sort(names)

				-- print options to console
				for _, v in pairs(names) do
					s_printnl("  - ", v)
				end

				s_printnl()
			end

			return commands_upToArg(line, byTitle and 2 or 1) .. common_commonStartString(names)
		end
	end
end

function map(line)
	local args = commands_args(line)
	local byTitle = args[2] == "-t"
	local minArgs = byTitle and 2 and 1

	if not c_tcm_current_set then
		s_print(" map: please select a level set.\n See \"help set\" for more information.\n")

		return
	end

	if #args > 1 then
		local this, that

		if byTitle then
			this = commands_concatArgs(line, 3)
		else
			this = commands_concatArgs(line, 2)
		end

		for k, v in pairs(c_tcm_current_set.maps) do
			if byTitle then
				that = v.title
			else
				that = v.name
			end

			if this == that then
				c_tcm_current_map = v
				commands_mapSelected()

				return
			end
		end

		s_printnl("map: no such map '", this, "' found")
	else
		return help("help map")
	end
end

function mapT(line)
	local args = commands_args(line)
	local byTitle = args[2] == "-t"
	local beginsWith

	if not c_tcm_current_set then
		return
	end

	if byTitle then
		if #args > 2 then
			beginsWith = commands_concatArgs(line, 3)
		else
			return
		end
	else
		if #args > 1 then
			beginsWith = commands_concatArgs(line, 2)
		else
			return
		end
	end
	if #c_tcm_current_set.maps > 0 then
		local names = {}

		for k, v in pairs(c_tcm_current_set.maps) do
			if not byTitle and v.name:find("^" .. common_escape(beginsWith)) then
				table.insert(names, v.name)
			elseif byTitle and v.title:find("^" .. common_escape(beginsWith)) then
				table.insert(names, v.title)
			end
		end

		if not common_empty(names) then
			if #names > 1 then
				table.sort(names)

				-- print options to console
				for _, v in pairs(names) do
					s_printnl("  - ", v)
				end

				s_printnl()
			end

			return commands_upToArg(line, byTitle and 2 or 1) .. common_commonStartString(names)
		end
	end
end

function echo(line)
	local args = commands_args(line)

	if #args > 1 then
		s_println(commands_concatArgs(line, 2))
	else
		return help("help echo")
	end
end

-- no auto completion for echo

function pause(line)
	local args = commands_args(line)

	if c_world_getPaused() then
		c_world_setPaused(false)
		s_printnl(" pause: the game has been unpaused")
	else
		c_world_setPaused(true)
		s_printnl(" pause: the game has been paused")
	end
end

-- no auto completion for pause

function restart(line)
	local args = commands_args(line)

	s_restart()
end

-- no auto completion for restart

function port(line)
	local args = commands_args(line)

	if #args >= 2 then
		local port = tonumber(args[2])

		if not port or port > 65535 or port < 0 then
			return help("help port")
		end

		c_config_set("server.port", port)

		s_printnl("port: new port '", tostring(port), "' will be used on next restart")
	else
		s_printnl("port: current port is '", tostring(c_config_get("server.port")), "'")
	end
end

-- no auto completion for port

function gameType(line)
	local args = commands_args(line)

	if #args >= 2 then
		local gameType = tostring(args[2])

		if not gameType then
			return help("help gameType")
		end

		c_config_set("game.gameType", gameType)

		s_printnl("gameType: new game type '", tostring(gameType), "' will be used on next restart")
	else
		s_printnl("gameType: current game type is '", c_world_gameTypeString(), "' (" .. c_world_gameTypeHumanString() .. ")")
	end
end

do
local gameTypes = {}
for k, v in pairs(c_world_getGameTypes()) do
	gameTypes[k] = c_world_gameTypeString(v[1])
end
function gameTypeT(line)
	local args = commands_args(line)
	local gameType = commands_concatArgs(line, 2)
	local names = {}

	if #args >= 2 then
		for _, v in pairs(gameTypes) do
			if v:lower():find("^" .. gameType:lower()) then
				table.insert(names, v)
			end
		end

		if #names > 1 then
			table.sort(names)

			-- print options to console
			for _, v in pairs(names) do
				s_printnl("  - ", v)
			end

			s_printnl()

			return commands_upToArg(line, 1) .. common_commonStartString(names)
		elseif #names == 1 then
			return commands_upToArg(line, 1) .. names[1]
		end
	end
end
end

local guidLen = 6
local clientFormat = "%3s - %15s - %15s - %5s - %10s - %" .. tostring(1 + 2 * (guidLen)) .. "s"
function clientList(line)
	local args = commands_args(line)
	local idOnly = args[2] == "-i" or args[2] == "--id-only"
	local clients

	if #args >= (idOnly and 3 or 2) then
		local identifier = commands_concatArgs(line, idOnly and 3 or 2)

		clients = client_getClientsByIdentifier(identifier, idOnly)
	else
		clients = client_getClients()
	end

	s_printnl("clientList: '", #clients, "' connected client" .. (#clients == 1 and "" or "s"))

	s_printnl()
	s_printnl(string.format(clientFormat, "ID", "name", "IP", "port", "connecting", "guid"))
	for k, v in pairs(clients) do
		s_printnl(string.format(clientFormat, tostring(k), v.tank.name, v.ip, tostring(v.port), v.banned and "banned" or (v.connecting and "connecting" or "connected"), "*" .. common_stringToHex("", "", v.ui:sub(-guidLen, -1))))
	end
	s_printnl()
end

-- no auto completion for clientList

function kick(line)
	local args = commands_args(line)
	local idOnly = args[2] == "-i" or args[2] == "--id-only"
	local num = (idOnly and #args - 1 or #args)

	if num >= 3 then
		local identifier = args[2]
		local reason = commands_concatArgs(line, 3)

		local clients = client_getClientsByIdentifier(identifier, idOnly)

		if #clients > 1 then
			s_printnl("kick: '", tostring(#clients) .. "' clients found matching ID, guid, IP:port, or name of '", tostring(identifier), "'")

			s_printnl()
			return clientList("clientList " .. (idOnly and "--id-only " or "") .. "\"" .. identifier .. "\"")
		elseif #clients == 1 then
			client_kick(clients[1], reason)
		else--if #clients < 1 then
			s_printnl("kick: no clients found matching ID, guid, IP:port, or name of '", tostring(identifier), "'")
		end
	else
		return help("help kick")
	end
end

-- no auto completion for kick

function ban(line)
	local args = commands_args(line)
	local idOnly = args[2] == "-i" or args[2] == "--id-only"
	local num = (idOnly and #args - 1 or #args)

	if num >= 3 then
		local identifier = args[2]
		local reason = commands_concatArgs(line, 3)

		local clients = client_getClientsByIdentifier(identifier, idOnly)

		if #clients > 1 then
			s_printnl("ban: '", tostring(#clients) .. "' clients found matching ID, guid, IP:port, or name of '", tostring(identifier), "'")

			s_printnl()
			return clientList("clientList " .. (idOnly and "--id-only " or "") .. "\"" .. identifier .. "\"")
		elseif #clients == 1 then
			client_banClient(clients[1], reason, "console")
		else--if #clients < 1 then
			s_printnl("ban: no clients found matching ID, GUID, IP:port, or name of '", tostring(identifier), "'")
		end
	else
		return help("help ban")
	end
end

-- no auto completion for ban

function kickban(line)
	ban(line)
	kick(line)
end

-- no auto completion for kickban

local guidLen = 6
local banFormat = "%4d - %15s - %" .. tostring(1 + 2 * (guidLen)) .. "s - %25s - %64s"
function banList(line)
	local args   = commands_args(line)
	local range  = nil
	local filter = nil

	if #args >= 3 then
		if args[3]:find("^[(%d)]+# *- *[(%d)]+#$") then
			range = {args[3]:match("^[(%d)]+# *- *[(%d)]+#$")}
			range[1] = tonumber(range[1])
			range[2] = tonumber(range[2])

			filter = args[3]
		elseif args[2]:find("^[(%d)]+# *- *[(%d)]+#$") then
			range = {args[2]:match("^[(%d)]+# *- *[(%d)]+#$")}
			range[1] = tonumber(range[1])
			range[2] = tonumber(range[2])

			filter = args[3]
		end
	elseif #args == 2 then
		if args[2]:find("^[(%d)]+# *- *[(%d)]+#$") then
			range = {args[2]:match("^[(%d)]+# *- *[(%d)]+#$")}
			range[1] = tonumber(range[1])
			range[2] = tonumber(range[2])
		else
			filter = args[2]
		end
	end

	local bans = client_getBans(range, filter)

	s_printnl("banList: '", #bans, "' bans shown")

	for k, v in pairs(bans) do
		s_printnl(string.format(banFormat, v[1], v[2].ip, "*" .. v[2].ui:sub(2 * -guidLen, -1), v[2].name, v[2].reason))
	end

	s_printnl()
end

-- no auto completion for banList

function unban(line)
	local args = commands_args(line)

	if #args >= 2 then
		local banID = tonumber(args[2])

		if not banID then
			return help("help unban")
		end

		if not client_getBans()[banID] then
			s_printnl("unban: no such ban by ID '", tostring(banID), "'")
		end

		client_unban(banID)

		s_printnl("unban: removed ban '", tostring(banID), "'")
	else
		return help("help unban")
	end
end

-- no auto completion for unban

function saveBans(line)
	local args = commands_args(line)
	local filename = args[2] or c_const_get("bans_file")

	client_saveBans(filename)

	s_printnl("saveBans: bans saved to ", filename)
end

-- no auto completion for saveBans

function saveBans(line)
	local args = commands_args(line)
	local filename = args[2] or c_const_get("bans_file")

	client_saveBans(filename)

	s_printnl("saveBans: bans saved to ", filename)
end

-- no auto completion for loadBans

function loadBans(line)
	local args = commands_args(line)
	local filename = args[2] or c_const_get("bans_file")

	client_loadBans(filename)

	s_printnl("loadBans: bans read from ", filename)
end

function instagib(line)
	local args = commands_args(line)

	if #args >= 2 then
		local instagib = tostring(args[2]):lower()
		local enabled = nil

		local switch = instagib:sub(1, 1)
		if switch == 't' then
			enabled = true
		elseif switch == 'f' then
			enabled = false
		elseif switch == 'd' then
			enabled = false
		elseif switch == 'e' then
			enabled = true
		elseif switch == 'y' then
			enabled = true
		elseif switch == 'n' then
			enabled = false
		elseif switch == 'o' then
			local switch = instagib:sub(2, 2)
			if switch == 'n' then
				enabled = true
			elseif switch == 'f' then
				if instagib:sub(3, 3) == 'f' then
					enabled = false
				end
			end
		elseif switch == 's' then
			enabled = "semi"
		elseif switch == '/' then
			enabled = "semi"
		elseif switch == 'p' then
			enabled = "semi"
		end

		if enabled == nil then
			return help("help instagib")
		end

		c_config_set("game.instagib", enabled)

		s_printnl("instagib: instagib will be set to '", tostring(enabled),"' at next restart")
	else
		local instagib
		local nextInstagib

		local function textify(instagib)
			local switch = c_world_getInstagib()
			if switch == true then
				return "enabled"
			elseif switch == "semi" then
				return "semi"
			else
				return "disabled"
			end
		end

		instagib = textify(c_world_getInstagib())
		nextInstagib = textify(c_config_get("game.instagib"))

		s_printnl("instagib: instagib is currently set to '", instagib, "'")
		if nextInstagib ~= instagib then
			s_printnl("instagib: instagib will be set to '", nextInstagib, "' at next restart")
		end
	end
end

-- no auto completion for instagib

function c_set(line)
	local args = commands_args(line)
	local force = args[2] == "-f"
	local config = force and args[3] or args[2]
	local val = force and commands_concatArgs(line, 4) or commands_concatArgs(line, 3)
	local minArgs = args[2] == force and 4 or 3

	if #args >= minArgs then
		if force or c_config_get(config, true) ~= nil then
			c_config_set(config, val)
			s_printnl("c_set: configurable '", config, "' set to '", tostring(val),"'")
		else
			s_printnl("c_set: configurable doesn't exist (see \"help c_set\")")
		end
	else
		return help("help c_set")
	end
end

-- no auto completion for set

function c_get(line)
	local args = commands_args(line)

	if #args >= 2 then
		local result = c_config_get(args[2], true)

		if result == nil then
			s_printnl("c_get: config '", args[2], "' doesn't exist (or is nil)")
		else
			s_printnl("c_get: config '", args[2], "' is currently set to '", tostring(result), "'")
		end
	else
		return help("help c_get")
	end
end

-- no auto completion for get

commands =
{
	{
		"help",
		help,
		helpT,
		"Usage:\n" ..
		" help (-l|command)\n" ..
		"\n" ..
		" If the -l option is given,\n" ..
		" a list of commands is given.\n" ..
		" Otherwise, if command is given, the description\n" ..
		" of the command is given."
	},

	{
		{"exec", "exe", "execute"},
		exec,
		execT,
		"Usage:\n" ..
		" exec [lua code]\n" ..
		"\n" ..
		" Executes lua code"
	},

	{
		{"eval", "evaluate"},
		eval,
		evalT,
		"Usage:\n" ..
		" eval commands\n" ..
		"\n" ..
		" This command evaluates multiple commands.  The commands are separated by\n" ..
		" semicolons.  Everything passed to the server by the command line\n" ..
		" is passed to this command, but whitespace will not be preserved in this case!  (TODO)\n" ..  -- TODO
		" Example: \"eval echo message 1; echo message 2\""
	},

	{
		{"exit", "quit"},
		exit,
		exitT,
		"Usage:\n" ..
		" exit\n" ..
		"\n" ..
		" Stops the server"
	},

	{
		"set",
		set,
		setT,
		"Usage:\n" ..
		" set (-t) [name]\n" ..
		"\n" ..
		" Loads a set with the name \"name\".\n" ..
		" If the -t option is present, the set will be selected\n" ..
		" by title"
	},

	{
		"map",
		map,
		mapT,
		"Usage:\n" ..
		" map (-t) [name]\n" ..
		"\n" ..
		" Loads a map with the name \"name\".\n" ..
		" If the -t option is present, the map will be selected\n" ..
		" by title"
	},

	{
		{"listSets", "showSets", "setList"},
		listSets,
		listSetsT,
		"Usage:\n" ..
		" listSets (-d) (beginsIn)\n" ..
		"\n" ..
		" Lists the available sets\n" ..
		" If the -d is given, the description of the sets are given."
	},

	{
		{"listMaps", "showMaps", "mapList"},
		listMaps,
		listMapsT,
		"Usage:\n" ..
		" listMaps (-d) (beginsIn)\n" ..
		"\n" ..
		" Lists the available maps of the current select set\n" ..
		" that optionally start with \"beginsIn\".\n" ..
		" This must be run after \"set\".\n" ..
		" If the -d is given, the description and authors of the maps are given."
	},

	{
		{"echo", "print"},
		echo,
		echoT,
		"Usage:\n" ..
		" echo [text]\n" ..
		"\n" ..
		" Prints text to the console"
	},

	{
		{"pause", "pause"},
		pause,
		pauseT,
		"Usage:\n" ..
		" pause\n" ..
		"\n" ..
		" Pauses or unpauses the game"
	},

	{
		"restart",
		restart,
		restartT,
		"Usage:\n" ..
		" restart\n" ..
		"\n" ..
		" Restarts the game"
	},

	{
		"port",
		port,
		portT,
		"Usage:\n" ..
		" port (port)\n" ..
		"\n" ..
		" Sets the port to be used on restart"
	},

	{
		"gameType",
		gameType,
		gameTypeT,
		"Usage:\n" ..
		" gameType (game type)\n" ..
		"\n" ..
		" Sets the game type, or lists the current gameType when called without arguments"
	},

	{
		{"clientList", "listClients", "showClients", "showClientList", "clients"},
		clientList,
		clientListT,
		"Usage:\n" ..
		" clientList (-i/--id-only) (client)\n" ..
		"\n" ..
		" Lists the connected clients.  This list can optionally be limited\n" ..
		" by the identifier 'client'\n" ..
		" If a listed client is banned, he isn't really connected.  This is a placeholder\n" ..
		" so that the server can ignore the client on future connection attempts\n" ..
		" for the current map, partly to avoid \"connection attempt\" spam.\n" ..
		" This placeholder will need to be kicked after you unban a client\n" ..
		" if you want him to be able to connect after you unban him."
	},

	{
		{"kick", "drop"},
		kick,
		kickT,
		"Usage:\n" ..
		" kick (-i/--id-only) [client] [reason]\n" ..
		"\n" ..
		" Disconnects client from the server\n" ..
		" for a reason.  Clients can be specified by ID, (partial) GID, \n" ..
		" IP:port (both IP and port, e.g. 1.2.3.4:43210), or (partial) name (see \"help clientList\").\n" ..
		" If multiple clients match the identifier, a list will be presented to the user, and no action\n" ..
		" will be taken.  If the -i (id-only) option is given, only ID's will be tested\n" ..
		" by his ID, regardless of other matches; this is the only affect of the -f (force) option."
	},

	{
		"ban",
		ban,
		banT,
		"Usage:\n" ..
		" ban (-i/--id-only) [client] [reason]\n" ..
		"\n" ..
		" Prevents the client from connecting in the future until the ban is manually lifted.\n" ..
		" A ban itself will not immediately disconnect a player (see \"help kickban\")"
	},

	{
		{"kickban", "bankick", "kickandban", "banandkick"},
		kickban,
		kickbanT,
		"Usage:\n" ..
		" kickban (-i/--id-only) [client] [reason]\n" ..
		"\n" ..
		" \"kickban\" directly calls \"ban\" with the arguments given, and then \"kick\" with\n" ..
		" the arguments given.  This effectively disconnects and bans a client from a server.\n" ..
		" See \"help ban\" and \"help kick\" for more information"
	},

	{
		{"banList", "listBans", "showBans", "showBanList", "bans"},
		banList,
		banListT,
		"Usage:\n" ..
		" banList (start#-end#) (filter)\n" ..
		"\n" ..
		" Lists all bans by default.\n" ..
		" If the second or third argument given matches\n" ..
		" ^[(%d)]+# *- *[(%d)]+#$, it is treated as the ban list range, and if the\n" ..
		" other argument exists, it is treated as the filter; \n" ..
		" otherwise, the first argument given will be the filter (remember to quote spaces).  The\n" ..
		" filter will be tested with string.find against the name of the banned client, the GID, and\n" ..
		" IP."
	},

	{
		{"unban", "removeBan", "liftBan"},
		unban,
		unbanT,
		"Usage:\n" ..
		" unban [banID]\n" ..
		"\n" ..
		" Removes a ban"
	},

	{
		{"saveBans", "writeBans"},
		saveBans,
		saveBansT,
		"Usage:\n" ..
		" saveBans (filename)\n" ..
		"\n" ..
		" Writes all bans to the file given, or the bans file by default.  Tankbobs\n" ..
		" automatically writes all bans to the\n" ..
		" bans file on restart."
	},

	{
		{"loadBans", "readBans"},
		loadBans,
		loadBansT,
		"Usage:\n" ..
		" loadBans (filename)\n" ..
		"\n" ..
		" Reads bans from the file given, or the bans file by default.  All unsaved\n" ..
		" bans will be lost!"
	},

	{
		"instagib",
		instagib,
		instagibT,
		"Usage:\n" ..
		" instagib (true|false|enabled|disabled|yes|no|on|off)\n" ..
		"\n"  ..
		" Sets instagib mode.  When called without arguments, will print the\n" ..
		" current mode to console."
	},

	{
		{"c_set", "config_set", "cset", "configSet"},
		c_set,
		c_setT,
		"Usage:\n" ..
		" c_set (-f) config val\n" ..
		"\n" ..
		" Sets a configurable to the given value.  The '-f' option will set a configurable\n" ..
		" even if it doesn't exist.  Setting too many non-existent variables can inflate the\n" ..
		" configuration and make the server run slowly.\n" ..
		"\n" ..
		" These configurables are commonly set:\n" ..
		"   - game.fragLimit\n" ..
		"   - game.chaseLimit\n" ..
		"   - game.pointLimit (domination)\n" ..
		"   - game.captureLimit\n" ..
		"   - server.port\n" ..
		"   - server.logFile (blank, false or nil to not record logs)\n" ..
		"   - server.writeFileOnBan"
	},

	{
		{"c_get", "config_get", "cget", "configGet", "get"},
		c_get,
		c_getT,
		"Usage:\n" ..
		" c_get config\n" ..
		"\n" ..
		" Outputs a configurable to the console."
	},
}
