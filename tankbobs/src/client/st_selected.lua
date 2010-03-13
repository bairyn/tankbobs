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
	local gameType = c_config_get("game.gameType")
		if gameType == "deathmatch" then
		pos = 1
		limitConfig = "game.fragLimit"
	elseif gameType == "chase" then
		pos = 2
		limitConfig = "game.chaseLimit"
	elseif gameType == "domination" then
		pos = 3
		limitConfig = "game.pointLimit"
	elseif gameType == "capturetheflag" then
		pos = 4
		limitConfig = "game.captureLimit"
	end
	local instagibPos = 0
	local switch = c_config_get("game.instagib")
	if switch == false then
		instagibPos = 1
	elseif switch == "semi" then
		instagibPos = 2
	else
		instagibPos = 3
	end
	local skillPos = 0
	local skill = c_config_get("game.allBotLevels")
	if type(skill) ~= "number" or skill <= 0 then
		skillPos = 0
	elseif skill == 1 then
		skillPos = 1
	elseif skill == 2 then
		skillPos = 2
	elseif skill == 4 then
		skillPos = 3
	elseif skill == 8 then
		skillPos = 4
	elseif skill == 16 then
		skillPos = 5
	end
	local skillLevels = {"Decent", "Medium", "Easy", "Very easy", "Ridiculously easy"}
	skillLevels[0] = "Automatic"
	gui_addLabel(tankbobs.m_vec2(50, 75), "Game type", nil, 1 / 3) gui_addCycle(tankbobs.m_vec2(75, 75), "Game type", nil, st_selected_gameType, {"Deathmatch", "Chase", "Domination", "Capture the Flag"}, pos, 0.5)
	limit = gui_addLabel(tankbobs.m_vec2(50, 69), "Frag limit", nil, 1 / 3) limitInput = gui_addInput(tankbobs.m_vec2(75, 69), tostring(c_config_get(limitConfig)), nil, st_selected_limit, true, 4, 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 63), "Instagib", nil, 1 / 3) gui_addCycle(tankbobs.m_vec2(75, 63), "Instagib", nil, st_selected_instagib, {"No", "Semi", "Yes"}, instagibPos, 0.5)
	if type(c_config_get("game.computers")) == "number" and c_config_get("game.computers") > 0 then
		gui_addLabel(tankbobs.m_vec2(50, 57), "Difficulty against bots", nil, 1 / 5) gui_addCycle(tankbobs.m_vec2(75, 57), "Difficulty against bots", nil, st_selected_skill, skillLevels, skillPos, 0.5)
	end
	gui_addAction(tankbobs.m_vec2(75, 48), "Start", nil, st_selected_start)
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
			if button == 0x1B or button == c_config_get("client.key.quit") then
				c_state_advance()
			elseif button == c_config_get("client.key.exit") then
				c_state_goto(exit_state)
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
	c_config_set(limitConfig, tonumber(widget.inputText) or 0)
end

function st_selected_instagib(widget, string, index)
	if string == "Yes" then
		c_config_set("game.instagib", true)
	elseif string == "Semi" then
		c_config_set("game.instagib", "semi")
	elseif string == "No" then
		c_config_set("game.instagib", false)
	end
end

function st_selected_gameType(widget, string, index)
	if index == 1 then
		limitConfig = "game.fragLimit"
		limitInput:setText(c_config_get(limitConfig))
		limit:setText "Frag Limit"

		c_config_set("game.gameType", "deathmatch")
	elseif index == 2 then
		limitConfig = "game.chaseLimit"
		limitInput:setText(c_config_get(limitConfig))
		limit:setText "Point Limit"

		c_config_set("game.gameType", "chase")
	elseif index == 3 then
		limitConfig = "game.pointLimit"
		limitInput:setText(c_config_get(limitConfig))
		limit:setText "Point Limit"

		c_config_set("game.gameType", "domination")
	elseif index == 4 then
		limitConfig = "game.captureLimit"
		limitInput:setText(c_config_get(limitConfig))
		limit:setText "Capture Limit"

		c_config_set("game.gameType", "capturetheflag")
	end

	c_world_setGameType(c_config_get("game.gameType"))
end

function st_selected_skill(widget, string, index)
	if     index == 0 then
		c_config_set("game.allBotLevels", "automatic")
	elseif index == 1 then
		c_config_set("game.allBotLevels", 1)
	elseif index == 2 then
		c_config_set("game.allBotLevels", 2)
	elseif index == 3 then
		c_config_set("game.allBotLevels", 4)
	elseif index == 4 then
		c_config_set("game.allBotLevels", 8)
	elseif index == 5 then
		c_config_set("game.allBotLevels", 16)
	end
end

function st_selected_start(widget)
	if c_config_get(limitConfig) > 0 then
		renderer_clear()
		c_state_goto(play_state)
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
