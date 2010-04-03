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
st_options.lua

Options
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
			if button == c_config_get("client.key.exit") then
				c_state_goto(exit_state)
			elseif button == 0x1B or button == c_config_get("client.key.quit") then
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

local st_optionsGame_init
local st_optionsGame_done

local st_optionsGame_worldFPS

function st_optionsGame_init()
	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	local pos = 0
	local buf = c_config_get("game.worldFPS")
		if buf == 8 then
		pos = 1
	elseif buf == 16 then
		pos = 2
	elseif buf == 32 then
		pos = 3
	elseif buf == 64 then
		pos = 4
	elseif buf == 128 then
		pos = 5
	elseif buf == 256 then
		pos = 6
	elseif buf == 512 then
		pos = 7
	elseif buf == 1024 then
		pos = 8
	end
	-- World FPS needs to be constant
	gui_addLabel(tankbobs.m_vec2(50, 75), "World Simulation", nil, 1 / 3) gui_addCycle(tankbobs.m_vec2(75, 75), "World Simulation", nil, st_optionsGame_worldFPS, {"Slide Show", "Roughest", "Rougher", "Rough", "Medium", "Smooth", "Smoother", "Smoothest"}, pos, 1 / 3)
	gui_addLabel(tankbobs.m_vec2(50, 72), "(Restart to take effect to world simulation smoothness)", nil, 1 / 3)
end

function st_optionsGame_done()
	gui_finish()
end

function st_optionsGame_worldFPS(widget, string, index)
		if string == "Smoothest" then
		c_config_set("game.worldFPS", 1024)
	elseif string == "Smoother" then
		c_config_set("game.worldFPS", 512)
	elseif string == "Smooth" then
		c_config_set("game.worldFPS", 256)
	elseif string == "Medium" then
		c_config_set("game.worldFPS", 128)
	elseif string == "Rough" then
		c_config_set("game.worldFPS", 64)
	elseif string == "Rougher" then
		c_config_set("game.worldFPS", 32)
	elseif string == "Roughest" then
		c_config_set("game.worldFPS", 16)
	elseif string == "Slide Show" then
		c_config_set("game.worldFPS", 8)
	end
end

optionsGame_state =
{
	name   = "optionsGame_state",
	init   = st_optionsGame_init,
	done   = st_optionsGame_done,
	next   = function () return options_state end,

	click  = st_options_click,
	button = st_options_button,
	mouse  = st_options_mouse,

	main   = st_options_step
}

local st_optionsAudio_init
local st_optionsAudio_done

local st_optionsAudio_volume
local st_optionsAudio_musicVolume
local st_optionsAudio_chunkSize

function st_optionsAudio_init()
	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	gui_addLabel(tankbobs.m_vec2(50, 75), "Volume", nil, 2 / 3)

	gui_addLabel(tankbobs.m_vec2(50, 57), "Volume", nil, 2 / 3) gui_addScale(tankbobs.m_vec2(75, 57), "Volume", nil, st_optionsAudio_volume, c_config_get("client.volume"))
	gui_addLabel(tankbobs.m_vec2(50, 51), "Music", nil, 2 / 3) gui_addScale(tankbobs.m_vec2(75, 51), "Music", nil, st_optionsAudio_musicVolume, c_config_get("client.musicVolume"))

	local pos = 0
	local buf = c_config_get("client.audioChunkSize")
		if buf == 256 then
		pos = 1
	elseif buf == 512 then
		pos = 2
	elseif buf == 1024 then
		pos = 3
	elseif buf == 3072 then
		pos = 4
	elseif buf == 4096 then
		pos = 5
	elseif buf == 8192 then
		pos = 6
	elseif buf == 16384 then
		pos = 7
	end
	gui_addLabel(tankbobs.m_vec2(50, 39), "Chunk Size", nil, 2 / 3) gui_addCycle(tankbobs.m_vec2(75, 39), "Chunk Size", nil, st_optionsAudio_chunkSize, {"Lowest", "Lower", "Low", "Medium", "High", "Higher", "Highest"}, pos, 2 / 3)
	gui_addLabel(tankbobs.m_vec2(50, 36), "(Restart to take effect to chunk size)", nil, 1 / 3)
end

function st_optionsAudio_done()
	gui_finish()
end

function st_optionsAudio_volume(widget, pos)
	c_config_set("client.volume", pos)
	tankbobs.a_setVolume(pos)
end

function st_optionsAudio_musicVolume(widget, pos)
	c_config_set("client.musicVolume", pos)
	tankbobs.a_setMusicVolume(pos)
end

function st_optionsAudio_chunkSize(widget, string, index)
		if string == "Highest" then
		c_config_set("client.audioChunkSize", 16384)
	elseif string == "Higher" then
		c_config_set("client.audioChunkSize", 8192)
	elseif string == "High" then
		c_config_set("client.audioChunkSize", 4096)
	elseif string == "Medium" then
		c_config_set("client.audioChunkSize", 3072)  -- magic number (*3, not *2) seems to eliminate fuzz
	elseif string == "Low" then
		c_config_set("client.audioChunkSize", 1024)
	elseif string == "Lower" then
		c_config_set("client.audioChunkSize", 512)
	elseif string == "Lowest" then
		c_config_set("client.audioChunkSize", 256)
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
local st_optionsVideo_resolution
local st_optionsVideo_width
local st_optionsVideo_height
local st_optionsVideo_apply
local st_optionsVideo_fpsCounter
local st_optionsVideo_rotateCamera
local st_optionsVideo_screen

local custom = false

function st_optionsVideo_init()
	st_optionsVideo_renderer = {fullscreen = c_config_get("client.renderer.fullscreen"), width = c_config_get("client.renderer.width"), height = c_config_get("client.renderer.height")}

	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	local offset = 0
	local pos = 1
	local rresolutions = tankbobs.in_getResolutions()
	resolutions = {"Custom"}
	if rresolutions then
		for k, v in pairs(rresolutions) do
			if not custom and st_optionsVideo_renderer.width == v[1] and st_optionsVideo_renderer.height == v[2] then
				pos = k + 1
			end
			resolutions[k + 1] = tostring(v[1]) .. "x" .. tostring(v[2])
		end
	end

	custom = false

	gui_addLabel(tankbobs.m_vec2(50, 75), "Fullscreen", nil, 2 / 3) gui_addCycle(tankbobs.m_vec2(75, 75), "Fullscreen", nil, st_optionsVideo_fullscreen, {"No", "Yes"}, c_config_get("client.renderer.fullscreen") and 2 or 1)
	gui_addLabel(tankbobs.m_vec2(50, 69), "Resolution", nil, 2 / 3) gui_addCycle(tankbobs.m_vec2(75, 69), "Resolution", nil, st_optionsVideo_resolution, resolutions, pos)
	if pos == 1 then
		offset = -12

		gui_addLabel(tankbobs.m_vec2(50, 75 + offset), "Width", nil, 2 / 3) gui_addInput(tankbobs.m_vec2(75, 75 + offset), tostring(c_config_get("client.renderer.width")), nil, st_optionsVideo_width, true, 5)
		gui_addLabel(tankbobs.m_vec2(50, 69 + offset), "Height", nil, 2 / 3) gui_addInput(tankbobs.m_vec2(75, 69 + offset), tostring(c_config_get("client.renderer.height")), nil, st_optionsVideo_height, true, 5)
	end
	gui_addAction(tankbobs.m_vec2(75, 63 + offset), "Apply", nil, st_optionsVideo_apply)

	gui_addLabel(tankbobs.m_vec2(50, 54 + offset), "FPS Counter", nil, 2 / 4) gui_addCycle(tankbobs.m_vec2(75, 54 + offset), "FPS Counter", nil, st_optionsVideo_fpsCounter, {"No", "Yes"}, c_config_get("client.renderer.fpsCounter") and 2 or 1)  -- Label needs to be a bit smaller

	gui_addLabel(tankbobs.m_vec2(50, 48 + offset), "Rotate Camera", nil, 2 / 4) gui_addCycle(tankbobs.m_vec2(75, 48 + offset), "Rotate Camera", nil, st_optionsVideo_rotateCamera, {"No", "Yes"}, c_config_get("client.cameraRotate") and 2 or 1)  -- Label needs to be a bit smaller

	gui_addLabel(tankbobs.m_vec2(50, 42 + offset), "Screen", nil, 2 / 3) gui_addCycle(tankbobs.m_vec2(75, 42 + offset), "Fullscreen", nil, st_optionsVideo_screen, {"Single", "One Tank", "Split", "Triple", "Four"}, math.min(4, c_config_get("client.screens") + 1))
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

function st_optionsVideo_resolution(widget, string, index)
	if string:find("x") and index > 1 then
		st_optionsVideo_renderer.width = tonumber(string:sub(1, string:find("x") - 1))
		st_optionsVideo_renderer.height = tonumber(string:sub(string:find("x") + 1, -1))
	else
		custom = true
		c_state_goto(optionsVideo_state)
	end
end

function st_optionsVideo_width(widget)
	st_optionsVideo_renderer.width = tonumber(widget.inputText)
end

function st_optionsVideo_height(widget)
	st_optionsVideo_renderer.height = tonumber(widget.inputText)
end

function st_optionsVideo_apply(widget)
	if c_config_get("client.renderer.fullscreen") ~= st_optionsVideo_renderer.fullscreen or c_config_get("client.renderer.width") ~= st_optionsVideo_renderer.width or c_config_get("client.renderer.height") ~= st_optionsVideo_renderer.height then
		c_config_set("client.renderer.fullscreen", st_optionsVideo_renderer.fullscreen)
		c_config_set("client.renderer.width", st_optionsVideo_renderer.width)
		c_config_set("client.renderer.height", st_optionsVideo_renderer.height)
		renderer_updateWindow()  -- in case SDL forgets to send a resize signal
		tankbobs.r_newWindow(c_config_get("client.renderer.width"), c_config_get("client.renderer.height"), c_config_get("client.renderer.fullscreen"), c_const_get("title"), c_const_get("icon"))
		c_state_goto(optionsVideo_state)
	end
end

function st_optionsVideo_fpsCounter(widget, string, index)
	if string == "Yes" then
		c_config_set("client.renderer.fpsCounter", true)
	elseif string == "No" then
		c_config_set("client.renderer.fpsCounter", false)
	end
end

function st_optionsVideo_rotateCamera(widget, string, index)
	if string == "Yes" then
		c_config_set("client.cameraRotate", true)
	elseif string == "No" then
		c_config_set("client.cameraRotate", false)
	end
end

function st_optionsVideo_screen(widget, string, index)
	c_config_set("client.screens", index - 1)
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
local st_optionsPlayers_reverse
local st_optionsPlayers_mod
local st_optionsPlayers_reload
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

	gui_addLabel(tankbobs.m_vec2(50, 75), "Computers", nil, 1 / 3) gui_addInput(tankbobs.m_vec2(75, 75), tostring(tonumber(c_config_get("game.computers"))), nil, st_optionsPlayers_computers, true, 1, 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 72), "Players", nil, 1 / 3) gui_addInput(tankbobs.m_vec2(75, 72), tostring(tonumber(c_config_get("game.players"))), nil, st_optionsPlayers_players, true, 1, 0.5)

	gui_addLabel(tankbobs.m_vec2(50, 66), "Set up player", nil, 1 / 3) gui_addInput(tankbobs.m_vec2(75, 66), "1", nil, st_optionsPlayers_configurePlayer, true, 1, 0.5)
	if not (c_config_get("game.player1.name", true)) then
		c_config_set("game.player1.name", "Player1")
	end
	if not (c_config_get("client.key.player1.fire", true)) then
		c_config_set("client.key.player1.fire", false)
	end
	if not (c_config_get("client.key.player1.forward", true)) then
		c_config_set("client.key.player1.forward", false)
	end
	if not (c_config_get("client.key.player1.back", true)) then
		c_config_set("client.key.player1.back", false)
	end
	if not (c_config_get("client.key.player1.left", true)) then
		c_config_set("client.key.player1.left", false)
	end
	if not (c_config_get("client.key.player1.right", true)) then
		c_config_set("client.key.player1.right", false)
	end
	if not (c_config_get("client.key.player1.special", true)) then
		c_config_set("client.key.player1.special", false)
	end
	if not (c_config_get("client.key.player1.reload", true)) then
		c_config_set("client.key.player1.reload", false)
	end
	if not (c_config_get("client.key.player1.reverse", true)) then
		c_config_set("client.key.player1.reverse", false)
	end
	if not (c_config_get("client.key.player1.mod", true)) then
		c_config_set("client.key.player1.mod", false)
	end
	if not (c_config_get("game.player1.color.r", true)) then
		c_config_set("game.player1.color.r", c_config_get("game.defaultTankRed"))
	end
	if not (c_config_get("game.player1.color.g", true)) then
		c_config_set("game.player1.color.g", c_config_get("game.defaultTankGreen"))
	end
	if not (c_config_get("game.player1.color.b", true)) then
		c_config_set("game.player1.color.b", c_config_get("game.defaultTankBlue"))
	end
	if not (c_config_get("game.player1.team", true)) then
		c_config_set("game.player1.team", false)
	end

	gui_addLabel(tankbobs.m_vec2(50, 63), "Name", nil, 1 / 3) player.name = gui_addInput(tankbobs.m_vec2(75, 63), c_config_get("game.player1.name"), nil, st_optionsPlayers_name, false, c_const_get("max_nameLength"), 0.5)

	gui_addLabel(tankbobs.m_vec2(50, 57), "Fire", nil, 1 / 3) player.fire = gui_addKey(tankbobs.m_vec2(75, 57), c_config_get("client.key.player1.fire"), nil, st_optionsPlayers_fire, c_config_get("client.key.player1.fire"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 54), "Forward", nil, 1 / 3) player.forward = gui_addKey(tankbobs.m_vec2(75, 54), c_config_get("client.key.player1.forward"), nil, st_optionsPlayers_forward, c_config_get("client.key.player1.forward"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 51), "Back", nil, 1 / 3) player.back = gui_addKey(tankbobs.m_vec2(75, 51), c_config_get("client.key.player1.back"), nil, st_optionsPlayers_back, c_config_get("client.key.player1.back"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 48), "Left", nil, 1 / 3) player.left = gui_addKey(tankbobs.m_vec2(75, 48), c_config_get("client.key.player1.left"), nil, st_optionsPlayers_left, c_config_get("client.key.player1.left"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 45), "Right", nil, 1 / 3) player.right = gui_addKey(tankbobs.m_vec2(75, 45), c_config_get("client.key.player1.right"), nil, st_optionsPlayers_right, c_config_get("client.key.player1.right"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 42), "Special", nil, 1 / 3) player.special = gui_addKey(tankbobs.m_vec2(75, 42), c_config_get("client.key.player1.special"), nil, st_optionsPlayers_special, c_config_get("client.key.player1.special"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 39), "Reload", nil, 1 / 3) player.reload = gui_addKey(tankbobs.m_vec2(75, 39), c_config_get("client.key.player1.reload"), nil, st_optionsPlayers_reload, c_config_get("client.key.player1.reload"), 0.5)
	--gui_addLabel(tankbobs.m_vec2(50, 36), "Reverse", nil, 1 / 3) player.reverse = gui_addKey(tankbobs.m_vec2(75, 36), c_config_get("client.key.player1.reverse"), nil, st_optionsPlayers_reverse, c_config_get("client.key.player1.reverse"), 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 36), "Mod Key", nil, 1 / 3) player.mod = gui_addKey(tankbobs.m_vec2(75, 36), c_config_get("client.key.player1.mod"), nil, st_optionsPlayers_mod, c_config_get("client.key.player1.mod"), 0.5)

	gui_addLabel(tankbobs.m_vec2(50, 30), "Adjust color", nil, 1 / 3)

	player.colorR = gui_addScale(tankbobs.m_vec2(75, 27), c_config_get("game.player1.color.r"), nil, st_optionsPlayers_colorR, c_config_get("game.player1.color.r"), nil, 0.5, 1.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0)
	player.colorG = gui_addScale(tankbobs.m_vec2(75, 24), c_config_get("game.player1.color.g"), nil, st_optionsPlayers_colorG, c_config_get("game.player1.color.g"), nil, 0.5, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0)
	player.colorB = gui_addScale(tankbobs.m_vec2(75, 21), c_config_get("game.player1.color.b"), nil, st_optionsPlayers_colorB, c_config_get("game.player1.color.b"), nil, 0.5, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0)

	-- image of tank is drawn (takes 15 and 18)

	gui_addLabel(tankbobs.m_vec2(50, 9), "Team", nil, 2 / 3) player.team = gui_addCycle(tankbobs.m_vec2(75, 9), "Team", nil, st_optionsPlayers_team, {"Blue", "Red"}, c_config_get("game.player1.team") == "red" and 2 or 1, 2 / 3)
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
			gl.Color(c_config_get("game.player" .. tostring(currentPlayer) .. ".color.r"), c_config_get("game.player" .. tostring(currentPlayer) .. ".color.g"), c_config_get("game.player" .. tostring(currentPlayer) .. ".color.b"), 1)
			gl.TexEnv("TEXTURE_ENV_COLOR", c_config_get("game.player" .. tostring(currentPlayer) .. ".color.r"), c_config_get("game.player" .. tostring(currentPlayer) .. ".color.g"), c_config_get("game.player" .. tostring(currentPlayer) .. ".color.b"), 1)
			gl.Translate(85, 16.5, 0)
			gl.Rotate(tankbobs.m_degrees(tankRotation), 0, 0, 1)
			tankRotation = tankRotation + d * c_const_get("optionsPlayers_tankRotation")
			gl.CallList(tank_listBase)
			gl.Color(1, 1, 1, 1)
			gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 1)
			gl.CallList(tankBorder_listBase)
		gl.PopMatrix()
	gl.PopAttrib()
end

function st_optionsPlayers_configurePlayer(widget)
	currentPlayer = tonumber(widget.inputText) or 1
	if type(currentPlayer) ~= "number" or currentPlayer < 1 then
		currentPlayer = 1
	end

	if not (c_config_get("game.player" .. tonumber(currentPlayer) .. ".name", true)) then
		c_config_set("game.player" .. tonumber(currentPlayer) .. ".name", "Player" .. tonumber(currentPlayer))
	end
	local name = c_config_get("game.player" .. tonumber(currentPlayer) .. ".name")
	player.name:setText(#name <= c_const_get("max_nameLength") and name or "Player" .. tonumber(currentPlayer))

	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".fire", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".fire", false)
	end
	local fire = c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".fire")
	player.fire:setKey(fire)

	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".forward", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".forward", false)
	end
	local forward = c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".forward")
	player.forward:setKey(forward)

	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".back", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".back", false)
	end
	local back = c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".back")
	player.back:setKey(back)

	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".left", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".left", false)
	end
	local left = c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".left")
	player.left:setKey(left)

	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".right", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".right", false)
	end
	local right = c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".right")
	player.right:setKey(right)

	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".special", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".special", false)
	end
	local special = c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".special")
	player.special:setKey(special)

	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".reload", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".reload", false)
	end
	local reload = c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".reload")
	player.reload:setKey(reload)

	--if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".reverse", true)) then
		--c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".reverse", false)
	--end
	--local reverse = c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".reverse")
	--player.reverse:setKey(reverse)

	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".mod", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".mod", false)
	end
	local mod = c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".mod")
	player.mod:setKey(mod)

	if not (c_config_get("game.player" .. tonumber(currentPlayer) .. ".color.r", true)) then
		c_config_set("game.player" .. tonumber(currentPlayer) .. ".color.r", c_config_get("game.defaultTankRed"))
	end
	local colorR = c_config_get("game.player" .. tonumber(currentPlayer) .. ".color.r")
	player.colorR:setScalePos(colorR)

	if not (c_config_get("game.player" .. tonumber(currentPlayer) .. ".color.g", true)) then
		c_config_set("game.player" .. tonumber(currentPlayer) .. ".color.g", c_config_get("game.defaultTankGreen"))
	end
	local colorG = c_config_get("game.player" .. tonumber(currentPlayer) .. ".color.g")
	player.colorG:setScalePos(colorG)

	if not (c_config_get("game.player" .. tonumber(currentPlayer) .. ".color.b", true)) then
		c_config_set("game.player" .. tonumber(currentPlayer) .. ".color.b", c_config_get("game.defaultTankBlue"))
	end
	local colorB = c_config_get("game.player" .. tonumber(currentPlayer) .. ".color.b")
	player.colorB:setScalePos(colorB)

	if not (c_config_get("game.player" .. tonumber(currentPlayer) .. ".team", true)) then
		c_config_set("game.player" .. tonumber(currentPlayer) .. ".team", false)
	end
	local team = c_config_get("game.player" .. tonumber(currentPlayer) .. ".team") == "red" and 2 or 1
	player.team:setCyclePos(team)
end

function st_optionsPlayers_computers(widget)
	c_config_set("game.computers", tonumber(widget.inputText))
end

function st_optionsPlayers_players(widget)
	c_config_set("game.players", tonumber(widget.inputText))
end

function st_optionsPlayers_name(widget)
	if not (c_config_get("game.player" .. tonumber(currentPlayer) .. ".name", true)) then
		c_config_set("game.player" .. tonumber(currentPlayer) .. ".name", "Player" .. tonumber(currentPlayer))
	end

	c_config_set("game.player" .. tonumber(currentPlayer) .. ".name", tostring(widget.inputText))
end

function st_optionsPlayers_fire(widget, button)
	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".fire", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".fire", false)
	end

	if button then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".fire", c_config_keyLayoutSet(button))
	else
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".fire", false)
	end
end

function st_optionsPlayers_forward(widget, button)
	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".forward", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".forward", false)
	end

	if button then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".forward", c_config_keyLayoutSet(button))
	else
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".forward", false)
	end
end

function st_optionsPlayers_right(widget, button)
	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".right", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".right", false)
	end

	if button then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".right", c_config_keyLayoutSet(button))
	else
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".right", false)
	end
end

function st_optionsPlayers_back(widget, button)
	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".back", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".back", false)
	end

	if button then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".back", c_config_keyLayoutSet(button))
	else
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".back", false)
	end
end

function st_optionsPlayers_left(widget, button)
	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".left", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".left", false)
	end

	if button then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".left", c_config_keyLayoutSet(button))
	else
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".left", false)
	end
end

function st_optionsPlayers_special(widget, button)
	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".special", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".special", false)
	end

	if button then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".special", c_config_keyLayoutSet(button))
	else
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".special", false)
	end
end

function st_optionsPlayers_reload(widget, button)
	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".reload", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".reload", false)
	end

	if button then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".reload", c_config_keyLayoutSet(button))
	else
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".reload", false)
	end
end

function st_optionsPlayers_reverse(widget, button)
	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".reverse", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".reverse", false)
	end

	if button then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".reverse", c_config_keyLayoutSet(button))
	else
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".reverse", false)
	end
end

function st_optionsPlayers_mod(widget, button)
	if not (c_config_get("client.key.player" .. tonumber(currentPlayer) .. ".mod", true)) then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".mod", false)
	end

	if button then
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".mod", c_config_keyLayoutSet(button))
	else
		c_config_set("client.key.player" .. tonumber(currentPlayer) .. ".mod", false)
	end
end

function st_optionsPlayers_colorR(widget, pos)
	if not (c_config_get("game.player" .. tonumber(currentPlayer) .. ".color.r", true)) then
		c_config_set("game.player" .. tonumber(currentPlayer) .. ".color.r", c_config_get("game.defaultTankRed"))
	end

	c_config_set("game.player" .. tonumber(currentPlayer) .. ".color.r", pos)
end

function st_optionsPlayers_colorG(widget, pos)
	if not (c_config_get("game.player" .. tonumber(currentPlayer) .. ".color.g", true)) then
		c_config_set("game.player" .. tonumber(currentPlayer) .. ".color.g", c_config_get("game.defaultTankGreen"))
	end

	c_config_set("game.player" .. tonumber(currentPlayer) .. ".color.g", pos)
end

function st_optionsPlayers_colorB(widget, pos)
	if not (c_config_get("game.player" .. tonumber(currentPlayer) .. ".color.b", true)) then
		c_config_set("game.player" .. tonumber(currentPlayer) .. ".color.b", c_config_get("game.defaultTankBlue"))
	end

	c_config_set("game.player" .. tonumber(currentPlayer) .. ".color.b", pos)
end

function st_optionsPlayers_team(widget, string, index)
	if string == "Red" then
		if not (c_config_get("game.player" .. tonumber(currentPlayer) .. ".team", true)) then
			c_config_set("game.player" .. tonumber(currentPlayer) .. ".team", false)
		end

		c_config_set("game.player" .. tonumber(currentPlayer) .. ".team", "red")
	elseif string == "Blue" then
		if not (c_config_get("game.player" .. tonumber(currentPlayer) .. ".team", true)) then
			c_config_set("game.player" .. tonumber(currentPlayer) .. ".team", false)
		end

		c_config_set("game.player" .. tonumber(currentPlayer) .. ".team", "blue")
	end
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

local st_optionsControls_keyLayout
local st_optionsControls_pause
local st_optionsControls_exit
local st_optionsControls_quit
local st_optionsControls_screenToggle
local st_optionsControls_krr

function st_optionsControls_init()
	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	local pos = 1
	for k, v in pairs(c_const_get("keyLayouts")) do
		if v == c_config_get("client.keyLayout") then
			pos = k

			break
		end
	end
	gui_addLabel(tankbobs.m_vec2(50, 65), "Key Layout", nil, 1 / 3) gui_addCycle(tankbobs.m_vec2(75, 65), "Key Layout", nil, st_optionsControls_keyLayout, c_const_get("keyLayouts"), pos, 1 / 2)

	gui_addLabel(tankbobs.m_vec2(50, 53), "Pause", nil, 1 / 3) gui_addKey(tankbobs.m_vec2(75, 53), c_config_get("client.key.pause"), nil, st_optionsControls_pause, c_config_get("client.key.pause"), 1 / 2)
	gui_addLabel(tankbobs.m_vec2(50, 50), "Back", nil, 1 / 3) gui_addKey(tankbobs.m_vec2(75, 50), c_config_get("client.key.quit"), nil, st_optionsControls_quit, c_config_get("client.key.quit"), 1 / 2)
	gui_addLabel(tankbobs.m_vec2(50, 47), "Quit", nil, 1 / 3) gui_addKey(tankbobs.m_vec2(75, 47), c_config_get("client.key.exit"), nil, st_optionsControls_exit, c_config_get("client.key.exit"), 1 / 2)
	gui_addLabel(tankbobs.m_vec2(50, 44), "Toggle Split Screen", nil, 1 / 3) gui_addKey(tankbobs.m_vec2(75, 44), c_config_get("client.key.screenToggle"), nil, st_optionsControls_screenToggle, c_config_get("client.key.screenToggle"), 1 / 2)

	gui_addLabel(tankbobs.m_vec2(50, 38), "Key Refresh Rate in Frames", nil, 1 / 3) gui_addInput(tankbobs.m_vec2(85, 38), tostring(c_config_get("client.krr")), nil, st_optionsControls_krr, true, 5, 1 / 2)
end

function st_optionsControls_done()
	gui_finish()
end

function st_optionsControls_keyLayout(widget, string, index)
	if c_const_get("keyLayout_" .. string) then
		c_config_set("client.keyLayout", string)
	end
end

function st_optionsControls_pause(widget, button)
	if button then
		c_config_set("client.key.pause", c_config_keyLayoutSet(button))
	else
		c_config_set("client.key.pause", false)
	end
end

function st_optionsControls_exit(widget, button)
	if button then
		c_config_set("client.key.exit", c_config_keyLayoutSet(button))
	else
		c_config_set("client.key.exit", false)
	end
end

function st_optionsControls_quit(widget, button)
	if button then
		c_config_set("client.key.quit", c_config_keyLayoutSet(button))
	else
		c_config_set("client.key.quit", false)
	end
end

function st_optionsControls_screenToggle(widget, button)
	if button then
		c_config_set("client.key.screenToggle", c_config_keyLayoutSet(button))
	else
		c_config_set("client.key.screenToggle", false)
	end
end

function st_optionsControls_krr(widget)
	c_config_set("client.krr", tonumber(widget.inputText))
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

local st_optionsInternet_stepAhead
local st_optionsInternet_unlagged

function st_optionsInternet_init()
	gui_addAction(tankbobs.m_vec2(25, 85), "Back", nil, c_state_advance)

	gui_addLabel(tankbobs.m_vec2(50, 75), "Step Ahead", nil, 1 / 3) gui_addCycle(tankbobs.m_vec2(75, 75), "Step Ahead", nil, st_optionsInternet_stepAhead, {"No", "Yes"}, c_config_get("client.online.stepAhead") and 2 or 1, 1.5 / 3)
	gui_addLabel(tankbobs.m_vec2(50, 72), "Predict other tanks", nil, 1 / 3) gui_addCycle(tankbobs.m_vec2(75, 72), "Predict other tanks", nil, st_optionsInternet_unlagged, {"No", "Yes"}, c_config_get("client.online.unlagged") and 2 or 1, 1.5 / 3)
end

function st_optionsInternet_done()
	gui_finish()
end

function st_optionsInternet_stepAhead(widget, string, index)
	if string == "Yes" then
		c_config_set("client.online.stepAhead", true)
	elseif string == "No" then
		c_config_set("client.online.stepAhead", false)
	end
end

function st_optionsInternet_unlagged(widget, string, index)
	if string == "Yes" then
		c_config_set("client.online.unlagged", true)
	elseif string == "No" then
		c_config_set("client.online.unlagged", false)
	end
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

	gui_addAction(tankbobs.m_vec2(50, 75), "Game", nil, st_options_game)
	gui_addAction(tankbobs.m_vec2(50, 69), "Audio", nil, st_options_audio)
	gui_addAction(tankbobs.m_vec2(50, 63), "Video", nil, st_options_video)
	gui_addAction(tankbobs.m_vec2(50, 57), "Players", nil, st_options_players)
	gui_addAction(tankbobs.m_vec2(50, 51), "Controls", nil, st_options_controls)
	gui_addAction(tankbobs.m_vec2(50, 45), "Internet", nil, st_options_internet)
end

function st_options_done()
	gui_finish()
end

function st_options_game()
	c_state_goto(optionsGame_state)
end

function st_options_video()
	c_state_goto(optionsVideo_state)
end

function st_options_audio()
	c_state_goto(optionsAudio_state)
end

function st_options_players()
	c_state_goto(optionsPlayers_state)
end

function st_options_controls()
	c_state_goto(optionsControls_state)
end

function st_options_internet()
	c_state_goto(optionsInternet_state)
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
