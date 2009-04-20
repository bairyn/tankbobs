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

	c_const_set("server_mlf", 1, 0)

	c_const_set("module_dir", c_const_get("data_dir") .. "modules/", 1)
	c_const_set("textures_dir",  c_const_get("data_dir") .. "textures/", 1)
	c_const_set("textures_default_dir", c_const_get("textures_dir") .. "global/", 1)
	c_const_set("textures_default", c_const_get("textures_default_dir") .. "invisible.png", 1)
	if tankbobs.io_getHomeDirectory() == nil then
		error(select(2, tankbobs.io_getHomeDirectory()))
	end
	c_const_set("user_dir", tankbobs.io_getHomeDirectory() .. "/.tankbobs/", 1)
	c_const_set("data_conf", c_const_get("data_dir") .. "default_conf.xml", 1)
	c_const_set("user_conf", c_const_get("user_dir") .. "rc.xml", 1)
	c_const_set("ttf_dir", c_const_get("data_dir") .. "ttf/", 1)
	c_const_set("default_fontSize", "12", 1)
	c_const_set("scripts_dir", c_const_get("data_dir") .. "scripts/", 1)
	c_const_set("icon", c_const_get("data_dir") .. "icon.png", 1)
	c_const_set("title", "tankbobs", 1)

	c_const_set("max_tanks", 64, 1)
end

function c_data_done()
	c_data_done = nil
end
