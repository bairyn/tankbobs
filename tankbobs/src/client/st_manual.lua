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
	gui_action("Back", tankbobs.m_vec2(25, 75), nil, c_state_advance)

	gui_label("Tankbobs", tankbobs.m_vec2(50, 65))

	gui_label("Tankbobs is a 2D shooter game.", tankbobs.m_vec2(50, 55))
	gui_label("Your objective is to get the most kills.", tankbobs.m_vec2(50, 65))
end

function st_manual_done()
	gui_finish()
end

function st_manual_click(button, pressed, x, y)
	if pressed then
		gui_click(x, y)
	end
end

function st_manual_button(button, pressed)
	if pressed then
		if button == 0x1B or button == c_config_get("config.key.quit") then
			c_state_advance()
		elseif button == c_config_get("config.key.exit") then
			c_state_new(exit_state)
		end
		gui_button(button)
	end
end

function st_manual_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

function st_manual_step(d)
	gui_paint(d)
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
