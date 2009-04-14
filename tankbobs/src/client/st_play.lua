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
st_play.lua

main play state
--]]

function st_play_init()
	gui_conserve()
end

function st_play_done()
	gui_finish()
end

function st_play_click(button, pressed, x, y)
	gui_click(x, y)
end

function st_play_button(button, pressed)
	if pressed == 1 then
		if button == 0x1B or button == c_config_get("config.key.quit") then
			c_state_advance()
		elseif button == c_config_get("config.key.exit") then
			c_state_new(exit_state)
		end
		gui_button(button)
	end
end

function st_play_mouse(x, y, xrel, yrel)
	gui_mouse(x, y)
end

function st_play_step()
	-- TODO: use display lists and find a better algorithm for "depth"

	-- iterate each time from 1 to hard-coded 20 but render tanks before level 9
	for i = 1, 20 do
		for k, v in pairs(c_tcm_current_map.walls) do
			if i == c_const_get("tcm_tankLevel") then
				-- render tanks
			end

			if v.l == i then
				if v.q then
					gl.Begin("QUADS")
				else
					gl.Begin("TRIANGLES")
				end
					gl.Vertex(v.p[1].x, v.p[1].y)
					gl.Vertex(v.p[2].x, v.p[2].y)
					gl.Vertex(v.p[3].x, v.p[3].y)
					if v.q then
						gl.Vertex(v.p[4].x, v.p[4].y)
					end
				gl.End()
			end
		end
	end
	
	gui_paint()
end

play_state =
{
	name   = "play_state",
	init   = st_play_init,
	done   = st_play_done,
	next   = function () return title_state end,

	click  = st_play_click,
	button = st_play_button,
	mouse  = st_play_mouse,

	main   = st_play_step
}
