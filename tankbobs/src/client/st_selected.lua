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
local st_selected_gameType
local st_selected_instagib
local st_selected_spawn
local st_selected_punish
local st_selected_skill
local st_selected_players
local st_selected_computers
local limit = nil
local limitInput = nil
local limitConfig = ""

function st_selected_init()
	gui_addAction(tankbobs.m_vec2(25, 92.5), "Back", nil, c_state_advance)

	local pos = 0
	local gameType = c_world_gameTypeConstant(c_config_get("game.gameType"))
	for k, v in pairs(c_world_getGameTypes()) do
		if gameType == v[1] then
			pos = k

			break
		end
	end

	limitConfig = c_world_gameTypePointLimit(gameType)

	local instagibPos = 0
	local switch = c_config_get("game.instagib")
	if switch == false then
		instagibPos = 1
	elseif switch == "semi" then
		instagibPos = 2
	else
		instagibPos = 3
	end

	local spawnPos = 0
	local switch = c_config_get("game.spawnStyle")
	if switch == BLOCKABLE then
		spawnPos = 1
	elseif switch == ALTERNATING then
		spawnPos = 2
	end

	local punishPos = 0
	local switch = c_config_get("game.punish")
	if switch == true then
		punishPos = 1
	else
		punishPos = 2
	end

	local skillLevels = {"Automatic", "Decent", "Medium", "Easy", "Very easy", "Ridiculously easy"}
	local skillPos = 0
	local skill = c_config_get("game.allBotLevels")
	if type(skill) ~= "number" or skill <= 0 then
		skillPos = 1
	elseif skill == 1 then
		skillPos = 2
	elseif skill == 2 then
		skillPos = 3
	elseif skill == 4 then
		skillPos = 4
	elseif skill == 8 then
		skillPos = 5
	elseif skill == 16 then
		skillPos = 6
	else
		skillPos = 0
	end

	local strings = {}
	for k, v in pairs(c_world_getGameTypes()) do
		strings[k] = c_world_gameTypeHumanString(v[1])
	end

	skillLevels[0] = "Custom"
	gui_addLabel(tankbobs.m_vec2(50, 75), "Game mode", nil, 1 / 3) gui_addCycle(tankbobs.m_vec2(75, 75), "Game mode", nil, st_selected_gameType, strings, pos, 0.5)
	limit = gui_addLabel(tankbobs.m_vec2(50, 69), c_world_gameTypePointLimitLabel(gameType), nil, 1 / 3) limitInput = gui_addInput(tankbobs.m_vec2(75, 69), tostring(c_config_get(limitConfig)), nil, st_selected_limit, true, 4, 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 63), "Instagib", nil, 1 / 3) gui_addCycle(tankbobs.m_vec2(75, 63), "Instagib", nil, st_selected_instagib, {"No", "Semi", "Yes"}, instagibPos, 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 57), "Spawn mode", nil, 1 / 3) gui_addCycle(tankbobs.m_vec2(75, 57), "Spawn style", nil, st_selected_spawn, {"Blockable", "Alternating"}, spawnPos, 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 51), "Punish teamkills and suicides", nil, 1 / 5) gui_addCycle(tankbobs.m_vec2(75, 51), "Punish teamkills and suicides", nil, st_selected_punish, {"Yes", "No"}, punishPos, 0.5)

	gui_addLabel(tankbobs.m_vec2(50, 45), "Players", nil, 1 / 3) gui_addInput(tankbobs.m_vec2(75, 45), tostring(tonumber(c_config_get("game.players"))), nil, st_selected_players, true, 1, 0.5)
	gui_addLabel(tankbobs.m_vec2(50, 39), "Computers", nil, 1 / 3) gui_addInput(tankbobs.m_vec2(75, 39), tostring(tonumber(c_config_get("game.computers"))), nil, st_selected_computers, true, 1, 0.5)

	--if type(c_config_get("game.computers")) == "number" and c_config_get("game.computers") > 0 then
	gui_addLabel(tankbobs.m_vec2(50, 33), "Computer skill", nil, 1 / 5) gui_addCycle(tankbobs.m_vec2(75, 33), "Difficulty against bots", nil, st_selected_skill, skillLevels, skillPos, 0.5)
	--end

	gui_addAction(tankbobs.m_vec2(75, 24), "Start", nil, st_selected_start)
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
	local setting = false
	if string == "Yes" then
		setting = true
	elseif string == "Semi" then
		setting = "semi"
	elseif string == "No" then
		setting = false
	end
	c_config_set("game.instagib", setting)
	c_world_setInstagib(setting)
end

function st_selected_spawn(widget, string, index)
	local setting = false
	if string == "Blockable" then
		setting = BLOCKABLE
	elseif string == "Alternating" then
		setting = ALTERNATING
	end
	c_config_set("game.spawnStyle", setting)
end

function st_selected_punish(widget, string, index)
	local setting = true
	if string == "Yes" then
		setting = true
	elseif string == "No" then
		setting = false
	end
	c_config_set("game.punish", setting)
end

function st_selected_gameType(widget, string, index)
	local gameType = c_world_gameTypeConstant(string)
	limitConfig = c_world_gameTypePointLimit(string)
	limitInput:setText(c_config_get(limitConfig))
	limit:setText(c_world_gameTypePointLimitLabel(gameType))
	c_config_set("game.gameType", c_world_gameTypeString(gameType))
	c_world_setGameType(c_config_get("game.gameType"))
end

function st_selected_skill(widget, string, index)
	if     index == 1 then
		c_config_set("game.allBotLevels", "automatic")
	elseif index == 2 then
		c_config_set("game.allBotLevels", 1)
	elseif index == 3 then
		c_config_set("game.allBotLevels", 2)
	elseif index == 4 then
		c_config_set("game.allBotLevels", 4)
	elseif index == 5 then
		c_config_set("game.allBotLevels", 8)
	elseif index == 6 then
		c_config_set("game.allBotLevels", 16)
	end
end

function st_selected_players(widget)
	c_config_set("game.players", tonumber(widget.inputText))
end

function st_selected_computers(widget)
	c_config_set("game.computers", tonumber(widget.inputText))
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
