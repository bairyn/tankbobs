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
c_class.lua

Object orientation

To make a class, add "new = c_class_new" to a table
--]]

local tankbobs
local t_t_clone

function c_class_init()
	tankbobs = _G.tankbobs
	t_t_clone = _G.tankbobs.t_clone
end

function c_class_done()
end

function c_class_new(self, o, base)
	o = o or {}

	if base then
		tankbobs.t_clone(true, base or _G[base], o)
	elseif self.base then
		if not self.base then
			self.base = _G[self.base]
		end

		t_t_clone(true, self.base, o)
		setmetatable(self, {__index = self.base or _G[self.base]})
	end

	t_t_clone(true, self, o)
	setmetatable(o, {__index = self})

	-- call init if it exists (can be inherited)
	if self.init then
		self.init(o)
	end

	if not self.type then
		self.type = {}
	end

	o.type = self.type

	return o, o.type
end
class_new = c_class_new
new       = c_class_new

function c_class_copy(from, to)
	to = to or {}

	t_t_clone(true, from, to)

	return to
end
class_copy = c_class_copy
copy       = c_class_copy
