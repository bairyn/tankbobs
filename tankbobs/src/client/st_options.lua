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

local gl
local c_const_get
local c_const_set
local c_config_get
local c_config_set
local tank_listBase

local st_options_click
local st_options_button
local st_options_mouse
local st_options_step

function st_options_click(button, pressed, x, y)
	gui_click(button, pressed, x, y)
end

function st_options_button(button, pressed)
	if not gui_button(button, pressed) then
		if pressed then
			if button == c_config_get("config.key.exit") then
				c_state_new(exit_state)
			elseif button == 0x1B or button == c_config_get("config.key.quit") then
				c_state_advance()
			end
		end
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

local st_optionsAudio_volume
local st_optionsAudio_musicVolume
local st_optionsAudio_chunkSize

function st_optionsAudio_init()
	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	gui_addLabel(tankbobs.m_vec2(50, 75), "Volume", nil, 2 / 3)

	gui_addLabel(tankbobs.m_vec2(50, 57), "Volume", nil, 2 / 3) gui_addScale(tankbobs.m_vec2(75, 57), "Volume", nil, st_optionsAudio_volume, c_config_get("config.client.volume"))
	gui_addLabel(tankbobs.m_vec2(50, 51), "Music", nil, 2 / 3) gui_addScale(tankbobs.m_vec2(75, 51), "Music", nil, st_optionsAudio_musicVolume, c_config_get("config.client.musicVolume"))

	local pos = 0
	local buf = c_config_get("config.client.audioChunkSize")
	if buf == 1024 then
		pos = 1
	elseif buf == 3072 then
		pos = 2
	elseif buf == 4096 then
		pos = 3
	end

	gui_addLabel(tankbobs.m_vec2(50, 39), "Chunk Size", nil, 2 / 3) gui_addCycle(tankbobs.m_vec2(75, 39), "Chunk Size", nil, st_optionsAudio_chunkSize, {"Low", "Medium", "High"}, pos, 2 / 3)
	gui_addLabel(tankbobs.m_vec2(50, 36), "(Restart to take effect to chunk size)", nil, 1 / 3)
end

function st_optionsAudio_done()
	gui_finish()
end

function st_optionsAudio_volume(widget, pos)
	c_config_set("config.client.volume", pos)
	tankbobs.a_setVolume(pos)
end

function st_optionsAudio_musicVolume(widget, pos)
	c_config_set("config.client.musicVolume", pos)
	tankbobs.a_setMusicVolume(pos)
end

function st_optionsAudio_chunkSize(widget, string, index)
	if string == "High" then
		c_config_set("config.client.audioChunkSize", 4096)
	elseif string == "Medium" then
		c_config_set("config.client.audioChunkSize", 3072)
	elseif string == "Low" then
		c_config_set("config.client.audioChunkSize", 1024)
	end
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
local st_optionsVideo_fpsCounter

function st_optionsVideo_init()
	st_optionsVideo_renderer = {fullscreen = c_config_get("config.renderer.fullscreen"), width = c_config_get("config.renderer.width"), height = c_config_get("config.renderer.height")}

	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	gui_addLabel(tankbobs.m_vec2(50, 75), "Fullscreen", nil, 2 / 3) gui_addCycle(tankbobs.m_vec2(75, 75), "Fullscreen", nil, st_optionsVideo_fullscreen, {"No", "Yes"}, c_config_get("config.renderer.fullscreen") and 2 or 1)
	gui_addLabel(tankbobs.m_vec2(50, 69), "Width", nil, 2 / 3) gui_addInput(tankbobs.m_vec2(75, 69), tostring(c_config_get("config.renderer.width")), nil, st_optionsVideo_width, true, 5)
	gui_addLabel(tankbobs.m_vec2(50, 63), "Height", nil, 2 / 3) gui_addInput(tankbobs.m_vec2(75, 63), tostring(c_config_get("config.renderer.height")), nil, st_optionsVideo_height, true, 5)
	gui_addAction(tankbobs.m_vec2(75, 57), "Apply", nil, st_optionsVideo_apply)

	gui_addLabel(tankbobs.m_vec2(50, 45), "FPS Counter", nil, 2 / 4) gui_addCycle(tankbobs.m_vec2(75, 45), "FPS Counter", nil, st_optionsVideo_fpsCounter, {"No", "Yes"}, c_config_get("config.game.fpsCounter") and 2 or 1)  -- Label needs to be a bit smaller
end

function st_optionsVideo_done()
	gui_finish()

	st_optionsVideo_renderer = nil
end

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

function st_optionsVideo_fpsCounter(widget, string, index)
	if string == "Yes" then
		c_config_set("config.game.fpsCounter", true)
	elseif string == "No" then
		c_config_set("config.game.fpsCounter", false)
	end
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
local st_optionsPlayers_step

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
local st_optionsPlayers_colorR
local st_optionsPlayers_colorG
local st_optionsPlayers_colorB

local currentPlayer = 1
local player

function st_optionsPlayers_init()
	currentPlayer = 1
	player = {}

	c_const_set("optionsPlayers_tankRotation", -math.pi / 2, -1)

	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	gui_addLabel(tankbobs.m_vec2(50, 75), "Computers", nil, 1 / 3) gui_addInput(tankbobs.m_vec2(75, 75), tostring(tonumber(c_config_get("config.game.computers"))), nil, st_optionsPlayers_computers, true, 1, 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 72), "Players", nil, 1 / 3) gui_addInput(tankbobs.m_vec2(75, 72), tostring(tonumber(c_config_get("config.game.players"))), nil, st_optionsPlayers_players, true, 1, 0.5)

	gui_addLabel(tankbobs.m_vec2(50, 66), "Set up player", nil, 1 / 3) gui_addInput(tankbobs.m_vec2(75, 66), "1", nil, st_optionsPlayers_configurePlayer, true, 1, 0.5)
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
	if not (c_config_get("config.game.player1.color.r", nil, true)) then
		c_config_set("config.game.player1.color.r", c_config_get("config.game.defaultTankRed"))
	end
	if not (c_config_get("config.game.player1.color.g", nil, true)) then
		c_config_set("config.game.player1.color.g", c_config_get("config.game.defaultTankGreen"))
	end
	if not (c_config_get("config.game.player1.color.b", nil, true)) then
		c_config_set("config.game.player1.color.b", c_config_get("config.game.defaultTankBlue"))
	end
	gui_addLabel(tankbobs.m_vec2(50, 63), "Name", nil, 1 / 3) player.name = gui_addInput(tankbobs.m_vec2(75, 63), c_config_get("config.game.player1.name"), nil, st_optionsPlayers_name, false, c_const_get("max_nameLength"), 0.5)

	gui_addLabel(tankbobs.m_vec2(50, 57), "Fire", nil, 1 / 3) player.fire = gui_addKey(tankbobs.m_vec2(75, 57), c_config_get("config.key.player1.fire"), nil, st_optionsPlayers_fire, c_config_get("config.key.player1.fire"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 54), "Forward", nil, 1 / 3) player.forward = gui_addKey(tankbobs.m_vec2(75, 54), c_config_get("config.key.player1.forward"), nil, st_optionsPlayers_forward, c_config_get("config.key.player1.forward"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 51), "Back", nil, 1 / 3) player.back = gui_addKey(tankbobs.m_vec2(75, 51), c_config_get("config.key.player1.back"), nil, st_optionsPlayers_back, c_config_get("config.key.player1.back"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 48), "Left", nil, 1 / 3) player.left = gui_addKey(tankbobs.m_vec2(75, 48), c_config_get("config.key.player1.left"), nil, st_optionsPlayers_left, c_config_get("config.key.player1.left"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 45), "Right", nil, 1 / 3) player.right = gui_addKey(tankbobs.m_vec2(75, 45), c_config_get("config.key.player1.right"), nil, st_optionsPlayers_right, c_config_get("config.key.player1.right"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 42), "Special", nil, 1 / 3) player.special = gui_addKey(tankbobs.m_vec2(75, 42), c_config_get("config.key.player1.special"), nil, st_optionsPlayers_special, c_config_get("config.key.player1.special"), 0.5)

	gui_addLabel(tankbobs.m_vec2(50, 36), "Adjust color", nil, 1 / 3)

	player.colorR = gui_addScale(tankbobs.m_vec2(75, 33), c_config_get("config.game.player1.color.r"), nil, st_optionsPlayers_colorR, c_config_get("config.game.player1.color.r"), nil, 0.5, 1.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0)
	player.colorG = gui_addScale(tankbobs.m_vec2(75, 30), c_config_get("config.game.player1.color.g"), nil, st_optionsPlayers_colorG, c_config_get("config.game.player1.color.g"), nil, 0.5, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0)
	player.colorB = gui_addScale(tankbobs.m_vec2(75, 27), c_config_get("config.game.player1.color.b"), nil, st_optionsPlayers_colorB, c_config_get("config.game.player1.color.b"), nil, 0.5, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0)

	-- image of tank is drawn (takes 21 and 24)
end

function st_optionsPlayers_done()
	gui_finish()

	currentPlayer = 1
	player = nil
end

local tankRotation = 0

function st_optionsPlayers_step(d)
	gui_paint(d)

	-- draw the tank below the color scales
	gl.PushAttrib("CURRENT_BIT")
		gl.PushMatrix()
			gl.Color(c_config_get("config.game.player" .. tostring(currentPlayer) .. ".color.r"), c_config_get("config.game.player" .. tostring(currentPlayer) .. ".color.g"), c_config_get("config.game.player" .. tostring(currentPlayer) .. ".color.b"), 1)
			gl.TexEnv("TEXTURE_ENV_COLOR", c_config_get("config.game.player" .. tostring(currentPlayer) .. ".color.r"), c_config_get("config.game.player" .. tostring(currentPlayer) .. ".color.g"), c_config_get("config.game.player" .. tostring(currentPlayer) .. ".color.b"), 1)
			gl.Translate(85, 22.5, 0)
			gl.Rotate(tankbobs.m_degrees(tankRotation), 0, 0, 1)
			tankRotation = tankRotation + d * c_const_get("optionsPlayers_tankRotation")
			gl.CallList(tank_listBase)
		gl.PopMatrix()
	gl.PopAttrib()
end

function st_optionsPlayers_configurePlayer(widget)
	currentPlayer = tonumber(widget.inputText) or 1
	if type(currentPlayer) ~= "number" or currentPlayer < 1 then
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

	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".color.r", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".color.r", c_config_get("config.game.defaultTankRed"))
	end
	local colorR = c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".color.r")
	player.colorR:setScalePos(colorR)

	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".color.g", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".color.g", c_config_get("config.game.defaultTankGreen"))
	end
	local colorG = c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".color.g")
	player.colorG:setScalePos(colorG)

	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".color.b", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".color.b", c_config_get("config.game.defaultTankBlue"))
	end
	local colorB = c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".color.b")
	player.colorB:setScalePos(colorB)
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

function st_optionsPlayers_fire(widget, button)
	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".fire", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".fire", false)
	end

	if button then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".fire", button)
	else
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".fire", false)
	end
end

function st_optionsPlayers_forward(widget, button)
	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".forward", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".forward", false)
	end

	if button then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".forward", button)
	else
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".forward", false)
	end
end

function st_optionsPlayers_right(widget, button)
	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".right", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".right", false)
	end

	if button then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".right", button)
	else
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".right", false)
	end
end

function st_optionsPlayers_back(widget, button)
	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".back", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".back", false)
	end

	if button then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".back", button)
	else
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".back", false)
	end
end

function st_optionsPlayers_left(widget, button)
	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".left", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".left", false)
	end

	if button then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".left", button)
	else
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".left", false)
	end
end

function st_optionsPlayers_special(widget, button)
	if not (c_config_get("config.key.player" .. tonumber(currentPlayer) .. ".special", nil, true)) then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".special", false)
	end

	if button then
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".special", button)
	else
		c_config_set("config.key.player" .. tonumber(currentPlayer) .. ".special", false)
	end
end

function st_optionsPlayers_colorR(widget, pos)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".color.r", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".color.r", c_config_get("config.game.defaultTankRed"))
	end

	c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".color.r", pos)
end

function st_optionsPlayers_colorG(widget, pos)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".color.g", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".color.g", c_config_get("config.game.defaultTankGreen"))
	end

	c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".color.g", pos)
end

function st_optionsPlayers_colorB(widget, pos)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".color.b", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".color.b", c_config_get("config.game.defaultTankBlue"))
	end

	c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".color.b", pos)
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

	main   = st_optionsPlayers_step
}

local optionsControls_init
local optionsControls_done

local st_optionsControls_pause
local st_optionsControls_exit
local st_optionsControls_quit

function st_optionsControls_init()
	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	local pos = 1
	for k, v in pairs(c_const_get("keyLayouts")) do
		if v == c_config_get("config.keyLayout") then
			pos = k

			break
		end
	end
	gui_addLabel(tankbobs.m_vec2(50, 65), "Key Layout", nil, 2 / 3) gui_addCycle(tankbobs.m_vec2(75, 65), "Key Layout", nil, st_optionsControls_keyLayout, c_const_get("keyLayouts"), pos)

	gui_addLabel(tankbobs.m_vec2(50, 53), "Pause", nil, 2 / 3) gui_addKey(tankbobs.m_vec2(75, 53), c_config_get("config.key.pause"), nil, st_optionsControls_pause, c_config_get("config.key.pause"))
	gui_addLabel(tankbobs.m_vec2(50, 37), "Back", nil, 2 / 3) gui_addKey(tankbobs.m_vec2(75, 37), c_config_get("config.key.quit"), nil, st_optionsControls_quit, c_config_get("config.key.quit"))
	gui_addLabel(tankbobs.m_vec2(50, 31), "Quit", nil, 2 / 3) gui_addKey(tankbobs.m_vec2(75, 31), c_config_get("config.key.exit"), nil, st_optionsControls_exit, c_config_get("config.key.exit"))
end

function st_optionsControls_done()
	gui_finish()
end

function st_optionsControls_keyLayout(widget, string, index)
	if c_const_get("keyLayout_" .. string) then
		c_config_set("config.keyLayout", string)
	end
end

function st_optionsControls_pause(widget, button)
	if button then
		c_config_set("config.key.pause", button)
	else
		c_config_set("config.key.pause", false)
	end
end

function st_optionsControls_exit(widget, button)
	if button then
		c_config_set("config.key.exit", button)
	else
		c_config_set("config.key.exit", false)
	end
end

function st_optionsControls_quit(widget, button)
	if button then
		c_config_set("config.key.quit", button)
	else
		c_config_set("config.key.quit", false)
	end
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
	gl = _G.gl
	c_const_get = _G.c_const_get
	c_const_set = _G.c_const_set
	c_config_get = _G.c_config_get
	c_config_set = _G.c_config_set
	tank_listBase = _G.tank_listBase

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
