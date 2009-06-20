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
st_options.lua

configuration screen
--]]

local st_options_init
local st_options_done
local st_options_click
local st_options_button
local st_options_mouse
local st_options_step

function st_options_init()
	st_options_renderer = {fullscreen = c_config_get("config.renderer.fullscreen"), width = c_config_get("config.renderer.width"), height = c_config_get("config.renderer.height")}
	st_options_player = {}

	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	gui_addLabel(tankbobs.m_vec2(50, 85), "Fullscreen", nil, 0.33) gui_addCycle(tankbobs.m_vec2(75, 85), "Fullscreen", nil, st_options_fullscreen, {"No", "Yes"}, c_config_get("config.renderer.fullscreen") and 2 or 1, 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 81), "Width", nil, 0.33) gui_addInput(tankbobs.m_vec2(75, 81), tostring(c_config_get("config.renderer.width")), nil, st_options_width, true, 4, 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 77), "Height", nil, 0.33) gui_addInput(tankbobs.m_vec2(75, 77), tostring(c_config_get("config.renderer.height")), nil, st_options_height, true, 4, 0.5)
	gui_addAction(tankbobs.m_vec2(50, 73), "Apply", nil, st_options_apply, 0.5)

	gui_addLabel(tankbobs.m_vec2(50, 65), "Pause", nil, 0.33) gui_addKey(tankbobs.m_vec2(75, 65), c_config_get("config.key.pause"), nil, st_options_pause, c_config_get("config.key.pause"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 61), "Back", nil, 0.33) gui_addKey(tankbobs.m_vec2(75, 61), c_config_get("config.key.quit"), nil, st_options_quit, c_config_get("config.key.quit"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 57), "Quit", nil, 0.33) gui_addKey(tankbobs.m_vec2(75, 57), c_config_get("config.key.exit"), nil, st_options_exit, c_config_get("config.key.exit"), 0.5)

	gui_addLabel(tankbobs.m_vec2(50, 49), "Computers", nil, 0.33) gui_addInput(tankbobs.m_vec2(75, 49), tostring(tonumber(c_config_get("config.game.computers"))), nil, st_options_computers, true, 1, 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 45), "Players", nil, 0.33) gui_addInput(tankbobs.m_vec2(75, 45), tostring(tonumber(c_config_get("config.game.players"))), nil, st_options_players, true, 1, 0.5)

	gui_addLabel(tankbobs.m_vec2(50, 38), "Set up player", nil, 0.33) gui_addInput(tankbobs.m_vec2(75, 38), "1", nil, st_options_configurePlayer, true, 1, 0.5)
	if not (c_config_get("config.game.player1.name", nil, true)) then
		c_config_set("config.game.player1.name", "Player1")
	end
	if not (c_config_get("config.key.player1.fire", nil, true)) then
		c_config_set("config.key.player1.fire", false)
	end
	if not (c_config_get("config.key.player1.forward", nil, true)) then
		c_config_set("config.key.player1.forward", false)
	end
	if not (c_config_get("config.key.player1.back", nil, true)) then
		c_config_set("config.key.player1.back", false)
	end
	if not (c_config_get("config.key.player1.left", nil, true)) then
		c_config_set("config.key.player1.left", false)
	end
	if not (c_config_get("config.key.player1.right", nil, true)) then
		c_config_set("config.key.player1.right", false)
	end
	if not (c_config_get("config.key.player1.special", nil, true)) then
		c_config_set("config.key.player1.special", false)
	end
	gui_addLabel(tankbobs.m_vec2(50, 34), "Name", nil, 0.33) st_options_player.name = gui_addInput(tankbobs.m_vec2(75, 34), c_config_get("config.game.player1.name"), nil, st_options_name, false, c_const_get("max_nameLength"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 30), "Fire", nil, 0.33) st_options_player.fire = gui_addKey(tankbobs.m_vec2(75, 30), c_config_get("config.key.player1.fire"), nil, st_options_fire, c_config_get("config.key.player1.fire"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 26), "Forward", nil, 0.33) st_options_player.forward = gui_addKey(tankbobs.m_vec2(75, 26), c_config_get("config.key.player1.forward"), nil, st_options_forward, c_config_get("config.key.player1.special"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 22), "Back", nil, 0.33) st_options_player.back = gui_addKey(tankbobs.m_vec2(75, 22), c_config_get("config.key.player1.back"), nil, st_options_back, c_config_get("config.key.player1.back"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 18), "Left", nil, 0.33) st_options_player.left = gui_addKey(tankbobs.m_vec2(75, 18), c_config_get("config.key.player1.left"), nil, st_options_left, c_config_get("config.key.player1.left"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 14), "Right", nil, 0.33) st_options_player.right = gui_addKey(tankbobs.m_vec2(75, 14), c_config_get("config.key.player1.right"), nil, st_options_right, c_config_get("config.key.player1.right"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 10), "Special", nil, 0.33) st_options_player.special = gui_addKey(tankbobs.m_vec2(75, 10), c_config_get("config.key.player1.special"), nil, st_options_special, c_config_get("config.key.player1.special"), 0.5)
end

function st_options_done()
	gui_finish()

	st_options_renderer = nil
	st_options_player = nil
end

local currentPlayer = 1

function st_options_click(button, pressed, x, y)
	if pressed then
		gui_click(x, y)
	end
end

function st_options_button(button, pressed)
	if not pressed and options_key then
		if button == 0x0D then
		elseif button == 0x1B then
			options_key = nil
		elseif button == 0x08 then
			c_config_set(options_key, "")
			options_key = nil
		else
			c_config_set(options_key, button)
			options_key = nil
		end
	elseif pressed and not options_key then
		if button == c_config_get("config.key.exit") then
			c_state_new(exit_state)
		elseif button == 0x1B or button == c_config_get("config.key.quit") then
			c_state_advance()
		end
		gui_button(button)
	end
end

function st_options_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

function st_options_step(d)
	gui_paint(d)
end

function st_options_apply(widget)
	c_config_set("config.renderer.fullscreen", st_options_renderer.fullscreen)
	c_config_set("config.renderer.width", st_options_renderer.width)
	c_config_set("config.renderer.height", st_options_renderer.height)
	renderer_updateWindow()  -- in case SDL forgets to send a resize signal
	tankbobs.r_newWindow(c_config_get("config.renderer.width"), c_config_get("config.renderer.height"), c_config_get("config.renderer.fullscreen"), c_const_get("title"), c_const_get("icon"))
end

function st_options_fullscreen(widget, string, index)
	if string == "Yes" then
		st_options_renderer.fullscreen = true
	elseif string == "No" then
		st_options_renderer.fullscreen = false
	end
end

function st_options_width(widget)
	st_options_renderer.width = tonumber(widget.inputText)
end

function st_options_height(widget)
	st_options_renderer.height = tonumber(widget.inputText)
end

function st_options_players(widget)
	c_config_set("config.game.players", tonumber(widget.inputText))
end

function st_options_computers(widget)
	c_config_set("config.game.computers", tonumber(widget.inputText))
end

function st_options_configurePlayer(widget)
	currentPlayer = tonumber(widget.inputText) or 1
	if currentPlayer < 1 then
		currentPlayer = 1
	end

	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".name", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".name", "Player" .. tonumber(currentPlayer))
	end
	local name = c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".name")
	st_options_player.name:setText(#name <= c_const_get("max_nameLength") and name or "Player" .. tonumber(currentPlayer))

	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".fire", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".fire", false)
	end
	local fire = c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".fire")
	st_options_player.fire:setKey(fire)

	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".forward", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".forward", false)
	end
	local forward = c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".forward")
	st_options_player.forward:setKey(forward)

	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".back", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".back", false)
	end
	local back = c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".back")
	st_options_player.back:setKey(back)

	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".left", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".left", false)
	end
	local left = c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".left")
	st_options_player.left:setKey(left)

	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".right", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".right", false)
	end
	local right = c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".right")
	st_options_player.right:setKey(right)

	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".special", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".special", false)
	end
	local special = c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".special")
	st_options_player.special:setKey(special)
end

function st_options_name(widget)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".name", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".name", "Player" .. tonumber(currentPlayer))
	end

	c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".name", tostring(widget.inputText))
end

function st_options_fire(widget)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".fire", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".fire", false)
	end

	if widget.key then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".fire", widget.key)
	else
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".fire", false)
	end
end

function st_options_forward(widget)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".forward", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".forward", false)
	end

	if widget.key then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".forward", widget.key)
	else
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".forward", false)
	end
end

function st_options_back(widget)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".back", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".back", false)
	end

	if widget.key then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".back", widget.key)
	else
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".back", false)
	end
end

function st_options_right(widget)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".right", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".right", false)
	end

	if widget.key then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".right", widget.key)
	else
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".right", false)
	end
end

function st_options_left(widget)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".left", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".left", false)
	end

	if widget.key then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".left", widget.key)
	else
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".left", false)
	end
end

function st_options_special(widget)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".special", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".special", false)
	end

	if widget.key then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".special", widget.key)
	else
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".special", false)
	end
end

function st_options_pause(widget)
	if widget.button then
		c_config_set("config.key.pause", widget.button)
	else
		c_config_set("config.key.pause", false)
	end
end

function st_options_exit(widget)
	if widget.button then
		c_config_set("config.key.exit", widget.button)
	else
		c_config_set("config.key.exit", false)
	end
end

function st_options_quit(widget)
	if widget.button then
		c_config_set("config.key.quit", widget.button)
	else
		c_config_set("config.key.quit", false)
	end
end

options_state =
{
	name   = "options_state",
	init   = st_options_init,
	done   = st_options_done,
	next   = function () return title_state end,

	click  = st_options_click,
	button = st_options_button,
	mouse  = st_options_mouse,

	main   = st_options_step
}
