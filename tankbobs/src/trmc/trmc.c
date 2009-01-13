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
tankbobs trm specification

NeedToRevise: tankbobs is set oriented.  And it doesn't support campaign..

note: trm to tcm is not one way.  Decompiling is more than possible.
tcm is not complex.  it's mroe a smaller and ready-to-be read by tankbobs

Note: Do no set integers to -214783646, -214783647 or -214783648; and doubles to 1.5e307, 1.6e307 or 1.7307
IF YOUR MAP JUST DOESN'T COMPILE OR MAKE ERROR'S WITHOUT ANY OUTPUT, THIS IS WHY!!
If you are absolutely SURE the map is clean and includes ALL OPTIONAL VALUES, and the map requires one of these values, use the option "-force"

{"map", integer id, string name, string title, optional string description, optional string authors, optional string version, optional string initscript, optional string exitscript}
{"set", integer id, integer order, string name, string title, string description, optional string authors, optional string version}
{"wall", string texture, string flags, string script1, string script2, string script3, double x1, double y1, double x2, double y2, double x3, double y3, optional double x4, optional double y3}
{"teleporter", integer group, integer active, double x, double y}
{"powerspawn", string powerups, integer enable, double x, double y}
{"spawnpoint", double x, double y}

map: this field defines the information of the map itself
		id: the map's unique id (unique to sets too); the typical convention
				 - is id's starting with 1 are sets (the _set_'s id), 2 are
				 - maps, 3 are maps in beta / progress, 4 are unfinished maps.
				 - the standard maps included in the official release also use
				 - this convention, but also prefix the id with an additional
				 - '9' (eg, a standard map in beta's id could be 93123)

		name: the map's name
		title: the map's title
		description: the map's description
		authors: one or more authors go here, however format, should not parsed
					 - by tankbobs

		version: once again, any format to your liking, tankbobs should not even
					 - bother with this value

		scripts: before scripts are executed, tcm_mapID and tcm_setID are set
set_id: if not a campaign map, set both of these to 0.  If it is, this
			 - tells the engine which set and order the map is linked
			 - to.  If two maps in the same set have the same order,
			 - the second map gets the slot and first gets overwritten

			id: the set's id to link to
			order: which order the level comes into the set.  Must be
					 - positive.  If this value is 1, the "set" field
					 - is read, otherwise the "set" field is ignored

set: if the map is campaign and order is 1, this field will define the set,
		 - otherwise this field is ignored, and specifying it is optional

		name: the set's name
		title: the set's title
		description: the set's description
		authors: one or more authors, whichever format, should not be parsed by
					 - tankbobs
		version: version, any format, should not be parsed by tankbobs

wall: a basic building block of all tankbobs maps - they can be used for trigger
		 - events, backgrounds, and walls themselves.  Walls are usually quads,
		 - and its vertices must be specified CCW.  When a script is executed,
		 - the script is looked for in scripts_dir/script.lua.  Before it is
		 - executed, world_wallID is set interally to the wall's id.  Note that
		 - the level's boundries always need to be present with nopass

		texture: the texture of the wall.  The engine will first look in
					 - texture_dir/name/texture where name is name specified as
					 - the value "name" in the "map" field.  If it isn't found,
					 - it looks for default_texture_dir/texture.  If that isn't
					 - found, it looks for texture_dir/texture (meant for
					 - accessing textures from other maps).  And if that isn't
					 - found, if the map is campaign, it looks in
					 - texture_dir/name/texture where name is the setname (this
					 - doesn't mean setname and mapname can't clash). And
					 - finally, if _that_ isn't found, the default texture is
					 - used, which usually should be invisible, null, black or
					 - white.

		flags: the flags of the wall.  The following flags are available:
				detail: the wall is detail - it isn't physically a part of the
							 - world

				structural: the wall is structural (this is the default)
				back-most: the wall is to be drawn first
				back: the wall is to be drawn on top of back-most
				back-least: the wall is to be drawn on top of back
				top-least: the wall is to be drawn immediately after tanks and
							 - everything else non-map (this is the default)

				top: the wall is to be drawn after top-least
				top-most: this wall covers everything else
				touch: (note that if another wall of the same size
						 - is under or on this wall, a touch event is not
						 - gaurneteed.  If you still need to cover a standard
						 - wall with a touch wall, stretch the touch wall out a
						 - bit) - script1 will be executed when a touch event is
						 - fired

				damage: script2 will be executed when a missile strikes it
				missiles: the wall reflects missiles instead of taking damage
							 - (the attack event will still be fired)

				nopass: the player can never pass this wall, even with special
							 - powerups.  This is typically used for level
							 - boundries

				back-mostmore: a new flag designed for specifically backgrounds
								 - this really is the most back

				back-mostmost: another new flag, usually same as mostmore.  If
								 - the background moves and the mapper has
								 - open spots that need to be filled, this
								 - flag is set as the filler for the open spots

		coordinates of type double: walls can be either triangular or
										 - rectangular.  0, 0 is the bottom left
										 - corner.  100, 100 is the top right,
										 - higher values are also valid, and not
										 - uncommon.  Tankbobs will stretch
										 - the screen if overview mode is on.
										 - if not, the screen will move with the
										 - player(s)

teleporter: define a teleporter
			group: two and only two teleporters of the same group
			active: set one teleporter to 0 to set the pair a 1-way teleporter
			coordinates: center; a teleporter has a height of 5 and a width of 5

powerspawn: define a powerup spawning location
				powerups: a string containing names of various powerups,
					 - seperated by commas (no spaces)

				enable: if this is true, all powerups but the ones listed will
							 - be disabled (meaning, only the powerups listed
							 - will be enabled), or if not true, all powerups
							 - will be enabled and the powerups listed will be
							 - disabled

				coordinates: center; a powerspawn has a height of 1 and a width
								 - of 1 (although it doesn't matter much)

spawnpoint: a tank spawnpoint
				cordinates: center, default 1 (doesn't matter?)
*/

/* the long awaited code to compile the trm format to the tcm format. consider this hackish and gets the job done */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <SDL/SDL_endian.h>

#define TCM_VERSION 1
#define MAGIC 0xDEADBEEF
#define WARNING -2147483647 /* must be non-zero */
#define NEXTFIELDEND 0 /* must be zero */
#define ERROR -214783648 /* must be non-zero */
#define NOVALUE -214783646 /* must be non-zero */
#define ERRORDOUBLE 1.7e307
#define WARNINGDOUBLE 1.6e307
#define NOVALUEDOUBLE  1.5e307
#define GOOD 0 /* must be zero */

void header(FILE *);

void map(FILE *, char *, char *);
void set(FILE *, char *, char *);
void wall(FILE *, char *, char *);
void teleporter(FILE *, char *, char *);
void powerspawn(FILE *, char *, char *);
void spawnpoint(FILE *, char *, char *);

void put_double(FILE *, const double *);
void put_float(FILE *, const float *);
void put_int(FILE *, const int *);
void put_short(FILE *, const short *);
void put_char(FILE *, const char *);
void put_cdouble(FILE *, const double);
void put_cfloat(FILE *, const float);
void put_cint(FILE *, const int);
void put_cshort(FILE *, const short);
void put_cchar(FILE *, const char);
void put_lstr(FILE *, const char *, unsigned long int, int);
void put_str(FILE *, const char *, int);

char *next_field_offset(char *);  /* exclusive, only these two functions returns 0 on end  */
char *next_field_close(char *);  /* exclusive, only these two functions returns 0 on end */
int validate(char *);
int restore(char *, char *);

char *stringvalue(char *, char *, int, int);  /* these 3 functions will insert a NULL byte before each , */
int integervalue(char *, char *, int, int);
double doublevalue(char *, char *, int, int);

static char *t = NULL;
static int force = 0;

int restore(char *start, char *end)
{
	int dq = 0;

	if(start >= end)
	{
		fprintf(stdout, "Warning: could not restore field - overlapping bounds\n");
		return WARNING;
	}

	for(; start < end; start++)
	{
		if(*start == '"')
			dq = !dq;
		if(!*start)
			*start = ((dq) ? '"' : ' ');
	}

	return GOOD;
}

char *stringvalue(char *start, char *end, int field, int nofieldNoWarning)
{
	int i, dq = 0;
	char *pos = start, *pos2;

	if(start >= end)
	{
		fprintf(stdout, "Warning: empty or small field\n");
		return (char *)WARNING;
	}

	/* first set pos to starting position of field (non-whitespace character after ,) */
	for(i = 0; i < field; i++)
	{
		while(pos < end && (dq || *pos != ','))
		{
			if(*pos == '"' && *(pos - 1) != '\\')
				dq = !dq;
			if(dq && !*pos)
				dq = !dq;
			pos++;
		}

		if(pos++ >= end)
		{
			if(!nofieldNoWarning)
			{
				if(!dq)
					fprintf(stdout, "Warning: too few fields for value requested\n");
				else
					fprintf(stdout, "Warning: unterminated string\n");
				return (char *)WARNING;
			}
			return (char *)NOVALUE;
		}
	}
	while(pos < end && *pos != ',' && (*pos == '\n' || *pos == ' ' || *pos == '\t' || *pos == '\r')) pos++;
	if(*pos == ',' || pos >= end)
	{
		if(!nofieldNoWarning)
		{
			fprintf(stdout, "Warning: cannot parse value requested\n");
			return (char *)WARNING;
		}
		return (char *)NOVALUE;
	}

	/* (after checking for "'s to reset pos, ) set pos2 to end of string */
	pos2 = pos;
	if(*pos == '"')
	{
		pos++;
		pos2++;
		while(pos2 < end && *pos2 && (*pos2 != '"' || *(pos2 - 1) == '\\')) pos2++;
		if(pos2 >= end)
		{
			fprintf(stdout, "Warning: unterminated string\n");
			return (char *)WARNING;
		}
		pos2--;
	}
	else
	{
		while(pos2 < end && *pos2 != ',') pos2++;
		do pos2--; while(pos2 > start && (*pos2 == '\n' || *pos2 == ' ' || *pos2 == '\t' || *pos2 == '\r'));
	}

	/* leave escapes to be dealt with in the function */
	/* insert NULL byte (replaces either " before the space before the comma, or the space before the comma) */
	*((*pos2 == '"' && pos2 != (pos - 1)) ? (pos2++) : (++pos2)) = 0;
	return pos;
}

int integervalue(char *start, char *end, int field, int nofieldNoWarning)
{
	int i, dq = 0, sign = 1, result = 0;
	char *pos = start;

	if(start >= end)
	{
		fprintf(stdout, "Warning: empty or small field\n");
		return WARNING;
	}

	/* first set pos to starting position of field (first digit) */
	for(i = 0; i < field; i++)
	{
		while(pos < end && (dq || *pos != ','))
		{
			if(*pos == '"' && *(pos - 1) != '\\')
				dq = !dq;
			if(dq && !*pos)
				dq = !dq;
			pos++;
		}

		if(pos++ >= end)
		{
			if(!nofieldNoWarning)
			{
				if(!dq)
					fprintf(stdout, "Warning: too few fields for value requested\n");
				else
					fprintf(stdout, "Warning: unterminated string\n");
				return WARNING;
			}
			return NOVALUE;
		}
	}
	while(pos < end && *pos != ',' && (*pos < '0' || *pos > '9') && *pos != '+' && *pos != '-') pos++;
	if(*pos == ',' || pos >= end)
	{
		if(!nofieldNoWarning)
		{
			fprintf(stdout, "Warning: cannot parse value requested\n");
			return WARNING;
		}
		return NOVALUE;
	}

	/* now parse the integer */
	if(*pos == '+' || *pos == '-')
	{
		if(*pos++ == '-')
			sign = -1;
	}
	if(*pos < '0' || *pos > '9')
	{
		if(!nofieldNoWarning)
		{
			fprintf(stdout, "Warning: integer value cannot be parsed - (sign?) missing integer\n");
			return WARNING;
		}
		return NOVALUE;
	}
	while(*pos >= '0' && *pos <= '9')
	{
		result = result * 10 + (*pos - '0');

		pos++;
	}

	/* we good! */
	return result * sign;
}

double doublevalue(char *start, char *end, int field, int nofieldNoWarning)
{
	int i, dq = 0;
	double sign = 1, result = 0.0;
	char *pos = start;

	if(start >= end)
	{
		fprintf(stdout, "Warning: empty or small field\n");
		return WARNINGDOUBLE;
	}

	/* first set pos to starting position of field (first digit) */
	for(i = 0; i < field; i++)
	{
		while(pos < end && (dq || *pos != ','))
		{
			if(*pos == '"' && *(pos - 1) != '\\')
				dq = !dq;
			if(dq && !*pos)
				dq = !dq;
			pos++;
		}

		if(pos++ >= end)
		{
			if(!nofieldNoWarning)
			{
				if(!dq)
					fprintf(stdout, "Warning: too few fields for value requested\n");
				else
					fprintf(stdout, "Warning: unterminated string\n");
				return WARNINGDOUBLE;
			}
			return NOVALUEDOUBLE;
		}
	}
	while(pos < end && *pos != ',' && (*pos < '0' || *pos > '9') && *pos != '+' && *pos != '-' && *pos != '.') pos++;
	if(*pos == ',' || pos >= end)
	{
		if(!nofieldNoWarning)
		{
			fprintf(stdout, "Warning: cannot parse value requested\n");
			return WARNINGDOUBLE;
		}
		return NOVALUEDOUBLE;
	}

	/* now parse the double */
	if(*pos == '+' || *pos == '-')
	{
		if(*pos++ == '-')
			sign = -1;
	}
	if(*pos != '.' && (*pos < '0' || *pos > '9'))
	{
		if(!nofieldNoWarning)
		{
			fprintf(stdout, "Warning: double value cannot be parsed - (sign?) missing double\n");
			return WARNINGDOUBLE;
		}
		return NOVALUEDOUBLE;
	}
	if(*pos == '.')
	{
		double depth = 0.1;

		pos++;

		if(*pos < '0' || *pos > '9')
		{
			if(!nofieldNoWarning)
			{
				fprintf(stdout, "Warning: double value cannot be parsed - (sign?) missing double\n");
				return WARNINGDOUBLE;
			}
			return NOVALUEDOUBLE;
		}

		while(*pos >= '0' && *pos <= '9')
		{
			result += (*pos - '0') * depth;
			depth *= 0.1;

			pos++;
		}
	}
	else
	{
		while(*pos >= '0' && *pos <= '9')
		{
			result = result * 10 + (*pos - '0');

			pos++;
		}
		if(*pos++ != '.')
		{
		}
		else if(*pos < '0' || *pos > '9')
		{
		}
		else
		{
			double depth = 0.1;

			while(*pos >= '0' && *pos <= '9')
			{
				result += (*pos - '0') * depth;
				depth *= 0.1;

				pos++;
			}
		}
	}

	/* we good! */
	return result * sign;
}

char *next_field_offset(char *in)
{
	while(*in)
	{
		if(*in++ == '{')
			return in;
	}

	return NEXTFIELDEND;
}

char *next_field_close(char *in)
{
	while(*in)
	{
		if(*in++ == '}')
			return (--in - 1); /* yuck */
	}

	return NEXTFIELDEND;
}

int validate(char *in)
{
	int count = 1;
	char field = '{';
	char *t = in, *pos = in;

	/* make sure there is something to parse */
	while(*pos != '{')
	{
		if(!*pos++)
		{
			fprintf(stdout, "Warning: nothing to validate\n");
			return WARNING;
		}
	} pos = t;

	/* validate an even number of {}'s */
	while(*pos)
	{
		if(*pos == '{' || *pos == '}')
			count++;

		if(!count)
		{
			fprintf(stdout, "Warning: too many fields");
			return WARNING;
		}

		pos++;
	} pos = t;
	count++;
	if(count % 2)
	{
		fprintf(stdout, "Warning: uneven number of {}'s");
		return WARNING;
	}

	/* validate the order of {}'s */
	while(*pos)
	{
		if(*pos == '{' || *pos == '}')
		{
			if(*pos != field)
			{
				fprintf(stdout, "Warning: invalid order of {}'s");
				return WARNING;
			}
			if(*pos == '{')
				field = '}';
			else
				field = '{';
		}

		pos++;
	} pos = t;

	/* we're good */
	return GOOD;
}

void put_double(FILE *fout, const double *d)
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

void put_float(FILE *fout, const float *f)
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

void put_int(FILE *fout, const int *i)
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

void put_short(FILE *fout, const short *s)
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

void put_char(FILE *fout, const char *c)
{
	const unsigned char *p = (const unsigned char *)c;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char)p[0], fout);
#else
    fputc((const unsigned char)p[0], fout);
#endif
}

void put_cdouble(FILE *fout, const double d)
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

void put_cfloat(FILE *fout, const float f)
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

void put_cint(FILE *fout, const int i)
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

void put_cshort(FILE *fout, const short s)
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

void put_cchar(FILE *fout, const char c)
{
	const unsigned char *p = (const unsigned char *)&c;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    fputc((const unsigned char)p[0], fout);
#else
    fputc((const unsigned char)p[0], fout);
#endif
}

void put_lstr(FILE *fout, const char *s, unsigned long int len, int escape)
{
	unsigned long int i;

	for(i = 0; i < len; i++)
	{
		if(escape && s[i] != '\\' && s[i + 1] != '\\')
		{
			fputc(s[++i], fout);
			continue;
		}

		if(!escape || (s[i] != '\\' && s[i + 1] != '"'))
			fputc(s[i], fout);
		else
			fputc(s[++i], fout);
	}
}

void put_str(FILE *fout, const char *s, int escape)
{
	unsigned long int i;

	if(!escape)
	{
		fputs(s, fout);
	}
	else
	{
		for(i = 0; i < strlen(s); i++)
		{
			if(escape && s[i] == '\\' && s[i + 1] == '\\')
			{
				fputc(s[++i], fout);
				continue;
			}

			if(!escape || (s[i] != '\\' && s[i + 1] != '"'))
				fputc(s[i], fout);
			else
				fputc(s[++i], fout);
		}
	}
}

static int validateExtension(char *ext)
{
	if(!ext)
		return 0;

	if(*ext++ != 't')
		return 0;

	if(*ext++ != 'r' && *ext-- && *ext++ != 'c')
		return 0;

	if(*ext++ != 'm')
		return 0;

	if(*ext--)
		return 0;

	return ((*--ext == 'r') ? (1) : (0)) + 1;
}

static void filenametotcm(char *map)
{
	char *pos = map;

	while(*pos++);
	while(pos-- > map && *pos != '.');

	if(*pos++ != '.')
	{
		fprintf(stderr, "file %s extension not known to trmc\n", map);
		exit(1);
	}

	if(!validateExtension(pos))
	{
		fprintf(stderr, "file %s extension not known to trmc\n", map);
		exit(1);
	}

	if(validateExtension(pos) == 2)
	{
		*++pos = 'c';
	}
}

static void filenametotrm(char *map)
{
	char *pos = map;

	while(*pos++);
	while(pos-- > map && *pos != '.');

	if(*pos++ != '.')
	{
		fprintf(stderr, "file %s extension not known to trmc\n", map);
		exit(ERROR);
	}

	if(!validateExtension(pos))
	{
		fprintf(stderr, "file %s extension not known to trmc\n", map);
		exit(ERROR);
	}

	if(validateExtension(pos) == 1)
	{
		*++pos = 'r';
	}
}

static void addSpacesBeforeCommasAndEnd(char *te)
{
	char *p = te;
	char ** const Po = &p, *pE = p;
	char *pB = *Po;
	while(*p++);
	pE = --p;
	p = pB;
	/* so now we have pB set to start, pE set to end(p->null turm) and variable p set to start */
	while(p < pE)
	{
		if(*p == ',' || *p == '}')
		{
			memmove(p + 1, p, pE++ - p);
			*p++ = ' ';
		}
		p++;
	} p = pB;
}

static int parse(char *in, FILE *fout)
{
	int result = GOOD, tmp;
	char *pos = in, *pos2 = in;

	if((result = validate(pos)))
	{
		return result;
	}

	addSpacesBeforeCommasAndEnd(in);

	if(!next_field_offset(pos))
	{
		fprintf(stdout, "Warning: nothing to parse\n");
		return WARNING;
	}

	header(fout);

	while((pos = next_field_offset(pos)))
	{
		if(!(pos2 = next_field_close(pos)))
		{
			fprintf(stderr, "corrupt file to parse\n");
			result |= ERROR;
			return ERROR;
		}

		if(stringvalue(pos, pos2, 0, 0) == (char *)ERROR)
		{
			result |= ERROR;
			return ERROR;
		}
		else if(stringvalue(pos, pos2, 0, 0) == (char *)WARNING)
		{
			result |= WARNING;
		}
		else if(stringvalue(pos, pos2, 0, 0) == (char *)GOOD)
		{
			/* do nothing */
		}
		else if(!strcmp(stringvalue(pos, pos2, 0, 0), "map"))
		{
			map(fout, pos, pos2);
		}
		else if(!strcmp(stringvalue(pos, pos2, 0, 0), "set"))
		{
			set(fout, pos, pos2);
		}
		else if(!strcmp(stringvalue(pos, pos2, 0, 0), "wall"))
		{
			wall(fout, pos, pos2);
		}
		else if(!strcmp(stringvalue(pos, pos2, 0, 0), "teleporter"))
		{
			teleporter(fout, pos, pos2);
		}
		else if(!strcmp(stringvalue(pos, pos2, 0, 0), "powerspawn"))
		{
			powerspawn(fout, pos, pos2);
		}
		else if(!strcmp(stringvalue(pos, pos2, 0, 0), "spawnpoint"))
		{
			spawnpoint(fout, pos, pos2);
		}
		else
		{
			result |= WARNING;
			fprintf(stdout, "Warning: field %s not known\n", stringvalue(pos, pos2, 0, 0));
		}

		if((tmp = restore(pos, pos2)))
		{
			result |= tmp;
			if(tmp != WARNING)
				return tmp;
		}
	} pos = pos2 = in;

	return result;
}

static void init0(char *m, unsigned long len)
{
	unsigned long i;

	for(i = 0L; i < len; i++)
	{
		m[i] = 0;
	}
}

static int trmc(char *map, int noprompt, int lowmem)
{
	int result;
	unsigned long i = 0L, len, size = 1L;
	FILE *trm = NULL;
	FILE *tcm = NULL;

	filenametotcm(map);
	if((tcm = fopen(map, "r")))
	{
		fclose(tcm);
		if(noprompt)
		{
			fprintf(stderr, "file %s exists\n", map);
			return ERROR;
		}
		fprintf(stdout, "file %s exists, overwrite? [y/N]: ", map);
		if(fgetc(stdin) != 'y')
			return ERROR;
		fprintf(stdout, "Overwriting (low memory disabled)...\n");
		lowmem = 0; /* TODO: allow multiple stdin's character retrieval */
	}
	if(!(tcm = fopen(map, "w")))
	{
		fprintf(stderr, "cannot open %s for writing\n", map);
		return ERROR;
	}
	filenametotrm(map);
	if(!(trm = fopen(map, "r")))
	{
		fprintf(stderr, "cannot open %s for reading\n", map);
		return ERROR;
	}

	/* calculate file size and dump into memory */
	while(size && fgetc(trm) != EOF) size++;
	if(!size || !++size)
	{
		fprintf(stderr, "file %s too big\n", map);
		return ERROR;
	}
	if(!(t = malloc((len = size-- * 2))))
	{
		if((t = malloc((len = size + 6))))
		{
			if(!lowmem)
			{
				free(t);
				fprintf(stderr, "file %s too big to dump into memory\n", map);
				return ERROR;
			}
			else
			{
				if(!noprompt)
				{
					fprintf(stdout, "low memory is available for file %s, try to continue anyway? [y/N]: ", map);
					if(fgetc(stdin) != 'y')
					{
					}
					else
					{
						fprintf(stdout, "Continuing (expect a segfault or other error)...\n");
					}
				}
				else
				{
					free(t);
					fprintf(stdout, "Warning: low memory for file %s is available\n", map);
					return WARNING;
				}
			}
		}
		else
		{
			fprintf(stderr, "file %s too big to dump into memory\n", map);
			return ERROR;
		}
	}
	init0(t, len);
	fseek(trm, 0, SEEK_SET);
	while(i < size && (t[i] = fgetc(trm)) != EOF) i++;
	t[i++] = 0;
	fclose(trm);

	/* Begin parsing.. */
	if((result = parse(t, tcm)))
	{
		free(t);
		fflush(tcm);
		fclose(tcm);
		filenametotcm(map);
		remove(map);
		filenametotrm(map);
		if(result == WARNING)
		{
			fprintf(stdout, "Warning: %s is not being compiled\n", map);
			return WARNING;
		}
		else
		{
			return result;
		}
	}

	/* write data */
	free(t);
	fflush(tcm);
	fclose(tcm);
	return GOOD;
}

static int find(const char *text, const char *find) /* 0 on not found or index + 1 */
{
	int i;
	const char * const oP = text;

	while(*text)
	{
		for(i = 0; i < strlen(find); i++)
		{
			if(text[i] != find[i])
				break;
		}
		if(i == strlen(find))
			return text + 1 - oP;
		text++;
	}

	return 0;
}

/* -------------------------------------------------------------------------- */

void header(FILE *fout)
{
	put_cchar(fout, 0x00);
	put_str(fout, "TCM", 0);
	put_cchar(fout, 0x01);
	put_cint(fout, MAGIC);
	put_cchar(fout, TCM_VERSION);
}

/*
{"map", integer id, string name, string title, optional string description, optional string authors, optional string version, optional string initscript, optional string exitscript}
{"set", string name, string title, string description, optional string authors, optional string version}
{"wall", string texture, string flags, string script1, string script2, string script3, double x1, double y1, double x2, double y2, double x3, double y3, optional double x4, optional double y3}
{"teleporter", integer group, integer active, double x, double y}
{"powerspawn", string powerups, integer enable, double x, double y}
{"spawnpoint", double x, double y}
*/

void map(FILE *fout, char *start, char *end)
{
	int id;
	char *name, *title, *description, *authors = NULL, *version = NULL, *initscript = NULL, *exitscript = NULL;  /* shut up GCC! */

	id = integervalue(start, end, 1, 0);
	if(!force && (id <= 0))
	{
		fprintf(stderr, "compiled map supplied a non-positive id\n");
		exit(ERROR);
	}
	if(!force && (id == ERROR || id == WARNING))
	{
		exit(id);
	}

	name = stringvalue(start, end, 2, 0);
	if(!force && (name == (char *)ERROR || name == (char *)WARNING))
	{
		exit((int)name);
	}
	if(!force && !name)
	{
		fprintf(stderr, "an unknown error has occured (1)\n");
		exit(ERROR);
	}

	title = stringvalue(start, end, 3, 0);
	if(!force && (title == (char *)ERROR || title == (char *)WARNING))
	{
		exit((int)title);
	}
	if(!force && !title)
	{
		fprintf(stderr, "an unknown error has occured (2)\n");
		exit(ERROR);
	}

	description = stringvalue(start, end, 4, 1);
	if(force || (description != (char *)NOVALUE && description))
	{
		if(!force && (description == (char *)ERROR || description == (char *)WARNING))
		{
			exit((int)description);
		}
		else
		{
			authors = stringvalue(start, end, 5, 1);
			if(force || (authors != (char *)NOVALUE && authors))
			{
				if(!force && (authors == (char *)ERROR || authors == (char *)WARNING))
				{
					exit((int)authors);
				}
				else
				{
					version = stringvalue(start, end, 6, 1);
					if(force || (version != (char *)NOVALUE && version))
					{
						if(!force && (version == (char *)ERROR || version == (char *)WARNING))
						{
							exit((int)version);
						}
						else
						{
							initscript = stringvalue(start, end, 7, 1);
							if(force || (initscript != (char *)NOVALUE && initscript))
							{
								if(!force && (initscript == (char *)ERROR || initscript == (char *)WARNING))
								{
									exit((int)initscript);
								}
								else
								{
									exitscript = stringvalue(start, end, 8, 1);
									if(force || (exitscript != (char *)NOVALUE && exitscript))
									{
										if(!force && (exitscript == (char *)ERROR || exitscript == (char *)WARNING))
										{
											exit((int)exitscript);
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}

	put_cchar(fout, 0x01);
	put_cint(fout, id);
	put_cint(fout, 0x00000000);
	put_str(fout, name, 1);
	put_cchar(fout, 0x00);
	put_cint(fout, 0x00000000);
	put_str(fout, title, 1);
	put_cchar(fout, 0x00);
	if(force || (description && description != (char *)NOVALUE))
	{
		put_cint(fout, 0x00000000);
		put_str(fout, description, 1);
		put_cchar(fout, 0x00);
		if(force || (authors && authors != (char *)NOVALUE))
		{
			put_cint(fout, 0x00000000);
			put_str(fout, authors, 1);
			put_cchar(fout, 0x00);
			if(force || (version && version != (char *)NOVALUE))
			{
				put_cint(fout, 0x00000000);
				put_str(fout, version, 1);
				put_cchar(fout, 0x00);
				if(force || (initscript && initscript != (char *)NOVALUE))
				{
					put_cint(fout, 0x00000000);
					put_str(fout, initscript, 1);
					put_cchar(fout, 0x00);
					if(force || (exitscript && exitscript != (char *)NOVALUE))
					{
						put_cint(fout, 0x00000000);
						put_str(fout, exitscript, 1);
						put_cchar(fout, 0x00);
					}
					else
					{
						put_cint(fout, 0x00000000);
						put_cchar(fout, 0x00);
					}
				}
				else
				{
					put_cint(fout, 0x00000000);
					put_cchar(fout, 0x00);
					put_cint(fout, 0x00000000);
					put_cchar(fout, 0x00);
				}
			}
			else
			{
				put_cint(fout, 0x00000000);
				put_cchar(fout, 0x00);
				put_cint(fout, 0x00000000);
				put_cchar(fout, 0x00);
				put_cint(fout, 0x00000000);
				put_cchar(fout, 0x00);
			}
		}
		else
		{
			put_cint(fout, 0x00000000);
			put_cchar(fout, 0x00);
			put_cint(fout, 0x00000000);
			put_cchar(fout, 0x00);
			put_cint(fout, 0x00000000);
			put_cchar(fout, 0x00);
			put_cint(fout, 0x00000000);
			put_cchar(fout, 0x00);
		}
	}
}

void set(FILE *fout, char *start, char *end)
{
	int id, order;
	char *name, *title, *description, *authors = NULL, *version = NULL;  /* shut up GCC! */

	id = integervalue(start, end, 1, 0);
	if(!force && (id == ERROR || id == WARNING))
	{
		exit(id);
	}

	order = integervalue(start, end, 2, 0);
	if(!force && (order == ERROR || order == WARNING))
	{
		exit(order);
	}

	name = stringvalue(start, end, 3, 0);
	if(!force && (name == (char *)ERROR || name == (char *)WARNING))
	{
		exit((int)name);
	}
	if(!force && !name)
	{
		fprintf(stderr, "an unknown error has occured (3)\n");
		exit(ERROR);
	}

	title = stringvalue(start, end, 4, 0);
	if(!force && (title == (char *)ERROR || title == (char *)WARNING))
	{
		exit((int)title);
	}
	if(!title)
	{
		fprintf(stderr, "an unknown error has occured (4)\n");
		exit(ERROR);
	}

	description = stringvalue(start, end, 5, 1);
	if(force || (description != (char *)NOVALUE && description))
	{
		if(!force && (description == (char *)ERROR || description == (char *)WARNING))
		{
			exit((int)description);
		}
		else
		{
			authors = stringvalue(start, end, 6, 1);
			if(force || (authors != (char *)NOVALUE && authors))
			{
				if(!force && (authors == (char *)ERROR || authors == (char *)WARNING))
				{
					exit((int)authors);
				}
				else
				{
					version = stringvalue(start, end, 7, 1);
					if(force || (version != (char *)NOVALUE && version))
					{
						if(!force && (version == (char *)ERROR || version == (char *)WARNING))
						{
							exit((int)version);
						}
					}
				}
			}
		}
	}

	if(!force && (id <= 0 || order <= 0))
	{
		fprintf(stderr, "invalid id and order");
		exit(ERROR);
#if 0
		put_cchar(fout, 0x02);
		put_cint(fout, 0x00000000);
		put_cint(fout, 0x00000000);
#endif
	}
	else
	{
		put_cchar(fout, 0x02);
		put_cint(fout, id);
		put_cint(fout, order);
	}

	put_cint(fout, 0x00000000);
	put_str(fout, name, 1);
	put_cchar(fout, 0x00);
	put_cint(fout, 0x00000000);
	put_str(fout, title, 1);
	put_cchar(fout, 0x00);
	if(force || (description && description != (char *)NOVALUE))
	{
		put_cint(fout, 0x00000000);
		put_str(fout, description, 1);
		put_cchar(fout, 0x00);
		if(force || (authors && authors != (char *)NOVALUE))
		{
			put_cint(fout, 0x00000000);
			put_str(fout, authors, 1);
			put_cchar(fout, 0x00);
			if(force || (version && version != (char *)NOVALUE))
			{
				put_cint(fout, 0x00000000);
				put_str(fout, version, 1);
				put_cchar(fout, 0x00);
			}
			else
			{
				put_cint(fout, 0x00000000);
				put_cchar(fout, 0x00);
			}
		}
		else
		{
			put_cint(fout, 0x00000000);
			put_cchar(fout, 0x00);
			put_cint(fout, 0x00000000);
			put_cchar(fout, 0x00);
		}
	}
	else
	{
		put_cint(fout, 0x00000000);
		put_cchar(fout, 0x00);
		put_cint(fout, 0x00000000);
		put_cchar(fout, 0x00);
		put_cint(fout, 0x00000000);
		put_cchar(fout, 0x00);
	}
}

void wall(FILE *fout, char *start, char *end)
{
	char *texture, *flags, *script1, *script2, *script3;
	double x1, y1, x2, y2, x3, y3, x4, y4;

	texture = stringvalue(start, end, 1, 0);
	if(!force && (texture == (char *)ERROR || texture == (char *)WARNING))
	{
		exit((int)texture);
	}
	if(!force && !texture)
	{
		fprintf(stderr, "an unknown error has occured (5)\n");
		exit(ERROR);
	}

	flags = stringvalue(start, end, 2, 0);
	if(!force && (flags == (char *)ERROR || flags == (char *)WARNING))
	{
		exit((int)flags);
	}
	if(!force && !flags)
	{
		fprintf(stderr, "an unknown error has occured (6)\n");
		exit(ERROR);
	}

	script1 = stringvalue(start, end, 3, 0);
	if(!force && (script1 == (char *)ERROR || script1 == (char *)WARNING))
	{
		exit((int)script1);
	}
	if(!force && !script1)
	{
		fprintf(stderr, "an unknown error has occured (7)\n");
		exit(ERROR);
	}

	script2 = stringvalue(start, end, 4, 0);
	if(!force && (script2 == (char *)ERROR || script2 == (char *)WARNING))
	{
		exit((int)script2);
	}
	if(!force && !script2)
	{
		fprintf(stderr, "an unknown error has occured (8)\n");
		exit(ERROR);
	}

	script3 = stringvalue(start, end, 5, 0);
	if(!force && (script3 == (char *)ERROR || script3 == (char *)WARNING))
	{
		exit((int)script3);
	}
	if(!force && !script3)
	{
		fprintf(stderr, "an unknown error has occured (9)\n");
		exit(ERROR);
	}

	x1 = doublevalue(start, end, 6, 0);
	y1 = doublevalue(start, end, 7, 0);
	if(!force && (x1 == ERRORDOUBLE || x1 == WARNINGDOUBLE || y1 == ERRORDOUBLE || y1 == WARNINGDOUBLE))
	{
		exit((int)((int)x1 | (int)y1));
	}
	x2 = doublevalue(start, end, 8, 0);
	y2 = doublevalue(start, end, 9, 0);
	if(!force && (x2 == ERRORDOUBLE || x2 == WARNINGDOUBLE || y2 == ERRORDOUBLE || y2 == WARNINGDOUBLE))
	{
		exit((int)((int)x2 | (int)y2));
	}
	x3 = doublevalue(start, end, 10, 0);
	y3 = doublevalue(start, end, 11, 0);
	if(!force && (x3 == ERRORDOUBLE || x3 == WARNINGDOUBLE || y3 == ERRORDOUBLE || y3 == WARNINGDOUBLE))
	{
		exit((int)((int)x3 | (int)y3));
	}
	x4 = doublevalue(start, end, 12, 1);
	y4 = doublevalue(start, end, 13, 1);
	if(!force && (x4 == ERRORDOUBLE || x4 == WARNINGDOUBLE || y4 == ERRORDOUBLE || y4 == WARNINGDOUBLE))
	{
		exit((int)((int)x4 | (int)y4));
	}

	put_cchar(fout, 0x03);
	put_cint(fout, 0x00000000);
	put_str(fout, texture, 1);
	put_cchar(fout, 0x00);
	put_cint(fout, 0x00000000);
	if(find(flags, "detail") && !find(flags, "structural"))
	{
		put_cchar(fout, 0x01);
	}
	if(find(flags, "back-most"))
	{
		put_cchar(fout, 0x02);
	}
	if(find(flags, "back"))
	{
		put_cchar(fout, 0x03);
	}
	if(find(flags, "back-least"))
	{
		put_cchar(fout, 0x04);
	}
	if(find(flags, "top-least"))
	{
		put_cchar(fout, 0x05);
	}
	if(find(flags, "top"))
	{
		put_cchar(fout, 0x06);
	}
	if(find(flags, "top-most"))
	{
		put_cchar(fout, 0x07);
	}
	if(find(flags, "touch"))
	{
		put_cchar(fout, 0x08);
	}
	if(find(flags, "damage"))
	{
		put_cchar(fout, 0x09);
	}
	if(find(flags, "missiles"))
	{
		put_cchar(fout, 0x0A);
	}
	if(find(flags, "nopass"))
	{
		put_cchar(fout, 0x0B);
	}
	if(find(flags, "back-mostmore"))
	{
		put_cchar(fout, 0x0C);
	}
	put_cchar(fout, 0x00);
	put_cint(fout, 0x00000000);
	put_str(fout, script1, 1);
	put_cchar(fout, 0x00);
	put_cint(fout, 0x00000000);
	put_str(fout, script2, 1);
	put_cchar(fout, 0x00);
	put_cint(fout, 0x00000000);
	put_str(fout, script3, 1);
	put_cchar(fout, 0x00);
	put_cdouble(fout, x1);
	put_cdouble(fout, y1);
	put_cdouble(fout, x2);
	put_cdouble(fout, y2);
	put_cdouble(fout, x3);
	put_cdouble(fout, y3);
	if(force || (x4 != NOVALUEDOUBLE && y4 != NOVALUEDOUBLE))
	{
		put_cdouble(fout, x4);
		put_cdouble(fout, y4);
	}
	else
	{
		put_cdouble(fout, (double)((int)-1));
		put_cdouble(fout, (double)((int)-1));
	}
}

void teleporter(FILE *fout, char *start, char *end)
{
	int group, active;
	double x, y;

	fprintf(stderr, "teleporter no longer supported\n");
	exit(ERROR);

	group = integervalue(start, end, 1, 0);
	if(!force && (group <= 0))
	{
		fprintf(stderr, "compiled map supplied a non-positive teleporter group\n");
		exit(ERROR);
	}
	if(!force && (group == ERROR || group == WARNING))
	{
		exit(group);
	}

	active = integervalue(start, end, 2, 0);
	if(!force && (active == ERROR || active == WARNING))
	{
		exit(active);
	}

	x = doublevalue(start, end, 3, 0);
	if(!force && (x == ERRORDOUBLE || x == WARNINGDOUBLE))
	{
		exit((int)x);
	}

	y = doublevalue(start, end, 4, 0);
	if(!force && (y == ERRORDOUBLE || y == WARNINGDOUBLE))
	{
		exit((int)y);
	}

	put_cchar(fout, 0x04);
	put_cint(fout, group);
	put_cint(fout, active);
	put_cdouble(fout, x);
	put_cdouble(fout, y);
}

void powerspawn(FILE *fout, char *start, char *end)
{
	char *powerups;
	int enabled;
	double x, y;

	powerups = stringvalue(start, end, 1, 0);
	if(!force && (powerups == (char *)ERROR || powerups == (char *)WARNING))
	{
		exit((int)powerups);
	}
	if(!force && !powerups)
	{
		fprintf(stderr, "an unknown error has occured (10)\n");
		exit(ERROR);
	}

	enabled = integervalue(start, end, 2, 0);
	if(!force && (enabled == ERROR || enabled == WARNING))
	{
		exit(enabled);
	}

	x = doublevalue(start, end, 3, 0);
	if(!force && (x == ERRORDOUBLE || x == WARNINGDOUBLE))
	{
		exit((int)x);
	}

	y = doublevalue(start, end, 4, 0);
	if(!force && (y == ERRORDOUBLE || y == WARNINGDOUBLE))
	{
		exit((int)y);
	}

	put_cchar(fout, 0x05);
	put_cint(fout, 0x00000000);
	put_str(fout, powerups, 1);
	put_cchar(fout, 0x00);
	put_cint(fout, enabled);
	put_cdouble(fout, x);
	put_cdouble(fout, y);
}

void spawnpoint(FILE *fout, char *start, char *end)
{
	double x, y;

	x = doublevalue(start, end, 1, 0);
	if(!force && (x == ERRORDOUBLE || x == WARNINGDOUBLE))
	{
		exit((int)x);
	}

	y = doublevalue(start, end, 2, 0);
	if(!force && (y == ERRORDOUBLE || y == WARNINGDOUBLE))
	{
		exit((int)y);
	}

	put_cchar(fout, 0x06);
	put_cdouble(fout, x);
	put_cdouble(fout, y);
}

/* -------------------------------------------------------------------------- */

int main(int argc, char **argv)
{
	int i = 1, result, noprompt = 0, lowmem = 0;

	if(ERRORDOUBLE == WARNINGDOUBLE || ERRORDOUBLE == NOVALUEDOUBLE || WARNINGDOUBLE == NOVALUEDOUBLE || ERROR == WARNING || ERROR == NOVALUE || WARNING == NOVALUE || ERROR == 0 || WARNING == 0 || GOOD != 0 || NOVALUE == 0)
	{
		fprintf(stderr, "error case ambiguity (a problem in the build)\n");
		return 1;
	}

	if(i >= 1 && argc > 1 && !strcmp(argv[1], "-noprompt"))
	{
		i++;
		noprompt++;
	}

	if(i >= 1 && argc > 1 && !strcmp(argv[1], "-lowmem"))
	{
		i++;
		lowmem++;
	}

	if(i >= 1 && argc > 1 && !strcmp(argv[1], "-force"))
	{
		i++;
		force++;
	}

	if(i >= 2 && argc > 2 && !strcmp(argv[2], "-noprompt"))
	{
		i++;
		noprompt++;
	}

	if(i >= 2 && argc > 2 && !strcmp(argv[2], "-lowmem"))
	{
		i++;
		lowmem++;
	}

	if(i >= 2 && argc > 2 && !strcmp(argv[2], "-force"))
	{
		i++;
		force++;
	}

	if(i >= 3 && argc > 3 && !strcmp(argv[3], "-noprompt"))
	{
		i++;
		noprompt++;
	}

	if(i >= 3 && argc > 3 && !strcmp(argv[3], "-lowmem"))
	{
		i++;
		lowmem++;
	}

	if(i >= 3 && argc > 3 && !strcmp(argv[3], "-force"))
	{
		i++;
		force++;
	}

	for(; i < argc; i++)
	{
		if((result = trmc(argv[i], noprompt, lowmem)))
		{
			if(result != WARNING || noprompt)
				return result;
		}
	}

	return 0;
}
