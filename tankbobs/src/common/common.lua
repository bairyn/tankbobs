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
common.lua

common lua functions
--]]

function common_nil(...)
	return ...
end

function common_init()
	require "tankbobs"
	tankbobs.t_initialize(client and not server);

	c_const_init()

	c_data_init()

	c_module_init()

	c_config_init()

	c_mods_init()  -- anything below this is moddable

	c_state_init()

	c_tcm_init()
end

function common_done()
	c_tcm_done()

	c_state_done()

	c_mods_done()

	c_config_done()

	c_module_done()

	c_data_done()

	c_const_done()

	tankbobs.t_quit()
end
