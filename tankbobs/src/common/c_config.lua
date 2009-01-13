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
c_config.lua

base configuration settings - mods should not need to redefine anything here
all keys should be strings.  Numbers and other types are untested
--]]

function c_config_init()
	c_config_init = nil

	c_module_load "lxp"
	c_module_load "lxp.lom"

	local config = {}
	local id

	local function c_config_init(config, defaults)
		local function parse(data, config)
			config["r_init"] = true

			local stringdata = ""
			local indeces = {}

			if data["tag"] == nil then
				error("no tag when parsing XML")
			end

			for k, v in ipairs(data) do
				if type(v) == "table" then
					indeces[data["tag"]] = true
					local conf = {}
					if c_config_get(data["tag"], config, true) and type(c_config_get(data["tag"], config, true)) == "table" then
						conf = c_config_get(data["tag"], config)
					end
					parse(v, conf)
					if c_config_get(data["tag"], config, true) ~= table then
						c_config_set(data["tag"], conf, config)
					end
				elseif tostring(v) then
					stringdata = stringdata .. tostring(v)
				end
			end

			if not indeces[data["tag"]] then
				c_config_set(data["tag"], stringdata, config)
			end
		end

		config["r_init"] = true
		if defaults then
			config["r_defaults"] = true
		end

		--load default configuration
		do
			local f, message = io.open(c_const_get("data_conf"), "r")
			if f == nil then
				error("cannot establish game data directory - " .. message)
			end
			local data, message = lxp.lom.parse(f:read("*all"), _G)
			f:close()
			if not data then
				error("cannot parse XML: - " .. message)
			end
			if data["tag"] then
				parse(data, config)
			end
		end

		--load home configuration
		if not defaults then
			local f, message = io.open(c_const_get("user_conf"), "r")
			if f ~= nil then
				local data, message = lxp.lom.parse(f:read("*all"), _G)
				f:close()
				if not data then
					io.stderr:write("Warning: cannot parse XML: - ", message, '\n')
				elseif data["tag"] then
					parse(data, config)
				end
			end
		end
	end

	function c_config_defaults(conf)
		if conf == nil then
			config = {}
			c_config_init(config, true)
		else
			conf = {}
			c_config_init(conf, true)
		end
	end

	local function c_config_force_set(k, v, conf)
		conf = conf or config

		local function trim()
			return function (v)
				local oldV = v
				if type(v) == "string" then
					v = v:match("^[\n\t ]*([%d%.]+)[\n\t ]*$")
					if v == nil then
						v = oldV
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
		end

		v = trim()(v)

		if k == nil then
			error("no key for config set")
		end

		if not conf["r_init"] then
			c_config_init(conf)
		end

		if type(k) ~= "string" then
			conf[k] = v
		end
		local pos = k:find('%.')
		if pos == nil then
			conf[k] = v
		else
			if type(conf[k:sub(1, pos - 1)]) ~= "table" then
				conf[k:sub(1, pos - 1)] = {}
			end
			c_config_force_set(k:sub(pos + 1, -1), v, conf[k:sub(1, pos - 1)])
		end
	end

	function c_config_set(k, v, conf)
		conf = conf or config

		local function trim()
			return function (v)
				local oldV = v
				if type(v) == "string" then
					v = v:match("^[\n\t ]*([%d%.]+)[\n\t ]*$")
					if v == nil then
						v = oldV
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
		end

		v = trim()(v)

		if k == nil then
			error("no key for config set")
		end

		if type(v) == "string" and (v:find("^r_")) then
			error("cannot set reserved key " .. k)
		end

		if not conf["r_init"] then
			c_config_init(conf)
		end

		if type(k) ~= "string" then
			conf[k] = v
		end
		local pos = k:find('%.')
		if pos == nil then
			conf[k] = v
		else
			if type(conf[k:sub(1, pos - 1)]) ~= "table" then
				conf[k:sub(1, pos - 1)] = {}
			end
			c_config_set(k:sub(pos + 1, -1), v, conf[k:sub(1, pos - 1)])
		end
	end

	function c_config_get(k, conf, nilOnError)
		conf = conf or config

		local function trim()
			return function (v)
				local oldV = v
				if type(v) == "string" then
					v = v:match("^[\n\t ]*([%d%.]+)[\n\t ]*$")
					if v == nil then
						v = oldV
						if tonumber(v) then
							v = tonumber(v)
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
		end

		if k == nil then
			error("no key for config retrieval")
		end

		if not conf["r_init"] then
			c_config_init(conf)
		end

		if not (type(k) == "string" and k:find('%.')) and conf[k] == nil then
			if type(k) == "string" then
				if not nilOnError then
					error("config value doesn't exist - config " .. k .. " requested")
				end
				return nil
			elseif type(k) == "number" then
				if not nilOnError then
					error("config value doesn't exist - id #" .. tostring(tonumber(k)) .. " requested")
				end
				return nil
			else
				if not nilOnError then
					error("config value doesn't exist - " .. type(k) .. " requested")
				end
				return nil
			end
		else
			if type(k) ~= "string" then
				return conf[k]
			end
			local pos = k:find('%.')
			if pos == nil then
				return trim()(conf[k])
			else
				return c_config_get(k:sub(pos + 1, -1), conf[k:sub(1, pos - 1)])
			end
		end
	end

	function c_config_backup(k)
		local res = {}
		k = k or config
		if type(k) == "table" then
			local function clone(i, o)
				for k, v in pairs(i) do
					if type(v) == "table" then
						o[k] = {}
						clone(v, o[k])
					else
						o[k] = v
					end
				end
			end
			clone(k, res)
		elseif type(k) == "string" and type(c_config_get(k)) == "table" then
			local function clone(i, o)
				for k, v in pairs(i) do
					if type(v) == "table" then
						o[k] = {}
						clone(v, o[k])
					else
						o[k] = v
					end
				end
			end
			clone(c_config_get(k), res)
		else
			error("config_backup invalid backup key")
		end
		return res
	end

	function c_config_restore(k, v)
		k = k or config
		if type(v) ~= "table" then
			error("config_restore invalid value")
		end
		if type(k) == "table" then
			local function clone(i, o)
				for k, v in pairs(i) do
					if type(v) == "table" then
						o[k] = {}
						clone(v, o[k])
					else
						o[k] = v
					end
				end
			end
			clone(v, k)
		elseif type(k) == "string" and type(config_get(k)) == "table" then
			local function clone(i, o)
				for k, v in pairs(i) do
					if type(v) == "table" then
						c_config_force_set(k, {}, o)
						clone(v, o[k])
					else
						c_config_force_set(k, v, o)
					end
				end
			end
			clone(v, c_config_get(k))
		else
			error("config_restore invalid backup key")
		end
	end

	function c_config_done(conf)
		conf = conf or config

		if not conf["r_init"] then
			c_config_init(conf)
		end

		require "lfs"

		lfs.mkdir(c_const_get("user_dir"):sub(1, -2))

		local f, message = os.remove(c_const_get("user_conf"))
		if not f then
			io.stderr:write("Warning: could not remove '", c_const_get("user_dir"), c_const_get("user_conf"), " for new config file (this will happen on the first run) - ", message, '\n')
		end

		local f, message = io.open(c_const_get("user_conf"), "w+")
		if not f then
			error("error opening '" .. c_const_get("user_dir") .. c_const_get("user_conf") .. " for new config file - " .. message)
		end

		f:setvbuf("line")

		f:seek("set", 0)

		local function finish(conf, tabs, tag)
			tabs = tabs or 0
			if type(tag) == "string" then
				local i = 1
				while i <= tabs do
					f:write('\t')
					i = i + 1
				end
				f:write(string.format("<%s>\n", tag))
			end
			for k, v in pairs(conf) do
				if not (string.find(k, "^r_")) then
					if type(v) == "table" and type(k) == "string" then
						finish(v, tabs + 1, k)
					elseif tostring(v) ~= nil and type(v) ~= nil and type(k) == "string" then
						local i = 1
						while i <= tabs + 1 do
							f:write('\t')
							i = i + 1
						end
						f:write(string.format("<%s>%s</%s>\n", k, tostring(v), k))
					elseif type(v) ~= nil then
						io.stderr:write("Warning: config of type " .. type(v) .. " is not being saved\n")
					end
				end
			end
			local i = 1
			while i <= tabs do
				f:write('\t')
				i = i + 1
			end
			if type(tag) == "string" then
				f:write(string.format("</%s>\n", tag))
			end
		end
		finish(conf, -1)

		f:flush()
		f:close()
	end
end

function c_config_done()
	c_config_done = nil
end
