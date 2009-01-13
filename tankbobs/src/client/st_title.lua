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
	gui_widget("label", renderer_font.sans, 50, 75, renderer_size.sans, "Main Menu")
	gui_widget("active", st_title_play, renderer_font.sans, 50, 70, renderer_size.sans, "Play")
	gui_widget("active", st_title_options, renderer_font.sans, 50, 67.5, renderer_size.sans, "Options")
	gui_widget("active", st_title_help, renderer_font.sans, 50, 65, renderer_size.sans, "Help")
	gui_widget("active", c_state_advance, renderer_font.sans, 50, 62.5, renderer_size.sans, "Exit")
end

function st_title_done()
	gui_finish()
end

function st_title_click(button, pressed, x, y)
	gui_click(x, y)
end

function st_title_button(button, pressed)
	if pressed == 1 then
		if button == 0x1B or button == c_config_get("config.key.exit") or button == c_config_get("config.key.quit") then
			c_state_advance()
		end
		gui_button(button)
	end
end

function st_title_mouse(x, y, xrel, yrel)
	gui_mouse(x, y)
end

function st_title_step()
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
