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
gui.lua

Graphical User Interface
--]]

function gui_init()
	gui_widgets = {labels = {}, actions = {}, cycles = {}, inputs = {}, selection = 1, selectionType = {}}

	c_const_set("widget_length", 16, 1)

	c_const_set("label_prefix", "", 1)
	c_const_set("label_suffix", "", 1)
	c_const_set("label_r", 0.8, 1)
	c_const_set("label_g", 0.5, 1)
	c_const_set("label_b", 0.1, 1)
	c_const_set("label_a", 1.0, 1)
	c_const_set("label_scalex", 1 / 8, 1)
	c_const_set("label_scaley", 1 / 8, 1)

	c_const_set("action_prefix", "", 1)
	c_const_set("action_suffix", "", 1)
	c_const_set("action_r", 0.92, 1)
	c_const_set("action_g", 0.94, 1)
	c_const_set("action_b", 0.98, 1)
	c_const_set("action_a", 1.0, 1)
	c_const_set("action_scalex", 1 / 12, 1)
	c_const_set("action_scaley", 1 / 12, 1)
	c_const_set("actionSelected_r", 0.6, 1)
	c_const_set("actionSelected_g", 0.4, 1)
	c_const_set("actionSelected_b", 0.2, 1)
	c_const_set("actionSelected_a", 1.0, 1)

	c_const_set("cycle_prefix", "[", 1)
	c_const_set("cycle_suffix", "]", 1)
	c_const_set("cycle_r", 0.92, 1)
	c_const_set("cycle_g", 0.94, 1)
	c_const_set("cycle_b", 0.98, 1)
	c_const_set("cycle_a", 1.0, 1)
	c_const_set("cycle_scalex", 1 / 12, 1)
	c_const_set("cycle_scaley", 1 / 12, 1)
	c_const_set("cycleSelected_r", 0.2, 1)
	c_const_set("cycleSelected_g", 0.6, 1)
	c_const_set("cycleSelected_b", 0.4, 1)
	c_const_set("cycleSelected_a", 1.0, 1)

	c_const_set("input_prefix", ": ", 1)
	c_const_set("input_suffix", "", 1)
	c_const_set("input_r", 0.92, 1)
	c_const_set("input_g", 0.94, 1)
	c_const_set("input_b", 0.98, 1)
	c_const_set("input_a", 1.0, 1)
	c_const_set("input_scalex", 1 / 12, 1)
	c_const_set("input_scaley", 1 / 12, 1)
	c_const_set("inputSelected_r", 0.6, 1)
	c_const_set("inputSelected_g", 0.4, 1)
	c_const_set("inputSelected_b", 0.2, 1)
	c_const_set("inputSelected_a", 1.0, 1)
	c_const_set("input_posCharacter", "|", 1)

	c_const_set("select_init", 0.25, 1)
	c_const_set("select_drop", 1.0, 1)
end

function gui_done()
	gui_widgets = nil
end

gui_widget =
{
	new = common_new,

	init = function (o)
		o.p = tankbobs.m_vec2()
		o.scale = 1
	end,

	p = nil,
	text = "",
	updateText = nil,
	scale = 0,
	color = {},
	altColor = {},

	bump = nil
}

gui_wlabel =
{
	new = common_new,

	init = function (o)
		o.p = tankbobs.m_vec2()
		o.scale = 1
		o.color.r = c_const_get("label_r") o.altColor.r = c_const_get("label_r")
		o.color.g = c_const_get("label_g") o.altColor.g = c_const_get("label_g")
		o.color.b = c_const_get("label_b") o.altColor.b = c_const_get("label_b")
		o.color.a = c_const_get("label_a") o.altColor.a = c_const_get("label_a")
	end
}

gui_waction =
{
	new = common_new,

	init = function (o)
		o.p = tankbobs.m_vec2()
		o.r = tankbobs.m_vec2()
		o.scale = 1
		o.color.r = c_const_get("action_r") o.altColor.r = c_const_get("actionSelected_r")
		o.color.g = c_const_get("action_g") o.altColor.g = c_const_get("actionSelected_g")
		o.color.b = c_const_get("action_b") o.altColor.b = c_const_get("actionSelected_b")
		o.color.a = c_const_get("action_a") o.altColor.a = c_const_get("actionSelected_a")
	end,

	actionCallback = nil,
	r = nil  -- position of upper-right coordinates
}

gui_wcycle =
{
	new = common_new,

	init = function (o)
		o.p = tankbobs.m_vec2()
		o.r = tankbobs.m_vec2()
		o.scale = 1
		o.color.r = c_const_get("cycle_r") o.altColor.r = c_const_get("cycleSelected_r")
		o.color.g = c_const_get("cycle_g") o.altColor.g = c_const_get("cycleSelected_g")
		o.color.b = c_const_get("cycle_b") o.altColor.b = c_const_get("cycleSelected_b")
		o.color.a = c_const_get("cycle_a") o.altColor.a = c_const_get("cycleSelected_a")
	end,

	r = nil,
	cycleCallBack = nil,
	list = {},
	integerOnly = false,
	current = 0
}

gui_winput =
{
	new = common_new,

	init = function (o)
		o.p = tankbobs.m_vec2()
		o.r = tankbobs.m_vec2()
		o.scale = 1
		o.color.r = c_const_get("input_r") o.altColor.r = c_const_get("inputSelected_r")
		o.color.g = c_const_get("input_g") o.altColor.g = c_const_get("inputSelected_g")
		o.color.b = c_const_get("input_b") o.altColor.b = c_const_get("inputSelected_b")
		o.color.a = c_const_get("input_a") o.altColor.a = c_const_get("inputSelected_a")
	end,

	setText = function (self, text)
		text = tostring(text)
		if #text >= 1 then
			text = text:sub(1, self.maxLength)
			self.text = text
			self.pos = #text
		end
	end,

	r = nil,
	changeCallBack = nil,
	maxLength = 0,
	pos = 0
}

local length = 0
local selected = nil

function gui_finish()
	length = 0
	selected = nil
	gui_widgets = {labels = {}, actions = {}, cycles = {}, inputs = {}, selection = 1, selectionType = {}}
end

function gui_label(text, p, updateTextCallBack, scale, color_r, color_g, color_b, color_a, altColor_r, altColor_g, altColor_b, altColor_a)
	local label = gui_wlabel:new(gui_widget)

	label.p(p)
	label.text = text
	label.updateTextCallBack = updateTextCallBack
	label.scale = scale or 1
	label.color.r = color_r or label.color.r label.altColor.r = altColor_r or label.altColor.r
	label.color.g = color_g or label.color.g label.altColor.g = altColor_g or label.altColor.g
	label.color.b = color_b or label.color.b label.altColor.b = altColor_b or label.altColor.b
	label.color.a = color_a or label.color.a label.altColor.a = altColor_a or label.altColor.a

	table.insert(gui_widgets.labels, label)

	return label
end

function gui_action(text, p, updateTextCallBack, actionCallBack, scale, color_r, color_g, color_b, color_a, altColor_r, altColor_g, altColor_b, altColor_a)
	local action = gui_waction:new(gui_widget)

	action.p(p)
	action.r(p)  -- make sure r is initialized before it is added
	action.text = text
	action.updateTextCallBack = updateTextCallBack
	action.actionCallBack = actionCallBack
	action.scale = scale or 1
	action.color.r = color_r or action.color.r action.altColor.r = altColor_r or action.altColor.r
	action.color.g = color_g or action.color.g action.altColor.g = altColor_g or action.altColor.g
	action.color.b = color_b or action.color.b action.altColor.b = altColor_b or action.altColor.b
	action.color.a = color_a or action.color.a action.altColor.a = altColor_a or action.altColor.a

	table.insert(gui_widgets.actions, action)

	return action
end

function gui_cycle(text, p, updateTextCallBack, cycleCallBack, list, default, scale, color_r, color_g, color_b, color_a, altColor_r, altColor_g, altColor_b, altColor_a)
	local cycle = gui_wcycle:new(gui_widget)

	cycle.p(p)
	cycle.r(p)
	cycle.text = text
	cycle.updateTextCallBack = updateTextCallBack
	cycle.cycleCallBack = cycleCallBack
	cycle.list = list
	cycle.current = default
	cycle.scale = scale or 1
	cycle.color.r = color_r or cycle.color.r cycle.altColor.r = altColor_r or cycle.altColor.r
	cycle.color.g = color_g or cycle.color.g cycle.altColor.g = altColor_g or cycle.altColor.g
	cycle.color.b = color_b or cycle.color.b cycle.altColor.b = altColor_b or cycle.altColor.b
	cycle.color.a = color_a or cycle.color.a cycle.altColor.a = altColor_a or cycle.altColor.a

	table.insert(gui_widgets.cycles, cycle)

	return cycle
end

function gui_input(text, p, updateTextCallBack, changeCallBack, integerOnly, maxLength, scale, color_r, color_g, color_b, color_a, altColor_r, altColor_g, altColor_b, altColor_a)
	local input = gui_winput:new(gui_widget)

	input.p(p)
	input.r(p)  -- make sure r is initialized before it is added
	input.text = text
	input.pos = #text
	input.updateTextCallBack = updateTextCallBack
	input.changeCallBack = changeCallBack
	input.integerOnly = integerOnly
	input.maxLength = maxLength
	input.scale = scale or 1
	input.color.r = color_r or input.color.r input.altColor.r = altColor_r or input.altColor.r
	input.color.g = color_g or input.color.g input.altColor.g = altColor_g or input.altColor.g
	input.color.b = color_b or input.color.b input.altColor.b = altColor_b or input.altColor.b
	input.color.a = color_a or input.color.a input.altColor.a = altColor_a or input.altColor.a

	table.insert(gui_widgets.inputs, input)

	return input
end

local function gui_private_text(text)
	if #text > length then
		length = #text
	end

	return text
end

local function gui_private_scale(scalar)
	return scalar * length / c_const_get("widget_length")
end

function gui_paint(d)
	for k, v in pairs(gui_widgets.labels) do
		if v.updateTextCallBack then
			v:updateTextCallBack(d)
		end

		local scalex = c_const_get("label_scalex") * v.scale
		local scaley = c_const_get("label_scaley") * v.scale

		local text = gui_private_text(c_const_get("label_prefix") .. v.text .. c_const_get("label_suffix"))
		tankbobs.r_drawString(text, v.p, v.color.r, v.color.g, v.color.b, v.color.a, gui_private_scale(scalex), gui_private_scale(scaley), false)
	end

	for k, v in pairs(gui_widgets.actions) do
		if v.updateTextCallBack then
			v:updateTextCallBack(d)
		end

		local scalex = c_const_get("action_scalex") * v.scale
		local scaley = c_const_get("action_scaley") * v.scale

		if v.bump then
			v.bump = v.bump - d * c_const_get("select_drop")
			if v.bump <= 0 then
				v.bump = nil
			else
				scalex = scalex * (1 + v.bump)
				scaley = scaley * (1 + v.bump)
			end
		end

		local text = gui_private_text(c_const_get("action_prefix") .. v.text .. c_const_get("action_suffix"))
		if v == gui_widgets.selectionType[gui_widgets.selection] then
			v.r = tankbobs.r_drawString(text, v.p, v.altColor.r, v.altColor.g, v.altColor.b, v.altColor.a, gui_private_scale(scalex), gui_private_scale(scaley), false)
		else
			v.r = tankbobs.r_drawString(text, v.p, v.color.r, v.color.g, v.color.b, v.color.a, gui_private_scale(scalex), gui_private_scale(scaley), false)
		end
	end

	for k, v in pairs(gui_widgets.cycles) do
		if v.updateTextCallBack then
			v:updateTextCallBack(d)
		end

		local scalex = c_const_get("cycle_scalex") * v.scale
		local scaley = c_const_get("cycle_scaley") * v.scale

		if v.bump then
			v.bump = v.bump - d * c_const_get("select_drop")
			if v.bump <= 0 then
				v.bump = nil
			else
				scalex = scalex * (1 + v.bump)
				scaley = scaley * (1 + v.bump)
			end
		end

		local text = gui_private_text(c_const_get("cycle_prefix") .. v.list[v.current] .. c_const_get("cycle_suffix"))
		if v == gui_widgets.selectionType[gui_widgets.selection] then
			v.r = tankbobs.r_drawString(text, v.p, v.altColor.r, v.altColor.g, v.altColor.b, v.altColor.a, gui_private_scale(scalex), gui_private_scale(scaley), false)
		else
			v.r = tankbobs.r_drawString(text, v.p, v.color.r, v.color.g, v.color.b, v.color.a, gui_private_scale(scalex), gui_private_scale(scaley), false)
		end
	end

	for k, v in pairs(gui_widgets.inputs) do
		if v.updateTextCallBack then
			v:updateTextCallBack(d)
		end

		local scalex = c_const_get("cycle_scalex") * v.scale
		local scaley = c_const_get("cycle_scaley") * v.scale

		if v.bump then
			v.bump = v.bump - d * c_const_get("select_drop")
			if v.bump <= 0 then
				v.bump = nil
			else
				scalex = scalex * (1 + v.bump)
				scaley = scaley * (1 + v.bump)
			end
		end

		local text = gui_private_text(c_const_get("input_prefix") .. v.text:sub(1, v.pos) .. c_const_get("input_posCharacter") .. v.text:sub(v.pos + 1) .. c_const_get("input_suffix"))
		if v == gui_widgets.selectionType[gui_widgets.selection] then
			v.r = tankbobs.r_drawString(text, v.p, v.altColor.r, v.altColor.g, v.altColor.b, v.altColor.a, gui_private_scale(scalex), gui_private_scale(scaley), false)
		else
			v.r = tankbobs.r_drawString(text, v.p, v.color.r, v.color.g, v.color.b, v.color.a, gui_private_scale(scalex), gui_private_scale(scaley), false)
		end
	end
end

local function gui_private_selected(selection, selectionType)
	gui_widgets.selection = selection or gui_widgets.selection
	gui_widgets.selectionType = selectionType or gui_widgets.selectionType

	selected = gui_widgets.selectionType[gui_widgets.selection]

	selected.bump = c_const_get("select_init")
end

local function gui_private_inputKey(button)
	if button == 276 or button == c_config_get("config.key.left") then  -- left
		if selected.pos > 0 then
			selected.pos = selected.pos - 1
		end

		return true
	elseif button == 275 or button == c_config_get("config.key.right") then  -- right
		if selected.pos < #selected.text then
			selected.pos = selected.pos + 1
		end

		return true
	elseif button == 8 then  -- backspace
		if selected.pos >= 0 then
			selected.text = selected.text:sub(1, selected.pos - 1) .. selected.text:sub(selected.pos + 1, -1)
			selected.pos = selected.pos - 1

			if selected.changeCallBack then
				selected:changeCallBack()
			end
		end

		return true
	elseif button == 127 then  -- delete
		if selected.pos < #selected.text then
			selected.text = selected.text:sub(1, selected.pos) .. selected.text:sub(selected.pos + 2, -1)

			if selected.changeCallBack then
				selected:changeCallBack()
			end
		end

		return true
	elseif button == 278 then  -- home
		selected.pos = 0

		return true
	elseif button == 279 then  -- end
		selected.pos = #selected.text

		return true
	elseif button >= 32 and button < 127 then
		if (#selected.text < selected.maxLength) and (not selected.integerOnly or (button >= string.byte('0') and button <= string.byte('9'))) then
			local add = string.char(button)

			if shift then
				add = add:upper()
			end
			selected.text = selected.text:sub(1, selected.pos) .. add .. selected.text:sub(selected.pos + 1, -1)
			selected.pos = selected.pos + 1

			if selected.changeCallBack then
				selected:changeCallBack()
			end
		end

		return true
	else
		--if c_const_get("debug") then
			--io.stderr:write("Warning: unrecognized key pressed: '", tostring(button), "' (", tostring(char(button)), ")\n")
		--end
	end
end

function gui_click(x, y)
	for k, v in pairs(gui_widgets.actions) do
		if x >= v.p.x and x <= v.r.x and y >= v.p.y and y <= v.r.y then
			if v.actionCallBack then
				v:actionCallBack(x, y)
			end

			return
		end
	end

	for k, v in pairs(gui_widgets.cycles) do
		if x >= v.p.x and x <= v.r.x and y >= v.p.y and y <= v.r.y then
			-- cycle through
			if v.list[v.current + 1] then
				v.current = v.current + 1
				if v.cycleCallBack then
					v:cycleCallBack(v, v.list[v.current], v.current)
				end
			else
				v.current = 1
				if v.cycleCallBack then
					v:cycleCallBack(v, v.list[v.current], v.current)
				end
			end

			return
		end
	end
end

function gui_mouse(x, y, xrel, yrel)
	for k, v in pairs(gui_widgets.actions) do
		if x >= v.p.x and x <= v.r.x and y >= v.p.y and y <= v.r.y then
			if v ~= selected then
				gui_private_selected(k, gui_widgets.actions)

				return
			end
		end
	end

	for k, v in pairs(gui_widgets.cycles) do
		if x >= v.p.x and x <= v.r.x and y >= v.p.y and y <= v.r.y then
			if v ~= selected then
				gui_private_selected(k, gui_widgets.cycles)

				return
			end
		end
	end

	for k, v in pairs(gui_widgets.inputs) do
		if x >= v.p.x and x <= v.r.x and y >= v.p.y and y <= v.r.y then
			if v ~= selected then
				gui_private_selected(k, gui_widgets.inputs)

				return
			end
		end
	end
end

function gui_button(button)
	if button == 0x0D or button == c_config_get("config.key.select") then  -- enter
		if gui_widgets.selectionType and gui_widgets.selectionType[gui_widgets.selection] then
		end
		if selected and gui_widgets.selectionType == gui_widgets.actions then
			if selected.actionCallBack then
				selected:actionCallBack(button)
			end
		elseif selected and gui_widgets.selectionType == gui_widgets.cycles then
			-- cycle through
			if selected.list[selected.current + 1] then
				selected.current = selected.current + 1
				if selected.cycleCallBack then
					selected:cycleCallBack(selected, selected.list[selected.current], selected.current)
				end
			else
				selected.current = 1
				if selected.cycleCallBack then
					selected:cycleCallBack(v, selected.list[selected.current], selected.current)
				end
			end
		end
	elseif button == 273 or button == c_config_get("config.key.up") then  -- up
		if not selected then
			gui_private_selected(math.max(1, #gui_widgets.actions), gui_widgets.actions)
			return
		end

		local y, x = 0, 0
		local selection, selectionType

		for k, v in pairs(gui_widgets.actions) do
			if v.p.y == selected.p.y then
				if v.p.x < selected.p.x and v.p.x > x then
					selection, selectionType = k, gui_widgets.actions
					y, x = v.p.y, v.p.x
				end
			elseif v.p.y > selected.p.y and (v.p.y < y or y == 0) then
				selection, selectionType = k, gui_widgets.actions
				y, x = v.p.y, v.p.x
			end
		end

		for k, v in pairs(gui_widgets.cycles) do
			if v.p.y == selected.p.y then
				if v.p.x < selected.p.x and v.p.x > x then
					selection, selectionType = k, gui_widgets.cycles
					y, x = v.p.y, v.p.x
				end
			elseif v.p.y > selected.p.y and v.p.y < y then
				selection, selectionType = k, gui_widgets.cycles
				y, x = v.p.y, v.p.x
			end
		end

		for k, v in pairs(gui_widgets.inputs) do
			if v.p.y == selected.p.y then
				if v.p.x < selected.p.x and v.p.x > x then
					selection, selectionType = k, gui_widgets.inputs
					y, x = v.p.y, v.p.x
				end
			elseif v.p.y > selected.p.y and v.p.y < y then
				selection, selectionType = k, gui_widgets.inputs
				y, x = v.p.y, v.p.x
			end
		end

		if selection and selectionType then
			gui_private_selected(selection, selectionType)
		end
	elseif button == 274 or button == c_config_get("config.key.down") then  -- down
		if not selected then
			gui_private_selected(1, gui_widgets.actions)
			return
		end

		local y, x = 0, 0
		local selection, selectionType

		for k, v in pairs(gui_widgets.actions) do
			if v.p.y == selected.p.y then
				if v.p.x > selected.p.x and (v.p.x < x or x == 0) then
					selection, selectionType = k, gui_widgets.actions
					y, x = v.p.y, v.p.x
				end
			elseif v.p.y < selected.p.y and v.p.y > y then
				selection, selectionType = k, gui_widgets.actions
				y, x = v.p.y, v.p.x
			end
		end

		for k, v in pairs(gui_widgets.cycles) do
			if v.p.y == selected.p.y then
				if v.p.x > selected.p.x and v.p.x < x then
					selection, selectionType = k, gui_widgets.cycles
					y, x = v.p.y, v.p.x
				end
			elseif v.p.y < selected.p.y and v.p.y > y then
				selection, selectionType = k, gui_widgets.cycles
				y, x = v.p.y, v.p.x
			end
		end

		for k, v in pairs(gui_widgets.inputs) do
			if v.p.y == selected.p.y then
				if v.p.x > selected.p.x and v.p.x < x then
					selection, selectionType = k, gui_widgets.inputs
					y, x = v.p.y, v.p.x
				end
			elseif v.p.y < selected.p.y and v.p.y > y then
				selection, selectionType = k, gui_widgets.inputs
				y, x = v.p.y, v.p.x
			end
		end

		if selection and selectionType then
			gui_private_selected(selection, selectionType)
		end
	elseif selected and gui_widgets.selectionType == gui_widgets.inputs then
		return gui_private_inputKey(button)
	elseif button == 276 or button == c_config_get("config.key.left") then  -- left
		if selected and gui_widgets.selectionType == gui_widgets.cycles then
			if selected.list[selected.current - 1] then
				selected.current = selected.current - 1
				if selected.cycleCallBack then
					selected:cycleCallBack(selected.list[selected.current], selected.current)
				end
			end
		end
	elseif button == 275 or button == c_config_get("config.key.right") then  -- right
		if selected and gui_widgets.selectionType == gui_widgets.cycles then
			if selected.list[selected.current + 1] then
				selected.current = selected.current + 1
				if selected.cycleCallBack then
					selected:cycleCallBack(selected.list[selected.current], selected.current)
				end
			end
		end
	end
end

function gui_char(c)
	if c == 0x00 then
		return "?", "?"
	elseif c == 0x01 then
		return "?", "?"
	elseif c == 0x02 then
		return "?", "?"
	elseif c == 0x03 then
		return "?", "?"
	elseif c == 0x04 then
		return "?", "?"
	elseif c == 0x05 then
		return "?", "?"
	elseif c == 0x06 then
		return "?", "?"
	elseif c == 0x07 then
		return "?", "?"
	elseif c == 0x08 then
		return "", "Backspace"
	elseif c == 0x09 then
		return "TAB", "Tab"
	elseif c == 0x0A then
		return "?", "?"
	elseif c == 0x0B then
		return "?", "?"
	elseif c == 0x0C then
		return "?", "?"
	elseif c == 0x0D then
		return "?", "?"
	elseif c == 0x0E then
		return "?", "?"
	elseif c == 0x0F then
		return "?", "?"
	elseif c == 0x10 then
		return "?", "?"
	elseif c == 0x11 then
		return "?", "?"
	elseif c == 0x12 then
		return "?", "?"
	elseif c == 0x12 then
		return "?", "?"
	elseif c == 0x13 then
		return "?", "?"
	elseif c == 0x14 then
		return "?", "?"
	elseif c == 0x15 then
		return "?", "?"
	elseif c == 0x16 then
		return "?", "?"
	elseif c == 0x17 then
		return "?", "?"
	elseif c == 0x18 then
		return "?", "?"
	elseif c == 0x19 then
		return "?", "?"
	elseif c == 0x19 then
		return "?", "?"
	elseif c == 0x1A then
		return "?", "?"
	elseif c == 0x1B then
		return "ESC", "Escape"
	elseif c == 0x1C then
		return "?", "?"
	elseif c == 0x1D then
		return "?", "?"
	elseif c == 0x1E then
		return "?", "?"
	elseif c == 0x1F then
		return "?", "?"
	elseif c == 0x20 then
		return "SPACE", "Space"
	elseif c == 0x21 then
		return "!", "Exclamation"
	elseif c == 0x22 then
		return "\"", "Double Quotation"
	elseif c == 0x23 then
		return "#", "Pound"
	elseif c == 0x24 then
		return "$", "Dollar"
	elseif c == 0x25 then
		return "%", "Percentage"
	elseif c == 0x26 then
		return "&", "Ampersand"
	elseif c == 0x27 then
		return "'", "Single Quotation"
	elseif c == 0x28 then
		return "(", "Left Perinthesis"
	elseif c == 0x29 then
		return ")", "Right Perinthesis"
	elseif c == 0x2A then
		return "*", "Asterisk"
	elseif c == 0x2B then
		return "+", "Plus"
	elseif c == 0x2C then
		return ",", "Comma"
	elseif c == 0x2D then
		return "-", "hyphen"
	elseif c == 0x2E then
		return ".", "period"
	elseif c == 0x2F then
		return "/", "slash"
	elseif c == 0x30 then
		return "0", "Zero"
	elseif c == 0x31 then
		return "1", "One"
	elseif c == 0x32 then
		return "2", "Two"
	elseif c == 0x33 then
		return "3", "Three"
	elseif c == 0x34 then
		return "4", "Four"
	elseif c == 0x35 then
		return "5", "Five"
	elseif c == 0x36 then
		return "6", "Six"
	elseif c == 0x37 then
		return "7", "Seven"
	elseif c == 0x38 then
		return "8", "Eight"
	elseif c == 0x39 then
		return "9", "Nine"
	elseif c == 0x3A then
		return ":", "Colon"
	elseif c == 0x3B then
		return ";", "Semicolon"
	elseif c == 0x3C then
		return "<", "Less Than"
	elseif c == 0x3D then
		return "=", "Equal"
	elseif c == 0x3E then
		return ">", "Greater Than"
	elseif c == 0x3F then
		return "?", "Question Mark"
	elseif c == 0x40 then
		return "@", "At"
	elseif c == 0x41 then
		return "A", "A"
	elseif c == 0x42 then
		return "B", "B"
	elseif c == 0x43 then
		return "C", "C"
	elseif c == 0x44 then
		return "D", "D"
	elseif c == 0x45 then
		return "E", "E"
	elseif c == 0x46 then
		return "F", "F"
	elseif c == 0x47 then
		return "G", "G"
	elseif c == 0x48 then
		return "H", "H"
	elseif c == 0x49 then
		return "I", "I"
	elseif c == 0x4A then
		return "J", "J"
	elseif c == 0x4B then
		return "K", "K"
	elseif c == 0x4C then
		return "L", "L"
	elseif c == 0x4D then
		return "M", "M"
	elseif c == 0x4E then
		return "N", "N"
	elseif c == 0x4F then
		return "O", "O"
	elseif c == 0x50 then
		return "P", "P"
	elseif c == 0x51 then
		return "Q", "Q"
	elseif c == 0x52 then
		return "R", "R"
	elseif c == 0x53 then
		return "S", "S"
	elseif c == 0x54 then
		return "T", "T"
	elseif c == 0x55 then
		return "U", "U"
	elseif c == 0x56 then
		return "V", "V"
	elseif c == 0x57 then
		return "W", "W"
	elseif c == 0x58 then
		return "X", "X"
	elseif c == 0x59 then
		return "Y", "Y"
	elseif c == 0x5A then
		return "Z", "Z"
	elseif c == 0x5B then
		return "[", "Opening Bracket"
	elseif c == 0x5C then
		return "\\", "Backslash"
	elseif c == 0x5D then
		return "]", "Closing Bracket"
	elseif c == 0x5E then
		return "^", "Carrot"
	elseif c == 0x5F then
		return "_", "Underscore"
	elseif c == 0x60 then
		return "`", "Apostraphe"
	elseif c == 0x61 then
		return "a", "a"
	elseif c == 0x62 then
		return "b", "b"
	elseif c == 0x63 then
		return "c", "c"
	elseif c == 0x64 then
		return "d", "d"
	elseif c == 0x65 then
		return "e", "e"
	elseif c == 0x66 then
		return "f", "f"
	elseif c == 0x67 then
		return "g", "g"
	elseif c == 0x68 then
		return "h", "h"
	elseif c == 0x69 then
		return "i", "i"
	elseif c == 0x6A then
		return "j", "j"
	elseif c == 0x6B then
		return "k", "k"
	elseif c == 0x6C then
		return "l", "l"
	elseif c == 0x6D then
		return "m", "m"
	elseif c == 0x6E then
		return "n", "n"
	elseif c == 0x6F then
		return "o", "o"
	elseif c == 0x70 then
		return "p", "p"
	elseif c == 0x71 then
		return "q", "q"
	elseif c == 0x72 then
		return "r", "r"
	elseif c == 0x73 then
		return "s", "s"
	elseif c == 0x74 then
		return "t", "t"
	elseif c == 0x75 then
		return "u", "u"
	elseif c == 0x76 then
		return "v", "v"
	elseif c == 0x77 then
		return "w", "w"
	elseif c == 0x78 then
		return "x", "x"
	elseif c == 0x79 then
		return "y", "y"
	elseif c == 0x7A then
		return "z", "z"
	elseif c == 0x7B then
		return "{", "Opening Brace"
	elseif c == 0x7C then
		return "|", "Pipe"
	elseif c == 0x7D then
		return "}", "Closing Brace"
	elseif c == 0x7E then
		return "~", "Tilde"
	elseif c == 0x7F then
		return "", "Delete"
	elseif type(c) == "number" and c >= 0x80 then
		return "KEY", "Key"
	else
		return "?", "Unbound"
	end
end
