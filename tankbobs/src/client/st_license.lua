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
st_license.lua

licensing
--]]

function st_license_init()
	gui_widget("active", c_state_advance, renderer_font.sans, 5, 87.5, renderer_size.sans, "Back")
	gui_widget("label", renderer_font.sans, 15, 85, renderer_size.sans * 0.5, "Tankbobs: a simple tank game")
	gui_widget("label", renderer_font.sans, 15, 82.5, renderer_size.sans * 0.5, "Copyright (C) 2008  Byron James Johnson")
	gui_widget("label", renderer_font.sans, 15, 77.5, renderer_size.sans * 0.5, "This program is free software: you can redistribute it and/or modify")
	gui_widget("label", renderer_font.sans, 15, 75, renderer_size.sans * 0.5, "it under the terms of the GNU General Public License as published by")
	gui_widget("label", renderer_font.sans, 15, 72.5, renderer_size.sans * 0.5, "the Free Software Foundation, either version 3 of the License, or")
	gui_widget("label", renderer_font.sans, 15, 70, renderer_size.sans * 0.5, "(at your option) any later version.")
	gui_widget("label", renderer_font.sans, 15, 65, renderer_size.sans * 0.5, "This program is distributed in the hope that it will be useful,")
	gui_widget("label", renderer_font.sans, 15, 62.5, renderer_size.sans * 0.5, "but WITHOUT ANY WARRANTY; without even the implied warranty of")
	gui_widget("label", renderer_font.sans, 15, 60, renderer_size.sans * 0.5, "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the")
	gui_widget("label", renderer_font.sans, 15, 57.5, renderer_size.sans * 0.5, "GNU General Public License for more details.")
	gui_widget("label", renderer_font.sans, 15, 52.5, renderer_size.sans * 0.5, "You should have received a copy of the GNU General Public License")
	gui_widget("label", renderer_font.sans, 15, 50, renderer_size.sans * 0.5, "along with this program.  If not, see <http://www.gnu.org/licenses/>.")
	gui_widget("label", renderer_font.sans, 15, 45, renderer_size.sans, "Also see 'NOTICE'")
end

function st_license_done()
	gui_finish()
end

function st_license_click(button, pressed, x, y)
	gui_click(x, y)
end

function st_license_button(button, pressed)
	if pressed == 1 then
		if button == 0x1B or button == c_config_get("config.key.quit") then
			c_state_advance()
		elseif button == c_config_get("config.key.exit") then
			c_state_new(exit_state)
		end
		gui_button(button)
	end
end

function st_license_mouse(x, y, xrel, yrel)
	gui_mouse(x, y)
end

function st_license_step()
	gui_paint()
end

license_state =
{
	name   = "license_state",
	init   = st_license_init,
	done   = st_license_done,
	next   = function () return help_state end,

	click  = st_license_click,
	button = st_license_button,
	mouse  = st_license_mouse,

	main   = st_license_step
}
