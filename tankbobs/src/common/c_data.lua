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
data.lua

Constants
--]]

function c_data_init()
	c_data_init = nil

	c_const_set("version", version)
	c_const_set("libmtankbobsversion", tankbobs.t_getVersion())
	c_const_set("debug", select(1, tankbobs.t_isDebug()))
	--c_const_set("data_dir", "./data/")
	c_const_set("data_dir", "")
	--c_const_set("client-mods_dir", "./mod-client/")
	--c_const_set("server-mods_dir", "./mod-server/")
	c_const_set("client-mods_dir", "mod-client/")
	c_const_set("server-mods_dir", "mod-server/")

	c_const_set("const_setError", true, 9)

	c_const_set("client_minFPS", 15, 0)
	c_const_set("server_minFPS", 5, 0)

	c_const_set("textures_dir", c_const_get("data_dir") .. "textures/", 1)
	c_const_set("textures_default_dir", c_const_get("textures_dir") .. "global/", 1)
	c_const_set("textures_default", c_const_get("textures_default_dir") .. "null.png", 1)
	c_const_set("game_dir", c_const_get("textures_dir") .. "game/", 1)
	c_const_set("weaponTextures_dir", c_const_get("game_dir") .. "weapons/", 1)
	c_const_set("healthbar_texture", c_const_get("game_dir") .. "healthbar.png", 1)
	c_const_set("healthbarBorder_texture", c_const_get("game_dir") .. "healthbarBorder.png", 1)
	c_const_set("ammobarBorder_texture", c_const_get("game_dir") .. "healthbarBorder.png", 1)
	--c_const_set("user_dir", tankbobs.fs_getUserDirectory() .. "/.tankbobs/", 1)
	c_const_set("user_dir", "", 1)
	--c_const_set("module_dir", "./modules/", 1)
	--c_const_set("module64_dir", "./modules64/", 1)
	--c_const_set("module-win_dir", "./modules-win/", 1)
	--c_const_set("module64-win_dir", "./modules64-win/", 1)
	c_const_set("module_dir", c_const_get("data_dir") .. "modules/", 1)
	c_const_set("module64_dir", c_const_get("data_dir") .. "modules64/", 1)
	c_const_set("module-win_dir", c_const_get("data_dir") .. "modules-win/", 1)
	c_const_set("module64-win_dir", c_const_get("data_dir") .. "modules64-win/", 1)
	c_const_set("jit_dir", c_const_get("data_dir") .. "jit/", 1)
	c_const_set("data_conf", c_const_get("data_dir") .. "default_conf.xml", 1)
	c_const_set("user_conf", c_const_get("user_dir") .. "rc.xml", 1)
	c_const_set("ui_file", c_const_get("user_dir") .. "GUID.dat", 1)
	c_const_set("ttf_dir", c_const_get("data_dir") .. "ttf/", 1)
	c_const_set("bans_file", c_const_get("user_dir") .. "bans.txt", 1)
	c_const_set("default_fontSize", "12", 1)
	c_const_set("scripts_dir", c_const_get("data_dir") .. "scripts/", 1)
	c_const_set("icon", c_const_get("data_dir") .. "icon.png", 1)
	c_const_set("tank", c_const_get("game_dir") .. "tank.png", 1)
	c_const_set("tankBorder", c_const_get("game_dir") .. "tankBorder.png", 1)
	c_const_set("tankShield", c_const_get("game_dir") .. "tankShield.png", 1)
	c_const_set("tankTagged", c_const_get("game_dir") .. "tankTagged.png", 1)
	c_const_set("tankMega", c_const_get("game_dir") .. "tankTagged.png", 1)
	c_const_set("explosion", c_const_get("game_dir") .. "explosion.png", 1)
	c_const_set("corpse", c_const_get("game_dir") .. "deadTank.png", 1)
	c_const_set("corpseBorder", c_const_get("game_dir") .. "tankBorder.png", 1)
	c_const_set("powerup", c_const_get("game_dir") .. "powerup.png", 1)
	c_const_set("controlPoint", c_const_get("game_dir") .. "controlPoint.png", 1)
	c_const_set("flag", c_const_get("game_dir") .. "flag.png", 1)
	c_const_set("flagBase", c_const_get("game_dir") .. "flagBase.png", 1)
	c_const_set("title", "Tankbobs", 1)
	c_const_set("history_file", c_const_get("user_dir") .. "history.txt", 1)
	c_const_set("audio_dir", c_const_get("data_dir") .. "audio/", 1)
	c_const_set("weaponAudio_dir", c_const_get("audio_dir") .. "weapons/", 1)
	c_const_set("song_dir", c_const_get("audio_dir") .. "songs/", 1)
	c_const_set("gameAudio_dir", c_const_get("audio_dir") .. "game/", 1)
	c_const_set("globalAudio_dir", c_const_get("audio_dir") .. "global/", 1)
	c_const_set("collide_sound", c_const_get("gameAudio_dir") .. "collide.wav", 1)
	c_const_set("corpseExplode_sound", c_const_get("gameAudio_dir") .. "explode.wav", 1)
	c_const_set("damage_sound", c_const_get("gameAudio_dir") .. "damage.wav", 1)
	c_const_set("die_sound", c_const_get("gameAudio_dir") .. "die.wav", 1)
	c_const_set("powerupPickup_sound", c_const_get("gameAudio_dir") .. "powerupSpawn.wav", 1)
	c_const_set("powerupSpawn_sound", c_const_get("gameAudio_dir") .. "powerupSpawn.wav", 1)
	c_const_set("collideProjectile_sounds", {c_const_get("gameAudio_dir") .. "collideProjectile.wav", c_const_get("gameAudio_dir") .. "collideProjectile2.wav", c_const_get("gameAudio_dir") .. "collideProjectile3.wav", c_const_get("gameAudio_dir") .. "collideProjectile4.wav", c_const_get("gameAudio_dir") .. "collideProjectile5.wav", c_const_get("gameAudio_dir") .. "collideProjectile6.wav"}, 1)
	c_const_set("emptyTrigger_sound", c_const_get("gameAudio_dir") .. "trigger.wav", 1)
	c_const_set("teleport_sound", c_const_get("gameAudio_dir") .. "teleport.wav", 1)
	c_const_set("control_sound", c_const_get("gameAudio_dir") .. "controlPoint.wav", 1)
	c_const_set("flagCapture_sound", c_const_get("gameAudio_dir") .. "flagCapture.wav", 1)
	c_const_set("flagPickUp_sound", c_const_get("gameAudio_dir") .. "controlPoint.wav", 1)
	c_const_set("flagReturn_sound", c_const_get("gameAudio_dir") .. "controlPoint.wav", 1)
	c_const_set("newMegaTank_sound", c_const_get("gameAudio_dir") .. "flagCapture.wav", 1)
	c_const_set("win_sound", c_const_get("gameAudio_dir") .. "win.wav", 1)
	c_const_set("ambience_sounds", {c_const_get("gameAudio_dir") .. "storm.mp3"}, 1)
	c_const_set("ambience_chanceDenom", 64, 1)  -- will play 1 - 64 ambience sounds, or nothing if doesn't exist

	-- key layouts enable configurations (including default keys) to be saved, loaded and shared in a standard format: qwerty

	local layout_qwerty =
	{
		{from = 97,  to = 97},   -- a
		{from = 98,  to = 98},   -- b
		{from = 99,  to = 99},   -- c
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
		{from = 91,  to = 91},   -- [
		{from = 93,  to = 93},   -- ]
		{from = 92,  to = 92},   -- \
		{from = 47,  to = 47},   -- /
		{from = 61,  to = 61},   -- =
		{from = 45,  to = 45},   -- -
		{from = 39,  to = 39},   -- '
		{from = 44,  to = 44},   -- ,
		{from = 46,  to = 46},   -- .
		{from = 59,  to = 59}    -- ;
	}
	local layout_qwertyTo = {}
	local layout_qwertyFrom = {}
	for _, v in pairs(layout_qwerty) do
		layout_qwertyTo[v.from] = v.to
		layout_qwertyFrom[v.to] = v.from
	end

	local layout_dvorak =
	{
		{from = 97,  to = 97},   -- a -> a
		{from = 98,  to = 120},  -- b -> x
		{from = 99,  to = 106},  -- c -> j
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
		{from = 91,  to = 47},   -- [ -> /
		{from = 93,  to = 61},   -- ] -> =
		{from = 92,  to = 92},   -- \ -> \
		{from = 47,  to = 122},  -- / -> z
		{from = 61,  to = 93},   -- = -> ]
		{from = 45,  to = 91},   -- - -> [
		{from = 39,  to = 45},   -- ' -> -
		{from = 44,  to = 119},  -- , -> w
		{from = 46,  to = 118},  -- . -> v
		{from = 59,  to = 115}   -- ; -> s
	}
	local layout_dvorakTo = {}
	local layout_dvorakFrom = {}
	for _, v in pairs(layout_dvorak) do
		layout_dvorakTo[v.from] = v.to
		layout_dvorakFrom[v.to] = v.from
	end

	c_const_set("keyLayout_default", layout_qwerty, 1)
	c_const_set("keyLayout_defaultTo", layout_qwertyTo, 1)
	c_const_set("keyLayout_defaultFrom", layout_qwertyFrom, 1)
	c_const_set("keyLayout_qwerty", layout_qwerty, 1)
	c_const_set("keyLayout_qwertyTo", layout_qwertyTo, 1)
	c_const_set("keyLayout_qwertyFrom", layout_qwertyFrom, 1)
	c_const_set("keyLayout_dvorak", layout_dvorak, 1)
	c_const_set("keyLayout_dvorakTo", layout_dvorakTo, 1)
	c_const_set("keyLayout_dvorakFrom", layout_dvorakFrom, 1)
	c_const_set("keyLayouts", {"qwerty", "dvorak"}, 1)

	c_const_set("default_connectPort", 43210, 1)

	c_const_set("defaultName", "UnnamedPlayer", 1)
	c_const_set("max_nameLength", 32, 1)

	if tankbobs.t_c() then
	    -- console is not implemented on all platforms
		tankbobs.c_setHistoryFile(c_const_get("history_file"))
	end
end

function c_data_done()
	c_data_done = nil
end
