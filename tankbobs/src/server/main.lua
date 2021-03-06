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

	c_state_goto(main_state)

	main_data = {}

	if main_parseArgs(args) then
		return
	end

	args = nil

	main_runCommands(c_config_get("server.startupCommandFile"))

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

	local logFile = c_config_get("server.logFile", true)
	if type(logFile) ~= "string" then
		logFile = nil
	else
		logFile = c_const_get("user_dir") .. logFile
	end

	local fout
	if logFile then
		fout = tankbobs.fs_openAppend(logFile)
	end

	for _, v in pairs(p) do
		local vs = tostring(v)

		if fout then
			tankbobs.fs_write(fout, vs)
		end

		tankbobs.c_print(vs)
	end

	if fout then
		tankbobs.fs_close(fout)
	end
end

function s_restart()
	c_state_goto(main_state)
	s_printnl("Restarting . . .")
end

local s_print = s_print
function s_printnl(...)
	s_print(...)

	s_print('\n')
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
		stdout:write("Time wrapped\n")
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

	fps = common_MTF(t - lastTime)
	if c_config_get("common.dro") then
		common_dro_addFrame(fps)
	end

	if c_tcm_current_map and (c_config_get("server.pfps") == 0 or not lastPTime or t - lastPTime > common_FTM(c_config_get("server.pfps"))) then
		lastPTime = t

		if not p then
			p = {}
		else
			tankbobs.t_emptyTable(p)
		end
		local reachedFinal = false
		local data
		repeat
			data, reachedFinal = c_protocol_persist(c_config_get("server.maxPersistSize"))
			table.insert(p, data)
		until reachedFinal
	end

	local d = (t - lastTime) / c_world_timeMultiplier()
	lastTime = t

	if d == 0 then
		d = 1.0E-6  -- make an inaccurate guess
	end

	c_state_step(d)
end

function main_parseArgs(args)
	local line

	for k, v in pairs(args) do
		if k > 1 then
			if not line then
				line = "eval " .. v
			else
				line = line .. " " .. v
			end
		end
	end

	if not line then
		return
	end

	return commands_command(line)
end

function main_runCommands(filename)
	if #filename <= 0 or not tankbobs.fs_fileExists(filename) then
		return
	end

	local fin = tankbobs.fs_openRead(filename)

	line = tankbobs.fs_getStr(fin, '\n')
	while line do
		commands_command(line)

		line = tankbobs.fs_getStr(fin, '\n')
	end

	tankbobs.fs_close(fin)
end
