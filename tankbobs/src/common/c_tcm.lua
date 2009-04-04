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

TankCompiledMap (compiled TankRawMap)
format:

1st byte is 0x00
2nd byte is 0x54 -]
3rd byte is 0x43  | - TCM
4th byte is 0x4D -]
5th byte is 0x01
6th-10th is Sint32 magic number
11th byte is Uint8 (char) version
--
4 bytes map version sint
64 bytes unique name
64 bytes title
64 bytes description
512 bytes authors
64 bytes map version
4 bytes map version (for compatibility issues in the future)
4 bytes number of walls
4 bytes number of teleporters
4 bytes number of playerSpawnPoints
4 bytes number of powerupSpawnPoints
walls, ...
 -4 bytes id (unique to every other entity's id too)
 -1 byte: if non-zero, the 4th coordinates are used
 -8 bytes x1 double float
 -8 bytes y1 double float
 -8 bytes x2 double float
 -8 bytes y2 double float
 -8 bytes x3 double float
 -8 bytes y3 double float
 -8 bytes x4 double float
 -8 bytes y4 double float
 -256 bytes texture
 -4 bytes level of wall (tanks are level 9)
 - 329 total bytes, this amount for each wall
teleporters, ...
 -4 bytes id
 -4 bytes target id
 -8 bytes x1 double float
 -8 bytes y1 double float
 - 24 total bytes
playerSpawnPoints
 -4 bytes id
 -8 bytes x1 double float
 -8 bytes y1 double float
 - 20 total bytes
powerupSpawnPoints
 -4 bytes id
 -8 bytes x1 double float
 -8 bytes y1 double float
 -4 bytes powerups to enable
 -4 bytes more powerups to enable
 -4 bytes more powerups to enable
 -4 bytes more powerups to enable
 -another 4 groups of powerups - altogether 64 bytes
 - 52 total bytes
--]]

function c_tcm_init()
	c_const_set("tcm_dir", c_const_get("data_dir") .. "tcm/")
	c_const_set("tcm_sets_dir", c_const_get("data_dir") .. "sets/")
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
	c_const_set("tcm_tankLevel", 9, 1)

	-- parse every set into memory
	c_tcm_current_sets = {}

	c_tcm_read_sets(c_const_get("tcm_sets_dir"), c_tcm_current_sets)
end

function c_tcm_done()
end

c_tcm_set =
{
	new = function (self, o)
		o = o or {}
		common_clone(self, o)
		if self.init then
			self.init(o)
		end
		setmetatable(o, {__index = self})
		self.__index = self
		return o
	end,

	maps = {},  -- table of maps.  All maps are loaded once
	name = "",  -- internal name.
	title = "",  -- the name the player will see.
	description = ""  -- the description
}

c_tcm_map =
{
	new = function (self, o)
		o = o or {}
		common_clone(self, o)
		if self.init then
			self.init(o)
		end
		setmetatable(o, {__index = self})
		self.__index = self
		return o
	end,

	map = "",  -- the filename

	version = 0,
	name = "",  -- unique name
	title = "",  -- the name the player will see
	description = "",  -- the description
	authors = "",
	version_string = "",

	walls_n = 0,
	teleporters_n = 0,
	playerSpawnPoints_n = 0,
	powerupSpawnPoints_n = 0,

	walls = {},  -- table of walls
	teleporters = {},  -- table of walls
	playerSpawnPoints = {},  -- table of walls
	powerupSpawnPoints = {},  -- table of walls
	message = ""  -- the level message
}

c_tcm_wall =
{
	new = function (self, o)
		o = o or {}
		common_clone(self, o)
		if self.init then
			self.init(o)
		end
		setmetatable(o, {__index = self})
		self.__index = self
		return o
	end,

	init = function (o)
		o.p[1] = c_vec2:new()
		o.p[2] = c_vec2:new()
		o.p[3] = c_vec2:new()
		--o.p[4] = c_vec2:new()
		o.l = c_const_get("tcm_tankLevel")
	end,

	id = 0,
	p = {},
	texture = "",
	l = 0,
	q = false  -- only for a quick way to see if the 4th point exists
}

c_tcm_teleporter =
{
	new = function (self, o)
		o = o or {}
		common_clone(self, o)
		if self.init then
			self.init(o)
		end
		setmetatable(o, {__index = self})
		self.__index = self
		return o
	end,

	init = function (o)
		o.p[1] = c_vec2:new()
	end,

	id = 0,
	t = 0,
	p = {}
}

c_tcm_playerSpawnPoint =
{
	new = function (self, o)
		o = o or {}
		common_clone(self, o)
		if self.init then
			self.init(o)
		end
		setmetatable(o, {__index = self})
		self.__index = self
		return o
	end,

	init = function (o)
		o.p[1] = c_vec2:new()
	end,

	id = 0,
	p = {}
}

c_tcm_powerupSpawnPoint =
{
	new = function (self, o)
		o = o or {}
		common_clone(self, o)
		if self.init then
			self.init(o)
		end
		setmetatable(o, {__index = self})
		self.__index = self
		return o
	end,

	init = function (o)
		o.p[1] = c_vec2:new()
		o.enabledPowerups.foo = false
	end,

	id = 0,
	p = {},
	enabledPowerups = {}
}

function c_tcm_read_sets(dir, t)
	require "lfs"

	if not dir or dir == "" then
		error "Invalid set directory."
	end

	mods_data = {}  -- defines, values, other uses, etc; for mods

	for filename in lfs.dir(dir) do
		if not filename:find("^%.") and filename:find("^set-") and common_endsIn(filename, ".txt") then
			c_tcm_read_set(dir .. filename, t)
		end
	end

	c_mods_data_load()
	c_mods_body()
end

function c_tcm_read_set(filename, t)
	local s = c_tcm_set:new()
	local set_f, err = io.open(filename, "r")
	local line

	if not set_f then
		error("Error opening '" .. filename .. "': " .. err)
	end

	-- read the set file line by line:
	-- The 1st line is the set's name
	line, err = set_f:read()
	if not line then
		error("Unexepected EOF when reading '" .. filename .. "': " .. err)
	end
	s.name = line

	-- The 2nd line is the set's title
	line, err = set_f:read()
	if not line then
		error("Unexepected EOF when reading '" .. filename .. "': " .. err)
	end
	s.title = line

	-- The 3rd line is the set's description
	line, err = set_f:read()
	if not line then
		error("Unexepected EOF when reading '" .. filename .. "': " .. err)
	end
	s.description = line

	-- read the set's filenames and read their headers
	line = set_f:read()
	while line and type(line) == "string" and line ~= "" do
		table.insert(s.maps, c_tcm_read_map(c_const_get("tcm_dir") .. line))

		line = set_f:read()
	end

	set_f:close()

	table.insert(t, s)
end

-- f: io function (e.g. tankbobs.io_getChar)
-- i: input file
-- t: if this argument is true, instead of giving an error, nil is returned
-- ...: extra arguments to pass (t can be false)
local function c_tcm_private_get(f, i, t, ...)
	local d = f(i, ...)

	if d == c_const_get("tcm_eof") then
		if t then
			return nil
		else
			error "EOF unexpected"
		end
	end
end

local function c_tcm_check_true_header(i)
	if c_tcm_private_get(tankbobs.io_getChar, i) ~= 0x00 then
		error "Invalid map header"
	elseif c_tcm_private_get(tankbobs.io_getChar, i) ~= 0x54 then
		error "Invalid map header"
	elseif c_tcm_private_get(tankbobs.io_getChar, i) ~= 0x43 then
		error "Invalid map header"
	elseif c_tcm_private_get(tankbobs.io_getChar, i) ~= 0x4D then
		error "Invalid map header"
	elseif c_tcm_private_get(tankbobs.io_getChar, i) ~= 0x01 then
		error "Invalid map header"
	elseif c_tcm_private_get(tankbobs.io_getInt, i) ~= string.format("%X", c_const_get("tcm_magic")) then
		error "Invalid map header"
	elseif c_tcm_private_get(tankbobs.io_getChar, i) ~= c_const_get("tcm_version") then
		i:seek("cur", -1)
		io.stdout:write("Warning: map was built for tcm version '", tostring(c_tcm_private_get(tankbobs.io_getChar, i)), "'; you are using version '", tostring(c_const_get("tcm_version")), "'")
	end
end

function c_tcm_read_map(map)
	local r = c_tcm_map:new()

	if c_const_get("debug") then
		io.stdout:write("Parsing header of file: ", map)
	end

	r.map = map

	local i, err, errnum = io.open(map, "r")

	if not i then
		error("Could not open '" .. map .. "': " .. err .. " - error number: " .. errnum .. ".")
	end
	
	c_tcm_check_true_header(i)

	r.version = c_tcm_private_get(tankbobs.io_getChar, i)
	r.name = c_tcm_private_get(tankbobs.io_getStr, i, false, 64)
	r.title = c_tcm_private_get(tankbobs.io_getStr, i, false, 64)
	r.description = c_tcm_private_get(tankbobs.io_getStr, i, false, 64)
	r.authors = c_tcm_private_get(tankbobs.io_getStr, i, false, 512)
	r.version_string = c_tcm_private_get(tankbobs.io_getStr, i, false, 64)
	-- strip trailing 0's from NULL-terminated strings passed by C
	r.name = r.name:gsub("%z*$", "")
	r.title = r.title:gsub("%z*$", "")
	r.description = r.description:gsub("%z*$", "")
	r.authors = r.authors:gsub("%z*$", "")
	r.version_string = r.version_string:gsub("%z*$", "")

	r.walls_n = c_tcm_private_get(tankbobs.io_getInt, i)
	r.teleporters_n = c_tcm_private_get(tankbobs.io_getInt, i)
	r.playerSpawnPoints_n = c_tcm_private_get(tankbobs.io_getInt, i)
	r.powerupSpawnPoints_n = c_tcm_private_get(tankbobs.io_getInt, i)

	for i = 1, r.walls_n do
		local wall = c_tcm_wall:new()

		wall.id = c_tcm_private_get(tankbobs.io_getInt, i)
		if c_tcm_private_get(tankbobs.io_getChar, i) ~= 0 then
			wall.q = true
		else
			wall.q = false
		end
		wall.p[1].x = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.p[1].y = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.p[2].x = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.p[2].y = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.p[3].x = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.p[3].y = c_tcm_private_get(tankbobs.io_getDouble, i)
		if wall.q then
			wall.p[4].x = c_tcm_private_get(tankbobs.io_getDouble, i)
			wall.p[4].y = c_tcm_private_get(tankbobs.io_getDouble, i)
		else
			i:seek("cur", 16)
		end
		wall.texture = c_tcm_private_get(tankbobs.io_getStr, i, false, 256)
		wall.texture = wall.texture:gsub("%z*$", "")
		wall.l = c_tcm_private_get(tankbobs.io_getInt, i)

		table.insert(r.walls, wall)
	end

	for it = 1, r.teleporters_n do
		local teleporter = c_tcm_teleporter:new()

		teleporter.id = c_tcm_private_get(tankbobs.io_getInt, i)
		teleporter.t = c_tcm_private_get(tankbobs.io_getInt, i)
		teleporter.p[1].x = c_tcm_private_get(tankbobs.io_getDouble, i)
		teleporter.p[1].y = c_tcm_private_get(tankbobs.io_getDouble, i)

		table.insert(r.teleporters, teleporter)
	end

	for it = 1, r.playerSpawnPoints_n do
		local playerSpawnPoint = c_tcm_playerSpawnPoint:new()

		playerSpawnPoint.id = c_tcm_private_get(tankbobs.io_getInt, i)
		playerSpawnPoint.p[1].x = c_tcm_private_get(tankbobs.io_getDouble, i)
		playerSpawnPoint.p[1].y = c_tcm_private_get(tankbobs.io_getDouble, i)

		table.insert(r.playerSpawnPoints, playerSpawnPoint)
	end

	for it = 1, r.powerupSpawnPoints_n do
		local powerupSpawnPoint = c_tcm_powerupSpawnPoint:new()

		powerupSpawnPoint.id = c_tcm_private_get(tankbobs.io_getInt, i)
		powerupSpawnPoint.p[1].x = c_tcm_private_get(tankbobs.io_getDouble, i)
		powerupSpawnPoint.p[1].y = c_tcm_private_get(tankbobs.io_getDouble, i)

		local powerups = {}
		for it = 1, 16 do  -- the format includes 16 ints for different powerup possibilities
			table.insert(powerups, c_tcm_private_get(tankbobs.io_getInt, i))
		end
		-- powerupSpawnPoint.enabledPowerups.x = true | false will be set when more powerups exist

		table.insert(r.powerupSpawnPoints, powerupSpawnPoint)
	end

	i:close()
end

function c_tcm_select_set(name)
	for k, v in pairs(c_tcm_current_sets) do
		if v.name == name then
			c_tcm_current_set = v
			return
		end
	end

	error("c_tcm_select_set: set '" .. name .. "' not found")
end

function c_tcm_select_map(name)
	for k, v in pairs(c_tcm_current_set.maps) do
		if v.name == name then
			c_tcm_current_map = v
			return
		end
	end

	error("c_tcm_select_map: map '" .. name .. "' not found")
end
