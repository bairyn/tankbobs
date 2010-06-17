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
c_mods.lua

Mods
--]]

function c_mods_init()
end

function c_mods_done()
end

function c_mods_load(dir)
	local mods = {}

	for _, v in pairs(tankbobs.fs_listFiles(dir)) do
		if common_endsIn(v, ".lua") then
			table.insert(mods, {dir .. v, loadfile(dir .. v)})
		end
	end

	for _, v in pairs(mods) do
		if c_const_get("debug") then
			common_print(-1, "Running mod: " .. v[1] .. "\n")
		end

		local status, err = pcall(v[2])

		if not status then
			print("Error loading mod '" .. v[1] .. "': " .. err)
		end
	end

	c_mods_data_load()
	c_mods_body()
end

function c_mods_data_load()  -- redefine some constants
end

function c_mods_body()
end

function c_mods_argParse(arg, args, index)  -- parses an arg - arg is the single arg, args is the array of args, and index
												-- is the index in the args array.  returns nil  for nothing to  do, a number
												-- specifying the  next index of args to  be parsed,  or another type to stop
												-- parsing and terminate.  This function is called _after_ previous args are
												-- called.  After the client/server parses arguments, this is called, and the
												-- arguments should not be modified
	return nil
end

function c_mods_preArgParse(arg, args, index)  -- same as above, but instead
													-- this function is (or should be) called
													-- _before_ the main server/client
													-- "module" parses the arguments
													-- note that this function is good
													-- for bypassing what would otherwise
													-- cause the client/server module
													-- to terminate (eg -h).  To do so,
													-- simply remove the arguments from
													-- the argument table
	return nil
end

function c_mods_start()  -- This is called after everything is initialized.  This can be useful for resetting constant data.
end

function c_mods_finish()  -- This function is called before the cleanup code is called.
end


local functions = {}

-- c_mods_appendFunction appends f to a function by the name of 'name'.  The function must have global scope.  The results of the base function are dropped.
function c_mods_appendFunction(name, f)
	local base = _G[name]

	local exists = false
	for _, v in pairs(functions) do
		if v[1] == name then
			exists = true
		end
	end
	if not exists then
		table.insert(functions, {name, _G[name]})
	end

	_G[name] = function (...)
		base(...)
		return f(...)
	end
end

-- c_mods_appendFunction prepends f to a function by the name of 'name'.  The function must have global scope.  The results of the prepended function are dropped.
-- This function can return three arguments.  If the first is false (not nil!) then the second part of the function is not called.  If the second argument is a table, the base function will be called with those arguments contained in the table.  If the third argument is a table, the contents of it are returned.
function c_mods_prependFunction(name, f)
	local base = _G[name]

	local exists = false
	for _, v in pairs(functions) do
		if v[1] == name then
			exists = true
		end
	end
	if not exists then
		table.insert(functions, {name, _G[name]})
	end

	_G[name] = function (...)
		local call, args, ret = f(...)

		if call ~= false then
			if type(args) == "table" then
				if type(ret) == "table" then
					base(unpack(args))
					return unpack(ret)
				else
					return base(unpack(args))
				end
			else
				if type(ret) == "table" then
					base(...)
					return unpack(ret)
				else
					return base(...)
				end
			end
		else
			if type(ret) == "table" then
				return unpack(ret)
			else
				return
			end
		end
	end
end

function c_mods_replaceFunction(name, f)
	local base = _G[name]

	local exists = false
	for _, v in pairs(functions) do
		if v[1] == name then
			exists = true
		end
	end
	if not exists then
		table.insert(functions, {name, _G[name]})
	end

	_G[name] = f
end

-- restore a single function
function c_mods_restoreFunction(name)
	for _, v in pairs(functions) do
		if v[1] == name then
			_G[v[1]] = v[2]
		end
	end
end

-- restore all functions
function c_mods_restoreFunctions()
	for _, v in pairs(functions) do
		_G[v[1]] = v[2]
	end

	functions = {}
end

-- this function appends f to freeWorld.  This is useful to set an exit function for level scripts.
function c_mods_exitWorldFunction(f)
	c_mods_appendFunction("c_world_freeWorld", f)
end
