/*
Copyright (C) 2008-2009 Byron James Johnson

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

/*
 * trmc.c
 *
 * see c_tcm.lua for map format
 */

#include <stdio.h>
#include <math.h>

#include <SDL_endian.h>

#define VERSION 3
#define MAGIC 0xDEADBEEF

#define TCM_FILENAME_BUF_SIZE 256
#define MAX_STRING_SIZE 512
#define MAX_STRING_STRUCT_CHARS 256
#define MAX_LINE_SIZE 1024

#define SCALE 100  /* Untransformed textures repeat one screen-full at a time */

/* Some math */

typedef double vec2_t[2];

#ifndef M_PI
#define M_PI 3.1415926535897932
#endif

double m_degreesNL(double radians)
{
	return radians * 180 / M_PI;
}

double m_radiansNL(double degrees)
{
	return degrees * M_PI / 180;
}

static int m_force = 0;  /* force overwriting compiled maps */

static const char *read_line = NULL;
static int read_pos = 0;

static void put_double(FILE *fout, const double *d)
{
    const unsigned char * const p = (const unsigned char *)d;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char) p[7], fout);
    fputc((const unsigned char) p[6], fout);
    fputc((const unsigned char) p[5], fout);
    fputc((const unsigned char) p[4], fout);
    fputc((const unsigned char) p[3], fout);
    fputc((const unsigned char) p[2], fout);
    fputc((const unsigned char) p[1], fout);
    fputc((const unsigned char) p[0], fout);
#else
    fputc((const unsigned char) p[0], fout);
    fputc((const unsigned char) p[1], fout);
    fputc((const unsigned char) p[2], fout);
    fputc((const unsigned char) p[3], fout);
    fputc((const unsigned char) p[4], fout);
    fputc((const unsigned char) p[5], fout);
    fputc((const unsigned char) p[6], fout);
    fputc((const unsigned char) p[7], fout);
#endif
}

static void put_float(FILE *fout, const float *f)
{
    const unsigned char *p = (const unsigned char *)f;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char) p[3], fout);
    fputc((const unsigned char) p[2], fout);
    fputc((const unsigned char) p[1], fout);
    fputc((const unsigned char) p[0], fout);
#else
    fputc((const unsigned char) p[0], fout);
    fputc((const unsigned char) p[1], fout);
    fputc((const unsigned char) p[2], fout);
    fputc((const unsigned char) p[3], fout);
#endif
}

static void put_int(FILE *fout, const unsigned int *i)
{
    const unsigned char *p = (const unsigned char *)i;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char) p[3], fout);
    fputc((const unsigned char) p[2], fout);
    fputc((const unsigned char) p[1], fout);
    fputc((const unsigned char) p[0], fout);
#else
    fputc((const unsigned char) p[0], fout);
    fputc((const unsigned char) p[1], fout);
    fputc((const unsigned char) p[2], fout);
    fputc((const unsigned char) p[3], fout);
#endif
}

static void put_short(FILE *fout, const unsigned short *s)
{
    const unsigned char *p = (const unsigned char *)s;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char) p[1], fout);
    fputc((const unsigned char) p[0], fout);
#else
    fputc((const unsigned char) p[0], fout);
    fputc((const unsigned char) p[1], fout);
#endif
}

static void put_char(FILE *fout, const unsigned char *c)
{
	const unsigned char *p = (const unsigned char *)c;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char) p[0], fout);
#else
    fputc((const unsigned char) p[0], fout);
#endif
}

static void put_cdouble(FILE *fout, const double d)
{
    const unsigned char *p = (const unsigned char *)&d;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char) p[7], fout);
    fputc((const unsigned char) p[6], fout);
    fputc((const unsigned char) p[5], fout);
    fputc((const unsigned char) p[4], fout);
    fputc((const unsigned char) p[3], fout);
    fputc((const unsigned char) p[2], fout);
    fputc((const unsigned char) p[1], fout);
    fputc((const unsigned char) p[0], fout);
#else
    fputc((const unsigned char) p[0], fout);
    fputc((const unsigned char) p[1], fout);
    fputc((const unsigned char) p[2], fout);
    fputc((const unsigned char) p[3], fout);
    fputc((const unsigned char) p[4], fout);
    fputc((const unsigned char) p[5], fout);
    fputc((const unsigned char) p[6], fout);
    fputc((const unsigned char) p[7], fout);
#endif
}

static void put_cfloat(FILE *fout, const float f)
{
    const unsigned char *p = (const unsigned char *)&f;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char) p[3], fout);
    fputc((const unsigned char) p[2], fout);
    fputc((const unsigned char) p[1], fout);
    fputc((const unsigned char) p[0], fout);
#else
    fputc((const unsigned char) p[0], fout);
    fputc((const unsigned char) p[1], fout);
    fputc((const unsigned char) p[2], fout);
    fputc((const unsigned char) p[3], fout);
#endif
}

static void put_cint(FILE *fout, const unsigned int i)
{
    const unsigned char *p = (const unsigned char *)&i;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char) p[3], fout);
    fputc((const unsigned char) p[2], fout);
    fputc((const unsigned char) p[1], fout);
    fputc((const unsigned char) p[0], fout);
#else
    fputc((const unsigned char) p[0], fout);
    fputc((const unsigned char) p[1], fout);
    fputc((const unsigned char) p[2], fout);
    fputc((const unsigned char) p[3], fout);
#endif
}

static void put_cshort(FILE *fout, const unsigned short s)
{
    const unsigned char *p = (const unsigned char *)&s;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char) p[1], fout);
    fputc((const unsigned char) p[0], fout);
#else
    fputc((const unsigned char) p[0], fout);
    fputc((const unsigned char) p[1], fout);
#endif
}

static void put_cchar(FILE *fout, const unsigned char c)
{
	const unsigned char *p = (const unsigned char *)&c;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char) p[0], fout);
#else
    fputc((const unsigned char) p[0], fout);
#endif
}

static void put_str(FILE *fout, const char *s, int l)
{
	while(l--)
		put_char(fout, (unsigned char *) s++);
}

static char read_getChar(const char **p)
{
	char c;
	char hex;

	if(**p == '\\')
	{
		c = tolower(*(++(*p)));
		if(!((c >= 'a' && c <= 'f') || (c >= '0' && c <= '9')))
		{
			return '\\';
		}

		c = tolower(*(++(*p)));
		if(!((c >= 'a' && c <= 'f') || (c >= '0' && c <= '9')))
		{
			(*p)--;
			return '\\';
		}

		(*p)++;

		if(c >= '0' && c <= '9')
		{
			hex = c - '0';
		}
		else
		{
			hex = c - 'a' + 0x0A;
		}

		c = tolower(*((*p) - 2));
		if(c >= '0' && c <= '9')
		{
			return 0x10 * (c - '0') + hex;
		}
		else
		{
			return 0x10 * (c - 'a' + 0x0A) + hex;
		}
	}
	/* else */
	return *((*p)++);
}

static int read_int(void)
{
	const char *p = read_line, *p2;
	int i;
	char c;
	int sign = 1;
	int value = 0;

	if(!read_line)
	{
		fprintf(stderr, "Error: read_int() called before read_reset()\n");
		exit(1);
	}

	/* set position to the first character after the comma */
	for(i = 0; i < read_pos; i++)
	{
		while(*p && p - read_line < MAX_LINE_SIZE)
		{
			if(*p++ == ',')
				break;
		}

		if(!*p)
		{
			fprintf(stderr, "Error: too few fields: '%s'\n", read_line);
			exit(1);
		}

		if(p - read_line >= MAX_LINE_SIZE)
		{
			fprintf(stderr, "Error: line is too long: '%s'\n", read_line);
			exit(1);
		}
	}

	/* check for overflows */
	p2 = p;

	while(*p2++)
	{
		if(p2 - read_line >= MAX_LINE_SIZE)
		{
			fprintf(stderr, "Error: line is too long: '%s'\n", read_line);
			exit(1);
		}
	}

	/* skip whitespace */
	while(*p == ' ' || *p == '\t') p++;

	/* read the integer */

	/* read the signs */
	while(*p == '+' || *p == '-')
		if(*p++ == '-')
			sign = -sign;

	while(*p != ',')
	{
		c = read_getChar(&p);

		if(!(c >= '0' && c <= '9'))
			break;

		value = value * 10 + c - '0';
	}

	read_pos++;

	return value * sign;
}

static double read_double(void)
{
	const char *p = read_line, *p2;
	int i;
	char c;
	double sign = 1;
	double value = 0;
	double fraction = 0.1;
	int decimal = 0;

	if(!read_line)
	{
		fprintf(stderr, "Error: read_double() called before read_reset()\n");
		exit(1);
	}

	/* set position to the first character after the comma */
	for(i = 0; i < read_pos; i++)
	{
		while(*p && p - read_line < MAX_LINE_SIZE)
		{
			if(*p++ == ',')
				break;
		}

		if(!*p)
		{
			fprintf(stderr, "Error: too few fields: '%s'\n", read_line);
			exit(1);
		}

		if(p - read_line >= MAX_LINE_SIZE)
		{
			fprintf(stderr, "Error: line is too long: '%s'\n", read_line);
			exit(1);
		}
	}

	/* check for overflows */
	p2 = p;

	while(*p2++)
	{
		if(p2 - read_line >= MAX_LINE_SIZE)
		{
			fprintf(stderr, "Error: line is too long: '%s'\n", read_line);
			exit(1);
		}
	}

	/* skip whitespace */
	while(*p == ' ' || *p == '\t') p++;

	/* read the double */

	/* read the signs */
	while(*p == '+' || *p == '-')
		if(*p++ == '-')
			sign = -sign;

	while(*p != ',')
	{
		c = read_getChar(&p);

		if(!((c == '.') || (c >= '0' && c <= '9')))
			break;

		if(decimal)
		{
			if(c == '.')
			{
				break;
			}
			else
			{
				value += fraction * (c - '0');
				fraction *= 0.1;
			}
		}
		else
		{
			if(c == '.')
			{
				decimal = 1;
			}
			else
			{
				value = value * 10 + c - '0';
			}
		}
	}

	read_pos++;

	return sign * value;
}

static void read_string(char *s)
{
	const char *p = read_line, *p2;
	int i;
	char c;

	if(!read_line)
	{
		fprintf(stderr, "Error: read_string() called before read_reset()\n");
		exit(1);
	}

	/* set position to the first character after the comma */
	for(i = 0; i < read_pos; i++)
	{
		while(*p && p - read_line < MAX_LINE_SIZE)
		{
			if(*p++ == ',')
				break;
		}

		if(!*p)
		{
			fprintf(stderr, "Error: too few fields: '%s'\n", read_line);
			exit(1);
		}

		if(p - read_line >= MAX_LINE_SIZE)
		{
			fprintf(stderr, "Error: line is too long: '%s'\n", read_line);
			exit(1);
		}
	}

	/* check for overflows */
	p2 = p;

	while(*p2++)
	{
		if(p2 - read_line >= MAX_LINE_SIZE)
		{
			fprintf(stderr, "Error: line is too long: '%s'\n", read_line);
			exit(1);
		}
	}

	/* skip whitespace */
	while(*p == ' ' || *p == '\t') p++;

	/* read the string */

	i = s[0] = 0;

	while(*p != ',' && i < MAX_STRING_SIZE - 1)
	{
		c = read_getChar(&p);

		s[i++] = c;
		s[i] = 0;
	}

	/* strip trailing whitespace */
	while(i > 0 && (s[i] == ' ' || s[i] == '\t'))
	{
		s[i--] - 0;
	}

	read_pos++;
}

static int read_reset(const char *line)
{
	read_line = line;
	read_pos = 0;

	if(!line)
	{
		fprintf(stderr, "Error: invalid line passed to read_reset\n");
		return 0;
	}

	return 1;
}

#define MAX_MAPS 1
#define MAX_WALLS 4096
#define MAX_TELEPORTERS 528
#define MAX_PLAYERSPAWNPOINTS 256
#define MAX_POWERUPSPAWNPOINTS 528
#define MAX_PATHS 2048
#define MAX_CONTROLPOINTS 528
#define MAX_FLAGS 256
#define MAX_WAYPOINTS 2048

typedef struct map_s map_t;
static struct map_s
{
	char name[64];
	char title[64];
	char description[1024];
	char song[512];
	char authors[512];
	char version_s[64];
	int version;
	int staticCamera;
	char script[64];
} maps[MAX_MAPS];

typedef struct wall_s wall_t;
static struct wall_s
{
	int quad;
	double x1; double y1;
	double x2; double y2;
	double x3; double y3;
	double x4; double y4;
	double tht;
	double tvt;
	double ths;
	double tvs;
	double tr;
	char texture[256];  /* hardcoded for format */
	int level;
	char target[MAX_STRING_STRUCT_CHARS];
	int path;
	int detail;
	int staticW;
	char misc[512];
} walls[MAX_WALLS];

typedef struct teleporter_s teleporter_t;
static struct teleporter_s
{
	char targetName[MAX_STRING_STRUCT_CHARS];
	char target[MAX_STRING_STRUCT_CHARS];
	double x1; double y1;
	int enabled;
	char misc[512];
} teleporters[MAX_TELEPORTERS];

typedef struct playerSpawnPoint_s playerSpawnPoint_t;
static struct playerSpawnPoint_s
{
	double x1; double y1;
	char misc[512];
} playerSpawnPoints[MAX_PLAYERSPAWNPOINTS];

typedef struct powerupSpawnPoint_s powerupSpawnPoint_t;
static struct powerupSpawnPoint_s
{
	double x1; double y1;
	char powerupsToEnable[MAX_STRING_STRUCT_CHARS];
	int linked;
	double repeat;
	double initial;
	int focus;
	char misc[512];
} powerupSpawnPoints[MAX_POWERUPSPAWNPOINTS];

typedef struct path_s path_t;
static struct path_s
{
	char targetName[MAX_STRING_STRUCT_CHARS];
	char target[MAX_STRING_STRUCT_CHARS];
	double x1; double y1;
	int enabled;
	double time;
	char misc[512];
} paths[MAX_PATHS];

typedef struct controlPoint_s controlPoint_t;
static struct controlPoint_s
{
	double x1; double y1;
	int red;
	char misc[512];
} controlPoints[MAX_CONTROLPOINTS];

typedef struct flag_s flag_t;
static struct flag_s
{
	double x1; double y1;
	int red;
	char misc[512];
} flags[MAX_FLAGS];

typedef struct wayPoint_s wayPoint_t;
static struct wayPoint_s
{
	double x1; double y1;
	char misc[512];
} wayPoints[MAX_WAYPOINTS];


static void calculateTextureCoordinates(wall_t *wall, vec2_t t[4])
{
	int i;
	double th, r;

	/* calculate texture coordinates by rotation and horizontal and vertical translation and scale */
	t[0][0] = (wall->x1 + wall->tht) / SCALE;
	t[1][0] = (wall->x2 + wall->tht) / SCALE;
	t[2][0] = (wall->x3 + wall->tht) / SCALE;
	t[3][0] = (wall->x4 + wall->tht) / SCALE;
	t[0][1] = (wall->y1 + wall->tvt) / SCALE;
	t[1][1] = (wall->y2 + wall->tvt) / SCALE;
	t[2][1] = (wall->y3 + wall->tvt) / SCALE;
	t[3][1] = (wall->y4 + wall->tvt) / SCALE;

	t[0][0] *= wall->ths;
	t[1][0] *= wall->ths;
	t[2][0] *= wall->ths;
	t[3][0] *= wall->ths;
	t[0][1] *= wall->tvs;
	t[1][1] *= wall->tvs;
	t[2][1] *= wall->tvs;
	t[3][1] *= wall->tvs;

	for(i = 0; i < ((wall->quad) ? (4) : (3)); i++)
	{
		if(t[i][0] != 0.0 || t[i][1] != 0.0)
		{
			th = atan2(t[i][1], t[i][0]) + m_radiansNL(wall->tr + 180);  /* correct upside-down-ness */
			r = sqrt(t[i][0] * t[i][0] + t[i][1] * t[i][1]);
			t[i][0] = r * cos(th);
			t[i][1] = r * sin(th);
		}
	}

	/*
	/8 shift vertices until t[0] matches the lowest vertex 8/
	k = 0;
	while(k++ < 4 && ((t[0][1] > t[1][1]) || (t[0][1] > t[2][1]) || (wall->quad && t[0][1] > t[3][3])))
	{
		t[0][0] ^= t[1][0];
		t[1][0] ^= t[0][0];
		t[0][0] ^= t[1][0];
		t[1][0] ^= t[2][0];
		t[2][0] ^= t[1][0];
		t[1][0] ^= t[2][0];
		t[0][1] ^= t[1][1];
		t[1][1] ^= t[0][1];
		t[0][1] ^= t[1][1];
		t[1][1] ^= t[2][1];
		t[2][1] ^= t[1][1];
		t[1][1] ^= t[2][1];
		if(wall->quad)
		{
			t[2][1] ^= t[3][1];
			t[3][1] ^= t[2][1];
			t[2][1] ^= t[3][1];
		}
	}
	*/
}

static int mc;
static int wc;
static int tc;
static int lc;
static int oc;
static int pc;
static int cc;
static int fc;
static int ac;

static void add_map(const char *name, const char *title, const char *description, const char *song, const char *authors, const char *version_s, int version, int staticCamera, const char *script)
{
	map_t *map = &maps[mc++];

	if(mc > MAX_MAPS)
	{
		fprintf(stderr, "Error: map overflow (%d)\n", MAX_MAPS);
		exit(1);
	}

	strncpy(map->name, name, sizeof(map->name));
	strncpy(map->title, title, sizeof(map->title));
	strncpy(map->description, description, sizeof(map->description));
	strncpy(map->song, song, sizeof(map->song));
	strncpy(map->authors, description, sizeof(map->authors));
	strncpy(map->version_s, version_s, sizeof(map->version_s));
	map->version = version;
	map->staticCamera = staticCamera;
	strncpy(map->script, script, sizeof(map->script));
}

static void add_wall(int quad, double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4, double tht, double tvt, double ths, double tvs, double tr, const char *texture, int level, const char *target, int path, int detail, int staticW, const char *misc)
{
	wall_t *wall = &walls[wc++];

	if(wc > MAX_WALLS)
	{
		fprintf(stderr, "Error: wall overflow (%d)\n", MAX_WALLS);
		exit(1);
	}

	wall->quad = quad;
	wall->x1 = x1;
	wall->y1 = y1;
	wall->x2 = x2;
	wall->y2 = y2;
	wall->x3 = x3;
	wall->y3 = y3;
	wall->x4 = x4;
	wall->y4 = y4;
	wall->tht = tht;
	wall->tvt = tvt;
	wall->ths = ths;
	wall->tvs = tvs;
	wall->tr = tr;
	strncpy(wall->texture, texture, sizeof(wall->texture));
	wall->level = level;
	strncpy(wall->target, target, sizeof(wall->target));
	wall->path = path;
	wall->detail = detail;
	wall->staticW = staticW;
	strncpy(wall->misc, misc, sizeof(wall->misc));
}

static void add_teleporter(const char *targetName, const char *target, double x1, double y1, int enabled, const char *misc)
{
	teleporter_t *teleporter = &teleporters[tc++];

	if(tc > MAX_TELEPORTERS)
	{
		fprintf(stderr, "Error: teleporter overflow (%d)\n", MAX_TELEPORTERS);
		exit(1);
	}

	strncpy(teleporter->targetName, targetName, sizeof(teleporter->targetName));
	strncpy(teleporter->target, target, sizeof(teleporter->target));
	teleporter->x1 = x1;
	teleporter->y1 = y1;
	teleporter->enabled = enabled;
	strncpy(teleporter->misc, misc, sizeof(teleporter->misc));
}

static void add_playerSpawnPoint(double x1, double y1, const char *misc)
{
	playerSpawnPoint_t *playerSpawnPoint = &playerSpawnPoints[lc++];

	if(lc > MAX_PLAYERSPAWNPOINTS)
	{
		fprintf(stderr, "Error: playerSpawnPoint overflow (%d)\n", MAX_PLAYERSPAWNPOINTS);
		exit(1);
	}

	playerSpawnPoint->x1 = x1;
	playerSpawnPoint->y1 = y1;
	strncpy(playerSpawnPoint->misc, misc, sizeof(playerSpawnPoint->misc));
}

static void add_powerupSpawnPoint(double x1, double y1, const char *powerupsToEnable, int linked, double repeat, double initial, int focus, const char *misc)
{
	powerupSpawnPoint_t *powerupSpawnPoint = &powerupSpawnPoints[oc++];

	if(oc > MAX_POWERUPSPAWNPOINTS)
	{
		fprintf(stderr, "Error: powerupSpawnPoint overflow (%d)\n", MAX_POWERUPSPAWNPOINTS);
		exit(1);
	}

	powerupSpawnPoint->x1 = x1;
	powerupSpawnPoint->y1 = y1;
	strncpy(powerupSpawnPoint->powerupsToEnable, powerupsToEnable, sizeof(powerupSpawnPoint->powerupsToEnable));
	powerupSpawnPoint->linked = linked;
	powerupSpawnPoint->repeat = repeat;
	powerupSpawnPoint->initial = initial;
	powerupSpawnPoint->focus = focus;
	strncpy(powerupSpawnPoint->misc, misc, sizeof(powerupSpawnPoint->misc));
}

static void add_path(const char *targetName, const char *target, double x1, double y1, int enabled, double time, const char *misc)
{
	path_t *path = &paths[pc++];

	if(pc > MAX_PATHS)
	{
		fprintf(stderr, "Error: path overflow (%d)\n", MAX_PATHS);
		exit(1);
	}

	strncpy(path->targetName, targetName, sizeof(path->targetName));
	strncpy(path->target, target, sizeof(path->target));
	path->x1 = x1;
	path->y1 = y1;
	path->enabled = enabled;
	path->time = time;
	strncpy(path->misc, misc, sizeof(path->misc));
}

static void add_controlPoint(double x1, double y1, int red, const char *misc)
{
	controlPoint_t *controlPoint = &controlPoints[cc++];

	if(cc > MAX_CONTROLPOINTS)
	{
		fprintf(stderr, "Error: controlPoint overflow (%d)\n", MAX_CONTROLPOINTS);
		exit(1);
	}

	controlPoint->x1 = x1;
	controlPoint->y1 = y1;
	controlPoint->red = red;
	strncpy(controlPoint->misc, misc, sizeof(controlPoint->misc));
}

static void add_flag(double x1, double y1, int red, const char *misc)
{
	flag_t *flag = &flags[fc++];

	if(fc > MAX_FLAGS)
	{
		fprintf(stderr, "Error: flag overflow (%d)\n", MAX_FLAGS);
		exit(1);
	}

	flag->x1 = x1;
	flag->y1 = y1;
	flag->red = red;
	strncpy(flag->misc, misc, sizeof(flag->misc));
}

static void add_wayPoint(double x1, double y1, const char *misc)
{
	wayPoint_t *wayPoint = &wayPoints[ac++];

	if(ac > MAX_WAYPOINTS)
	{
		fprintf(stderr, "Error: wayPoint overflow (%d)\n", MAX_WAYPOINTS);
		exit(1);
	}

	wayPoint->x1 = x1;
	wayPoint->y1 = y1;
	strncpy(wayPoint->misc, misc, sizeof(wayPoint->misc));
}


static int hidden(const char *filename)
{
	const char *p = filename;

	while(*p) p++;
	while(p >= filename && *p != '/') p--;
	return *++p == '.';
}

static int compile(const char *filename)
{
	char c;
	char tcmFilenameBuf[TCM_FILENAME_BUF_SIZE];
	char *tcmFilename = tcmFilenameBuf;
	int tcmAllocated = 0;  /* see if we need to free the memory */
	char *p;
	FILE *fin;
	FILE *fout;
	int i = 0;
	int j, k;
	char line[MAX_LINE_SIZE] = {""};

	/* reset counters */
	mc = wc = tc = lc = oc = pc = cc = fc = ac = 0;

	if(hidden(filename))
	{
		fprintf(stderr, "Warning: ignoring hidden file: '%s'\n", filename);
		return 1;
	}

	if(strlen(filename) + strlen(".tcm") + 1 > sizeof(tcmFilenameBuf))
	{
		tcmAllocated = 1;
		tcmFilename = calloc(sizeof(char), strlen(filename) + strlen(".tcm") + 1);  /* not enough room for tcm filename, so allocate more memory for it */
	}

	strcpy(tcmFilename, filename);

	/* change .trm to .tcm or else append .tcm */
	p = tcmFilename;
	while(*p) p++;
	if((p - tcmFilename) > strlen(".tcm") + 1 && *(p - 4) == '.' && *(p - 3) == 't' && *(p - 2) == 'r' && *(p - 1) == 'm')  /* NOTE: strlen(...) _+ 1_ doesn't match ".tcm" exactly (we don't want to match hidden files) */
	{
		/* filename ends in .trm; change tcmFilename to .tcm */
		*(p - 2) = 'c';
	}
	else
	{
		/* append .tcm */
		*p++ = '.';
		*p++ = 't';
		*p++ = 'c';
		*p++ = 'm';
		*p++ = 0;
	}

	/* we have the filename for the input and ouput files, so open the streams */

	/* first check we aren't overwriting anything undesirably */
	fin = fopen(tcmFilename, "r");
	if(fin)
	{
		fclose(fin);

		if(!m_force)
		{
			if(tcmAllocated)
				free(tcmFilename);
			fprintf(stderr, "Not overwriting file: '%s'.  (Use -f to override.)\n", tcmFilename);
			return 1;
		}
	}

	if(!(fin = fopen(filename, "r")))
	{
		if(tcmAllocated)
			free(tcmFilename);
		perror(NULL);
		fprintf(stderr, "Error opening file for reading: '%s'\n", filename);
		return 0;
	}

	/* read map and store all of map into memory */
	while((c = fgetc(fin)) != EOF)
	{
		if(c == '\n')
		{
			if(i)
			{
				char entity[MAX_STRING_SIZE];

				if(!read_reset(line))
				{
					fprintf(stderr, "Error reading file: '%s'\n", filename);
					fclose(fin);
					return 0;
				}

				read_string(entity);
				if(strncmp(entity, "map", sizeof(entity)) == 0)
				{
					char name[MAX_STRING_SIZE];
					char title[MAX_STRING_SIZE];
					char description[MAX_STRING_SIZE];
					char song[MAX_STRING_SIZE];
					char authors[MAX_STRING_SIZE];
					char version_s[MAX_STRING_SIZE];
					int version;
					int staticCamera;
					char script[MAX_STRING_SIZE];

					read_string(name);
					read_string(title);
					read_string(description);
					read_string(song);
					read_string(authors);
					read_string(version_s);
					version = read_int();
					staticCamera = read_int();
					read_string(script);

					add_map(name, title, description, song, authors, version_s, version, staticCamera, script);
				}
				else if(strncmp(entity, "wall", sizeof(entity)) == 0)
				{
					int quad;
					double x1, y1;
					double x2, y2;
					double x3, y3;
					double x4, y4;
					double tht;
					double tvt;
					double ths;
					double tvs;
					double tr;
					char texture[MAX_STRING_SIZE];
					int level;
					char target[MAX_STRING_SIZE];
					int path;
					int detail;
					int staticW;
					char misc[MAX_STRING_SIZE];

					quad = read_int();
					x1   = read_double();
					y1   = read_double();
					x2   = read_double();
					y2   = read_double();
					x3   = read_double();
					y3   = read_double();
					x4   = read_double();
					y4   = read_double();
					tht  = read_double();
					tvt  = read_double();
					ths  = read_double();
					tvs  = read_double();
					tr   = read_double();
					read_string(texture);
					level = read_int();
					read_string(target);
					path = read_int();
					detail = read_int();
					staticW = read_int();
					read_string(misc);

					add_wall(quad, x1, y1, x2, y2, x3, y3, x4, y4, tht, tvt, ths, tvs, tr, texture, level, target, path, detail, staticW, misc);
				}
				else if(strncmp(entity, "teleporter", sizeof(entity)) == 0)
				{
					char targetName[MAX_STRING_SIZE];
					char target[MAX_STRING_SIZE];
					double x1, y1;
					int enabled;
					char misc[MAX_STRING_SIZE];

					read_string(targetName);
					read_string(target);
					x1 = read_double();
					y1 = read_double();
					enabled = read_int();
					read_string(misc);

					add_teleporter(targetName, target, x1, y1, enabled, misc);
				}
				else if(strncmp(entity, "playerSpawnPoint", sizeof(entity)) == 0)
				{
					double x1, y1;
					char misc[MAX_STRING_SIZE];

					x1 = read_double();
					y1 = read_double();
					read_string(misc);

					add_playerSpawnPoint(x1, y1, misc);
				}
				else if(strncmp(entity, "powerupSpawnPoint", sizeof(entity)) == 0)
				{
					double x1, y1;
					char powerupsToEnable[MAX_STRING_SIZE];
					int linked;
					double repeat;
					double initial;
					int focus;
					char misc[MAX_STRING_SIZE];

					x1 = read_double();
					y1 = read_double();
					read_string(powerupsToEnable);
					linked = read_int();
					repeat = read_double();
					initial = read_double();
					focus = read_int();
					read_string(misc);

					add_powerupSpawnPoint(x1, y1, powerupsToEnable, linked, repeat, initial, focus, misc);
				}
				else if(strncmp(entity, "path", sizeof(entity)) == 0)
				{
					char targetName[MAX_STRING_SIZE];
					char target[MAX_STRING_SIZE];
					double x1, y1;
					int enabled;
					double time;
					char misc[MAX_STRING_SIZE];

					read_string(targetName);
					read_string(target);
					x1 = read_double();
					y1 = read_double();
					enabled = read_int();
					time = read_double();
					read_string(misc);

					add_path(targetName, target, x1, y1, enabled, time, misc);
				}
				else if(strncmp(entity, "controlPoint", sizeof(entity)) == 0)
				{
					double x1, y1;
					int red;
					char misc[MAX_STRING_SIZE];

					x1 = read_double();
					y1 = read_double();
					red = read_int();
					read_string(misc);

					add_controlPoint(x1, y1, red, misc);
				}
				else if(strncmp(entity, "flag", sizeof(entity)) == 0)
				{
					double x1, y1;
					int red;
					char misc[MAX_STRING_SIZE];

					x1 = read_double();
					y1 = read_double();
					red = read_int();
					read_string(misc);

					add_flag(x1, y1, red, misc);
				}
				else if(strncmp(entity, "wayPoint", sizeof(entity)) == 0)
				{
					double x1, y1;
					char misc[MAX_STRING_SIZE];

					x1 = read_double();
					y1 = read_double();
					read_string(misc);

					add_wayPoint(x1, y1, misc);
				}

				else
				{
					fclose(fin);
					if(tcmAllocated)
						free(tcmFilename);
					fprintf(stderr, "Unknown entity when reading '%s': '%s'\n", filename, entity);
					return 0;
				}

				i = line[0] = 0;
			}
		}
		else
		{
			line[i++] = c;
			line[i] = 0;
		}
	}

	if(line[0])
	{
		fprintf(stderr, "Warning: ignored trailing line missing a newline character while reading '%s'\n", filename);
	}

	fclose(fin);

	if(!(fout = fopen(tcmFilename, "wb")))
	{
		if(tcmAllocated)
			free(tcmFilename);
		perror(NULL);
		fprintf(stderr, "Error opening file for writing: '%s'\n", tcmFilename);
		return 0;
	}

	/* header */
	put_cchar(fout, 0x00);
	put_cchar(fout, 0x54);
	put_cchar(fout, 0x43);
	put_cchar(fout, 0x4D);
	put_cchar(fout, 0x01);
	put_cint(fout, MAGIC);
	put_cchar(fout, VERSION);

	put_str(fout, maps[0].name, 64);
	put_str(fout, maps[0].title, 64);
	put_str(fout, maps[0].description, 1024);
	put_str(fout, maps[0].song, 512);
	put_str(fout, maps[0].authors, 512);
	put_str(fout, maps[0].version_s, 64);
	put_cint(fout, maps[0].version);
	put_cchar(fout, maps[0].staticCamera);
	put_str(fout, maps[0].script, 64);

	put_cint(fout, wc);
	put_cint(fout, tc);
	put_cint(fout, lc);
	put_cint(fout, oc);
	put_cint(fout, pc);
	put_cint(fout, cc);
	put_cint(fout, fc);
	put_cint(fout, ac);

	for(i = 0; i < wc; i++)
	{
		int id = 0;
		vec2_t t[4];
		wall_t *wall = &walls[i];

		/* find the target (it might not exist) */
		for(j = 0; j < pc; j++)
		{
			path_t *path = &paths[j];

			if(strcmp(wall->target, path->targetName) == 0)
			{
				id = j;
				break;
			}
		}

		calculateTextureCoordinates(wall, t);

		put_cint(fout, i);
		put_cchar(fout, ((wall->quad) ? (1) : (0)));
		put_cdouble(fout, wall->x1);
		put_cdouble(fout, wall->y1);
		put_cdouble(fout, wall->x2);
		put_cdouble(fout, wall->y2);
		put_cdouble(fout, wall->x3);
		put_cdouble(fout, wall->y3);
		put_cdouble(fout, wall->x4);
		put_cdouble(fout, wall->y4);
		for(j = 0; j < 4; j++)
		{
			for(k = 0; k < 2; k++)
			{
				put_cdouble(fout, t[j][k]);
			}
		}
		put_str(fout, wall->texture, 256);
		put_cint(fout, wall->level);
		put_cint(fout, id);
		put_cchar(fout, ((wall->path) ? (1) : (0)));
		put_cchar(fout, ((wall->detail) ? (1) : (0)));
		put_cchar(fout, ((wall->staticW) ? (1) : (0)));
		put_str(fout, wall->misc, 512);
	}

	for(i = 0; i < tc; i++)
	{
		int id = 0;
		teleporter_t *teleporter = &teleporters[i];

		/* find the target (it might not exist) */
		for(j = 0; j < tc; j++)
		{
			teleporter_t *teleporter2 = &teleporters[j];

			if(strcmp(teleporter->target, teleporter2->targetName) == 0)
			{
				id = j;
				break;
			}
		}

		put_cint(fout, i);
		put_cint(fout, id);
		put_cdouble(fout, teleporter->x1);
		put_cdouble(fout, teleporter->y1);
		put_cchar(fout, ((teleporter->enabled) ? (1) : (0)));
		put_str(fout, teleporter->misc, 512);
	}

	for(i = 0; i < lc; i++)
	{
		playerSpawnPoint_t *playerSpawnPoint = &playerSpawnPoints[i];

		put_cint(fout, i);
		put_cdouble(fout, playerSpawnPoint->x1);
		put_cdouble(fout, playerSpawnPoint->y1);
		put_str(fout, playerSpawnPoint->misc, 512);
	}

	for(i = 0; i < oc; i++)
	{
		unsigned int powerups[16] = {0};
		powerupSpawnPoint_t *powerupSpawnPoint = &powerupSpawnPoints[i];

		if(strstr(powerupSpawnPoint->powerupsToEnable, "machinegun"))
		{
			powerups[0] |= 0x00000001;
		}
		if(strstr(powerupSpawnPoint->powerupsToEnable, "shotgun"))
		{
			powerups[0] |= 0x00000002;
		}
		if(strstr(powerupSpawnPoint->powerupsToEnable, "railgun"))
		{
			powerups[0] |= 0x00000004;
		}
		if(strstr(powerupSpawnPoint->powerupsToEnable, "coilgun"))
		{
			powerups[0] |= 0x00000008;
		}
		if(strstr(powerupSpawnPoint->powerupsToEnable, "saw"))
		{
			powerups[0] |= 0x00000010;
		}
		if(strstr(powerupSpawnPoint->powerupsToEnable, "ammo"))
		{
			powerups[0] |= 0x00000020;
		}
		if(strstr(powerupSpawnPoint->powerupsToEnable, "aim-aid"))
		{
			powerups[0] |= 0x00000040;
		}
		if(strstr(powerupSpawnPoint->powerupsToEnable, "health"))
		{
			powerups[0] |= 0x00000080;
		}
		if(strstr(powerupSpawnPoint->powerupsToEnable, "acceleration"))
		{
			powerups[0] |= 0x00000100;
		}
		if(strstr(powerupSpawnPoint->powerupsToEnable, "shield"))
		{
			powerups[0] |= 0x00000200;
		}
		if(strstr(powerupSpawnPoint->powerupsToEnable, "rocket-launcher"))
		{
			powerups[0] |= 0x00000400;
		}
		if(strstr(powerupSpawnPoint->powerupsToEnable, "laser-gun"))
		{
			powerups[0] |= 0x00000800;
		}
		if(strstr(powerupSpawnPoint->powerupsToEnable, "plasma-gun"))
		{
			powerups[0] |= 0x00001000;
		}

		put_cint(fout, i);
		put_cdouble(fout, powerupSpawnPoint->x1);
		put_cdouble(fout, powerupSpawnPoint->y1);
		for(j = 0; j < sizeof(powerups) / sizeof(powerups[0]); j++)
		{
			put_cint(fout, powerups[j]);
		}
		put_cchar(fout, powerupSpawnPoint->linked);
		put_cdouble(fout, powerupSpawnPoint->repeat);
		put_cdouble(fout, powerupSpawnPoint->initial);
		put_cchar(fout, powerupSpawnPoint->focus);
		put_str(fout, powerupSpawnPoint->misc, 512);
	}

	for(i = 0; i < pc; i++)
	{
		int id = 0;
		path_t *path = &paths[i];

		/* find the target (it might not exist) */
		for(j = 0; j < pc; j++)
		{
			path_t *path2 = &paths[j];

			if(strcmp(path->target, path2->targetName) == 0)
			{
				id = j;
				break;
			}
		}

		put_cint(fout, i);
		put_cdouble(fout, path->x1);
		put_cdouble(fout, path->y1);
		put_cchar(fout, ((path->enabled) ? (1) : (0)));
		put_cdouble(fout, path->time);
		put_cint(fout, id);
		put_str(fout, path->misc, 512);
	}

	for(i = 0; i < cc; i++)
	{
		controlPoint_t *controlPoint = &controlPoints[i];

		put_cint(fout, i);
		put_cdouble(fout, controlPoint->x1);
		put_cdouble(fout, controlPoint->y1);
		put_cchar(fout, ((controlPoint->red) ? (1) : (0)));
		put_str(fout, controlPoint->misc, 512);
	}

	for(i = 0; i < fc; i++)
	{
		flag_t *flag = &flags[i];

		put_cint(fout, i);
		put_cdouble(fout, flag->x1);
		put_cdouble(fout, flag->y1);
		put_cchar(fout, ((flag->red) ? (1) : (0)));
		put_str(fout, flag->misc, 512);
	}

	for(i = 0; i < ac; i++)
	{
		wayPoint_t *wayPoint = &wayPoints[i];

		put_cint(fout, i);
		put_cdouble(fout, wayPoint->x1);
		put_cdouble(fout, wayPoint->y1);
		put_str(fout, wayPoint->misc, 512);
	}

	fclose(fout);

	if(tcmAllocated)
		free(tcmFilename);

	return 1;
}

int main(int argc, char **argv)
{
	int i;
	int force = 1;

	/* parse the options first */
	for(i = 1; i < argc; i++)
	{
		if(argv[i][0] == '-')
		{
			if(argv[i][1] == '-')
			{
				/* continue parsing filenames */
				force = i + 1;
				break;
			}

			else if(strcmp(argv[i], "-h") == 0)
			{
				fprintf(stdout, "Usage: %s [-h] [-f]\n-h: display this help message\n-f: force overwriting\n", argv[0]);
				return 1;
			}
			else if(strcmp(argv[i], "-f") == 0)
			{
				m_force = 1;
			}
			else
			{
				fprintf(stderr, "Unrecognized option: '%s'\n", argv[i]);
				return 1;
			}
		}
	}

	/* parse the filenames */
	for(i = force; i < argc; i++)
	{
		if(force > 1 || argv[i][0] != '-')
		{
			if(!compile(argv[i]))
			{
				fprintf(stderr, "Error compiling map '%s'\n", argv[i]);
				return 1;
			}
		}
	}

	if(0)
	{
		/* unused function warning */
		put_double(NULL, NULL);
		put_float(NULL, NULL);
		put_int(NULL, NULL);
		put_short(NULL, NULL);
		put_char(NULL, NULL);
		put_cdouble(NULL, 0);
		put_cfloat(NULL, 0);
		put_cint(NULL, 0);
		put_cshort(NULL, 0);
		put_cchar(NULL, 0);
		put_str(NULL, NULL, 0);
	}

	return 0;
}
