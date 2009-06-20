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
local tank_textures
local powerup_listBase
local powerup_textures
local wall_listBase
local wall_textures
local healthbar_listBase
local healthbarBorder_listBase
local healthbar_texture
local healthbarBorder_texture

local st_play_init
local st_play_done
local st_play_click
local st_play_button
local st_play_mouse
local st_play_step

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

	-- initialize renderer stuff
	c_const_set("tank_renderx1", -2.0, 1) c_const_set("tank_rendery1",  2.0, 1)
	c_const_set("tank_renderx2", -2.0, 1) c_const_set("tank_rendery2", -2.0, 1)
	c_const_set("tank_renderx3",  2.0, 1) c_const_set("tank_rendery3", -2.0, 1)
	c_const_set("tank_renderx4",  2.0, 1) c_const_set("tank_rendery4",  2.0, 1)
	c_const_set("tank_texturex1", 1.0, 1) c_const_set("tank_texturey1", 1.0, 1)
	c_const_set("tank_texturex2", 0.0, 1) c_const_set("tank_texturey2", 1.0, 1)
	c_const_set("tank_texturex3", 0.0, 1) c_const_set("tank_texturey3", 0.1, 1)  -- eliminate fuzzy top
	c_const_set("tank_texturex4", 1.0, 1) c_const_set("tank_texturey4", 0.1, 1)  -- eliminate fuzzy top

	tank_listBase = gl.GenLists(1)
	tank_textures = gl.GenTextures(1)

	if tank_listBase == 0 then
		error "st_play_init: could not generate lists"
	end

	gl.BindTexture("TEXTURE_2D", tank_textures[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("tank"), c_const_get("textures_default"))

	gl.NewList(tank_listBase, "COMPILE_AND_EXECUTE")  -- execute to remove "choppy" effect
		-- blend tank with color
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")
		gl.BindTexture("TEXTURE_2D", tank_textures[1])
		gl.Begin("QUADS")
			gl.TexCoord(c_const_get("tank_texturex1"), c_const_get("tank_texturey1")) gl.Vertex(c_const_get("tank_renderx1"), c_const_get("tank_rendery1"))
			gl.TexCoord(c_const_get("tank_texturex2"), c_const_get("tank_texturey2")) gl.Vertex(c_const_get("tank_renderx2"), c_const_get("tank_rendery2"))
			gl.TexCoord(c_const_get("tank_texturex3"), c_const_get("tank_texturey3")) gl.Vertex(c_const_get("tank_renderx3"), c_const_get("tank_rendery3"))
			gl.TexCoord(c_const_get("tank_texturex4"), c_const_get("tank_texturey4")) gl.Vertex(c_const_get("tank_renderx4"), c_const_get("tank_rendery4"))
		gl.End()
	gl.EndList()

	powerup_listBase = gl.GenLists(1)
	powerup_textures = gl.GenTextures(1)

	if powerup_listBase == 0 then
		error "st_play_init: could not generate lists"
	end

	c_const_set("powerup_renderx1",  0, 1) c_const_set("powerup_rendery1",  1, 1)
	c_const_set("powerup_renderx2",  0, 1) c_const_set("powerup_rendery2",  0, 1)
	c_const_set("powerup_renderx3",  1, 1) c_const_set("powerup_rendery3",  0, 1)
	c_const_set("powerup_renderx4",  1, 1) c_const_set("powerup_rendery4",  1, 1)
	c_const_set("powerup_texturex1", 0, 1) c_const_set("powerup_texturey1", 1, 1)
	c_const_set("powerup_texturex2", 0, 1) c_const_set("powerup_texturey2", 0, 1)
	c_const_set("powerup_texturex3", 1, 1) c_const_set("powerup_texturey3", 0, 1)
	c_const_set("powerup_texturex4", 1, 1) c_const_set("powerup_texturey4", 1, 1)

	gl.BindTexture("TEXTURE_2D", powerup_textures[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("powerup"), c_const_get("textures_default"))

	gl.NewList(powerup_listBase, "COMPILE_AND_EXECUTE")
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")
		gl.BindTexture("TEXTURE_2D", powerup_textures[1])
		gl.Begin("QUADS")
			gl.TexCoord(c_const_get("powerup_texturex1"), c_const_get("powerup_texturey1")) gl.Vertex(c_const_get("powerup_renderx1"), c_const_get("powerup_rendery1"))
			gl.TexCoord(c_const_get("powerup_texturex2"), c_const_get("powerup_texturey2")) gl.Vertex(c_const_get("powerup_renderx2"), c_const_get("powerup_rendery2"))
			gl.TexCoord(c_const_get("powerup_texturex3"), c_const_get("powerup_texturey3")) gl.Vertex(c_const_get("powerup_renderx3"), c_const_get("powerup_rendery3"))
			gl.TexCoord(c_const_get("powerup_texturex4"), c_const_get("powerup_texturey4")) gl.Vertex(c_const_get("powerup_renderx4"), c_const_get("powerup_rendery4"))
		gl.End()
	gl.EndList()

	local listOffset = 0

	wall_listBase = gl.GenLists(c_tcm_current_map.walls_n)
	wall_textures = gl.GenTextures(c_tcm_current_map.walls_n)

	if wall_listBase == 0 then
		error "st_play_init: could not generate lists"
	end

	for k, v in pairs(c_tcm_current_map.walls) do
		v.m.list = wall_listBase + listOffset
		v.m.texture = wall_textures[k]

		gl.BindTexture("TEXTURE_2D", v.m.texture)
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
		tankbobs.r_loadImage2D(c_const_get("textures_dir") .. v.texture, c_const_get("textures_default"))

		-- TODO: use vertex buffers to render dynamic walls.  Static walls will always be drawn in their initial location until then
		gl.NewList(v.m.list, "COMPILE_AND_EXECUTE")
			gl.Color(1, 1, 1, 1)
			gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 1)
			gl.BindTexture("TEXTURE_2D", v.m.texture)
			gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

			gl.Begin("POLYGON")
				for i = 1, #v.p do
					gl.TexCoord(v.t[i].x, v.t[i].y)
					gl.Vertex(v.p[i].x, v.p[i].y)
				end
			gl.End()
		gl.EndList()

		listOffset = listOffset + 1
	end

	for _, v in pairs(c_weapon_getWeapons()) do
		v.m.list = gl.GenLists(1)
		v.m.projectileList = gl.GenLists(1)

		v.m.texture = gl.GenTextures(1)
		v.m.projectileTexture = gl.GenTextures(1)

		gl.BindTexture("TEXTURE_2D", v.m.texture[1])
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
		tankbobs.r_loadImage2D(c_const_get("weaponTextures_dir") .. v.texture, c_const_get("textures_default"))
		gl.BindTexture("TEXTURE_2D", v.m.projectileTexture[1])
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
		tankbobs.r_loadImage2D(c_const_get("weaponTextures_dir") .. v.projectileTexture, c_const_get("textures_default"))

		gl.NewList(v.m.list, "COMPILE_AND_EXECUTE")
			gl.Color(1, 1, 1, 1)
			gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 1)
			gl.BindTexture("TEXTURE_2D", v.m.texture[1])
			gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

			gl.Begin("POLYGON")
				for i = 1, #v.render do
					gl.TexCoord(v.texturer[i].x, v.texturer[i].y)
					gl.Vertex(v.render[i].x, v.render[i].y)
				end
			gl.End()
		gl.EndList()

		gl.NewList(v.m.projectileList, "COMPILE_AND_EXECUTE")
			gl.Color(1, 1, 1, 1)
			gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 1)
			gl.BindTexture("TEXTURE_2D", v.m.projectileTexture[1])
			gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

			gl.Begin("POLYGON")
				for i = 1, #v.projectileRender do
					gl.TexCoord(v.projectileTexturer[i].x, v.projectileTexturer[i].y)
					gl.Vertex(v.projectileRender[i].x, v.projectileRender[i].y)
				end
			gl.End()
		gl.EndList()
	end

	healthbar_listBase = gl.GenLists(1)
	healthbarBorder_listBase = gl.GenLists(1)
	healthbar_texture = gl.GenTextures(1)
	healthbarBorder_texture = gl.GenTextures(1)

	gl.BindTexture("TEXTURE_2D", healthbar_texture[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("healthbar_texture"), c_const_get("textures_default"))
	gl.BindTexture("TEXTURE_2D", healthbarBorder_texture[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("healthbarBorder_texture"), c_const_get("texturesBorder_default"))

	c_const_set("healthbar_texture", "", 1)
	c_const_set("healthbar_renderx1", -0.875, 1) c_const_set("healthbar_rendery1", -2.875, 1)
	c_const_set("healthbar_renderx2", -0.875, 1) c_const_set("healthbar_rendery2", -2.5, 1)
	c_const_set("healthbar_renderx3",  0.875, 1) c_const_set("healthbar_rendery3", -2.5, 1)
	c_const_set("healthbar_renderx4",  0.875, 1) c_const_set("healthbar_rendery4", -2.875, 1)
	c_const_set("healthbar_texturex1", 0, 1) c_const_set("healthbar_texturey1", 1, 1)
	c_const_set("healthbar_texturex2", 0, 1) c_const_set("healthbar_texturey2", 0, 1)
	c_const_set("healthbar_texturex3", 1, 1) c_const_set("healthbar_texturey3", 0, 1)
	c_const_set("healthbar_texturex4", 1, 1) c_const_set("healthbar_texturey4", 1, 1)
	c_const_set("healthbarBorder_renderx1", -1, 1) c_const_set("healthbarBorder_rendery1", -3, 1)
	c_const_set("healthbarBorder_renderx2", -1, 1) c_const_set("healthbarBorder_rendery2", -2.25, 1)
	c_const_set("healthbarBorder_renderx3",  1, 1) c_const_set("healthbarBorder_rendery3", -2.25, 1)
	c_const_set("healthbarBorder_renderx4",  1, 1) c_const_set("healthbarBorder_rendery4", -3, 1)
	c_const_set("healthbarBorder_texturex1", 0, 1) c_const_set("healthbarBorder_texturey1", 1, 1)
	c_const_set("healthbarBorder_texturex2", 0, 1) c_const_set("healthbarBorder_texturey2", 0, 1)
	c_const_set("healthbarBorder_texturex3", 1, 1) c_const_set("healthbarBorder_texturey3", 0, 1)
	c_const_set("healthbarBorder_texturex4", 1, 1) c_const_set("healthbarBorder_texturey4", 1, 1)
	c_const_set("healthbar_rotation", 270, 1)

	gl.NewList(healthbar_listBase, "COMPILE_AND_EXECUTE")
		gl.BindTexture("TEXTURE_2D", healthbar_texture[1])
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

		gl.Begin("QUADS")
			for i = 1, 4 do
				gl.TexCoord(c_const_get("healthbar_texturex" .. i), c_const_get("healthbar_texturey" .. i))
				gl.Vertex(c_const_get("healthbar_renderx" .. i), c_const_get("healthbar_rendery" .. i))
			end
		gl.End()
	gl.EndList()

	gl.NewList(healthbarBorder_listBase, "COMPILE_AND_EXECUTE")
		gl.BindTexture("TEXTURE_2D", healthbarBorder_texture[1])
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

		gl.Begin("QUADS")
			for i = 1, 4 do
				gl.TexCoord(c_const_get("healthbarBorder_texturex" .. i), c_const_get("healthbarBorder_texturey" .. i))
				gl.Vertex(c_const_get("healthbarBorder_renderx" .. i), c_const_get("healthbarBorder_rendery" .. i))
			end
		gl.End()
	gl.EndList()

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
		if c_world_getPaused() then
			widget.text = "Paused"
		else
			widget.text = ""
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

		-- spawn
		c_world_tank_spawn(tank)
	end
end

function st_play_done()
	gui_finish()

	gl.DeleteLists(tank_listBase, 1)
	gl.DeleteLists(wall_listBase, c_tcm_current_map.walls_n)
	gl.DeleteLists(powerup_listBase, 1)

	gl.DeleteTextures(tank_textures)
	gl.DeleteTextures(wall_textures)
	gl.DeleteTextures(powerup_textures)

	for _, v in pairs(c_weapon_getWeapons()) do
		gl.DeleteLists(v.m.list, 1)
		gl.DeleteLists(v.m.projectileList, 1)
		gl.DeleteTextures(v.m.texture, 1)
		gl.DeleteTextures(v.m.projectileTexture, 1)
	end

	gl.DeleteLists(healthbar_listBase, 1)
	gl.DeleteLists(healthbarBorder_listBase, 1)
	gl.DeleteTextures(healthbar_texture)
	gl.DeleteTextures(healthbarBorder_texture)

	c_tcm_unload_extra_data()
	c_weapon_clear()

	-- reset texenv to avoid messing the GUI up
	gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

	-- free the world
	c_world_freeWorld()
end

function st_play_click(button, pressed, x, y)
	if pressed then
		gui_click(x, y)
	end
end

function st_play_button(button, pressed)
	if pressed then
		if not gui_button(button) then
			if button == c_config_get("config.key.pause") then
				c_world_setPaused(not c_world_getPaused())
			elseif button == 0x1B or button == c_config_get("config.key.quit") then
				c_state_advance()
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

function st_play_step(d)
	-- TODO: use display lists and find a better algorithm for "depth"

	c_world_step(d)

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
								gl.Color(c_config_get("config.game.player" .. tostring(k) .. ".color.r"), c_config_get("config.game.player" .. tostring(k) .. ".color.g"), c_config_get("config.game.player" .. tostring(k) .. ".color.b"), 1)
								gl.TexEnv("TEXTURE_ENV_COLOR", c_config_get("config.game.player" .. tostring(k) .. ".color.r"), c_config_get("config.game.player" .. tostring(k) .. ".color.g"), c_config_get("config.game.player" .. tostring(k) .. ".color.b"), 1)
								-- blend color with tank texture
								gl.CallList(tank_listBase)

								if v.weapon then
									gl.CallList(v.weapon.m.list)
								end
							gl.PopMatrix()
						gl.PopAttrib()
					end
				end
			end

			if v.l == i then
				gl.CallList(v.m.list)
			end
		end
	end

	-- aiming aids
	gl.EnableClientState("VERTEX_ARRAY")
	for _, v in pairs(c_world_getTanks()) do
		if v.exists then
			if (v.weapon and v.weapon.aimAid) or (v.cd.aimAid) then
				local a = {}
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

				table.insert(a, {start.x, start.y})
				table.insert(a, {endP.x, endP.y})
				gl.Color(0.9, 0.1, 0.1, 1)
				gl.TexEnv("TEXTURE_ENV_COLOR", 0.9, 0.1, 0.1, 1)
				gl.VertexPointer(a)
				gl.LineWidth(c_const_get("aimAid_width"))
				gl.DrawArrays("LINES", 0, 2)
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
		gl.PushMatrix()
			gl.Translate(v.p[1].x, v.p[1].y, 0)
			gl.Rotate(tankbobs.m_degrees(v.r), 0, 0, 1)
			gl.CallList(v.weapon.m.projectileList)
		gl.PopMatrix()
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

				gl.Color(c_config_get("config.game.player" .. tostring(k) .. ".color.r"), c_config_get("config.game.player" .. tostring(k) .. ".color.g"), c_config_get("config.game.player" .. tostring(k) .. ".color.b"), 1)
				gl.TexEnv("TEXTURE_ENV_COLOR", c_config_get("config.game.player" .. tostring(k) .. ".color.r"), c_config_get("config.game.player" .. tostring(k) .. ".color.g"), c_config_get("config.game.player" .. tostring(k) .. ".color.b"), 1)
				gl.CallList(healthbarBorder_listBase)
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
