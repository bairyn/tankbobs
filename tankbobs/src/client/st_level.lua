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
st_level.lua

level selection
--]]

function st_level_init()
	gui_widget("label", renderer_font.sans, 50, 92.5, renderer_size.sans, "Select Level From " .. c_tcm_current_set.title)
	gui_widget("active", c_state_advance, renderer_font.sans, 25, 87.5, renderer_size.sans, "Back")
	local x, y = 50, 85
	for _, v in pairs(c_tcm_current_set.maps) do
		gui_widget("active", st_level_select, renderer_font.sans, x, y, renderer_size.sans, v.title, v.name)
		y = y - 2.5
	end
end

function st_level_done()
	gui_finish()
end

function st_level_click(button, pressed, x, y)
	if pressed then
		gui_click(x, y)
	end
end

function st_level_button(button, pressed)
	if pressed then
		if button == 0x1B or button == c_config_get("config.key.quit") then
			c_state_advance()
		elseif button == c_config_get("config.key.exit") then
			c_state_new(exit_state)
		end
		gui_button(button)
	end
end

function st_level_mouse(x, y, xrel, yrel)
	gui_mouse(x, y)
end

function st_level_step(d)
	gui_paint()
end

function st_level_select(title, name)
	c_tcm_select_map(name)
	c_state_new(start_state)
end

level_state =
{
	name   = "level_state",
	init   = st_level_init,
	done   = st_level_done,
	next   = function () return set_state end,

	click  = st_level_click,
	button = st_level_button,
	mouse  = st_level_mouse,

	main   = st_level_step
}
