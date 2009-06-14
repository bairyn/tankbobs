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
renderer.lua

drawing output and gl
--]]

local gl

function renderer_init()
	c_module_load "opengl"

	tankbobs.r_initialize()

	gl = _G.gl
end

function renderer_done()
	-- tankbobs module frees fonts for us

	renderer_font = nil
	renderer_size = nil
end

function renderer_setupNewWindow() -- this should be called once after new window
	gl.Enable("BLEND")
	gl.BlendFunc("SRC_ALPHA", "ONE_MINUS_SRC_ALPHA")

	gl.ClearColor(0, 0, 0, 0)

	renderer_updateWindow()
end

function renderer_updateWindow() -- this should to be called after resize, focus, new window, etc
	gl.Viewport(0, 0, c_config_get("config.renderer.width"), c_config_get("config.renderer.height"))
	gl.MatrixMode("PROJECTION")
	gl.LoadIdentity()
	gl.Ortho(0, 100, 0, 100, -1, 1)
	gl.MatrixMode("MODELVIEW")
	gl.LoadIdentity()

	-- settings for text
	gl.ShadeModel("SMOOTH")
	gl.Enable("TEXTURE_2D")
	gl.Enable("POINT_SMOOTH")
	gl.Enable("LINE_SMOOTH")
	gl.Enable("POLYGON_SMOOTH")
	gl.Hint("POINT_SMOOTH_HINT", "NICEST")
	gl.Hint("LINE_SMOOTH_HINT", "NICEST")
	gl.Hint("POLYGON_SMOOTH_HINT", "NICEST")

	for k, v in pairs(c_config_get("config.fonts")) do
		if type(v) == "table" then
			tankbobs.r_newFont(k, c_const_get("ttf_dir") .. c_config_get("ttf", v), c_config_get("size", v))
		end
	end

	tankbobs.r_selectFont(c_config_get("config.font"))
end

function renderer_start()
	gl.Clear("COLOR_BUFFER_BIT")
	gl.LoadIdentity()
end

function renderer_end()
	gl.Flush()
	tankbobs.r_swapBuffers()
end
