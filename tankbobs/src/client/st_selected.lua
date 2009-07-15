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
st_selected.lua

Screen before playing
--]]

local st_selected_init
local st_selected_done
local st_selected_click
local st_selected_button
local st_selected_mouse
local st_selected_step

local st_selected_limit
local st_selected_start
local limit = nil
local limitInput = nil
local limitConfig = ""

function st_selected_init()
	gui_addAction(tankbobs.m_vec2(25, 92.5), "Back", nil, c_state_advance)

	local pos = 0
	local type = c_config_get("config.game.gameType")
		if type == "deathmatch" then
		pos = 1
		limitConfig = "config.game.fragLimit"
	elseif type == "domination" then
		pos = 2
		limitConfig = "config.game.pointLimit"
	elseif type == "capturetheflag" then
		pos = 3
		limitConfig = "config.game.captureLimit"
	end
	gui_addLabel(tankbobs.m_vec2(50, 75), "Game type", nil, 1 / 3) gui_addCycle(tankbobs.m_vec2(75, 75), "Instagib", nil, st_selected_gameType, {"Deathmatch", "Domination", "Capture the Flag"}, pos, 0.5)
	limit = gui_addLabel(tankbobs.m_vec2(50, 69), "Frag limit", nil, 1 / 3) limitInput = gui_addInput(tankbobs.m_vec2(75, 69), tostring(c_config_get(limitConfig)), nil, st_selected_limit, true, 4, 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 63), "Instagib", nil, 1 / 3) gui_addCycle(tankbobs.m_vec2(75, 63), "Instagib", nil, st_selected_instagib, {"No", "Yes"}, c_config_get("config.game.instagib") and 2 or 1, 0.5)
	gui_addAction(tankbobs.m_vec2(75, 54), "Start", nil, st_selected_start)
end

function st_selected_done()
	gui_finish()
end

function st_selected_click(button, pressed, x, y)
	gui_click(button, pressed, x, y)
end

function st_selected_button(button, pressed)
	if not gui_button(button, pressed) then
		if pressed then
			if button == 0x1B or button == c_config_get("config.key.quit") then
				c_state_advance()
			elseif button == c_config_get("config.key.exit") then
				c_state_new(exit_state)
			end
		end
	end
end

function st_selected_mouse(x, y, xrel, yrel)
	gui_mouse(x, y, xrel, yrel)
end

function st_selected_step(d)
	gui_paint(d)
end

function st_selected_limit(widget)
	c_config_set(limitConfig, tonumber(widget.inputText))
end

function st_selected_instagib(widget, string, index)
	if string == "Yes" then
		c_config_set("config.game.instagib", true)
	elseif string == "No" then
		c_config_set("config.game.instagib", false)
	end
end

function st_selected_gameType(widget, string, index)
	if index == 1 then
		limitConfig = "config.game.fragLimit"
		limitInput:setText(c_config_get(limitConfig))
		limit:setText "Frag Limit"

		c_config_set("config.game.gameType", "deathmatch")
	elseif index == 2 then
		limitConfig = "config.game.pointLimit"
		limitInput:setText(c_config_get(limitConfig))
		limit:setText "Point Limit"

		c_config_set("config.game.gameType", "domination")
	elseif index == 3 then
		limitConfig = "config.game.captureLimit"
		limitInput:setText(c_config_get(limitConfig))
		limit:setText "Capture Limit"

		c_config_set("config.game.gameType", "capturetheflag")
	end
end

function st_selected_start(widget)
	if c_config_get(limitConfig) > 0 then
		c_state_new(play_state)
	end
end

selected_state =
{
	name   = "selected_state",
	init   = st_selected_init,
	done   = st_selected_done,
	next   = function () return level_state end,

	click  = st_selected_click,
	button = st_selected_button,
	mouse  = st_selected_mouse,

	main   = st_selected_step
}
