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
c_const.lua

(semi-)constant data
--]]

function c_const_init()
	c_const_init = nil

	local clone = tankbobs.t_clone

	local const = {}

	function c_const_get(k)
		local cst = const

		if not cst[k] then
			return nil
		end

		-- return a proxy table so the real table doesn't change (the clone also handles sub-tables)
		if type(cst[k][1]) == "table" then
			local t = {}
			clone(true, cst[k][1], t)
			return t
		else
			return cst[k][1]
		end
	end

	function c_const_set(k, v, c)
		if type(k) ~= "string" then
			error("attempt to set constant with non-string key" .. type(k))
		end

		if c_const_get(k) == nil then
			const[k] = {}
			const[k][1] = v
			const[k][2] = 0
			if c ~= nil and tonumber(c) then
				const[k][2] = tonumber(c)
			end
		elseif const[k][2] <= 0 and const[k][2] ~= -1 then
			--if c_const_get("const_setError") then
				--error("attempt to change constant '" .. tostring(k) .. "' from '" .. tostring(c_const_get(k)) .. "' to '" .. tostring(v) .. "'")
			--end
			if c_const_get("debug") then
				io.stderr:write("Warning: attempt to change constant '" .. tostring(k) .. "' from '" .. tostring(c_const_get(k)) .. "' to '" .. tostring(v) .. "'\n")
			end
		else
			if const[k][2] ~= -1 then
				const[k][2] = const[k][2] - 1
			end

			const[k][1] = v
		end
	end

	c_const_set("const_setError", true, -1)  -- error by default
end

function c_const_done()
	c_const_done = nil
end
