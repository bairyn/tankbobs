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
renderer.lua

Tankbobs renderer
--]]

local gl
local tankbobs

local tank_textures
local tankBorder_textures
local tankShield_textures
local tankTagged_textures
local corpse_textures
local corpseBorder_textures
local powerup_textures
local healthbar_texture
local healthbarBorder_texture
local ammobarBorder_textures
local controlPoint_textures
local flag_textures
local flagBase_textures
local explosion_textures

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

	c_const_set("aimAid_startDistance", 2.1, 1)  -- distance between the aid and the tank
	c_const_set("aimAid_maxDistance", 4096, 1)
	c_const_set("aimAid_width", 0.75, 1)
	c_const_set("trail_startDistance", 2.6, 1)  -- distance between the trail and the tank
	c_const_set("trail_maxDistance", 4096, 1)
	c_const_set("tank_lightAccelerationColorOffset", -0.66, 1)
	c_const_set("tank_accelerationColorOffset", 0.33, 1)
	--c_const_set("tank_accelerationAlpha", 0.75, 1)
	c_const_set("tank_nameOffset", tankbobs.m_vec2(-3, 0), 1)
	c_const_set("tank_nameScalex", 1 / 33, 1)
	c_const_set("tank_nameScaley", 1 / 33, 1)

	tankbobs.r_newFont(c_config_get("client.renderer.font"), c_const_get("ttf_dir") .. c_config_get("client.renderer.fonts." .. c_config_get("client.renderer.font") .. ".ttf"), c_config_get("client.renderer.fonts." .. c_config_get("client.renderer.font") .. ".size"))
	tankbobs.r_selectFont(c_config_get("client.renderer.font"))

	c_const_set("ammobar_r", 0.1, 1)
	c_const_set("ammobar_g", 0.1, 1)
	c_const_set("ammobar_b", 0.1, 1)
	c_const_set("ammobar_a", 1.0, 1)

	c_const_set("tank_renderx1", -2.0, 1) c_const_set("tank_rendery1",  2.0, 1)
	c_const_set("tank_renderx2", -2.0, 1) c_const_set("tank_rendery2", -2.0, 1)
	c_const_set("tank_renderx3",  2.0, 1) c_const_set("tank_rendery3", -2.0, 1)
	c_const_set("tank_renderx4",  2.0, 1) c_const_set("tank_rendery4",  2.0, 1)
	c_const_set("tank_texturex1", 1.0, 1) c_const_set("tank_texturey1", 1.0, 1)
	c_const_set("tank_texturex2", 0.0, 1) c_const_set("tank_texturey2", 1.0, 1)
	c_const_set("tank_texturex3", 0.0, 1) c_const_set("tank_texturey3", 0.1, 1)  -- eliminate fuzzy top
	c_const_set("tank_texturex4", 1.0, 1) c_const_set("tank_texturey4", 0.1, 1)  -- eliminate fuzzy top

	c_const_set("tankBorder_renderx1", -2.1, 1) c_const_set("tankBorder_rendery1",  2.1, 1)
	c_const_set("tankBorder_renderx2", -2.1, 1) c_const_set("tankBorder_rendery2", -2.1, 1)
	c_const_set("tankBorder_renderx3",  2.1, 1) c_const_set("tankBorder_rendery3", -2.1, 1)
	c_const_set("tankBorder_renderx4",  2.1, 1) c_const_set("tankBorder_rendery4",  2.1, 1)
	c_const_set("tankBorder_texturex1", 0.9875, 1) c_const_set("tankBorder_texturey1", 0.9875, 1)
	c_const_set("tankBorder_texturex2", 0.0125, 1) c_const_set("tankBorder_texturey2", 0.9875, 1)
	c_const_set("tankBorder_texturex3", 0.0125, 1) c_const_set("tankBorder_texturey3", 0.1, 1)  -- no outline on top
	c_const_set("tankBorder_texturex4", 0.9875, 1) c_const_set("tankBorder_texturey4", 0.1, 1)  -- no outline on top

	c_const_set("tankShield_renderx1", -2.33, 1) c_const_set("tankShield_rendery1",  2.33, 1)
	c_const_set("tankShield_renderx2", -2.33, 1) c_const_set("tankShield_rendery2", -2.33, 1)
	c_const_set("tankShield_renderx3",  2.33, 1) c_const_set("tankShield_rendery3", -2.33, 1)
	c_const_set("tankShield_renderx4",  2.33, 1) c_const_set("tankShield_rendery4",  2.33, 1)
	c_const_set("tankShield_texturex1", 1.0, 1) c_const_set("tankShield_texturey1", 1.0, 1)
	c_const_set("tankShield_texturex2", 0.0, 1) c_const_set("tankShield_texturey2", 1.0, 1)
	c_const_set("tankShield_texturex3", 0.0, 1) c_const_set("tankShield_texturey3", 0.1, 1)  -- eliminate fuzzy top
	c_const_set("tankShield_texturex4", 1.0, 1) c_const_set("tankShield_texturey4", 0.1, 1)  -- eliminate fuzzy top

	c_const_set("tankTagged_renderx1", -2.33, 1) c_const_set("tankTagged_rendery1",  2.33, 1)
	c_const_set("tankTagged_renderx2", -2.33, 1) c_const_set("tankTagged_rendery2", -2.33, 1)
	c_const_set("tankTagged_renderx3",  2.33, 1) c_const_set("tankTagged_rendery3", -2.33, 1)
	c_const_set("tankTagged_renderx4",  2.33, 1) c_const_set("tankTagged_rendery4",  2.33, 1)
	c_const_set("tankTagged_texturex1", 1.0, 1) c_const_set("tankTagged_texturey1", 1.0, 1)
	c_const_set("tankTagged_texturex2", 0.0, 1) c_const_set("tankTagged_texturey2", 1.0, 1)
	c_const_set("tankTagged_texturex3", 0.0, 1) c_const_set("tankTagged_texturey3", 0.1, 1)  -- eliminate fuzzy top
	c_const_set("tankTagged_texturex4", 1.0, 1) c_const_set("tankTagged_texturey4", 0.1, 1)  -- eliminate fuzzy top

	c_const_set("corpse_renderx1", -2.0, 1) c_const_set("corpse_rendery1",  2.0, 1)
	c_const_set("corpse_renderx2", -2.0, 1) c_const_set("corpse_rendery2", -2.0, 1)
	c_const_set("corpse_renderx3",  2.0, 1) c_const_set("corpse_rendery3", -2.0, 1)
	c_const_set("corpse_renderx4",  2.0, 1) c_const_set("corpse_rendery4",  2.0, 1)
	c_const_set("corpse_texturex1", 1.0, 1) c_const_set("corpse_texturey1", 1.0, 1)
	c_const_set("corpse_texturex2", 0.0, 1) c_const_set("corpse_texturey2", 1.0, 1)
	c_const_set("corpse_texturex3", 0.0, 1) c_const_set("corpse_texturey3", 0.1, 1)  -- eliminate fuzzy top
	c_const_set("corpse_texturex4", 1.0, 1) c_const_set("corpse_texturey4", 0.1, 1)  -- eliminate fuzzy top

	c_const_set("corpseBorder_renderx1", -2.1, 1) c_const_set("corpseBorder_rendery1",  2.1, 1)
	c_const_set("corpseBorder_renderx2", -2.1, 1) c_const_set("corpseBorder_rendery2", -2.1, 1)
	c_const_set("corpseBorder_renderx3",  2.1, 1) c_const_set("corpseBorder_rendery3", -2.1, 1)
	c_const_set("corpseBorder_renderx4",  2.1, 1) c_const_set("corpseBorder_rendery4",  2.1, 1)
	c_const_set("corpseBorder_texturex1", 0.9875, 1) c_const_set("corpseBorder_texturey1", 0.9875, 1)
	c_const_set("corpseBorder_texturex2", 0.0125, 1) c_const_set("corpseBorder_texturey2", 0.9875, 1)
	c_const_set("corpseBorder_texturex3", 0.0125, 1) c_const_set("corpseBorder_texturey3", 0.1, 1)  -- no outline on top
	c_const_set("corpseBorder_texturex4", 0.9875, 1) c_const_set("corpseBorder_texturey4", 0.1, 1)  -- no outline on top

	c_const_set("color_red", {0.875, 0.125, 0.125, 1})
	c_const_set("color_blue", {0.125, 0.125, 0.875, 1})
	c_const_set("color_neutral", {0.2, 0.2, 0.33, 1})

	tank_listBase = gl.GenLists(1)
	tank_textures = gl.GenTextures(1)
	tankBorder_listBase = gl.GenLists(1)
	tankBorder_textures = gl.GenTextures(1)
	tankShield_listBase = gl.GenLists(1)
	tankShield_textures = gl.GenTextures(1)
	tankTagged_listBase = gl.GenLists(1)
	tankTagged_textures = gl.GenTextures(1)
	corpse_listBase = gl.GenLists(1)
	corpse_textures = gl.GenTextures(1)
	corpseBorder_listBase = gl.GenLists(1)
	corpseBorder_textures = gl.GenTextures(1)

	if tank_listBase == 0 or tankBorder_listBase == 0 then
		error("st_play_init: could not generate lists: " .. gl.GetError())
	end

	gl.BindTexture("TEXTURE_2D", tank_textures[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("tank"), c_const_get("textures_default"))

	gl.NewList(tank_listBase, "COMPILE")
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

	gl.BindTexture("TEXTURE_2D", tankBorder_textures[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("tankBorder"), c_const_get("textures_default"))

	gl.NewList(tankBorder_listBase, "COMPILE")
		-- blend tank with color
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")
		gl.BindTexture("TEXTURE_2D", tankBorder_textures[1])
		gl.Begin("QUADS")
			gl.TexCoord(c_const_get("tankBorder_texturex1"), c_const_get("tankBorder_texturey1")) gl.Vertex(c_const_get("tankBorder_renderx1"), c_const_get("tankBorder_rendery1"))
			gl.TexCoord(c_const_get("tankBorder_texturex2"), c_const_get("tankBorder_texturey2")) gl.Vertex(c_const_get("tankBorder_renderx2"), c_const_get("tankBorder_rendery2"))
			gl.TexCoord(c_const_get("tankBorder_texturex3"), c_const_get("tankBorder_texturey3")) gl.Vertex(c_const_get("tankBorder_renderx3"), c_const_get("tankBorder_rendery3"))
			gl.TexCoord(c_const_get("tankBorder_texturex4"), c_const_get("tankBorder_texturey4")) gl.Vertex(c_const_get("tankBorder_renderx4"), c_const_get("tankBorder_rendery4"))
		gl.End()
	gl.EndList()

	gl.BindTexture("TEXTURE_2D", corpse_textures[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("corpse"), c_const_get("textures_default"))

	gl.NewList(corpse_listBase, "COMPILE")
		-- blend corpse with color
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")
		gl.BindTexture("TEXTURE_2D", corpse_textures[1])
		gl.Begin("QUADS")
			gl.TexCoord(c_const_get("corpse_texturex1"), c_const_get("corpse_texturey1")) gl.Vertex(c_const_get("corpse_renderx1"), c_const_get("corpse_rendery1"))
			gl.TexCoord(c_const_get("corpse_texturex2"), c_const_get("corpse_texturey2")) gl.Vertex(c_const_get("corpse_renderx2"), c_const_get("corpse_rendery2"))
			gl.TexCoord(c_const_get("corpse_texturex3"), c_const_get("corpse_texturey3")) gl.Vertex(c_const_get("corpse_renderx3"), c_const_get("corpse_rendery3"))
			gl.TexCoord(c_const_get("corpse_texturex4"), c_const_get("corpse_texturey4")) gl.Vertex(c_const_get("corpse_renderx4"), c_const_get("corpse_rendery4"))
		gl.End()
	gl.EndList()

	gl.BindTexture("TEXTURE_2D", corpseBorder_textures[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("corpseBorder"), c_const_get("textures_default"))

	gl.NewList(corpseBorder_listBase, "COMPILE")
		-- blend corpse with color
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")
		gl.BindTexture("TEXTURE_2D", corpseBorder_textures[1])
		gl.Begin("QUADS")
			gl.TexCoord(c_const_get("corpseBorder_texturex1"), c_const_get("corpseBorder_texturey1")) gl.Vertex(c_const_get("corpseBorder_renderx1"), c_const_get("corpseBorder_rendery1"))
			gl.TexCoord(c_const_get("corpseBorder_texturex2"), c_const_get("corpseBorder_texturey2")) gl.Vertex(c_const_get("corpseBorder_renderx2"), c_const_get("corpseBorder_rendery2"))
			gl.TexCoord(c_const_get("corpseBorder_texturex3"), c_const_get("corpseBorder_texturey3")) gl.Vertex(c_const_get("corpseBorder_renderx3"), c_const_get("corpseBorder_rendery3"))
			gl.TexCoord(c_const_get("corpseBorder_texturex4"), c_const_get("corpseBorder_texturey4")) gl.Vertex(c_const_get("corpseBorder_renderx4"), c_const_get("corpseBorder_rendery4"))
		gl.End()
	gl.EndList()

	gl.BindTexture("TEXTURE_2D", tankShield_textures[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("tankShield"), c_const_get("textures_default"))

	gl.NewList(tankShield_listBase, "COMPILE")
		-- blend tank with color
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")
		gl.BindTexture("TEXTURE_2D", tankShield_textures[1])
		gl.Begin("QUADS")
			gl.TexCoord(c_const_get("tankShield_texturex1"), c_const_get("tankShield_texturey1")) gl.Vertex(c_const_get("tankShield_renderx1"), c_const_get("tankShield_rendery1"))
			gl.TexCoord(c_const_get("tankShield_texturex2"), c_const_get("tankShield_texturey2")) gl.Vertex(c_const_get("tankShield_renderx2"), c_const_get("tankShield_rendery2"))
			gl.TexCoord(c_const_get("tankShield_texturex3"), c_const_get("tankShield_texturey3")) gl.Vertex(c_const_get("tankShield_renderx3"), c_const_get("tankShield_rendery3"))
			gl.TexCoord(c_const_get("tankShield_texturex4"), c_const_get("tankShield_texturey4")) gl.Vertex(c_const_get("tankShield_renderx4"), c_const_get("tankShield_rendery4"))
		gl.End()
	gl.EndList()

	gl.BindTexture("TEXTURE_2D", tankTagged_textures[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("tankTagged"), c_const_get("textures_default"))

	gl.NewList(tankTagged_listBase, "COMPILE")
		-- blend tank with color
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")
		gl.BindTexture("TEXTURE_2D", tankTagged_textures[1])
		gl.Begin("QUADS")
			gl.TexCoord(c_const_get("tankTagged_texturex1"), c_const_get("tankTagged_texturey1")) gl.Vertex(c_const_get("tankTagged_renderx1"), c_const_get("tankTagged_rendery1"))
			gl.TexCoord(c_const_get("tankTagged_texturex2"), c_const_get("tankTagged_texturey2")) gl.Vertex(c_const_get("tankTagged_renderx2"), c_const_get("tankTagged_rendery2"))
			gl.TexCoord(c_const_get("tankTagged_texturex3"), c_const_get("tankTagged_texturey3")) gl.Vertex(c_const_get("tankTagged_renderx3"), c_const_get("tankTagged_rendery3"))
			gl.TexCoord(c_const_get("tankTagged_texturex4"), c_const_get("tankTagged_texturey4")) gl.Vertex(c_const_get("tankTagged_renderx4"), c_const_get("tankTagged_rendery4"))
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

	gl.NewList(powerup_listBase, "COMPILE")
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")
		gl.BindTexture("TEXTURE_2D", powerup_textures[1])
		gl.Begin("QUADS")
			gl.TexCoord(c_const_get("powerup_texturex1"), c_const_get("powerup_texturey1")) gl.Vertex(c_const_get("powerup_renderx1"), c_const_get("powerup_rendery1"))
			gl.TexCoord(c_const_get("powerup_texturex2"), c_const_get("powerup_texturey2")) gl.Vertex(c_const_get("powerup_renderx2"), c_const_get("powerup_rendery2"))
			gl.TexCoord(c_const_get("powerup_texturex3"), c_const_get("powerup_texturey3")) gl.Vertex(c_const_get("powerup_renderx3"), c_const_get("powerup_rendery3"))
			gl.TexCoord(c_const_get("powerup_texturex4"), c_const_get("powerup_texturey4")) gl.Vertex(c_const_get("powerup_renderx4"), c_const_get("powerup_rendery4"))
		gl.End()
	gl.EndList()

	controlPoint_listBase = gl.GenLists(1)
	controlPoint_textures = gl.GenTextures(1)

	if controlPoint_listBase == 0 then
		error "st_play_init: could not generate lists"
	end

	c_const_set("controlPoint_renderx1",  -2, 1) c_const_set("controlPoint_rendery1",  2, 1)
	c_const_set("controlPoint_renderx2",  -2, 1) c_const_set("controlPoint_rendery2",  -2, 1)
	c_const_set("controlPoint_renderx3",  2, 1) c_const_set("controlPoint_rendery3",  -2, 1)
	c_const_set("controlPoint_renderx4",  2, 1) c_const_set("controlPoint_rendery4",  2, 1)
	c_const_set("controlPoint_texturex1", 0, 1) c_const_set("controlPoint_texturey1", 1, 1)
	c_const_set("controlPoint_texturex2", 0, 1) c_const_set("controlPoint_texturey2", 0, 1)
	c_const_set("controlPoint_texturex3", 1, 1) c_const_set("controlPoint_texturey3", 0, 1)
	c_const_set("controlPoint_texturex4", 1, 1) c_const_set("controlPoint_texturey4", 1, 1)

	c_const_set("controlPoint_rotation", -math.pi / 2, 1)

	gl.BindTexture("TEXTURE_2D", controlPoint_textures[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("controlPoint"), c_const_get("textures_default"))

	gl.NewList(controlPoint_listBase, "COMPILE")
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")
		gl.BindTexture("TEXTURE_2D", controlPoint_textures[1])
		gl.Begin("QUADS")
			gl.TexCoord(c_const_get("controlPoint_texturex1"), c_const_get("controlPoint_texturey1")) gl.Vertex(c_const_get("controlPoint_renderx1"), c_const_get("controlPoint_rendery1"))
			gl.TexCoord(c_const_get("controlPoint_texturex2"), c_const_get("controlPoint_texturey2")) gl.Vertex(c_const_get("controlPoint_renderx2"), c_const_get("controlPoint_rendery2"))
			gl.TexCoord(c_const_get("controlPoint_texturex3"), c_const_get("controlPoint_texturey3")) gl.Vertex(c_const_get("controlPoint_renderx3"), c_const_get("controlPoint_rendery3"))
			gl.TexCoord(c_const_get("controlPoint_texturex4"), c_const_get("controlPoint_texturey4")) gl.Vertex(c_const_get("controlPoint_renderx4"), c_const_get("controlPoint_rendery4"))
		gl.End()
	gl.EndList()

	flag_listBase = gl.GenLists(1)
	flag_textures = gl.GenTextures(1)

	if flag_listBase == 0 then
		error "st_play_init: could not generate lists"
	end

	c_const_set("flag_renderx1",  -1, 1) c_const_set("flag_rendery1",  -2, 1)
	c_const_set("flag_renderx2",  -1, 1) c_const_set("flag_rendery2",  2, 1)
	c_const_set("flag_renderx3",  1, 1) c_const_set("flag_rendery3",  2, 1)
	c_const_set("flag_renderx4",  1, 1) c_const_set("flag_rendery4",  -2, 1)
	c_const_set("flag_texturex1", 0, 1) c_const_set("flag_texturey1", 1, 1)
	c_const_set("flag_texturex2", 0, 1) c_const_set("flag_texturey2", 0, 1)
	c_const_set("flag_texturex3", 1, 1) c_const_set("flag_texturey3", 0, 1)
	c_const_set("flag_texturex4", 1, 1) c_const_set("flag_texturey4", 1, 1)

	gl.BindTexture("TEXTURE_2D", flag_textures[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("flag"), c_const_get("textures_default"))

	gl.NewList(flag_listBase, "COMPILE")
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")
		gl.BindTexture("TEXTURE_2D", flag_textures[1])
		gl.Begin("QUADS")
			gl.TexCoord(c_const_get("flag_texturex1"), c_const_get("flag_texturey1")) gl.Vertex(c_const_get("flag_renderx1"), c_const_get("flag_rendery1"))
			gl.TexCoord(c_const_get("flag_texturex2"), c_const_get("flag_texturey2")) gl.Vertex(c_const_get("flag_renderx2"), c_const_get("flag_rendery2"))
			gl.TexCoord(c_const_get("flag_texturex3"), c_const_get("flag_texturey3")) gl.Vertex(c_const_get("flag_renderx3"), c_const_get("flag_rendery3"))
			gl.TexCoord(c_const_get("flag_texturex4"), c_const_get("flag_texturey4")) gl.Vertex(c_const_get("flag_renderx4"), c_const_get("flag_rendery4"))
		gl.End()
	gl.EndList()

	flagBase_listBase = gl.GenLists(1)
	flagBase_textures = gl.GenTextures(1)

	if flagBase_listBase == 0 then
		error "st_play_init: could not generate lists"
	end

	c_const_set("flagBase_renderx1",  -2, 1) c_const_set("flagBase_rendery1",  2, 1)
	c_const_set("flagBase_renderx2",  -2, 1) c_const_set("flagBase_rendery2",  -2, 1)
	c_const_set("flagBase_renderx3",  2, 1) c_const_set("flagBase_rendery3",  -2, 1)
	c_const_set("flagBase_renderx4",  2, 1) c_const_set("flagBase_rendery4",  2, 1)
	c_const_set("flagBase_texturex1", 0, 1) c_const_set("flagBase_texturey1", 1, 1)
	c_const_set("flagBase_texturex2", 0, 1) c_const_set("flagBase_texturey2", 0, 1)
	c_const_set("flagBase_texturex3", 1, 1) c_const_set("flagBase_texturey3", 0, 1)
	c_const_set("flagBase_texturex4", 1, 1) c_const_set("flagBase_texturey4", 1, 1)

	gl.BindTexture("TEXTURE_2D", flagBase_textures[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("flagBase"), c_const_get("textures_default"))

	gl.NewList(flagBase_listBase, "COMPILE")
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")
		gl.BindTexture("TEXTURE_2D", flagBase_textures[1])
		gl.Begin("QUADS")
			gl.TexCoord(c_const_get("flagBase_texturex1"), c_const_get("flagBase_texturey1")) gl.Vertex(c_const_get("flagBase_renderx1"), c_const_get("flagBase_rendery1"))
			gl.TexCoord(c_const_get("flagBase_texturex2"), c_const_get("flagBase_texturey2")) gl.Vertex(c_const_get("flagBase_renderx2"), c_const_get("flagBase_rendery2"))
			gl.TexCoord(c_const_get("flagBase_texturex3"), c_const_get("flagBase_texturey3")) gl.Vertex(c_const_get("flagBase_renderx3"), c_const_get("flagBase_rendery3"))
			gl.TexCoord(c_const_get("flagBase_texturex4"), c_const_get("flagBase_texturey4")) gl.Vertex(c_const_get("flagBase_renderx4"), c_const_get("flagBase_rendery4"))
		gl.End()
	gl.EndList()

	explosion_listBase = gl.GenLists(1)
	explosion_textures = gl.GenTextures(1)

	if explosion_listBase == 0 then
		error "st_play_init: could not generate lists"
	end

	c_const_set("explosion_renderx1",  -0.5, 1) c_const_set("explosion_rendery1",  3, 1)
	c_const_set("explosion_renderx2",  -0.5, 1) c_const_set("explosion_rendery2",  0, 1)
	c_const_set("explosion_renderx3",  0.5, 1) c_const_set("explosion_rendery3",  0, 1)
	c_const_set("explosion_renderx4",  0.5, 1) c_const_set("explosion_rendery4",  3, 1)
	c_const_set("explosion_texturex1", 0, 1) c_const_set("explosion_texturey1", 1, 1)
	c_const_set("explosion_texturex2", 0, 1) c_const_set("explosion_texturey2", 0, 1)
	c_const_set("explosion_texturex3", 1, 1) c_const_set("explosion_texturey3", 0, 1)
	c_const_set("explosion_texturex4", 1, 1) c_const_set("explosion_texturey4", 1, 1)

	gl.BindTexture("TEXTURE_2D", explosion_textures[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("explosion"), c_const_get("textures_default"))

	gl.NewList(explosion_listBase, "COMPILE")
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")
		gl.BindTexture("TEXTURE_2D", explosion_textures[1])
		local num = 8

		for i = 1, num do
			local angle = common_lerp(0, 360, (i - 1) / (num - 1))

			gl.PushMatrix()
				gl.Rotate(angle, 0, 0, 1)

				gl.Begin("QUADS")
					gl.TexCoord(c_const_get("explosion_texturex1"), c_const_get("explosion_texturey1")) gl.Vertex(c_const_get("explosion_renderx1"), c_const_get("explosion_rendery1"))
					gl.TexCoord(c_const_get("explosion_texturex2"), c_const_get("explosion_texturey2")) gl.Vertex(c_const_get("explosion_renderx2"), c_const_get("explosion_rendery2"))
					gl.TexCoord(c_const_get("explosion_texturex3"), c_const_get("explosion_texturey3")) gl.Vertex(c_const_get("explosion_renderx3"), c_const_get("explosion_rendery3"))
					gl.TexCoord(c_const_get("explosion_texturex4"), c_const_get("explosion_texturey4")) gl.Vertex(c_const_get("explosion_renderx4"), c_const_get("explosion_rendery4"))
				gl.End()
			gl.PopMatrix()
		end
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

		gl.NewList(v.m.p.list, "COMPILE")
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

		gl.NewList(v.m.p.projectileList, "COMPILE")
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
	ammobarBorder_listBase = gl.GenLists(1)
	healthbar_texture = gl.GenTextures(1)
	healthbarBorder_texture = gl.GenTextures(1)
	ammobarBorder_texture = gl.GenTextures(1)

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
	tankbobs.r_loadImage2D(c_const_get("healthbarBorder_texture"), c_const_get("textures_default"))
	gl.BindTexture("TEXTURE_2D", ammobarBorder_texture[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("ammobarBorder_texture"), c_const_get("textures_default"))

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
	c_const_set("ammobarBorder_renderx1", -1.5, 1) c_const_set("ammobarBorder_rendery1", -4.5, 1)
	c_const_set("ammobarBorder_renderx2", -1.5, 1) c_const_set("ammobarBorder_rendery2", -3.25, 1)
	c_const_set("ammobarBorder_renderx3",  1.5, 1) c_const_set("ammobarBorder_rendery3", -3.25, 1)
	c_const_set("ammobarBorder_renderx4",  1.5, 1) c_const_set("ammobarBorder_rendery4", -4.5, 1)
	c_const_set("ammobarBorder_texturex1", 0, 1) c_const_set("ammobarBorder_texturey1", 1, 1)
	c_const_set("ammobarBorder_texturex2", 0, 1) c_const_set("ammobarBorder_texturey2", 0, 1)
	c_const_set("ammobarBorder_texturex3", 1, 1) c_const_set("ammobarBorder_texturey3", 0, 1)
	c_const_set("ammobarBorder_texturex4", 1, 1) c_const_set("ammobarBorder_texturey4", 1, 1)
	c_const_set("healthbar_rotation", 270, 1)

	gl.NewList(healthbar_listBase, "COMPILE")
		gl.BindTexture("TEXTURE_2D", healthbar_texture[1])
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

		gl.Begin("QUADS")
			for i = 1, 4 do
				gl.TexCoord(c_const_get("healthbar_texturex" .. i), c_const_get("healthbar_texturey" .. i))
				gl.Vertex(c_const_get("healthbar_renderx" .. i), c_const_get("healthbar_rendery" .. i))
			end
		gl.End()
	gl.EndList()

	gl.NewList(healthbarBorder_listBase, "COMPILE")
		gl.BindTexture("TEXTURE_2D", healthbarBorder_texture[1])
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

		gl.Begin("QUADS")
			for i = 1, 4 do
				gl.TexCoord(c_const_get("healthbarBorder_texturex" .. i), c_const_get("healthbarBorder_texturey" .. i))
				gl.Vertex(c_const_get("healthbarBorder_renderx" .. i), c_const_get("healthbarBorder_rendery" .. i))
			end
		gl.End()
	gl.EndList()

	gl.NewList(ammobarBorder_listBase, "COMPILE")
		gl.BindTexture("TEXTURE_2D", ammobarBorder_texture[1])
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

		gl.Begin("QUADS")
			for i = 1, 4 do
				gl.TexCoord(c_const_get("ammobarBorder_texturex" .. i), c_const_get("ammobarBorder_texturey" .. i))
				gl.Vertex(c_const_get("ammobarBorder_renderx" .. i), c_const_get("ammobarBorder_rendery" .. i))
			end
		gl.End()
	gl.EndList()
end

function renderer_done()
	tankbobs.r_freeFont(c_config_get("client.renderer.font"))

	gl.DeleteLists(tank_listBase, 1)
	gl.DeleteLists(tankBorder_listBase, 1)
	gl.DeleteLists(tankShield_listBase, 1)
	gl.DeleteLists(tankTagged_listBase, 1)
	gl.DeleteLists(powerup_listBase, 1)
	gl.DeleteLists(controlPoint_listBase, 1)
	gl.DeleteLists(flag_listBase, 1)
	gl.DeleteLists(flagBase_listBase, 1)
	gl.DeleteLists(corpse_listBase, 1)
	gl.DeleteLists(corpseBorder_listBase, 1)
	gl.DeleteLists(explosion_listBase, 1)

	gl.DeleteTextures(tank_textures)
	gl.DeleteTextures(tankBorder_textures)
	gl.DeleteTextures(tankShield_textures)
	gl.DeleteTextures(tankTagged_textures)
	gl.DeleteTextures(powerup_textures)
	gl.DeleteTextures(controlPoint_textures)
	gl.DeleteTextures(flag_textures)
	gl.DeleteTextures(flagBase_textures)
	gl.DeleteTextures(corpse_textures)
	gl.DeleteTextures(corpseBorder_textures)
	gl.DeleteTextures(explosion_textures)

	for _, v in pairs(c_weapon_getWeapons()) do
		gl.DeleteLists(v.m.p.list, 1)
		gl.DeleteLists(v.m.p.projectileList, 1)
		gl.DeleteTextures(v.m.p.texture, 1)
		gl.DeleteTextures(v.m.p.projectileTexture, 1)
	end

	gl.DeleteLists(healthbar_listBase, 1)
	gl.DeleteLists(healthbarBorder_listBase, 1)
	gl.DeleteLists(ammobarBorder_listBase, 1)
	gl.DeleteTextures(healthbar_texture)
	gl.DeleteTextures(healthbarBorder_texture)
	gl.DeleteTextures(ammobarBorder_texture)

	c_weapon_clear(true)
end

function renderer_getMatrix()
	local r = {gl.Get("MODELVIEW_MATRIX")}

	return r
end

function renderer_setMatrix(M)
	if not M then
		return
	end

	gl.LoadIdentity()
	gl.MultMatrix(M)
end

function renderer_determinant(M)
	return
	M[13] * M[10]  * M[7]  * M[4] -
	M[9]  * M[14] * M[7]  * M[4] -
	M[13] * M[6]  * M[11] * M[4] +
	M[5]  * M[14] * M[11] * M[4] +
	M[9]  * M[6]  * M[15] * M[4] -
	M[5]  * M[10]  * M[15] * M[4] -
	M[13] * M[10]  * M[3]  * M[8] +
	M[9]  * M[14] * M[3]  * M[8] +
	M[13] * M[2]  * M[11] * M[8] -
	M[1]  * M[14] * M[11] * M[8] -
	M[9]  * M[2]  * M[15] * M[8] +
	M[1]  * M[10]  * M[15] * M[8] +
	M[13] * M[6]  * M[3]  * M[12] -
	M[5]  * M[14] * M[3]  * M[12] -
	M[13] * M[2]  * M[7]  * M[12] +
	M[1]  * M[14] * M[7]  * M[12] +
	M[5]  * M[2]  * M[15] * M[12] -
	M[1]  * M[6]  * M[15] * M[12] -
	M[9]  * M[6]  * M[3]  * M[16] +
	M[5]  * M[10]  * M[3]  * M[16] +
	M[9]  * M[2]  * M[7]  * M[16] -
	M[1]  * M[10]  * M[7]  * M[16] -
	M[5]  * M[2]  * M[11] * M[16] +
	M[1]  * M[6]  * M[11] * M[16]
end

function renderer_inverseMatrix(M, copy)
	local r = copy and {} or M

	local d = renderer_determinant(M)
	if d == 1 then
		return tankbobs.t_clone(M)
	end

	r[1]= (-M[14] * M[11] * M[8] +M[10] * M[15] * M[8] +M[14] * M[7] * M[12]
			-M[6] * M[15] * M[12] -M[10] * M[7] * M[16] +M[6] * M[11] * M[16]) / d
	r[5]= ( M[13] * M[11] * M[8] -M[9] * M[15] * M[8] -M[13] * M[7] * M[12]
			+M[5] * M[15] * M[12] +M[9] * M[7] * M[16] -M[5] * M[11] * M[16]) / d
	r[9]= (-M[13] * M[10]  * M[8] +M[9] * M[14] * M[8] +M[13] * M[6] * M[12]
			-M[5] * M[14] * M[12] -M[9] * M[6] * M[16] +M[5] * M[10] *  M[16]) / d
	r[13]=( M[13] * M[10]  * M[7] -M[9] * M[14] * M[7] -M[13] * M[6] * M[11]
			+M[5] * M[14] * M[11] +M[9] * M[6] * M[15] -M[5] * M[10] *  M[15]) / d
	r[2]= ( M[14] * M[11] * M[4] -M[10] * M[15] * M[4] -M[14] * M[3] * M[12]
			+M[2] * M[15] * M[12] +M[10] * M[3] * M[16] -M[2] * M[11] * M[16]) / d
	r[6]= (-M[13] * M[11] * M[4] +M[9] * M[15] * M[4] +M[13] * M[3] * M[12]
			-M[1] * M[15] * M[12] -M[9] * M[3] * M[16] +M[1] * M[11] * M[16]) / d
	r[10]= ( M[13] * M[10]  * M[4] -M[9] * M[14] * M[4] -M[13] * M[2] * M[12]
			+M[1] * M[14] * M[12] +M[9] * M[2] * M[16] -M[1] * M[10] *  M[16]) / d
	r[14]=(-M[13] * M[10]  * M[3] +M[9] * M[14] * M[3] +M[13] * M[2] * M[11]
			-M[1] * M[14] * M[11] -M[9] * M[2] * M[15] +M[1] * M[10] *  M[15]) / d
	r[3]= (-M[14] * M[7]  * M[4] +M[6] * M[15] * M[4] +M[14] * M[3] * M[8]
			-M[2] * M[15] * M[8] -M[6] * M[3] * M[16] +M[2] * M[7] *  M[16]) / d
	r[7]= ( M[13] * M[7]  * M[4] -M[5] * M[15] * M[4] -M[13] * M[3] * M[8]
			+M[1] * M[15] * M[8] +M[5] * M[3] * M[16] -M[1] * M[7] *  M[16]) / d
	r[11]=(-M[13] * M[6]  * M[4] +M[5] * M[14] * M[4] +M[13] * M[2] * M[8]
			-M[1] * M[14] * M[8] -M[5] * M[2] * M[16] +M[1] * M[6] *  M[16]) / d
	r[15]=( M[13] * M[6]  * M[3] -M[5] * M[14] * M[3] -M[13] * M[2] * M[7]
			+M[1] * M[14] * M[7] +M[5] * M[2] * M[15] -M[1] * M[6] *  M[15]) / d
	r[4]= ( M[10]  * M[7]  * M[4] -M[6] * M[11] * M[4] -M[10] *  M[3] * M[8]
			+M[2] * M[11] * M[8] +M[6] * M[3] * M[12] -M[2] * M[7] *  M[12]) / d
	r[8]= (-M[9]  * M[7]  * M[4] +M[5] * M[11] * M[4] +M[9] *  M[3] * M[8]
			-M[1] * M[11] * M[8] -M[5] * M[3] * M[12] +M[1] * M[7] *  M[12]) / d
	r[12]=( M[9]  * M[6]  * M[4] -M[5] * M[10] *  M[4] -M[9] *  M[2] * M[8]
			+M[1] * M[10]  * M[8] +M[5] * M[2] * M[12] -M[1] * M[6] *  M[12]) / d
	r[16]=(-M[9]  * M[6]  * M[3] +M[5] * M[10] *  M[3] +M[9] *  M[2] * M[7]
			-M[1] * M[10]  * M[7] -M[5] * M[2] * M[11] +M[1] * M[6] *  M[11]) / d

	return r
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

	gl.Viewport(0, 0, c_config_get("client.renderer.width"), c_config_get("client.renderer.height"))
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

function renderer_clear()
	renderer_end()
	renderer_start()
end
