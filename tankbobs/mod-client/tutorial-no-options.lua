local function init()
	if c_config_get("game.lastMap") == "tutorial" then
		gui_addAction(tankbobs.m_vec2(25, 92.5), "Back", nil, c_state_advance)

		gui_addAction(tankbobs.m_vec2(75, 75), "Start", nil, st_selected_start)

		return false
	end
end

c_mods_prependFunction("init", init, selected_state)
