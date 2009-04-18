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
	require "tankbobs"
	tankbobs.t_initialize(client and not server);

	c_const_init()

	c_data_init()

	-- remove debug if debugging isn't enabled for security reasons
	if not c_const_get("debug") then
		debug = nil
	end

	c_module_init()
c_module_load("profiler")
profiler.start()

	c_config_init()

	c_mods_init()
	b_mods()  -- anything below this is moddable

	c_math_init()

	c_state_init()

	c_tcm_init()

	c_world_init()
end

function common_done()
	c_world_done()

	c_tcm_done()

	c_state_done()

	c_math_init()

	c_mods_done()

	c_config_done()

profiler.start()
	c_module_done()

	c_data_done()

	c_const_done()

	tankbobs.t_quit()
end

function common_print(...)
	print(...)
end

function common_endsIn(str, match)
	if not (type(str) == "string" and type(match) == "string") then
		common_error("common_endsIn: invalid arguments passed: ", str, match)
	end

	return match == "" or str:sub(-match:len()) == match
end

function common_clone(i, o)
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
				if c_const_get("debug") and type(v) == "userdata" then
					common_print("Warning: cloning table containing a member of the userdata type")
				end

				o[k] = v
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
					if c_const_get("debug") and type(v) == "userdata" then
						common_print("Warning: cloning table containing a member of the userdata type")
					end

					o[k] = v
				end
			end
		end

		return o
	end

	clone_level(i, o, e, "")
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
			t[w] = v
			return t[w]
		end
	end
end

-- for classes and inheritance
function common_new(self, o)
	o = o or {}
	common_clone(self, o)
	if self.init then
		self.init(o)
	end
	setmetatable(o, {__index = self})
	self.__index = self
	return o
end
