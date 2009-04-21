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

#include "config.h"
#include "util.h"

static int config[c_numConfig];
static bool init = false;

static void config_init()
{
	for(int i = 0; i < c_numConfig; i++)
		config[i] = 0;

	init = true;

	config_set_int(c_autoSelect, c_autoSelectDefault);
	config_set_int(c_noModify, c_noModifyDefault);
	config_set_int(c_autoNoTexture, c_autoNoTextureDefault);
}

int config_get_int(int c)
{
	if(!init)
		config_init();

	return config[c];
}

void config_set_int(int c, int v)
{
	if(!init)
		config_init();

	config[c] = v;
}

bool config_args(int argc, char **argv)
{
	for(int i = 1; i < argc; i++)
	{
		if(!util_strncmp(argv[i], "-h", 2))
		{
			argv[i] += 2;

			fprintf(stdout, "Usage: (%s -h) or (%s -cConfigValue)\n", argv[0], argv[0]);

			return false;
		}
		else if(!util_strncmp(argv[i], "-c", 2))
		{
			argv[i] += 2;

			const char *m = "c_autoSelect";
			if(!util_strncmp(argv[i], m, strlen(m)))
			{
				argv[i] += strlen(m);
				config_set_int(c_autoSelect, util_atoi(argv[i]));
			}
			m = "c_noModify";
			if(!util_strncmp(argv[i], m, strlen(m)))
			{
				argv[i] += strlen(m);
				config_set_int(c_noModify, util_atoi(argv[i]));
			}
		}
	}

	return true;
}
