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

	c_numConfig,

	c_autoSelectDefault    = 1,
	c_noModifyDefault      = 0,
	c_autoNoTextureDefault = 1,

	c_null
};

#endif
