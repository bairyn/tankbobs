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
init.lua

TODO: figure out what below TODO is asking and if it's necessary
TODO: in every file, describe a description of every global function
inits all scripts
--]]

--[[
some ideas for powerups before I forget:
there is a key to use the currently held powerup.
once a powerup is held, there is a special time (0-5 seconds, something) until
  the powerup is automatically used.  Some powerups can be help longer, whereas
  others are almost immediate.  (proposed implementation:) the longer a powerup is held,
  the less efective it becomes until it completely degrades / disappears.  With this implementaiton,
  it is probably ideal to make all powerups take effect immediately (no need for a powerup key).
(needs balance testing and thinking)Once a powerup spawns in the map, the powerup itself
  will have its own(or somewhat random?) time until it starts to fade, and then
  it'll slow down(or will it?) until it dissapears.  The time it takes for
  it to start fading and disappear completely should be almost the same
  except for a few special powerups
if a powerup is already held and a second powerup is grabbed, they are combined
  immediately(or some variation, but I haven't thought of any) to another special
  powerup.  this will make room for many more special powerups(maybe the ones
  that aren't special will just only combine the powers to a degree of somewhat)
  to n*(n-1), eg 6 powerups would make 30, ie 6*(6-1) = 6 * 5 = 30.  since I was
  expecting to make 20-60 powerups, 60*59=3540, a unique powerup combination is
  not looking too realistic, espcially if I plan to allow furthur combinations
  (player picks up powerup A, then picks up B, the player gets a special combination
    powerup while it slowly dissinigrates, then before it gets too weak (or the combination
    powerup would be pretty weak itself on the side of the original powerup) the player picks
    up a third powerup and gets even another combination).  Not the mention the
    possibilty of picking up a second powerup identical to the first powerup already
    being carried.
--]]

function init()
	server = false
	client = true

	common_init()

	gui_init()

	main_init()
	  --renderer_init()

	  --renderer_done()
	main_done()

	gui_done()

	common_done()
end
