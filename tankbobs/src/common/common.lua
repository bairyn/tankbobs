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
common.lua

Common functions
--]]

version = {0,1,0 ,"-dev"}

-- All code should use the PhysicsFS interface
path = package.path
cpath = package.cpath
stdout = io.stdout
stderr = io.stderr
io = nil

require "libmtankbobs"
tankbobs.t_initialize("common_interrupt", false)

-- initial seed
math.randomseed(os.time())

function common_init()
	package.path = package.path
	package.cpath = package.cpath

	c_const_init()

	c_data_init()

	-- remove debug if debugging isn't enabled for security reasons
	if not c_const_get("debug") then
		debug = nil
	else
		debug = require "debug"
	end

	if c_const_get("debug") then
		if jit then
			common_print(-1, "JIT enabled\n")
		else
			common_print(-1, "JIT disabled\n")
		end
	end

	c_module_init()

	c_files_init()

	-- the filesystem is initialized, so now we can start optimizing
	if jit then
		require "jit.opt".start()
		require "jit.opt_inline".start()
	end


	c_config_init()

	-- load the bit module
	local bit = c_module_load "bit"

	-- contents
	NULL           = bit.tobit(NULL)
	WALL           = bit.tobit(WALL)
	POWERUP        = bit.tobit(POWERUP)
	TANK           = bit.tobit(TANK)
	PROJECTILE     = bit.tobit(PROJECTILE)
	CORPSE         = bit.tobit(CORPSE)

	-- input state bitmasks
	FIRING         = bit.tobit(FIRING)
	FORWARD        = bit.tobit(FORWARD)
	BACK           = bit.tobit(BACK)
	LEFT           = bit.tobit(LEFT)
	RIGHT          = bit.tobit(RIGHT)
	SPECIAL        = bit.tobit(SPECIAL)
	RELOAD         = bit.tobit(RELOAD)
	REVERSE        = bit.tobit(REVERSE)
	SLOW           = bit.tobit(SLOW)
	MOD            = bit.tobit(MOD)

	c_mods_init()
	b_mods()  -- anything below this is moddable

	c_class_init()

	c_math_init()

	c_state_init()

	c_tcm_init()

	c_world_init()

	c_weapon_init()

	c_ai_init()

	common_misc_start()

	c_mods_start()
end

function common_done()
	c_mods_finish()

	common_misc_finish()

	c_ai_done()

	c_world_done()

	c_tcm_done()

	c_weapon_done()

	c_state_done()

	c_math_init()

	c_class_done()

	c_mods_done()

	c_config_done()

	c_files_done()

	c_module_done()

	c_data_done()

	c_const_done()

	tankbobs.t_quit()
end

function common_misc_start()
	if tankbobs.t_n() then
		tankbobs.n_setQueueTime(c_config_get("common.online.packetDelay"))
	end
end

function common_misc_finish()
end

function common_nil(...)
	return ...
end

function common_cmpVersions(a, b)
	-- returns a positive number when 'a' > 'b', a negative number when 'a' < 'b', and zero when 'a' = 'b'
	for i = 1, math.max(#a, #b) do
		local na = a[i]
		local nb = b[i]

		if type(na) ~= nb or type(na) ~= "number" then
			return 0
		elseif na > nb then
			return 1
		elseif na < nb then
			return -1
		end
	end

	return 0
end

function common_versionString(v)
	local string = ""

	for i = 1, #v do
		local n = v[i]

		if type(n) ~= "number" then
			string = string .. tostring(n)

			break
		end

		if #string > 0 then
			string = string .. "."
		end
		string = string .. tostring(n)
	end

	return string
end

function common_interrupt()
	--common_done()

	done = true  -- cleanly exit
end

function common_listFiles(dir, extension)
	require "lfs"

	local files = {}

	extension = extension or ".tpk"

	for filename in lfs.dir(dir) do
		if not filename:find("^%.") and common_endsIn(filename, extension) then
			table.insert(files, filename)
		end
	end

	return files
end

function common_isDirectory(filename)
	local attributes = lfs.attributes(filename, "mode")

	if attributes and attributes[mode] then
		return attributes[mode] == "directory"
	end

	return false

	--[[
	if tankbobs.t_isWindows() then
		-- TODO: windows method
	else
		require "posix"

		local p = posix.stat(filename)

		return p and p.type == "directory"
	end
	--]]
end

function common_deepClone(object)
	-- http://lua-users.org/wiki/CopyTable

	local lookup_table = {}
	local function copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for k, v in pairs(object) do
			new_table[copy(k)] = copy(v)
		end
		return setmetatable(new_table, getmetatable(object))
	end

	return copy(object)
end

function common_print(level, ...)
	if level < 0 then
		-- negative verbosity levels have the special meaning that it is possible that not everything has initialized, so print to standard output
		stdout:write(...)
	else
		-- ignore verbosity level for now; TODO: <-

		if client and not server then
			stdout:write(...)
		elseif not client and server then
			s_printnl(...)
		end
	end
end

STOP = -1337666

function common_printError(level, ...)
	if level == STOP then
		error(...)
	elseif level < 0 then
		-- negative verbosity levels have the special meaning that it is possible that not everything has initialized, so print to stderr
		stderr:write("(EE) ", ...)
	else
		-- ignore verbosity level for now; TODO: <-

		if client and not server then
			stderr:write("(EE) ", ...)
		elseif not client and server then
			s_printnl("(EE) ", ...)
		end
	end
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
		if debug and type(v) == "table" then
			common_printError(0, "Warning: common_tConcat: copying a reference to a table")
		end

		table.insert(r, v)
	end

	for k, v in pairs(t2) do
		if debug and type(v) == "table" then
			common_printError(0, "Warning: common_tConcat: copying a reference to a table")
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
		error("common_fileMustExist: file '" .. tostring(filename) .. "' could not be opened for reading")
	end
end

do
local hex = "0123456789ABCEF"
function common_tohex(number)
	local result = ""

	while number > 0 do
		local mod = math.fmod(number, #hex)
		result = hex:sub(mod + 1, mod + 1) .. result
		number = math.floor(number / #hex)
	end

	if result == "" then
		result = "0"
	end

	return result
end
end
local common_tohex = common_tohex

-- returns a hex string
function common_stringToHex(separator, prefix, str)
	local result = ""

	for i = 1, #str do
		if i ~= 1 then
			result = result .. separator
		end

		result = result .. prefix

		local char = string.byte(str, i)
		result = result .. common_tohex(char)
	end

	return result
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

-- escapes Lua string formats
function common_escape(string)
	local goodString = ""

	for i = 1, #string do
		local char = string:sub(i, i)

		if char == '^' or char == '.' or char == '$' or char == '(' or char == ')' or char == '%' or char == '[' or char == ']' or char == '*' then
			goodString = goodString .. "%" .. char
		else
			goodString = goodString .. char
		end
	end

	return goodString
end

function common_commonStartString(strings)
	local result = ""

	if #strings < 1 then
		return nil
	end

	for i = 1, #strings[1] do
		local test = result .. strings[1]:sub(i, i)

		for _, v in pairs(strings) do
			if not v:find("^" .. common_escape(test)) then
				return result
			end
		end

		result = test
	end

	return result
end

---[[ constants ]]---

SPECIAL        = {}

CIRCLE         = 2 * math.pi

-- gametypes
DEATHMATCH     = {}
TEAMDEATHMATCH = {}
SURVIVOR       = {}
TEAMSURVIVOR   = {}
MEGATANK       = {}
CHASE          = {}
PLAGUE         = {}
DOMINATION     = {}
CAPTURETHEFLAG = {}

-- bitmasks --

-- contents
NULL           = 0x0001
WALL           = 0x0002
POWERUP        = 0x0004
TANK           = 0x0008
PROJECTILE     = 0x0010
CORPSE         = 0x0020

-- input state bitmasks
FIRING         = 0x0001
FORWARD        = 0x0002
BACK           = 0x0004
LEFT           = 0x0008
RIGHT          = 0x0010
SPECIAL        = 0x0020
RELOAD         = 0x0040
REVERSE        = 0x0080
SLOW           = 0x0100
MOD            = 0x0200
