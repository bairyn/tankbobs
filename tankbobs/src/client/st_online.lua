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
st_online.lua

Functions for playing online
--]]

local tankbobs = tankbobs
local gl = gl
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
local powerup_listBase
local wall_listBase
local healthbar_listBase
local healthbarBorder_listBase
local c_world_findClosestIntersection
local connection

local bit

local st_online_init
local st_online_done
local st_online_click
local st_online_button
local st_online_mouse
local st_online_step

local won
local newScreens

local refreshKeys = function()
	tankbobs.in_getKeys()

	if not connection.t or not c_world_getTanks()[connection.t] then
		return
	end

	--for i = connection.t, connection.t do
	for i = 1, 1 do
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
		if not (c_config_get("client.key.player" .. tostring(i) .. ".slow", true)) then
			c_config_set("client.key.player" .. tostring(i) .. ".slow", false)
		end
		if not (c_config_get("client.key.player" .. tostring(i) .. ".mod", true)) then
			c_config_set("client.key.player" .. tostring(i) .. ".mod", false)
		end

		local ks = "client.key.player" .. tostring(i) .. "."
		local kp, kl, cg = tankbobs.in_keyPressed, c_config_keyLayoutGet, c_config_get

		local function key(state, flag)
			local key = cg(ks .. state)

			if key ~= 303 and key ~= 304 then
				key = kl(key)

				local tank = c_world_getTanks()[connection.t]

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
		key("slow", SLOW)
		key("mod", MOD)
	end
end


function st_online_init()
	-- localize frequently used globals
	tankbobs = _G.tankbobs
	gl = _G.gl
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
	powerup_listBase = _G.powerup_listBase
	wall_listBase = _G.wall_listBase
	healthbar_listBase = _G.healthbar_listBase
	healthbarBorder_listBase = _G.healthbarBorder_listBase
	connection = _G.connection
	c_world_findClosestIntersection = _G.c_world_findClosestIntersection

	online = true

	bit = c_module_load "bit"

	game_refreshKeys = refreshKeys

	game_new()

	won = nil
	newScreens = nil

	-- pause label

	-- pause
	local function updatePause(widget)
		if c_world_getPaused() and not won and not quitScreen and connection.state > UNCONNECTED then
			widget.text = "Paused"
			tankbobs.in_grabClear()
		else
			widget.text = ""

			if quitScreen or connection.state < CONNECTED then
				tankbobs.in_grabClear()
			elseif not tankbobs.in_isGrabbed() then
				if not c_const_get("debug") or c_config_get("debug.client.grabMouse") then
					tankbobs.in_grabMouse(c_config_get("client.renderer.width") / 2, c_config_get("client.renderer.height") / 2)
				end
			end
		end
	end

	gui_addLabel(tankbobs.m_vec2(37.5, 50), "", updatePause, nil, c_config_get("client.renderer.pauseRed"), c_config_get("client.renderer.pauseGreen"), c_config_get("client.renderer.pauseBlue"), c_config_get("client.renderer.pauseAlpha"), c_config_get("client.renderer.pauseRed"), c_config_get("client.renderer.pauseGreen"), c_config_get("client.renderer.pauseBlue"), c_config_get("client.renderer.pauseAlpha"))

	-- create local world
	c_world_newWorld()

	c_protocol_setUnpersistProtocol(protocol_unpersist)
end

function st_online_done()
	gui_finish()

	if connection.state > REQUESTING then
		-- abort the connection
		tankbobs.n_newPacket(33)
		tankbobs.n_writeToPacket(tankbobs.io_fromChar(0x04))
		tankbobs.n_writeToPacket(connection.ui)
		tankbobs.n_sendPacket()
		tankbobs.n_sendPacket()
		tankbobs.n_sendPacket()
		tankbobs.n_sendPacket()
		tankbobs.n_sendPacket()
		tankbobs.n_quit()

		connection.state = UNCONNECTED
	end

	c_world_freeWorld()

	game_end()
end

function online_readPackets(d)
	local status, ip, port, data
	repeat
		if common_dro_getLevel() >= 4 then
			tankbobs.n_readPacket()
			status = false
		else
			status, ip, port, data = tankbobs.n_readPacket()
		end

		if status then
			local switch = string.byte(data, 1) data = data:sub(2)
			if switch == nil then
			elseif switch == 0xA2 then
				if connection.ping and not (common_dro_getLevel() >= 3 and math.random() >= 0.8) then
					local t = tankbobs.t_getTicks()
					connection.timestamp = tankbobs.io_toInt(data:sub(1, 4)) data = data:sub(5)
					connection.t = tankbobs.io_toInt(data:sub(1, 4)) data = data:sub(5)
					local tank = c_world_getTanks()[connection.t]
					if tank then
						if math.random() >= math.min(c_config_get("client.online.rsfMax"), c_config_get("client.online.randomSnapshotFilter") + ((common_dro_getLevel() >= 1) and 0.1 or 0)) then
							if c_config_get("client.online.stepAhead") then
								c_world_record(tank)
							end
							local state = tank.state
							c_protocol_unpersist(data)
							tank.state = state
							c_world_stepAhead(connection.timestamp, t)
						end
					else
						c_protocol_unpersist(data)
					end
				end
			elseif switch == 0xA3 then
				if #data >= 0 then
					-- server wants our tick
					tankbobs.n_newPacket(37)
					tankbobs.n_writeToPacket(tankbobs.io_fromChar(0x03))
					tankbobs.n_writeToPacket(connection.ui)
					tankbobs.n_writeToPacket(tankbobs.io_fromInt(tankbobs.t_getTicks()))
					tankbobs.n_sendPacket()
				end
			elseif switch == 0xA4 then
				if #data >= 1 then
					-- disconnected from server
					local reason = data:sub(1, data:find(tankbobs.io_fromChar(0x00)) - 1) data = data:sub(data:find(tankbobs.io_fromChar(0x00)) + 1)

					c_world_setPaused(true)

					gui_addLabel(tankbobs.m_vec2(20, 55), "You were disconnected from the server", nil, 1 / 3)
					gui_addLabel(tankbobs.m_vec2(20, 30), "Reason: " .. reason, nil, 1 / 3)

					connection.state = UNCONNECTED
				end
			elseif switch == 0xA5 then
				if #data >= 4 then
					-- server sent us our ping and tick offset
					connection.ping   = tankbobs.io_toInt(data:sub(1, 4)) data = data:sub(5)
					connection.offset = tankbobs.io_toInt(data:sub(1, 4)) data = data:sub(5)
				end
			elseif switch == 0xAA then
				if #data >= 9 then
					-- server sent us an event
					local id = tankbobs.io_toInt(data:sub(1, 4)) data = data:sub(5)

					-- tell the server we successfully received our event
					tankbobs.n_newPacket(37)
					tankbobs.n_writeToPacket(tankbobs.io_fromChar(0x0A))
					tankbobs.n_writeToPacket(connection.ui)
					tankbobs.n_writeToPacket(tankbobs.io_fromInt(id))
					tankbobs.n_sendPacket()

					local switch = string.byte(data, 1) data = data:sub(2)
					if switch == nil then
					elseif switch == 0x00 then
						-- win event
						if not won then
							local id = tankbobs.io_toInt(data:sub(1, 4)) data = data:sub(5)

							won = id

							c_world_setPaused(true)

							if c_world_gameTypeTeam() then
								if id ~= 0 then
									local name = "Red"
									local color = c_const_get("color_red")
									gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, color[1], color[2], color[3], 0.75, color[1], color[2], color[3], 0.8)
								else
									local name = "Blue"
									local color = c_const_get("color_blue")
									gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, color[1], color[2], color[3], 0.75, color[1], color[2], color[3], 0.8)
								end
							else
								local tank = c_world_getTanks()[won]
								if not tank then
									gui_addLabel(tankbobs.m_vec2(35, 50), "A player wins!", nil, 1.1, 1, 0, 0, 1)
									gui_addLabel(tankbobs.m_vec2(35, 80), "Couldn't find winning tank!", nil, 1.1, 1, 0, 0, 1)
								else
									local name = tostring(tank.name)
									gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, tank.color.r, tank.color.g, tank.color.b, 0.75, tank.color.r, tank.color.g, tank.color.b, 0.8)
								end
							end

							tankbobs.a_playSound(c_const_get("win_sound"))
						end
					end
				end
			end
		end
	until not status
end

function st_online_click(button, pressed, x, y)
	gui_click(button, pressed, x, y)
end

local quitLabel, yesAction, noAction
local function continue()
	if quitScreen then
		gui_removeWidget(quitLabel)
		gui_removeWidget(yesAction)
		gui_removeWidget(noAction)
		--c_world_setPaused(not c_world_getPaused())
		quitScreen = false
	end
end
function st_online_button(button, pressed)
	if not gui_button(button, pressed) then
		if pressed then
			if button == c_config_get("client.key.pause") then
				--if not won and not quitScreen then
					--c_world_setPaused(not c_world_getPaused())
				--end
			elseif button == c_config_get("client.key.screenToggle") then
				local screens = c_config_get("client.screens")

				if not newScreens then
					if screens == 0 then
						newScreens = c_config_get("game.players")
					else
						newScreens = 0
					end
				end

				c_config_set("client.screens", screens)
				newScreens = screens
			elseif button == 0x1B or button == c_config_get("client.key.quit") then  -- escape
				if connection.state < CONNECTED then
					c_state_goto(title_state)
				elseif quitScreen then
					continue()
				elseif won then
					c_state_goto(title_state)
				elseif c_world_getPaused() then
					--c_world_setPaused(not c_world_getPaused())
				else
					--c_world_setPaused(true)
					quitLabel = gui_addLabel(tankbobs.m_vec2(35.0, 60), "Really Quit?", nil, nil, c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"), c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"))
					yesAction = gui_addAction(tankbobs.m_vec2(35.0, 40), "Yes", nil, c_state_advance, nil, c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"), c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"))
					noAction = gui_addAction(tankbobs.m_vec2(65.0, 40), "No", nil, continue, nil, c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"), c_config_get("client.renderer.quitRed"), c_config_get("client.renderer.quitGreen"), c_config_get("client.renderer.quitBlue"), c_config_get("client.renderer.quitAlpha"))
					quitScreen = true
				end
			elseif button == c_config_get("client.key.exit") then
				c_state_goto(exit_state)
			end
		end

		if not connection.t or not c_world_getTanks()[connection.t] then
			return
		end

		--for i = 1, c_config_get("game.players") do
		for i = connection.t, connection.t do
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

function st_online_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

local function sendInput()
	local tank = c_world_getTanks()[connection.t]

	if not tank or not tank.exists then
		return
	end

	tankbobs.n_newPacket(35)
	tankbobs.n_writeToPacket(tankbobs.io_fromChar(0x02))
	tankbobs.n_writeToPacket(connection.ui)
	tankbobs.n_writeToPacket(tankbobs.io_fromShort(tank.state))
	tankbobs.n_sendPacket()
end

local lastITime
function st_online_step(d)
	online_readPackets(d)

	if not connection.ping then
		return
	end

	if connection.t and (c_config_get("client.ifps") == 0 or not lastITime or tankbobs.t_getTicks() - lastITime > common_FTM(c_config_get("client.ifps"))) then
		-- send server input
		lastITime = tankbobs.t_getTicks()
		sendInput()
	end

	c_world_step(d)

	game_step(d)

	gui_paint(d)
end

online_state =
{
	name   = "online_state",
	init   = st_online_init,
	done   = st_online_done,
	next   = function () return title_state end,

	click  = st_online_click,
	button = st_online_button,
	mouse  = st_online_mouse,

	main   = st_online_step
}
