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
