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
c_config.lua

Base configuration settings - mods should not need to redefine anything here
all keys should be strings.  Numbers and other types are untested
--]]

local t_t_clone

function c_config_init()
	c_config_init = nil

	t_t_clone = _G.tankbobs.t_clone

	c_module_load "lxp"
	c_module_load "lxp.lom"

	local config
	local cheats = {}

	local cheatsEnabled = false

	local function trim(v)
		local oldV = v
		if type(v) == "string" then
			v = v:match("^[\n\t ]*([%d%.]+)[\n\t ]*$")
			if v == nil or v:match("^.*%..*%..*$") then
				v = oldV
				v = string.match(v:lower(), "^[\n\t ]*false[\n\t ]*$")
				if v == nil then
					v = oldV
					v = string.match(v:lower(), "^[\n\t ]*true[\n\t ]*$")
					if v == nil then
						v = oldV
						v = string.match(v:lower(), "^[\n\t ]*nil[\n\t ]*$")
						if v == nil then
							v = oldV
						else
							v = nil
						end
					else
						v = true
					end
				else
					v = false
				end
			else
				if(tonumber(v)) then
					v = tonumber(v)
				else
					v = oldV
				end
			end
		end

		return v
	end

	local function c_config_init(defaults)
		-- this function can be called multiple times

		config = {}

		local function parse(data, key)
			key = key or ""

			if key == "config" then
				key = ""
			end

			local empty = true
			local string = ""

			if not data.tag then
				error("XML missing tag")
			end

			for _, v in ipairs(data) do
				if type(v) == "table" then
					empty = false

					parse(v, key .. (key == "" and '' or '.') .. data.tag)
				else
					string = string .. tostring(v)
				end
			end

			if empty then
				c_config_set(key .. (key == "" and '' or '.') .. data.tag, string)
			end
		end

		-- default configuration

		local oldCheatsEnabled = cheatsEnabled
		cheatsEnabled = true

		local fin = tankbobs.fs_openRead(c_const_get("data_conf"))

		local data, err = lxp.lom.parse(tankbobs.fs_getStr(fin, nil, true))
		tankbobs.fs_close(fin)

		if not data then
			stderr:write("Warning: cannot parse default configuration: - ", err, '\n')
		elseif data.tag then
			parse(data)
		end

		cheatsEnabled = oldCheatsEnabled

		if defaults then
			c_files_configLoaded()

			return
		end

		-- user configuration

		if tankbobs.fs_fileExists(c_const_get("user_conf")) then
			local fin = tankbobs.fs_openRead(c_const_get("user_conf"))
			local data, err = lxp.lom.parse(tankbobs.fs_getStr(fin, nil, true))
			tankbobs.fs_close(fin)

			if not data then
				stderr:write("Warning: cannot parse user configuration: - ", err, '\n')
			else
				parse(data)
			end
		end

		c_files_configLoaded()
	end

	function c_config_keyLayoutGet(key)
		--[[
		for _, v in pairs(c_const_get("keyLayout_" .. c_config_get("client.keyLayout"))) do
			if v.from == key then
				return v.to
			end
		end
		--]]

		local layout = c_const_get("keyLayout_" .. c_config_get("client.keyLayout") .. "To")

		return (layout and layout[key]) or tonumber(key) or -1
	end

	function c_config_keyLayoutSet(key)
		--[[
		for _, v in pairs(c_const_get("keyLayout_" .. c_config_get("client.keyLayout"))) do
			if v.to == key then
				return v.from
			end
		end
		--]]

		local layout = c_const_get("keyLayout_" .. c_config_get("client.keyLayout") .. "From")

		return (layout and layout[key]) or tonumber(key) or -1
	end

	function c_config_defaults()
		c_config_init(true)
	end

	function c_config_set(key, value)
		if cheats[key] and not cheatsEnabled then
			if server then
				s_printnl("c_config_set: ", key, " is cheat protected")
			else
				stdout:write("c_config_set: ", key, " is cheat protected")
			end

			return
		end

		if type(value) == "table" then
			config[key] = tankbobs.t_clone(value)
		else
			config[key] = value
		end
	end

	function c_config_get(key, noError)
		if config[key] == nil and not noError then
			if debug then
				print(debug.traceback())
			end

			error("c_config_get: config doesn't exist: " .. key)
		elseif type(config[key]) == "table" then
			return t_t_clone(config[key])
		else
			return trim(config[key])
		end
	end

	function c_config_cheats_set(e)
		cheatsEnabled = e
	end

	function c_config_cheats_get()
		return cheatsEnable
	end

	function c_config_cheat_protect(key)
		cheats[key] = true
	end

	local function c_config_save(key, value, config)
		value = trim(value)
		key = tostring(key)

		local pos = key:find('%.')
		if not pos then
			config[key] = value
		else
			if type(config[key:sub(1, pos - 1)]) ~= "table" then
				config[key:sub(1, pos - 1)] = {}
			end

			c_config_save(key:sub(pos + 1), value, config[key:sub(1, pos - 1)])
		end
	end

	local function c_config_write(fout, config, tabs)
		tabs = tabs or 0

		for k, v in pairs(config) do
			if type(v) == "table" then
				tankbobs.fs_write(fout, string.rep('\t', tabs))
				tankbobs.fs_write(fout, string.format("<%s>\n", k, tostring(v), k))
				c_config_write(fout, v, tabs + 1)
				tankbobs.fs_write(fout, string.rep('\t', tabs))
				tankbobs.fs_write(fout, string.format("</%s>\n", k, tostring(v), k))
			else
				tankbobs.fs_write(fout, string.rep('\t', tabs))
				tankbobs.fs_write(fout, string.format("<%s>%s</%s>\n", k, tostring(v), k))
			end
		end
	end

	local function done()
		c_module_load "lfs"

		lfs.mkdir(c_const_get("user_dir"):sub(1, -2))  -- trim trailing '/'

		local fout = tankbobs.fs_openWrite(c_const_get("user_conf"))

		-- put configuration into a table
		local save = {config = {}}

		for k, v in pairs(config) do
			c_config_save(k, v, save.config)
		end

		-- write configuration
		c_config_write(fout, save)

		tankbobs.fs_close(fout)
	end

	function c_config_done()
		done()
	end

	c_config_init()
end

function c_config_done()
	c_config_done = nil
end
