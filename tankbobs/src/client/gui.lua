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
gui.lua

Graphical User Interface
--]]

local c_const_get = c_const_get
local tankbobs = tankbobs
local gl = gl

local scaleCenter_listBase
local scaleCenter_texture
local scale_listBase
local scale_texture
local widgets = {}
local selected = nil
local scroll = 0

function gui_init()
	c_const_get = _G.c_const_get
	tankbobs = _G.tankbobs
	gl = _G.gl

	c_const_set("widget_length", 1.5, 1)
	c_const_set("gui_vspacing", 0.5, 1)

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

	c_const_set("key_prefix", "", 1)
	c_const_set("key_suffix", "", 1)
	c_const_set("key_r", 0.62, 1)
	c_const_set("key_g", 0.64, 1)
	c_const_set("key_b", 0.98, 1)
	c_const_set("key_a", 1.0, 1)
	c_const_set("key_scalex", 1 / 12, 1)
	c_const_set("key_scaley", 1 / 12, 1)
	c_const_set("key_activeSuffix", " ]", 1)
	c_const_set("keySelected_r", 0.31, 1)
	c_const_set("keySelected_g", 0.32, 1)
	c_const_set("keySelected_b", 0.65333333333333333, 1)
	c_const_set("keySelected_a", 1.0, 1)

	c_const_set("scale_prefix", "[", 1)
	c_const_set("scale_suffix", "]", 1)
	c_const_set("scale_r", 0.92, 1)
	c_const_set("scale_g", 0.94, 1)
	c_const_set("scale_b", 0.98, 1)
	c_const_set("scale_a", 1.0, 1)
	c_const_set("scale_scalex", 1 / 1, 1)
	c_const_set("scale_scaley", 1 / 1, 1)
	c_const_set("scaleSelected_r", 0.1, 1)
	c_const_set("scaleSelected_g", 0.8, 1)
	c_const_set("scaleSelected_b", 0.215, 1)
	c_const_set("scaleSelected_a", 1.0, 1)

	c_const_set("scaleCenter_texture", c_const_get("game_dir") .. "scaleCenter.png", 1)
	c_const_set("scaleCenter_width", 2, 1)
	c_const_set("scaleCenter_height", 4, 1)
	c_const_set("scaleCenter_renderx1", 0, 1) c_const_set("scaleCenter_rendery1", c_const_get("scaleCenter_height"), 1)
	c_const_set("scaleCenter_renderx2", 0, 1) c_const_set("scaleCenter_rendery2", 0, 1)
	c_const_set("scaleCenter_renderx3", c_const_get("scaleCenter_width"), 1) c_const_set("scaleCenter_rendery3", 0, 1)
	c_const_set("scaleCenter_renderx4", c_const_get("scaleCenter_width"), 1) c_const_set("scaleCenter_rendery4", c_const_get("scaleCenter_height"), 1)
	c_const_set("scaleCenter_texturex1", 0, 1) c_const_set("scaleCenter_texturey1", 1, 1)
	c_const_set("scaleCenter_texturex2", 0, 1) c_const_set("scaleCenter_texturey2", 0, 1)
	c_const_set("scaleCenter_texturex3", 1, 1) c_const_set("scaleCenter_texturey3", 0, 1)
	c_const_set("scaleCenter_texturex4", 1, 1) c_const_set("scaleCenter_texturey4", 1, 1)
	scaleCenter_listBase = gl.GenLists(1)
	scaleCenter_texture  = gl.GenTextures(1)
	gl.BindTexture("TEXTURE_2D", scaleCenter_texture[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("scaleCenter_texture"), c_const_get("textures_default"))
	gl.NewList(scaleCenter_listBase, "COMPILE")
		gl.BindTexture("TEXTURE_2D", scaleCenter_texture[1])
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

		gl.Begin("QUADS")
			for i = 1, 4 do
				gl.TexCoord(c_const_get("scaleCenter_texturex" .. i), c_const_get("scaleCenter_texturey" .. i))
				gl.Vertex(c_const_get("scaleCenter_renderx" .. i), c_const_get("scaleCenter_rendery" .. i))
			end
		gl.End()
	gl.EndList()

	c_const_set("scale_texture", c_const_get("game_dir") .. "scale.png", 1)
	c_const_set("scale_width", 20, 1)
	c_const_set("scale_height", 2, 1)
	c_const_set("scale_renderx1", 0, 1) c_const_set("scale_rendery1", c_const_get("scale_height"), 1)
	c_const_set("scale_renderx2", 0, 1) c_const_set("scale_rendery2", 0, 1)
	c_const_set("scale_renderx3", c_const_get("scale_width"), 1) c_const_set("scale_rendery3", 0, 1)
	c_const_set("scale_renderx4", c_const_get("scale_width"), 1) c_const_set("scale_rendery4", c_const_get("scale_height"), 1)
	c_const_set("scale_texturex1", 0, 1) c_const_set("scale_texturey1", 1, 1)
	c_const_set("scale_texturex2", 0, 1) c_const_set("scale_texturey2", 0, 1)
	c_const_set("scale_texturex3", 1, 1) c_const_set("scale_texturey3", 0, 1)
	c_const_set("scale_texturex4", 1, 1) c_const_set("scale_texturey4", 1, 1)
	scale_listBase       = gl.GenLists(1)
	scale_texture        = gl.GenTextures(1)
	gl.BindTexture("TEXTURE_2D", scale_texture[1])
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_S", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_WRAP_T", "REPEAT")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MIN_FILTER", "LINEAR")
	gl.TexParameter("TEXTURE_2D", "TEXTURE_MAG_FILTER", "LINEAR")
	tankbobs.r_loadImage2D(c_const_get("scale_texture"), c_const_get("textures_default"))
	gl.NewList(scale_listBase, "COMPILE")
		gl.BindTexture("TEXTURE_2D", scale_texture[1])
		gl.TexEnv("TEXTURE_ENV_MODE", "MODULATE")

		gl.Begin("QUADS")
			for i = 1, 4 do
				gl.TexCoord(c_const_get("scale_texturex" .. i), c_const_get("scale_texturey" .. i))
				gl.Vertex(c_const_get("scale_renderx" .. i), c_const_get("scale_rendery" .. i))
			end
		gl.End()
	gl.EndList()
	c_const_set("scale_scrollSpeed", 0.5, 1)

	c_const_set("select_init", 0.25, 1)
	c_const_set("select_drop", 1.0, 1)
end

function gui_done()
	widgets = nil
end

local GENERIC = {}
local LABEL   = {}
local ACTION  = {}
local CYCLE   = {}
local INPUT   = {}
local KEY     = {}
local SCALE   = {}

local widget =
{
	new  = c_class_new,
	init = function (o)
		o.scale = 1
		o.color.r = c_const_get("label_r") o.altColor.r = c_const_get("label_r")
		o.color.g = c_const_get("label_g") o.altColor.g = c_const_get("label_g")
		o.color.b = c_const_get("label_b") o.altColor.b = c_const_get("label_b")
		o.color.a = c_const_get("label_a") o.altColor.a = c_const_get("label_a")
	end,
	type = GENERIC,

	p = tankbobs.m_vec2(),
	upperRightPos = tankbobs.m_vec2(),
	text = "",
	updateTextCallBack = nil,  -- This function called every frame.  If the function exists and returns a string, the widget's text will be set to string returned.

	scale = 0,
	color = {0, 0, 0, 0},
	altColor = {0, 0, 0, 0},
	bump = nil,

	setText = function (self, text)
		self.text = tostring(text)

		return self
	end,

	selectedCallback = nil,

	setSelectedCallback = function (self, f)
		self.selectedCallback = f

		return self
	end,

	m = {p = {}},

	selectable = false
}

local label =
{
	new  = c_class_new,
	type = LABEL,
	base = widget,

	selectable = false
}

local action =
{
	new  = c_class_new,
	type = ACTION,
	base = widget,

	actionCallBack = nil,  -- this is called with either actionCallBack(currentWidget, mouseX, mouseY) or actionCallBack(currentWidget, keyButton)

	selectable = true
}

local cycle =
{
	new  = c_class_new,
	type = CYCLE,
	base = widget,

	setCyclePos = function (self, pos)
		self.cyclePos = pos

		return self
	end,
	cycleCallBack = nil,  -- called with (currentWidget, elementString, elementIndex) when the user changes the current element in a cycle
	cycleList = {},  -- a table of strings
	cyclePos = 0,  -- which element of the table is currently selected (by key / index)

	selectable = true
}

local input =
{
	new  = c_class_new,
	type = INPUT,
	base = widget,

	setText = function (self, text)
		text = tostring(text)

		if #text >= 1 then
			text = text:sub(1, self.maxLength)
		end

		self.text = text
		self.inputText = text
		self.textPos = #text

		-- Don't call change callback
		--if self.textChangedCallBack then
			--self:textChangedCallBack(self, self.inputText)
		--end

		return self
	end,
	inputText = "",
	textChangedCallBack = nil,
	maxLength = 0,
	integerOnly = false,
	textPos = 0,

	selectable = true
}

local key =
{
	new  = c_class_new,
	type = KEY,
	base = widget,

	setKey = function (self, button)
		self.button = c_config_keyLayoutGet(button)
		if key then
			self.text = gui_char(button)
		else
			self.text = ""
		end

		--if self.keyChangedCallBack then
			--self:keyChangedCallBack(self, self.button)
		--end

		return self
	end,
	keyActive = false,  -- whether or not a key press will set this key
	keyChangedCallBack = nil,
	button = nil,

	selectable = true
}

local scale =
{
	new  = c_class_new,
	type = KEY,
	base = widget,

	setScalePos = function (self, pos)
		if pos < 0 then
			pos = 0
		elseif pos > 1 then
			pos = 1
		end

		self.scalePos = pos

		--if self.scaleChangedCallBack then
			--self:scaleChangedCallBack(self, self.scalePos)
		--end

		return self
	end,
	scalePos = 0,  -- 0-1
	scaleChangedCallBack = nil,
	scaleMouseOffset = 0,
	scaleActive = false,
	scaleLength = nil,

	selectable = true
}

function gui_finish()
	selected = nil
	widgets = {}
end

--[[--
-- * gui_addWidget returns a handle to the widget (strictly speaking, the widget itself) which can be used with callbacks
--]]--
function gui_addLabel(position, text, updateTextCallBack, scale, color_r, color_g, color_b, color_a, altColor_r, altColor_g, altColor_b, altColor_a)
	local label = label:new()

	label.type = LABEL
	label.selectable = false  -- labels aren't selectable

	label.p(position)
	label.upperRightPos(position)  -- pre-initialize upperRightPos to avoid issues
	label.text = text
	label.updateTextCallBack = updateTextCallBack
	label.color.r = color_r or c_const_get("label_r") label.altColor.r = altColor_r or c_const_get("label_r")
	label.color.g = color_g or c_const_get("label_g") label.altColor.g = altColor_g or c_const_get("label_g")
	label.color.b = color_b or c_const_get("label_b") label.altColor.b = altColor_b or c_const_get("label_b")
	label.color.a = color_a or c_const_get("label_a") label.altColor.a = altColor_a or c_const_get("label_a")
	label.scale = scale or label.scale

	table.insert(widgets, label)

	return label
end

function gui_addAction(position, text, updateTextCallBack, actionCallBack, scale, color_r, color_g, color_b, color_a, altColor_r, altColor_g, altColor_b, altColor_a)
	local action = action:new()

	action.type = ACTION
	action.selectable = true

	action.p(position)
	action.upperRightPos(position)  -- pre-initialize upperRightPos to avoid issues
	action.text = text
	action.updateTextCallBack = updateTextCallBack
	action.actionCallBack = actionCallBack
	action.color.r = color_r or c_const_get("action_r") action.altColor.r = altColor_r or c_const_get("actionSelected_r")
	action.color.g = color_g or c_const_get("action_g") action.altColor.g = altColor_g or c_const_get("actionSelected_g")
	action.color.b = color_b or c_const_get("action_b") action.altColor.b = altColor_b or c_const_get("actionSelected_b")
	action.color.a = color_a or c_const_get("action_a") action.altColor.a = altColor_a or c_const_get("actionSelected_a")
	action.scale = scale or action.scale

	table.insert(widgets, action)

	return action
end

function gui_addCycle(position, text, updateTextCallBack, cycleCallBack, cycleList, initialCycleIndex, scale, color_r, color_g, color_b, color_a, altColor_r, altColor_g, altColor_b, altColor_a)
	local cycle = cycle:new()

	cycle.type = CYCLE
	cycle.selectable = true

	cycle.p(position)
	cycle.upperRightPos(position)  -- pre-initialize upperRightPos to avoid issues
	cycle.text = text
	cycle.updateTextCallBack = updateTextCallBack
	cycle.cycleCallBack = cycleCallBack
	cycle.cycleList = cycleList
	cycle.cyclePos = initialCycleIndex
	cycle.color.r = color_r or c_const_get("cycle_r") cycle.altColor.r = altColor_r or c_const_get("cycleSelected_r")
	cycle.color.g = color_g or c_const_get("cycle_g") cycle.altColor.g = altColor_g or c_const_get("cycleSelected_g")
	cycle.color.b = color_b or c_const_get("cycle_b") cycle.altColor.b = altColor_b or c_const_get("cycleSelected_b")
	cycle.color.a = color_a or c_const_get("cycle_a") cycle.altColor.a = altColor_a or c_const_get("cycleSelected_a")
	cycle.scale = scale or cycle.scale

	table.insert(widgets, cycle)

	return cycle
end

function gui_addInput(position, text, updateTextCallBack, textChangedCallBack, integerOnly, maxLength, scale, color_r, color_g, color_b, color_a, altColor_r, altColor_g, altColor_b, altColor_a)
	local input = input:new()

	input.type = INPUT
	input.selectable = true

	input.p(position)
	input.upperRightPos(position)  -- pre-initialize upperRightPos to avoid issues
	input.text = text
	input.inputText = text
	input.textPos = #text
	input.updateTextCallBack = updateTextCallBack
	input.textChangedCallBack = textChangedCallBack
	input.integerOnly = integerOnly
	input.maxLength = maxLength
	input.color.r = color_r or c_const_get("input_r") input.altColor.r = altColor_r or c_const_get("inputSelected_r")
	input.color.g = color_g or c_const_get("input_g") input.altColor.g = altColor_g or c_const_get("inputSelected_g")
	input.color.b = color_b or c_const_get("input_b") input.altColor.b = altColor_b or c_const_get("inputSelected_b")
	input.color.a = color_a or c_const_get("input_a") input.altColor.a = altColor_a or c_const_get("inputSelected_a")
	input.scale = scale or input.scale

	table.insert(widgets, input)

	return input
end

function gui_addKey(position, text, updateTextCallBack, keyChangedCallBack, initialButton, scale, color_r, color_g, color_b, color_a, altColor_r, altColor_g, altColor_b, altColor_a)
	local key = key:new()

	key.type = KEY
	key.selectable = true

	key.p(position)
	key.upperRightPos(position)  -- pre-initialize upperRightPos to avoid issues
	key.text = text
	key.updateTextCallBack = updateTextCallBack
	key.keyChangedCallBack = keyChangedCallBack
	key.button = c_config_keyLayoutGet(initialButton)
	key.color.r = color_r or c_const_get("key_r") key.altColor.r = altColor_r or c_const_get("keySelected_r")
	key.color.g = color_g or c_const_get("key_g") key.altColor.g = altColor_g or c_const_get("keySelected_g")
	key.color.b = color_b or c_const_get("key_b") key.altColor.b = altColor_b or c_const_get("keySelected_b")
	key.color.a = color_a or c_const_get("key_a") key.altColor.a = altColor_a or c_const_get("keySelected_a")
	key.scale = scale or key.scale

	table.insert(widgets, key)

	return key
end

function gui_addScale(position, text, updateTextCallBack, scaleChangedCallBack, initialPos, length, scale_, color_r, color_g, color_b, color_a, altColor_r, altColor_g, altColor_b, altColor_a)
	local scale = scale:new()

	scale.type = SCALE
	scale.selectable = true

	scale.p(position)
	scale.upperRightPos(position)  -- pre-initialize upperRightPos to avoid issues
	scale.text = text
	scale.updateTextCallBack = updateTextCallBack
	scale.scaleChangedCallBack = scaleChangedCallBack
	scale.scalePos = initialPos
	scale.scaleLength = length or c_const_get("scale_width")
	scale.color.r = color_r or c_const_get("scale_r") scale.altColor.r = altColor_r or c_const_get("scaleSelected_r")
	scale.color.g = color_g or c_const_get("scale_g") scale.altColor.g = altColor_g or c_const_get("scaleSelected_g")
	scale.color.b = color_b or c_const_get("scale_b") scale.altColor.b = altColor_b or c_const_get("scaleSelected_b")
	scale.color.a = color_a or c_const_get("scale_a") scale.altColor.a = altColor_a or c_const_get("scaleSelected_a")
	scale.scale = scale_ or scale.scale

	table.insert(widgets, scale)

	return scale
end

local function gui_private_scale(scalar)
	return scalar / c_const_get("widget_length")
end

function gui_paint(d)
	for _, v in pairs(widgets) do
		local breaking = false repeat  -- ugly method of continue in lua
			local scalex, scaley = 1, 1
			local prefix, suffix = "", ""

			-- type specific stuff
			local switch = v.type
			if switch == nil then
			elseif switch == LABEL then
				scalex = c_const_get("label_scalex") scaley = c_const_get("label_scaley")
				prefix = c_const_get("label_prefix") suffix = c_const_get("label_suffix")
			elseif switch == ACTION then
				scalex = c_const_get("action_scalex") scaley = c_const_get("action_scaley")
				prefix = c_const_get("action_prefix") suffix = c_const_get("action_suffix")
			elseif switch == CYCLE then
				scalex = c_const_get("cycle_scalex") scaley = c_const_get("cycle_scaley")
				prefix = c_const_get("cycle_prefix") suffix = c_const_get("cycle_suffix")
				v.text = v.cycleList[v.cyclePos]
			elseif switch == INPUT then
				scalex = c_const_get("input_scalex") scaley = c_const_get("input_scaley")
				prefix = c_const_get("input_prefix") suffix = c_const_get("input_suffix")
				v.text = v.inputText:sub(1, v.textPos) .. c_const_get("input_posCharacter") .. v.inputText:sub(v.textPos + 1)
			elseif switch == KEY then
				scalex = c_const_get("key_scalex") scaley = c_const_get("key_scaley")
				prefix = c_const_get("key_prefix") suffix = c_const_get("key_suffix")
				if v.keyActive then
					v.text = gui_char(v.button) .. c_const_get("key_activeSuffix")
				else
					v.text = gui_char(v.button)
				end
			elseif switch == SCALE then
				-- handle scales quite differently since they aren't textual widgets
				if v.updateTextCallBack then
					local text = v:updateTextCallBack(d)

					if text and type(text) == "string" then
						v.text = text
					end
				end

				scalex = c_const_get("scale_scalex") scaley = c_const_get("scale_scaley")
				scalex = scalex * v.scale
				scaley = scaley * v.scale
				if v.bump then
					v.bump = v.bump - d * c_const_get("select_drop")

					if v.bump <= 0 then
						v.bump = nil
					else
						scalex = scalex * (1 + v.bump)
						scaley = scaley * (1 + v.bump)
					end
				end

				if selected == v then
					v.scalePos = v.scalePos + d * scroll * c_const_get("scale_scrollSpeed")

					if v.scalePos < 0 then
						v.scalePos = 0
					end
					if v.scalePos > 1 then
						v.scalePos = 1
					end

					if scroll ~= 0 then
						if v.scaleChangedCallBack then
							v:scaleChangedCallBack(v.scalePos)
						end
					end
				end

				v.upperRightPos(v.p.x + v.scaleLength, v.p.y + c_const_get("scale_height"))  -- set upperRightPos manually

				gl.PushMatrix()
					gl.Translate(v.p.x, v.p.y, 0)
					if selected == v then
						gl.Color(v.color.r, v.color.g, v.color.b, v.color.a)
						gl.TexEnv("TEXTURE_ENV_COLOR", v.color.r, v.color.g, v.color.b, v.color.a)
					else
						gl.Color(v.altColor.r, v.altColor.g, v.altColor.b, v.altColor.a)
						gl.TexEnv("TEXTURE_ENV_COLOR", v.altColor.r, v.altColor.g, v.altColor.b, v.altColor.a)
					end
					gl.PushMatrix()
						gl.Scale(scalex * v.scaleLength / c_const_get("scale_width"), scaley, 1)
						gl.CallList(scale_listBase)
					gl.PopMatrix()
					gl.Scale(scalex, scaley, 1)
					gl.Translate(v.scalePos * v.scaleLength, 0, 0)
					gl.CallList(scaleCenter_listBase)
				gl.PopMatrix()

				breaking = false break  -- continue
			end

			if v.updateTextCallBack then
				local text = v:updateTextCallBack(d)

				if text and type(text) == "string" then
					v.text = text
				end
			end

			scalex = scalex * v.scale
			scaley = scaley * v.scale

			if v.bump then
				v.bump = v.bump - d * c_const_get("select_drop")

				if v.bump <= 0 then
					v.bump = nil
				else
					scalex = scalex * (1 + v.bump)
					scaley = scaley * (1 + v.bump)
				end
			end

			local text = prefix .. v.text .. suffix

			if v ~= selected then
				local p = tankbobs.m_vec2(v.p)
				local decrement = v.upperRightPos.y - v.p.y + c_const_get("gui_vspacing")

				for _, vSub in pairs(tankbobs.t_explode(text, '\n')) do
					local oldR = tankbobs.m_vec2(v.upperRightPos)

					v.upperRightPos = tankbobs.r_drawString(vSub, p, v.color.r, v.color.g, v.color.b, v.color.a, gui_private_scale(scalex), gui_private_scale(scaley), false)
					if oldR.y > v.upperRightPos.y then
						v.upperRightPos(oldR)
					end

					p.y = p.y - decrement
				end
			else
				-- draw with altColor
				local p = tankbobs.m_vec2(v.p)
				local decrement = v.upperRightPos.y - v.p.y + c_const_get("gui_vspacing")

				for _, vSub in pairs(tankbobs.t_explode(text, '\n')) do
					local oldR = tankbobs.m_vec2(v.upperRightPos)

					v.upperRightPos = tankbobs.r_drawString(vSub, v.p, v.altColor.r, v.altColor.g, v.altColor.b, v.altColor.a, gui_private_scale(scalex), gui_private_scale(scaley), false)
					if oldR.y > v.upperRightPos.y then
						v.upperRightPos(oldR)
					end

					p.y = p.y - decrement
				end
			end
		until true if breaking then break end
	end
end

local function gui_private_selected(selection)
	selected = selection

	selected.bump = c_const_get("select_init")

	if selected.selectedCallback then
		selected:selectedCallback()
	end
end

-- returns true when the pressed key should not be handled further than the input widget
local function gui_private_inputKey(button)
	if button == 276 or button == c_config_get("client.key.left") then  -- left
		if selected.textPos > 0 then
			selected.textPos = selected.textPos - 1
		end

		return true
	elseif button == 275 or button == c_config_get("client.key.right") then  -- right
		if selected.textPos < #selected.inputText then
			selected.textPos = selected.textPos + 1
		end

		return true
	elseif button == 8 then  -- backspace
		if selected.textPos > 0 then
			selected.inputText = selected.inputText:sub(1, selected.textPos - 1) .. selected.inputText:sub(selected.textPos + 1, -1)
			selected.textPos = selected.textPos - 1

			if selected.textChangedCallBack then
				selected:textChangedCallBack(selected.inputText)
			end
		end

		return true
	elseif button == 127 then  -- delete
		if selected.textPos < #selected.inputText then
			selected.inputText = selected.inputText:sub(1, selected.textPos) .. selected.inputText:sub(selected.textPos + 2, -1)

			if selected.textChangedCallBack then
				selected:textChangedCallBack(selected.inputText)
			end
		end

		return true
	elseif button == 278 then  -- home
		selected.textPos = 0

		return true
	elseif button == 279 then  -- end
		selected.textPos = #selected.inputText

		return true
	elseif button >= 32 and button < 127 then
		if (#selected.inputText < selected.maxLength) and (not selected.integerOnly or (button >= string.byte('0') and button <= string.byte('9'))) then
			local add = string.char(button)

			if shift then
				add = add:upper()
				if add == ";" then
					add = ":"
				elseif add == "1" then
					add = "!"
				elseif add == "2" then
					add = "@"
				elseif add == "3" then
					add = "#"
				elseif add == "4" then
					add = "$"
				elseif add == "5" then
					add = "%"
				elseif add == "6" then
					add = "^"
				elseif add == "7" then
					add = "&"
				elseif add == "8" then
					add = "("
				elseif add == "9" then
					add = ")"
				elseif add == "\\" then
					add = "|"
				elseif add == "/" then
					add = "?"
				elseif add == "[" then
					add = "{"
				elseif add == "]" then
					add = "}"
				elseif add == "," then
					add = "<"
				elseif add == "." then
					add = ">"
				elseif add == "'" then
					add = "\""
				end
			end
			selected.inputText = selected.inputText:sub(1, selected.textPos) .. add .. selected.inputText:sub(selected.textPos + 1, -1)
			selected.textPos = selected.textPos + 1

			if selected.textChangedCallBack then
				selected:textChangedCallBack(selected.inputText)
			end
		end

		return true
	else
		--if c_const_get("debug") then
			--io.stderr:write("Warning: unrecognized key pressed: '", tostring(button), "' (", tostring(char(button)), ")\n")
		--end
	end
end

function gui_click(button, pressed, x, y)
	if button == 1 then  -- left mouse button
		if pressed then
			for _, v in pairs(widgets) do
				if (x >= v.p.x and x <= v.upperRightPos.x and y >= v.p.y and y <= v.upperRightPos.y) or v.type == SCALE then
					local switch = v.type
					if switch == nil then
					elseif switch == LABEL then
					elseif switch == ACTION then
						if v.actionCallBack then
							v:actionCallBack(x, y)
						end
					elseif switch == CYCLE then
						if v.cycleList[v.cyclePos + 1] then
							-- cycle through
							v.cyclePos = v.cyclePos + 1

							if v.cycleCallBack then
								v:cycleCallBack(v.cycleList[v.cyclePos], v.cyclePos)
							end
						else
							-- back to beginning
							v.cyclePos = 1

							if v.cycleCallBack then
								v:cycleCallBack(v.cycleList[v.cyclePos], v.cyclePos)
							end
						end
					elseif switch == INPUT then
					elseif switch == KEY then
						v.keyActive = true
					elseif switch == SCALE then
						local centerStart, centerEnd

						centerStart = v.p.x + v.scalePos * v.scaleLength * v.scale
						centerEnd = centerStart + c_const_get("scaleCenter_width")

						if x >= centerStart and x <= centerEnd and y >= v.p.y and y <= v.p.y + c_const_get("scaleCenter_height") then
							v.scaleMouseOffset = x - centerStart
							v.scaleActive = true
						end
					end
				end
			end
		else
			for _, v in pairs(widgets) do
				if v.type == SCALE then
					v.scaleActive = false
				end
			end
		end
	end
end

function gui_mouse(x, y, xrel, yrel)
	if selected and selected.type == SCALE and selected.scaleActive then
		selected.scalePos = (x - selected.p.x) / (selected.scale * selected.scaleLength)

		if selected.scalePos < 0 then
			selected.scalePos = 0
		end
		if selected.scalePos > 1 then
			selected.scalePos = 1
		end

		if selected.scaleChangedCallBack then
			selected:scaleChangedCallBack(selected.scalePos)
		end

		return
	end

	for _, v in pairs(widgets) do
		if v.selectable and v ~= selected then
			if x >= v.p.x and x <= v.upperRightPos.x and y >= v.p.y and y <= v.upperRightPos.y then
				gui_private_selected(v)

				return
			end
		end
	end
end

function gui_button(button, pressed)
	if selected and selected.type == KEY and selected.keyActive then
		if pressed then
			selected.keyActive = false
			if button == 8 then
				-- BACKSPACE
				selected.button = nil
			elseif button == 27 then
				-- ESCAPE
			else
				selected.button = button
			end

			if selected.keyChangedCallBack then
				selected:keyChangedCallBack(selected.button)
			end
		end

		return true
	elseif button == 0x0D or button == c_config_get("client.key.select") then
		-- ENTER

		if pressed then
			if selected then
				local switch = selected.type
				if switch == nil then
				elseif switch == LABEL then
				elseif switch == ACTION then
					if selected.actionCallBack then
						selected:actionCallBack(button)
					end
				elseif switch == CYCLE then
					-- same as clicking
					if selected.cycleList[selected.cyclePos + 1] then
						-- cycle through
						selected.cyclePos = selected.cyclePos + 1

						if selected.cycleCallBack then
							selected:cycleCallBack(selected.cycleList[selected.cyclePos], selected.cyclePos)
						end
					else
						-- back to beginning
						selected.cyclePos = 1

						if selected.cycleCallBack then
							selected:cycleCallBack(selected.cycleList[selected.cyclePos], selected.cyclePos)
						end
					end
				elseif switch == INPUT then
				elseif switch == KEY then
					selected.keyActive = true
				elseif switch == SCALE then
				end
			end
		end

	elseif button == 273 or button == c_config_get("client.key.up") then
		-- UP

		if pressed then
			local y, x
			local selection

			if not selected then
				-- select the bottom-most widget

				for _, v in pairs(widgets) do
					if v.selectable then
						if not y or v.p.y <= y then
							selection = v
							y, x = v.p.y, v.p.x
						end
					end
				end

				for _, v in pairs(widgets) do
					if v.selectable then
						if v.p.y == y and v.p.x > x then
							selection = v
							x = v.p.x
						end
					end
				end

				if selection then
					gui_private_selected(selection)
				end

				return
			end

			-- a widget is selected, so select the previous if it exists

			for _, v in pairs(widgets) do
				if v.selectable and v ~= selected then
					if v.p.y == selected.p.y and (not x or v.p.x >= x) and v.p.x <= selected.p.x then
						selection = v
						y, x = v.p.y, v.p.x
					end
				end
			end

			for _, v in pairs(widgets) do
				if v.selectable and v ~= selected then
					if (not y or v.p.y <= y) and v.p.y > selected.p.y then
						selection = v
						y, x = v.p.y, v.p.x
					end
				end
			end

			for _, v in pairs(widgets) do
				if v.selectable and v ~= selected then
					if v.p.y == y and v.p.x > x then
						selection = v
						x = v.p.x
					end
				end
			end

			if selection then
				gui_private_selected(selection)
			end
		end

	elseif button == 274 or button == c_config_get("client.key.down") then
		-- DOWN

		if pressed then
			local y, x
			local selection

			if not selected then
				-- select upper-most widget

				for _, v in pairs(widgets) do
					if v.selectable then
						if not y or v.p.y >= y then
							selection = v
							y, x = v.p.y, v.p.x
						end
					end
				end

				for _, v in pairs(widgets) do
					if v.selectable then
						if v.p.y == y and v.p.x < x then
							selection = v
							x = v.p.x
						end
					end
				end

				if selection then
					gui_private_selected(selection)
				end

				return
			end

			-- a widget is selected, so select the next one if it exists

			for _, v in pairs(widgets) do
				if v.selectable and v ~= selected then
					if v.p.y == selected.p.y and (not x or v.p.x <= x) and v.p.x >= selected.p.x then
						selection = v
						y, x = v.p.y, v.p.x
					end
				end
			end

			for _, v in pairs(widgets) do
				if v.selectable and v ~= selected then
					if (not y or v.p.y >= y) and v.p.y < selected.p.y then
						selection = v
						y, x = v.p.y, v.p.x
					end
				end
			end

			for _, v in pairs(widgets) do
				if v.selectable and v ~= selected then
					if v.p.y == y and v.p.x < x then
						selection = v
						x = v.p.x
					end
				end
			end

			if selection then
				gui_private_selected(selection)
			end
		end

	elseif selected and selected.type == INPUT then
		if pressed then
			return gui_private_inputKey(button)
		end

		return true

	elseif button == 276 or button == c_config_get("client.key.left") then
		-- LEFT

		if selected then
			local switch = selected.type
			if switch == nil then
			elseif switch == LABEL then
			elseif switch == ACTION then
			elseif switch == CYCLE then
				if pressed then
					if selected.cycleList[selected.cyclePos - 1] then
						selected.cyclePos = selected.cyclePos - 1

						if selected.cycleCallBack then
							selected:cycleCallBack(selected.cycleList[selected.cyclePos], selected.cyclePos)
						end
					end
				end
			elseif switch == INPUT then
			elseif switch == KEY then
			elseif switch == SCALE then
				if pressed then
					scroll = -1
				elseif scroll <= 0 then
					scroll = 0
				end
			end
		end

	elseif button == 275 or button == c_config_get("client.key.right") then
		-- RIGHT

		if selected then
			local switch = selected.type
			if switch == nil then
			elseif switch == LABEL then
			elseif switch == ACTION then
			elseif switch == CYCLE then
				if pressed then
					if selected.cycleList[selected.cyclePos + 1] then
						selected.cyclePos = selected.cyclePos + 1

						if selected.cycleCallBack then
							selected:cycleCallBack(selected.cycleList[selected.cyclePos], selected.cyclePos)
						end
					end
				end
			elseif switch == INPUT then
			elseif switch == KEY then
			elseif switch == SCALE then
				if pressed then
					scroll = 1
				elseif scroll >= 0 then
					scroll = 0
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
		return "Backspace", "Backspace"
	elseif c == 0x09 then
		return "Tab", "Tab"
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
		return "Escape", "Escape"
	elseif c == 0x1C then
		return "?", "?"
	elseif c == 0x1D then
		return "?", "?"
	elseif c == 0x1E then
		return "?", "?"
	elseif c == 0x1F then
		return "?", "?"
	elseif c == 0x20 then
		return "Space", "Space"
	elseif c == 0x21 then
		return "!", "!"
	elseif c == 0x22 then
		return "\"", "\""
	elseif c == 0x23 then
		return "#", "#"
	elseif c == 0x24 then
		return "$", "$"
	elseif c == 0x25 then
		return "%", "%"
	elseif c == 0x26 then
		return "&", "&"
	elseif c == 0x27 then
		return "'", "'"
	elseif c == 0x28 then
		return "(", "("
	elseif c == 0x29 then
		return ")", ")"
	elseif c == 0x2A then
		return "*", "*"
	elseif c == 0x2B then
		return "+", "+"
	elseif c == 0x2C then
		return ",", ","
	elseif c == 0x2D then
		return "-", "-"
	elseif c == 0x2E then
		return ".", "."
	elseif c == 0x2F then
		return "/", "/"
	elseif c == 0x30 then
		return "0", "0"
	elseif c == 0x31 then
		return "1", "1"
	elseif c == 0x32 then
		return "2", "2"
	elseif c == 0x33 then
		return "3", "3"
	elseif c == 0x34 then
		return "4", "4"
	elseif c == 0x35 then
		return "5", "5"
	elseif c == 0x36 then
		return "6", "6"
	elseif c == 0x37 then
		return "7", "7"
	elseif c == 0x38 then
		return "8", "8"
	elseif c == 0x39 then
		return "9", "9"
	elseif c == 0x3A then
		return ":", ":"
	elseif c == 0x3B then
		return ";", ";"
	elseif c == 0x3C then
		return "<", "<"
	elseif c == 0x3D then
		return "=", "="
	elseif c == 0x3E then
		return ">", ">"
	elseif c == 0x3F then
		return "?", "?"
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
		return "[", "["
	elseif c == 0x5C then
		return "\\", "\\"
	elseif c == 0x5D then
		return "]", "]"
	elseif c == 0x5E then
		return "^", "^"
	elseif c == 0x5F then
		return "_", "_"
	elseif c == 0x60 then
		return "`", "`"
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
	elseif c == 8 then
		return "Backspace", "Backspace"
	elseif c == 9 then
		return "Tab", "Tab"
	elseif c == 39 then
		return "'", "Quote"
	elseif c == 256 then
		return "KP_0", "Keypad 0"
	elseif c == 257 then
		return "KP_1", "Keypad 1"
	elseif c == 258 then
		return "KP_2", "Keypad 2"
	elseif c == 259 then
		return "KP_3", "Keypad 3"
	elseif c == 260 then
		return "KP_4", "Keypad 4"
	elseif c == 261 then
		return "KP_5", "Keypad 5"
	elseif c == 262 then
		return "KP_6", "Keypad 6"
	elseif c == 263 then
		return "KP_7", "Keypad 7"
	elseif c == 264 then
		return "KP_8", "Keypad 8"
	elseif c == 265 then
		return "KP_9", "Keypad 9"
	elseif c == 266 then
		return "KP .", "Keypad Period"
	elseif c == 267 then
		return "KP /", "Keypad Divide"
	elseif c == 268 then
		return "KP *", "Keypad Multyply"
	elseif c == 269 then
		return "KP -", "Keypad Minus"
	elseif c == 270 then
		return "KP +", "Keypad Plus"
	elseif c == 271 then
		return "KP_ENTER", "Keypad Enter"
	elseif c == 272 then
		return "KP =", "Keypad Equals"
	elseif c == 273 then
		return "Up", "Up"
	elseif c == 274 then
		return "Down", "Down"
	elseif c == 275 then
		return "Right", "Right"
	elseif c == 276 then
		return "Left", "Left"
	elseif c == 277 then
		return "Insert", "Insert"
	elseif c == 278 then
		return "Home", "Home"
	elseif c == 279 then
		return "End", "End"
	elseif c == 280 then
		return "Page Up", "Page Up"
	elseif c == 281 then
		return "Page Down", "Page Down"
	elseif c == 282 then
		return "F1", "F1"
	elseif c == 283 then
		return "F2", "F2"
	elseif c == 284 then
		return "F3", "F3"
	elseif c == 285 then
		return "F4", "F4"
	elseif c == 286 then
		return "F5", "F5"
	elseif c == 287 then
		return "F6", "F6"
	elseif c == 288 then
		return "F7", "F7"
	elseif c == 289 then
		return "F8", "F8"
	elseif c == 290 then
		return "F9", "F9"
	elseif c == 291 then
		return "F10", "F10"
	elseif c == 292 then
		return "F11", "F11"
	elseif c == 293 then
		return "F12", "F12"
	elseif c == 294 then
		return "F13", "F13"
	elseif c == 295 then
		return "F14", "F14"
	elseif c == 296 then
		return "F15", "F15"
	elseif c == 300 then
		return "NumLock", "NumLock"
	elseif c == 301 then
		return "CapsLock", "CapsLock"
	elseif c == 302 then
		return "ScrollLock", "ScrollLock"
	elseif c == 303 then
		return "RShift", "Right Shift"
	elseif c == 304 then
		return "LShift", "Left Shift"
	elseif c == 305 then
		return "RCtrl", "Right Control"
	elseif c == 306 then
		return "LCtrl", "Left Control"
	elseif c == 307 then
		return "RAlt", "Right Alt"
	elseif c == 308 then
		return "LAlt", "Left Alt"
	elseif c == 309 then
		return "RMeta", "Right Meta"
	elseif c == 310 then
		return "LMeta", "Left Meta"
	elseif c == 311 then
		return "RSuper", "Right Super"
	elseif c == 312 then
		return "LSuper", "Left Super"
	elseif c == 313 then
		return "Mode", "Mode"
	elseif c == 314 then
		return "Compose", "Compose"
	elseif c == 315 then
		return "Help", "Help"
	elseif c == 316 then
		return "Print", "Print"
	elseif c == 317 then
		return "SysReq", "System Request"
	elseif c == 318 then
		return "Break", "Break"
	elseif c == 319 then
		return "Menu", "Menu"
	elseif c == 320 then
		return "Power", "Power"
	elseif c == 321 then
		return "Euro", "Euro"
	elseif c == 322 then
		return "Undo", "Undo"
	else
		return "?", "?"
	end
end
