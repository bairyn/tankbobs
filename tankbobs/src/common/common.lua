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
common.lua

common lua functions
--]]

function common_nil(...)
	return ...
end

function common_init()
	if jit then
		require "jit.opt".start()
		require "jit.opt_inline".start()
	end

	require "libmtankbobs"
	tankbobs.t_initialize("common_interrupt", client and not server)

	c_const_init()

	c_data_init()

	-- remove debug if debugging isn't enabled for security reasons
	if not c_const_get("debug") then
		debug = nil
	end

	if c_const_get("debug") then
		if jit then
			print("JIT enabled")
		else
			print("JIT disabled")
		end
	end

	c_module_init()

	c_config_init()

	c_mods_init()
	b_mods()  -- anything below this is moddable

	c_math_init()

	c_state_init()

	c_weapon_init()

	c_tcm_init()

	c_world_init()

	c_mods_start()
end

function common_done()
	c_mods_finish()

	c_world_done()

	c_tcm_done()

	c_weapon_done()

	c_state_done()

	c_math_init()

	c_mods_done()

	c_config_done()

	c_module_done()

	c_data_done()

	c_const_done()

	tankbobs.t_quit()
end

SPECIAL = {}

function common_interrupt()
	--common_done()

	done = true  -- cleanly exit
end

function common_print(...)
	print(...)
end

function common_error(...)
	error(table.concat({...}))
end

function common_endsIn(str, match)
	if not (type(str) == "string" and type(match) == "string") then
		common_error("common_endsIn: invalid arguments passed: ", str, match)
	end

	return match == "" or str:sub(-match:len()) == match
end

-- NOTE: This function is very slow and creates much garbage.  Use the C implementation of tankbobs.t_clone instead

-- traverse i into o
-- if the output table exists, any values that are not overwritten from the input table will remain unchanged
function common_clone(c, i, o)
	local copyVectors = false

	if not o then
		o = i
		i = c
	else
		copyVectors = c
	end

	local cloned_tables = {}

	o = o or {}

	local function clone_level(i, o)
		table.insert(cloned_tables, o)
		table.insert(cloned_tables, i)

		for k, v in pairs(i) do
			local recursed = false

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
					clone_level(v, o[k])
				end
			else
				if copyVectors and type(v) == "userdata" and v.vec2 then
					local vec = c_math_vec2:new()

					vec.x = v.x
					vec.y = v.y
					--vec.R = vec.R
					--vec.t = vec.t
				else
					o[k] = v
				end
			end
		end

		return o
	end

	clone_level(i, o)
end

function common_clone_except(i, o, e)
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
				else
					o[k] = v
				end
			end
		end

		return o
	end

	clone_level(i, o, e, "")
end

--[[--
-- * common_tConcat
-- *
-- * concats some tables
-- * common_tConcat only traverses through one level
--]]--
function common_tConcat(t1, t2)
	local r = {}

	for k, v in pairs(t1) do
		if type(v) == "table" and debug then
			common_print("Warning: common_tConcat: copying a reference to a table")
		end

		table.insert(r, v)
	end

	for k, v in pairs(t2) do
		if type(v) == "table" and debug then
			common_print("Warning: common_tConcat: copying a reference to a table")
		end

		table.insert(r, v)
	end

	return r
end

function common_empty(t)
	return next(t) == nil
end

function common_getField(f, e)
	local v = e or _G

	for k in string.gmatch(f, "[%w_]+") do
		v = v[w]
	end

	return v
end

function common_setField(f, v, e)
	local t = e or _G

	for w, d in sting.gmatch(f, "([%w_]+)(.?)") do
		if d == "." then
			if type(t[w]) ~= "table" then
				t[w] = {}
			end
			t = t[w]
		else
		end
	end
end

-- for classes and inheritance
function common_new(self, inh, o)
	o = o or {}
	if inh then
		tankbobs.t_clone(inh, o)
	end
	tankbobs.t_clone(self, o)
	if self.init then
		self.init(o)
	end
	setmetatable(o, {__index = self})
	self.__index = self
	return o
end

function common_fileExists(filename)
	local f, err = io.open(filename, "r")

	if f then
		io.close(f)

		return true
	else
		return false, err
	end
end

function common_fileMustExist(filename)
	local f, err = io.open(filename, "r")

	if f then
		io.close(f)
	else
		error("common_FileMustExist: file '" .. tostring(filename) .. "' could not be opened for reading")
	end
end

-- FPS to MS
function common_FTM(fps)
	return 1000 / fps
end

-- MS to FPS
function common_MTF(ms)
	return 1000 / ms
end

function common_lerp(from, to, value)
	return from - (value * (from - to))
end
