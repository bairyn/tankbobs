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
	end
end

function commands_done()
end

function commands_setSelected()
	s_printnl("Selected level set '", c_tcm_current_set.name, "' (", c_tcm_current_set.title, ")")
end
local commands_setSelected = commands_setSelected

function commands_mapSelected()
	s_printnl("Selected level '", c_tcm_current_map.name, "' (", c_tcm_current_map.title, ")")

	s_restart()
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
		local names = {}

		args[1] = args[1] or ""

		for _, v in pairs(commands) do
			local match = false

			if type(v.name) == "string" then
				if v.name:upper():find("^" .. args[1]:upper()) then
					match = v.name
				end
			elseif type(v.name) == "table" then
				for _, v in pairs(v.name) do
					if v:upper():find("^" .. args[1]:upper()) then
						match = v

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

				-- print options to console and don't touch the input
				for _, v in pairs(names) do
					s_printnl("  - ", v)
				end

				s_printnl()

				return
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
	description = ""
}

local help, exec, exit, set, map, listSets, listMaps, echo, pause, restart, port, gameType, clientList, kick
local helpT, execT, exitT, setT, mapT, listSetsT, listMapsT, echoT, pauseT, restartT, portT, gameTypeT, clientListT, kickT

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
		s_print(
			"help can give the description of a command or list all.\n" ..
			" available commands.  When a command is called, the options\n" ..
			" must be in order .  For example,\n" ..
			" \"command foo -bar\" will not pass the option -bar to foo.\n" ..
			" All options start with one '-'\n" ..
			"\n" ..
			"Some common commands:\n" ..
			" -help\n" ..
			" -set\n" ..
			" -map\n" ..
			" -listMaps\n" ..
			" -listSets\n" ..
			" -gameType\n" ..
			" -exec\n" ..
			"\n" ..
			"See \"help help\" for usage\n"
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
			local match = false

			if type(v.name) == "string" then
				if v.name:find("^" .. args[2]) then
					match = v.name
				end
			elseif type(v.name) == "table" then
				for _, v in pairs(v.name) do
					if v:find("^" .. args[2]) then
						match = v

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
				elseif type(v.name) == "table" then
					for _, v in pairs(v.name) do
						if v:lower():find("^" .. args[2]:lower()) then
							match = v
	
							break
						end
					end
				end
			end

			if match then
				table.insert(names, v.name)
			end
		end

		if not common_empty(names) then
			if #names > 1 then
				table.sort(names)

				-- print options to console and don't touch the input
				for _, v in pairs(names) do
					s_printnl("  - " .. v)
				end

				s_printnl()

				return
			else
				return commands_upToArg(line, 1) .. names[1]
			end
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
			s_print("exec: could not compile '", execString, "': ", err, "\n")
		else
			local results = {pcall(toExec)}

			if not results[1] then
				s_print("exec: could not run '", execString, "': ", results[2], "\n")
			else
				table.remove(results, 1)
				-- give the user the output
				s_print("exec: code returned '", #results, "' results\n")
				for _, v in pairs(results) do
					if type(v) == "table" then
						s_print(" ", tostring(v))
						if #v > 4 then
							s_print("   too many elements\n")
						else
							for k, v in pairs(v) do
								s_print("   ", k, " ", v, "\n")
							end
						end
					elseif type(v) == "string" or type(v) == "boolean" or type(v) == "nil" or type(v) == "number"  then
						-- printable types
						s_print(" ", type(v), ": ", tostring(v), "\n")
					else
						s_print(" ", tostring(v), "\n")
					end
				end
			end
		end
	else
		return help("help exec")
	end
end

-- no auto completion for exec

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
			if v.name:find("^" .. beginsWith) or v.title:find("^" .. beginsWith) then
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
			if v.name:find("^" .. beginsWith) then
				table.insert(names, v.name)
			elseif v.title:find("^" .. beginsWith) then
				table.insert(names, v.name)
			end
		end

		if not common_empty(names) then
			if #names > 1 then
				table.sort(names)

				-- print options to console and don't touch the input
				for _, v in pairs(names) do
					s_printnl("  - ", v)
				end

				s_printnl()

				return
			else
				return commands_upToArg(line, description and 2 or 1) .. names[1]
			end
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
			if v.name:find("^" .. beginsWith) or v.title:find("^" .. beginsWith) then
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
			if v.name:find("^" .. beginsWith) then
				table.insert(names, v.name)
			elseif v.title:find("^" .. beginsWith) then
				table.insert(names, v.name)
			end
		end

		if not common_empty(names) then
			if #names > 1 then
				table.sort(names)

				-- print options to console and don't touch the input
				for _, v in pairs(names) do
					s_printnl("  - ", v)
				end

				s_printnl()

				return
			else
				return commands_upToArg(line, description and 2 or 1) .. names[1]
			end
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
			if not byTitle and v.name:find("^" .. beginsWith) then
				table.insert(names, v.name)
			elseif byTitle and v.title:find("^" .. beginsWith) then
				table.insert(names, v.title)
			end
		end

		if not common_empty(names) then
			if #names > 1 then
				table.sort(names)

				-- print options to console and don't touch the input
				for _, v in pairs(names) do
					s_printnl("  - ", v)
				end

				s_printnl()

				return
			else
				return commands_upToArg(line, byTitle and 2 or 1) .. names[1]
			end
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
			if not byTitle and v.name:find("^" .. beginsWith) then
				table.insert(names, v.name)
			elseif byTitle and v.title:find("^" .. beginsWith) then
				table.insert(names, v.title)
			end
		end

		if not common_empty(names) then
			if #names > 1 then
				table.sort(names)

				-- print options to console and don't touch the input
				for _, v in pairs(names) do
					s_printnl("  - ", v)
				end

				s_printnl()

				return
			else
				return commands_upToArg(line, byTitle and 2 or 1) .. names[1]
			end
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
		s_print(" pause: the game has been unpaused")
	else
		c_world_setPaused(true)
		s_print(" pause: the game has been paused")
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
		return help("help gameType")
	end
end

do
local gameTypes = {"deathmatch", "domination", "capturetheflag"}
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

			-- print options to console and don't touch the input
			for _, v in pairs(names) do
				s_printnl("  - ", v)
			end

			s_printnl()

			return
		elseif #names == 1 then
			return commands_upToArg(line, 1) .. names[1]
		end
	end
end
end

local guidLen = 6
local clientFormat = "%3s - %15s - %15s - %5s - %10s - %" .. tostring(1 + 4 * (guidLen) + 1 * (guidLen - 1)) .. "s"
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

	s_printnl("clientList: '", #clients, "connected client" .. (#clients == 1 and "" or "s"))

	s_printnl()
	s_printnl(string.format(clientFormat, "ID", "name", "IP", "port", "connecting", "guid"))
	for k, v in pairs(clients) do
		s_printnl(string.format(clientFormat, tostring(k, v.name), v.ip, tostring(v.port), v.connecting and "connecting" or "connected", "*" .. common_stringToHex("", "", v.ui:sub(-guidLen, -1))))
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
		local reason = args[3]

		local clients = client_getClientsByIdentifier(identifier, idOnly)

		if #clients > 1 then
			s_printnl("kick: '", tostring(#clients) .. "' clients found matching ID, guid, IP:port, or name of ", tostring(identifier))

			s_printnl()
			return clientList("clientList " .. (idOnly and "--id-only " or "") .. "\"" .. identifier .. "\"")
		elseif #clients == 1 then
			client_kick(clients[1], reason)
		else--if #clients < 1 then
			s_printnl("kick: no clients found matching ID, guid, IP:port, or name of ", tostring(identifier))
		end
	else
		return help("help kick")
	end
end

-- no auto completion for kick

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
		" gameType [game type]\n" ..
		"\n" ..
		" Sets the game type"
	},

	{
		{"clientList", "listClients", "showClients", "showClientList"},
		clientList,
		clientListT,
		"Usage:\n" ..
		" clientList (-i/--id-only) (client)\n" ..
		"\n" ..
		" Lists the connected clients.  This list can optionally be limited\n" ..
		" by the identifier 'client'"
	},

	{
		{"kick", "drop"},
		kick,
		kickT,
		"Usage:\n" ..
		" kick (-i/--id-only) [client] [reason]\n" ..
		"\n" ..
		" Disconnects client from the server\n" ..
		" for a reason.  Clients can be specified by ID, (partial) guid, \n" ..
		" IP:port (both IP and port, e.g. 1.2.3.4:43210), or (partial) name (see \"help clientList\").\n" ..
		" If multiple clients match the identifier, a list will be presented to the user, and no action\n" ..
		" will be taken.  If the -i (id-only) option is given, only ID's will be tested\n" ..
		" by his ID, regardless of other matches; this is the only affect of the -f (force) option."
	},
}
