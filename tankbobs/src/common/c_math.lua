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
math.lua

math
--]]

-- 2d math

function c_radians(degrees)
	return degrees * 180 / math.pi
end

function c_degrees(radians)
	return radians * math.pi / 180
end

c_vec2 =
{
	self =
	{
		-- these are stored as radians
		x,
		y,
		R,
		t,
	},
	new = function (self, o)
		o = o or {}  --  create table if user does not provide one
		setmetatable(o, self)
		self.__index = self
		return o
	end,
	x = function (self, v)
		if v then
			self.self.x = v
			-- calculate polar coordinates and return
			self.self.R = math.sqrt(self.self.x^2 + self.self.y^2)
			self.self.t = math.atan(self.self.y / self.self.x)
			return self.self.x
		else
			return self.self.x
		end
	end,
	y = function (self, v)
		if v then
			self.self.y = v
			-- calculate polar coordinates and return
			self.self.R = math.sqrt(self.self.x^2 + self.self.y^2)
			self.self.t = math.atan(self.self.y / self.self.x)
			return self.self.y
		else
			return self.self.y
		end
	end,
	R = function (self, v)
		if v then
			self.self.R = v
			-- calculate rectangular coordinates and return
			self.self.x = self.self.R * math.cos(self.self.t)
			self.self.y = self.self.R * math.sin(self.self.t)
			return self.self.R
		else
			return self.self.R
		end
	end,
	t = function (self, v)
		if v then
			self.self.t = v
			-- calculate rectangular coordinates and return
			return self.self.t
		else
			return self.self.t
		end
	end,
	unify = function (self)
		self:R(1)
	end,
	add = function (a, b)
		a:x(a:x() + b:x())
		a:y(a:y() + b:y())
	end,
	sub = function (a, b)
		a:x(a:x() - b:x())
		a:y(a:y() - b:y())
	end,
	inv = function (self)
		self:x(-self:x())
		self:y(-self:y())
	end,
	unit = function (self)
		r = c_vec2:new()
		r:x(self:x())
		r:y(self:y())
		r:R(1)
		return r
	end,
	__add = function (a, b)
		r = c_vec2:new()
		r:x(a:x() + b:x())
		r:y(a:y() + b:y())
		return r
	end,
	__sub = function (a, b)
		r = c_vec2:new()
		r:x(a:x() - b:x())
		r:y(a:y() - b:y())
		return r
	end,
	__unm = function (a)
		r = c_vec2:new()
		r:x(-a:x())
		r:y(-a:y())
		return r
	end,
	__len = function (self)
		-- returns a number, not a vector
		return self:R()
	end,
	__eq = function (a, b)
		return a:x() == b:x() and a:y() == b:y()
	end,
	__newindex = function (self, key, value)
		-- allow syntax for vector.x = 0, etc
		if key == "x" then
			self:x(value)
		elseif key == "y" then
			self:y(value)
		elseif key == "R" then
			self:R(value)
		elseif key == "t" then
			self:t(value)
		end
	end,
	__call = function (self, x, y)
		-- rectangular coordinates
		-- an argument check might be good here if it does't impede performance
		self:x(x)
		self:y(y)
	end
}

-- example_vector = c_vec2:new()
-- example_vector.x(2.5)
-- example_vector(3, 4)
-- example_vector.x = 3
