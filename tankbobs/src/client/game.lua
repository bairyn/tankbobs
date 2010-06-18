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
st_game.lua

Game play functions shared by both offline and online states
--]]

local tankbobs = tankbobs
local gl = gl
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

local zoom   = {}
local trails = {}
local camera = {}

local wall_textures

function game_init()
	-- localize frequently used globals
	tankbobs = _G.tankbobs
	gl = _G.gl
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

	c_const_set("game_roundWinLabelTime", 1, 1)
	c_const_set("game_roundWinLabelMaxOpacityTime", 0.75, 1)
	c_const_set("game_audioRange", 150, 0)
end

function game_done()
end

function game_new()
	-- stop background state *only* if a game is being started from foreground state
	if c_state_getCurrentState() == 1 and backgroundState then
		c_state_backgroundStop(backgroundState)
		backgroundState = nil
	end

	for i = 1, 4 do
		camera[i] = tankbobs.m_vec2(50, 50)
		zoom[i] = 1
	end

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

	-- GUI if in foreground
	if c_state_getCurrentState() == 1 then
		-- scores
		local function updateScores(widget)
			if not c_world_gameTypeTeam(c_world_getGameType()) then
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

		-- game timer
		local function updateGameTimer(widget)
			widget.text = common_formatTimeSeconds(c_world_getTimer())
		end

		local y = 92.5

		if c_config_get("client.renderer.gameTimer") then
			gui_addLabel(tankbobs.m_vec2(89.75, y), "", updateGameTimer, 0.5, c_config_get("client.renderer.fpsRed"), c_config_get("client.renderer.fpsGreen"), c_config_get("client.renderer.fpsBlue"), c_config_get("client.renderer.fpsAlpha"), c_config_get("client.renderer.fpsRed"), c_config_get("client.renderer.fpsGreen"), c_config_get("client.renderer.fpsGreen"), c_config_get("client.renderer.fpsAlpha"))
			y = y - 7.5
		end

		-- fps counter
		local function updateFPS(widget)
			widget.text = tostring(math.floor(fps))
		end

		if c_config_get("client.renderer.fpsCounter") then
			gui_addLabel(tankbobs.m_vec2(92.5, y), "", updateFPS, 0.5, c_config_get("client.renderer.fpsRed"), c_config_get("client.renderer.fpsGreen"), c_config_get("client.renderer.fpsBlue"), c_config_get("client.renderer.fpsAlpha"), c_config_get("client.renderer.fpsRed"), c_config_get("client.renderer.fpsGreen"), c_config_get("client.renderer.fpsGreen"), c_config_get("client.renderer.fpsAlpha"))
		end

		-- end of round label
		local timeRemaining = 0
		local bwin = {"", {r = 0, g = 0, b = 0, a = 0}}
		local function updateRound(widget, d)
			if win then
				bwin = win
				win = nil

				if not bwin.a then
					bwin.a = 1.0
				end

				timeRemaining = c_const_get("game_roundWinLabelTime")
			end

			timeRemaining = math.max(0, timeRemaining - d)

			if timeRemaining > 0 then
				widget.text = bwin[1]
				widget.color.r = bwin[2].r
				widget.color.g = bwin[2].g
				widget.color.b = bwin[2].b
			end
			widget.color.a = math.min(1, timeRemaining / c_const_get("game_roundWinLabelMaxOpacityTime"))
		end

		gui_addLabel(tankbobs.m_vec2(25, 50), "", updateRound, 1.1, c_config_get("client.renderer.scoresRed"), c_config_get("client.renderer.scoresGreen"), c_config_get("client.renderer.scoresBlue"), c_config_get("client.renderer.scoresAlpha"), c_config_get("client.renderer.scoresRed"), c_config_get("client.renderer.scoresGreen"), c_config_get("client.renderer.scoresGreen"), c_config_get("client.renderer.scoresAlpha"))
	end

	-- initialize melee sounds
	for _, v in pairs(c_weapon_getWeapons()) do
		if v.meleeRange ~= 0 then
			tankbobs.a_playSound(c_const_get("weaponAudio_dir") .. v.fireSound, -1)
			tankbobs.a_setVolumeChunk(c_const_get("weaponAudio_dir") .. v.fireSound, 0)
		end
	end

	-- randomly play ambience
	if c_config_get("client.ambience") then
		local a = c_const_get("ambience_sounds")[math.random(1, c_const_get("ambience_chanceDenom"))]
		if a then
			ambience = a

			tankbobs.a_playSound(a)
		end
	end

	-- play music
	if #c_tcm_current_map.song > 0 then
		tankbobs.a_startMusic(c_const_get("song_dir") .. c_tcm_current_map.song)
	end
end

function game_end()
	-- reset viewport
	gl.Viewport(0, 0, c_config_get("client.renderer.width"), c_config_get("client.renderer.height"))

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

	-- stop music
	tankbobs.a_stopMusic()

	-- stop playing ambience
	if ambience then
		tankbobs.a_freeSound(ambience)
		ambience = nil
	end

	-- free melee sounds
	for _, v in pairs(c_weapon_getWeapons()) do
		if v.meleeRange ~= 0 then
			tankbobs.a_setVolumeChunk(c_const_get("weaponAudio_dir") .. v.fireSound, 0)
			tankbobs.a_freeSound(c_const_get("weaponAudio_dir") .. v.fireSound)
		end
	end

	-- start background game *only* if the game ended from foreground state
	if c_state_getCurrentState() == 1 and c_config_get("client.preview") then
		backgroundState = c_state_backgroundStart(background_state)
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
		until true if breaking then break end
	end
end

local aa = {{0, 0}, {0, 0}}  -- aim-aid table
local m = {0, 0, 0, 0, 0, 0, 0, 0}  -- ammobar table
local w, t = {{0, 0}, {0, 0}, {0, 0}, {0, 0}}, {{0, 0}, {0, 0}, {0, 0}, {0, 0}}
function game_drawWorld(d, M, rotM)
	gl.PushMatrix()
		-- draw tanks and walls
		for i = 1, c_const_get("tcm_maxLevel") do
			local l = c_tcm_current_map.levels[i]

			if l then
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
										if c_world_gameTypeTeam(c_world_getGameType()) then
											-- team colors
											local color = c_const_get(v.red and "color_red" or "color_blue")
											r, g, b, a = color[1], color[2], color[3], color[4]
										end
										gl.Color(r, g, b, a)
										gl.TexEnv("TEXTURE_ENV_COLOR", r, g, b, a)

										-- corpse
										gl.CallList(corpse_listBase)
										-- corpse outline
										gl.Color(1, 1, 1, 1)
										gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 1)
										gl.CallList(corpseBorder_listBase)
									gl.PopMatrix()
								gl.PopAttrib()
							else
								-- draw explosions things from center

								gl.PushAttrib("CURRENT_BIT")
									gl.PushMatrix()
										gl.Translate(v.p.x, v.p.y, 0)
										gl.Color(1, 1, 1, 1)
										gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 1)
										local scale = -v.timeTilExplode / c_const_get("world_corpsePostTime")
										gl.Scale(scale, scale, 1)
										gl.CallList(explosion_listBase)
									gl.PopMatrix()
								gl.PopAttrib()
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
									if c_world_gameTypeTeam(c_world_getGameType()) then
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
									local switch = c_world_getGameType()
									if switch == MEGATANK then
										if v.tagged or (v.megaTank and c_world_getTanks()[v.megaTank] == v) then
											gl.Color(1 - r, 1 - g, 1 - b, 0.7)
											gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 0.7)
											gl.CallList(tankMega_listBase)
										end
									elseif switch == CHASE then
										if v.tagged then
											gl.Color(1 - r, 1 - g, 1 - b, 0.7)
											gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 0.7)
											gl.CallList(tankTagged_listBase)
										end
									elseif switch == PLAGUE then
										if v.tagged then
											gl.Color(1 - r, 1 - g, 1 - b, 0.7)
											gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 0.7)
											gl.CallList(tankPlagued_listBase)
										end
									end

									if v.weapon and v.reloading <= 0.0 and c_weapon_getWeapons()[v.weapon] then
										gl.CallList(c_weapon_getWeapons()[v.weapon].m.p.list)
									end
								gl.PopMatrix()
							gl.PopAttrib()

							-- aiming aids
							gl.EnableClientState("VERTEX_ARRAY")
							if (v.weapon and c_weapon_getWeapons()[v.weapon] and c_weapon_getWeapons()[v.weapon].aimAid and v.reloading <= 0) or (v.cd.aimAid) then
								gl.PushAttrib("ENABLE_BIT")
									local l = v.cd.aimAidLock or 0

									aa[1][1] = v.cd.aimAidStart and v.cd.aimAidStart.x or 0 aa[1][2] = v.cd.aimAidStart and v.cd.aimAidStart.y or 0
									aa[2][1] = v.cd.aimAidStart and v.cd.aimAidEnd.x or 0 aa[2][2] = v.cd.aimAidStart and v.cd.aimAidEnd.y or 0
									gl.Disable("TEXTURE_2D")
									gl.Color(0.9 - 0.9 * l, 0.1, 0.1 + 0.9 * l, 1)
									gl.TexEnv("TEXTURE_ENV_COLOR", 0.9, 0.1, 0.1, 1)
									gl.VertexPointer(aa)
									gl.LineWidth(c_const_get("aimAid_width") + c_const_get("aimAid_lockWidth") * l)
									gl.DrawArrays("LINES", 0, 2)
								gl.PopAttrib()
							end
							gl.DisableClientState("VERTEX_ARRAY")


							-- draw name
							gl.PushMatrix()
								-- Un-rotate
								-- TODO: FIXME
								--[[
								if M and rotM then
									renderer_setMatrix(M)
								end
								--]]

								gl.Translate(v.p.x, v.p.y, 0)
								tankbobs.r_drawString(v.name, c_const_get("tank_nameOffset"), v.color.r, v.color.g, v.color.b, c_config_get("client.renderer.scoresAlpha"), c_const_get("tank_nameScalex"), c_const_get("tank_nameScaley"), false)

								-- Re-rotate
								--[[
								if M and rotM then
									renderer_setMatrix(rotM)
								end
								--]]
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

					-- render explosive projectiles
					for _, v in pairs(c_weapon_getProjectiles()) do
						local weapon = c_weapon_getWeapons()[v.weapon]

						if weapon and weapon.projectileExplode and v.collided and v.m.collideTime then
							-- draw explosions things from center
							gl.PushAttrib("CURRENT_BIT")
								gl.PushMatrix()
									gl.Translate(v.p.x, v.p.y, 0)
									gl.Color(1, 1, 1, 1)
									gl.TexEnv("TEXTURE_ENV_COLOR", 1, 1, 1, 1)
									local scale = 1 - ((v.m.collideTime - tankbobs.t_getTicks()) / c_world_timeMultiplier()) / weapon.projectileExplodeTime
									gl.Scale(scale, scale, 1)
									gl.CallList(explosion_listBase)
								gl.PopMatrix()
							gl.PopAttrib()
						end
					end
				end

				for _, v in pairs(l) do
					if v.m.pos then
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
		end

		-- render game-type dependant stuff
		local switch = c_world_getGameType()
		if switch == DOMINATION then
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
		elseif switch == CAPTURETHEFLAG then
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
			if v.exists and v.weapon then
				local weapon = c_weapon_getWeapons()[v.weapon]
				if weapon and ((bit.band(v.state, FIRING) ~= 0 and v.reloading <= 0) or weapon.meleeRange < 0) and weapon.meleeRange ~= 0 then
					gl.PushMatrix()
						gl.Translate(v.p.x, v.p.y, 0)
						gl.Rotate(tankbobs.m_degrees(v.r - c_const_get("tank_defaultRotation")), 0, 0, 1)
						if weapon.meleeRange < 0 then
							gl.Scale(v.radiusFireTime * 2, v.radiusFireTime * 2, 1)
						end
						gl.CallList(weapon.m.p.projectileList)
					gl.PopMatrix()
				end
			end
		end

		-- projectiles
		for _, v in pairs(c_weapon_getProjectiles()) do
			if c_weapon_getWeapons()[v.weapon] then
				if c_weapon_getWeapons()[v.weapon].trail == 0 and c_weapon_getWeapons()[v.weapon].trailWidth == 0 then  -- only draw the trail
					gl.PushMatrix()
						gl.Translate(v.p.x, v.p.y, 0)
						gl.Rotate(tankbobs.m_degrees(v.r), 0, 0, 1)
						gl.CallList(c_weapon_getWeapons()[v.weapon].m.p.projectileList)
					gl.PopMatrix()
				elseif debug and c_config_get("debug.client.drawTrailProjectiles") then  -- TODO client.debug.etc
					-- draw a red square
					gl.PushAttrib("ENABLE_BIT")
						gl.PushMatrix()
							gl.Disable("TEXTURE_2D")
							gl.Translate(v.p.x, v.p.y, 0)
							gl.Scale(2, 2, 1)
							gl.Color(1, 0, 0, 1)
							gl.Begin("QUADS")
								gl.Vertex(-1,  1)
								gl.Vertex(-1, -1)
								gl.Vertex( 1, -1)
								gl.Vertex( 1,  1)
							gl.End()
						gl.PopMatrix()
					gl.PopAttrib()
				end
			end
		end
	gl.PopMatrix()
end

function game_audioDistance(p)
	if not (online and connection.t and c_world_getTanks()[connection.t]) then
		local ds = {}
		for _, v in pairs(c_world_getTanks()) do
			table.insert(ds, math.max(0, 1 - (p - v.p).R / c_const_get("game_audioRange")))
		end
		table.sort(ds, function(a, b) return a > b end)  -- reverse sort
		return ds[1] or 1
	else
		return math.max(0, 1 - (p - c_world_getTanks()[connection.t].p).R / c_const_get("game_audioRange"))
	end
end

local frame = 0
function game_step(d)
	local t = tankbobs.t_getTicks()

	if frame % 1024 == 0 then
		math.randomseed(t)
	end

	frame = frame + 1

	-- get input keys
	local krr = c_config_get("client.krr")
	if krr > 0 and frame % krr == 0 then
		game_refreshKeys()
	end

	local function draw(filter, camnum)  -- filter tanks
		camnum = camnum or 1

		gl.PushMatrix()
			-- adjust the camera
			local uppermost
			local lowermost
			local rightmost
			local leftmost
			-- Position the camera so that all tanks and special powerups are shown, while zooming in as much as possible
			for k, v in pairs(c_world_getTanks()) do
				if not filter or filter(k, v) then
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
			for _, v in pairs(c_world_getPowerups()) do
				if not v.m.refocus or t > v.m.refocus then
					v.m.refocus = t + c_world_timeMultiplier(c_config_get("client.powerupRefocusTime"))

					if not v.m.focus then
						v.m.focus = {}
					end

					v.m.focus[camnum] = false

					for ks, vs in pairs(c_world_getTanks()) do
						if not filter or filter(ks, vs) then
							if vs.exists and (vs.p - v.p).R <= c_config_get("client.powerupFocusDistance") then
								v.m.focus[camnum] = true

								break
							end
						end
					end
				end

				--if c_tcm_current_map.powerupSpawnPoints[v.spawner] and c_tcm_current_map.powerupSpawnPoints[v.spawner].focus then
				if v.m.focus and v.m.focus[camnum] then
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
				game_drawWorld(d, nil, nil)

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
			scale = scale * c_config_get("client.cameraZoom") * c_world_getZoom()
			zoom[camnum] = common_lerp(zoom[camnum], scale, math.min(1, d * c_config_get("client.cameraSpeed")))
			gl.Scale(zoom[camnum], zoom[camnum], 1)

			camera[camnum] = common_lerp(camera[camnum], tankbobs.m_vec2(-(rightmost + leftmost) / 2, -(uppermost + lowermost) / 2), math.min(1, d * c_config_get("client.cameraSpeed")))

			local M, rotM

			gl.PushMatrix()
				gl.Translate(camera[camnum].x, camera[camnum].y, 0)

				M = renderer_getMatrix()  -- rotM can be identical to M
			gl.PopMatrix()

			if c_config_get("client.screens") > 0 and c_config_get("client.cameraRotate") then
				local tank = c_world_getTanks()[camnum]

				if tank and tank.exists then
					gl.Rotate(-tankbobs.m_degrees(tank.r - c_const_get("tank_defaultRotation")), 0, 0, 1)
				end
			end

			gl.Translate(camera[camnum].x, camera[camnum].y, 0)

			rotM = renderer_getMatrix()

			game_drawWorld(d, M, rotM)
		gl.PopMatrix()
	end

	-- render world
	local screens = c_config_get("client.screens")
	if c_config_get("client.screensEven") then
		screens = math.min(screens, #c_world_getTanks())
	end
	if online then
		screens = 1
	end
	local widthChange = c_config_get("client.screensWidthChange")  -- some space on side to avoid stretch effect

	local spacing = 2

	if screens == 0 then
		draw()
	elseif screens == 1 then
		gl.Viewport(0, 0, c_config_get("client.renderer.width"), c_config_get("client.renderer.height"))

		local function filter(k, v)
			if not online or not connection or not connection.t then
				return k == 1
			else
				return k == connection.t
			end
		end

		draw(filter)
	elseif screens == 2 then
		-- draw upper portion
		gl.Viewport(0, c_config_get("client.renderer.height") / 2 + spacing / 2, c_config_get("client.renderer.width") * widthChange, c_config_get("client.renderer.height") / 2 - spacing / 2)

		draw(function (k, v) return k == 1 end, 1)

		-- lower portion
		gl.Viewport(0, 0, c_config_get("client.renderer.width") * widthChange, c_config_get("client.renderer.height") / 2 - spacing / 2)

		draw(function (k, v) return k == 2 end, 2)
	elseif screens == 3 then
		-- draw upper portion
		gl.Viewport(0, c_config_get("client.renderer.height") / 2 + spacing / 2, c_config_get("client.renderer.width") * widthChange, c_config_get("client.renderer.height") / 2 - spacing / 2)

		draw(function (k, v) return k == 1 end, 1)

		-- lower left portion
		gl.Viewport(0, 0, c_config_get("client.renderer.width") / 2 - spacing / 2, c_config_get("client.renderer.height") / 2 - spacing / 2)

		draw(function (k, v) return k == 2 end, 2)

		-- lower right portion
		gl.Viewport(c_config_get("client.renderer.width") / 2 + spacing / 2, 0, c_config_get("client.renderer.width") / 2 - spacing / 2, c_config_get("client.renderer.height") / 2 - spacing / 2)

		draw(function (k, v) return k == 3 end, 3)
	elseif screens == 4 then
		-- upper left portion
		gl.Viewport(0, c_config_get("client.renderer.height") / 2 + spacing / 2, c_config_get("client.renderer.width") / 2 - spacing / 2, c_config_get("client.renderer.height") / 2 - spacing / 2)

		draw(function (k, v) return k == 1 end, 1)

		-- upper right portion
		gl.Viewport(c_config_get("client.renderer.width") / 2 + spacing / 2, c_config_get("client.renderer.height") / 2 + spacing / 2, c_config_get("client.renderer.width") / 2 - spacing / 2, c_config_get("client.renderer.height") / 2 - spacing / 2)

		draw(function (k, v) return k == 2 end, 2)

		-- lower left portion
		gl.Viewport(0, 0, c_config_get("client.renderer.width") / 2 - spacing / 2, c_config_get("client.renderer.height") / 2 - spacing / 2)

		draw(function (k, v) return k == 3 end, 3)

		-- lower right portion
		gl.Viewport(c_config_get("client.renderer.width") / 2 + spacing / 2, 0, c_config_get("client.renderer.width") / 2 - spacing / 2, c_config_get("client.renderer.height") / 2 - spacing / 2)

		draw(function (k, v) return k == 4 end, 4)
	else
		c_config_set("client.screens", 0)
	end

	-- reset viewport for GUI
	gl.Viewport(0, 0, c_config_get("client.renderer.width"), c_config_get("client.renderer.height"))

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
			v.m.used = nil
		end
	end

	for _, v in pairs(c_world_getCorpses()) do
		if v.exists then
			if v.explode and not v.m.explodeSound then
				v.m.explodeSound = t
				if c_const_get("world_corpseTime") >= c_const_get("world_minimumCorpseTimeForDeathNoiseAndStuff") then
					tankbobs.a_playSound(c_const_get("corpseExplode_sound"))
					tankbobs.a_setVolumeChunk(c_const_get("corpseExplode_sound"), game_audioDistance(v.p))
				end
			end
		end
	end

	local function tank(v)
		if v.exists then
			-- handle melee sounds specially
			if v.weapon and c_weapon_getWeapons()[v.weapon] and c_weapon_getWeapons()[v.weapon].meleeRange ~= 0 and v.reloading <= 0 then
				if bit.band(v.state, FIRING) ~= 0 then
					local m = c_weapon_getWeapons()[v.weapon].m
					if m.used then
						m.used = math.max(m.used, game_audioDistance(v.p))
					else
						m.used = game_audioDistance(v.p)
					end
				end
			end

			if v.weapon and bit.band(v.state, FIRING) ~= 0 and c_weapon_canFireInMode() then
				if v.m.lastFireTime ~= v.lastFireTime then
					v.m.lastFireTime = v.lastFireTime

					if c_weapon_getWeapons()[v.weapon].meleeRange ~= 0 then
					elseif v.m.empty then
						tankbobs.a_playSound(c_const_get("emptyTrigger_sound"))
						tankbobs.a_setVolumeChunk(c_const_get("emptyTrigger_sound"), game_audioDistance(v.p))
					elseif v.weapon and v.m.fired then
						local sound

						if type(c_weapon_getWeapons()[v.weapon].fireSound) == "table" then
							sound = c_const_get("weaponAudio_dir") .. c_weapon_getWeapons()[v.weapon].fireSound[math.random(1, #c_weapon_getWeapons()[v.weapon].fireSound)]
						elseif type(c_weapon_getWeapons()[v.weapon].fireSound) == "string" then
							sound = c_const_get("weaponAudio_dir") .. c_weapon_getWeapons()[v.weapon].fireSound
						end
						tankbobs.a_playSound(sound)
						tankbobs.a_setVolumeChunk(sound, game_audioDistance(v.p))

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

									tmp(c_weapon_getWeapons()[v.weapon].projectiletextureR[1])
									gl.TexCoord(tmp.x, tmp.y)
									tmp = start - offset
									gl.Vertex(tmp.x, tmp.y)

									tmp(c_weapon_getWeapons()[v.weapon].projectiletextureR[2])
									gl.TexCoord(tmp.x, tmp.y)
									tmp = start + offset
									gl.Vertex(tmp.x, tmp.y)

									tmp(c_weapon_getWeapons()[v.weapon].projectiletextureR[3])
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

			if v.weapon and v.reloading > 0 and (v.m.lastReload < v.reloading or not not v.m.lastShotgunReloading ~= not not v.shotgunReloadState) then
				local sound

				if c_weapon_getWeapons()[v.weapon] and c_weapon_getWeapons()[v.weapon].shotgunClips then
					if v.shotgunReloadState == 0 then
						sound = c_const_get("weaponAudio_dir") .. c_weapon_getWeapons()[v.weapon].reloadSound.initial
					elseif v.shotgunReloadState == 1 then
						sound = c_const_get("weaponAudio_dir") .. c_weapon_getWeapons()[v.weapon].reloadSound.clip
					elseif v.shotgunReloadState == 2 then
						sound = c_const_get("weaponAudio_dir") .. c_weapon_getWeapons()[v.weapon].reloadSound.final
					else
						-- silently ignore
						sound = ""
					end
				else
					if type(c_weapon_getWeapons()[v.weapon].reloadSound) == "table" then
						sound = c_const_get("weaponAudio_dir") .. c_weapon_getWeapons()[v.weapon].fireSound[math.random(1, #c_weapon_getWeapons()[v.weapon].reloadSound)]
					else
						sound = c_const_get("weaponAudio_dir") .. c_weapon_getWeapons()[v.weapon].reloadSound
					end
				end

				tankbobs.a_playSound(sound)
				tankbobs.a_setVolumeChunk(sound, game_audioDistance(v.p))
			end
			v.m.lastReload = v.reloading
			v.m.lastShotgunReloading = not not v.shotgunReloadState

			if v.m.lastCollideTime and v.m.lastCollideTimeB ~= v.m.lastCollideTime then
				v.m.lastCollideTimeB = v.m.lastCollideTime

				tankbobs.a_playSound(c_const_get("collide_sound"))
				tankbobs.a_setVolumeChunk(c_const_get("collide_sound"), v.m.intensity * c_config_get("client.volume") * game_audioDistance(v.p))
			end

			if v.m.lastDamageTime and v.m.lastDamageTimeB ~= v.m.lastDamageTime then
				v.m.lastDamageTimeB = v.m.lastDamageTime

				tankbobs.a_playSound(c_const_get("damage_sound"))
				tankbobs.a_setVolumeChunk(c_const_get("damage_sound"), game_audioDistance(v.p))
			end
		else
			v.m.lastCollideTime, v.m.lastDamageTime, v.m.lastReloadTime = nil
		end

		if v.spawning and v.m.lastDieTimeB ~= v.m.lastDieTime then
			v.m.lastDieTimeB = v.m.lastDieTime

			local switch = c_world_getGameType()
			if switch == PLAGUE then
				if not roundEnd or v.tagged then
					tankbobs.a_playSound(c_const_get("die_sound"))
					tankbobs.a_setVolumeChunk(c_const_get("die_sound"), game_audioDistance(v.p))
				end
			else
				tankbobs.a_playSound(c_const_get("die_sound"))
				tankbobs.a_setVolumeChunk(c_const_get("die_sound"), game_audioDistance(v.p))
			end
		end

		if v.m.lastPickupTime and v.m.lastPickupTimeB ~= v.m.lastPickupTime then
			v.m.lastPickupTimeB = v.m.lastPickupTime 

			tankbobs.a_playSound(c_const_get("powerupPickup_sound"))
			tankbobs.a_setVolumeChunk(c_const_get("powerupPickup_sound"), game_audioDistance(v.p))
		end

		if v.m.lastTeleportTime and v.m.lastTeleportTimeB ~= v.m.lastTeleportTime then
			v.m.lastTeleportTimeB = v.m.lastTeleportTime 

			local intensity = math.max(game_audioDistance(v.p), game_audioDistance(v.m.lastTeleportPosition))
			tankbobs.a_playSound(c_const_get("teleport_sound"))
			tankbobs.a_setVolumeChunk(c_const_get("teleport_sound"), intensity)
		end
	end

	for k, v in pairs(c_world_getTanks()) do
		if not (online and connection.t and k == connection.t) then
			tank(v)
		end
	end
	if online and connection.t and c_world_getTanks()[connection.t] then
		tank(c_world_getTanks()[connection.t])
	end

	for _, v in pairs(c_weapon_getWeapons()) do
		if v.meleeRange ~= 0 then
			if v.m.used then
				tankbobs.a_setVolumeChunk(c_const_get("weaponAudio_dir") .. v.fireSound, v.m.used)
			else
				tankbobs.a_setVolumeChunk(c_const_get("weaponAudio_dir") .. v.fireSound, 0)
			end
		end
	end

	for _, v in pairs(c_tcm_current_map.powerupSpawnPoints) do
		if v.m.lastSpawnTimeB ~= v.m.lastSpawnTime then
			v.m.lastSpawnTimeB = v.m.lastSpawnTime

			tankbobs.a_playSound(c_const_get("powerupSpawn_sound"))
			tankbobs.a_setVolumeChunk(c_const_get("powerupSpawn_sound"), game_audioDistance(v.p))
		end
	end

	for _, v in pairs(c_weapon_getProjectiles()) do
		local weapon = c_weapon_getWeapons()[v.weapon]

		if weapon and v.collisions > 0 and v.collisions ~= v.m.lastCollisions and weapon.trail == 0 and weapon.trailWidth == 0 then
			v.m.lastCollisions = v.collisions

			if weapon.projectileIsCollideSound then
				local sound = c_const_get("collideProjectile_sounds")[math.random(1, #c_const_get("collideProjectile_sounds"))]
				tankbobs.a_playSound(sound)
				tankbobs.a_setVolumeChunk(sound, game_audioDistance(v.p))
			end

			if weapon.projectileExplode then
				local sound = c_const_get("weaponAudio_dir") .. weapon.projectileExplodeSound
				tankbobs.a_playSound(sound)
				tankbobs.a_setVolumeChunk(sound, game_audioDistance(v.p))
			end
		end
	end

	-- game-type audio
	local switch = c_world_getGameType()
	if switch == MEGATANK then
		local changed = false
		for _, v in pairs(c_world_getTanks()) do
			if not changed then
				if v.megaTank ~= v.megaTankB then
					changed = v.megaTank

					tankbobs.a_playSound(c_const_get("newMegaTank_sound"))
				else
					break  -- megaTank should be set consistently across all tanks, so it shouldn't differ between two tanks, so break after the first test fails
				end
			end

			if changed then
				v.megaTankB = changed
			end
		end
	elseif switch == DOMINATION then
		for _, v in pairs(c_tcm_current_map.controlPoints) do
			if v.m.teamB ~= v.m.team then
				v.m.teamB = v.m.team

				tankbobs.a_playSound(c_const_get("control_sound"))
				tankbobs.a_setVolumeChunk(c_const_get("control_sound"), game_audioDistance(v.p))
			end
		end
	elseif switch == CAPTURETHEFLAG then
		for _, v in pairs(c_tcm_current_map.flags) do
			local tank = nil
			local function findTank()
				if not tank then
					for _, vs in pairs(c_world_getTanks()) do
						if vs.flag == v then
							tank = vs

							break
						end
					end
				end

				return tank or c_world_getTanks()[1]
			end
			if v.m.lastCaptureTime and v.m.lastCaptureTimeB ~= v.m.lastCaptureTime then
				v.m.lastCaptureTimeB = v.m.lastCaptureTime

				tankbobs.a_playSound(c_const_get("flagCapture_sound"))
				tankbobs.a_setVolumeChunk(c_const_get("flagCapture_sound"), game_audioDistance(v.p))
			end

			if v.m.lastPickupTime and v.m.lastPickupTimeB ~= v.m.lastPickupTime then
				v.m.lastPickupTimeB = v.m.lastPickupTime

				tankbobs.a_playSound(c_const_get("flagPickUp_sound"))
				tankbobs.a_setVolumeChunk(c_const_get("flagPickUp_sound"), game_audioDistance(findTank().p))
			end

			if v.m.lastReturnTime and v.m.lastReturnTimeB ~= v.m.lastReturnTime then
				v.m.lastReturnTimeB = v.m.lastReturnTime

				tankbobs.a_playSound(c_const_get("flagReturn_sound"))
				tankbobs.a_setVolumeChunk(c_const_get("flagReturn_sound"), game_audioDistance(v.m.pos or v.p))
			end
		end
	elseif switch == PLAGUE or
	       switch == SURVIVOR or
	       switch == TEAMSURVIVOR then
		if roundEnd then
			roundEnd = false

			tankbobs.a_playSound(c_const_get("endOfRound_sound"))
		end
	end
end
