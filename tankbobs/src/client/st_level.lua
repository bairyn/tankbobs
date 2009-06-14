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
	gui_addAction(tankbobs.m_vec2(25, 92.5), "Back", nil, c_state_advance)

	gui_addLabel(tankbobs.m_vec2(50, 92.5), "Select Level From\n" .. c_tcm_current_set.title, nil, 0.75)

	local x, y = 50, 75
	for _, v in pairs(c_tcm_current_set.maps) do
		gui_addAction(tankbobs.m_vec2(x, y), v.title, nil, st_level_select).misc.name = v.name
		y = y - 5
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
		if not gui_button(button) then
			if button == 0x1B or button == c_config_get("config.key.quit") then
				c_state_advance()
			elseif button == c_config_get("config.key.exit") then
				c_state_new(exit_state)
			end
		end
	end
end

function st_level_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

function st_level_step(d)
	gui_paint(d)
end

function st_level_select(widget)
	c_tcm_select_map(widget.misc.name)
	c_state_new(play_state)
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
