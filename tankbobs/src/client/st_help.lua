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
st_help.lua

game help and information
--]]

function st_help_init()
	gui_action("Back", tankbobs.m_vec2(25, 75), nil, c_state_advance)

	gui_action("Manual", tankbobs.m_vec2(50, 65), nil, st_help_manual)
end

function st_help_done()
	gui_finish()
end

function st_help_click(button, pressed, x, y)
	if pressed then
		gui_click(x, y)
	end
end

function st_help_button(button, pressed)
	if pressed then
		if button == 0x1B or button == c_config_get("config.key.quit") then
			c_state_advance()
		elseif button == c_config_get("config.key.exit") then
			c_state_new(exit_state)
		end
		gui_button(button)
	end
end

function st_help_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

function st_help_step(d)
	gui_paint(d)
end

function st_help_manual()
	c_state_new(manual_state)
end

function st_help_licensing()
	c_state_new(license_state)
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
