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
main.lua

startup and the like
--]]

local c_const_get  = c_const_get
local c_const_set  = c_const_set
local c_state_step = c_state_step
local c_config_get = c_config_get
local c_config_set = c_config_set
local common_FTM   = common_FTM
local common_MTF   = common_MTF
local tankbobs     = tankbobs

local main_loop

function main_init()
	c_const_get  = _G.c_const_get
	c_const_set  = _G.c_const_set
	c_state_step = _G.c_state_step
	c_config_get = _G.c_config_get
	c_config_set = _G.c_config_set
	common_FTM   = _G.common_FTM
	common_MTF   = _G.common_MTF
	tankbobs     = _G.tankbobs

	--execution begins here; args are stored in table 'args'; ./tankbobs will generate {"./tankbobs"}
	main_data = {}

	if main_parseArgs(args) then
		return
	end

	args = nil  -- protect against bad code

	tankbobs.a_init()
	tankbobs.a_setVolume(c_config_get("config.client.volume"))
	tankbobs.a_setMusicVolume(c_config_get("config.client.musicVolume"))

	tankbobs.r_newWindow(c_config_get("config.renderer.width"), c_config_get("config.renderer.height"), c_config_get("config.renderer.fullscreen"), c_const_get("title"), c_const_get("icon"))
	renderer_setupNewWindow()

	renderer_init()
	gui_init()

	c_state_new(title_state)

	while not done do
		main_loop()
	end
end

function main_done()
	tankbobs.a_quit()
	gui_done()
	renderer_done()
end

function main_stt(x, y)
	-- convert SDL coordinates to tankbobs coordinates and return
	y = c_config_get("config.renderer.height") - y
	x = (100 * x) / c_config_get("config.renderer.width")
	y = (100 * y) / c_config_get("config.renderer.height")

	return x, y
end

function main_tts(x, y)
	-- convert tankbobs coordinates to SDL coordinates and return
	y = y / (100 * c_config_get("config.renderer.height"))
	x = x / (100 * c_config_get("config.renderer.width"))
	y = c_config_get("config.renderer.height") - y

	return x, y
end

local lastTime = 0

function main_loop()
	local t = tankbobs.t_getTicks()
	local main_stt = main_stt

	if lastTime == 0 then
		lastTime = tankbobs.t_getTicks()
		return
	end

	if tankbobs.t_getTicks() - lastTime < c_const_get("world_timeWrapTest") then
		--handle time wrap here
		io.stdout:write("Time wrapped\n")
		lastTime = tankbobs.t_getTicks()
		c_world_timeWrapped()
		return
	end

	if c_config_get("config.client.fps") < c_const_get("client_minFPS") and c_config_get("config.client.fps") ~= 0 then
		c_config_set("config.client.fps", c_const_get("client_minFPS"))
	end

	if c_config_get("config.client.fps") > 0 and t - lastTime < common_FTM(c_config_get("config.client.fps")) then
		tankbobs.t_delay(common_FTM(c_config_get("config.client.fps")) - t + lastTime)
		return
	end

	fps = common_MTF(t - lastTime)

	local d = (t - lastTime) / (c_const_get("world_time") * c_config_get("config.game.timescale"))
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
				config_set("config.renderer.width", tankbobs.in_getEventData(lastevent, "intData0"))
				config_set("config.renderer.height", tankbobs.in_getEventData(lastevent, "intData1"))
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
end

function main_parseArgs(args)
	local function main_usage()
		io.stdout:write("Usage\n\n-h: print this help message\n-d: use default configuration (old configuration may be lost)/rc.xml\n-c x y: set config x to y\n")
		return true
	end

	local function parse(i)
		local c_config_set = c_config_set
		do
			local c_oldConfig_set = c_config_set
			c_config_set = function(k, v)
				if type(k) == "string" and not k:find("^config%.") then
					return c_oldConfig_set("config." .. k, v)
				else
					return c_oldConfig_set(k, v)
				end
			end
		end

		if args[i] == nil then
			return nil
		end

		local res = c_mods_preArgParse(args[i], args, i)
		if res then
			if type(res) == "number" then
				return parse(res)
			else
				return res
			end
		elseif string.find(args[i], "^-h") then
			return main_usage()
		elseif string.find(args[i], "^-d") then
			c_config_defaults()
		elseif string.find(args[i], "^-c") then
			if string.find(args[i], "^[\n\t ]*-c[\n\t ]*$") then
				if args[i + 1] and string.find(args[i + 1], "[\n\t ]+") then
					config_set(string.sub(args[i + 1], 1, (string.find(args[i + 1], "[\n\t ]+")) - 1), string.sub(args[i + 1], select(2, string.find(args[i + 1], "[\n\t ]+") + 1, -1)))
					return parse(i + 2)
				elseif args[i + 2] then
					c_config_set(args[i + 1], args[i + 2])
					return parse(i + 3)
				end
			else
				if string.find(args[i], "[\n\t ]+", select(2, string.find(args[i], "^[\n\t ]*-c[\n\t ]*")) + 1) then
					config_set(string.sub(args[i], select(2, string.find(args[i], "^[\n\t ]*-c[\n\t ]*")) + 1, string.find(args[i], "[\n\t ]+", select(2, string.find(args[i], "^[\n\t ]*-c[\n\t ]*")) + 1) - 1), string.sub(args[i], select(2, string.find(args[i], "[\n\t ]+", select(2, string.find(args[i], "^[\n\t ]*-c[\n\t ]*")) + 1)) + 1, -1))
					return parse(i + 1)
				elseif args[i + 1] then
					c_config_set(string.sub(args[i], select(2, string.find(args[i], "^[\n\t ]*-c[\n\t ]*")) + 1, -1), args[i + 1])
					return parse(i + 2)
				end
			end
		elseif string.find(args[i], "^-C") then
			c_config_cheats_set(true)
		elseif string.find(args[i], "^-n") then
			c_config_cheats_set(false)
		else
			local res = c_mods_argParse(args[i], args, i)
			if res then
				if type(res) == "number" then
					return parse(res)
				else
					return res
				end
			end
		end

		return parse(i + 1)
	end

	return parse(1)
end

function b_mods()
	c_const_get  = _G.c_const_get
	c_const_set  = _G.c_const_set
	c_state_step = _G.c_state_step
	c_config_get = _G.c_config_get
	c_config_set = _G.c_config_set
	common_FTM   = _G.common_FTM
	common_MTF   = _G.common_MTF
	tankbobs     = _G.tankbobs

	c_mods_load(c_const_get("client-mods_dir"))
end
