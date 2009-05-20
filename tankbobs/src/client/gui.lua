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
	gui_widgets = {labels = {}, actions = {}, cycles = {}, selection = 1, selectionType = nil}

	c_const_set("label_r", 0.8, 1)
	c_const_set("label_g", 0.5, 1)
	c_const_set("label_b", 0.1, 1)
	c_const_set("label_a", 1.0, 1)
	c_const_set("label_scalex", 1 / 20, -1)
	c_const_set("label_scaley", 1 / 20, -1)

	c_const_set("action_r", 0.92, 1)
	c_const_set("action_g", 0.94, 1)
	c_const_set("action_b", 0.98, 1)
	c_const_set("action_a", 1.0, 1)
	c_const_set("action_scalex", 1 / 40, -1)
	c_const_set("action_scaley", 1 / 40, -1)

	c_const_set("actionSelected_r", 0.6, 1)
	c_const_set("actionSelected_g", 0.4, 1)
	c_const_set("actionSelected_b", 0.2, 1)
	c_const_set("actionSelected_a", 1.0, 1)
	c_const_set("actionSelected_scalex", 1 / 30, -1)
	c_const_set("actionSelected_scaley", 1 / 30, -1)
end

function gui_done()
	gui_widgets = nil
end

gui_widget =
{
	new = common_new,

	init = function (o)
		o.p = tankbobs.m_vec2()
	end,

	p = nil,
	text = "",
	updateText = nil,
}

gui_wlabel =
{
	new = common_new,

	init = function (o)
		o.p = tankbobs.m_vec2()
	end
}

gui_waction =
{
	new = common_new,

	init = function (o)
		o.p = tankbobs.m_vec2()
		o.r = tankbobs.m_vec2()
	end,

	actionCallback = nil,
	r = nil  -- position of upper-right coordinates
}

function gui_finish()
	gui_widgets = {labels = {}, actions = {}, cycles = {}, selection = 1, selectionType = nil}
end

function gui_label(text, p, updateTextCallBack)
	local label = gui_wlabel:new(gui_widget)

	label.p(p)
	label.text = text
	label.updateTextCallBack = updateTextCallBack

	table.insert(gui_widgets.labels, label)

	return label
end

function gui_action(text, p, updateTextCallBack, actionCallBack)
	local action = gui_waction:new(gui_widget)

	action.p(p)
	action.r(p)  -- make sure r is initialized before it is added
	action.text = text
	action.updateTextCallBack = updateTextCallBack
	action.actionCallBack = actionCallBack

	table.insert(gui_widgets.actions, action)

	return action
end

function gui_paint(d)
	for k, v in pairs(gui_widgets.labels) do
		if v.updateTextCallBack then
			v:updateTextCallBack(d)
		end

		tankbobs.r_drawString(v.text, v.p, c_const_get("label_r"), c_const_get("label_g"), c_const_get("label_b"), c_const_get("label_a"), c_const_get("label_scalex"), c_const_get("label_scaley"), false)
	end

	for k, v in pairs(gui_widgets.actions) do
		if v.updateTextCallBack then
			v:updateTextCallBack(d)
		end

		v.r = tankbobs.r_drawString(v.text, v.p, c_const_get("action_r"), c_const_get("action_g"), c_const_get("action_b"), c_const_get("action_a"), c_const_get("action_scalex"), c_const_get("action_scaley"), false)
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
end

function gui_mouse(x, y, xrel, yrel)
	for k, v in pairs(gui_widgets.actions) do
		if x >= v.p.x and x <= v.r.x and y >= v.p.y and y <= v.r.y then
			gui_widgets.selection = k
			gui_widgets.selectionType = gui_widgets.gui_actions

			return
		end
	end
end

function gui_button(button)
	-- widgets are added in an decending order
	if button == 0x0D or button == c_config_get("config.key.select") then  -- enter
		if gui_widgets.selectionType and gui_widgets.selectionType[gui_widgets.selection] then
			local widget = gui_widgets.selectionType[gui_widgets.selection]

			if widget.actionCallBack then
				widget:actionCallBack(button)
			end
		end
	elseif button == 273 or button == c_config_get("config.key.up") then  -- up
		if gui_widgets.selectionType and gui_widgets.selectionType[gui_widgets.selection] then
			if gui_widgets.selectionType[gui_widgets.selection - 1] then
				gui_widgets.selection = gui_widgets.selection - 1
			end

			return
		end
	elseif button == 274 or button == c_config_get("config.key.down") then  -- down
		if gui_widgets.selectionType and gui_widgets.selectionType[gui_widgets.selection] then
			if gui_widgets.selectionType[gui_widgets.selection + 1] then
				gui_widgets.selection = gui_widgets.selection + 1
			end

			return
		end
	elseif button == 276 or button == c_config_get("config.key.left") then  -- left
	elseif button == 275 or button == c_config_get("config.key.right") then  -- right
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
