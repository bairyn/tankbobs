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
main.lua

startup and the like
--]]

local c_const_get  = c_const_get
local c_const_set  = c_const_set
local c_state_step = c_state_step
local c_config_get = c_config_get
local c_config_set = c_config_set
local common_FTM   = common_FTM
local tankbobs     = tankbobs

local main_loop

function main_init()
	c_const_get  = _G.c_const_get
	c_const_set  = _G.c_const_set
	c_state_step = _G.c_state_step
	c_config_get = _G.c_config_get
	c_config_set = _G.c_config_set
	common_FTM   = _G.common_FTM
	tankbobs     = _G.tankbobs

	tankbobs.c_loadHistory()

	tankbobs.c_init()

	c_state_new(main_state)

	while not done do
		main_loop()
	end

	tankbobs.c_quit()
end

function main_done()
	tankbobs.c_saveHistory()
end

function b_mods()
	c_const_get  = _G.c_const_get
	c_const_set  = _G.c_const_set
	c_state_step = _G.c_state_step
	c_config_get = _G.c_config_get
	c_config_set = _G.c_config_set
	common_FTM   = _G.common_FTM
	tankbobs     = _G.tankbobs

	c_mods_load(c_const_get("server-mods_dir"))
end

function s_print(...)
	local p = {}
	tankbobs.t_clone({...}, p)

	for _, v in pairs(p) do
		tankbobs.c_print(tostring(v))
	end
end

function s_restart()
	c_state_new(main_state)
	s_printnl("Restarting . . .")
end

local s_print = s_print
function s_printnl(...)
	s_print(...)

	tankbobs.c_print('\n')
end
s_println = s_printnl

local lastTime = 0
function main_loop()
	local t = tankbobs.t_getTicks()

	if lastTime == 0 then
		lastTime = tankbobs.t_getTicks()
		return
	end

	if tankbobs.t_getTicks() - lastTime < c_const_get("world_timeWrapTest") then
		--handle time wrap here
		io.stdout:write("Time wrapped\n")
		lastTime = tankbobs.t_getTicks()
		c_world_timeWrapped()
		return
	end

	if c_config_get("server.fps") < c_const_get("server_minFPS") and c_config_get("server.fps") ~= 0 then
		c_config_set("server.fps", c_const_get("server_minFPS"))
	end

	if c_config_get("server.fps") > 0 and t - lastTime < common_FTM(c_config_get("server.fps")) then
		tankbobs.t_delay(common_FTM(c_config_get("server.fps")) - t + lastTime)

		return
	end

	if c_tcm_current_map and (c_config_get("server.pfps") == 0 or not lastPTime or t - lastPTime > common_FTM(c_config_get("server.pfps"))) then
		lastPTime = t
		p = tankbobs.w_persistWorld(c_weapon_getProjectiles(), c_world_getTanks(), c_world_getPowerups(), c_tcm_current_map.walls, c_tcm_current_map.controlPoints, c_tcm_current_map.flags)
	end

	local d = (t - lastTime) / (c_const_get("world_time") * c_config_get("game.timescale"))
	lastTime = t

	if d == 0 then
		d = 1.0E-6  -- make an inaccurate guess
	end

	c_state_step(d)
end
