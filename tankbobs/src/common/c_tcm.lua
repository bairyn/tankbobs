--this needs to be completely rewritten

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
c_tcm.lua

map loading and reading.  The TankCompiledMap (compiled from trm(TankRawMap))
format is simple:

1st byte is 0x00
2nd byte is 0x54 -]
3rd byte is 0x43  | - TCM
4th byte is 0x4D -]
5th byte is 0x01
6th-10th is Sint32 magic number
11th byte is Uint8 (char) version
--
4 bytes map version sint
512 bytes authors
256 bytes map version
4 bytes map version (for compatibility issues in the future)
4 bytes number of walls
4 bytes number of teleporters
4 bytes number of playerSpawnPoints
4 bytes number of powerupSpawnPoints
walls, ...
 -8 bytes x1 double float
 -8 bytes y1 double float
 -8 bytes x2 double float
 -8 bytes y2 double float
 -8 bytes x3 double float
 -8 bytes y3 double float
 -8 bytes x4 double float
 -8 bytes y4 double float
 -1 byte: if non-zero, the 4th coordinates are used
 -256 bytes texture
 -4 bytes level of wall (tanks are level 9)
 - 325 total bytes, this amount for each wall
teleporters, ...
 -8 bytes x1 double float
 -8 bytes y1 double float
playerSpawnPoints
 -8 bytes x1 double float
 -8 bytes y1 double float
powerupSpawnPoints
 -8 bytes x1 double float
 -8 bytes y1 double float
--]]

function c_tcm_init()
	c_const_set("tcm_dir", c_const_get("data_dir") .. "tcm/")
	local magic = 0xDEADBEEF
	c_const_set("tcm_magic", magic)
	c_const_set("tcm_version", 1)
	c_const_set("tcm_headerLength", 11)
	c_const_set("tcm_eof", "EOF !#\\")

	c_const_set("tcm_teleporterWidth",  5, 1)
	c_const_set("tcm_teleporterHeight", 5, 1)
	c_const_set("tcm_powerspawnWidth",  5, 1)
	c_const_set("tcm_powerspawnHeight", 5, 1)
	c_const_set("tcm_spawnpointWidth",  5, 1)
	c_const_set("tcm_spawnpointHeight", 5, 1)

	c_tcm_map =
	{
		nil
	}

	c_tcm_set =
	{
		nil
	}

	c_tcm_sets =
	{
		nil
	}
end

function c_tcm_done()
end

local function c_tcm_private_base_base(t, i)
	while true do
		local c = tankbobs.io_getChar(t[1])
		if c == c_const_get("tcm_eof") then
			return nil
		elseif c == t[2] then
			return i
		elseif c == 0x00 then
		elseif c == 0x01 then
			t[1]:seek("cur", 4)
			for _ = 1, 7 do
				c = tankbobs.io_getInt(t[1])
				if c == 0 then
					while true do
						c = tankbobs.io_getChar(t[1])
						if c == 0 then
							break
						end
						if c == c_const_get("tcm_eof") then
							error("parsing map ended early")
						end
					end
				elseif type(c) == "number" and c > 0 then
					t[1]:seek("cur", c)
				else
					error("parsing map ended early")
				end
			end
		elseif c == 0x02 then
			t[1]:seek("cur", 8)
			for _ = 1, 5 do
				c = tankbobs.io_getInt(t[1])
				if c == 0 then
					while true do
						c = tankbobs.io_getChar(t[1])
						if c == 0 then
							break
						end
						if c == c_const_get("tcm_eof") then
							error("parsing map ended early")
						end
					end
				elseif type(c) == "number" and c > 0 then
					t[1]:seek("cur", c)
				else
					error("parsing map ended early")
				end
			end
		elseif c == 0x03 then
			for _ = 1, 5 do
				c = tankbobs.io_getInt(t[1])
				if c == 0 then
					while true do
						c = tankbobs.io_getChar(t[1])
						if c == 0 then
							break
						end
						if c == c_const_get("tcm_eof") then
							error("parsing map ended early")
						end
					end
				elseif type(c) == "number" and c > 0 then
					t[1]:seek("cur", c)
				else
					error("parsing map ended early")
				end
			end
			t[1]:seek("cur", 58)
		elseif c == 0x04 then
		elseif c == 0x05 then
			c = tankbobs.io_getInt(t[1])
			if c == 0 then
				while true do
					c = tankbobs.io_getChar(t[1])
					if c == 0 then
						break
					end
					if c == c_const_get("tcm_eof") then
						error("parsing map ended early")
					end
				end
			elseif type(c) == "number" and c > 0 then
				t[1]:seek("cur", c)
			else
				error("parsing map ended early")
			end
			t[1]:seek("cur", 20)
		elseif c == 0x06 then
			t[1]:seek("cur", 16)
		end
	end
end

local function c_tcm_private_base(f, b)
	return c_tcm_private_base_base, {f, b}, 0
end

local function c_tcm_private_skipbase(f, s)
	f:seek("cur", -s)
	local c = tankbobs.io_getChar(t[1])
	if c == c_const_get("tcm_eof") then
		return nil
	elseif c == t[2] then
		return i
	elseif c == 0x00 then
	elseif c == 0x01 then
		t[1]:seek("cur", 4)
		for _ = 1, 7 do
			c = tankbobs.io_getInt(t[1])
			if c == 0 then
				while true do
					c = tankbobs.io_getChar(t[1])
					if c == 0 then
						break
					end
					if c == c_const_get("tcm_eof") then
						error("parsing map ended early")
					end
				end
			elseif type(c) == "number" and c > 0 then
				t[1]:seek("cur", c)
			else
				error("parsing map ended early")
			end
		end
	elseif c == 0x02 then
		t[1]:seek("cur", 8)
		for _ = 1, 5 do
			c = tankbobs.io_getInt(t[1])
			if c == 0 then
				while true do
					c = tankbobs.io_getChar(t[1])
					if c == 0 then
						break
					end
					if c == c_const_get("tcm_eof") then
						error("parsing map ended early")
					end
				end
			elseif type(c) == "number" and c > 0 then
				t[1]:seek("cur", c)
			else
				error("parsing map ended early")
			end
		end
	elseif c == 0x03 then
		for _ = 1, 5 do
			c = tankbobs.io_getInt(t[1])
			if c == 0 then
				while true do
					c = tankbobs.io_getChar(t[1])
					if c == 0 then
						break
					end
					if c == c_const_get("tcm_eof") then
						error("parsing map ended early")
					end
				end
			elseif type(c) == "number" and c > 0 then
				t[1]:seek("cur", c)
			else
				error("parsing map ended early")
			end
		end
		t[1]:seek("cur", 58)
	elseif c == 0x04 then
	elseif c == 0x05 then
		c = tankbobs.io_getInt(t[1])
		if c == 0 then
			while true do
				c = tankbobs.io_getChar(t[1])
				if c == 0 then
					break
				end
				if c == c_const_get("tcm_eof") then
					error("parsing map ended early")
				end
			end
		elseif type(c) == "number" and c > 0 then
			t[1]:seek("cur", c)
		else
			error("parsing map ended early")
		end
		t[1]:seek("cur", 20)
	elseif c == 0x06 then
		t[1]:seek("cur", 16)
	end
end

local function c_tcm_private_getstr(f)
	local c = tankbobs.io_getInt(f)
	if c == 0 then
		return tankbobs.io_getStr(f)
	elseif c > 0 then
		return tankbobs.io_getStrL(f, c)
	else
		error("error parsing map: preterminated byte sequence")
	end
end

local function c_tcm_private_header(f, filename)
	if not f then
		error("cannot read " .. filename)
	end
	if tankbobs.io_getChar(f) ~= 0x00 then
		error("map " .. filename .. " is not a valid c_tcm file")
	elseif tankbobs.io_getChar(f) ~= 0x54 then
		error("map " .. filename .. " is not a valid c_tcm file")
	elseif tankbobs.io_getChar(f) ~= 0x43 then
		error("map " .. filename .. " is not a valid c_tcm file")
	elseif tankbobs.io_getChar(f) ~= 0x4D then
		error("map " .. filename .. " is not a valid c_tcm file")
	elseif tankbobs.io_getChar(f) ~= 0x01 then
		error("map " .. filename .. " is not a valid c_tcm file")
	elseif string.format("%X", tankbobs.io_getInt(f))  ~= string.format("%X", c_const_get("tcm_magic")) then
		error("map " .. filename .. " is not a valid c_tcm file")
	elseif tankbobs.io_getChar(f) ~= c_const_get("tcm_version") then
		f:seek("cur", -4)
		print("map " .. filename .. " is compatible with tankbobs version " .. tostring(tankbobs.io_getChar(f)) .. ", you are using version " .. tostring(c_const_get("version")) .. "; you probably won't get what you were expecting!  Expect a crash.  Continuing anyway...")
	end
end

local function c_tcm_private_psets(filename)
	local id, order, name, title, description, authors, version
	local f = io.open(filename, "r")
	c_tcm_private_header(f, filename)
	local first, c = false
	for _ in c_tcm_private_base(f, 0x02) do
		id = tankbobs.io_getInt(f)
		order = tankbobs.io_getInt(f)
		name = c_tcm_private_getstr(f)
		title = c_tcm_private_getstr(f)
		description = c_tcm_private_getstr(f)
		authors = c_tcm_private_getstr(f)
		version = c_tcm_private_getstr(f)
		if id == c_const_get("tcm_eof") or title == c_const_get("tcm_eof") or name == c_const_get("tcm_eof") or description == c_const_get("tcm_eof") or authors == c_const_get("tcm_eof") or version == c_const_get("tcm_eof") or id == nil or title == nil or name == nil or description == nil or authors == nil or version == nil then
			error("tcm " .. filename .. " has an incomplete set description")
		elseif order == 1 then
			local set = {id, order, name, title, description, authors, version}
			table.insert(c_tcm_sets, set)
		end
		return
	end
end

local function c_tcm_private_plevels(filename, id)
	local sid, lid, order
	local f = io.open(filename, "r")
	c_tcm_private_header(f, filename)
	local first, c = false
	for _ in c_tcm_private_base(f, 0x02) do
		sid = tankbobs.io_getInt(f)
		order = tankbobs.io_getInt(f)
		local c = c_tcm_private_getstr(f)
		if c == nil or c == c_const_get("tcm_eof")== c_const_get("tcm_eof") or sid == nil or sid == c_const_get("tcm_eof") or order == nil or order == c_const_get("tcm_eof") then
			error("tcm " .. filename .. " has an incomplete set description")
		end
		c = c_tcm_private_getstr(f)
		if c == nil or c == c_const_get("tcm_eof") then
			error("tcm " .. filename .. " has an incomplete set description")
		end
		c = c_tcm_private_getstr(f)
		if c == nil or c == -1 then
			error("tcm " .. filename .. " has an incomplete set description")
		end
		c = c_tcm_private_getstr(f)
		if c == nil or c == c_const_get("tcm_eof") then
			error("tcm " .. filename .. " has an incomplete set description")
		end
		c = c_tcm_private_getstr(f)
		if c == nil or c == c_const_get("tcm_eof") then
			error("tcm " .. filename .. " has an incomplete set description")
		end
		if sid == id then
			f:seek("set", c_const_get("tcm_headerLength") - 1)
			local id, name, title, description, authors, version, initscript, exitscript
			for _ in c_tcm_private_base(f, 0x01) do
				id = tankbobs.io_getInt(f)
				name = c_tcm_private_getstr(f)
				title = c_tcm_private_getstr(f)
				description = c_tcm_private_getstr(f)
				authors = c_tcm_private_getstr(f)
				version = c_tcm_private_getstr(f)
				initscript = c_tcm_private_getstr(f)
				exitscript = c_tcm_private_getstr(f)
				break
			end
			if id == nil or name == nil or title == nil or description == nil or authors == nil or version == nil or initscript == nil or exitscript == nil or id == c_const_get("tcm_eof") or name == c_const_get("tcm_eof") or title == c_const_get("tcm_eof") or description == c_const_get("tcm_eof") or authors == c_const_get("tcm_eof") or version == c_const_get("tcm_eof") or initscript == c_const_get("tcm_eof") or exitscript == c_const_get("tcm_eof") then
				error("c_tcm " .. filename .. " has an incomplete map description")
			end
			local level = {sid, id, name, title, descripition, authors, version, initscript, exitscript, filename, order}
			c_tcm_set[order] = level
			return
		else
			return
		end
	end
end

local function c_tcm_private_plevel(order)
	local filename = c_tcm_set[order][10]
	local f = io.open(filename, "r")
	c_tcm_private_header(f, filename)
	c_tcm_map.walls       = {}
	c_tcm_map.spawns      = {}
	c_tcm_map.powerspawns = {}
	c_tcm_map.initscript  = ((c_tcm_set[order][8] == "") and (nil) or (c_tcm_set[order][8]))
	c_tcm_map.exitscript  = ((c_tcm_set[order][9] == "") and (nil) or (c_tcm_set[order][9]))

	local texture
	local traits = {}
	local script1, script2, script3, x1, y1, x2, y2, x3, y3, x4, y4
	for _ in c_tcm_private_base(f, 0x03) do
		texture = c_tcm_private_getstr(f)
		local traitstr = c_tcm_private_getstr(f)
		if traitstr:find(string.format("%c", 0x01)) then
			traits.detail = true
		end
		if traitstr:find(string.format("%c", 0x02)) then
			traits.back_most = true
		elseif traitstr:find(string.format("%c", 0x03)) then
			traits.back = true
		elseif traitstr:find(string.format("%c", 0x04)) then
			traits.back_least = true
		elseif traitstr:find(string.format("%c", 0x05)) then
			traits.top_least = true
		elseif traitstr:find(string.format("%c", 0x06)) then
			traits.top = true
		elseif traitstr:find(string.format("%c", 0x07)) then
			traits.top_most = true
		elseif traitstr:find(string.format("%c", 0x0C)) then
			traits.back_mostmore = true
		elseif traitstr:find(string.format("%c", 0x0D)) then
			traits.back_mostmost = true
		end
		if traitstr:find(string.format("%c", 0x08)) then
			traits.touch = true
		end
		if traitstr:find(string.format("%c", 0x09)) then
			traits.damage = true
		end
		if traitstr:find(string.format("%c", 0x0A)) then
			traits.missiles = true
		end
		if traitstr:find(string.format("%c", 0x0B)) then
			traits.nopass = true
		end
		script1 = c_tcm_private_getstr(f)
		script2 = c_tcm_private_getstr(f)
		script3 = c_tcm_private_getstr(f)
		x1 = tankbobs.io_getDouble(f)
		y1 = tankbobs.io_getDouble(f)
		x2 = tankbobs.io_getDouble(f)
		y2 = tankbobs.io_getDouble(f)
		x3 = tankbobs.io_getDouble(f)
		y3 = tankbobs.io_getDouble(f)
		x4 = tankbobs.io_getDouble(f)
		y4 = tankbobs.io_getDouble(f)
		if x4 == c_const_get("tcm_eof") and y4 == c_const_get("tcm_eof") then
			x4, y4 = nil, nil
		end
		if texture == nil or traits == nil or script1 == nil or script2 == nil or script3 == nil or x1 == nil or y1 == nil or x2 == nil or y2 == nil or x3 == nil or y3 == nil or texture == c_const_get("tcm_eof") or traits == c_const_get("tcm_eof") or script1 == c_const_get("tcm_eof") or script2 == c_const_get("tcm_eof") or script3 == c_const_get("tcm_eof") or x1 == c_const_get("tcm_eof") or y1 == c_const_get("tcm_eof") or x2 == -2 or y2 == c_const_get("tcm_eof") or x3 == c_const_get("tcm_eof") or y3 == c_const_get("tcm_eof") or x4 == c_const_get("tcm_eof") or y4 == c_const_get("tcm_eof") then
			error("tcm " .. filename .. " has an incomplete map description")
		end
		local wall = {texture, traits, script1, script2, script3, x1, y1, x2, y2, x3, y3, x4, y4}
		table.insert(c_tcm_map.walls, wall)
	end

	f:seek("set", c_const_get("tcm_headerLength") - 1)
	local x, y
	for _ in c_tcm_private_base(f, 0x06) do
		x = tankbobs.io_getDouble(f)
		y = tankbobs.io_getDouble(f)
		if x == nil or y == nil or x == c_const_get("tcm_eof") or y == c_const_get("tcm_eof") then
			error("tcm " .. filename .. " has an incomplete map description")
		end
		local spawn = {x, y}
		table.insert(c_tcm_map.spawns, spawn)
	end

	f:seek("set", c_const_get("tcm_headerLength") - 1)
	local powerups, enable
	for _ in c_tcm_private_base(f, 0x05) do
		powerups = c_tcm_private_getstr(f)
		enable = tankbobs.io_getInt(f)
		x = tankbobs.io_getDouble(f)
		y = tankbobs.io_getDouble(f)
		if powerups == nil or enable == nil or x == nil or y == nil or powerups == c_const_get("tcm_eof") or enable == c_const_get("tcm_eof") or x == c_const_get("tcm_eof") or y == c_const_get("tcm_eof") then
			error("tcm " .. filename .. " has an incomplete map description")
		end
		local powerspawn = {powerups, enable, x, y}
		table.insert(c_tcm_map.powerspawns, powerspawn)
	end
end

function c_tcm_headers()  -- c_tcm_sets
	if c_tcm_sets[1] ~= nil then
		return
	end
	for filename in lfs.dir(c_const_get("tcm_dir")) do
		if not filename:find("^%.") and filename:find("%.c_tcm$") then
			c_tcm_private_psets(c_const_get("tcm_dir") .. filename)
		end
	end
end

function c_tcm_levels(id)  -- c_tcm_set
	if c_tcm_set[1] ~= nil then
		c_tcm_set = nil
		c_tcm_set = {nil}
	end
	for filename in lfs.dir(c_const_get("tcm_dir")) do
		if not filename:find("^%.") and filename:find("%.c_tcm$") then
			c_tcm_private_plevels(c_const_get("tcm_dir") .. filename, id)
		end
	end
end

function c_tcm_level(order)  -- c_tcm_map
--	if c_tcm_map[1] ~= nil then
--		-- any freeing goes here
--	end
	c_tcm_map = nil
	c_tcm_map = {}
	c_tcm_private_plevel(order)
end

function c_tcm_setsi()
	local i = 0
	return function ()
		i = i + 1
		local j = 0
		for k, v in ipairs(c_tcm_sets) do
			if v ~= nil then
				j = j + 1
				if j == i then
					return v[1], v[2], v[3], v[4], v[5], v[6]
				end
			end
		end
		return nil
	end
end

function c_tcm_levelsi()
	local i = 0
	return function ()
		i = i + 1
		local j= 0
		for k, v in ipairs(c_tcm_set) do
			if v ~= nil then
				j = j + 1
				if j == i then
					return v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9], v[10], v[11]
				end
			end
		end
		return nil
	end
end
