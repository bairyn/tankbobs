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

options
--]]

local st_options_click
local st_options_button
local st_options_mouse
local st_options_step

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

local st_optionsAudio_init
local st_optionsAudio_done

function st_optionsAudio_init()
	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)
end

function st_optionsAudio_done()
	gui_finish()
end

optionsAudio_state =
{
	name   = "optionsAudio_state",
	init   = st_optionsAudio_init,
	done   = st_optionsAudio_done,
	next   = function () return options_state end,

	click  = st_options_click,
	button = st_options_button,
	mouse  = st_options_mouse,

	main   = st_options_step
}

local st_optionsVideo_init
local st_optionsVideo_done

local st_optionsVideo_renderer

local st_optionsVideo_fullscreen
local st_optionsVideo_width
local st_optionsVideo_height
local st_optionsVideo_apply

function st_optionsVideo_fullscreen(widget, string, index)
	if string == "Yes" then
		st_optionsVideo_renderer.fullscreen = true
	elseif string == "No" then
		st_optionsVideo_renderer.fullscreen = false
	end
end

function st_optionsVideo_width(widget)
	st_optionsVideo_renderer.width = tonumber(widget.inputText)
end

function st_optionsVideo_height(widget)
	st_optionsVideo_renderer.height = tonumber(widget.inputText)
end

function st_optionsVideo_apply(widget)
	if c_config_get("config.renderer.fullscreen") ~= st_optionsVideo_renderer.fullscreen or c_config_get("config.renderer.width") ~= st_optionsVideo_renderer.width or c_config_get("config.renderer.height") ~= st_optionsVideo_renderer.height then
		c_config_set("config.renderer.fullscreen", st_optionsVideo_renderer.fullscreen)
		c_config_set("config.renderer.width", st_optionsVideo_renderer.width)
		c_config_set("config.renderer.height", st_optionsVideo_renderer.height)
		renderer_updateWindow()  -- in case SDL forgets to send a resize signal
		tankbobs.r_newWindow(c_config_get("config.renderer.width"), c_config_get("config.renderer.height"), c_config_get("config.renderer.fullscreen"), c_const_get("title"), c_const_get("icon"))
	end
end

function st_optionsVideo_init()
	st_optionsVideo_renderer = {fullscreen = c_config_get("config.renderer.fullscreen"), width = c_config_get("config.renderer.width"), height = c_config_get("config.renderer.height")}

	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	gui_addLabel(tankbobs.m_vec2(50, 75), "Fullscreen", nil, 2 / 3) gui_addCycle(tankbobs.m_vec2(75, 75), "Fullscreen", nil, st_optionsVideo_fullscreen, {"No", "Yes"}, c_config_get("config.renderer.fullscreen") and 2 or 1)
	gui_addLabel(tankbobs.m_vec2(50, 69), "Width", nil, 2 / 3) gui_addInput(tankbobs.m_vec2(75, 69), tostring(c_config_get("config.renderer.width")), nil, st_optionsVideo_width, true, 5)
	gui_addLabel(tankbobs.m_vec2(50, 63), "Height", nil, 2 / 3) gui_addInput(tankbobs.m_vec2(75, 63), tostring(c_config_get("config.renderer.height")), nil, st_optionsVideo_height, true, 5)
	gui_addAction(tankbobs.m_vec2(75, 57), "Apply", nil, st_optionsVideo_apply)
end

function st_optionsVideo_done()
	gui_finish()

	st_optionsVideo_renderer = nil
end

optionsVideo_state =
{
	name   = "optionsVideo_state",
	init   = st_optionsVideo_init,
	done   = st_optionsVideo_done,
	next   = function () return options_state end,

	click  = st_options_click,
	button = st_options_button,
	mouse  = st_options_mouse,

	main   = st_options_step
}

local st_optionsPlayers_init
local st_optionsPlayers_done

local st_optionsPlayers_configurePlayer
local st_optionsPlayers_computers
local st_optionsPlayers_players
local st_optionsPlayers_name
local st_optionsPlayers_fire
local st_optionsPlayers_forward
local st_optionsPlayers_back
local st_optionsPlayers_left
local st_optionsPlayers_right
local st_optionsPlayers_special

local currentPlayer = 1
local player

function st_optionsPlayers_configurePlayer(widget)
	currentPlayer = tonumber(widget.inputText) or 1
	if currentPlayer < 1 then
		currentPlayer = 1
	end

	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".name", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".name", "Player" .. tonumber(currentPlayer))
	end
	local name = c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".name")
	player.name:setText(#name <= c_const_get("max_nameLength") and name or "Player" .. tonumber(currentPlayer))

	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".fire", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".fire", false)
	end
	local fire = c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".fire")
	player.fire:setKey(fire)

	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".forward", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".forward", false)
	end
	local forward = c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".forward")
	player.forward:setKey(forward)

	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".back", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".back", false)
	end
	local back = c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".back")
	player.back:setKey(back)

	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".left", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".left", false)
	end
	local left = c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".left")
	player.left:setKey(left)

	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".right", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".right", false)
	end
	local right = c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".right")
	player.right:setKey(right)

	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".special", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".special", false)
	end
	local special = c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".special")
	player.special:setKey(special)
end

function st_optionsPlayers_computers(widget)
	c_config_set("config.game.computers", tonumber(widget.inputText))
end

function st_optionsPlayers_players(widget)
	c_config_set("config.game.players", tonumber(widget.inputText))
end

function st_optionsPlayers_name(widget)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".name", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".name", "Player" .. tonumber(currentPlayer))
	end

	c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".name", tostring(widget.inputText))
end

function st_optionsPlayers_fire(widget)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".fire", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".fire", false)
	end

	if widget.button then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".fire", widget.button)
	else
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".fire", false)
	end
end

function st_optionsPlayers_forward(widget)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".forward", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".forward", false)
	end

	if widget.button then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".forward", widget.button)
	else
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".forward", false)
	end
end

function st_optionsPlayers_right(widget)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".right", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".right", false)
	end

	if widget.button then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".right", widget.button)
	else
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".right", false)
	end
end

function st_optionsPlayers_back(widget)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".back", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".back", false)
	end

	if widget.button then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".back", widget.button)
	else
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".back", false)
	end
end

function st_optionsPlayers_left(widget)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".left", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".left", false)
	end

	if widget.button then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".left", widget.button)
	else
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".left", false)
	end
end

function st_optionsPlayers_special(widget)
print(widget, widget.table)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".special", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".special", false)
	end

	if widget.button then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".special", widget.button)
	else
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".special", false)
	end
end

function st_optionsPlayers_init()
	player = {}

	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	gui_addLabel(tankbobs.m_vec2(50, 75), "Computers", nil, 1 / 3) gui_addInput(tankbobs.m_vec2(75, 75), tostring(tonumber(c_config_get("config.game.computers"))), nil, st_optionsPlayers_computers, true, 1, 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 72), "Players", nil, 1 / 3) gui_addInput(tankbobs.m_vec2(75, 72), tostring(tonumber(c_config_get("config.game.players"))), nil, st_optionsPlayers_players, true, 1, 0.5)

	gui_addLabel(tankbobs.m_vec2(50, 69), "Set up player", nil, 1 / 3) gui_addInput(tankbobs.m_vec2(75, 69), "1", nil, st_optionsPlayers_configurePlayer, true, 1, 0.5)
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
	gui_addLabel(tankbobs.m_vec2(50, 66), "Name", nil, 1 / 3) player.name = gui_addInput(tankbobs.m_vec2(75, 66), c_config_get("config.game.player1.name"), nil, st_optionsPlayers_name, false, c_const_get("max_nameLength"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 63), "Fire", nil, 1 / 3) player.fire = gui_addKey(tankbobs.m_vec2(75, 63), c_config_get("config.key.player1.fire"), nil, st_optionsPlayers_fire, c_config_get("config.key.player1.fire"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 60), "Forward", nil, 1 / 3) player.forward = gui_addKey(tankbobs.m_vec2(75, 60), c_config_get("config.key.player1.forward"), nil, st_optionsPlayers_forward, c_config_get("config.key.player1.special"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 57), "Back", nil, 1 / 3) player.back = gui_addKey(tankbobs.m_vec2(75, 57), c_config_get("config.key.player1.back"), nil, st_optionsPlayers_back, c_config_get("config.key.player1.back"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 54), "Left", nil, 1 / 3) player.left = gui_addKey(tankbobs.m_vec2(75, 54), c_config_get("config.key.player1.left"), nil, st_optionsPlayers_left, c_config_get("config.key.player1.left"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 51), "Right", nil, 1 / 3) player.right = gui_addKey(tankbobs.m_vec2(75, 51), c_config_get("config.key.player1.right"), nil, st_optionsPlayers_right, c_config_get("config.key.player1.right"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 48), "Special", nil, 1 / 3) player.special = gui_addKey(tankbobs.m_vec2(75, 48), c_config_get("config.key.player1.special"), nil, st_optionsPlayers_special, c_config_get("config.key.player1.special"), 0.5)
end

function st_optionsPlayers_done()
	gui_finish()

	currentPlayer = 1
	player = nil
end

optionsPlayers_state =
{
	name   = "optionsPlayers_state",
	init   = st_optionsPlayers_init,
	done   = st_optionsPlayers_done,
	next   = function () return options_state end,

	click  = st_options_click,
	button = st_options_button,
	mouse  = st_options_mouse,

	main   = st_options_step
}

local optionsControls_init
local optionsControls_done

local st_optionsControls_pause
local st_optionsControls_exit
local st_optionsControls_quit

function st_optionsControls_pause(widget)
	if widget.button then
		c_config_set("config.key.pause", widget.button)
	else
		c_config_set("config.key.pause", false)
	end
end

function st_optionsControls_exit(widget)
	if widget.button then
		c_config_set("config.key.exit", widget.button)
	else
		c_config_set("config.key.exit", false)
	end
end

function st_optionsControls_quit(widget)
	if widget.button then
		c_config_set("config.key.quit", widget.button)
	else
		c_config_set("config.key.quit", false)
	end
end

function st_optionsControls_init()
	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	gui_addLabel(tankbobs.m_vec2(50, 65), "Pause", nil, 2 / 3) gui_addKey(tankbobs.m_vec2(75, 65), c_config_get("config.key.pause"), nil, st_optionsControls_pause, c_config_get("config.key.pause"))
	gui_addLabel(tankbobs.m_vec2(50, 59), "Back", nil, 2 / 3) gui_addKey(tankbobs.m_vec2(75, 59), c_config_get("config.key.quit"), nil, st_optionsControls_quit, c_config_get("config.key.quit"))
	gui_addLabel(tankbobs.m_vec2(50, 54), "Quit", nil, 2 / 3) gui_addKey(tankbobs.m_vec2(75, 54), c_config_get("config.key.exit"), nil, st_optionsControls_exit, c_config_get("config.key.exit"))
end

function st_optionsControls_done()
	gui_finish()
end

optionsControls_state =
{
	name   = "optionsControls_state",
	init   = st_optionsControls_init,
	done   = st_optionsControls_done,
	next   = function () return options_state end,

	click  = st_options_click,
	button = st_options_button,
	mouse  = st_options_mouse,

	main   = st_options_step
}

local st_optionsInternet_init
local st_optionsInternet_done

function st_optionsInternet_init()
	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)
end

function st_optionsInternet_done()
	gui_finish()
end

optionsInternet_state =
{
	name   = "optionsInternet_state",
	init   = st_optionsInternet_init,
	done   = st_optionsInternet_done,
	next   = function () return options_state end,

	click  = st_options_click,
	button = st_options_button,
	mouse  = st_options_mouse,

	main   = st_options_step
}

local st_options_init
local st_options_done

local st_options_video
local st_options_audio
local st_options_players
local st_options_controls
local st_options_internet

function st_options_init()
	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	gui_addAction(tankbobs.m_vec2(50, 75), "Audio", nil, st_options_audio)
	gui_addAction(tankbobs.m_vec2(50, 69), "Video", nil, st_options_video)
	gui_addAction(tankbobs.m_vec2(50, 63), "Players", nil, st_options_players)
	gui_addAction(tankbobs.m_vec2(50, 57), "Controls", nil, st_options_controls)
	gui_addAction(tankbobs.m_vec2(50, 51), "Internet", nil, st_options_internet)
end

function st_options_done()
	gui_finish()
end

function st_options_video()
	c_state_new(optionsVideo_state)
end

function st_options_audio()
	c_state_new(optionsAudio_state)
end

function st_options_players()
	c_state_new(optionsPlayers_state)
end

function st_options_controls()
	c_state_new(optionsControls_state)
end

function st_options_internet()
	c_state_new(optionsInternet_state)
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
