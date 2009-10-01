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
st_play.lua

Offline play state
--]]

local tankbobs = tankbobs
local gl = gl
local c_world_step = c_world_step
local gui_paint = gui_paint
local gui_button = gui_button
local gui_mouse = gui_mouse
local c_world_getPowerups = c_world_getPowerups
local c_weapon_getProjectiles = c_weapon_getProjectiles
local c_world_getTanks = c_world_getTanks
local c_world_getPaused = c_world_getPaused
local c_const_get = c_const_get
local c_const_set = c_const_set
local c_config_get = c_config_get
local c_config_set = c_config_set
local c_weapon_getWeapons = c_weapon_getWeapons
local tank_listBase
local tankBorder_listBase
local powerup_listBase
local healthbar_listBase
local healthbarBorder_listBase
local c_world_findClosestIntersection
local common_lerp

local st_play_init
local st_play_done
local st_play_click
local st_play_button
local st_play_mouse
local st_play_step

local endOfGame
local quitScreen

local bit

local refreshKeys = function ()
	tankbobs.in_getKeys()

	for i = 1, #c_world_getTanks() do
		local tank = c_world_getTanks()[i]

		if not tank then
			break
		end

		if not (c_config_get("client.key.player" .. tostring(i) .. ".fire", true)) then
			c_config_set("client.key.player" .. tostring(i) .. ".fire", false)
		end
		if not (c_config_get("client.key.player" .. tostring(i) .. ".forward", true)) then
			c_config_set("client.key.player" .. tostring(i) .. ".forward", false)
		end
		if not (c_config_get("client.key.player" .. tostring(i) .. ".back", true)) then
			c_config_set("client.key.player" .. tostring(i) .. ".back", false)
		end
		if not (c_config_get("client.key.player" .. tostring(i) .. ".right", true)) then
			c_config_set("client.key.player" .. tostring(i) .. ".right", false)
		end
		if not (c_config_get("client.key.player" .. tostring(i) .. ".left", true)) then
			c_config_set("client.key.player" .. tostring(i) .. ".left", false)
		end
		if not (c_config_get("client.key.player" .. tostring(i) .. ".special", true)) then
			c_config_set("client.key.player" .. tostring(i) .. ".special", false)
		end
		if not (c_config_get("client.key.player" .. tostring(i) .. ".reload", true)) then
			c_config_set("client.key.player" .. tostring(i) .. ".reload", false)
		end
		--if not (c_config_get("client.key.player" .. tostring(i) .. ".reverse", true)) then
			--c_config_set("client.key.player" .. tostring(i) .. ".reverse", false)
		--end
		if not (c_config_get("client.key.player" .. tostring(i) .. ".mod", true)) then
			c_config_set("client.key.player" .. tostring(i) .. ".mod", false)
		end

		local ks = "client.key.player" .. tostring(i) .. "."
		local kp, kl, cg = tankbobs.in_keyPressed, c_config_keyLayoutGet, c_config_get

		local function key(state, flag)
			local key = cg(ks .. state)

			if key ~= 303 and key ~= 304 then
				key = kl(key)

				if kp(key) then
					tank.state = bit.bor(tank.state, flag)
				else
					tank.state = bit.band(tank.state, bit.bnot(flag))
				end
			end
		end

		key("fire", FIRING)
		key("forward", FORWARD)
		key("back", BACK)
		key("left", LEFT)
		key("right", RIGHT)
		key("special", SPECIAL)
		key("reload", RELOAD)
		--key("reverse", REVERSE)
		key("mod", MOD)
	end
end

function st_play_init()
	-- localize frequently used globals
	tankbobs = _G.tankbobs
	gl = _G.gl
	c_world_step = _G.c_world_step
	gui_paint = _G.gui_paint
	gui_button = _G.gui_button
	gui_mouse = _G.gui_mouse
	c_world_getPowerups = _G.c_world_getPowerups
	c_weapon_getProjectiles = _G.c_weapon_getProjectiles
	c_world_getTanks = _G.c_world_getTanks
	c_world_getPaused = _G.c_world_getPaused
	c_const_get = _G.c_const_get
	c_const_set = _G.c_const_set
	c_config_get = _G.c_config_get
	c_config_set = _G.c_config_set
	c_weapon_getWeapons = _G.c_weapon_getWeapons
	tank_listBase = _G.tank_listBase
	tankBorder_listBase = _G.tankBorder_listBase
	powerup_listBase = _G.powerup_listBase
	healthbar_listBase = _G.healthbar_listBase
	healthbarBorder_listBase = _G.healthbarBorder_listBase
	c_world_findClosestIntersection = _G.c_world_findClosestIntersection
	common_lerp = _G.common_lerp

	bit = c_module_load "bit"

	game_refreshKeys = refreshKeys

	endOfGame = false
	quitScreen = false

	game_new()

	-- pause label

	-- pause
	local function updatePause(widget)
		if c_world_getPaused() and not endOfGame and not quitScreen then
			widget.text = "Paused"
			tankbobs.in_grabClear()
		else
			widget.text = ""

			if quitScreen then
				tankbobs.in_grabClear()
			elseif not tankbobs.in_isGrabbed() then
				if not c_const_get("debug") or c_config_get("debug.client.grabMouse") then
					tankbobs.in_grabMouse(c_config_get("client.renderer.width") / 2, c_config_get("client.renderer.height") / 2)
				end
			end
		end
	end

	gui_addLabel(tankbobs.m_vec2(37.5, 50), "", updatePause, nil, c_config_get("client.renderer.pauseRed"), c_config_get("client.renderer.pauseGreen"), c_config_get("client.renderer.pauseBlue"), c_config_get("client.renderer.pauseAlpha"), c_config_get("client.renderer.pauseRed"), c_config_get("client.renderer.pauseGreen"), c_config_get("client.renderer.pauseBlue"), c_config_get("client.renderer.pauseAlpha"))

	-- initialize the world
	c_world_newWorld()

	-- set instagib state
	c_world_setInstagib(c_config_get("game.instagib"))

	for i = 1, c_config_get("game.players") + c_config_get("game.computers") do
		if i > c_const_get("max_tanks") then
			break
		end

		local tank = c_world_tank:new()
		table.insert(c_world_getTanks(), tank)

		if not (c_config_get("game.player" .. tostring(i) .. ".name", true)) then
			c_config_set("game.player" .. tostring(i) .. ".name", "Player" .. tostring(i))
		end

		tank.name = c_config_get("game.player" .. tostring(i) .. ".name")
		if not (c_config_get("game.player" .. tostring(i) .. ".color.r", true)) then
			c_config_set("game.player" .. tostring(i) .. ".color.r", c_config_get("game.defaultTankRed"))
			c_config_set("game.player" .. tostring(i) .. ".color.g", c_config_get("game.defaultTankBlue"))
			c_config_set("game.player" .. tostring(i) .. ".color.b", c_config_get("game.defaultTankGreen"))
			c_config_set("game.player" .. tostring(i) .. ".color.a", c_config_get("game.defaultTankAlpha"))
		end
		if not (c_config_get("game.player" .. tostring(i) .. ".team", true)) then
			c_config_set("game.player" .. tostring(i) .. ".team", false)
		end
		tank.color.r = c_config_get("game.player" .. tostring(i) .. ".color.r")
		tank.color.g = c_config_get("game.player" .. tostring(i) .. ".color.g")
		tank.color.b = c_config_get("game.player" .. tostring(i) .. ".color.b")
		tank.red = c_config_get("game.player" .. tostring(i) .. ".team") == "red"

		-- spawn
		c_world_tank_spawn(tank)
	end
end

function st_play_done()
	gui_finish()

	-- reset texenv
	gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

	-- end game
	game_end()

	-- free the world
	c_world_freeWorld()
end

function st_play_click(button, pressed, x, y)
	gui_click(button, pressed, x, y)

	if pressed and endOfGame then
		c_state_new(play_state)
	end
end

local quitLabel, yesAction, noAction
local function continue()
	if quitScreen then
		gui_removeWidget(quitLabel)
		gui_removeWidget(yesAction)
		gui_removeWidget(noAction)
		c_world_setPaused(not c_world_getPaused())
		quitScreen = false
	end
end
function st_play_button(button, pressed)
	if not gui_button(button, pressed) then
		if pressed then
			if button == 0x0D and endOfGame then  -- enter
				c_state_new(play_state)
			elseif button == c_config_get("client.key.pause") then
				if not endOfGame and not quitScreen then
					c_world_setPaused(not c_world_getPaused())
				end
			elseif button == 0x1B or button == c_config_get("client.key.quit") then  -- escape
				if endOfGame then
					c_state_new(play_state)
				elseif quitScreen then
					continue()
				elseif c_world_getPaused() then
					c_world_setPaused(not c_world_getPaused())
				else
					c_world_setPaused(true)
					quitLabel = gui_addLabel(tankbobs.m_vec2(35.0, 60), "Really Quit?", nil, nil, c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"), c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"))
					yesAction = gui_addAction(tankbobs.m_vec2(35.0, 40), "Yes", nil, c_state_advance, nil, c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"), c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"))
					noAction = gui_addAction(tankbobs.m_vec2(65.0, 40), "No", nil, continue, nil, c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"), c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"))
					quitScreen = true
				end
			elseif button == c_config_get("client.key.exit") then
				c_state_new(exit_state)
			end
		end

		for i = 1, c_config_get("game.players") do
			local tank = c_world_getTanks()[i]

			if not tank then
				break
			end

			if not (c_config_get("client.key.player" .. tostring(i) .. ".fire", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".fire", false)
			end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".forward", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".forward", false)
			end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".back", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".back", false)
			end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".right", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".right", false)
			end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".left", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".left", false)
			end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".special", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".special", false)
			end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".reload", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".reload", false)
			end
			--if not (c_config_get("client.key.player" .. tostring(i) .. ".reverse", true)) then
				--c_config_set("client.key.player" .. tostring(i) .. ".reverse", false)
			--end
			if not (c_config_get("client.key.player" .. tostring(i) .. ".mod", true)) then
				c_config_set("client.key.player" .. tostring(i) .. ".mod", false)
			end

			local ks = "client.key.player" .. tostring(i) .. "."

			if pressed then
				if button == c_config_get(ks .. "fire") then
					tank.state = bit.bor(tank.state, FIRING)
				end if button == c_config_get(ks .. "forward") then
					tank.state = bit.bor(tank.state, FORWARD)
				end if button == c_config_get(ks .. "back") then
					tank.state = bit.bor(tank.state, BACK)
				end if button == c_config_get(ks .. "left") then
					tank.state = bit.bor(tank.state, LEFT)
				end if button == c_config_get(ks .. "right") then
					tank.state = bit.bor(tank.state, RIGHT)
				end if button == c_config_get(ks .. "special") then
					tank.state = bit.bor(tank.state, SPECIAL)
				end if button == c_config_get(ks .. "reload") then
					tank.state = bit.bor(tank.state, RELOAD)
				--end if button == c_config_get(ks .. "reverse") then
					--tank.state = bit.bor(tank.state, REVERSE)
				end if button == c_config_get(ks .. "mod") then
					tank.state = bit.bor(tank.state, MOD)
				end
			else
				if button == c_config_get(ks .. "fire") then
					tank.state = bit.band(tank.state, bit.bnot(FIRING))
				end if button == c_config_get(ks ..           "forward") then
					tank.state = bit.band(tank.state, bit.bnot(FORWARD))
				end if button == c_config_get(ks ..           "back") then
					tank.state = bit.band(tank.state, bit.bnot(BACK))
				end if button == c_config_get(ks ..           "left") then
					tank.state = bit.band(tank.state, bit.bnot(LEFT))
				end if button == c_config_get(ks ..           "right") then
					tank.state = bit.band(tank.state, bit.bnot(RIGHT))
				end if button == c_config_get(ks ..           "special") then
					tank.state = bit.band(tank.state, bit.bnot(SPECIAL))
				end if button == c_config_get(ks ..           "reload") then
					tank.state = bit.band(tank.state, bit.bnot(RELOAD))
				--end if button == c_config_get(ks ..           "reverse") then
					--tank.state = bit.band(tank.state, bit.bnot(REVERSE)
				end if button == c_config_get(ks ..           "mod") then
					tank.state = bit.band(tank.state, bit.bnot(MOD))
				end
			end
		end
	end

	game_refreshKeys()
end

function st_play_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

local function play_testEnd()
	-- test for end of game
	if endOfGame then
		c_world_setPaused(true)
	end

	local switch = c_world_gameType
	if switch == DEATHMATCH then
		local fragLimit = c_config_get("game.fragLimit")

		if fragLimit > 0 then
			for k, v in pairs(c_world_getTanks()) do
				if v.score >= fragLimit then
					c_world_setPaused(true)

					local name = tostring(c_config_get("game.player" .. tostring(k) .. ".name"))
					gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, v.color.r, v.color.g, v.color.b, 0.75, v.color.r, v.color.g, v.color.b, 0.8)

					if not endOfGame then
						tankbobs.a_playSound(c_const_get("win_sound"))
					end

					endOfGame = true
				end
			end
		end
	elseif switch == CHASE then
		local chaseLimit = c_config_get("game.chaseLimit")

		if chaseLimit > 0 then
			for k, v in pairs(c_world_getTanks()) do
				if v.score >= chaseLimit then
					c_world_setPaused(true)

					local name = tostring(c_config_get("game.player" .. tostring(k) .. ".name"))
					gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, v.color.r, v.color.g, v.color.b, 0.75, v.color.r, v.color.g, v.color.b, 0.8)

					if not endOfGame then
						tankbobs.a_playSound(c_const_get("win_sound"))
					end

					endOfGame = true
				end
			end
		end
	elseif switch == DOMINATION then
		local pointLimit = c_config_get("game.pointLimit")

		if pointLimit > 0 then
			if c_world_redTeam.score >= pointLimit then
				c_world_setPaused(true)

				local name = "Red"
				local color = c_const_get("color_red")
				gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, color[1], color[2], color[3], 0.75, color[1], color[2], color[3], 0.8)

				if not endOfGame then
					tankbobs.a_playSound(c_const_get("win_sound"))
				end

				endOfGame = true
			elseif c_world_blueTeam.score >= pointLimit then
				c_world_setPaused(true)

				local name = "Blue"
				local color = c_const_get("color_blue")
				gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, color[1], color[2], color[3], 0.75, color[1], color[2], color[3], 0.8)

				if not endOfGame then
					tankbobs.a_playSound(c_const_get("win_sound"))
				end

				endOfGame = true
			end
		end
	elseif switch == CAPTURETHEFLAG then
		local captureLimit = c_config_get("game.captureLimit")

		if captureLimit > 0 then
			if c_world_redTeam.score >= captureLimit then
				c_world_setPaused(true)

				local name = "Red"
				local color = c_const_get("color_red")
				gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, color[1], color[2], color[3], 0.75, color[1], color[2], color[3], 0.8)

				if not endOfGame then
					tankbobs.a_playSound(c_const_get("win_sound"))
				end

				endOfGame = true
			elseif c_world_blueTeam.score >= captureLimit then
				c_world_setPaused(true)

				local name = "Blue"
				local color = c_const_get("color_blue")
				gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, color[1], color[2], color[3], 0.75, color[1], color[2], color[3], 0.8)

				if not endOfGame then
					tankbobs.a_playSound(c_const_get("win_sound"))
				end

				endOfGame = true
			end
		end
	end
end

function st_play_step(d)
	-- test for end of game
	play_testEnd()

	c_world_step(d)

	game_step(d)

	gui_paint(d)
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
