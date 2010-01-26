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
c_module.lua

Interface to modules
--]]

function c_module_init()
	c_module_init = nil

	package.cpath = c_const_get("data_dir") .. "?.lua" .. ";" .. package.cpath
	package.path = c_const_get("data_dir") .. "?.lua" .. ";" .. package.path
	package.path = c_const_get("jit_dir") .. "?.lua" .. ";" .. package.path

	if tankbobs.t_isWindows() then
		if tankbobs.t_is64Bit() then
			package.cpath = c_const_get("module64-win_dir") .. "?.dll" .. ";" .. package.cpath
		else
			package.cpath = c_const_get("module-win_dir") .. "?.dll" .. ";" .. package.cpath
		end
	else
		if tankbobs.t_is64Bit() then
			package.cpath = c_const_get("module64_dir") .. "?.so" .. ";" .. package.cpath
		else
			package.cpath = c_const_get("module_dir") .. "?.so" .. ";" .. package.cpath
		end
	end

	common_print(-1, "Tankbobs v" .. c_const_get("version") .. " startup\n")
end

function c_module_done()
	common_print(-1, "Tankbobs v" .. c_const_get("version") .. " shutdown\n")

	c_module_done = nil
end

function c_module_initAbsoluteDirs()
	--package.cpath = c_const_get("base_absoluteDir") .. "?.lua" .. ";" .. package.path
	--package.cpath = c_const_get("jit_absoluteDir") .. "?.lua" .. ";" .. package.path
	package.path = c_const_get("base_absoluteDir") .. "?.lua" .. ";" .. package.path
	package.path = c_const_get("jit_absoluteDir") .. "?.lua" .. ";" .. package.path

	if tankbobs.t_isWindows() then
		if tankbobs.t_is64Bit() then
			package.cpath = c_const_get("module64-win_absoluteDir") .. "?.dll" .. ";" .. package.cpath
		else
			package.cpath = c_const_get("module-win_absoluteDir") .. "?.dll" .. ";" .. package.cpath
		end
	else
		if tankbobs.t_is64Bit() then
			package.cpath = c_const_get("module64_absoluteDir") .. "?.so" .. ";" .. package.cpath
		else
			package.cpath = c_const_get("module_absoluteDir") .. "?.so" .. ";" .. package.cpath
		end
	end
end

function c_module_load(mod)
	return require(mod)
end
