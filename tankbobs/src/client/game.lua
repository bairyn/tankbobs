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
st_game.lua

Game play functions shared by both offline and online states
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
local tankBorder_listBase
local powerup_listBase
local healthbar_listBase
local healthbarBorder_listBase
local c_world_findClosestIntersection
local common_lerp

local bit

local trails = {}
local camera
local zoom

local wall_textures

function game_init()
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
	tankBorder_listBase = _G.tankBorder_listBase
	powerup_listBase = _G.powerup_listBase
	healthbar_listBase = _G.healthbar_listBase
	healthbarBorder_listBase = _G.healthbarBorder_listBase
	c_world_findClosestIntersection = _G.c_world_findClosestIntersection
	common_lerp = _G.common_lerp

	bit = c_module_load "bit"
end

function game_done()
end

function game_new()
	camera = tankbobs.m_vec2(-50, -50)
	zoom = 1

	-- initialize wall textures per individual level
	wall_textures = {}
	local function lookup(textureName)
		for k, v in pairs(wall_textures) do
			if v == textureName then
				return k
			end
		end

		return nil
	end

	for _, v in pairs(c_tcm_current_map.walls) do
		local texture = c_const_get("textures_dir") .. v.texture

		v.m.texture = lookup(texture)
		if not v.m.texture then
			table.insert(wall_textures, texture)
			v.m.texture = lookup(texture)
		end
	end

	local textures = gl.GenTextures(#wall_textures)

	for k, v in pairs(wall_textures) do
		wall_textures[k] = {v, textures[k]}

		gl.BindTexture("TEXTURE_2D", textures[k])
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
		gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
		tankbobs.r_loadImage2D(wall_textures[k][1], c_const_get("textures_default"))
	end

	for _, v in pairs(c_tcm_current_map.walls) do
		v.m.texture = wall_textures[v.m.texture][2]
	end

	-- scores
	local function updateScores(widget)
		if not c_world_isTeamGameType(c_world_gameType) then
			-- non-team scores

			local length = 0

			widget.text = ""

			for _, v in pairs(c_world_getTanks()) do
				local name = v.name

				if #name > length then
					length = #name
				end
			end

			if length < 1 then
				length = 1
			end

			for _, v in pairs(c_world_getTanks()) do
				local name, between, score

				if widget.text:len() ~= 0 then
					widget.text = widget.text .. "\n"
				end

				name = tostring(v.name)
				between = string.rep("  ", length - #name + 1)
				score = tostring(v.score)

				widget.text = widget.text .. name .. between .. score
			end
		else
			-- team scores

			widget.text = "Red  " .. c_world_redTeam.score .. "\nBlue " .. c_world_blueTeam.score
		end
	end

	gui_addLabel(tankbobs.m_vec2(7.5, 92.5), "", updateScores, 0.5, c_config_get("client.renderer.scoresRed"), c_config_get("client.renderer.scoresGreen"), c_config_get("client.renderer.scoresBlue"), c_config_get("client.renderer.scoresAlpha"), c_config_get("client.renderer.scoresRed"), c_config_get("client.renderer.scoresGreen"), c_config_get("client.renderer.scoresGreen"), c_config_get("client.renderer.scoresAlpha"))

	-- fps counter
	local function updateFPS(widget)
		local fps = fps

		widget.text = tostring(fps - (fps % 1))
	end

	if c_config_get("client.renderer.fpsCounter") then
		gui_addLabel(tankbobs.m_vec2(92.5, 92.5), "", updateFPS, 0.5, c_config_get("client.renderer.fpsRed"), c_config_get("client.renderer.fpsGreen"), c_config_get("client.renderer.fpsBlue"), c_config_get("client.renderer.fpsAlpha"), c_config_get("client.renderer.fpsRed"), c_config_get("client.renderer.fpsGreen"), c_config_get("client.renderer.fpsGreen"), c_config_get("client.renderer.fpsAlpha"))
	end

	-- initialize melee sounds
	for _, v in pairs(c_weapon_getWeapons()) do
		if v.meleeRange ~= 0 then
			tankbobs.a_setVolumeChunk(c_const_get("weaponAudio_dir") .. v.fireSound, 0)
			tankbobs.a_playSound(c_const_get("weaponAudio_dir") .. v.fireSound, -1)
			tankbobs.a_setVolumeChunk(c_const_get("weaponAudio_dir") .. v.fireSound, 0)
		end
	end
end

function game_end()
	-- free the cursor
	tankbobs.in_grabClear()

	-- free renderer stuff
	gl.DeleteTextures(wall_textures)
	for _, v in pairs(trails) do
		if gl.IsList(v[3]) then
			gl.DeleteLists(v[3], 1)
		end
	end

	c_tcm_unload_extra_data(false)
	c_weapon_clear(false)

	-- free melee sounds
	for _, v in pairs(c_weapon_getWeapons()) do
		if v.meleeRange ~= 0 then
			tankbobs.a_setVolumeChunk(c_const_get("weaponAudio_dir") .. v.fireSound, 0)
			tankbobs.a_freeSound(c_const_get("weaponAudio_dir") .. v.fireSound)
		end
	end
end

-- default game_refreshKeys in case it isn't defined
function game_refreshKeys()
	tankbobs.in_getKeys()

	for i = 1, #c_world_getTanks() do
		local breaking = false repeat
			local tank = c_world_getTanks()[i]

			if not tank then
				breaking = true break
			end

			if tank.bot then
				breaking = false break
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
		until true if breaking then break end
	end
end

local aa = {{0, 0}, {0, 0}}  -- aim-aid table
local m = {0, 0, 0, 0, 0, 0, 0, 0}  -- ammobar table
local w, t = {{0, 0}, {0, 0}, {0, 0}, {0, 0}}, {{0, 0}, {0, 0}, {0, 0}, {0, 0}}
local function game_drawWorld(d)
	gl.PushMatrix()
		-- draw tanks and walls
		for i = 1, c_const_get("tcm_maxLevel") do
			if i == c_const_get("tcm_tankLevel") then
				-- draw tank-level things

				-- trails
				for k, v in pairs(trails) do
					local breaking = false repeat
						-- {time left, maximum intensity, list}
						v[1] = v[1] - d
						if v[1] <= 0 then
							gl.DeleteLists(v[3], 1)

							if trails[k] then
								trails[k] = nil
							end

							breaking = false break
						end

						gl.Color(1, 1, 1, v[1] / v[2])
						gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, v[2] / v[3])
						gl.PushMatrix()
							gl.CallList(v[3])
						gl.PopMatrix()
					until true if breaking then break end
				end

				-- draw corpses
				for _, v in pairs(c_world_getCorpses()) do
					if v.exists then
						if not v.explode then
							gl.PushAttrib("CURRENT_BIT")
								gl.PushMatrix()
									gl.Translate(v.p.x, v.p.y, 0)
									gl.Rotate(tankbobs.m_degrees(v.r), 0, 0, 1)
									local r, g, b, a = v.color.r, v.color.g, v.color.b, 1
									if c_world_isTeamGameType(c_world_gameType) then
										-- team colors
										local color = c_const_get(v.red and "color_red" or "color_blue")
										r, g, b, a = color[1], color[2], color[3], color[4]
										gl.Color(r, g, b, a)
										gl.TexEnv("TEXTURE_ENV_COLOR", r, g, b, a)

										-- corpse
										gl.CallList(corpse_listBase)
										-- corpse outline
										gl.Color(1, 1, 1, 1)
										gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 1)
										gl.CallList(corpseBorder_listBase)
									end
								gl.PopMatrix()
							gl.PopAttrib()
						else
							-- draw explosions things from center

							-- TODO
						end
					end
				end

				-- render tanks
				for k, v in pairs(c_world_getTanks()) do
					if v.exists then
						gl.PushAttrib("CURRENT_BIT")
							gl.PushMatrix()
								gl.Translate(v.p.x, v.p.y, 0)
								gl.Rotate(tankbobs.m_degrees(v.r), 0, 0, 1)
								local r, g, b, a = v.color.r, v.color.g, v.color.b, 1
								if c_world_isTeamGameType(c_world_gameType) then
									-- team colors
									local color = c_const_get(v.red and "color_red" or "color_blue")
									r, g, b, a = color[1], color[2], color[3], color[4]
								end
								if v.cd.acceleration then
									if r + g + b >= 2.5 then
										r = r + c_const_get("tank_lightAccelerationColorOffset")
										g = g + c_const_get("tank_lightAccelerationColorOffset")
										b = b + c_const_get("tank_lightAccelerationColorOffset")
									else
										r = r + c_const_get("tank_accelerationColorOffset")
										g = g + c_const_get("tank_accelerationColorOffset")
										b = b + c_const_get("tank_accelerationColorOffset")
									end
								end
								gl.Color(r, g, b, a)
								gl.TexEnv("TEXTURE_ENV_COLOR", r, g, b, a)
								-- blend color with tank texture
								gl.CallList(tank_listBase)
								-- white outline
								gl.Color(1, 1, 1, 1)
								gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 1)
								gl.CallList(tankBorder_listBase)
								-- shield
								gl.Color(1, 1, 1, v.shield / c_const_get("tank_boostShield"))
								gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, v.shield / c_const_get("tank_boostShield"))
								gl.CallList(tankShield_listBase)
								-- tag
								if c_world_gameType == CHASE and v.tagged then
									gl.Color(1, 1, 1, 1)
									gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 1)
									gl.CallList(tankTagged_listBase)
								end

								if v.weapon and not v.reloading and c_weapon_getWeapons()[v.weapon] then
									gl.CallList(c_weapon_getWeapons()[v.weapon].m.p.list)
								end
							gl.PopMatrix()
						gl.PopAttrib()

						-- aiming aids
						gl.EnableClientState("VERTEX_ARRAY")
						if (v.weapon and c_weapon_getWeapons()[v.weapon] and c_weapon_getWeapons()[v.weapon].aimAid and not v.reloading) or (v.cd.aimAid) then
							gl.PushAttrib("ENABLE_BIT")
								local b
								local vec = tankbobs.m_vec2()
								local start, endP = tankbobs.m_vec2(v.p), tankbobs.m_vec2()
				
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
				
								aa[1][1] = start.x aa[1][2] = start.y
								aa[2][1] = endP.x aa[2][2] = endP.y
								gl.Disable("TEXTURE_2D")
								gl.Color(0.9, 0.1, 0.1, 1)
								gl.TexEnv("TEXTURE_ENV_COLOR", 0.9, 0.1, 0.1, 1)
								gl.VertexPointer(aa)
								gl.LineWidth(c_const_get("aimAid_width"))
								gl.DrawArrays("LINES", 0, 2)
							gl.PopAttrib()
						end
						gl.DisableClientState("VERTEX_ARRAY")

						-- draw name
						gl.PushMatrix()
							gl.Translate(v.p.x, v.p.y, 0)
							tankbobs.r_drawString(v.name, c_const_get("tank_nameOffset"), v.color.r, v.color.g, v.color.b, c_config_get("client.renderer.scoresAlpha"), c_const_get("tank_nameScalex"), c_const_get("tank_nameScaley"), false)
						gl.PopMatrix()

						-- healthbars and ammo bars
						gl.PushMatrix()
							gl.Translate(v.p.x, v.p.y, 0)
							gl.Rotate(tankbobs.m_degrees(v.r) + c_const_get("healthbar_rotation"), 0, 0, 1)
							if not (c_config_get("game.player" .. tostring(k) .. ".color.r", true)) then
								c_config_set("game.player" .. tostring(k) .. ".color.r", c_config_get("game.defaultTankRed"))
								c_config_set("game.player" .. tostring(k) .. ".color.g", c_config_get("game.defaultTankBlue"))
								c_config_set("game.player" .. tostring(k) .. ".color.b", c_config_get("game.defaultTankGreen"))
								c_config_set("game.player" .. tostring(k) .. ".color.a", c_config_get("game.defaultTankAlpha"))
							end

							if v.weapon and c_weapon_getWeapons()[v.weapon] and c_weapon_getWeapons()[v.weapon].capacity > 0 then
								gl.Color(1, 1, 1, 1)
								gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 1)
								gl.CallList(ammobarBorder_listBase)
								gl.Color(c_const_get("ammobar_r"), c_const_get("ammobar_g"), c_const_get("ammobar_b"), c_const_get("ammobar_a"))
								gl.TexEnv("TEXTURE_ENV_COLOR", c_const_get("ammobar_r"), c_const_get("ammobar_g"), c_const_get("ammobar_b"), c_const_get("ammobar_a"))
								gl.PushMatrix()
									gl.PushAttrib("ENABLE_BIT")
										gl.Disable("TEXTURE_2D")
										gl.Translate((c_const_get("ammobarBorder_renderx1") + c_const_get("ammobarBorder_renderx2")) / 2, c_const_get("ammobarBorder_rendery1"), 0)
										gl.Scale(c_const_get("ammobarBorder_renderx4") - c_const_get("ammobarBorder_renderx1"), 1, 1)

										local height = c_const_get("ammobarBorder_rendery2") - c_const_get("ammobarBorder_rendery1")

										gl.EnableClientState("VERTEX_ARRAY")
											local ammo = v.ammo
											local capacity = c_weapon_getWeapons()[v.weapon].capacity
											local spacing = 0.1 * (3 / capacity)

											local x = 0
											local xp = x
											for i = 1, ammo do
												xp = x
												x = x - spacing + 1 / capacity

												m[i * 8 - 7], m[i * 8 - 6] = xp, height
												m[i * 8 - 5], m[i * 8 - 4] = xp, 0
												m[i * 8 - 3], m[i * 8 - 2] = x, 0
												m[i * 8 - 1], m[i * 8 - 0] = x, height

												x = x + spacing
											end

											if ammo > 0 then
												gl.VertexPointer(m, 2)  -- XXX: this call causes memory corruption under older versions of LuaGL  -- TODO: update windows (32 and 64-bit) LuaGL libraries
												gl.DrawArrays("QUADS", 0, 4 * ammo)
											end
										gl.DisableClientState("VERTEX_ARRAY")
									gl.PopAttrib()
								gl.PopMatrix()

								-- clips
								gl.PushMatrix()
									gl.PushAttrib("ENABLE_BIT")
										gl.Disable("TEXTURE_2D")
										gl.Translate((c_const_get("ammobarBorder_renderx1") + c_const_get("ammobarBorder_renderx2")) / 2, c_const_get("ammobarBorder_rendery1") - 0.5, 0)
										gl.Scale(c_const_get("ammobarBorder_renderx4") - c_const_get("ammobarBorder_renderx1"), 1, 1)

										local height = 2 * c_const_get("ammobarBorder_rendery2") - c_const_get("ammobarBorder_rendery1")

										gl.EnableClientState("VERTEX_ARRAY")
											local clips = v.clips
											local spacing = 1 / 8

											local x = 0
											local xp = x
											for i = 1, clips do
												xp = x
												x = x + spacing

												m[i * 8 - 7], m[i * 8 - 6] = xp, height
												m[i * 8 - 5], m[i * 8 - 4] = xp, 0
												m[i * 8 - 3], m[i * 8 - 2] = x, 0
												m[i * 8 - 1], m[i * 8 - 0] = x, height

												x = x + spacing
											end

											if clips > 0 then
												gl.VertexPointer(m, 2)
												gl.DrawArrays("QUADS", 0, 4 * clips)  -- this call (possibly the second call *also*) causes memory corruption on older versions of LuaGL  -- TODO: update windows and 64-bit LuaGL libraries
											end
										gl.DisableClientState("VERTEX_ARRAY")
									gl.PopAttrib()
								gl.PopMatrix()
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
			end

			for k, v in pairs(c_tcm_current_map.walls) do
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
					gl.DrawArrays("POLYGON", 0, #v.m.pos)  -- TODO: FIXME: figure out why texture coordinates are ignored and remove immediate mode below
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

		if c_world_gameType == DOMINATION then
			-- draw control points
			for _, v in pairs(c_tcm_current_map.controlPoints) do
				local color

				if v.m.team == "red" then
					color = c_const_get("color_red")
				elseif v.m.team == "blue" then
					color = c_const_get("color_blue")
				else
					color = c_const_get("color_neutral")
				end

				if not v.m.r then
					v.m.r = 0
				else
					v.m.r = v.m.r + d * c_const_get("controlPoint_rotation")
				end

				gl.Color(color[1], color[2], color[3], color[4])
				gl.TexEnv("TEXTURE_ENV_COLOR", color[1], color[2], color[3], color[4])
				gl.PushMatrix()
					gl.Translate(v.p.x, v.p.y, 0)
					gl.Rotate(tankbobs.m_degrees(v.m.r), 0, 0, 1)
					gl.CallList(controlPoint_listBase)
				gl.PopMatrix()
			end
		elseif c_world_gameType == CAPTURETHEFLAG then
			for _, v in pairs(c_tcm_current_map.flags) do
				local color

				if v.red then
					color = c_const_get("color_red")
				else
					color = c_const_get("color_blue")
				end

				gl.Color(color[1], color[2], color[3], color[4])
				gl.TexEnv("TEXTURE_ENV_COLOR", color[1], color[2], color[3], color[4])

				-- draw base
				gl.PushMatrix()
					gl.Translate(v.p.x, v.p.y, 0)
					gl.CallList(flagBase_listBase)
				gl.PopMatrix()

				-- draw flag
				gl.PushMatrix()
					if v.m.dropped then
						gl.Translate(v.m.pos.x, v.m.pos.y, 0)
					elseif v.m.stolen then
						gl.Translate(c_world_getTanks()[v.m.stolen].p.x, c_world_getTanks()[v.m.stolen].p.y, 0)
					else
						gl.Translate(v.p.x, v.p.y, 0)
					end
					gl.CallList(flag_listBase)
				gl.PopMatrix()
			end
		end

		-- powerups are drawn next
		for _, v in pairs(c_world_getPowerups()) do
			local powerupType = c_world_getPowerupTypeByIndex(v.powerupType)

			if powerupType then
				gl.PushMatrix()
					local c = powerupType.c
					gl.Color(c.r, c.g, c.b, c.a)
					gl.TexEnv("TEXTURE_ENV_COLOR", c.r, c.g, c.b, c.a)
					gl.Translate(v.p.x, v.p.y, 0)
					gl.Rotate(tankbobs.m_degrees(v.r), 0, 0, 1)
					gl.CallList(powerup_listBase)
				gl.PopMatrix()
			end
		end

		-- melee weapons
		for _, v in pairs(c_world_getTanks()) do
			if v.exists then
				if bit.band(v.state, FIRING) ~= 0 and v.weapon and c_weapon_getWeapons()[v.weapon] and c_weapon_getWeapons()[v.weapon].meleeRange ~= 0 and not v.reloading then
					gl.PushMatrix()
						gl.Translate(v.p.x, v.p.y, 0)
						gl.Rotate(tankbobs.m_degrees(v.r - c_const_get("tank_defaultRotation")), 0, 0, 1)
						gl.CallList(c_weapon_getWeapons()[v.weapon].m.p.projectileList)
					gl.PopMatrix()
				end
			end
		end

		-- projectiles
		for _, v in pairs(c_weapon_getProjectiles()) do
			if c_weapon_getWeapons()[v.weapon] and c_weapon_getWeapons()[v.weapon].trail == 0 and c_weapon_getWeapons()[v.weapon].trailWidth == 0 then  -- only draw the trail
				gl.PushMatrix()
					gl.Translate(v.p.x, v.p.y, 0)
					gl.Rotate(tankbobs.m_degrees(v.r), 0, 0, 1)
					gl.CallList(c_weapon_getWeapons()[v.weapon].m.p.projectileList)
				gl.PopMatrix()
			end
		end
	gl.PopMatrix()
end

local frame = 0
function game_step(d)
	if frame % 1024 == 0 then
		math.randomseed(tankbobs.t_getTicks())
	end

	frame = frame + 1

	-- get input keys
	local krr = c_config_get("client.krr")
	if krr > 0 and frame % krr == 0 then
		game_refreshKeys()
	end

	-- render world
	gl.PushMatrix()
		-- adjust the camera
		local uppermost
		local lowermost
		local rightmost
		local leftmost
		-- Position the camera so that all tanks and special powerups are shown, while zooming in as much as possible
		for _, v in pairs(c_world_getTanks()) do
			if not leftmost or v.p.x < leftmost then
				leftmost = v.p.x
			end
			if not rightmost or v.p.x > rightmost then
				rightmost = v.p.x
			end

			if not lowermost or v.p.y < lowermost then
				lowermost = v.p.y
			end
			if not uppermost or v.p.y > uppermost then
				uppermost = v.p.y
			end
		end
		for _, v in pairs(c_world_getPowerups()) do
			if c_tcm_current_map.powerupSpawnPoints[v.spawner] and c_tcm_current_map.powerupSpawnPoints[v.spawner].focus then
				if not leftmost or v.p.x < leftmost then
					leftmost = v.p.x
				end
				if not rightmost or v.p.x > rightmost then
					rightmost = v.p.x
				end

				if not lowermost or v.p.y < lowermost then
					lowermost = v.p.y
				end
				if not uppermost or v.p.y > uppermost then
					uppermost = v.p.y
				end
			end
		end
		if not uppermost or not lowermost or not rightmost or not leftmost then
			-- draw world in default position
			game_drawWorld(d)

			return
		end
		local m = c_tcm_current_map
		-- ignore m.staticCamera and automatically determine whether to keep camera static
		if m.uppermost <= 105 and m.lowermost >= -5 and m.rightmost <= 105 and m.leftmost >= -5 then
			uppermost, rightmost, lowermost, leftmost = 50, 50, 50, 50
		end

		gl.Translate(50, 50, 0)

		local distance = math.abs(rightmost - leftmost) > math.abs(uppermost - lowermost) and math.abs(rightmost - leftmost) or math.abs(uppermost - lowermost)
		local scale = 100 / (distance + c_config_get("client.cameraExtraFOV"))
		if scale > 1 then
			scale = 1
		end
		zoom = common_lerp(zoom, scale, math.min(1, d * c_config_get("client.cameraSpeed")))
		gl.Scale(zoom, zoom, 1)

		camera = common_lerp(camera, tankbobs.m_vec2(-(rightmost + leftmost) / 2, -(uppermost + lowermost) / 2), math.min(1, d * c_config_get("client.cameraSpeed")))
		gl.Translate(camera.x, camera.y, 0)

		game_drawWorld(d)
	gl.PopMatrix()

	-- play sounds and insert trails
	if c_world_getPaused() then
		for _, v in pairs(c_weapon_getWeapons()) do
			if v.meleeRange ~= 0 then
				tankbobs.a_setVolumeChunk(c_const_get("weaponAudio_dir") .. v.fireSound, 0)
			end
		end

		return
	end

	for _, v in pairs(c_weapon_getWeapons()) do
		if v.meleeRange ~= 0 then
			v.m.used = false
		end
	end

	for _, v in pairs(c_world_getTanks()) do
		if v.exists then
			if v.explode and not v.m.explodeSound then
				if c_const_get("world_corpseTime") >= c_const_get("world_minimumCorpseTimeForDeathNoiseAndStuff") then
					tankbobs.a_playSound(c_const_get("corpseExplode_sound"))
				end
			end
		end
	end

	for _, v in pairs(c_world_getTanks()) do
		if v.exists then
			-- handle melee sounds specially
			if v.weapon and c_weapon_getWeapons()[v.weapon] and c_weapon_getWeapons()[v.weapon].meleeRange ~= 0 and not v.reloading then
				if bit.band(v.state, FIRING) ~= 0 then
					c_weapon_getWeapons()[v.weapon].m.used = true
				end
			end

			if v.weapon and bit.band(v.state, FIRING) ~= 0 then
				if v.m.lastFireTime ~= v.lastFireTime then
					v.m.lastFireTime = v.lastFireTime

					if c_weapon_getWeapons()[v.weapon].meleeRange ~= 0 then
					elseif v.m.empty then
						tankbobs.a_playSound(c_const_get("emptyTrigger_sound"))
					elseif v.weapon and v.m.fired then
						if type(c_weapon_getWeapons()[v.weapon].fireSound) == "table" then
							tankbobs.a_playSound(c_const_get("weaponAudio_dir") .. c_weapon_getWeapons()[v.weapon].fireSound[math.random(1, #c_weapon_getWeapons()[v.weapon].fireSound)])
						elseif type(c_weapon_getWeapons()[v.weapon].fireSound) == "string" then
							tankbobs.a_playSound(c_const_get("weaponAudio_dir") .. c_weapon_getWeapons()[v.weapon].fireSound)
						end

						if c_weapon_getWeapons()[v.weapon].trail ~= 0 and c_weapon_getWeapons()[v.weapon].trailWidth ~= 0 then
							-- calculate the beginning and end point before inserting
							local start, endP = tankbobs.m_vec2(v.p), tankbobs.m_vec2()
							local tmp = tankbobs.m_vec2()
							local list = gl.GenLists(1)
							local b

							start.R = c_const_get("trail_startDistance")
							start.t = v.r
							start:add(v.p)

							endP(start)
							tmp.R = c_const_get("trail_maxDistance")
							tmp.t = v.r
							endP:add(tmp)

							b, vec, _, _ = c_world_findClosestIntersection(start, endP, "projectile")
							if b and vec then  -- FIXME: vec can be nil if b is not true?
								endP = vec
							end

							gl.NewList(list, "COMPILE")
								local offset = tankbobs.m_vec2()

								offset.R = c_weapon_getWeapons()[v.weapon].trailWidth / 2
								offset.t = (endP - start).t + (2 * math.pi / 4)

								gl.BindTexture("TEXTURE_2D", c_weapon_getWeapons()[v.weapon].m.p.projectileTexture[1])
								gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")
								gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
								gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")

								gl.Begin("TRIANGLES")
									local length = (endP - start).R

									tmp(c_weapon_getWeapons()[v.weapon].projectileTexturer[1])
									gl.TexCoord(tmp.x, tmp.y)
									tmp = start - offset
									gl.Vertex(tmp.x, tmp.y)

									tmp(c_weapon_getWeapons()[v.weapon].projectileTexturer[2])
									gl.TexCoord(tmp.x, tmp.y)
									tmp = start + offset
									gl.Vertex(tmp.x, tmp.y)

									tmp(c_weapon_getWeapons()[v.weapon].projectileTexturer[3])
									gl.TexCoord(tmp.x, tmp.y * length)
									tmp(endP)
									gl.Vertex(tmp.x, tmp.y)
								gl.End()
							gl.EndList()

							table.insert(trails, {c_weapon_getWeapons()[v.weapon].trail, c_weapon_getWeapons()[v.weapon].trail, list})
						end
					end
				end
			end

			if v.weapon and v.reloading and v.m.lastReloadTime ~= v.reloading then
				v.m.lastReloadTime = v.reloading

				if c_weapon_getWeapons()[v.weapon] and c_weapon_getWeapons()[v.weapon].shotgunClips then
					if v.shotgunReloadState == 0 then
						tankbobs.a_playSound(c_const_get("weaponAudio_dir") .. c_weapon_getWeapons()[v.weapon].reloadSound.initial)
					elseif v.shotgunReloadState == 1 then
						tankbobs.a_playSound(c_const_get("weaponAudio_dir") .. c_weapon_getWeapons()[v.weapon].reloadSound.clip)
					elseif v.shotgunReloadState == 2 then
						tankbobs.a_playSound(c_const_get("weaponAudio_dir") .. c_weapon_getWeapons()[v.weapon].reloadSound.final)
					end
				else
					if type(c_weapon_getWeapons()[v.weapon].reloadSound) == "table" then
						tankbobs.a_playSound(c_const_get("weaponAudio_dir") .. c_weapon_getWeapons()[v.weapon].fireSound[math.random(1, #c_weapon_getWeapons()[v.weapon].reloadSound)])
					else
						tankbobs.a_playSound(c_const_get("weaponAudio_dir") .. c_weapon_getWeapons()[v.weapon].reloadSound)
					end
				end
			end

			if v.m.lastCollideTime and v.m.lastCollideTimeB ~= v.m.lastCollideTime then
				v.m.lastCollideTimeB = v.m.lastCollideTime

				tankbobs.a_setVolumeChunk(c_const_get("collide_sound"), v.m.intensity * c_config_get("client.volume"))
				tankbobs.a_playSound(c_const_get("collide_sound"))
			end

			if v.m.lastDamageTime and v.m.lastDamageTimeB ~= v.m.lastDamageTime then
				v.m.lastDamageTimeB = v.m.lastDamageTime

				tankbobs.a_playSound(c_const_get("damage_sound"))
			end
		else
			v.m.lastCollideTime, v.m.lastDamageTime, v.m.lastReloadTime = nil
		end

		if v.spawning and v.m.lastDieTimeB ~= v.m.lastDieTime then
			v.m.lastDieTimeB = v.m.lastDieTime

			tankbobs.a_playSound(c_const_get("die_sound"))
		end

		if v.m.lastPickupTime and v.m.lastPickupTimeB ~= v.m.lastPickupTime then
			v.m.lastPickupTimeB = v.m.lastPickupTime 

			tankbobs.a_playSound(c_const_get("powerupPickup_sound"))
		end

		if v.m.lastTeleportTime and v.m.lastTeleportTimeB ~= v.m.lastTeleportTime then
			v.m.lastTeleportTimeB = v.m.lastTeleportTime 

			tankbobs.a_playSound(c_const_get("teleport_sound"))
		end
	end

	for _, v in pairs(c_weapon_getWeapons()) do
		if v.meleeRange ~= 0 then
			if v.m.used then
				tankbobs.a_setVolumeChunk(c_const_get("weaponAudio_dir") .. v.fireSound, c_config_get("client.volume"))
			else
				tankbobs.a_setVolumeChunk(c_const_get("weaponAudio_dir") .. v.fireSound, 0)
			end
		end
	end

	for _, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
		if v.m.lastSpawnTimeB ~= v.m.lastSpawnTime then
			v.m.lastSpawnTimeB = v.m.lastSpawnTime

			tankbobs.a_playSound(c_const_get("powerupSpawn_sound"))
		end
	end

	for _, v in pairs(c_weapon_getProjectiles()) do
		if v.collisions > 0 and v.collisions ~= v.m.lastCollisions and c_weapon_getWeapons()[v.weapon] and c_weapon_getWeapons()[v.weapon].trail == 0 and c_weapon_getWeapons()[v.weapon].trailWidth == 0 then
			v.m.lastCollisions = v.collisions

			tankbobs.a_playSound(c_const_get("collideProjectile_sounds")[math.random(1, #c_const_get("collideProjectile_sounds"))])
		end
	end

	if c_world_gameType == DOMINATION then
		for _, v in pairs(c_tcm_current_map.controlPoints) do
			if v.m.teamB ~= v.m.team then
				v.m.teamB = v.m.team

				tankbobs.a_playSound(c_const_get("control_sound"))
			end
		end
	elseif c_world_gameType == CAPTURETHEFLAG then
		for _, v in pairs(c_tcm_current_map.flags) do
			if v.m.lastCaptureTime and v.m.lastCaptureTimeB ~= v.m.lastCaptureTime then
				v.m.lastCaptureTimeB = v.m.lastCaptureTime

				tankbobs.a_playSound(c_const_get("flagCapture_sound"))
			end

			if v.m.lastPickupTime and v.m.lastPickupTimeB ~= v.m.lastPickupTime then
				v.m.lastPickupTimeB = v.m.lastPickupTime

				tankbobs.a_playSound(c_const_get("flagPickUp_sound"))
			end

			if v.m.lastReturnTime and v.m.lastReturnTimeB ~= v.m.lastReturnTime then
				v.m.lastReturnTimeB = v.m.lastReturnTime

				tankbobs.a_playSound(c_const_get("flagReturn_sound"))
			end
		end
	end
end
