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

TankRawMap text format
everything is read line by line
Backslashes can be used for special character if it is followed by two hex chars.  (e.g. "\31" will be translated as "1", and "\ZYX" will be unchanged: "\ZYX")
The first element identifies the entity type.
Any whitespace before or after any commas is ignored.  Trailing whitespace at the end of a line is also ignored.  Escapes can be used to include whitespace (e.g. "  \31foo" for " foo").

Entities
map, string name, string title, string description, string authors, string version, integer version - the result is undefined if multiple map entities exist.  The concept of the "map" entity is similar to Quake's "worldspawn" entity.
wall, integer quad, double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4, double tx1, double ty1, double tx2, double ty2, double tx3, double ty3, double tx4, double ty4, string texture, integer level / layer of wall, string target, integer path, integer detail, integer static - target is the path
teleporter, string name, string targetName, double x1, double y1, int enabled
playerSpawnPoint, double x1, double y1
powerupSpawnPoint, double x1, double y1, string stringPowerupsToEnable - stringPowerupsToEnable will be searched for and will be tested if it has the name of any powerups
path, string name, string targetName, double x1, double y1, int enabled, time

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
4 bytes number of paths
walls, ...
 -4 bytes id (unique only to other walls)  -- NOTE: every enitity's id must increment consecutively
 -1 byte: if non-zero, the 4th coordinates are used
 -8 bytes x1 double float
 -8 bytes y1 double float
 -8 bytes x2 double float
 -8 bytes y2 double float
 -8 bytes x3 double float
 -8 bytes y3 double float
 -8 bytes x4 double float
 -8 bytes y4 double float
 -8 bytes texture x1 double float
 -8 bytes texture y1 double float
 -8 bytes texture x2 double float
 -8 bytes texture y2 double float
 -8 bytes texture x3 double float
 -8 bytes texture y3 double float
 -8 bytes texture x4 double float
 -8 bytes texture y4 double float
 -256 bytes texture
 -4 bytes level of wall (tanks are level 9)
 -1 byte detail
 -1 byte static
 -4 bytes path id
 -1 byte path (whether or not the wall follows a path)
 - 367 total bytes, this amount for each wall
teleporters, ...
 -4 bytes id
 -4 bytes target id
 -8 bytes x1 double float
 -8 bytes y1 double float
 -1 byte enabled
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
paths
 -4 bytes id
 -8 bytes x1 double float
 -8 bytes y1 double float
 -1 byte enabled
 -8 bytes double float time to reach other path
 -4 bites target id
 - 20 total bytes
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
	c_const_set("tcm_maxLevel", 20, 1)

	-- parse every set into memory
	c_tcm_current_sets = {}

	c_tcm_read_sets(c_const_get("tcm_sets_dir"), c_tcm_current_sets)
end

function c_tcm_done()
end

c_tcm_set =
{
	new = common_new,

	maps = {},  -- table of maps.  All maps are loaded once
	name = "",  -- internal name.
	title = "",  -- the name the player will see.
	description = ""  -- the description
}

c_tcm_map =
{
	new = common_new,

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
	paths_n = 0,

	walls = {},  -- table of walls
	teleporters = {},
	playerSpawnPoints = {},
	powerupSpawnPoints = {},
	paths = {},
	message = ""  -- the level message
}

c_tcm_wall =
{
	new = common_new,

	init = function (o)
		o.p[1] = tankbobs.m_vec2()
		o.p[2] = tankbobs.m_vec2()
		o.p[3] = tankbobs.m_vec2()
		o.p[4] = tankbobs.m_vec2()
		o.t[1] = tankbobs.m_vec2()
		o.t[2] = tankbobs.m_vec2()
		o.t[3] = tankbobs.m_vec2()
		o.t[4] = tankbobs.m_vec2()
		o.l = c_const_get("tcm_tankLevel")
	end,

	id = 0,
	p = {},
	t = {},
	texture = "",
	detail = false,
	static = false,
	l = 0,

	pid = 0,
	path = false,

	m = {p = {}}  -- extra data (data not in tcm; eg position if on a path)
}

c_tcm_teleporter =
{
	new = common_new,

	init = function (o)
		o.p[1] = tankbobs.m_vec2()
	end,

	id = 0,
	t = 0,
	p = {},

	m = {p = {}}  -- extra data
}

c_tcm_playerSpawnPoint =
{
	new = common_new,

	init = function (o)
		o.p[1] = tankbobs.m_vec2()
	end,

	id = 0,
	p = {},

	m = {p = {}}  -- extra data
}

c_tcm_powerupSpawnPoint =
{
	new = common_new,

	init = function (o)
		o.p[1] = tankbobs.m_vec2()
	end,

	id = 0,
	p = {},
	enabledPowerups = {},

	m = {p = {}}  -- extra data
}

c_tcm_path =
{
	new = common_new,

	init = function (o)
		o.p[1] = tankbobs.m_vec2()
	end,

	id = 0,
	p = {},
	t = 0,
	time = 0,
	enabled = false,

	m = {p = {}}  -- extra data
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

	return d
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
	elseif string.format("%X", c_tcm_private_get(tankbobs.io_getInt, i)):sub(-8) ~= string.format("%X", c_const_get("tcm_magic")):sub(-8) then
		error "Invalid map header"
	elseif c_tcm_private_get(tankbobs.io_getChar, i) ~= c_const_get("tcm_version") then
		i:seek("cur", -1)
		io.stdout:write("Warning: map was built for tcm version '", tostring(c_tcm_private_get(tankbobs.io_getChar, i)), "'; you are using version '", tostring(c_const_get("tcm_version")), "'\n")
	end
end

function c_tcm_read_map(map)
	local r = c_tcm_map:new()

	if c_const_get("debug") then
		io.stdout:write("Parsing header of file: ", map, "\n")
	end

	r.map = map

	local i, err, errnum = io.open(map, "r")

	if not i then
		error("Could not open '" .. map .. "': " .. err .. " - error number: " .. errnum .. ".")
	end
	
	c_tcm_check_true_header(i)

	r.name = c_tcm_private_get(tankbobs.io_getStrL, i, false, 64)
	r.title = c_tcm_private_get(tankbobs.io_getStrL, i, false, 64)
	r.description = c_tcm_private_get(tankbobs.io_getStrL, i, false, 64)
	r.authors = c_tcm_private_get(tankbobs.io_getStrL, i, false, 512)
	r.version_string = c_tcm_private_get(tankbobs.io_getStrL, i, false, 64)
	r.version = c_tcm_private_get(tankbobs.io_getInt, i)
	-- strip trailing 0's from NULL-terminated strings passed by C
	-- we might use getStr and avoid this but if the string uses all of the bytes getStr won't work
	r.name = r.name:gsub("%z*$", "")
	r.title = r.title:gsub("%z*$", "")
	r.description = r.description:gsub("%z*$", "")
	r.authors = r.authors:gsub("%z*$", "")
	r.version_string = r.version_string:gsub("%z*$", "")

	r.walls_n = c_tcm_private_get(tankbobs.io_getInt, i)
	r.teleporters_n = c_tcm_private_get(tankbobs.io_getInt, i)
	r.playerSpawnPoints_n = c_tcm_private_get(tankbobs.io_getInt, i)
	r.powerupSpawnPoints_n = c_tcm_private_get(tankbobs.io_getInt, i)
	r.paths_n = c_tcm_private_get(tankbobs.io_getInt, i)

	for it = 1, r.walls_n do
		local wall = c_tcm_wall:new()
		local q = false

		wall.id = c_tcm_private_get(tankbobs.io_getInt, i)
		if c_tcm_private_get(tankbobs.io_getChar, i) ~= 0 then
			q = true
		else
			q = false
			table.remove(wall.p, 4)
		end
		wall.p[1].x = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.p[1].y = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.p[2].x = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.p[2].y = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.p[3].x = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.p[3].y = c_tcm_private_get(tankbobs.io_getDouble, i)
		if q then
			wall.p[4].x = c_tcm_private_get(tankbobs.io_getDouble, i)
			wall.p[4].y = c_tcm_private_get(tankbobs.io_getDouble, i)
		else
			i:seek("cur", 16)
			--for its = 1, 2 do
				--c_tcm_private_get(tankbobs.io_getDouble, i)
			--end
		end
		wall.t[1].x = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.t[1].y = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.t[2].x = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.t[2].y = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.t[3].x = c_tcm_private_get(tankbobs.io_getDouble, i)
		wall.t[3].y = c_tcm_private_get(tankbobs.io_getDouble, i)
		if q then
			wall.t[4].x = c_tcm_private_get(tankbobs.io_getDouble, i)
			wall.t[4].y = c_tcm_private_get(tankbobs.io_getDouble, i)
		else
			i:seek("cur", 16)
			--for its = 1, 2 do
				--c_tcm_private_get(tankbobs.io_getDouble, i)
			--end
		end

		wall.texture = c_tcm_private_get(tankbobs.io_getStrL, i, false, 256)
		wall.texture = wall.texture:gsub("%z*$", "")
		wall.l = c_tcm_private_get(tankbobs.io_getInt, i)

		wall.pid = c_tcm_private_get(tankbobs.io_getInt, i)
		if c_tcm_private_get(tankbobs.io_getChar, i) ~= 0 then
			wall.path = true
		else
			wall.path = false
		end

		if c_tcm_private_get(tankbobs.io_getChar, i) ~= 0 then
			wall.detail = true
		else
			wall.detail = false
		end
		if c_tcm_private_get(tankbobs.io_getChar, i) ~= 0 then
			wall.static = true
		else
			wall.static = false
		end

		table.insert(r.walls, wall)
	end

	for it = 1, r.teleporters_n do
		local teleporter = c_tcm_teleporter:new()

		teleporter.id = c_tcm_private_get(tankbobs.io_getInt, i)
		teleporter.t = c_tcm_private_get(tankbobs.io_getInt, i)
		teleporter.p[1].x = c_tcm_private_get(tankbobs.io_getDouble, i)
		teleporter.p[1].y = c_tcm_private_get(tankbobs.io_getDouble, i)
		if c_tcm_private_get(tankbobs.io_getChar, i) ~= 0 then
			teleporter.enabled = true
		else
			teleporter.enabled = false
		end

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
		if tankbobs.t_testAND(powerups[1], 0x00000001) then
			powerupSpawnPoint.enabledPowerups.machinegun = true
		else
			powerupSpawnPoint.enabledPowerups.machinegun = false
		end
		if tankbobs.t_testAND(powerups[1], 0x00000002) then
			powerupSpawnPoint.enabledPowerups.shotgun = true
		else
			powerupSpawnPoint.enabledPowerups.shotgun = false
		end
		if tankbobs.t_testAND(powerups[1], 0x00000004) then
			powerupSpawnPoint.enabledPowerups.railgun = true
		else
			powerupSpawnPoint.enabledPowerups.railgun = false
		end
		if tankbobs.t_testAND(powerups[1], 0x00000008) then
			powerupSpawnPoint.enabledPowerups.coilgun = true
		else
			powerupSpawnPoint.enabledPowerups.coilgun = false
		end
		if tankbobs.t_testAND(powerups[1], 0x00000010) then
			powerupSpawnPoint.enabledPowerups.saw = true
		else
			powerupSpawnPoint.enabledPowerups.saw = false
		end
		if tankbobs.t_testAND(powerups[1], 0x00000020) then
			powerupSpawnPoint.enabledPowerups.ammo = true
		else
			powerupSpawnPoint.enabledPowerups.ammo = false
		end
		if tankbobs.t_testAND(powerups[1], 0x00000040) then
			powerupSpawnPoint.enabledPowerups["aim-aid"] = true
		else
			powerupSpawnPoint.enabledPowerups["aim-aid"] = false
		end
		if tankbobs.t_testAND(powerups[1], 0x00000040) then
			powerupSpawnPoint.enabledPowerups.health = true
		else
			powerupSpawnPoint.enabledPowerups.health = false
		end

		table.insert(r.powerupSpawnPoints, powerupSpawnPoint)
	end
 
	for it = 1, r.paths_n do
		local path = c_tcm_path:new()

		path.id = c_tcm_private_get(tankbobs.io_getInt, i)
		path.p[1].x = c_tcm_private_get(tankbobs.io_getDouble, i)
		path.p[1].y = c_tcm_private_get(tankbobs.io_getDouble, i)
		if c_tcm_private_get(tankbobs.io_getChar, i) ~= 0 then
			path.enabled = true
		else
			path.enabled = false
		end
		path.time = c_tcm_private_get(tankbobs.io_getDouble, i)
		path.t = c_tcm_private_get(tankbobs.io_getInt, i)

		table.insert(r.paths, path)
	end

	i:close()

	-- sort entities based on their id's, so that wall[i] has an id of i - 1
	table.sort(r.walls, function (e1, e2) return e1.id < e2.id end)
	table.sort(r.teleporters, function (e1, e2) return e1.id < e2.id end)
	table.sort(r.playerSpawnPoints, function (e1, e2) return e1.id < e2.id end)
	table.sort(r.powerupSpawnPoints, function (e1, e2) return e1.id < e2.id end)
	table.sort(r.paths, function (e1, e2) return e1.id < e2.id end)

	return r;
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

function c_tcm_unload_extra_data(clearPersitant)
	if c_tcm_current_map then
		for _, v in pairs(c_tcm_current_map.walls) do
			local pers = v.m.p
			v.m = {p = {}}
			if not clearPersistant then
				v.m.p = pers
			end
		end

		for _, v in pairs(c_tcm_current_map.teleporters) do
			local pers = v.m.p
			v.m = {p = {}}
			if not clearPersistant then
				v.m.p = pers
			end
		end

		for _, v in pairs(c_tcm_current_map.playerSpawnPoints) do
			local pers = v.m.p
			v.m = {p = {}}
			if not clearPersistant then
				v.m.p = pers
			end
		end

		for _, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
			local pers = v.m.p
			v.m = {p = {}}
			if not clearPersistant then
				v.m.p = pers
			end
		end

		for _, v in pairs(c_tcm_current_map.paths) do
			local pers = v.m.p
			v.m = {p = {}}
			if not clearPersistant then
				v.m.p = pers
			end
		end
	end
end
