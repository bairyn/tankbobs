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
st_exit.lua

for exiting
--]]

function st_exit_init()
	done = true
end

exit_state =
{
	name   = "exit_state",
	init   = st_exit_init,
	done   = st_exit_init,
	next   = st_exit_init,

	click  = st_exit_init,
	button = st_exit_init,
	mouse  = st_exit_init,

	main   = st_exit_init
}
