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
c_mods.lua

includes common functions for mod use or that would otherwise not be available to mods.
traverses mod directory for function redefinitions.
It is up to the server and client to call
--]]

function c_mods_init()
	c_mods_env = {}
	c_mods_data = {}  -- general-purpose table for mods to use
end

function c_mods_done()
end

function common_clone_except_special(i, o, e)
	local cloned_tables = {}

	o = o or {}

	local function clone_level(i, o, e, s)
		table.insert(cloned_tables, o)
		table.insert(cloned_tables, i)

		for k, v in pairs(i) do
			local recursed = false
			local continue = false

			if s:len() > 0 then
				s = s .. "."
			end

			for _, v2 in pairs(e) do
				if string.match(s .. k, v2) then
					continue = true
					break
				end
			end

			if not continue then
				if type(v) == "table" then
					for _, v2 in pairs(cloned_tables) do
						if v == v2 or o[k] == v2 then
							recursed = true
							break
						end
					end

					if not recursed then
						if type(o[k]) ~= "table" then
							o[k] = {}
						end
						clone_level(v, o[k], e, s .. k)
					end
				--+++++++++++++++++++++++++++++++++++++++++++++++--
				--elseif type(v) == "function" then  -- handle functions specially
				elseif false then  -- TODO: FIXME: this is broken; mods aren't safe until this is fixed!
					local do_f = v

					o[k] = function (...)
						local unsafe = c_config_get("config.mods.unsafe")

						if unsafe and not c_const_get("debug") then
							error "Debugging is disabled.  Not running in unsafe mode."
						end

						if unsafe then
							common_clone(_G, c_mods_env)
						else
							common_clone_except(_G, c_mods_env, c_const_get("hidden_globals"))
							c_mods_env._G = false
						end
						setfenv(do_f, c_mods_env)

						local result = {do_f(...)}

						if unsafe then
							common_clone(c_mods_env, _G)
						else
							--common_clone_except(c_mods_env, G_t, c_const_get("protected_globals"))
							-- use a special version of clone so that redefined functions (protected globals can be accessed but not redefined) don't have access to hidden globals

							common_clone_except_special(c_mods_env, _G, c_const_get("protected_globals"))
						end

						return unpack(result)
					end
				--+++++++++++++++++++++++++++++++++++++++++++++++--
				else
					o[k] = v
				end
			end
		end

		return o
	end

	clone_level(i, o, e, "")
end

function c_mods_load(dir)
	require "lfs"

	local unsafe = c_config_get("config.mods.unsafe")
	local mods = {}

	if not dir or dir == "" then
		error "Invalid mod directory."
	end

	for filename in lfs.dir(dir) do
		if not filename:find("^%.") and common_endsIn(filename, ".lua") then
			table.insert(mods, {dir .. filename, loadfile(dir .. filename)})
		end
	end

	if unsafe and not c_const_get("debug") then
		error "Debugging is disabled.  Not running in unsafe mode."
	end

	if unsafe then
		common_clone(_G, c_mods_env)
	else
		common_clone_except(_G, c_mods_env, c_const_get("hidden_globals"))
		c_mods_env._G = false
	end

	for _, v in pairs(mods) do
		if c_const_get("debug") then
			common_print("Running mod: " .. v[1])
		end

		setfenv(v[2], c_mods_env)
		local status, err = pcall(v[2])

		if not status then
			print("Error running mod '" .. v .. "': " .. err)
		end
	end

	if unsafe then
		common_clone(c_mods_env, _G)
	else
		--common_clone_except(c_mods_env, G_t, c_const_get("protected_globals"))
		-- use a special version of clone so that redefined functions (protected globals can be accessed but not redefined) don't have access to hidden globals
		common_clone_except_special(c_mods_env, _G, c_const_get("protected_globals"))
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
