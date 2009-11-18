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
st_manual.lua

game rules
--]]

local st_manual_init
local st_manual_done
local st_manual_click
local st_manual_button
local st_manual_mouse
local st_manual_step

function st_manual_init()
	gui_addAction(tankbobs.m_vec2(25, 75), "Back", nil, c_state_advance)

	gui_addLabel(tankbobs.m_vec2(50, 65), "Tankbobs", nil, 1/3)
end

function st_manual_done()
	gui_finish()
end

function st_manual_click(button, pressed, x, y)
	gui_click(button, pressed, x, y)
end

function st_manual_button(button, pressed)
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
