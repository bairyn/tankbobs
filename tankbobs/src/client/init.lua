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
init.lua

Initialization (and cleanup)
--]]

function init()
	-- execution begins here; the arguments passed are stored in the table 'args'

	server = false
	client = true

	if jit then
		jit.on(true, true)
		assert(jit.compilesub(true, true) == nil)
	end

	-- check submodules
	assert(tankbobs.t_t())
	assert(tankbobs.t_in())
	assert(tankbobs.t_io())
	assert(tankbobs.t_r())
	assert(tankbobs.t_m())
	assert(tankbobs.t_w())
	assert(tankbobs.t_a())
	assert(tankbobs.t_n())
	assert(tankbobs.t_fs())

	common_init()

	main_init()

	renderer_init()

	gui_init()

	game_init()

	main_start()

	game_done()

	gui_done()

	renderer_done()

	main_done()

	common_done()

	if jit then
		jit.off(true, true)
	end
end
