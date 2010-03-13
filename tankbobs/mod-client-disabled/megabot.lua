local isMegaBot = true
local function prependFrame()
    if isMegaBot then
		local lastSwitchTime = tankbobs.t_getTicks()
	    local weapons = {"rocket-launcher", "coilgun", "railgun", "machinegun", "rocket-launcher", "shotgun", "laser-gun", "rocket-launcher", "plasma-gun", "saw", "rocket-launcher"}
		local switchTime = c_world_timeMultiplier(30)

		local pos = 1
		local function frame(d)
			for _, v in pairs(c_world_getTanks()) do
				if v.bot then
					if v.exists then
						if not v.m.noResetMega then
							v.m.noResetMega = true
							v.shield = 8 * c_const_get("tank_boostShield")
							v.health = 2500
						end
						local t = tankbobs.t_getTicks()
						if t - lastSwitchTime >= switchTime then
							lastSwitchTime = t
							pos = pos + 1
							if not weapons[pos] then
								pos = 1
							end
						end
						local weapon = c_weapon_getByName(weapons[pos])
						if v.weapon ~= weapon.index then
							c_weapon_pickUp(v, weapons[pos])
						end
						v.ammo = weapon.capacity
						v.clips = 1
						v.ai.skill = 1
						v.name = "[BOT] Megabot!"
					else
						v.m.noResetMega = false
					end
				end
			end
		end

		isMegaBot = false
	    c_mods_prependFunction("c_world_step", frame)
	end
end
local function addMega()
	local pos = 0
	local switch = isMegaBot
	if switch == false then
		pos = 1
	else
		pos = 2
	end

	local function st_selected_mega(widget)
		if c_config_get(limitConfig) > 0 then
			renderer_clear()
			c_state_goto(play_state)
		end
	end

	local function st_selected_mega(widget, string, index)
		if string == "Yes" then
			isMegaBot = true
		elseif string == "No" then
			isMegaBot = false
		end
	end
	gui_addLabel(tankbobs.m_vec2(50, 30), "Megabot", nil, 1 / 3) gui_addCycle(tankbobs.m_vec2(75, 30), "Megabot", nil, st_selected_mega, {"No", "Yes"}, pos, 0.5)
end
local oldSelectedInit = selected_state.init
selected_state.init = function(...)
	oldSelectedInit(...)
	addMega(...)
end
-- copy main_loop except call prependFrame
local lastTime = 0
local function main_loop()
	local t = tankbobs.t_getTicks()
	local main_stt = main_stt

	if lastTime == 0 then
		lastTime = tankbobs.t_getTicks()
		return
	end

	if tankbobs.t_getTicks() - lastTime < c_const_get("world_timeWrapTest") then
		--handle time wrap here
		stdout:write("Time wrapped\n")
		lastTime = tankbobs.t_getTicks()
		c_world_timeWrapped()
		return
	end

	if c_config_get("client.fps") < c_const_get("client_minFPS") and c_config_get("client.fps") ~= 0 then
		c_config_set("client.fps", c_const_get("client_minFPS"))
	end

	if c_config_get("client.fps") > 0 and t - lastTime < common_FTM(c_config_get("client.fps")) then
		tankbobs.t_delay(common_FTM(c_config_get("client.fps")) - t + lastTime)
		return
	end

	fps = common_MTF(t - lastTime)

	local d = (t - lastTime) / c_world_timeMultiplier()
	lastTime = t

	if d == 0 then
		d = 1.0E-6  -- make an inaccurate guess
	end

	local results, eventqueue = tankbobs.in_getEvents()
	if results ~= nil then
		local lastevent = eventqueue
		repeat
			if tankbobs.in_getEventData(lastevent, "type") == "quit" then
				done = true
			elseif tankbobs.in_getEventData(lastevent, "type") == "video" then
				c_config_set("client.renderer.width", tankbobs.in_getEventData(lastevent, "intData0"))
				c_config_set("client.renderer.height", tankbobs.in_getEventData(lastevent, "intData1"))
				renderer_updateWindow()
			elseif tankbobs.in_getEventData(lastevent, "type") == "video_focus" then
				video_updateWindow()
			elseif tankbobs.in_getEventData(lastevent, "type") == "mousedown" then
				local x, y = tankbobs.in_getEventData(lastevent, "intData1"), tankbobs.in_getEventData(lastevent, "intData2")

				x, y = main_stt(x, y)
				if tankbobs.in_getEventData(lastevent, "intData0") >= 1 and tankbobs.in_getEventData(lastevent, "intData0") <= 5 then
					c_state_click(tankbobs.in_getEventData(lastevent, "intData0"), true, x, y)
				else
					c_state_click(tankbobs.in_getEventData(lastevent, "intData3"), true, x, y)
				end
			elseif tankbobs.in_getEventData(lastevent, "type") == "mouseup" then
				local x, y = tankbobs.in_getEventData(lastevent, "intData1"), tankbobs.in_getEventData(lastevent, "intData2")

				x, y = main_stt(x, y)
				if tankbobs.in_getEventData(lastevent, "intData0") >= 1 and tankbobs.in_getEventData(lastevent, "intData0") <= 5 then
					c_state_click(tankbobs.in_getEventData(lastevent, "intData0"), false, x, y)
				else
					c_state_click(tankbobs.in_getEventData(lastevent, "intData3"), false, x, y)
				end
			elseif tankbobs.in_getEventData(lastevent, "type") == "keydown" then
				c_state_button(tankbobs.in_getEventData(lastevent, "intData0"), true)
			elseif tankbobs.in_getEventData(lastevent, "type") == "keyup" then
				c_state_button(tankbobs.in_getEventData(lastevent, "intData0"), false)
			elseif tankbobs.in_getEventData(lastevent, "type") == "mousemove" then
				local x, y, xrel, yrel = tankbobs.in_getEventData(lastevent, "intData0"), tankbobs.in_getEventData(lastevent, "intData1"), tankbobs.in_getEventData(lastevent, "intData2"), tankbobs.in_getEventData(lastevent, "intData3")

				yrel = -yrel
				x, y = main_stt(x, y)
				c_state_mouse(x, y, xrel, yrel)
			end
			lastevent = tankbobs.in_nextEvent(lastevent)
		until not lastevent
		tankbobs.in_freeEvents(eventqueue)
	end
	renderer_start()
	c_state_step(d)
	renderer_end()

	if not backgroundState then
		prependFrame()
	end
end
local function start()
	c_state_goto(title_state)

	while not done do
		main_loop()
	end
end
c_mods_replaceFunction("main_start", start)
--c_mods_prependFunction("c_world_step", prependFrame)  -- c_world_step somehow resets
