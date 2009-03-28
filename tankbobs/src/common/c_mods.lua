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
mods.lua

includes common functions for mod use or that would otherwise not be available to mods.
traverses mod directory for function redefinitions.
It is up to the server and client to call
--]]

function c_mods_init()
end

function c_mods_done()
end

function c_mods_load(dir)
	require "lfs"

	if not dir or dir == "" then
		c_error "Invalid mod directory."
	end

	mods_data = {}  -- defines, values, other uses, etc; for mods

	for filename in lfs.dir(dir) do
		if not filename:find("^%.") and common_endsIn(filename, ".lua") then
			common_print("Running mod: " .. filename)
			dofile(dir .. filename)
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
