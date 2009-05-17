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
c_module.lua

interface to modules
--]]

function c_module_init()
	c_module_init = nil

	print("Tankbobs v" .. c_const_get("version") .. " startup")
end

function c_module_done()
	c_module_done = nil
end

function c_module_load(mod)
	if t.t_isWindows() then
		if t.t_is64Bit() then
			package.cpath = package.cpath .. ";" .. c_const_get("module64-win_dir") .. "?.so"
		else
			package.cpath = package.cpath .. ";" .. c_const_get("module-win_dir") .. "?.so"
		end

		if t.t_is64Bit() then
			package.cpath = package.cpath .. ";" .. c_const_get("module64_dir") .. "?.so"
		else
			package.cpath = package.cpath .. ";" .. c_const_get("module_dir") .. "?.so"
		end
	end
	require(mod)
end
