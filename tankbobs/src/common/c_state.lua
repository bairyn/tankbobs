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
c_state.lua

States
--]]

--[[
The state table prototype is defined as:

state_prototype =
{
	name - state name, string
	init - a function to be called when initializing
			if an error occurs, return a non-nil value
	done - a function to be called when exiting and before next state is loaded
			if an error occurs, return a non-nil value
	next - (optional) a function or table that is another state prototype; this is state
			that will be loaded after a call to state_advance() - this does not
			mean states are one directional, this is simply an optional table;
			if this is a table, on state_advance(), state_new(next) will be called
			after finishing current state.  If it is a function, the function
			called needs to return a state prototype table to be loaded with state_new().
			this function may also return a nested function to return a state table, which may
			also nest another function.  The only limit to the number of nested functions
			is stack space

	click(button, pressed, x, y)
							- a function that will be called on a click;
								button is 1: left, 2: right, 3: middle, 4: mwheeldown, 5:mwheelup, 6+ custom to mouse
								- pressed is 1 for mousedown, 0 for release
								- x and y are window coordinates of mouse at time
								- of click (note that x and y may very unlikely, but possibly,
								be unavailable, and if unavailable, will be nil)
	button(button, pressed) - a function to be called on a keyboard button event;
								button is ASCII value (0x74 / 116 for 't') - letters
								should typically be lowercase values, see SDL docs
								for all values
	mouse(x, y, xrel, yrel) - on mouse move, x and y are absolute coordinates for
								window position (0, 0 is bottom left) and xrel
								and yrel are positions relative to previous positions
								(relative coordinates are usually useful only in grabs,
								and absolute coordinates are usually useful when not
								grabbed)

	main()					- a function to be called every step
								if an error occurs, return a non-nil value
}
--]]

local states = {{cur = nil}}
local currentState = 1

local c_state_validate

function c_state_init()
end

function c_state_done()
	if not states[1] or not states[1].cur or not c_state_validate(states[1].cur) then
		return
	end

	local l = 1
	for k, _ in pairs(states) do
		if k < l then
			l = k
		end
	end

	for k = l, 1 do
		local v = states[k]
		if v and v.cur then
			currentState = k

			local res = v.cur.done()

			if res ~= nil then
				if type(res) == "number" or type(res) == "boolean" or type(res) == "string" then
					error("c_state_done: state " .. states[state].cur.name .. " returned an error value: " .. tostring(res))
				elseif tostring(res) then
					error("c_state_done: state " .. states[state].cur.name .. " returned an error value: " .. tostring(res))
				else
					error("c_state_done: state " .. states[state].cur.name .. " returned an error value of type: " .. type(res))
				end
			end
		end
	end
end

function c_state_validate(state)  -- local function
	if not state then
		return false
	elseif type(state) ~= "table" then
		return false
	elseif state.next and type(state.next) ~= "table" and type(state.next) ~= "function" then
		return false
	elseif not state.name then
		return false
	elseif not state.init then
		return false
	elseif not state.done then
		return false
	elseif not state.main then
		return false
	elseif type(state.name) ~= "string" then
		return false
	elseif type(state.init) ~= "function" then
		return false
	elseif type(state.done) ~= "function" then
		return false
	elseif type(state.main) ~= "function" then
		return false
	end

	return true
end

function c_state_click(button, pressed, x, y)  -- should only be called from the main loop
	if not states[1] then
		error("c_state_click: state not initialized or state table lost")
	end

	if not c_state_validate(states[1].cur) or type(states[1].cur.click) ~= "function" then
		error("c_state_click: no valid state")
	end

	local res = states[1].cur.click(button, pressed, x, y)
	if res ~= nil then
		if type(res) == "number" or type(res) == "boolean" or type(res) == "string" then
			error("c_state_click: state " .. states[1].cur.name .. " returned an error value: " .. tostring(res))
		elseif tostring(res) then
			error("c_state_click: state " .. states[1].cur.name .. " returned an error value: " .. tostring(res))
		else
			error("c_state_click: state " .. states[1].cur.name .. " returned an error value of type: " .. type(res))
		end
	end
end

function c_state_button(button, pressed, str)  -- should only be called from the main loop
	if not states[1] then
		error("c_state_button: state not initialized or state table lost")
	end

	if button == 303 or button == 304 then  -- right and left shifts
		shift = pressed and pressed ~= 0
	end

	if not c_state_validate(states[1].cur) or type(states[1].cur.button) ~= "function" then
		error("c_state_button: no valid state")
	end

	local res = states[1].cur.button(tonumber(c_config_keyLayoutSet(button)) or 0, pressed, str)
	if res ~= nil then
		if type(res) == "number" or type(res) == "boolean" or type(res) == "string" then
			error("c_state_button: state " .. states[1].cur.name .. " returned an error value: " .. tostring(res))
		elseif tostring(res) then
			error("c_state_button: state " .. states[1].cur.name .. " returned an error value: " .. tostring(res))
		else
			error("c_state_button: state " .. states[1].cur.name .. " returned an error value of type: " .. type(res))
		end
	end
end

function c_state_mouse(x, y, xrel, yrel)  -- should only be called from the main loop
	if not states[1] then
		error("c_state_mouse: state not initialized or state table lost")
	end

	if not c_state_validate(states[1].cur) or type(states[1].cur.mouse) ~= "function" then
		error("c_state_mouse: no valid state")
	end

	local res = states[1].cur.mouse(x, y, xrel, yrel)
	if res ~= nil then
		if type(res) == "number" or type(res) == "boolean" or type(res) == "string" then
			error("c_state_mouse: state " .. states[1].cur.name .. " returned an error value: " .. tostring(res))
		elseif tostring(res) then
			error("c_state_mouse: state " .. states[1].cur.name .. " returned an error value: " .. tostring(res))
		else
			error("c_state_mouse: state " .. states[1].cur.name .. " returned an error value of type: " .. type(res))
		end
	end
end

function c_state_advance()
	if not states[1] then
		error("c_state_advance: state not initialized or state table lost")
	end

	if not c_state_validate(states[1].cur) then
		error("c_state_advance: no valid state")
	end

	local state = states[1].cur.next

	while type(state) == "function" do
		state = state()
	end

	if not c_state_validate(state) then
		error("c_state_advance: state " .. states[1].cur.name .. " advance called with no valid next")
	end

	return c_state_goto(state)
end

function c_state_goto(state)
	if not states[1] then
		error("c_state_goto: state not initialized or state table lost")
	end

	if not c_state_validate(state) then
		error("c_state_goto: invalid new state")
	end

	local cur = states[1].cur

	states[1].cur = nil

	if cur ~= nil and not c_state_validate(cur) then
		error("c_state_goto: invalid state to stop")
	elseif cur ~= nil then
		local res = cur.done()
		if res ~= nil then
			if type(res) == "number" or type(res) == "boolean" or type(res) == "string" then
				error("c_state_init: state " .. states[1].cur.name .. " returned an error value: " .. tostring(res))
			elseif tostring(res) then
				error("c_state_init: state " .. states[1].cur.name .. " returned an error value: " .. tostring(res))
			else
				error("c_state_init: state " .. states[1].cur.name .. " returned an error value of type: " .. type(res))
			end
		end
	end

	cur = nil

	local res = state.init()
	if res ~= nil then
		if type(res) == "number" or type(res) == "boolean" or type(res) == "string" then
			error("c_state_init: state " .. states[1].cur.name .. " returned an error value: " .. tostring(res))
		elseif tostring(res) then
			error("c_state_init: state " .. states[1].cur.name .. " returned an error value: " .. tostring(res))
		else
			error("c_state_init: state " .. states[1].cur.name .. " returned an error value of type: " .. type(res))
		end
	end

	states[1].cur = state
end

function c_state_step(d)
	if not states[1] then
		error("c_state_step: state not initialized")
	end

	local l = 1
	for k, _ in pairs(states) do
		if k < l then
			l = k
		end
	end

	for k = l, 1 do
		local v = states[k]
		if v and v.cur then
			if not c_state_validate(v.cur) then
				error("c_state_step: no valid state")
			end

			currentState = k

			local res = v.cur.main(d)
			if res ~= nil then
				if type(res) == "number" or type(res) == "boolean" or type(res) == "string" then
					error("c_state_step: state " .. v.cur.name .. " returned an error value: " .. tostring(res))
				elseif tostring(res) then
					error("c_state_step: state " .. v.cur.name .. " returned an error value: " .. tostring(res))
				else
					error("c_state_step: state " .. v.cur.name .. " returned an error value of type: " .. type(res))
				end
			end
		end
	end
end

function c_state_getCurrentState()
	return currentState
end

-- background states

function c_state_backgroundStart(newState)
	local index = 1

	if not c_state_validate(newState) then
		error("c_state_backgroundStart: invalid new state")
	end

	for k, _ in pairs(states) do
		if k <= index then
			index = k - 1
		end
	end

	local oldCurrentState = currentState
	currentState = index

	states[index] = {cur = newState}

	local res = newState.init()
	if res ~= nil then
		if type(res) == "number" or type(res) == "boolean" or type(res) == "string" then
			error("c_state_init: state " .. newState.name .. " returned an error value: " .. tostring(res))
		elseif tostring(res) then
			error("c_state_init: state " .. newState.name .. " returned an error value: " .. tostring(res))
		else
			error("c_state_init: state " .. newState.name .. " returned an error value of type: " .. type(res))
		end
	end

	currentState = oldCurrentState

	return index
end

function c_state_backgroundStop(state)
	if not state or not states[state] or not states[state].cur then
		-- state could have possibly already been stopped
		return
	end

	local cur = states[state].cur

	local oldCurrentState = currentState
	currentState = index

	if cur ~= nil and not c_state_validate(cur) then
		error("c_state_backgroundStop: invalid state to stop")
	elseif cur ~= nil then
		local res = cur.done()
		if res ~= nil then
			if type(res) == "number" or type(res) == "boolean" or type(res) == "string" then
				error("c_state_init: state " .. states[state].cur.name .. " returned an error value: " .. tostring(res))
			elseif tostring(res) then
				error("c_state_init: state " .. states[state].cur.name .. " returned an error value: " .. tostring(res))
			else
				error("c_state_init: state " .. states[state].cur.name .. " returned an error value of type: " .. type(res))
			end
		end
	end

	currentState = oldCurrentState

	states[state] = nil
end

function c_state_backgroundGoto(state, newState)
	newState = newState or states[state].cur.next

	while type(newState) == "function" do
		newState = newState()
	end

	if not c_state_validate(newState) then
		error("c_state_backgroundGoto: invalid new state")
	end

	local done = states[state].cur.done

	local oldCurrentState = currentState
	currentState = index

	local res = done()
	if res ~= nil then
		if type(res) == "number" or type(res) == "boolean" or type(res) == "string" then
			error("c_state_init: state " .. states[state].cur.name .. " returned an error value: " .. tostring(res))
		elseif tostring(res) then
			error("c_state_init: state " .. states[state].cur.name .. " returned an error value: " .. tostring(res))
		else
			error("c_state_init: state " .. states[state].cur.name .. " returned an error value of type: " .. type(res))
		end
	end

	while type(newState) == "function" do
		newState = newState()
	end

	if not c_state_validate(newState) then
		error("c_state_backgroundGoto: invalid state to which to advance")
	end

	local res = newState.init()
	if res ~= nil then
		if type(res) == "number" or type(res) == "boolean" or type(res) == "string" then
			error("c_state_init: state " .. newState.name .. " returned an error value: " .. tostring(res))
		elseif tostring(res) then
			error("c_state_init: state " .. newState.name .. " returned an error value: " .. tostring(res))
		else
			error("c_state_init: state " .. newState.name .. " returned an error value of type: " .. type(res))
		end
	end

	currentState = oldCurrentState

	states[state].cur = newState
end

function c_state_backgroundAdvance(state)
	return c_state_backgroundGoto(state, nil)
end
