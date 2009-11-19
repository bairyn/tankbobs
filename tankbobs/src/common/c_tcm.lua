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
powerupSpawnPoint, double x1, double y1, string stringPowerupsToEnable, int linked, double repeat, double initial, int focus - stringPowerupsToEnable will be searched for and will be tested if it has the name of any powerups
path, string name, string targetName, double x1, double y1, int enabled, time
controlPoint, double x1, double y1, int red
flag, double x1, double y1, int red

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
64 bytes map version; human readable NULL-terminated string
4 bytes map version
64 bytes null-terminated script of map (run after world is initialized)
4 bytes number of walls
4 bytes number of teleporters
4 bytes number of playerSpawnPoints
4 bytes number of powerupSpawnPoints
4 bytes number of paths
4 bytes number of controlPoints
4 bytes number of flags
4 bytes number of wayPoints
walls
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
 -64 bytes misc
 - 367 total bytes
teleporters
 -4 bytes id
 -4 bytes target id
 -8 bytes x1 double float
 -8 bytes y1 double float
 -1 byte enabled
 -64 bytes misc
 - 33 total bytes
playerSpawnPoints
 -4 bytes id
 -8 bytes x1 double float
 -8 bytes y1 double float
 -64 bytes misc
 - 20 total bytes
powerupSpawnPoints
 -4 bytes id
 -8 bytes x1 double float
 -8 bytes y1 double float
 -4 bytes powerups to enable
 -4 bytes more powerups to enable
 -4 bytes more powerups to enable
 -4 bytes more powerups to enable
 -another 4 groups of powerups - these groups altogether are altogether 64 bytes
 -1 byte linked
 -8 bytes repeat double float
 -8 bytes initial double float
 -1 byte focus
 -64 bytes misc
 - 118 total bytes
paths
 -4 bytes id
 -8 bytes x1 double float
 -8 bytes y1 double float
 -1 byte enabled
 -8 bytes double float time to reach other path
 -4 bites target id
 -64 bytes misc
 - 33 total bytes
controlPoints
 -4 bytes id
 -8 bytes x1 double float
 -8 bytes y1 double float
 -1 byte red
 -64 bytes misc
 - 21 total bytes
wayPoints
 -4 bytes id
 -8 bytes x1 double float
 -8 bytes y1 double float
 -64 bytes misc
 - 20 total bytes
--]]

local bit

function c_tcm_init()
	bit = c_module_load "bit"

	c_const_set("tcm_dir", c_const_get("data_dir") .. "tcm/")
	c_const_set("tcm_sets_dir", c_const_get("data_dir") .. "sets/")
	local magic = 0xDEADBEEF
	c_const_set("tcm_magic", magic)
	c_const_set("tcm_version", 3)  -- odd number versions are unstable; even number versions are stable
	c_const_set("tcm_headerLength", 11)

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
	new = c_class_new,

	maps = {},  -- table of maps.  All maps are loaded once
	name = "",  -- internal name.
	order = 0,  -- bigger values of order are more back
	title = "",  -- the name the player will see.
	description = ""  -- the description
}

c_tcm_map =
{
	new = c_class_new,

	map = "",  -- the filename

	version = 0,
	name = "",  -- unique name
	title = "",  -- the name the player will see
	description = "",  -- the description
	authors = "",
	version_string = "",
	staticCamera = false,

	script = "",

	walls_n = 0,
	teleporters_n = 0,
	playerSpawnPoints_n = 0,
	powerupSpawnPoints_n = 0,
	paths_n = 0,
	controlPoints_n = 0,
	flags_n = 0,
	wayPoints_n = 0,

	walls = {},  -- table of walls
	teleporters = {},
	playerSpawnPoints = {},
	powerupSpawnPoints = {},
	paths = {},
	controlPoints = {},
	flags = {},
	wayPoints = {},

	message = "",  -- the level message

	wayPointNetwork = {},
	levels = {},
	uppermost = 0,
	lowermost = 0,
	rightmost = 0,
	leftmost = 0
}

c_tcm_entity =
{
	new = c_class_new,

	id = 0,
	p = tankbobs.m_vec2(),

	misc = "",

	m = {p = {}}  -- extra and persistent data (data not directly loaded in map; e.g. position on current path
}

c_tcm_wall =
{
	new  = c_class_new,
	base = c_tcm_entity,
	init = function (o)
		o.l = c_const_get("tcm_tankLevel")
	end,

	p = {tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()},  -- walls have 4 (or 3) positions
	t = {tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2(), tankbobs.m_vec2()},
	texture = "",
	detail = false,
	static = false,
	l = 0,

	pid = 0,
	path = false,
}

c_tcm_teleporter =
{
	new  = c_class_new,
	base = c_tcm_entity,

	t = 0,
	enabled = false,
}

c_tcm_playerSpawnPoint =
{
	new  = c_class_new,
	base = c_tcm_entity,
}

c_tcm_powerupSpawnPoint =
{
	new  = c_class_new,
	base = c_tcm_entity,

	enabledPowerups = {},
	linked = false,  -- powerups will spawn in order
	["repeat"] = 0,  -- time between each powerup
	initial = 0,  -- initial time before first powerup
	focus = false,  -- focus the camera on spawned powerup
}

c_tcm_path =
{
	new  = c_class_new,
	base = c_tcm_entity,

	t = 0,
	time = 0,
	enabled = false,
}

c_tcm_controlPoint =
{
	new  = c_class_new,
	base = c_tcm_entity,

	red = false,

	wayPoint = 0,
}

c_tcm_flag =
{
	new  = c_class_new,
	base = c_tcm_entity,

	red = false,

	wayPoint = 0,
}

c_tcm_wayPoint =
{
	new  = c_class_new,
	base = c_tcm_entity,
}

function c_tcm_read_sets(dir, t)
	if not dir or dir == "" then
		error "Invalid set directory."
	end

	for _, v in pairs(tankbobs.fs_listFiles(dir)) do
		if v:find("^set-") and common_endsIn(v, ".txt") then
			c_tcm_read_set(dir .. v, t)
		end
	end

	table.sort(t, function (a, b) return a.order < b.order end)

	c_mods_data_load()
	c_mods_body()
end

function c_tcm_read_set(filename, t)
	local s = c_tcm_set:new()
	local set_f = tankbobs.fs_openRead(filename)
	local line

	-- read the set file line by line:
	-- The 1st line is the set's name
	line = tankbobs.fs_getStr(set_f, '\n')
	if not line then
		error("c_tcm_read_set: unexpected EOF while reading '" .. filename .. "'")
	end
	s.name = line

	-- The 2nd line is the set's title
	line = tankbobs.fs_getStr(set_f, '\n')
	if not line then
		error("c_tcm_read_set: unexpected EOF while reading '" .. filename .. "'")
	end
	s.title = line

	-- The 3rd line is the set's order
	line = tankbobs.fs_getStr(set_f, '\n')
	if not line then
		error("c_tcm_read_set: unexpected EOF while reading '" .. filename .. "'")
	end
	s.order = line
	if(s.order:match("^[\n\t ]*([%d%.]+)[\n\t ]*$")) then
		s.order = s.order:match("^[\n\t ]*([%d%.]+)[\n\t ]*$")
	end
	s.order = tonumber(s.order)

	-- The 4th line is the set's description
	line = tankbobs.fs_getStr(set_f, '\n')
	if not line then
		error("c_tcm_read_set: unexpected EOF while reading '" .. filename .. "'")
	end
	s.description = line

	-- read the set's filenames and read their headers
	line = tankbobs.fs_getStr(set_f, '\n')
	if not line then
		error("c_tcm_read_set: unexpected EOF while reading '" .. filename .. "'")
	end
	while line and type(line) == "string" and line ~= "" do
		table.insert(s.maps, c_tcm_read_map(c_const_get("tcm_dir") .. line))

		line = tankbobs.fs_getStr(set_f, '\n')
	end

	tankbobs.fs_close(set_f)

	table.insert(t, s)
end

-- f: io function (e.g. tankbobs.fs_getChar)
-- i: input file
-- t: if this argument is true, instead of giving an error, nil is returned
-- ...: extra arguments to pass (t can be false)
local function c_tcm_private_get(f, i, t, ...)
	local d, d2 = f(i, ...)

	if d2 or not d then
		if t then
			return nil
		else
			error "EOF unexpected"
		end
	end

	return d
end

local function c_tcm_check_true_header(filename, i)
	if c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0x00 then
		error "Invalid map header"
	elseif c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0x54 then
		error "Invalid map header"
	elseif c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0x43 then
		error "Invalid map header"
	elseif c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0x4D then
		error "Invalid map header"
	elseif c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0x01 then
		error "Invalid map header"
	elseif string.format("%X", c_tcm_private_get(tankbobs.fs_getInt, i)):sub(-8) ~= string.format("%X", c_const_get("tcm_magic")):sub(-8) then
		error "Invalid map header"
	elseif c_tcm_private_get(tankbobs.fs_getChar, i) ~= c_const_get("tcm_version") then
		tankbobs.fs_seekFromStart(i, tankbobs.fs_tell(i) - 1)
		common_printError(-1, "Warning: map '", filename, "' was built for tcm version '", tostring(c_tcm_private_get(tankbobs.fs_getChar, i)), "'; you are running version '", tostring(c_const_get("tcm_version")), "'\n")
	end
end

function c_tcm_read_map(filename)
	local r = c_tcm_map:new()

	if c_const_get("debug") then
		common_print(-1, "Parsing header of file: ", filename, "\n")
	end

	r.map = filename

	local i = tankbobs.fs_openRead(filename)
	
	c_tcm_check_true_header(filename, i)

	r.name = c_tcm_private_get(tankbobs.fs_read, i, false, 64)
	r.title = c_tcm_private_get(tankbobs.fs_read, i, false, 64)
	r.description = c_tcm_private_get(tankbobs.fs_read, i, false, 64)
	r.authors = c_tcm_private_get(tankbobs.fs_read, i, false, 512)
	r.version_string = c_tcm_private_get(tankbobs.fs_read, i, false, 64)
	r.version = c_tcm_private_get(tankbobs.fs_getInt, i)
	if c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0 then
		r.staticCamera = true
	else
		r.staticCamera = false
	end
	r.script = c_tcm_private_get(tankbobs.fs_read, i, false, 64)
	-- strip trailing 0's from NULL-terminated strings passed by C
	-- we might use getStr and avoid this but if the string uses all of the bytes getStr won't work
	r.name = r.name:gsub("%z*$", "")
	r.title = r.title:gsub("%z*$", "")
	r.description = r.description:gsub("%z*$", "")
	r.authors = r.authors:gsub("%z*$", "")
	r.version_string = r.version_string:gsub("%z*$", "")
	r.script = r.script:gsub("%z*$", "")

	r.walls_n = c_tcm_private_get(tankbobs.fs_getInt, i)
	r.teleporters_n = c_tcm_private_get(tankbobs.fs_getInt, i)
	r.playerSpawnPoints_n = c_tcm_private_get(tankbobs.fs_getInt, i)
	r.powerupSpawnPoints_n = c_tcm_private_get(tankbobs.fs_getInt, i)
	r.paths_n = c_tcm_private_get(tankbobs.fs_getInt, i)
	r.controlPoints_n = c_tcm_private_get(tankbobs.fs_getInt, i)
	r.flags_n = c_tcm_private_get(tankbobs.fs_getInt, i)
	r.wayPoints_n = c_tcm_private_get(tankbobs.fs_getInt, i)

	local uppermost = 100
	local lowermost = 0
	local rightmost = 100
	local leftmost  = 0
	for it = 1, r.walls_n do
		local wall = c_tcm_wall:new()
		local q = false

		wall.id = c_tcm_private_get(tankbobs.fs_getInt, i)
		if c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0 then
			q = true
		else
			q = false
			wall.p[4] = nil
		end
		wall.p[1].x = c_tcm_private_get(tankbobs.fs_getDouble, i)
		wall.p[1].y = c_tcm_private_get(tankbobs.fs_getDouble, i)
		wall.p[2].x = c_tcm_private_get(tankbobs.fs_getDouble, i)
		wall.p[2].y = c_tcm_private_get(tankbobs.fs_getDouble, i)
		wall.p[3].x = c_tcm_private_get(tankbobs.fs_getDouble, i)
		wall.p[3].y = c_tcm_private_get(tankbobs.fs_getDouble, i)
		if q then
			wall.p[4].x = c_tcm_private_get(tankbobs.fs_getDouble, i)
			wall.p[4].y = c_tcm_private_get(tankbobs.fs_getDouble, i)

			for i = 1, 4 do
				if wall.p[i].x < leftmost then
					leftmost = wall.p[i].x
				elseif wall.p[i].x > rightmost then
					rightmost = wall.p[i].x
				end

				if wall.p[i].y < lowermost then
					lowermost = wall.p[i].y
				elseif wall.p[i].y > uppermost then
					uppermost = wall.p[i].y
				end
			end
		else
			tankbobs.fs_seekFromStart(i, tankbobs.fs_tell(i) + 16)
			--for its = 1, 2 do
				--c_tcm_private_get(tankbobs.fs_getDouble, i)
			--end

			for i = 1, 3 do
				if wall.p[i].x < leftmost then
					leftmost = wall.p[i].x
				elseif wall.p[i].x > rightmost then
					rightmost = wall.p[i].x
				end

				if wall.p[i].y < lowermost then
					lowermost = wall.p[i].y
				elseif wall.p[i].y > uppermost then
					uppermost = wall.p[i].y
				end
			end
		end
		wall.t[1].x = c_tcm_private_get(tankbobs.fs_getDouble, i)
		wall.t[1].y = c_tcm_private_get(tankbobs.fs_getDouble, i)
		wall.t[2].x = c_tcm_private_get(tankbobs.fs_getDouble, i)
		wall.t[2].y = c_tcm_private_get(tankbobs.fs_getDouble, i)
		wall.t[3].x = c_tcm_private_get(tankbobs.fs_getDouble, i)
		wall.t[3].y = c_tcm_private_get(tankbobs.fs_getDouble, i)
		if q then
			wall.t[4].x = c_tcm_private_get(tankbobs.fs_getDouble, i)
			wall.t[4].y = c_tcm_private_get(tankbobs.fs_getDouble, i)
		else
			tankbobs.fs_seekFromStart(i, tankbobs.fs_tell(i) + 16)
			--for its = 1, 2 do
				--c_tcm_private_get(tankbobs.fs_getDouble, i)
			--end
		end

		wall.texture = c_tcm_private_get(tankbobs.fs_read, i, false, 256)
		wall.texture = wall.texture:gsub("%z*$", "")
		wall.l = c_tcm_private_get(tankbobs.fs_getInt, i)

		wall.pid = c_tcm_private_get(tankbobs.fs_getInt, i)
		if c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0 then
			wall.path = true
		else
			wall.path = false
		end

		if c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0 then
			wall.detail = true
		else
			wall.detail = false
		end

		if c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0 then
			wall.static = true
		else
			wall.static = false
		end

		wall.misc = c_tcm_private_get(tankbobs.fs_read, i, false, 64)
		wall.misc = wall.misc:gsub("%z*$", "") 

		table.insert(r.walls, wall)
	end
	r.uppermost = uppermost
	r.lowermost = lowermost
	r.rightmost = rightmost
	r.leftmost  = leftmost

	for it = 1, r.teleporters_n do
		local teleporter = c_tcm_teleporter:new()

		teleporter.id = c_tcm_private_get(tankbobs.fs_getInt, i)
		teleporter.t = c_tcm_private_get(tankbobs.fs_getInt, i)
		teleporter.p.x = c_tcm_private_get(tankbobs.fs_getDouble, i)
		teleporter.p.y = c_tcm_private_get(tankbobs.fs_getDouble, i)
		if c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0 then
			teleporter.enabled = true
		else
			teleporter.enabled = false
		end

		teleporter.misc = c_tcm_private_get(tankbobs.fs_read, i, false, 64)
		teleporter.misc = teleporter.misc:gsub("%z*$", "") 

		r.wayPointNetwork[-it] = {}

		table.insert(r.teleporters, teleporter)
	end

	for it = 1, r.playerSpawnPoints_n do
		local playerSpawnPoint = c_tcm_playerSpawnPoint:new()

		playerSpawnPoint.id = c_tcm_private_get(tankbobs.fs_getInt, i)
		playerSpawnPoint.p.x = c_tcm_private_get(tankbobs.fs_getDouble, i)
		playerSpawnPoint.p.y = c_tcm_private_get(tankbobs.fs_getDouble, i)

		playerSpawnPoint.misc = c_tcm_private_get(tankbobs.fs_read, i, false, 64)
		playerSpawnPoint.misc = playerSpawnPoint.misc:gsub("%z*$", "") 

		table.insert(r.playerSpawnPoints, playerSpawnPoint)
	end

	for it = 1, r.powerupSpawnPoints_n do
		local powerupSpawnPoint = c_tcm_powerupSpawnPoint:new()

		powerupSpawnPoint.id = c_tcm_private_get(tankbobs.fs_getInt, i)
		powerupSpawnPoint.p.x = c_tcm_private_get(tankbobs.fs_getDouble, i)
		powerupSpawnPoint.p.y = c_tcm_private_get(tankbobs.fs_getDouble, i)

		local powerups = {}
		for it = 1, 16 do  -- the format includes 16 ints for different powerup possibilities
			table.insert(powerups, c_tcm_private_get(tankbobs.fs_getInt, i))
		end

		if bit.band(powerups[1], bit.tobit(0x00000001)) ~= 0 then
			powerupSpawnPoint.enabledPowerups.machinegun = true
		else
			powerupSpawnPoint.enabledPowerups.machinegun = false
		end
		if bit.band(powerups[1], bit.tobit(0x00000002)) ~= 0 then
			powerupSpawnPoint.enabledPowerups.shotgun = true
		else
			powerupSpawnPoint.enabledPowerups.shotgun = false
		end
		if bit.band(powerups[1], bit.tobit(0x00000004)) ~= 0 then
			powerupSpawnPoint.enabledPowerups.railgun = true
		else
			powerupSpawnPoint.enabledPowerups.railgun = false
		end
		if bit.band(powerups[1], bit.tobit(0x00000008)) ~= 0 then
			powerupSpawnPoint.enabledPowerups.coilgun = true
		else
			powerupSpawnPoint.enabledPowerups.coilgun = false
		end
		if bit.band(powerups[1], bit.tobit(0x00000010)) ~= 0 then
			powerupSpawnPoint.enabledPowerups.saw = true
		else
			powerupSpawnPoint.enabledPowerups.saw = false
		end
		if bit.band(powerups[1], bit.tobit(0x00000020)) ~= 0 then
			powerupSpawnPoint.enabledPowerups.ammo = true
		else
			powerupSpawnPoint.enabledPowerups.ammo = false
		end
		if bit.band(powerups[1], bit.tobit(0x00000040)) ~= 0 then
			powerupSpawnPoint.enabledPowerups["aim-aid"] = true
		else
			powerupSpawnPoint.enabledPowerups["aim-aid"] = false
		end
		if bit.band(powerups[1], bit.tobit(0x00000080)) ~= 0 then
			powerupSpawnPoint.enabledPowerups.health = true
		else
			powerupSpawnPoint.enabledPowerups.health = false
		end
		if bit.band(powerups[1], bit.tobit(0x00000100)) ~= 0 then
			powerupSpawnPoint.enabledPowerups.acceleration = true
		else
			powerupSpawnPoint.enabledPowerups.acceleration = false
		end
		if bit.band(powerups[1], bit.tobit(0x00000200)) ~= 0 then
			powerupSpawnPoint.enabledPowerups.shield = true
		else
			powerupSpawnPoint.enabledPowerups.shield = false
		end
		if bit.band(powerups[1], bit.tobit(0x00000400)) ~= 0 then
			powerupSpawnPoint.enabledPowerups["rocket-launcher"] = true
		else
			powerupSpawnPoint.enabledPowerups["rocket-launcher"] = false
		end
		if bit.band(powerups[1], bit.tobit(0x00000800)) ~= 0 then
			powerupSpawnPoint.enabledPowerups["laser-gun"] = true
		else
			powerupSpawnPoint.enabledPowerups["laser-gun"] = false
		end
		if bit.band(powerups[1], bit.tobit(0x00001000)) ~= 0 then
			powerupSpawnPoint.enabledPowerups["plasma-gun"] = true
		else
			powerupSpawnPoint.enabledPowerups["plasma-gun"] = false
		end

		if c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0 then
			powerupSpawnPoint.linked = true
		else
			powerupSpawnPoint.linked = false
		end
		powerupSpawnPoint["repeat"] = c_tcm_private_get(tankbobs.fs_getDouble, i)
		powerupSpawnPoint.initial = c_tcm_private_get(tankbobs.fs_getDouble, i)
		if c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0 then
			powerupSpawnPoint.focus = true
		else
			powerupSpawnPoint.focus = false
		end

		powerupSpawnPoint.misc = c_tcm_private_get(tankbobs.fs_read, i, false, 64)
		powerupSpawnPoint.misc = powerupSpawnPoint.misc:gsub("%z*$", "") 

		table.insert(r.powerupSpawnPoints, powerupSpawnPoint)
	end
 
	for it = 1, r.paths_n do
		local path = c_tcm_path:new()

		path.id = c_tcm_private_get(tankbobs.fs_getInt, i)
		path.p.x = c_tcm_private_get(tankbobs.fs_getDouble, i)
		path.p.y = c_tcm_private_get(tankbobs.fs_getDouble, i)
		if c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0 then
			path.enabled = true
		else
			path.enabled = false
		end
		path.time = c_tcm_private_get(tankbobs.fs_getDouble, i)
		path.t = c_tcm_private_get(tankbobs.fs_getInt, i)

		path.misc = c_tcm_private_get(tankbobs.fs_read, i, false, 64)
		path.misc = path.misc:gsub("%z*$", "") 

		table.insert(r.paths, path)
	end
  
	for it = 1, r.controlPoints_n do
		local controlPoint = c_tcm_controlPoint:new()

		controlPoint.id = c_tcm_private_get(tankbobs.fs_getInt, i)
		controlPoint.p.x = c_tcm_private_get(tankbobs.fs_getDouble, i)
		controlPoint.p.y = c_tcm_private_get(tankbobs.fs_getDouble, i)
		if c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0 then
			controlPoint.red = true
		else
			controlPoint.red = false
		end

		controlPoint.misc = c_tcm_private_get(tankbobs.fs_read, i, false, 64)
		controlPoint.misc = controlPoint.misc:gsub("%z*$", "") 

		table.insert(r.controlPoints, controlPoint)
	end

	for it = 1, r.flags_n do
		local flag = c_tcm_flag:new()

		flag.id = c_tcm_private_get(tankbobs.fs_getInt, i)
		flag.p.x = c_tcm_private_get(tankbobs.fs_getDouble, i)
		flag.p.y = c_tcm_private_get(tankbobs.fs_getDouble, i)
		if c_tcm_private_get(tankbobs.fs_getChar, i) ~= 0 then
			flag.red = true
		else
			flag.red = false
		end

		flag.misc = c_tcm_private_get(tankbobs.fs_read, i, false, 64)
		flag.misc = flag.misc:gsub("%z*$", "") 

		table.insert(r.flags, flag)
	end
  
	for it = 1, r.wayPoints_n do
		local wayPoint = c_tcm_wayPoint:new()

		wayPoint.id = c_tcm_private_get(tankbobs.fs_getInt, i)
		wayPoint.p.x = c_tcm_private_get(tankbobs.fs_getDouble, i)
		wayPoint.p.y = c_tcm_private_get(tankbobs.fs_getDouble, i)

		r.wayPointNetwork[it] = {}

		wayPoint.misc = c_tcm_private_get(tankbobs.fs_read, i, false, 64)
		wayPoint.misc = wayPoint.misc:gsub("%z*$", "") 

		table.insert(r.wayPoints, wayPoint)
	end

	tankbobs.fs_close(i)

	-- build way point network.  Positive id's are way points; negative id's are teleporters
	local lastPoint, currentPoint = nil
	local hull
	local a, b
	for i = 1, r.wayPoints_n do
		a = r.wayPoints[i]
		for j = i + 1, r.wayPoints_n do
			b = r.wayPoints[j]

			local intersection = false
			local weight = (b.p - a.p).R

			for _, v in pairs(r.walls) do
				if not v.detail and v.static then  -- ignore dynamic walls when testing for intersections
					--hull = v.m.pos
					hull = v.p
					for _, vs in pairs(hull) do
						currentPoint = vs
						if not lastPoint then
							lastPoint = hull[#hull]
						end

						if tankbobs.m_edge(lastPoint, currentPoint, a.p, b.p) then
							intersection = true
							break
						end

						lastPoint = currentPoint
					end
					lastPoint = nil
				end
			end

			if not intersection then
				table.insert(r.wayPointNetwork[i], {j, weight})
			end
		end
		for j = 1, r.teleporters_n do
			b = r.teleporters[j]

			local intersection = false
			local weight = (b.p - a.p).R

			for _, v in pairs(r.walls) do
				if not v.detail and v.static then  -- ignore dynamic walls when testing for intersections
					--hull = v.m.pos
					hull = v.p
					for _, vs in pairs(hull) do
						currentPoint = vs
						if not lastPoint then
							lastPoint = hull[#hull]
						end

						if tankbobs.m_edge(lastPoint, currentPoint, a.p, b.p) then
							intersection = true
							break
						end

						lastPoint = currentPoint
					end
					lastPoint = nil
				end
			end

			if not intersection and b.enabled and b.t > 0 then
				table.insert(r.wayPointNetwork[i], {-j, weight})
			end
		end
	end

	for i = 1, r.teleporters_n do
		a = r.teleporters[i]
		for j = i + 1, r.wayPoints_n do
			b = r.wayPoints[j]

			local intersection = false
			local weight = (b.p - a.p).R

			for _, v in pairs(r.walls) do
				if not v.detail and v.static then  -- ignore dynamic walls when testing for intersections
					--hull = v.m.pos
					hull = v.p
					for _, vs in pairs(hull) do
						currentPoint = v
						if not lastPoint then
							lastPoint = hull[#hull]
						end

						if tankbobs.m_edge(lastPoint, currentPoint, a.p, b.p) then
							intersection = true
							break
						end

						lastPoint = currentPoint
					end
					lastPoint = nil
				end
			end

			if not intersection then
				table.insert(r.wayPointNetwork[-i], {j, weight})
			end
		end
		for j = 1, r.teleporters_n do
			b = r.teleporters[j]

			local intersection = false
			--local weight = (b.p - a.p).R
			local weight = 0  -- teleporter to teleporter weighs nothing

			for _, v in pairs(r.walls) do
				if not v.detail and v.static then  -- ignore dynamic walls when testing for intersections
					--hull = v.m.pos
					hull = v.p
					for _, vs in pairs(hull) do
						currentPoint = vs
						if not lastPoint then
							lastPoint = hull[#hull]
						end

						if tankbobs.m_edge(lastPoint, currentPoint, a.p, b.p) then
							intersection = true
							break
						end

						lastPoint = currentPoint
					end
					lastPoint = nil
				end
			end

			if not intersection and a.enabled and a.t > 0 and b.enabled and b.t > 0 then
				table.insert(r.wayPointNetwork[-i], {-j, weight})
			end
		end
	end

	-- find closest way point in sight of all control points and flags
	local function findClosest(t)
		local lastPoint, currentPoint = nil
		local hull
		for _, v in pairs(t) do
			local w = {}

			for ks, vs in pairs(r.wayPoints) do
				local intersection = false

				for _, vss in pairs(r.walls) do
				if not vss.detail and vss.static then  -- ignore dynamic walls when testing for intersections
					--hull = vss.m.pos
					hull = vss.p
						for _, vsss in pairs(hull) do
							currentPoint = vsss
							if not lastPoint then
								lastPoint = hull[#hull]
							end

							if tankbobs.m_edge(lastPoint, currentPoint, v.p, vs.p) then
								intersection = true
								break
							end

							lastPoint = currentPoint
						end
						lastPoint = nil
					end
				end

				if not intersection then
					table.insert(w, ks)
				end
			end

			table.sort(w, function (a, b) return (r.wayPoints[a].p - v.p).R < (r.wayPoints[b].p - v.p).R end)

			if w[1] then
				v.wayPoint = w[1]
			else
				v.wayPoint = 0
			end
		end
	end

	-- build level table
	for i = 1, c_const_get("tcm_maxLevel") do
		if i == c_const_get("tcm_tankLevel") then
			r.levels[i] = {}
		end

		for _, v in pairs(r.walls) do
			if v.l == i then
				if not r.levels[i] then
					r.levels[i] = {}
				end

				table.insert(r.levels[i], v)
			end
		end
	end

	findClosest(r.controlPoints)
	findClosest(r.flags)

	-- sort entities by id, so that wall[i] has an id of i - 1
	table.sort(r.walls, function (e1, e2) return e1.id < e2.id end)
	table.sort(r.teleporters, function (e1, e2) return e1.id < e2.id end)
	table.sort(r.playerSpawnPoints, function (e1, e2) return e1.id < e2.id end)
	table.sort(r.powerupSpawnPoints, function (e1, e2) return e1.id < e2.id end)
	table.sort(r.paths, function (e1, e2) return e1.id < e2.id end)
	table.sort(r.controlPoints, function (e1, e2) return e1.id < e2.id end)
	table.sort(r.flags, function (e1, e2) return e1.id < e2.id end)
	table.sort(r.wayPoints, function (e1, e2) return e1.id < e2.id end)

	return r
end

function c_tcm_select_set(name)
	c_config_set("game.lastSet", name)

	for k, v in pairs(c_tcm_current_sets) do
		if v.name == name then
			c_tcm_current_set = v

			return
		end
	end

	common_printError(1, "warning: c_tcm_select_set: set '" .. name .. "' not found\n")
end

function c_tcm_select_map(name)
	c_config_set("game.lastMap", name)

	for k, v in pairs(c_tcm_current_set.maps) do
		if v.name == name then
			c_tcm_current_map = v

			return
		end
	end

	common_printError(1, "warning: c_tcm_select_map: map '" .. name .. "' not found\n")
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

		for _, v in pairs(c_tcm_current_map.controlPoints) do
			local pers = v.m.p
			v.m = {p = {}}
			if not clearPersistant then
				v.m.p = pers
			end
		end

		for _, v in pairs(c_tcm_current_map.flags) do
			local pers = v.m.p
			v.m = {p = {}}
			if not clearPersistant then
				v.m.p = pers
			end
		end

		for _, v in pairs(c_tcm_current_map.wayPoints) do
			local pers = v.m.p
			v.m = {p = {}}
			if not clearPersistant then
				v.m.p = pers
			end
		end
	end
end
