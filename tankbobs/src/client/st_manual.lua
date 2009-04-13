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
st_manual.lua

game rules
--]]

function st_manual_init()
	gui_widget("active", c_state_advance, renderer_font.sans, 25, 87.5, renderer_size.sans, "Back")
	gui_widget("label", renderer_font.sans, 50, 85, renderer_size.sans, "Tankbobs")
	gui_widget("label", renderer_font.sans, 50, 82.5, renderer_size.sans, "Tankbobs is a simple 2d player on player tank game")
	gui_widget("label", renderer_font.sans, 50, 80, renderer_size.sans, "Rules are not yet")
end

function st_manual_done()
	gui_finish()
end

function st_manual_click(button, pressed, x, y)
	gui_click(x, y)
end

function st_manual_button(button, pressed)
	if pressed == 1 then
		if button == 0x1B or button == c_config_get("config.key.quit") then
			c_state_advance()
		elseif button == c_config_get("config.key.exit") then
			c_state_new(exit_state)
		end
		gui_button(button)
	end
end

function st_manual_mouse(x, y, xrel, yrel)
	gui_mouse(x, y)
end

function st_manual_step()
	gui_paint()
end

manual_state =
{
	name   = "manual_state",
	init   = st_manual_init,
	done   = st_manual_done,
	next   = function () return help_state end,

	click  = st_manual_click,
	button = st_manual_button,
	mouse  = st_manual_mouse,

	main   = st_manual_step
}
