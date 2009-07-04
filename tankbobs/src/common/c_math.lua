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

function c_math_init()
end

function c_math_done()
end

-- 2d math

function c_math_radians(degrees)
	return degrees * math.pi / 180
end

function c_math_degrees(radians)
	return radians * 180 / math.pi
end

-- NOTE: This class is slow and creates much garbage.  Use the C implementation of tankbobs.m_vec2 instead

c_math_vec2 =
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
		o.i = self
		o.vec2 = true
		o.self = {}  -- initialize the values
		o.self.x, o.self.y, o.self.R, o.self.t = 0, 0, 0, 0  -- initialize the values
		return o
	end,
	-- never call vx, etc. directly.  use v.x
	vx = function (self, v)
		if v then
			self.self.x = v
			-- calculate polar coordinates and return
			self.self.R = math.sqrt(self.self.x^2 + self.self.y^2)
			self.self.t = math.atan(self.self.y / self.self.x)
			if self.self.x < 0 and self.self.y < 0 then
				self.self.t = self.self.t c_math_radians(180)
			elseif self.self.x < 0 then
				self.self.t = self.self.t c_math_radians(90)
			elseif self.self.y < 0 then
				self.self.t = self.self.t c_math_radians(270)
			end
			return self.self.x
		else
			return self.self.x
		end
	end,
	vy = function (self, v)
		if v then
			self.self.y = v
			-- calculate polar coordinates and return
			self.self.R = math.sqrt(self.self.x^2 + self.self.y^2)
			self.self.t = math.atan(self.self.y / self.self.x)
			if self.self.x < 0 and self.self.y < 0 then
				self.self.t = self.self.t c_math_radians(180)
			elseif self.self.x < 0 then
				self.self.t = self.self.t c_math_radians(90)
			elseif self.self.y < 0 then
				self.self.t = self.self.t c_math_radians(270)
			end
			return self.self.y
		else
			return self.self.y
		end
	end,
	vR = function (self, v)
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
	vt = function (self, v)
		if v then
			self.self.t = v
			-- calculate rectangular coordinates and return
			self.self.x = self.self.R * math.cos(self.self.t)
			self.self.y = self.self.R * math.sin(self.self.t)
			return self.self.t
		else
			return self.self.t
		end
	end,
	unify = function (self)
		self:R(1)
	end,
	normalize = function (self)
		self:R(1)
	end,
	add = function (a, b)
		a:vx(a:vx() + b:vx())
		a:vy(a:vy() + b:vy())
	end,
	sub = function (a, b)
		a:x(va:x() - b:vx())
		a:y(va:y() - b:vy())
	end,
	mul = function (a, b)  -- multiply by scalar
		a:vx(a:vx() * b)
		a:vy(a:vy() * b)
	end,
	div = function (a, b)
		a:vx(a:vx() / b)
		a:vy(a:vy() / b)
	end,
	inv = function (self)
		self:vx(-self:vx())
		self:vy(-self:vy())
	end,
	unit = function (self)
		local r = c_math_vec2:new()
		r:vx(self:vx())
		r:vy(self:vy())
		r:R(1)
		return r
	end,
	__add = function (a, b)
		local r = c_math_vec2:new()
		r:vx(a:vx() + b:vx())
		r:vy(a:vy() + b:vy())
		return r
	end,
	__mul = function (a, b)
		if type(b) == "number" then
			-- scalar multiplication
			local r = c_math_vec2:new()
			r:vx(a:vx() * b)
			r:vy(a:vy() * b)
			return r
		elseif type(a) == "number" then
			-- scalar multiplication
			local r = c_math_vec2:new()
			r:vx(a * b:vx())
			r:vy(a * b:vy())
			return r
		else
			-- the dot product
			return a:vx() * b:vx() + a:vy() * b:vy()
		end
	end,
	__div = function (a, b)
		local r = c_math_vec2:new()
		r:vx(a:vx() / b)
		r:vy(a:vy() / b)
		return r
	end,
	__sub = function (a, b)
		local r = c_math_vec2:new()
		r:vx(a:vx() - b:vx())
		r:vy(a:vy() - b:vy())
		return r
	end,
	__unm = function (a)
		local r = c_math_vec2:new()
		r:vx(-a:vx())
		r:vy(-a:vy())
		return r
	end,
	__len = function (self)
		-- returns a number, not a vector
		return self:vR()
	end,
	__eq = function (a, b)
		return a:vx() == b:vx() and a:vy() == b:vy()
	end,
	__index = function (self, key)
		-- allow syntax for vector.x = 0, etc
		if key == "x" then
			return self:vx(value)
		elseif key == "y" then
			return self:vy(value)
		elseif key == "R" then
			return self:vR(value)
		elseif key == "t" then
			return self:vt(value)
		elseif type(rawget(self, "i")) == "table" then
			return rawget(rawget(self, "i"), key)
		end
	end,
	__newindex = function (self, key, value)
		-- allow syntax for vector.x = 0, etc
		if key == "x" then
			return self:vx(value)
		elseif key == "y" then
			return self:vy(value)
		elseif key == "R" then
			return self:vR(value)
		elseif key == "t" then
			return self:vt(value)
		else
			rawset(self, key, value)
		end
	end,
	normalof = function (self)
		local r = c_math_vec2:new()
		r:vx(-self:vy())
		r:vy(self:vx())
		r:unify(1)
		return r;
	end,
	__call = function (self, x, y)
		-- rectangular coordinates
		-- an argument check might be good here if it does't impede performance
		if y then
			-- set rectangular coordinates
			self:vx(x)
			self:vy(y)
		elseif x then
			-- assignment
			self:vx(x:vx())
			self:vy(x:vy())
		end
	end,
	project = function (a, b)
		-- r = (-a * b) * b
		local r = (-a * b) * b
		return r;
	end
}

function c_math_edge(l1p1, l1p2, l2p1, l2p2) -- line1point1, ...
	error("c_math_edge: no Lua implementation")
end

function c_math_polygon(p1, p2)
	error("c_math_edge: no Lua implementation")
end

-- example_vector = c_math_vec2:new()
-- example_vector(3, 4)
-- example_vector.x = 5
-- other_vector = c_math_vec2:new()
-- other_vector(example_vector)
