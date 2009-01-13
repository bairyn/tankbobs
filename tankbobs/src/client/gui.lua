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
I'm not a good GUI guy, so I had implement gui_conserve() which stops gui input to keep it from being very slow (see the license, there's at leasy a 5 or so second delay)
--]]

function gui_init()
	gui_data = {}
	gui_colors = {{0.95, 0.5, 0.25, 1.0}, {1.0, 1.0, 1.0, 1.0}, {0.8, 0.8, 0.8, 0.6}, {0.9, 0.8, 0.1, 0.8}}
	gui_selection = nil
end

function gui_done()
	gui_finish()
	gui_data = nil
end

function gui_selectColor(r, g, b, a)
	gui_colors[1][1] = r
	gui_colors[1][2] = g
	gui_colors[1][3] = b
	gui_colors[1][4] = a
end

function gui_unselectColor(r, g, b, a)
	gui_colors[2][1] = r
	gui_colors[2][2] = g
	gui_colors[2][3] = b
	gui_colors[2][4] = a
end

function gui_buttonColor(r, g, b, a)
	gui_colors[3][1] = r
	gui_colors[3][2] = g
	gui_colors[3][3] = b
	gui_colors[3][4] = a
end

function gui_labelColor(r, g, b, a)
	gui_colors[4][1] = r
	gui_colors[4][2] = g
	gui_colors[4][3] = b
	gui_colors[4][4] = a
end

function gui_finish()
	gui_selection = nil
	gui_safe = nil
	gui_data = nil
	gui_colors = {{0.95, 0.5, 0.25, 1.0}, {1.0, 1.0, 1.0, 1.0}, {0.8, 0.8, 0.8, 0.6}, {0.9, 0.8, 0.1, 0.8}}
	gui_data = {}
end

local function gui_private_xpre(c, x)
	if c == "!" then
		x = x - 0.50
	elseif c == "l" then
		x = x - 0.50
	elseif c == "i" then
		x = x - 0.50
	end

	return x
end

local function gui_private_xpos(c, x)
	if c == "!" then
		x = x + 0.75
	elseif c == "l" then
		x = x + 0.75
	elseif c == "i" then
		x = x + 0.75
	end

	return x
end

local function gui_private_ypre(c, y)
	return y
end

local function gui_private_ypos(c, y)
	return y
end

local function gui_private_wpre(c, w)
	if c == "!" then
		w = w * 0.33
	elseif c == "m" then
		w = w * 1.25
	elseif c == "M" then
		w = w * 1.25
	elseif c == "l" then
		w = w * 0.33
	elseif c == "i" then
		w = w * 0.33
	end

	return w
end

local function gui_private_wpos(c, w)
	return w
end

local function gui_private_hpre(c, h)
	if c == "k" then
		h = h * 1.25
	elseif c == "K" then
		h = h * 1.125
	end

	return h
end

local function gui_private_hpos(c, h)
	return h
end

function gui_paint()
	for k, v in ipairs(gui_data) do
		if v[1] == "label" then
			gl.Color(gui_colors[4])
			local x, y = v[3], v[4]
			for i = 1, type(v[6]) == "function" and v[6]():len() or v[6]:len() do
				local w, h, c = v[5], v[5], type(v[6]) == "function" and v[6]():sub(i, i) or v[6]:sub(i, i)
				x = gui_private_xpre(c, x)
				y = gui_private_ypre(c, y)
				w = gui_private_wpre(c, w)
				h = gui_private_hpre(c, h)
				tankbobs.renderchar(x, y, w, h, v[2], c)
				x = x + w
				x = gui_private_xpos(c, x)
				y = gui_private_ypos(c, y)
				w = gui_private_wpos(c, w)
				h = gui_private_hpos(c, h)
			end
		elseif v[1] == "active" then
			if gui_selection == v then
				gl.Color(gui_colors[1])
			else
				gl.Color(gui_colors[2])
			end
			local x, y = v[4], v[5]
			for i = 1, type(v[7]) == "function" and v[7]():len() or v[7]:len() do
				local w, h, c = v[6], v[6], type(v[7]) == "function" and v[7]():sub(i, i) or v[7]:sub(i, i)
				x = gui_private_xpre(c, x)
				y = gui_private_ypre(c, y)
				w = gui_private_wpre(c, w)
				h = gui_private_hpre(c, h)
				tankbobs.renderchar(x, y, w, h, v[3], c)
				x = x + w
				x = gui_private_xpos(c, x)
				y = gui_private_ypos(c, y)
				w = gui_private_wpos(c, w)
				h = gui_private_hpos(c, h)
			end
		elseif v[1] == "option" then
			if gui_selection == v then
				gl.Color(gui_colors[1])
			else
				gl.Color(gui_colors[2])
			end
			local x, y = v[4], v[5]
			for i = 1, type(v[7]) == "function" and v[7]():len() or v[7]:len() do
				local w, h, c = v[6], v[6], type(v[7]) == "function" and v[7]():sub(i, i) or v[7]:sub(i, i)
				x = gui_private_xpre(c, x)
				y = gui_private_ypre(c, y)
				w = gui_private_wpre(c, w)
				h = gui_private_hpre(c, h)
				tankbobs.renderchar(x, y, w, h, v[3], c)
				x = x + w
				x = gui_private_xpos(c, x)
				y = gui_private_ypos(c, y)
				w = gui_private_wpos(c, w)
				h = gui_private_hpos(c, h)
			end
			x = x + v[6] * 3
			for i = 1, type(v[9]) == "function" and v[9]():len() or v[9]:len() do
				local w, h, c = v[6], v[6], type(v[9]) == "function" and v[9]():sub(i, i) or v[9]:sub(i, i)
				x = gui_private_xpre(c, x)
				y = gui_private_ypre(c, y)
				w = gui_private_wpre(c, w)
				h = gui_private_hpre(c, h)
				tankbobs.renderchar(x, y, w, h, v[3], c)
				x = x + w
				x = gui_private_xpos(c, x)
				y = gui_private_ypos(c, y)
				w = gui_private_wpos(c, w)
				h = gui_private_hpos(c, h)
			end
		end
	end
end

function gui_click(x, y)
	if gui_safe ~= nil then
		return nil
	end

	for k, v in ipairs(gui_data) do
		if v[1] == "active" then
			local xp, yp = v[4], v[5]
			for i = 1, type(v[7]) == "function" and v[7]():len() or v[7]:len() do
				local w, h, c = v[6], v[6], type(v[7]) == "function" and v[7]():sub(i, i) or v[7]:sub(i, i)
				xp = gui_private_xpre(c, xp)
				yp = gui_private_ypre(c, yp)
				w  = gui_private_ypre(c, w)
				h  = gui_private_ypre(c, h)
				if x > xp - w / 2 and x < xp + w / 2 and y > yp - h / 2 and y < yp + h / 2 then
					gui_selection = v
					if type(gui_selection[2]) == "table" then
						for k, v in ipairs(gui_selection[2]) do
							v(gui_selection[7], gui_selection[8])
						end
						for k, v in pairs(gui_selection[2]) do
							if type(k) ~= "number" then
								v(gui_selection[7], gui_selection[8])
							end
						end
					else
						gui_selection[2](gui_selection[7], gui_selection[8])
					end
					return
				end
				xp = xp + w
				xp = gui_private_xpos(c, xp)
				yp = gui_private_ypos(c, yp)
				w  = gui_private_ypos(c, w)
				h  = gui_private_ypos(c, h)
			end
		elseif v[1] == "option" then
			local xp, yp = v[4], v[5]
			for i = 1, type(v[7]) == "function" and v[7]():len() or v[7]:len() do
				local w, h, c = v[6], v[6], type(v[7]) == "function" and v[7]():sub(i, i) or v[7]:sub(i, i)
				xp = gui_private_xpre(c, xp)
				yp = gui_private_ypre(c, yp)
				w  = gui_private_ypre(c, w)
				h  = gui_private_ypre(c, h)
				if x > xp - w / 2 and x < xp + w / 2 and y > yp - h / 2 and y < yp + h / 2 then
					gui_selection = v
					if type(gui_selection[2]) == "table" then
						for k, v in ipairs(selection[2]) do
							v(true, k)
						end
						for k, v in pairs(gui_selection[2]) do
							if type(k) ~= "number" then
								v(true, k)
							end
						end
					else
						gui_selection[2](false)
					end
					return
				end
				xp = xp + w
				xp = gui_private_xpos(c, xp)
				yp = gui_private_ypos(c, yp)
				w  = gui_private_ypos(c, w)
				h  = gui_private_ypos(c, h)
			end
			xp = xp + v[6] * 3
			for i = 1, v[9]:len() do
				local w, h, c = v[6], v[6], v[9]:sub(i, i)
				xp = gui_private_xpre(c, xp)
				yp = gui_private_ypre(c, yp)
				w  = gui_private_ypre(c, w)
				h  = gui_private_ypre(c, h)
				if x > xp - w / 2 and x < xp + w / 2 and y > yp - h / 2 and y < yp + h / 2 then
					gui_selection = v
					if type(gui_selection[2]) == "table" then
						for k, v in ipairs(selection[2]) do
							v(true, k)
						end
						for k, v in pairs(gui_selection[2]) do
							if type(k) ~= "number" then
								v(true, k)
							end
						end
					else
						gui_selection[2](false)
					end
					return
				end
				xp = xp + w
				xp = gui_private_xpos(c, xp)
				yp = gui_private_ypos(c, yp)
				w  = gui_private_ypos(c, w)
				h  = gui_private_ypos(c, h)
			end
		end
	end
end

function gui_mouse(x, y)
	if gui_safe ~= nil then
		return nil
	end

	for k, v in ipairs(gui_data) do
		if v[1] == "active" then
			local xp, yp = v[4], v[5]
			for i = 1, type(v[7]) == "function" and v[7]():len() or v[7]:len() do
				local w, h, c = v[6], v[6], type(v[7]) == "function" and v[7]():sub(i, i) or v[7]:sub(i, i)
				xp = gui_private_xpre(c, xp)
				yp = gui_private_ypre(c, yp)
				w  = gui_private_ypre(c, w)
				h  = gui_private_ypre(c, h)
				if x > xp - w / 2 and x < xp + w / 2 and y > yp - h / 2 and y < yp + h / 2 then
					gui_selection = v
					return
				end
				xp = xp + w
				xp = gui_private_xpos(c, xp)
				yp = gui_private_ypos(c, yp)
				w  = gui_private_ypos(c, w)
				h  = gui_private_ypos(c, h)
			end
		elseif v[1] == "option" then
			local xp, yp = v[4], v[5]
			for i = 1, type(v[7]) == "function" and v[7]():len() or v[7]:len() do
				local w, h, c = v[6], v[6], type(v[7]) == "function" and v[7]():sub(i, i) or v[7]:sub(i, i)
				xp = gui_private_xpre(c, xp)
				yp = gui_private_ypre(c, yp)
				w  = gui_private_ypre(c, w)
				h  = gui_private_ypre(c, h)
				if x > xp - w / 2 and x < xp + w / 2 and y > yp - h / 2 and y < yp + h / 2 then
					gui_selection = v
					return
				end
				xp = xp + w
				xp = gui_private_xpos(c, xp)
				yp = gui_private_ypos(c, yp)
				w  = gui_private_ypos(c, w)
				h  = gui_private_ypos(c, h)
			end
			xp = xp + v[6] * 3
			for i = 1, v[9]:len() do
				local w, h, c = v[6], v[6], v[9]:sub(i, i)
				xp = gui_private_xpre(c, xp)
				yp = gui_private_ypre(c, yp)
				w  = gui_private_ypre(c, w)
				h  = gui_private_ypre(c, h)
				if x > xp - w / 2 and x < xp + w / 2 and y > yp - h / 2 and y < yp + h / 2 then
					gui_selection = v
					return
				end
				xp = xp + w
				xp = gui_private_xpos(c, xp)
				yp = gui_private_ypos(c, yp)
				w  = gui_private_ypos(c, w)
				h  = gui_private_ypos(c, h)
			end
		end
	end
end

function gui_button(button)
	if gui_safe ~= nil then
		return nil
	end

	if gui_selection then
		if button == 0x0D or button == c_config_get("config.key.select") then  -- enter
			if gui_selection[1] == "label" then
			elseif gui_selection[1] == "active" or gui_selection[1] == "option" then
				if type(gui_selection[2]) == "table" then
					for k, v in ipairs(gui_selection[2]) do
						v(gui_selection[7], gui_selection[8])
					end
					for k, v in pairs(gui_selection[2]) do
						if type(k) ~= "number" then
							v(gui_selection[7], gui_selection[8])
						end
					end
				else
					gui_selection[2](gui_selection[7], gui_selection[8])
				end
			end
		elseif button == 273 or button == c_config_get("config.key.up") then  -- up, pgup
			local i, pos = 0
			for k, v in ipairs(gui_data) do
				if v[1] == "active" or v[1] == "option" then
					i = i + 1
					if gui_selection == v then
						pos = i
					end
				end
			end
			if i == 0 or pos == nil then
				return false
			end

			i = 0
			for k, v in ipairs(gui_data) do
				if v[1] == "active" or v[1] == "option" then
					i = i + 1
					if pos == i + 1 then
						gui_selection = v
					end
				end
			end
		elseif button == 274 or button == c_config_get("config.key.down") then  -- down, pgdown
			local i, pos = 0
			for k, v in ipairs(gui_data) do
				if v[1] == "active" or v[1] == "option" then
					i = i + 1
					if gui_selection == v then
						pos = i
					end
				end
			end
			if i == 0 or pos == nil then
				return false
			end

			i = 0
			for k, v in ipairs(gui_data) do
				if v[1] == "active" or v[1] == "option" then
					i = i + 1
					if pos == i - 1 then
						gui_selection = v
					end
				end
			end
		elseif button == 276 or button == c_config_get("config.key.left") then  -- left
			if gui_selection[1] == "option" then
				local pos
				for k, v in ipairs(gui_selection[8]) do
					if v[4] == nil then
						if v[1] == gui_selection[9] then
							if pos then
								if v[3] then
									v[3](v[1])
								end
								gui_selection[9] = gui_selection[8][pos][1]
								gui_selection[8][pos][2](gui_selection[8][pos][1])
							end
						end
						pos = k
					elseif v[1] == gui_selection[9] then
						local V = v
						for k, v in ipairs(gui_selection[8]) do
							if v[4] == nil then
								if V[3] then
									V[3](V[1])
								end
								gui_selection[9] = v[1]
								return true
							end
						end
					end
				end
			else
				return nil
			end
		elseif button == 275 or button == c_config_get("config.key.right") then  -- right
			if gui_selection[1] == "option" then
				local next = false
				for k, v in ipairs(gui_selection[8]) do
					if v[4] == nil then
						if next then
							gui_selection[9] = v[1]
							v[2](v[1])
							return true
						end
						if v[1] == gui_selection[9] then
							next = true
							if v[3] and pos > 1 then
								v[3](v[1])
							end
						end
					elseif v[1] == gui_selection[9] then
						local V = gui_selection[9]
						for k, v in ipairs(gui_selection[8]) do
							if v[4] == nil then
								gui_selection[9] = v[1]
							end
						end
						for k, v in ipairs(gui_selection[8]) do
							if v[1] == V then
								if v[3] then
									v[3](v[1])
								end
								return true
							end
						end
					end
				end
			else
				return nil
			end
		else
			return nil
		end
	else
		return nil
	end

	return true
end

function gui_row()
	error("Debug: dynamic gui isn't supported yet (gui_row() was called)")
end

function gui_column()
	error("Debug: dynamic gui isn't supported yet (gui_column() was called)")
end

function gui_space()
	error("Debug: dynamic gui isn't supported yet (gui_space() was called)")
end

function gui_end()
	error("Debug: dynamic gui isn't supported yet (gui_end() was called)")
end

function gui_conserve()
	gui_safe = true
end

function gui_widget(type, callback, ttffont, x, y, size, text, cycle, ccurrent)
	if type == "label" then
		local label
		if callback == nil then
			label = {"label", ttffont, x, y, size, text}
		else
			label = {"label", callback, ttffont, x, y, size}  -- hack: if callback was ignored
		end
		table.insert(gui_data, label)
	elseif type == "active" then
		local active = {"active", callback, ttffont, x, y, size, text, cycle}  -- cycle is an extra paramater to be passed to the callback
		table.insert(gui_data, active)
		if not gui_selection then
			gui_selection = active
		end
	elseif type == "option" then
		local option = {"option", callback, ttffont, x, y, size, text, cycle, ccurrent}
		table.insert(gui_data, option)
		if not gui_selection then
			gui_selection = option
		end
	end
end

function gui_layout()
	error("Debug: dynamic gui isn't supported yet (gui_layout() was called)")
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
		return "[", "Opening Array Bracket"
	elseif c == 0x5C then
		return "\\", "Backslash"
	elseif c == 0x5D then
		return "]", "Closing Array Bracket"
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
