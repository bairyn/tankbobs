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
st_title.lua

title screen
--]]

function st_title_init()
	gui_label("Main Menu", tankbobs.m_vec2(50, 75))
	gui_action("Play", tankbobs.m_vec2(50, 70), nil, st_title_play)
	gui_action("Options", tankbobs.m_vec2(50, 67.5), nil, st_title_options)
	gui_action("Help", tankbobs.m_vec2(50, 65), nil, st_title_help)
	gui_action("Exit", tankbobs.m_vec2(50, 62.5), nil, c_state_advance)
end

function st_title_done()
	gui_finish()
end

function st_title_click(button, pressed, x, y)
	if pressed then
		gui_click(x, y)
	end
end

function st_title_button(button, pressed)
	if pressed then
		if button == 0x1B or button == c_config_get("config.key.exit") or button == c_config_get("config.key.quit") then
			c_state_advance()
		end
		gui_button(button)
	end
end

function st_title_mouse(x, y, xrel, yrel)
	gui_mouse(x, y)
end

function st_title_step(d)
	gui_paint()
end

function st_title_play()
	c_state_new(set_state)
end

function st_title_options()
	c_state_new(options_state)
end

function st_title_help()
	c_state_new(help_state)
end

title_state =
{
	name   = "title_state",
	init   = st_title_init,
	done   = st_title_done,
	next   = function () return exit_state end,

	click  = st_title_click,
	button = st_title_button,
	mouse  = st_title_mouse,

	main   = st_title_step
}
