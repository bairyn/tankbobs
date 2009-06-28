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
renderer.lua

drawing output and gl
--]]

local gl
local tankbobs

--local tank_textures
local powerup_textures
local healthbar_texture 
local healthbarBorder_texture 

function renderer_init()
	--tankbobs = _G.tankbobs
	--gl = _G.gl

	if not gl then
		tankbobs = _G.tankbobs

		tankbobs.r_initialize()

		if tankbobs.t_isWindows() then
			c_module_load "luagl"
		else
			c_module_load "opengl"
		end

		gl = _G.gl
	end

	for k, v in pairs(c_config_get("config.fonts")) do
		if type(v) == "table" then
			tankbobs.r_newFont(k, c_const_get("ttf_dir") .. c_config_get("ttf", v), c_config_get("size", v))
		end
	end

	c_const_set("aimAid_startDistance", 2.1, 1)  -- distance at which the aid begins
	c_const_set("aimAid_maxDistance", 4096, 1)
	c_const_set("aimAid_width", 0.75, 1)
	c_const_set("trail_startDistance", 2.1, 1)  -- distance at which the trail begins
	c_const_set("trail_maxDistance", 4096, 1)

	tankbobs.r_selectFont(c_config_get("config.font"))

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
		error("st_play_init: could not generate lists: " .. gl.GetError())
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

	for _, v in pairs(c_weapon_getWeapons()) do
		v.m.p.list = gl.GenLists(1)
		v.m.p.projectileList = gl.GenLists(1)

		v.m.p.texture = gl.GenTextures(1)
		v.m.p.projectileTexture = gl.GenTextures(1)

		gl.BindTexture("TEXTURE_2D", v.m.p.texture[1])
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
		tankbobs.r_loadImage2D(c_const_get("weaponTextures_dir") .. v.texture, c_const_get("textures_default"))
		gl.BindTexture("TEXTURE_2D", v.m.p.projectileTexture[1])
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
		tankbobs.r_loadImage2D(c_const_get("weaponTextures_dir") .. v.projectileTexture, c_const_get("textures_default"))

		gl.NewList(v.m.p.list, "COMPILE_AND_EXECUTE")
			gl.Color(1, 1, 1, 1)
			gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 1)
			gl.BindTexture("TEXTURE_2D", v.m.p.texture[1])
			gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

			gl.Begin("POLYGON")
				for i = 1, #v.render do
					gl.TexCoord(v.texturer[i].x, v.texturer[i].y)
					gl.Vertex(v.render[i].x, v.render[i].y)
				end
			gl.End()
		gl.EndList()

		gl.NewList(v.m.p.projectileList, "COMPILE_AND_EXECUTE")
			gl.Color(1, 1, 1, 1)
			gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 1)
			gl.BindTexture("TEXTURE_2D", v.m.p.projectileTexture[1])
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
end

function renderer_done()
	for k, v in pairs(c_config_get("config.fonts")) do
		if type(v) == "table" then
			tankbobs.r_freeFont(k, c_const_get("ttf_dir") .. c_config_get("ttf", v), c_config_get("size", v))
		end
	end

	gl.DeleteLists(tank_listBase, 1)
	gl.DeleteLists(powerup_listBase, 1)

	gl.DeleteTextures(tank_textures)
	gl.DeleteTextures(powerup_textures)

	for _, v in pairs(c_weapon_getWeapons()) do
		gl.DeleteLists(v.m.p.list, 1)
		gl.DeleteLists(v.m.p.projectileList, 1)
		gl.DeleteTextures(v.m.p.texture, 1)
		gl.DeleteTextures(v.m.p.projectileTexture, 1)
	end

	gl.DeleteLists(healthbar_listBase, 1)
	gl.DeleteLists(healthbarBorder_listBase, 1)
	gl.DeleteTextures(healthbar_texture)
	gl.DeleteTextures(healthbarBorder_texture)

	c_weapon_clear(true)
end

function renderer_setupNewWindow() -- this should be called once after new window
	if not gl then
		tankbobs = _G.tankbobs

		tankbobs.r_initialize()

		if tankbobs.t_isWindows() then
			c_module_load "luagl"
		else
			c_module_load "opengl"
		end

		gl = _G.gl
	end

	gl.Enable("BLEND")
	gl.BlendFunc("SRC_ALPHA", "ONE_MINUS_SRC_ALPHA")

	gl.ClearColor(0, 0, 0, 0)

	renderer_updateWindow()
end

function renderer_updateWindow() -- this should to be called after resize, focus, new window, etc
	if not gl then
		tankbobs = _G.tankbobs

		tankbobs.r_initialize()

		if tankbobs.t_isWindows() then
			c_module_load "luagl"
		else
			c_module_load "opengl"
		end

		gl = _G.gl
	end

	gl.Viewport(0, 0, c_config_get("config.renderer.width"), c_config_get("config.renderer.height"))
	gl.MatrixMode("PROJECTION")
	gl.LoadIdentity()
	gl.Ortho(0, 100, 0, 100, -1, 1)
	gl.MatrixMode("MODELVIEW")
	gl.LoadIdentity()

	-- settings for text
	gl.ShadeModel("SMOOTH")
	gl.Enable("TEXTURE_2D")
	gl.Enable("POINT_SMOOTH")
	gl.Enable("LINE_SMOOTH")
	gl.Enable("POLYGON_SMOOTH")
	gl.Hint("POINT_SMOOTH_HINT", "NICEST")
	gl.Hint("LINE_SMOOTH_HINT", "NICEST")
	gl.Hint("POLYGON_SMOOTH_HINT", "NICEST")
end

function renderer_start()
	gl.Clear("COLOR_BUFFER_BIT")
	gl.LoadIdentity()
end

function renderer_end()
	gl.Flush()
	tankbobs.r_swapBuffers()
end
