-- This is a work around while AI in larger levels is broken
-- set last map and last set to default
c_mods_appendFunction("c_tcm_select_set", function () c_config_set("game.lastSet", "small") end)
c_mods_appendFunction("c_tcm_select_map", function () c_config_set("game.lastMap", "small_1") end)
c_config_set("game.lastSet", "small")
c_config_set("game.lastMap", "small_1")
