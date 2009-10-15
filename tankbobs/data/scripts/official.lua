--[[
Script for official levels
--]]

c_mods_exitWorldFunction(c_mods_restoreFunctions)

if c_tcm_current_map.title == "The Arena" then
	local function giveShield(tank)
		tank.shield
	end

	c_mods_appendFunction("c_world_spawnTank_misc", giveShield)

	c_const_set("powerup_pushStrength", 0)
end
