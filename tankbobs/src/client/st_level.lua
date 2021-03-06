--[[
Copyright (C) 2008-2010 Byron James Johnson

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

Level selection
--]]

local st_level_init
local st_level_done
local st_level_click
local st_level_button
local st_level_mouse
local st_level_step

local level_description

function st_level_init()
	gui_addAction(tankbobs.m_vec2(25, 92.5), "Back", nil, c_state_advance)

	gui_addLabel(tankbobs.m_vec2(50, 92.5), "Select Level From\n" .. c_tcm_current_set.title, nil, 0.75)

	level_description = gui_addLabel(tankbobs.m_vec2(25, 15), "", nil, 0.3)

	local x, y = 50, 75

	for _, v in pairs(c_tcm_current_set.maps) do
		gui_addAction(tankbobs.m_vec2(x, y), v.title, nil, st_level_select):setSelectedCallback(st_level_levelSelected).m.info = {name = v.name, description = v.description}
		y = y - 5
	end
end

function st_level_done()
	gui_finish()
end

function st_level_click(button, pressed, x, y)
	gui_click(button, pressed, x, y)
end

function st_level_button(button, pressed, str)
	if not gui_button(button, pressed, str) then
		if pressed then
			if button == 0x1B or button == c_config_get("client.key.quit") then
				c_state_advance()
			elseif button == c_config_get("client.key.exit") then
				c_state_goto(exit_state)
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
	c_config_set("game.lastMap", widget.m.info.name)  -- don't load level yet (background can still be running)
	c_state_goto(selected_state)
end

function st_level_levelSelected(widget)
	if widget.m.info then
		level_description:setText(widget.m.info.description)
	end
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
