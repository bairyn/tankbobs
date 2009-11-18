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
st_set.lua

Set selection
--]]

local st_set_init
local st_set_done
local st_set_click
local st_set_button
local st_set_mouse
local st_set_step

local st_set_setSelected
local st_set_select
local set_description

function st_set_init()
	gui_addAction(tankbobs.m_vec2(25, 92.5), "Back", nil, c_state_advance)

	gui_addLabel(tankbobs.m_vec2(50, 92.5), "Select Level Set", nil, 0.75)

	set_description = gui_addLabel(tankbobs.m_vec2(25, 15), "", nil, 0.3)

	local x, y = 50, 85

	for _, v in pairs(c_tcm_current_sets) do
		gui_addAction(tankbobs.m_vec2(x, y), v.title, nil, st_set_select):setSelectedCallback(st_set_setSelected).m.info = {name = v.name, description = v.description}

		y = y - 5
	end
end

function st_set_done()
	gui_finish()
end

function st_set_click(button, pressed, x, y)
	gui_click(button, pressed, x, y)
end

function st_set_button(button, pressed)
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

function st_set_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

function st_set_step(d)
	gui_paint(d)
end

function st_set_select(widget)
	c_tcm_select_set(widget.m.info.name)
	c_state_goto(level_state)
end

function st_set_setSelected(widget)
	if widget.m.info then
		set_description:setText(widget.m.info.description)
	end
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
