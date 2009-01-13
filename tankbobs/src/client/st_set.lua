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
st_set.lua

set selection
--]]

function st_set_init()
	gui_widget("label", renderer_font.sans, 50, 92.5, renderer_size.sans, "Select Level Set")
	gui_widget("active", c_state_advance, renderer_font.sans, 25, 87.5, renderer_size.sans, "Back")
	tcm_headers()
	local x, y = 50, 85
	for id, _, _, title in tcm_setsi() do
		gui_widget("active", st_set_select, renderer_font.sans, x, y, renderer_size.sans, title, id)
		y = y - 2.5
	end
end

function st_set_done()
	gui_finish()
end

function st_set_click(button, pressed, x, y)
	gui_click(x, y)
end

function st_set_button(button, pressed)
	if pressed == 1 then
		if button == 0x1B or button == config_get("config.key.quit") then
			c_state_advance()
		elseif button == config_get("config.key.exit") then
			c_state_new(exit_state)
		end
		gui_button(button)
	end
end

function st_set_mouse(x, y, xrel, yrel)
	gui_mouse(x, y)
end

function st_set_step()
	gui_paint()
end

function st_set_select(title, id)
	main_data.set_title = title
	tcm_levels(id)
	c_state_new(level_state)
end

set_state =
{
	name   = "set_state",
	init   = st_set_init,
	done   = st_set_done,
	next   = function () return title_state end,

	click  = st_set_click,
	button = st_set_button,
	mouse  = st_set_mouse,

	main   = st_set_step
}
