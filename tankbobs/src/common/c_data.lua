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
data.lua

constants
--]]

function c_data_init()
	c_data_init = nil

	c_const_set("version", "0.1.0-dev")
	c_const_set("debug", select(1, tankbobs.t_isDebug()))
	c_const_set("data_dir", "./data/")
	c_const_set("client-mods_dir", "./mod-client/")
	c_const_set("server-mods_dir", "./mod-server/")

	c_const_set("const_setError", true, 9)

	local hidden_globals =
	{
		"init$",
		"done$",
		"^io$",
		"^tankbobs$",
		"^c_config_set$",
		"^c_mods",
		"^c_mods_env$",
		"^mods_env$",
		"^setfenv$",
		"^c_config_cheat",
		"^debug$"
	}

	local protected_globals =
	{
		"^common_$",
		"init$",
		"done$",
		"^io$",
		"^tankbobs$",
		"^tankbobs.vec2Meta$",
		"^tankbobs",
		"^string$",
		"^debug$",
		"^c_conf",
		"^c_data",
		"^c_mods_env$",
		"^mods_env$",
		"^c_config_cheat",
		"^setfenv$"
	}

	c_const_set("hidden_globals", hidden_globals)
	c_const_set("protected_globals", protected_globals)

	c_const_set("client_minFPS", 15, 0)
	c_const_set("server_minFPS", 5, 0)

	c_const_set("module_dir", c_const_get("data_dir") .. "modules/", 1)
	c_const_set("module64_dir", c_const_get("data_dir") .. "modules64/", 1)
	c_const_set("module-win_dir", c_const_get("data_dir") .. "modules-win/", 1)
	c_const_set("module64-win_dir", c_const_get("data_dir") .. "modules64-win/", 1)
	c_const_set("textures_dir",  c_const_get("data_dir") .. "textures/", 1)
	c_const_set("textures_default_dir", c_const_get("textures_dir") .. "global/", 1)
	c_const_set("textures_default", c_const_get("textures_default_dir") .. "null.png", 1)
	c_const_set("game_dir",  c_const_get("textures_dir") .. "game/", 1)
	c_const_set("weaponTextures_dir", c_const_get("game_dir") .. "weapons/", 1)
	if tankbobs.io_getHomeDirectory() == nil then
		error(select(2, tankbobs.io_getHomeDirectory()))
	end
	c_const_set("healthbar_texture",  c_const_get("game_dir") .. "healthbar.png", 1)
	c_const_set("healthbarBorder_texture",  c_const_get("game_dir") .. "healthbarBorder.png", 1)
	c_const_set("user_dir", tankbobs.io_getHomeDirectory() .. "/.tankbobs/", 1)
	c_const_set("data_conf", c_const_get("data_dir") .. "default_conf.xml", 1)
	c_const_set("user_conf", c_const_get("user_dir") .. "rc.xml", 1)
	c_const_set("ttf_dir", c_const_get("data_dir") .. "ttf/", 1)
	c_const_set("default_fontSize", "12", 1)
	c_const_set("scripts_dir", c_const_get("data_dir") .. "scripts/", 1)
	c_const_set("icon", c_const_get("game_dir") .. "icon.png", 1)
	c_const_set("tank", c_const_get("game_dir") .. "tank.png", 1)
	c_const_set("powerup", c_const_get("game_dir") .. "powerup.png", 1)
	c_const_set("title", "Tankbobs", 1)
	c_const_set("history_file", c_const_get("user_dir") .. "history.txt", 1)
	c_const_set("audio_dir",  c_const_get("data_dir") .. "audio/", 1)
	c_const_set("weaponAudio_dir",  c_const_get("audio_dir") .. "weapons/", 1)
	c_const_set("gameAudio_dir",  c_const_get("audio_dir") .. "game/", 1)
	c_const_set("collide_sound",  c_const_get("gameAudio_dir") .. "collide.wav", 1)
	c_const_set("damage_sound",  c_const_get("gameAudio_dir") .. "damage.wav", 1)
	c_const_set("die_sound",  c_const_get("gameAudio_dir") .. "die.wav", 1)
	c_const_set("powerupSpawn_sound",  c_const_get("gameAudio_dir") .. "powerupSpawn.wav", 1)

	c_const_set("max_tanks", 64, 1)

	local layout_qwerty =
	{
		{from = 97, to = 97},    -- a
		{from = 98, to = 98},    -- b
		{from = 99, to = 99},    -- c
		{from = 100, to = 100},  -- d
		{from = 101, to = 101},  -- e
		{from = 102, to = 102},  -- f
		{from = 103, to = 103},  -- g
		{from = 104, to = 104},  -- h
		{from = 105, to = 105},  -- i
		{from = 106, to = 106},  -- j
		{from = 107, to = 107},  -- k
		{from = 108, to = 108},  -- l
		{from = 109, to = 109},  -- m
		{from = 110, to = 110},  -- n
		{from = 111, to = 111},  -- o
		{from = 112, to = 112},  -- p
		{from = 113, to = 113},  -- q
		{from = 114, to = 114},  -- r
		{from = 115, to = 115},  -- s
		{from = 116, to = 116},  -- t
		{from = 117, to = 117},  -- u
		{from = 118, to = 118},  -- v
		{from = 119, to = 119},  -- w
		{from = 120, to = 110},  -- x
		{from = 121, to = 121},  -- y
		{from = 122, to = 122},  -- z
		{from = 91, to = 91},    -- [
		{from = 93, to = 93},    -- ]
		{from = 92, to = 92},    -- \
		{from = 47, to = 47},    -- /
		{from = 61, to = 61},    -- =
		{from = 45, to = 45},    -- -
		{from = 39, to = 39},    -- '
		{from = 44, to = 44},    -- ,
		{from = 46, to = 46},    -- .
		{from = 59, to = 59}     -- ;
	}

	local layout_dvorak =
	{
		{from = 97, to = 97},    -- a -> a
		{from = 98, to = 120},   -- b -> x
		{from = 99, to = 106},   -- c -> j
		{from = 100, to = 101},  -- d -> e
		{from = 101, to = 46},   -- e -> .
		{from = 102, to = 117},  -- f -> u
		{from = 103, to = 105},  -- g -> i
		{from = 104, to = 100},  -- h -> d
		{from = 105, to = 99},   -- i -> c
		{from = 106, to = 104},  -- j -> h
		{from = 107, to = 116},  -- k -> t
		{from = 108, to = 110},  -- l -> n
		{from = 109, to = 109},  -- m -> m
		{from = 110, to = 98},   -- n -> b
		{from = 111, to = 114},  -- o -> r
		{from = 112, to = 108},  -- p -> l
		{from = 113, to = 39},   -- q -> '
		{from = 114, to = 112},  -- r -> p
		{from = 115, to = 111},  -- s -> o
		{from = 116, to = 121},  -- t -> y
		{from = 117, to = 103},  -- u -> g
		{from = 118, to = 107},  -- v -> k
		{from = 119, to = 44},   -- w -> ,
		{from = 120, to = 113},  -- x -> q
		{from = 121, to = 102},  -- y -> f
		{from = 122, to = 59},   -- z -> ;
		{from = 91, to = 47},    -- [ -> /
		{from = 93, to = 61},    -- ] -> =
		{from = 92, to = 92},    -- \ -> \
		{from = 47, to = 122},   -- / -> z
		{from = 61, to = 93},    -- = -> ]
		{from = 45, to = 91},    -- - -> [
		{from = 39, to = 45},    -- ' -> -
		{from = 44, to = 119},   -- , -> w
		{from = 46, to = 118},   -- . -> v
		{from = 59, to = 115}    -- ; -> s
	}

	c_const_set("keyLayout_default", layout_qwerty, 1)
	c_const_set("keyLayout_qwerty", layout_qwerty, 1)
	c_const_set("keyLayout_dvorak", layout_dvorak, 1)

	c_const_set("max_nameLength", 32, 1)

	tankbobs.c_setHistoryFile(c_const_get("history_file"))
end

function c_data_done()
	c_data_done = nil
end
