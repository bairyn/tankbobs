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
local trails = {}
local camera
local zoom

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

	endOfGame = false
	camera = tankbobs.m_vec2(-50, -50)
	zoom = 1

	-- initialize renderer stuff
	-- wall textures are initialized per level
	local listOffset = 0

	wall_textures = gl.GenTextures(c_tcm_current_map.walls_n)

	for k, v in pairs(c_tcm_current_map.walls) do
		v.m.texture = wall_textures[k]

		gl.BindTexture("TEXTURE_2D", v.m.texture)
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
		tankbobs.r_loadImage2D(c_const_get("textures_dir") .. v.texture, c_const_get("textures_default"))
	end

	-- scores
	local function updateScores(widget)
		local length = 0

		widget.text = ""

		for k, v in pairs(c_world_getTanks()) do
			local name = tostring(c_config_get("config.game.player" .. tostring(k) .. ".name"))

			if #name > length then
				length = #name
			end
		end

		if length < 1 then
			length = 1
		end

		for k, v in pairs(c_world_getTanks()) do
			local name, between, score

			if widget.text:len() ~= 0 then
				widget.text = widget.text .. "\n"
			end

			name = tostring(c_config_get("config.game.player" .. tostring(k) .. ".name"))
			between = string.rep("  ", length - #name + 1)
			score = tostring(v.score)

			widget.text = widget.text .. name .. between .. score
		end
	end

	gui_addLabel(tankbobs.m_vec2(7.5, 92.5), "", updateScores, 0.5, c_config_get("config.game.scoresRed"), c_config_get("config.game.scoresGreen"), c_config_get("config.game.scoresBlue"), c_config_get("config.game.scoresAlpha"), c_config_get("config.game.scoresRed"), c_config_get("config.game.scoresGreen"), c_config_get("config.game.scoresGreen"), c_config_get("config.game.scoresAlpha"))

	-- fps counter
	local function updateFPS(widget)
		local fps = fps

		widget.text = tostring(fps - (fps % 1))
	end

	if c_config_get("config.game.fpsCounter") then
		gui_addLabel(tankbobs.m_vec2(92.5, 92.5), "", updateFPS, 0.5, c_config_get("config.game.fpsRed"), c_config_get("config.game.fpsGreen"), c_config_get("config.game.fpsBlue"), c_config_get("config.game.fpsAlpha"), c_config_get("config.game.fpsRed"), c_config_get("config.game.fpsGreen"), c_config_get("config.game.fpsGreen"), c_config_get("config.game.fpsAlpha"))
	end

	-- pause
	local function updatePause(widget)
		if c_world_getPaused() and not endOfGame then
			widget.text = "Paused"
			tankbobs.in_grabClear()
		else
			widget.text = ""
			if not tankbobs.in_isGrabbed() then
				tankbobs.in_grabMouse(c_config_get("config.renderer.width") / 2, c_config_get("config.renderer.height") / 2)
			end
		end
	end

	gui_addLabel(tankbobs.m_vec2(37.5, 50), "", updatePause, nil, c_config_get("config.game.pauseRed"), c_config_get("config.game.pauseGreen"), c_config_get("config.game.pauseBlue"), c_config_get("config.game.pauseAlpha"), c_config_get("config.game.pauseRed"), c_config_get("config.game.pauseGreen"), c_config_get("config.game.pauseBlue"), c_config_get("config.game.pauseAlpha"))

	-- initialize the world
	c_world_newWorld()

	for i = 1, c_config_get("config.game.players") + c_config_get("config.game.computers") do
		if i > c_const_get("max_tanks") then
			break
		end

		local tank = c_world_tank:new()
		table.insert(c_world_getTanks(), tank)

		if not (c_config_get("config.game.player" .. tostring(i) .. ".name", nil, true)) then
			c_config_set("config.game.player" .. tostring(i) .. ".name", "Player" .. tostring(i))
		end

		tank.name = c_config_get("config.game.player" .. tostring(i) .. ".name")
		if not (c_config_get("config.game.player" .. tostring(i) .. ".color", nil, true)) then
			c_config_set("config.game.player" .. tostring(i) .. ".color.r", c_config_get("config.game.defaultTankRed"))
			c_config_set("config.game.player" .. tostring(i) .. ".color.g", c_config_get("config.game.defaultTankBlue"))
			c_config_set("config.game.player" .. tostring(i) .. ".color.b", c_config_get("config.game.defaultTankGreen"))
			c_config_set("config.game.player" .. tostring(i) .. ".color.a", c_config_get("config.game.defaultTankAlpha"))
		end
		tank.color.r = c_config_get("config.game.player" .. tostring(i) .. ".color.r")
		tank.color.g = c_config_get("config.game.player" .. tostring(i) .. ".color.g")
		tank.color.b = c_config_get("config.game.player" .. tostring(i) .. ".color.b")

		-- spawn
		c_world_tank_spawn(tank)
	end
end

function st_play_done()
	gui_finish()

	-- free the cursor
	tankbobs.in_grabClear()

	-- free renderer stuff
	gl.DeleteTextures(wall_textures)
	for k, v in pairs(trails) do
		if gl.IsList(v[3]) then
			gl.DeleteLists(v[3], 1)
		end
	end

	c_tcm_unload_extra_data(false)
	c_weapon_clear(false)

	-- reset texenv
	gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

	-- free the world
	c_world_freeWorld()
end

function st_play_click(button, pressed, x, y)
	gui_click(button, pressed, x, y)

	if pressed and endOfGame then
		c_state_new(play_state)
	end
end

function st_play_button(button, pressed)
	if not gui_button(button, pressed) then
		if pressed then
			if button == 0x0D and endOfGame then
				c_state_new(play_state)
			elseif button == c_config_get("config.key.pause") then
				if not endOfGame then
					c_world_setPaused(not c_world_getPaused())
				end
			elseif button == 0x1B or button == c_config_get("config.key.quit") then
				if endOfGame then
					c_state_new(play_state)
				else
					c_state_advance()
				end
			elseif button == c_config_get("config.key.exit") then
				c_state_new(exit_state)
			end
		end
	end

	local c_world_tanks = c_world_getTanks()

	for i = 1, c_config_get("config.game.players") + c_config_get("config.game.computers") do
		if not (c_config_get("config.key.player" .. tostring(i) .. ".fire", nil, true)) then
			c_config_set("config.key.player" .. tostring(i) .. ".fire", false)
		end
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

		if button == c_config_get("config.key.player" .. tostring(i) .. ".fire") then
			c_world_tanks[i].state.firing = pressed
		end
		if button == c_config_get("config.key.player" .. tostring(i) .. ".forward") then
			c_world_tanks[i].state.forward = pressed
		end
		if button == c_config_get("config.key.player" .. tostring(i) .. ".back") then
			c_world_tanks[i].state.back = pressed
		end
		if button == c_config_get("config.key.player" .. tostring(i) .. ".left") then
			c_world_tanks[i].state.left = pressed
		end
		if button == c_config_get("config.key.player" .. tostring(i) .. ".right") then
			c_world_tanks[i].state.right = pressed
		end
		if button == c_config_get("config.key.player" .. tostring(i) .. ".special") then
			c_world_tanks[i].state.special = pressed
		end
	end
end

function st_play_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

local frame = 3
local a = {{0, 0}, {0, 0}}  -- aim-aid table
local w, t = {{0, 0}, {0, 0}, {0, 0}, {0, 0}}, {{0, 0}, {0, 0}, {0, 0}, {0, 0}}
function st_play_step(d)
	frame = frame - 1

	if frame <= 0 then
		frame = 256

		math.randomseed(os.time() * tankbobs.t_getTicks() + 10 * 768 * d)
	end

	-- test for end of game
	if endOfGame then
		c_world_setPaused(true)
	end

	local fragLimit = c_config_get("config.game.fragLimit")
	if fragLimit > 0 then
		for k, v in pairs(c_world_getTanks()) do
			if v.score >= fragLimit then
				endOfGame = true

				c_world_setPaused(true)

				local name = tostring(c_config_get("config.game.player" .. tostring(k) .. ".name"))
				gui_addLabel(tankbobs.m_vec2(35, 50), name .. " wins!", nil, 1.1, v.color.r, v.color.g, v.color.b, 0.75, v.color.r, v.color.g, v.color.b, 0.75)
			end
		end
	end

	c_world_step(d)

	-- adjust the camera
	local uppermost
	local lowermost
	local rightmost
	local leftmost
	-- Position the camera so that all tanks and powerups are shown, while zooming in as much as possible
	for _, v in pairs(c_world_getTanks()) do
		if not leftmost or v.p[1].x < leftmost then
			leftmost = v.p[1].x
		end
		if not rightmost or v.p[1].x > rightmost then
			rightmost = v.p[1].x
		end

		if not lowermost or v.p[1].y < lowermost then
			lowermost = v.p[1].y
		end
		if not uppermost or v.p[1].y > uppermost then
			uppermost = v.p[1].y
		end
	end
	for _, v in pairs(c_world_getPowerups()) do
		if v.spawner.focus then
			if not leftmost or v.p[1].x < leftmost then
				leftmost = v.p[1].x
			end
			if not rightmost or v.p[1].x > rightmost then
				rightmost = v.p[1].x
			end

			if not lowermost or v.p[1].y < lowermost then
				lowermost = v.p[1].y
			end
			if not uppermost or v.p[1].y > uppermost then
				uppermost = v.p[1].y
			end
		end
	end
	if not uppermost or not lowermost or not rightmost or not leftmost then
		return
	end
	local m = c_tcm_current_map
	-- FIXME: this is broken
	--uppermost = math.min(m.uppermost - 95, uppermost)
	--lowermost = math.max(m.lowermost + 95, lowermost)
	--rightmost = math.min(m.rightmost - 95, rightmost)
	--leftmost  = math.max(m.leftmost  + 95,  leftmost)

	gl.Translate(50, 50, 0)

	local distance = math.abs(rightmost - leftmost) > math.abs(uppermost - lowermost) and math.abs(rightmost - leftmost) or math.abs(uppermost - lowermost)
	local scale = 100 / (distance + c_config_get("config.client.cameraExtraFOV"))
	if scale > 1 then
		scale = 1
	end
	zoom = common_lerp(zoom, scale, d * c_config_get("config.client.cameraSpeed"))
	gl.Scale(zoom, zoom, 1)

	camera = common_lerp(camera, tankbobs.m_vec2(-(rightmost + leftmost) / 2, -(uppermost + lowermost) / 2), d * c_config_get("config.client.cameraSpeed"))
	gl.Translate(camera.x, camera.y, 0)

	-- draw tanks and walls
	for i = 1, c_const_get("tcm_maxLevel") do
		for k, v in pairs(c_tcm_current_map.walls) do
			if i == c_const_get("tcm_tankLevel") then
				-- render tanks
				for k, v in pairs(c_world_getTanks()) do
					if(v.exists) then
						gl.PushAttrib("CURRENT_BIT")
							gl.PushMatrix()
								gl.Translate(v.p[1].x, v.p[1].y, 0)
								gl.Rotate(tankbobs.m_degrees(v.r), 0, 0, 1)
								if not (c_config_get("config.game.player" .. tostring(k) .. ".color", nil, true)) then
									c_config_set("config.game.player" .. tostring(k) .. ".color.r", c_config_get("config.game.defaultTankRed"))
									c_config_set("config.game.player" .. tostring(k) .. ".color.g", c_config_get("config.game.defaultTankBlue"))
									c_config_set("config.game.player" .. tostring(k) .. ".color.b", c_config_get("config.game.defaultTankGreen"))
									c_config_set("config.game.player" .. tostring(k) .. ".color.a", c_config_get("config.game.defaultTankAlpha"))
								end
								gl.Color(v.color.r, v.color.g, v.color.b, 1)
								gl.TexEnv("TEXTURE_ENV_COLOR", v.color.r, v.color.g, v.color.b, 1)
								-- blend color with tank texture
								gl.CallList(tank_listBase)
								-- white outline
								gl.Color(1, 1, 1, 0.875)
								gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 0.875)
								gl.CallList(tankBorder_listBase)

								if v.weapon then
									gl.CallList(v.weapon.m.p.list)
								end
							gl.PopMatrix()
						gl.PopAttrib()
					end
				end
			end

			if v.l == i and v.m.pos then
				gl.Color(1, 1, 1, 1)
				gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1)
				gl.BindTexture("TEXTURE_2D", v.m.texture)

				gl.EnableClientState("VERTEX_ARRAY,TEXTURE_COORD_ARRAY")
				w[1][1], w[1][2] = v.m.pos[1].x, v.m.pos[1].y
				w[2][1], w[2][2] = v.m.pos[2].x, v.m.pos[2].y
				w[3][1], w[3][2] = v.m.pos[3].x, v.m.pos[3].y
				t[1][1], t[1][2] = v.t[1].x, v.t[1].y
				t[2][1], t[2][2] = v.t[2].x, v.t[2].y
				t[3][1], t[3][2] = v.t[3].x, v.t[3].y
				if v.m.pos[4] then
					w[4][1], w[4][2] = v.m.pos[4].x, v.m.pos[4].y
				else
					t[4][1], t[4][2] = v.t[4].x, v.t[4].y
				end
				gl.VertexPointer(w)
				gl.TexCoordPointer(t)
				gl.DrawArrays("POLYGON", 0, #v.m.pos)  -- TODO: FIXME: figure out why texture coordinates are being ignored and remove immediate mode below
				gl.DisableClientState("VERTEX_ARRAY,TEXTURE_COORD_ARRAY")

				gl.Begin(v.m.pos[4] and "QUADS" or "TRIANGLES")
					gl.TexCoord(v.t[1].x, v.t[1].y) gl.Vertex(v.m.pos[1].x, v.m.pos[1].y)
					gl.TexCoord(v.t[2].x, v.t[2].y) gl.Vertex(v.m.pos[2].x, v.m.pos[2].y)
					gl.TexCoord(v.t[3].x, v.t[3].y) gl.Vertex(v.m.pos[3].x, v.m.pos[3].y)
					if v.m.pos[4] then
						gl.TexCoord(v.t[4].x, v.t[4].y) gl.Vertex(v.m.pos[4].x, v.m.pos[4].y)
					end
				gl.End()
			end
		end
	end

	-- aiming aids
	gl.EnableClientState("VERTEX_ARRAY")
	for _, v in pairs(c_world_getTanks()) do
		if v.exists then
			if (v.weapon and v.weapon.aimAid) or (v.cd.aimAid) then
				gl.PushAttrib("ENABLE_BIT")
					local b
					local vec = tankbobs.m_vec2()
					local start, endP = tankbobs.m_vec2(v.p[1]), tankbobs.m_vec2()
	
					vec.t = v.r
					vec.R = c_const_get("aimAid_startDistance")
					start:add(vec)
	
					endP(start)
					vec.R = c_const_get("aimAid_maxDistance")
					endP:add(vec)
	
					b, vec = c_world_findClosestIntersection(start, endP)
					if b then
						endP = vec
					end
	
					a[1][1] = start.x a[1][2] = start.y
					a[2][1] = endP.x a[2][2] = endP.y
					gl.Disable("TEXTURE_2D")
					gl.Color(0.9, 0.1, 0.1, 1)
					gl.TexEnv("TEXTURE_ENV_COLOR", 0.9, 0.1, 0.1, 1)
					gl.VertexPointer(a)
					gl.LineWidth(c_const_get("aimAid_width"))
					gl.DrawArrays("LINES", 0, 2)
				gl.PopAttrib()
			end
		end
	end
	gl.DisableClientState("VERTEX_ARRAY")

	-- teleporters are drawn on top everything above
	--gl.CallLists(play_teleporter_listsMultiple)

	-- powerups are drawn next
	for _, v in pairs(c_world_getPowerups()) do
		gl.PushMatrix()
			local c = c_world_getPowerupTypeByName(v.typeName).c
			gl.Color(c.r, c.g, c.b, c.a)
			gl.TexEnv("TEXTURE_ENV_COLOR", c.r, c.g, c.b, c.a)
			gl.Translate(v.p[1].x, v.p[1].y, 0)
			gl.Rotate(tankbobs.m_degrees(v.r), 0, 0, 1)
			gl.CallList(powerup_listBase)
		gl.PopMatrix()
	end

	-- projectiles
	for _, v in pairs(c_weapon_getProjectiles()) do
		if v.weapon.trail == 0 then  -- only draw the trail
			gl.PushMatrix()
				gl.Translate(v.p[1].x, v.p[1].y, 0)
				gl.Rotate(tankbobs.m_degrees(v.r), 0, 0, 1)
				gl.CallList(v.weapon.m.p.projectileList)
			gl.PopMatrix()
		end
	end

	-- trails
	for k, v in pairs(trails) do
		-- {time left, maximum intensity, list}
		v[1] = v[1] - d
		if v[1] <= 0 then
			gl.DeleteLists(v[3], 1)

			table.remove(trails, k)

			return
		end

		gl.Color(1, 1, 1, v[1] / v[2])
		gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, v[2] / v[3])
		gl.CallList(v[3])
	end

	-- healthbars
	for k, v in pairs(c_world_getTanks()) do
		if v.exists then
			gl.PushMatrix()
				gl.Translate(v.p[1].x, v.p[1].y, 0)
				gl.Rotate(tankbobs.m_degrees(v.r) + c_const_get("healthbar_rotation"), 0, 0, 1)
				if not (c_config_get("config.game.player" .. tostring(k) .. ".color", nil, true)) then
					c_config_set("config.game.player" .. tostring(k) .. ".color.r", c_config_get("config.game.defaultTankRed"))
					c_config_set("config.game.player" .. tostring(k) .. ".color.g", c_config_get("config.game.defaultTankBlue"))
					c_config_set("config.game.player" .. tostring(k) .. ".color.b", c_config_get("config.game.defaultTankGreen"))
					c_config_set("config.game.player" .. tostring(k) .. ".color.a", c_config_get("config.game.defaultTankAlpha"))
				end

				gl.Color(v.color.r, v.color.g, v.color.b, 1)
				gl.TexEnv("TEXTURE_ENV_COLOR", v.color.r, v.color.g, v.color.b, 1)
				local scale = v.health / c_const_get("tank_health")
				if scale < 1 then
					scale = 1
				end
				gl.Scale(scale, 1, 1)
				gl.CallList(healthbarBorder_listBase)
				gl.Scale(1 / scale, 1, 1)
				if v.health >= c_const_get("tank_highHealth") then
					gl.Color(0.1, 1, 0.1, 1)
					gl.TexEnv("TEXTURE_ENV_COLOR", 0.1, 1, 0.1, 1)
				elseif v.health > c_const_get("tank_lowHealth") then
					gl.Color(1, 1, 0.1, 1)
					gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 0.1, 1)
				else
					gl.Color(1, 0.1, 0.1, 1)
					gl.TexEnv("TEXTURE_ENV_COLOR", 1, 0.1, 0.1, 1)
				end
				gl.Scale(v.health / c_const_get("tank_health"), 1, 1)
				gl.CallList(healthbar_listBase)
			gl.PopMatrix()
		end
	end

	-- scores, FPS, rest of HUD, etc.
	gui_paint(d)

	if c_world_getPaused() then
		return
	end

	-- play sounds and insert trails
	for _, v in pairs(c_world_getTanks()) do
		if v.state.firing then
			if v.m.lastFireTime ~= v.lastFireTime then
				v.m.lastFireTime = v.lastFireTime

				if v.m.empty then
					tankbobs.a_playSound(c_const_get("emptyTrigger_sound"))
				elseif v.weapon then
					if type(v.weapon.fireSound) == "table" then
						tankbobs.a_playSound(c_const_get("weaponAudio_dir") .. v.weapon.fireSound[math.random(1, #v.weapon.fireSound)])
					elseif type(v.weapon.fireSound) == "string" then
						tankbobs.a_playSound(c_const_get("weaponAudio_dir") .. v.weapon.fireSound)
					end

					if v.weapon.trail ~= 0 and v.weapon.trailWidth ~= 0 then
						-- calculate the beginning and end point before the insert
						local start, endP = tankbobs.m_vec2(v.p[1]), tankbobs.m_vec2()
						local vec = tankbobs.m_vec2()
						local list = gl.GenLists(1)
						local b

						vec.t = v.r
						vec.R = c_const_get("trail_startDistance")
						start:add(vec)

						endP(start)
						vec.R = c_const_get("trail_maxDistance")
						endP:add(vec)

						b, vec = c_world_findClosestIntersection(start, endP)
						if b then
							endP = vec
						end

						gl.NewList(list, "COMPILE_AND_EXECUTE")
							local a = {}
							local t = {}
							local offset = tankbobs.m_vec2()
							local tmp = tankbobs.m_vec2()

							offset.t = -1 / (endP - start).t
							offset.R = v.r

							gl.BindTexture("TEXTURE_2D", v.weapon.m.p.projectileTexture[1])
							gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")
							gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
							gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")

							gl.Begin("QUADS")
								local length = (endP - start).R

								tmp(v.weapon.projectileTexturer[1])
								tmp.R = tmp.R * length / v.weapon.projectileRender[1].R
								gl.TexCoord(tmp.x, tmp.y)
								tmp = start + offset
								gl.Vertex(tmp.x, tmp.y)

								tmp(v.weapon.projectileTexturer[2])
								tmp.R = tmp.R * length / v.weapon.projectileRender[2].R
								gl.TexCoord(tmp.x, tmp.y)
								tmp = start - offset
								gl.Vertex(tmp.x, tmp.y)

								tmp(v.weapon.projectileTexturer[3])
								tmp.R = tmp.R * length / v.weapon.projectileRender[3].R
								gl.TexCoord(tmp.x, tmp.y)
								tmp = endP - offset
								gl.Vertex(tmp.x, tmp.y)

								tmp(v.weapon.projectileTexturer[4])
								tmp.R = tmp.R * length / v.weapon.projectileRender[4].R
								gl.TexCoord(tmp.x, tmp.y)
								tmp = endP + offset
								gl.Vertex(tmp.x, tmp.y)
							gl.End()
						gl.EndList()

						table.insert(trails, {v.weapon.trail, v.weapon.trail, list})
					end

				end
			end
		end

		if v.m.lastCollideTime and v.m.lastCollideTimeB ~= v.m.lastCollideTime then
			v.m.lastCollideTimeB = v.m.lastCollideTime

			tankbobs.a_setVolumeChunk(c_const_get("collide_sound"), v.m.intensity * c_config_get("config.client.volume"))  -- this is temporarily commented out while Mix_VolumeChunk affects the volume of other samples
			tankbobs.a_playSound(c_const_get("collide_sound"))
		end

		if v.m.lastDamageTime and v.m.lastDamageTimeB ~= v.m.lastDamageTime then
			v.m.lastDamageTimeB = v.m.lastDamageTime

			tankbobs.a_playSound(c_const_get("damage_sound"))
		end

		if v.spawning and v.m.lastDieTimeB ~= v.m.lastDieTime then
			v.m.lastDieTimeB = v.m.lastDieTime

			tankbobs.a_playSound(c_const_get("die_sound"))
		end

		if v.m.lastPickupTime and v.m.lastPickupTimeB ~= v.m.lastPickupTime then
			v.m.lastPickupTimeB = v.m.lastPickupTime 

			tankbobs.a_playSound(c_const_get("powerupPickup_sound"))
		end
	end

	for _, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
		if v.m.lastSpawnTimeB ~= v.m.lastSpawnTime then
			v.m.lastSpawnTimeB = v.m.lastSpawnTime

			tankbobs.a_playSound(c_const_get("powerupSpawn_sound"))
		end
	end

	for _, v in pairs(c_weapon_getProjectiles()) do
		if v.collisions > 0 and v.collisions ~= v.m.lastCollisions and v.weapon.trail == 0 and v.weapon.trailWidth == 0 then
			v.m.lastCollisions = v.collisions

			tankbobs.a_playSound(c_const_get("collideProjectile_sounds")[math.random(1, #c_const_get("collideProjectile_sounds"))])
		end
	end
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
