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

#include <cstdlib>
#include <QApplication>
#include <vector>
#include <fstream>
#include "tankbobs-editor.h"
#include "trm.h"
#include "util.h"
#include "entities.h"
#include "config.h"
#include "properties.h"

extern QString file;

bool modified = false;

int transformation = t_none;
extern Tankbobs_editor *window;
void *selection;
int selectionType = e_selectionNone;
entities::Map tmap;
vector<entities::PlayerSpawnPoint *>  playerSpawnPoint;
vector<entities::PowerupSpawnPoint *> powerupSpawnPoint;
vector<entities::Teleporter *>        teleporter;
vector<entities::Wall *>              wall;
vector<entities::Path *>              path;
vector<void *>                        selections;  // list of _previously_ selected
//vector<void *>                        selection;  // actual selection

extern double zoom;
extern int x_scroll, y_scroll;

// isSelected returns 0 if not selected, else returns value in relation
// to last selected.  for example, if entity e was last selected, 1 in returned.
// if e was second to be selected 2 is returned.
int trm_isSelected(void *e)
{
	return e == selection;

#if 0
	int c = 0;
	void *t;

	for(vector<entities::void *>::reverse_iterator i = selection.rbegin; i != selection.rend; ++i)
	{
		c++;
		t = reinterpret_cast<void *>(*i);
		if(t == e)
		{
			return c;
		}
	}

	return false;
#endif
}

void trm_setSelected(void *e)
{
	selection = e;

#if 0
	selection.push_back(e);
#endif
}

void trm_clearAndSetSelected(void *e)
{
	selection = e;

#if 0
	selection.clear();
	selection.push_back(e);
#endif
}

void trm_modifyAttempted()
{
	window->statusAppend("Modify attempted in read-only mode");
}

/*
These function were copied from trmc.c
*/

static const char *read_line = NULL;
static int read_pos = 0;

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
		while(*p && p - read_line < 1024)
		{
			if(*p++ == ',')
				break;
		}

		if(!*p)
		{
			fprintf(stderr, "Error: too few fields: '%s'\n", read_line);
			exit(1);
		}

		if(p - read_line >= 1024)
		{
			fprintf(stderr, "Error: line is too long: '%s'\n", read_line);
			exit(1);
		}
	}

	/* check for overflows */
	p2 = p;

	while(*p2++)
	{
		if(p2 - read_line >= 1024)
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
		while(*p && p - read_line < 1024)
		{
			if(*p++ == ',')
				break;
		}

		if(!*p)
		{
			fprintf(stderr, "Error: too few fields: '%s'\n", read_line);
			exit(1);
		}

		if(p - read_line >= 1024)
		{
			fprintf(stderr, "Error: line is too long: '%s'\n", read_line);
			exit(1);
		}
	}

	/* check for overflows */
	p2 = p;

	while(*p2++)
	{
		if(p2 - read_line >= 1024)
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
		while(*p && p - read_line < 1024)
		{
			if(*p++ == ',')
				break;
		}

		if(!*p)
		{
			fprintf(stderr, "Error: too few fields: '%s'\n", read_line);
			exit(1);
		}

		if(p - read_line >= 1024)
		{
			fprintf(stderr, "Error: line is too long: '%s'\n", read_line);
			exit(1);
		}
	}

	/* check for overflows */
	p2 = p;

	while(*p2++)
	{
		if(p2 - read_line >= 1024)
		{
			fprintf(stderr, "Error: line is too long: '%s'\n", read_line);
			exit(1);
		}
	}

	/* skip whitespace */
	while(*p == ' ' || *p == '\t') p++;

	/* read the string */

	i = s[0] = 0;

	while(*p != ',' && i < 1024 - 1)
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

/* */

bool trm_open(const char *filename, bool import)  // Will not confirm unsaved progress!
{
	char c;
	FILE *fin;
	string line;

	if(!(fin = fopen(filename, "r")))
		return false;

	if(!import)
	{
		modified = false;
		tmap = entities::Map();
		playerSpawnPoint.clear();
		powerupSpawnPoint.clear();
		teleporter.clear();
		wall.clear();
		path.clear();
	}
	else
	{
		modified = true;
		file = "";
	}

	while((c = fgetc(fin)) != EOF)
	{
		if(c == '\n')
		{
			if(!line.empty())
			{
				char entity[1024];

				if(!read_reset(line.c_str()))
				{
					fprintf(stderr, "Error reading file: '%s'\n", filename);
					fclose(fin);
					return false;
				}

				read_string(entity);
				if(strncmp(entity, "map", sizeof(entity)) == 0)
				{
					char name[1024];
					char title[1024];
					char description[1024];
					char authors[1024];
					char version_s[1024];
					int version;

					read_string(name);
					read_string(title);
					read_string(description);
					read_string(authors);
					read_string(version_s);
					version = read_int();

					tmap.name = string(name);
					tmap.title = string(title);
					tmap.description = string(description);
					tmap.authors = string(authors);
					tmap.version_s = string(version_s);
					tmap.version = version;
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
					char texture[1024];
					int level;
					char target[1024];
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

					wall.push_back(new entities::Wall(x1, y1, quad, x2, y2, x3, y3, x4, y4, tx1, ty1, tx2, ty2, tx3, ty3, tx4, ty4, texture, level, target, path, detail, staticW));
				}
				else if(strncmp(entity, "teleporter", sizeof(entity)) == 0)
				{
					char targetName[1024];
					char target[1024];
					double x1, y1;
					int enabled;

					read_string(targetName);
					read_string(target);
					x1 = read_double();
					y1 = read_double();
					enabled = read_int();

					teleporter.push_back(new entities::Teleporter(x1, y1, targetName, target, enabled));
				}
				else if(strncmp(entity, "playerSpawnPoint", sizeof(entity)) == 0)
				{
					double x1, y1;

					x1 = read_double();
					y1 = read_double();

					playerSpawnPoint.push_back(new entities::PlayerSpawnPoint(x1, y1));
				}
				else if(strncmp(entity, "powerupSpawnPoint", sizeof(entity)) == 0)
				{
					double x1, y1;
					char powerupsToEnable[1024];
					int linked;
					double repeat;
					double initial;
					int focus;

					x1 = read_double();
					y1 = read_double();
					read_string(powerupsToEnable);
					linked = read_int();
					repeat = read_double();
					initial = read_double();
					focus = read_int();

					powerupSpawnPoint.push_back(new entities::PowerupSpawnPoint(x1, y1, powerupsToEnable, linked, repeat, initial, focus));
				}
				else if(strncmp(entity, "path", sizeof(entity)) == 0)
				{
					char targetName[1024];
					char target[1024];
					double x1, y1;
					int enabled;
					double time;

					read_string(targetName);
					read_string(target);
					x1 = read_double();
					y1 = read_double();
					enabled = read_int();
					time = read_double();

					path.push_back(new entities::Path(x1, y1, targetName, target, enabled, time));
				}

				else
				{
					fclose(fin);
					fprintf(stderr, "Unknown entity when reading '%s': '%s'\n", filename, entity);
					return false;
				}


				line.clear();
			}
		}
		else
		{
			line.append(1, c);
		}
	}

	if(!line.empty())
	{
		fprintf(stderr, "Error: ignored trailing line missing a newline character while reading '%s'\n", filename);
		fclose(fin);
		return false;
	}

	fclose(fin);

	return true;
}

bool trm_save(const char *filename)
{
	if(config_get_int(c_noModify))
	{
		trm_modifyAttempted();
		return false;
	}

	ofstream fout(filename, ios::out | ios::trunc);
	if(fout.fail())
		return false;

	fout << "map, "
		<< tmap.name
		<< ", "
		<< tmap.title
		<< ", "
		<< tmap.description
		<< ", "
		<< tmap.authors
		<< ", "
		<< tmap.version_s
		<< ", "
		<< tmap.version
		<< endl;

	for(vector<entities::Wall *>::iterator i = wall.begin(); i != wall.end(); ++i)
	{
		entities::Wall *e = *i;

		if(!e->target[0])
			e->target = "";

		fout << "wall, "
		<< static_cast<int>(e->quad)
		<< ", "
		<< e->x1
		<< ", "
		<< e->y1
		<< ", "
		<< e->x2
		<< ", "
		<< e->y2
		<< ", "
		<< e->x3
		<< ", "
		<< e->y3
		<< ", "
		<< e->x4
		<< ", "
		<< e->y4
		<< ", "
		<< e->tx1
		<< ", "
		<< e->ty1
		<< ", "
		<< e->tx2
		<< ", "
		<< e->ty2
		<< ", "
		<< e->tx3
		<< ", "
		<< e->ty3
		<< ", "
		<< e->tx4
		<< ", "
		<< e->ty4
		<< ", "
		<< e->texture
		<< ", "
		<< e->level
		<< ", "
		<< e->target
		<< ", "
		<< e->path
		<< ", "
		<< e->detail
		<< ", "
		<< e->staticW
		<< endl;
	}

	for(vector<entities::Teleporter *>::iterator i = teleporter.begin(); i != teleporter.end(); ++i)
	{
		entities::Teleporter *e = *i;

		fout << "teleporter, "
		<< e->targetName
		<< ", "
		<< e->target
		<< ", "
		<< e->x
		<< ", "
		<< e->y
		<< ", "
		<< e->enabled
		<< endl;
	}

	for(vector<entities::PlayerSpawnPoint *>::iterator i = playerSpawnPoint.begin(); i != playerSpawnPoint.end(); ++i)
	{
		entities::PlayerSpawnPoint *e = *i;

		fout << "playerSpawnPoint, "
		<< e->x
		<< ", "
		<< e->y
		<< endl;
	}

	for(vector<entities::PowerupSpawnPoint *>::iterator i = powerupSpawnPoint.begin(); i != powerupSpawnPoint.end(); ++i)
	{
		entities::PowerupSpawnPoint *e = *i;

		fout << "powerupSpawnPoint, "
		<< e->x
		<< ", "
		<< e->y
		<< ", "
		<< e->powerups
		<< ", "
		<< e->linked
		<< ", "
		<< e->repeat
		<< ", "
		<< e->initial
		<< ", "
		<< e->focus
		<< endl;
	}

	for(vector<entities::Path *>::iterator i = path.begin(); i != path.end(); ++i)
	{
		entities::Path *e = *i;

		fout << "path, "
		<< e->targetName
		<< ", "
		<< e->target
		<< ", "
		<< e->x
		<< ", "
		<< e->y
		<< ", "
		<< e->enabled
		<< ", "
		<< e->time
		<< endl;
	}

	fout.close();
	if(fout.fail())
		return false;

	return true;
}

bool trm_isWall(void *e)
{
	for(vector<entities::Wall *>::iterator i = wall.begin(); i != wall.end(); ++i)
		if(e == *i)
			return true;

	return false;
}

bool trm_isTeleporter(void *e)
{
	for(vector<entities::Teleporter *>::iterator i = teleporter.begin(); i != teleporter.end(); ++i)
		if(e == *i)
			return true;

	return false;
}

bool trm_isPlayerSpawnPoint(void *e)
{
	for(vector<entities::PlayerSpawnPoint *>::iterator i = playerSpawnPoint.begin(); i != playerSpawnPoint.end(); ++i)
		if(e == *i)
			return true;

	return false;
}

bool trm_isPowerupSpawnPoint(void *e)
{
	for(vector<entities::PowerupSpawnPoint *>::iterator i = powerupSpawnPoint.begin(); i != powerupSpawnPoint.end(); ++i)
		if(e == *i)
			return true;

	return false;
}

bool trm_isPath(void *e)
{
	for(vector<entities::Path *>::iterator i = path.begin(); i != path.end(); ++i)
		if(e == *i)
			return true;

	return false;
}

void trm_select(int x, int y)//, int multiple)
{
	// TODO: implement polymorphism to eliminate redundant use of iterating through
	// each type of entity; other functions (eg newPlayerSpawnPoint) also need
	// polymorphism.  Without it these functions tend to get really messy and
	// clunky
	// suggestion: before processing queue sort the entities so that the top is first, etc;
	// and sort each entity that are on the same level, ie one is not higher than the other,
	// so that the last created is newest, second to last is second newest, etc

	// iterate through player spawn points
	for(vector<entities::PlayerSpawnPoint *>::iterator i = playerSpawnPoint.begin(); i != playerSpawnPoint.end(); ++i)
	{
		entities::PlayerSpawnPoint *e = *i;
		void *ve = reinterpret_cast<void *>(e);
		if(x < e->x + PLAYERSPAWNPOINT_WIDTH && x > e->x - PLAYERSPAWNPOINT_WIDTH && y < e->y + PLAYERSPAWNPOINT_HEIGHT && y > e->y - PLAYERSPAWNPOINT_HEIGHT)
		{
			// the entity is under the cursor
			bool listed = false;
			for(vector<void *>::iterator i = selections.begin(); i != selections.end(); ++i)
			{
				if(*i == ve)
				{
					listed = true;
					break;
				}
			}
			if(!listed)
			{
				selections.push_back((selection = ve));
				return;
			}
		}
	}

	// iterate through powerup spawn points
	for(vector<entities::PowerupSpawnPoint *>::iterator i = powerupSpawnPoint.begin(); i != powerupSpawnPoint.end(); ++i)
	{
		entities::PowerupSpawnPoint *e = *i;
		void *ve = reinterpret_cast<void *>(e);
		if(x < e->x + POWERUPSPAWNPOINT_WIDTH && x > e->x - POWERUPSPAWNPOINT_WIDTH && y < e->y + POWERUPSPAWNPOINT_HEIGHT && y > e->y - POWERUPSPAWNPOINT_HEIGHT)
		{
			// the entity is under the cursor
			bool listed = false;
			for(vector<void *>::iterator i = selections.begin(); i != selections.end(); ++i)
			{
				if(*i == ve)
				{
					listed = true;
					break;
				}
			}
			if(!listed)
			{
				selections.push_back((selection = ve));
				return;
			}
		}
	}

	// iterate through teleporters
	for(vector<entities::Teleporter *>::iterator i = teleporter.begin(); i != teleporter.end(); ++i)
	{
		entities::Teleporter *e = *i;
		void *ve = reinterpret_cast<void *>(e);
		if(x < e->x + TELEPORTER_WIDTH && x > e->x - TELEPORTER_WIDTH && y < e->y + TELEPORTER_HEIGHT && y > e->y - TELEPORTER_HEIGHT)
		{
			// the entity is under the cursor
			bool listed = false;
			for(vector<void *>::iterator i = selections.begin(); i != selections.end(); ++i)
			{
				if(*i == ve)
				{
					listed = true;
					break;
				}
			}
			if(!listed)
			{
				selections.push_back((selection = ve));
				return;
			}
		}
	}

	for(vector<entities::Wall *>::iterator i = wall.begin(); i != wall.end(); ++i)
	{
		/*
		entities::Wall *e = *i;
		entities::Wall *s = reinterpret_cast<entities::Wall *>(os);
		if(s != e && util_pip(((e->x4 == NOVALUEDOUBLE || e->y4 == NOVALUEDOUBLE) ? (3) : (4)), ex, ey, x, y))
			ns = reinterpret_cast<void *>(e);
		*/
		entities::Wall *e = *i;
		if(config_get_int(c_hideDetail) && e->detail)  // don't select detail walls if hideDetail is set
			continue;
		void *ve = reinterpret_cast<void *>(e);
		float ex[4] = {e->x1, e->x2, e->x3, e->x4};
		float ey[4] = {e->y1, e->y2, e->y3, e->y4};
		if(util_pip(((!e->quad) ? (3) : (4)), ex, ey, x, y))
		{
			// the entity is under the cursor
			bool listed = false;
			for(vector<void *>::iterator i = selections.begin(); i != selections.end(); ++i)
			{
				if(*i == ve)
				{
					listed = true;
					break;
				}
			}
			if(!listed)
			{
				selections.push_back((selection = ve));
				return;
			}
		}
	}

	for(vector<entities::Path *>::iterator i = path.begin(); i != path.end(); ++i)
	{
		entities::Path *e = *i;

		void *ve = reinterpret_cast<void *>(e);
		if(x < e->x + PATH_WIDTH && x > e->x - PATH_WIDTH && y < e->y + PATH_HEIGHT && y > e->y - PATH_HEIGHT)
		{
			// the entity is under the cursor
			bool listed = false;
			for(vector<void *>::iterator i = selections.begin(); i != selections.end(); ++i)
			{
				if(*i == ve)
				{
					listed = true;
					break;
				}
			}
			if(!listed)
			{
				selections.push_back((selection = ve));
				return;
			}
		}
	}

	selection = NULL;
	selections.clear();
}

void trm_newPlayerSpawnPoint(int x, int y)
{
	if(config_get_int(c_noModify))
	{
		trm_modifyAttempted();
		return;
	}

	modified = true;

	playerSpawnPoint.push_back(new entities::PlayerSpawnPoint(x, y));
	selection = reinterpret_cast<void *>(playerSpawnPoint[playerSpawnPoint.size() - 1]);
}

void trm_newPowerupSpawnPoint(int x, int y)
{
	if(config_get_int(c_noModify))
	{
		trm_modifyAttempted();
		return;
	}

	modified = true;

	powerupSpawnPoint.push_back(new entities::PowerupSpawnPoint(x, y));
	selection = reinterpret_cast<void *>(powerupSpawnPoint[powerupSpawnPoint.size() - 1]);
}

void trm_newTeleporter(int x, int y)
{
	if(config_get_int(c_noModify))
	{
		trm_modifyAttempted();
		return;
	}

	modified = true;

	teleporter.push_back(new entities::Teleporter(x, y));
	selection = reinterpret_cast<void *>(teleporter[teleporter.size() - 1]);
}

void trm_newWall(int xs, int ys, int xe, int ye)
{
	if(config_get_int(c_noModify))
	{
		trm_modifyAttempted();
		return;
	}

	modified = true;

	if((xs == xe || ye == ys) || (xs - xe < WALL_MINDISTANCE && xe - xs < WALL_MINDISTANCE && ys - ye < WALL_MINDISTANCE && ye - ys < WALL_MINDISTANCE))
		return;
	wall.push_back(new entities::Wall(xs, ys, true, xs, ye, xe, ye, xe, ys));
	selection = reinterpret_cast<void *>(wall[wall.size() - 1]);
}

void trm_newPath(int x, int y)
{
	if(config_get_int(c_noModify))
	{
		trm_modifyAttempted();
		return;
	}

	modified = true;

	path.push_back(new entities::Path(x, y));
	selection = reinterpret_cast<void *>(path[path.size() - 1]);
}

int trm_keypress(int key, bool initial, QKeyEvent *e)
{
	if(key == Qt::Key_Backspace)
	{
		if(selection && initial)
		{
			for(vector<entities::PlayerSpawnPoint *>::iterator i = playerSpawnPoint.begin(); i != playerSpawnPoint.end(); ++i)
			{
				if(selection == reinterpret_cast<void *>(static_cast<entities::PlayerSpawnPoint *>(*i)))
				{
					if(config_get_int(c_noModify))
					{
						trm_modifyAttempted();
						return 0;
					}

					modified = true;
					selection = NULL;
					playerSpawnPoint.erase(i);
					return 0;
				}
			}
			for(vector<entities::PowerupSpawnPoint *>::iterator i = powerupSpawnPoint.begin(); i != powerupSpawnPoint.end(); ++i)
			{
				if(selection == reinterpret_cast<void *>(static_cast<entities::PowerupSpawnPoint *>(*i)))
				{
					if(config_get_int(c_noModify))
					{
						trm_modifyAttempted();
						return 0;
					}

					modified = true;
					selection = NULL;
					powerupSpawnPoint.erase(i);
					return 0;
				}
			}
			for(vector<entities::Teleporter *>::iterator i = teleporter.begin(); i != teleporter.end(); ++i)
			{
				if(selection == reinterpret_cast<void *>(static_cast<entities::Teleporter *>(*i)))
				{
					if(config_get_int(c_noModify))
					{
						trm_modifyAttempted();
						return 0;
					}

					modified = true;
					selection = NULL;
					teleporter.erase(i);
					return 0;
				}
			}
			for(vector<entities::Wall *>::iterator i = wall.begin(); i != wall.end(); ++i)
			{
				if(selection == reinterpret_cast<void *>(static_cast<entities::Wall *>(*i)))
				{
					if(config_get_int(c_noModify))
					{
						trm_modifyAttempted();
						return 0;
					}

					modified = true;
					selection = NULL;
					wall.erase(i);
					return 0;
				}
			}
			for(vector<entities::Path *>::iterator i = path.begin(); i != path.end(); ++i)
			{
				if(selection == reinterpret_cast<void *>(static_cast<entities::Path *>(*i)))
				{
					if(config_get_int(c_noModify))
					{
						trm_modifyAttempted();
						return 0;
					}

					modified = true;
					selection = NULL;
					path.erase(i);
					return 0;
				}
			}
		}
	}
	else if(key == Qt::Key_Escape)
	{
		selection = NULL;
	}
	else if(key == Qt::Key_N)
	{
		Properties properties(window);
		properties.exec();
	}
	else if(key == Qt::Key_C)
	{
		selectionType = e_selectionNone;
	}
	else if(key == Qt::Key_W)
	{
		selectionType = e_selectionWall;
	}
	else if(key == Qt::Key_A)
	{
		selectionType = e_selectionPlayerSpawnPoint;
	}
//	else if(key == Qt::Key_O && initial && !(e->modifiers() & Qt::ControlModifier))
	else if(key == Qt::Key_O && initial)
	{
		selectionType = e_selectionPowerupSpawnPoint;
	}
	else if(key == Qt::Key_E)
	{
		selectionType = e_selectionTeleporter;
	}
	else if(key == Qt::Key_P)
	{
		selectionType = e_selectionPath;
	}
	else if(key == Qt::Key_S && initial)
	{
		Tankbobs_editor::tsave();
	}
//	else if(key == Qt::Key_O && !initial && !(e->modifiers() & Qt::ControlModifier))
	else if(key == Qt::Key_O && !initial)
	{
		selectionType = e_selectionNone;
		Tankbobs_editor::topen();
	}
	else if(key == Qt::Key_T && initial)
	{
		Tankbobs_editor::topen();
	}
	else if(key == Qt::Key_I && initial)
	{
		Tankbobs_editor::timport();
	}
	else if(key == Qt::Key_R && initial)
	{
		x_scroll = y_scroll = 0;
		return 1;
	}
	else if(key == Qt::Key_Z && initial)
	{
		zoom = 1.0;
	}

	return 0;
}

int trm_keyrelease(int key, QKeyEvent *e)
{
	return 0;
}
