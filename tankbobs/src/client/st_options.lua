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
	st_options_renderer = {fullscreen = c_config_get("config.renderer.fullscreen"), width = c_config_get("config.renderer.width"), height = c_config_get("config.renderer.height")}
	st_options_player = {}

	gui_action("Back", tankbobs.m_vec2(25, 75), nil, c_state_advance)

	gui_label("Fullscreen", tankbobs.m_vec2(50, 65), nil, 0.5) gui_cycle("Fullscreen", tankbobs.m_vec2(75, 65), nil, st_options_fullscreen, {"No", "Yes"}, c_config_get("config.renderer.fullscreen") and 2 or 1, 0.75)
	gui_label("Width", tankbobs.m_vec2(50, 60), nil, 0.5) gui_input(tostring(c_config_get("config.renderer.width")), tankbobs.m_vec2(75, 60), nil, st_options_width, true, 4, 0.75)
	gui_label("Height", tankbobs.m_vec2(50, 55), nil, 0.5) gui_input(tostring(c_config_get("config.renderer.height")), tankbobs.m_vec2(75, 55), nil, st_options_height, true, 4, 0.75)
	gui_action("Apply", tankbobs.m_vec2(50, 50), nil, st_options_apply, 0.75)

	gui_label("Players", tankbobs.m_vec2(50, 40), nil, 0.5) gui_input(tostring(tonumber(c_config_get("config.game.players"))), tankbobs.m_vec2(75, 40), nil, st_options_players, true, 2, 0.75)

	gui_label("Set up player", tankbobs.m_vec2(50, 35), nil, 0.5) gui_input("1", tankbobs.m_vec2(75, 35), nil, st_options_configurePlayer, true, 2, 0.75)

	if not (c_config_get("config.game.player1.name", nil, true)) then
		c_config_set("config.game.player1.name", "Player1")
	end
	gui_label("Name", tankbobs.m_vec2(50, 30), nil, 0.5) st_options_player.name = gui_input(c_config_get("config.game.player1.name"), tankbobs.m_vec2(75, 30), nil, st_options_name, false, c_const_get("max_nameLength"), 0.75)


	--[[
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
		return c_config_get("config.renderer.fullscreen") == 0 and "No" or "Yes"
	end
	local function resolutiond()
		if c_config_get("config.renderer.width") == 320 and c_config_get("config.renderer.height") == 200 then
			return "320x200"
		elseif c_config_get("config.renderer.width") == 640 and c_config_get("config.renderer.height") == 480 then
			return "640x480"
		elseif c_config_get("config.renderer.width") == 800 and c_config_get("config.renderer.height") == 600 then
			return "800x600"
		elseif c_config_get("config.renderer.width") == 1024 and c_config_get("config.renderer.height") == 768 then
			return "1024x768"
		elseif c_config_get("config.renderer.width") == 1024 and c_config_get("config.renderer.height") == 1024 then
			return "1024x1024"
		else
			return "Custom"
		end
	end
	gui_widget("active", st_options_back, renderer_font.sans, 25, 75, renderer_size.sans, "Back")
	gui_widget("option", common_nil, renderer_font.sans, 50, 67.5, renderer_size.sans, "Fullscreen", fullscreen, fullscreend())
	gui_widget("option", common_nil, renderer_font.sans, 50, 65, renderer_size.sans, "Resolution", resolution, resolutiond())
	gui_widget("active", st_options_apply, renderer_font.sans, 50, 62.5, renderer_size.sans, "Apply")

	gui_widget("active", function () options_key = "config.key.quit" end, renderer_font.sans, 50, 57.5, renderer_size.sans, function () return "Quit   " .. gui_char(c_config_get("config.key.quit")) .. ((options_key == "config.key.quit") and ("-") or ("")) end)
	gui_widget("active", function () options_key = "config.key.exit" end, renderer_font.sans, 50, 55, renderer_size.sans, function () return "Exit   " .. gui_char(c_config_get("config.key.exit")) .. ((options_key == "config.key.exit") and ("-") or ("")) end)
	--]]
end

function st_options_done()
	gui_finish()

	st_options_renderer = nil
	st_options_player = nil
end

local currentPlayer = 1

function st_options_click(button, pressed, x, y)
	if pressed then
		gui_click(x, y)
	end
end

function st_options_button(button, pressed)
	if not pressed and options_key then
		if button == 0x0D then
		elseif button == 0x1B then
			options_key = nil
		elseif button == 0x08 then
			c_config_set(options_key, "")
			options_key = nil
		else
			c_config_set(options_key, button)
			options_key = nil
		end
	elseif pressed and not options_key then
		if button == c_config_get("config.key.exit") then
			c_state_new(exit_state)
		elseif button == 0x1B or button == c_config_get("config.key.quit") then
			c_state_advance()
		end
		gui_button(button)
	end
end

function st_options_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

function st_options_step(d)
	gui_paint(d)
end

function st_options_apply(widget)
	c_config_set("config.renderer.fullscreen", st_options_renderer.fullscreen)
	c_config_set("config.renderer.width", st_options_renderer.width)
	c_config_set("config.renderer.height", st_options_renderer.height)
	renderer_updateWindow()  -- in case SDL forgets to send a resize signal
	tankbobs.r_newWindow(c_config_get("config.renderer.width"), c_config_get("config.renderer.height"), c_config_get("config.renderer.fullscreen"), c_const_get("title"), c_const_get("icon"))
end

function st_options_fullscreen(widget, option, key)
	if option == "Yes" then
		st_options_renderer.fullscreen = true
	elseif option == "No" then
		st_options_renderer.fullscreen = false
	end
end

function st_options_width(widget)
	st_options_renderer.width = tonumber(widget.text)
end

function st_options_height(widget)
	st_options_renderer.height = tonumber(widget.text)
end

function st_options_players(widget)
	c_config_set("config.game.players", tonumber(widget.text))
end

function st_options_configurePlayer(widget)
	currentPlayer = tonumber(widget.text) or 1

	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".name", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".name", "Player" .. tonumber(currentPlayer))
	end
	local name = c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".name")
	st_options_player.name:setText(#name <= widget.maxLength and name or "Player" .. tonumber(currentPlayer))
end

function st_options_name(widget)
	if not (c_config_get("config.game.player" .. tonumber(currentPlayer) .. ".name", nil, true)) then
		c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".name", "Player" .. tonumber(currentPlayer))
	end

	c_config_set("config.game.player" .. tonumber(currentPlayer) .. ".name", tostring(widget.text))
end

function st_options_fullscreen(v)
	if v == "Yes" then
		c_config_set("config.renderer.fullscreen", 1)
	elseif v == "No" then
		c_config_set("config.renderer.fullscreen", 0)
	end
end

function st_options_resolution(v)
	if v == "320x200" then
		c_config_set("config.renderer.width", 320)
		c_config_set("config.renderer.height", 200)
	elseif v == "640x480" then
		c_config_set("config.renderer.width", 640)
		c_config_set("config.renderer.height", 480)
	elseif v == "800x600" then
		c_config_set("config.renderer.width", 800)
		c_config_set("config.renderer.height", 600)
	elseif v == "1024x768" then
		c_config_set("config.renderer.width", 1024)
		c_config_set("config.renderer.height", 768)
	elseif v == "1024x1024" then
		c_config_set("config.renderer.width", 1024)
		c_config_set("config.renderer.height", 1024)
	end
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
