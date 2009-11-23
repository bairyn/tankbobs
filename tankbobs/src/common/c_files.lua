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
c_files.lua

Files
--]]

function c_files_init()
	-- since we need the list after fs initialization, but we can only call common_listFiles before initialization, we load the 'lfs' module before initiazilation and use it to list files afterward
	--require "lfs"  -- since module loading bypasses fs, we can require this after initialization (for now)

	tankbobs.fs_setArgv0_(args[1])
	tankbobs.fs_init()

	-- set some constants and list files now that fs is initialized
	local d = tankbobs.fs_getRawDirectorySeparator()

	c_const_set("data_absoluteDir", tankbobs.fs_getBaseDirectory() .. d .. "data")
	c_const_set("base_absoluteDir", tankbobs.fs_getBaseDirectory())
	c_const_set("user_absoluteDir", tankbobs.fs_getUserDirectory() .. d .. ".tankbobs", 1)

	c_const_set("module_absoluteDir", c_const_get("data_absoluteDir") .. c_const_get("module_dir"), 1)
	c_const_set("module64_absoluteDir", c_const_get("data_absoluteDir") .. c_const_get("module64_dir"), 1)
	c_const_set("module-win_absoluteDir", c_const_get("data_absoluteDir") .. c_const_get("module-win_dir"), 1)
	c_const_set("module64-win_absoluteDir", c_const_get("data_absoluteDir") .. c_const_get("module64-win_dir"), 1)
	c_const_set("jit_absoluteDir", c_const_get("data_absoluteDir") .. c_const_get("jit_dir"), 1)
	c_module_initAbsoluteDirs()

	require "lfs"  -- since module loading bypasses fs, we can require this after initialization (for now)


	local function common_listFiles(dir, extension)
		local files = {}

		extension = extension or ".tpk"

		for filename in lfs.dir(dir) do
			if not filename:find("^%.") and common_endsIn(filename, extension) then
				table.insert(files, filename)
			end
		end

		return files
	end

	local us = common_listFiles(c_const_get("user_absoluteDir"))
	local bs = common_listFiles(c_const_get("base_absoluteDir"))


	tankbobs.fs_setWriteDirectory(c_const_get("user_absoluteDir"))

	local d = tankbobs.fs_getRawDirectorySeparator()

	-- order in which to search for files
	for _, v in pairs(tankbobs.fs_getCDDirectories()) do
		tankbobs.fs_mount(v, "", true)
	end
	tankbobs.fs_mount(c_const_get("user_absoluteDir"), "", true)
	for _, v in pairs(us) do
		tankbobs.fs_mount(c_const_get("user_absoluteDir") .. d .. v, "", true)
	end
	if tankbobs.fs_directoryExists(c_const_get("data_absoluteDir")) then
		tankbobs.fs_mount(c_const_get("data_absoluteDir"), "", true)
	end
	for _, v in pairs(bs) do
		tankbobs.fs_mount(c_const_get("base_absoluteDir") .. d .. v, "", true)
	end

	loadfile = tankbobs.fs_loadfile

	if debug then
		common_print(-1, "Current search path:\n")
		for _, v in pairs(tankbobs.fs_getSearchPath()) do
			common_print(-1, v .. "\n")
		end
		common_print(-1, "End of search path\n")
	end
end

function c_files_done()
	tankbobs.fs_quit()
end

function c_files_configLoaded()
	-- called when configuration had loaded
	tankbobs.fs_permitSymbolicLinks(c_config_get("common.permitSymbolicLinks"))
end
