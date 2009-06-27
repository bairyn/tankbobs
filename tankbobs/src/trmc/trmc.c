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

/*
 * trmc.c
 *
 * see c_tcm.lua for map format
 */

#include <stdio.h>

#include <SDL/SDL_endian.h>

#define VERSION 1
#define MAGIC 0xDEADBEEF

#define TCM_FILENAME_BUF_SIZE 256
#define MAX_STRING_SIZE 512
#define MAX_STRING_STRUCT_CHARS 256
#define MAX_LINE_SIZE 1024

static int m_force = 0;  /* force overwriting compiled maps */

static const char *read_line = NULL;
static int read_pos = 0;

static void put_double(FILE *fout, const double *d)
{
    const unsigned char * const p = (const unsigned char *)d;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char)p[7], fout);
    fputc((const unsigned char)p[6], fout);
    fputc((const unsigned char)p[5], fout);
    fputc((const unsigned char)p[4], fout);
    fputc((const unsigned char)p[3], fout);
    fputc((const unsigned char)p[2], fout);
    fputc((const unsigned char)p[1], fout);
    fputc((const unsigned char)p[0], fout);
#else
    fputc((const unsigned char)p[0], fout);
    fputc((const unsigned char)p[1], fout);
    fputc((const unsigned char)p[2], fout);
    fputc((const unsigned char)p[3], fout);
    fputc((const unsigned char)p[4], fout);
    fputc((const unsigned char)p[5], fout);
    fputc((const unsigned char)p[6], fout);
    fputc((const unsigned char)p[7], fout);
#endif
}

static void put_float(FILE *fout, const float *f)
{
    const unsigned char *p = (const unsigned char *)f;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char)p[3], fout);
    fputc((const unsigned char)p[2], fout);
    fputc((const unsigned char)p[1], fout);
    fputc((const unsigned char)p[0], fout);
#else
    fputc((const unsigned char)p[0], fout);
    fputc((const unsigned char)p[1], fout);
    fputc((const unsigned char)p[2], fout);
    fputc((const unsigned char)p[3], fout);
#endif
}

static void put_int(FILE *fout, const int *i)
{
    const unsigned char *p = (const unsigned char *)i;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char)p[3], fout);
    fputc((const unsigned char)p[2], fout);
    fputc((const unsigned char)p[1], fout);
    fputc((const unsigned char)p[0], fout);
#else
    fputc((const unsigned char)p[0], fout);
    fputc((const unsigned char)p[1], fout);
    fputc((const unsigned char)p[2], fout);
    fputc((const unsigned char)p[3], fout);
#endif
}

static void put_short(FILE *fout, const short *s)
{
    const unsigned char *p = (const unsigned char *)s;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char)p[1], fout);
    fputc((const unsigned char)p[0], fout);
#else
    fputc((const unsigned char)p[0], fout);
    fputc((const unsigned char)p[1], fout);
#endif
}

static void put_char(FILE *fout, const char *c)
{
	const unsigned char *p = (const unsigned char *)c;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char)p[0], fout);
#else
    fputc((const unsigned char)p[0], fout);
#endif
}

static void put_cdouble(FILE *fout, const double d)
{
    const unsigned char *p = (const unsigned char *)&d;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char)p[7], fout);
    fputc((const unsigned char)p[6], fout);
    fputc((const unsigned char)p[5], fout);
    fputc((const unsigned char)p[4], fout);
    fputc((const unsigned char)p[3], fout);
    fputc((const unsigned char)p[2], fout);
    fputc((const unsigned char)p[1], fout);
    fputc((const unsigned char)p[0], fout);
#else
    fputc((const unsigned char)p[0], fout);
    fputc((const unsigned char)p[1], fout);
    fputc((const unsigned char)p[2], fout);
    fputc((const unsigned char)p[3], fout);
    fputc((const unsigned char)p[4], fout);
    fputc((const unsigned char)p[5], fout);
    fputc((const unsigned char)p[6], fout);
    fputc((const unsigned char)p[7], fout);
#endif
}

static void put_cfloat(FILE *fout, const float f)
{
    const unsigned char *p = (const unsigned char *)&f;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char)p[3], fout);
    fputc((const unsigned char)p[2], fout);
    fputc((const unsigned char)p[1], fout);
    fputc((const unsigned char)p[0], fout);
#else
    fputc((const unsigned char)p[0], fout);
    fputc((const unsigned char)p[1], fout);
    fputc((const unsigned char)p[2], fout);
    fputc((const unsigned char)p[3], fout);
#endif
}

static void put_cint(FILE *fout, const int i)
{
    const unsigned char *p = (const unsigned char *)&i;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char)p[3], fout);
    fputc((const unsigned char)p[2], fout);
    fputc((const unsigned char)p[1], fout);
    fputc((const unsigned char)p[0], fout);
#else
    fputc((const unsigned char)p[0], fout);
    fputc((const unsigned char)p[1], fout);
    fputc((const unsigned char)p[2], fout);
    fputc((const unsigned char)p[3], fout);
#endif
}

static void put_cshort(FILE *fout, const short s)
{
    const unsigned char *p = (const unsigned char *)&s;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char)p[1], fout);
    fputc((const unsigned char)p[0], fout);
#else
    fputc((const unsigned char)p[0], fout);
    fputc((const unsigned char)p[1], fout);
#endif
}

static void put_cchar(FILE *fout, const char c)
{
	const unsigned char *p = (const unsigned char *)&c;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char)p[0], fout);
#else
    fputc((const unsigned char)p[0], fout);
#endif
}

static void put_str(FILE *fout, const char *s, int l)
{
	while(l--)
		put_char(fout, s++);
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
#define MAX_WALLS 1024
#define MAX_TELEPORTERS 528
#define MAX_PLAYERSPAWNPOINTS 256
#define MAX_POWERUPSPAWNPOINTS 528
#define MAX_PATHS 528

typedef struct map_s map_t;
static struct map_s
{
	char name[64];
	char title[64];
	char description[64];
	char authors[512];
	char version_s[64];
	int version;
} maps[MAX_MAPS];

typedef struct wall_s wall_t;
static struct wall_s
{
	int quad;
	double x1; double y1;
	double x2; double y2;
	double x3; double y3;
	double x4; double y4;
	double tx1; double ty1;
	double tx2; double ty2;
	double tx3; double ty3;
	double tx4; double ty4;
	char texture[256];  /* hardcoded for format */
	int level;
	char target[MAX_STRING_STRUCT_CHARS];
	int path;
	int detail;
	int staticW;
} walls[MAX_WALLS];

typedef struct teleporter_s teleporter_t;
static struct teleporter_s
{
	char targetName[MAX_STRING_STRUCT_CHARS];
	char target[MAX_STRING_STRUCT_CHARS];
	double x1; double y1;
	int enabled;
} teleporters[MAX_TELEPORTERS];

typedef struct playerSpawnPoint_s playerSpawnPoint_t;
static struct playerSpawnPoint_s
{
	double x1; double y1;
} playerSpawnPoints[MAX_PLAYERSPAWNPOINTS];

typedef struct powerupSpawnPoint_s powerupSpawnPoint_t;
static struct powerupSpawnPoint_s
{
	double x1; double y1;
	char powerupsToEnable[MAX_STRING_STRUCT_CHARS];
} powerupSpawnPoints[MAX_POWERUPSPAWNPOINTS];

typedef struct path_s path_t;
static struct path_s
{
	char targetName[MAX_STRING_STRUCT_CHARS];
	char target[MAX_STRING_STRUCT_CHARS];
	double x1; double y1;
	int enabled;
	double time;
} paths[MAX_PATHS];

static int mc;
static int wc;
static int tc;
static int lc;
static int oc;
static int pc;

static void add_map(const char *name, const char *title, const char *description, const char *authors, const char *version_s, int version)
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
	strncpy(map->authors, description, sizeof(map->authors));
	strncpy(map->version_s, version_s, sizeof(map->version_s));
	map->version = version;
}

static void add_wall(int quad, double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4, double tx1, double ty1, double tx2, double ty2, double tx3, double ty3, double tx4, double ty4, const char *texture, int level, const char *target, int path, int detail, int staticW)
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
	wall->tx1 = tx1;
	wall->ty1 = ty1;
	wall->tx2 = tx2;
	wall->ty2 = ty2;
	wall->tx3 = tx3;
	wall->ty3 = ty3;
	wall->tx4 = tx4;
	wall->ty4 = ty4;
	strncpy(wall->texture, texture, sizeof(wall->texture));
	wall->level = level;
	strncpy(wall->target, texture, sizeof(wall->target));
	wall->path = path;
	wall->detail = detail;
	wall->staticW = staticW;
}

static void add_teleporter(const char *targetName, const char *target, double x1, double y1, int enabled)
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
}

static void add_playerSpawnPoint(double x1, double y1)
{
	playerSpawnPoint_t *playerSpawnPoint = &playerSpawnPoints[lc++];

	if(lc > MAX_PLAYERSPAWNPOINTS)
	{
		fprintf(stderr, "Error: playerSpawnPoint overflow (%d)\n", MAX_PLAYERSPAWNPOINTS);
		exit(1);
	}

	playerSpawnPoint->x1 = x1;
	playerSpawnPoint->y1 = y1;
}

static void add_powerupSpawnPoint(double x1, double y1, const char *powerupsToEnable)
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
}

static void add_path(const char *targetName, const char *target, double x1, double y1, int enabled, double time)
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
}


static char hidden(const char *filename)
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
	int j;
	char line[MAX_LINE_SIZE] = {""};

	/* reset counters */
	mc = wc = tc = lc = oc = pc = 0;

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

	/* first check we aren't overwriting anything undesirablely */
	fout = fopen(tcmFilename, "rb");
	if(fout)
	{
		fclose(fout);

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
					char authors[MAX_STRING_SIZE];
					char version_s[MAX_STRING_SIZE];
					int version;

					read_string(name);
					read_string(title);
					read_string(description);
					read_string(authors);
					read_string(version_s);
					version = read_int();

					add_map(name, title, description, authors, version_s, version);
				}
				else if(strncmp(entity, "wall", sizeof(entity)) == 0)
				{
					int quad;
					double x1, y1;
					double x2, y2;
					double x3, y3;
					double x4, y4;
					double tx1, ty1;
					double tx2, ty2;
					double tx3, ty3;
					double tx4, ty4;
					char texture[MAX_STRING_SIZE];
					int level;
					char target[MAX_STRING_SIZE];
					int path;
					int detail;
					int staticW;

					quad = read_int();
					x1 = read_double();
					y1 = read_double();
					x2 = read_double();
					y2 = read_double();
					x3 = read_double();
					y3 = read_double();
					x4 = read_double();
					y4 = read_double();
					tx1 = read_double();
					ty1 = read_double();
					tx2 = read_double();
					ty2 = read_double();
					tx3 = read_double();
					ty3 = read_double();
					tx4 = read_double();
					ty4 = read_double();
					read_string(texture);
					level = read_int();
					read_string(target);
					path = read_int();
					detail = read_int();
					staticW = read_int();

					add_wall(quad, x1, y1, x2, y2, x3, y3, x4, y4, tx1, ty1, tx2, ty2, tx3, ty3, tx4, ty4, texture, level, target, path, detail, staticW);
				}
				else if(strncmp(entity, "teleporter", sizeof(entity)) == 0)
				{
					char targetName[MAX_STRING_SIZE];
					char target[MAX_STRING_SIZE];
					double x1, y1;
					int enabled;

					read_string(targetName);
					read_string(target);
					x1 = read_double();
					y1 = read_double();
					enabled = read_int();

					add_teleporter(targetName, target, x1, y1, enabled);
				}
				else if(strncmp(entity, "playerSpawnPoint", sizeof(entity)) == 0)
				{
					double x1, y1;

					x1 = read_double();
					y1 = read_double();

					add_playerSpawnPoint(x1, y1);
				}
				else if(strncmp(entity, "powerupSpawnPoint", sizeof(entity)) == 0)
				{
					double x1, y1;
					char powerupsToEnable[MAX_STRING_SIZE];

					x1 = read_double();
					y1 = read_double();
					read_string(powerupsToEnable);

					add_powerupSpawnPoint(x1, y1, powerupsToEnable);
				}
				else if(strncmp(entity, "path", sizeof(entity)) == 0)
				{
					char targetName[MAX_STRING_SIZE];
					char target[MAX_STRING_SIZE];
					double x1, y1;
					int enabled;
					double time;

					read_string(targetName);
					read_string(target);
					x1 = read_double();
					y1 = read_double();
					enabled = read_int();
					time = read_double();

					add_path(targetName, target, x1, y1, enabled, time);
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

	if(!(fout = fopen(tcmFilename, "w")))
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
	put_str(fout, maps[0].description, 64);
	put_str(fout, maps[0].authors, 512);
	put_str(fout, maps[0].version_s, 64);
	put_cint(fout, maps[0].version);

	put_cint(fout, wc);
	put_cint(fout, tc);
	put_cint(fout, lc);
	put_cint(fout, oc);
	put_cint(fout, pc);

	for(i = 0; i < wc; i++)
	{
		int id = 0;
		wall_t *wall = &walls[i];

		/* find the target (it might not exist) */
		for(j = 0; j < tc; j++)
		{
			teleporter_t *teleporter = &teleporters[j];

			if(strcmp(wall->target, teleporter->targetName) == 0)
			{
				id = j;
				break;
			}
		}

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
		put_cdouble(fout, wall->tx1);
		put_cdouble(fout, wall->ty1);
		put_cdouble(fout, wall->tx2);
		put_cdouble(fout, wall->ty2);
		put_cdouble(fout, wall->tx3);
		put_cdouble(fout, wall->ty3);
		put_cdouble(fout, wall->tx4);
		put_cdouble(fout, wall->ty4);
		put_str(fout, wall->texture, 256);
		put_cint(fout, wall->level);
		put_cint(fout, id);
		put_cchar(fout, ((wall->path) ? (1) : (0)));
		put_cchar(fout, ((wall->detail) ? (1) : (0)));
		put_cchar(fout, ((wall->staticW) ? (1) : (0)));
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
	}

	for(i = 0; i < lc; i++)
	{
		playerSpawnPoint_t *playerSpawnPoint = &playerSpawnPoints[i];

		put_cint(fout, i);
		put_cdouble(fout, playerSpawnPoint->x1);
		put_cdouble(fout, playerSpawnPoint->y1);
	}

	for(i = 0; i < oc; i++)
	{
		int powerups[16] = {0};
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

		put_cint(fout, i);
		put_cdouble(fout, powerupSpawnPoint->x1);
		put_cdouble(fout, powerupSpawnPoint->y1);
		for(j = 0; j < sizeof(powerups) / sizeof(powerups[0]); j++)
		{
			put_cint(fout, powerups[j]);
		}
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
