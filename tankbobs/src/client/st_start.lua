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
st_start.lua

temporary state (until a better gui) before play state.
--]]

function st_start_init()
	gui_conserve()
	start_countdowntime = tankbobs.sdlgetticks()
	gui_labelColor(1.0, 0.0, 0.0, 1.0)
	gui_widget("label", renderer_font.sans, 50, 50, renderer_size.sans, start_count)
end

function st_start_done()
	start_countdown = nil
	start_countdowntime = nil
	gui_finish()
end

function st_start_click(button, pressed, x, y)
	if pressed == 1 then
		c_state_advance()
	end
end

function st_start_button(button, pressed)
	if pressed == 1 then
		if button == 0x1B or button == c_config_get("config.key.quit") then
			c_state_advance()
		elseif button == 0x0D or button == c_config_get("config.key.select") then
			c_state_advance()
		elseif button == c_config_get("config.key.exit") then
			c_state_new(exit_state)
		end
	end
end

function st_start_mouse(x, y, xrel, yrel)
end

function st_start_step()
	if tankbobs.sdlgetticks() >= start_countdowntime + 1000 then
		start_countdowntime = tankbobs.sdlgetticks()
		if start_countdown == nil then
			start_countdown = 1
			gui_labelColor(1.0, 1.0, 0.0, 1.0)
		elseif start_countdown == 1 then
			start_countdown = 0
			gui_labelColor(0.0, 1.0, 0.0, 1.0)
		elseif start_countdown == 0 then
			c_state_advance()
		end
	end
	gui_paint()
end

function start_count()
	if start_countdown == 0 then
		return "Go!"
	elseif start_countdown == 1 then
		return "Set"
	elseif start_countdown == nil then
		return "Ready"
	end
	return ""
end

start_state =
{
	name   = "start_state",
	init   = st_start_init,
	done   = st_start_done,
	next   = function () return play_state end,

	click  = st_start_click,
	button = st_start_button,
	mouse  = st_start_mouse,

	main   = st_start_step
}
