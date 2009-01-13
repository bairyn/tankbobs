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
st_options.lua

configuration screen
--]]

function st_options_init()
	options_video = config_backup("config.video")
	local fullscreen =
	{
		{"No",  st_options_fullscreen},
		{"Yes", st_options_fullscreen}
	}
	local resolution =
	{
		{"Custom", nil, nil, true},
		{"320x200", st_options_resolution},
		{"640x480", st_options_resolution},
		{"800x600", st_options_resolution},
		{"1024x768", st_options_resolution},
		{"1024x1024", st_options_resolution}
	}
	local function fullscreend()
		return config_get("config.video.fullscreen") == 0 and "No" or "Yes"
	end
	local function resolutiond()
		if config_get("config.video.width") == 320 and config_get("config.video.height") == 200 then
			return "320x200"
		elseif config_get("config.video.width") == 640 and config_get("config.video.height") == 480 then
			return "640x480"
		elseif config_get("config.video.width") == 800 and config_get("config.video.height") == 600 then
			return "800x600"
		elseif config_get("config.video.width") == 1024 and config_get("config.video.height") == 768 then
			return "1024x768"
		elseif config_get("config.video.width") == 1024 and config_get("config.video.height") == 1024 then
			return "1024x1024"
		else
			return "Custom"
		end
	end
	gui_widget("active", st_options_back, renderer_font.sans, 25, 75, renderer_size.sans, "Back")
	gui_widget("option", main_nil, renderer_font.sans, 50, 67.5, renderer_size.sans, "Fullscreen", fullscreen, fullscreend())
	gui_widget("option", main_nil, renderer_font.sans, 50, 65, renderer_size.sans, "Resolution", resolution, resolutiond())
	gui_widget("active", st_options_apply, renderer_font.sans, 50, 62.5, renderer_size.sans, "Apply")

	gui_widget("active", function () options_key = "config.key.quit" end, renderer_font.sans, 50, 57.5, renderer_size.sans, function () return "Quit   " .. gui_char(config_get("config.key.quit")) .. ((options_key == "config.key.quit") and ("-") or ("")) end)
	gui_widget("active", function () options_key = "config.key.exit" end, renderer_font.sans, 50, 55, renderer_size.sans, function () return "Exit   " .. gui_char(config_get("config.key.exit")) .. ((options_key == "config.key.exit") and ("-") or ("")) end)
end

function st_options_done()
	gui_finish()
end

function st_options_click(button, pressed, x, y)
	gui_click(x, y)
end

function st_options_button(button, pressed)
	if pressed == 0 and options_key then
		if button == 0x0D then
		elseif button == 0x1B then
			options_key = nil
		elseif button == 0x08 then
			config_set(options_key, "")
			options_key = nil
		else
			config_set(options_key, button)
			options_key = nil
		end
	elseif pressed == 1 and not options_key then
		if button == config_get("config.key.exit") then
			c_state_new(exit_state)
		elseif button == 0x1B or button == config_get("config.key.quit") then
			st_options_back()
		end
		gui_button(button)
	end
end

function st_options_mouse(x, y, xrel, yrel)
	gui_mouse(x, y)
end

function st_options_step()
	gui_paint()
end

function st_options_back()
	config_restore("config.video", options_video)
	options_video = nil
	c_state_advance()
end

function st_options_fullscreen(v)
	if v == "Yes" then
		config_set("config.video.fullscreen", 1)
	elseif v == "No" then
		config_set("config.video.fullscreen", 0)
	end
end

function st_options_resolution(v)
	if v == "320x200" then
		config_set("config.video.width", 320)
		config_set("config.video.height", 200)
	elseif v == "640x480" then
		config_set("config.video.width", 640)
		config_set("config.video.height", 480)
	elseif v == "800x600" then
		config_set("config.video.width", 800)
		config_set("config.video.height", 600)
	elseif v == "1024x768" then
		config_set("config.video.width", 1024)
		config_set("config.video.height", 768)
	elseif v == "1024x1024" then
		config_set("config.video.width", 1024)
		config_set("config.video.height", 1024)
	end
end

function st_options_apply()
	options_video = config_backup("config.video")
	renderer_updateWindow()  -- in case SDL forgets to send a resize signal
	tankbobs.newvideo(config_get("config.video.width"), config_get("config.video.height"), not not (config_get("config.video.fullscreen") and config_get("config.video.fullscreen") > 0), const_get("title"), const_get("icon"))
end

options_state =
{
	name   = "options_state",
	init   = st_options_init,
	done   = st_options_done,
	next   = function () return title_state end,

	click  = st_options_click,
	button = st_options_button,
	mouse  = st_options_mouse,

	main   = st_options_step
}
