/*
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
*/

#ifndef CONFIG_H
#define CONFIG_H

int  config_get_int(int c);
void config_set_int(int c, int v);
bool config_args(int argc, char **argv);

enum
{
	c_autoSelect,
	c_noModify,
	c_autoNoTexture,
	c_hideDetail,

	c_numConfig,

	c_autoSelectDefault    = 1,
	c_noModifyDefault      = 0,
	c_autoNoTextureDefault = 1,
	c_hideDetailDefault    = 0,

	c_null
};

#endif
