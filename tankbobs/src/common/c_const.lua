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
c_const.lua

(semi-)constant data
--]]

function c_const_init()
	c_const_init = nil

	local const = {}

	function c_const_get(k)
		if not const[k] then
			return nil
		end

		-- return a proxy table so that the real table doesn't change (the clone also handles sub-tables)
		if type(const[k]["v"]) == "table" then
			local t = {}
			common_clone(const[k]["v"], t)
			return t
		else
			return const[k]["v"]
		end
	end

	function c_const_set(k, v, c)
		if type(k) ~= "string" then
			error("attempt to set constant with non-string key" .. type(k))
		end

		if c_const_get(k) == nil then
			const[k] = {}
			const[k]["v"] = v
			const[k]["c"] = 0
			if c ~= nil and tonumber(c) then
				const[k]["c"] = tonumber(c)
			end
		--[[
		elseif c~= nil and tonumber(c) then
			error("attempt to change constant changes and constant '" .. tostring(k) .. "' from '" .. tostring(const_get(k)) .. "' to '" .. tostring(v) .. "'")
		--]]
		elseif const[k]["c"] <= 0 and const[k]["c"] ~= -1 then
			error("attempt to change constant '" .. tostring(k) .. "' from '" .. tostring(const_get(k)) .. "' to '" .. tostring(v) .. "'")
		else
			if const[k]["c"] ~= -1 then
				const[k]["c"] = const[k]["c"] - 1
			end

			const[k]["v"] = v
		end
	end
end

function c_const_done()
	c_const_done = nil
end
