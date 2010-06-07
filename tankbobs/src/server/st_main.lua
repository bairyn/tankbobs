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
st_main.lua

main server state
--]]

local tankbobs
local commands_command
local c_world_setPaused
local c_world_step

local st_main_init
local st_main_done

function st_main_init()
	tankbobs = _G.tankbobs
	commands_command = _G.commands_command
	c_world_setPaused = _G.c_world_setPaused
	c_world_step = _G.c_world_step

	tankbobs.n_init(c_config_get("server.port", true))

	c_protocol_setPersistProtocol(protocol_persist)

	client_begin()

	c_world_setGameType(c_config_get("game.gameType"))
	c_world_setInstagib(c_config_get("game.instagib"))
	c_world_setSpawnStyle(c_config_get("game.spawnStyle"))

	c_world_newWorld()
end

function st_main_done()
	c_world_freeWorld()

	client_finish()

	tankbobs.n_quit()
end

local endOfGame = false
local function testEnd()
	-- test for end of game
	if endOfGame then
		c_world_setPaused(true)

		return
	end

	if not c_world_redTeam or c_world_blueTeam then
		return  -- world probably not initialized
	end

	local win, isTeam, key = c_world_hasWon()
	if win then
		endOfGame = true
		c_world_setPaused(true)

		if isTeam then
			if win.red then
				client_sendEvent(nil, tankbobs.io_fromChar(0x00) .. tankbobs.io_fromInt(0x00000001))

				s_printnl("(", c_world_gameTypeHumanString(), ") Red Team Wins!")
			else
				client_sendEvent(nil, tankbobs.io_fromChar(0x00) .. tankbobs.io_fromInt(0x00000000))

				s_printnl("(", c_world_gameTypeHumanString(), ") Blue Team Wins!")
			end
		else
			client_sendEvent(client_getByTank(win), tankbobs.io_fromChar(0x00) .. tankbobs.io_fromInt(key))

			s_printnl("(", c_world_gameTypeHumanString(), ") '", win.name, "' Wins!")
		end
	end
end

local seedCounter = 1024
function st_main_step(d)
	-- seed the random number generator every 1024 frames for non-gameplay purposes
	if seedCounter < 1024 then
		seedCounter = seedCounter + 1
	else
		seedCounter = 0

		math.randomseed(os.time() * tankbobs.t_getTicks() + 10 * 768 * d)
	end

	local input = tankbobs.c_input()

	if input then
		commands_command(input)
	end

	client_step(d)

	testEnd()

	if(client_connectedClients() <= 0) then
		if not c_world_getPaused() then
			s_printnl("The game has been automatically paused")
			c_world_setPaused(true)
		end
	end

	c_world_step(d)
end

main_state =
{
	name   = "title_state",
	init   = st_main_init,
	done   = st_main_done,
	next   = function () return exit_state end,

	click  = common_nil,
	button = common_nil,
	mouse  = common_nil,

	main   = st_main_step
}
