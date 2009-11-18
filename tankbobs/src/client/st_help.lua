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
st_help.lua

game help and information
--]]

local st_help_init
local st_help_done
local st_help_click
local st_help_button
local st_help_mouse
local st_help_step

function st_help_init()
	gui_addAction(tankbobs.m_vec2(25, 75), "Back", nil, c_state_advance)

	gui_addAction(tankbobs.m_vec2(50, 65), "Manual", nil, st_help_manual)
end

function st_help_done()
	gui_finish()
end

function st_help_click(button, pressed, x, y)
	gui_click(button, pressed, x, y)
end

function st_help_button(button, pressed)
	if not gui_button(button, pressed) then
		if pressed then
			if button == 0x1B or button == c_config_get("client.key.quit") then
				c_state_advance()
			elseif button == c_config_get("client.key.exit") then
				c_state_goto(exit_state)
			end
		end
	end
end

function st_help_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

function st_help_step(d)
	gui_paint(d)
end

function st_help_manual()
	c_state_goto(manual_state)
end

function st_help_licensing()
	c_state_goto(license_state)
end

help_state =
{
	name   = "help_state",
	init   = st_help_init,
	done   = st_help_done,
	next   = function () return title_state end,

	click  = st_help_click,
	button = st_help_button,
	mouse  = st_help_mouse,

	main   = st_help_step
}
