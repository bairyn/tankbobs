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

local function commands_private_setSelected()
	s_printnl("Selected level set '", c_tcm_current_set.name, "' (", c_tcm_current_set.title, ")")
end

local function commands_private_mapSelected()
	s_printnl("Selected level '", c_tcm_current_map.name, "' (", c_tcm_current_map.title, ")")

	s_restart()
end

local function commands_private_args(line)
	return tankbobs.t_explode(line, " \t", true, true, true)
end

local function commands_private_concatArgs(line, startArg)
	if #commands_private_args(line) < startArg then
		return ""
	else
		return line:match("[ \t]*" .. string.rep("[^ \t]*[ \t]*", startArg - 1) .. "(.*)")
	end
end

local function commands_private_upToArg(line, endArg)  -- inclusive
	if #commands_private_args(line) < endArg then
		endArg = #commands_private_args(line)
	end

	return line:match("([ \t]*" .. string.rep("[^ \t]*[ \t]*", endArg - 1) .. ").*")
end

function commands_command(line)
	local args = commands_private_args(line)

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
				match = tolower(v.name) == tolower(args[1])
			elseif type(v.name) == "table" then
				for _, v in pairs(v.name) do
					if tolower(v) == tolower(args[1]) then
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
	local args = commands_private_args(line)

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
	elseif #args == 1 then
		local names = {}

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

				-- print these options to the console and keep the input the same
				for _, v in pairs(names) do
					s_print("  - ", v, "\n")
				end

				return
			else
				return names[1]
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

local help, exec, exit, set, map, listSets, listMaps, echo, pause, port
local helpT, execT, exitT, setT, mapT, listSetsT, listMapsT, echoT, pauseT, port

function help(line)
	local args = commands_private_args(line)

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
			" -exec\n" ..
			"\n" ..
			"See \"help help\" for usage\n"
		)
	end
end

function helpT(line)
	local args = commands_private_args(line)

	if args[2] == "-l" then
		return
	end

	if #args > 1 then
		local names = {}

		for _, v in pairs(commands) do
			local match = false

			if type(v.name) == "string" then
				if v.name:find("^" .. args[1]) then
					match = v.name
				end
			elseif type(v.name) == "table" then
				for _, v in pairs(v.name) do
					if v:find("^" .. args[1]) then
						match = v

						break
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

				-- print these options to the console and keep the input the same
				for _, v in pairs(names) do
					s_print("  - " .. v)
				end

				return
			else
				return commands_private_upToArg(line, 1) .. names[1]
			end
		end
	end
end

function exit(line)
	local args = commands_private_args(line)

	done = true
end

-- no auto completion for exit

function exec(line)
	local args = commands_private_args(line)

	if #args > 1 then
		local execString = commands_private_concatArgs(line, 2)
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
	local args = commands_private_args(line)
	local description = args[2] == "-d"
	local beginsWith = ""

	if description then
		if #args > 2 then
			beginsWith = commands_private_concatArgs(line, 3)
		end
	else
		if #args > 1 then
			beginsWith = commands_private_concatArgs(line, 2)
		end
	end

	if #c_tcm_current_sets > 0 then
		s_print("             name - title\n")

		for k, v in pairs(c_tcm_current_sets) do
			if v.name:find("^" .. beginsWith) or v.title:find("^" .. beginsWith) then
				s_print(string.format(" %16s - %16s\n", v.name, v.title))

				if description then
					s_print("    Description: ", v.description, "\n")
				end
			end
		end
	end
end

function listSetsT(line)
	local args = commands_private_args(line)
	local description = args[2] == "-d"
	local beginsWith = ""

	if description then
		if #args > 2 then
			beginsWith = commands_private_concatArgs(line, 3)
		end
	else
		if #args > 1 then
			beginsWith = commands_private_concatArgs(line, 2)
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

				-- print these options to the console and keep the input the same
				for _, v in pairs(names) do
					s_print("  - ", v, "\n")
				end

				return
			else
				return commands_private_upToArg(line, description and 2 or 1) .. names[1]
			end
		end
	end
end

function listMaps(line)
	local args = commands_private_args(line)
	local description = args[2] == "-d"
	local beginsWith = ""

	if c_tcm_current_set then
		s_print(" listMaps: listing levels of level set '", c_tcm_current_set.name, "' (", c_tcm_current_set.title, ")\n")
	else
		s_print(" listMaps: please select a level set.\n See \"help set\" for more information.\n")

		return
	end

	if description then
		if #args > 2 then
			beginsWith = commands_private_concatArgs(line, 3)
		end
	else
		if #args > 1 then
			beginsWith = commands_private_concatArgs(line, 2)
		end
	end

	if #c_tcm_current_set.maps > 0 then
		s_print("             name - title\n")

		for k, v in pairs(c_tcm_current_set.maps) do
			if v.name:find("^" .. beginsWith) or v.title:find("^" .. beginsWith) then
				s_print(string.format(" %16s - %16s\n", v.name, v.title))

				if description then
					s_print("    Authors:     ", v.authors, "\n")
					s_print("    Description: ", v.description, "\n")
				end
			end
		end
	end
end

function listMapsT(line)
	local args = commands_private_args(line)
	local description = args[2] == "-d"
	local beginsWith = ""

	if not c_tcm_current_set then
		return
	end

	if description then
		if #args > 2 then
			beginsWith = commands_private_concatArgs(line, 3)
		else
			return
		end
	else
		if #args > 1 then
			beginsWith = commands_private_concatArgs(line, 2)
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

				-- print these options to the console and keep the input the same
				for _, v in pairs(names) do
					s_print("  - ", v, "\n")
				end

				return
			else
				return commands_private_upToArg(line, description and 2 or 1) .. names[1]
			end
		end
	end
end

function set(line)
	local args = commands_private_args(line)
	local byTitle = args[2] == "-t"
	local minArgs = byTitle and 2 and 1

	if #args > 1 then
		local this, that

		if byTitle then
			this = commands_private_concatArgs(line, 3)
		else
			this = commands_private_concatArgs(line, 2)
		end

		for k, v in pairs(c_tcm_current_sets) do
			if byTitle then
				that = v.title
			else
				that = v.name
			end

			if this == that then
				c_tcm_current_set = v
				commands_private_setSelected()

				return
			end
		end
	else
		return help("help set")
	end
end

function setT(line)
	local args = commands_private_args(line)
	local byTitle = args[2] == "-t"
	local beginsWith = ""

	if byTitle then
		if #args > 2 then
			beginsWith = commands_private_concatArgs(line, 3)
		else
			return
		end
	else
		if #args > 1 then
			beginsWith = commands_private_concatArgs(line, 2)
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

				-- print these options to the console and keep the input the same
				for _, v in pairs(names) do
					s_print("  - ", v, "\n")
				end

				return
			else
				return commands_private_upToArg(line, byTitle and 2 or 1) .. names[1]
			end
		end
	end
end

function map(line)
	local args = commands_private_args(line)
	local byTitle = args[2] == "-t"
	local minArgs = byTitle and 2 and 1

	if not c_tcm_current_set then
		s_print(" map: please select a level set.\n See \"help set\" for more information.\n")

		return
	end

	if #args > 1 then
		local this, that

		if byTitle then
			this = commands_private_concatArgs(line, 3)
		else
			this = commands_private_concatArgs(line, 2)
		end

		for k, v in pairs(c_tcm_current_set.maps) do
			if byTitle then
				that = v.title
			else
				that = v.name
			end

			if this == that then
				c_tcm_current_map = v
				commands_private_mapSelected()

				return
			end
		end
	else
		return help("help map")
	end
end

function mapT(line)
	local args = commands_private_args(line)
	local byTitle = args[2] == "-t"
	local beginsWith

	if not c_tcm_current_set then
		return
	end

	if byTitle then
		if #args > 2 then
			beginsWith = commands_private_concatArgs(line, 3)
		else
			return
		end
	else
		if #args > 1 then
			beginsWith = commands_private_concatArgs(line, 2)
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

				-- print these options to the console and keep the input the same
				for _, v in pairs(names) do
					s_print("  - ", v, "\n")
				end

				return
			else
				return commands_private_upToArg(line, byTitle and 2 or 1) .. names[1]
			end
		end
	end
end

function echo(line)
	local args = commands_private_args(line)

	if #args > 1 then
		s_println(commands_private_concatArgs(line, 2))
	else
		return help("help echo")
	end
end

-- no auto completion for echo

function pause(line)
	local args = commands_private_args(line)

	if c_world_getPaused() then
		c_world_setPaused(false)
		s_print(" pause: the game has been unpaused")
	else
		c_world_setPaused(true)
		s_print(" pause: the game has been paused")
	end
end

-- no auto completion for pause

function port(line)
	local args = commands_private_args(line)

	if #args >= 2 then
		local port = tonumber(args)

		if not port or port > 65535 or port < 0 then
			return help("help port")
		end

		c_config_set("server.port", port)

		s_printnl("port: new port '", tostring(port), "' will be used on next restart")
	else
		return help("help port")
	end
end

-- no auto completion for port

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
		"port",
		port,
		portT,
		"Usage:\n" ..
		" port [port]\n" ..
		"\n" ..
		" Sets the port to be used on restart"
	},
}
