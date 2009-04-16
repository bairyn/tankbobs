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

	for i = 1, c_config_get("config.game.players") + c_config_get("config.game.computers") do
		if i > c_const_get("max_tanks") then
			break
		end

		local tank = c_world_tank:new()
		table.insert(c_world_tanks, tank)

		if not (c_config_get("config.game.player" .. tostring(i) .. ".name", nil, true)) then
			c_config_set("config.game.player" .. tostring(i) .. ".name", "Player" .. tostring(i))
		end

		tank.name = c_config_get("config.game.player" .. tostring(i) .. ".name")

		-- spawn
		c_world_tank_spawn(tank)
	end
end

function st_play_done()
	gui_finish()

	c_world_tanks = {}
end

function st_play_click(button, pressed, x, y)
	if pressed then
		gui_click(x, y)
	end
end

function st_play_button(button, pressed)
	if pressed then
		if button == 0x1B or button == c_config_get("config.key.quit") then
			c_state_advance()
		elseif button == c_config_get("config.key.exit") then
			c_state_new(exit_state)
		end
		gui_button(button)
	end

	for i = 1, c_config_get("config.game.players") + c_config_get("config.game.computers") do
		if not (c_config_get("config.key.player" .. tostring(i) .. ".forward", nil, true)) then
			c_config_set("config.key.player" .. tostring(i) .. ".forward", false)
		end
		if not (c_config_get("config.key.player" .. tostring(i) .. ".back", nil, true)) then
			c_config_set("config.key.player" .. tostring(i) .. ".back", false)
		end
		if not (c_config_get("config.key.player" .. tostring(i) .. ".right", nil, true)) then
			c_config_set("config.key.player" .. tostring(i) .. ".right", false)
		end
		if not (c_config_get("config.key.player" .. tostring(i) .. ".left", nil, true)) then
			c_config_set("config.key.player" .. tostring(i) .. ".left", false)
		end
		if not (c_config_get("config.key.player" .. tostring(i) .. ".special", nil, true)) then
			c_config_set("config.key.player" .. tostring(i) .. ".special", false)
		end

		if button == c_config_get("config.key.player" .. tostring(i) .. ".forward") then
print("forward", pressed)
			c_world_tanks[i].state.forward = pressed
		end
		if button == c_config_get("config.key.player" .. tostring(i) .. ".back") then
print("back", pressed)
			c_world_tanks[i].state.back = pressed
		end
		if button == c_config_get("config.key.player" .. tostring(i) .. ".left") then
print("left", pressed)
			c_world_tanks[i].state.left = pressed
		end
		if button == c_config_get("config.key.player" .. tostring(i) .. ".right") then
print("right", pressed)
			c_world_tanks[i].state.right = pressed
		end
		if button == c_config_get("config.key.player" .. tostring(i) .. ".special") then
print("special", pressed)
			c_world_tanks[i].state.special = pressed
		end
	end
end

function st_play_mouse(x, y, xrel, yrel)
	gui_mouse(x, y)
end

function st_play_step()
	-- TODO: use display lists and find a better algorithm for "depth"

	c_world_step()

	-- iterate each time from 1 to hard-coded 20 but render tanks before level 9
	for i = 1, 20 do
		for k, v in pairs(c_tcm_current_map.walls) do
			if i == c_const_get("tcm_tankLevel") then
				-- render tanks
				-- TMP: aoeu
				for k, v in pairs(c_world_tanks) do
					if(v.exists) then
						gl.PushMatrix()
							gl.Translate(v.p[1].x, v.p[1].y, 0)
							gl.Rotate(v.r, 0, 0, 1)
							gl.Begin("QUADS")
								gl.Vertex(v.h[1].x, v.h[1].y)
								gl.Vertex(v.h[2].x, v.h[2].y)
								gl.Vertex(v.h[3].x, v.h[3].y)
								gl.Vertex(v.h[4].x, v.h[4].y)
							gl.End()
						gl.PopMatrix()
					end
				end
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
