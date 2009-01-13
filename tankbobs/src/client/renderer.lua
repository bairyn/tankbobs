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

function renderer_init()
	c_module_load "opengl"

	tankbobs.r_initialize()
end

function renderer_done()
	for _, v in pairs(renderer_font) do
		if type(v) == "userdata" then
			tankbobs.r_freeFont(v)
		end
	end

	renderer_font = nil
	renderer_size = nil
end

function renderer_setupNewWindow() -- this is/should be called once for every new window
	gl.ClearColor(0, 0, 0, 0)

	renderer_updateWindow()
end

function renderer_updateWindow() -- and this is too, but also for redrawing needs (resize, focus, etc)
	gl.Viewport(0, 0, c_config_get("config.renderer.width"), c_config_get("config.renderer.height"))
	gl.MatrixMode("PROJECTION")
	gl.LoadIdentity()
	gl.Ortho(0, 100, 0, 100, -1, 1)
	gl.MatrixMode("MODELVIEW")
	gl.LoadIdentity()

	if not renderer_font then
		renderer_font = {}
		renderer_size = {}

		gl.ShadeModel("SMOOTH")
		gl.Enable("TEXTURE_2D")
		gl.Enable("POINT_SMOOTH")
		gl.Enable("LINE_SMOOTH")
		gl.Enable("POLYGON_SMOOTH")
		gl.Hint("POINT_SMOOTH_HINT", "NICEST")
		gl.Hint("LINE_SMOOTH_HINT", "NICEST")
		gl.Hint("POLYGON_SMOOTH_HINT", "NICEST")

		for k, v in pairs(c_config_get("config.font")) do
			if type(v) == "table" then
				renderer_font[k] = tankbobs.r_newFont(c_const_get("ttf_dir") .. c_config_get("ttf", v))
				renderer_size[k] = c_config_get("size", v)
			end
		end
	end
end

function renderer_start()
	gl.Clear("COLOR_BUFFER_BIT")
	gl.LoadIdentity()
end

function renderer_end()
	gl.Flush()
	tankbobs.r_swapBuffers()
end
