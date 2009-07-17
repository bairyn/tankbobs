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
st_title.lua

title screen
--]]

local st_title_init
local st_title_done
local st_title_click
local st_title_button
local st_title_mouse
local st_title_step

local init = false
function st_title_init()
	if not init then
		-- ungrab mouse on init
		tankbobs.in_grabMouse(c_config_get("client.renderer.width") / 2, c_config_get("client.renderer.height") / 2)
		tankbobs.in_grabClear()
	end
	init = true

	gui_addLabel (tankbobs.m_vec2(50, 75), "Main Menu")

	gui_addAction(tankbobs.m_vec2(50, 65), "Play",    nil, st_title_play)
	gui_addAction(tankbobs.m_vec2(50, 59), "Online",  nil, st_title_internet)
	gui_addAction(tankbobs.m_vec2(50, 53), "Options", nil, st_title_options)
	gui_addAction(tankbobs.m_vec2(50, 47), "Help",    nil, st_title_help)
	gui_addAction(tankbobs.m_vec2(50, 41), "Exit",    nil, c_state_advance)
end

function st_title_done()
	gui_finish()
end

function st_title_click(button, pressed, x, y)
	gui_click(button, pressed, x, y)
end

function st_title_button(button, pressed)
	if not gui_button(button, pressed) then
		if pressed then
			if button == 0x1B or button == c_config_get("client.key.exit") or button == c_config_get("client.key.quit") then
				c_state_advance()
			end
		end
	end
end

function st_title_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

function st_title_step(d)
	gui_paint(d)
end

function st_title_play()
	c_state_new(set_state)
end

function st_title_internet()
	c_state_new(internet_state)
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
