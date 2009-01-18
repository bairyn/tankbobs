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
vector<void *>                        selections;

extern double zoom;
extern int x_scroll, y_scroll;

static void trm_private_modifyAttempted()
{
	window->statusAppend("Modify attempted in read-only mode");
}





/*

The following few lines were stolen from trmc.c and slightly modified

*/

char *stringvalue(char *, char *, int, int);  /* these 3 functions will insert a NULL byte before each , */
int integervalue(char *, char *, int, int);
double doublevalue(char *, char *, int, int);

int restore(char *start, char *end)
{
	int dq = 0;

	if(start >= end)
	{
		fprintf(stdout, "Warning: could not restore field - overlapping bounds\n");
		return 1;
	}

	for(; start < end; start++)
	{
		if(*start == '"')
			dq = !dq;
		if(!*start)
			*start = ((dq) ? '"' : ' ');
	}

	return 0;
}

char *stringvalue(char *start, char *end, int field, int nofieldNoWarning)  // alias nofieldnowarning=optional
{
	int i, dq = 0;
	char *pos = start, *pos2;

	if(start >= end)
	{
		fprintf(stdout, "Warning: empty or small field\n");
		return (char *)NOVALUE;
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
				return (char *)NOVALUE;
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
			return (char *)NOVALUE;
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
			return (char *)NOVALUE;
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
		return NOVALUE;
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
				return NOVALUE;
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
			return NOVALUE;
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
			return NOVALUE;
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
		return NOVALUEDOUBLE;
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
				return NOVALUEDOUBLE;
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
			return NOVALUEDOUBLE;
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
			return NOVALUEDOUBLE;
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
				return NOVALUEDOUBLE;
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

	return 0;
}

char *next_field_close(char *in)
{
	while(*in)
	{
		if(*in++ == '}')
			return (--in - 1); /* yuck */
	}

	return 0;
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
			return 1;
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
			return 1;
		}

		pos++;
	} pos = t;
	count++;
	if(count % 2)
	{
		fprintf(stdout, "Warning: uneven number of {}'s");
		return 1;
	}

	/* validate the order of {}'s */
	while(*pos)
	{
		if(*pos == '{' || *pos == '}')
		{
			if(*pos != field)
			{
				fprintf(stdout, "Warning: invalid order of {}'s");
				return 1;
			}
			if(*pos == '{')
				field = '}';
			else
				field = '{';
		}

		pos++;
	} pos = t;

	/* we're good */
	return 0;
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




bool trm_open(const char *filename, bool import)  // Will not confirm lost progress!
{
	char *buf;
	buf = reinterpret_cast<char *>(malloc(TEMAXBUF + 60));

	ifstream fin(filename, ios::in);
	if(fin.fail())
		return false;

	if(!buf)
	{
		fprintf(stderr, "could not allocate enough memory.  Try compiling with a smaller buffer size\n");
		return false;
	}

	if(!import)
	{
		modified = false;
		tmap = entities::Map();
		playerSpawnPoint.clear();
		powerupSpawnPoint.clear();
		teleporter.clear();
		wall.clear();
	}
	else
	{
		modified = true;
		file = "";
	}

	fin.read(buf, TEMAXBUF - 1);
	char *pos = buf, *pos2 = buf;
	if(!fin.eof())
	{
		free(buf);
		fprintf(stderr, "file too big for buffer.  Try compiling with a bigger buffer size\n");
		return false;
	}

	if(validate(pos))
	{
		free(buf);
		fprintf(stderr, "invalid file\n");
		return false;
	}

	addSpacesBeforeCommasAndEnd(pos);

	if(!next_field_offset(pos))
	{
		fprintf(stdout, "empty file\n");
		return false;
	}

	while((pos = next_field_offset(pos)))
	{
		if(!(pos2 = next_field_close(pos)))
		{
			fprintf(stderr, "corrupt file to parse\n");
			return false;
		}

		if(!stringvalue(pos, pos2, 0, 0))
		{
			return false;
		}

		else if(!strcmp(stringvalue(pos, pos2, 0, 0), "map"))
		{
			if(!import)
			{
				tmap.id = integervalue(pos, pos2, 1, 0);
				tmap.name = stringvalue(pos, pos2, 2, 0);
				tmap.title = stringvalue(pos, pos2, 3, 0);
				if(!stringvalue(pos, pos2, 4, 1) || stringvalue(pos, pos2, 4, 1) == (char *)NOVALUE)
					tmap.description = "";
				else
					tmap.description = stringvalue(pos, pos2, 4, 1);
				if(!stringvalue(pos, pos2, 5, 1) || stringvalue(pos, pos2, 5, 1) == (char *)NOVALUE)
					tmap.authors = "";
				else
					tmap.authors = stringvalue(pos, pos2, 5, 1);
				if(!stringvalue(pos, pos2, 6, 1) || stringvalue(pos, pos2, 6, 1) == (char *)NOVALUE)
					tmap.version = "";
				else
					tmap.version = stringvalue(pos, pos2, 6, 1);
				if(!stringvalue(pos, pos2, 7, 1) || stringvalue(pos, pos2, 7, 1) == (char *)NOVALUE)
					tmap.initscript = "";
				else
					tmap.initscript = stringvalue(pos, pos2, 7, 1);
				if(!stringvalue(pos, pos2, 8, 1) || stringvalue(pos, pos2, 8, 1) == (char *)NOVALUE)
					tmap.exitscript = "";
				else
					tmap.exitscript = stringvalue(pos, pos2, 8, 1);
			}
		}
		else if(!strcmp(stringvalue(pos, pos2, 0, 0), "set"))
		{
			if(!import)
			{
				tmap.setid = integervalue(pos, pos2, 1, 0);
				tmap.setorder = integervalue(pos, pos2, 2, 0);
				tmap.setname = stringvalue(pos, pos2, 3, 0);
				tmap.settitle = stringvalue(pos, pos2, 4, 0);
				if(!stringvalue(pos, pos2, 5, 1) || stringvalue(pos, pos2, 5, 1) == (char *)NOVALUE)
					tmap.setdescription = "";
				else
					tmap.setdescription = stringvalue(pos, pos2, 5, 1);
				if(!stringvalue(pos, pos2, 6, 1) || stringvalue(pos, pos2, 6, 1) == (char *)NOVALUE)
					tmap.setauthors = "";
				else
					tmap.setauthors = stringvalue(pos, pos2, 6, 1);
				if(!stringvalue(pos, pos2, 7, 1) || stringvalue(pos, pos2, 7, 1) == (char *)NOVALUE)
					tmap.setversion = "";
				else
					tmap.setversion = stringvalue(pos, pos2, 7, 1);
			}
		}
		else if(!strcmp(stringvalue(pos, pos2, 0, 0), "wall"))
		{
			wall.push_back(new entities::Wall(stringvalue(pos, pos2, 1, 0), stringvalue(pos, pos2, 2, 0), stringvalue(pos, pos2, 3, 0), stringvalue(pos, pos2, 4, 0), stringvalue(pos, pos2, 5, 0), doublevalue(pos, pos2, 6, 0), doublevalue(pos, pos2, 7, 0), doublevalue(pos, pos2, 8, 0), doublevalue(pos, pos2, 9, 0), doublevalue(pos, pos2, 10, 0), doublevalue(pos, pos2, 11, 0), doublevalue(pos, pos2, 12, 1), doublevalue(pos, pos2, 13, 1)));
		}
		else if(!strcmp(stringvalue(pos, pos2, 0, 0), "teleporter"))
		{
			teleporter.push_back(new entities::Teleporter(doublevalue(pos, pos2, 3, 0), doublevalue(pos, pos2, 4, 0), integervalue(pos, pos2, 1, 0), integervalue(pos, pos2, 2, 0)));
		}
		else if(!strcmp(stringvalue(pos, pos2, 0, 0), "powerspawn"))
		{
			powerupSpawnPoint.push_back(new entities::PowerupSpawnPoint(doublevalue(pos, pos2, 3, 0), doublevalue(pos, pos2, 4, 0), integervalue(pos, pos2, 2, 0), stringvalue(pos, pos2, 1, 0)));
		}
		else if(!strcmp(stringvalue(pos, pos2, 0, 0), "spawnpoint"))
		{
			playerSpawnPoint.push_back(new entities::PlayerSpawnPoint(doublevalue(pos, pos2, 1, 0), doublevalue(pos, pos2, 2, 0)));
		}
		else
		{
			fprintf(stdout, "Warning: field %s not known\n", stringvalue(pos, pos2, 0, 0));
		}

		if(restore(pos, pos2))
		{
			fprintf(stderr, "error restoring memory from %p to %p\n", pos, pos2);
			free(buf);
			return false;
		}
	}

	free(buf);
	return true;

/*
	char buf[TEMAXBUF];  // TEMAXBUF is 1024
	int line = 0;

	ifstream fin(filename, ios::in);
	if(fin.fail())
		return false;

	if(!import)
	{
		modified = false;
		tmap = entities::Map();
		playerSpawnPoint.clear();
		powerupSpawnPoint.clear();
		teleporter.clear();
		wall.clear();
	}
	else
	{
		file = "";
	}

	while(fin.getline(buf, TEMAXBUF), line++, !fin.eof())
	{
		if(fin.fail())
		{
			fprintf(stderr, "line %d too big to store into a %d byte buffer\n", line, TEMAXBUF);
			return false;
		}

		char *p = buf;
		while(*p != '{')
		{
			if(!*p++)
			{
				fprintf(stderr, "line %d is missing a '{'\n", line);
				return false;
			}
		}
		char *p2 = p + 1;
		while(*p2 != '}')
		{
			if(!*p2++)
			{
				fprintf(stderr, "line %d is missing a '{'\n", line);
				return false;
			}
		}
		p++;
		p2--;
		// p is now set to the character after '{' and p2 to the character
		// before '}'
		while(*p && p <= p2 && *p != ' ' && *p != '\t' && *p != '\n') p++;
		while(*p2 && p2 >= p && *p2 != ' '&& *p2 != '\t' && *p2 != '\n') p2++;
		if(p2 <= p || p > p2)
		{
			fprintf(sterr, "erroneous line %d: no body detected\n", line);
		}
		// p is now the first non-whitespace character
		// p2 is the last non-whitespace character
		char buf2[TEMAXBUF];
		int i = 1;
		while((int)(i++) <= (int)(TEMAXBUF))
		{
			if(i <= 0)
			{
				fprintf(stderr, "on parsing line %d: the iterator can't hold enough memory to point to buffer\n", line);
				return false;
			}
		}
		i = 0;
		char *etype = buf2;
		if(*etype == '"')
			etype++;
		char *p3 = p;
		while(*p3 && p3 <= p2 && *p != ' ' && *p3 != '\t' && *p3 != '\n') p3++;
		if(p2 <= p3 || p3 > p2)
		{
			fprintf(sterr, "erroneous line %d: no body detected\n", line);
		}
		while(p <= p2 && *p != '"' && *p != ',' && *p != '')
		{
			
		}
	}

	return true;*/
}

bool trm_save(const char *filename)
{
	if(config_get_int(c_noModify))
	{
		trm_private_modifyAttempted();
		return false;
	}

	ofstream fout(filename, ios::out | ios::trunc);
	if(fout.fail())
		return false;

	fout << "{\"map\""
		<< ", " << tmap.id << ""
		<< ", \"" << tmap.name << "\""
		<< ", \"" << tmap.title << "\"";
	if(tmap.description.length())
	{
		fout << ", \"" << tmap.description << "\"";
		if(tmap.authors.length())
		{
			fout << ", \"" << tmap.authors << "\"";
			if(tmap.version.length())
			{
				fout << ", \"" << tmap.version << "\"";
				if(tmap.initscript.length())
				{
					fout << ", \"" << tmap.initscript << "\"";
					if(tmap.exitscript.length())
					{
						fout << ", \"" << tmap.exitscript << "\"";
						fout << "}" << endl;
					}
					else
					{
						fout << "}" << endl;
					}
				}
				else
				{
					fout << "}" << endl;
				}
			}
			else
			{
				fout << "}" << endl;
			}
		}
		else
		{
			fout << "}" << endl;
		}
	}
	else
	{
		fout << "}" << endl;
	}

	fout << "{\"set\""
		<< ", " << tmap.setid << ""
		<< ", " << tmap.setorder << ""
		<< ", \"" << tmap.setname << "\""
		<< ", \"" << tmap.settitle << "\""
		<< ", \"" << tmap.setdescription << "\"";
	if(tmap.setauthors.length())
	{
		fout << ", \"" << tmap.setauthors << "\"";
		if(tmap.setversion.length())
		{
			fout << ", \"" << tmap.setversion << "\"";
			fout << "}" << endl;
		}
		else
		{
			fout << "}" << endl;
		}
	}
	else
	{
		fout << "}" << endl;
	}

	for(vector<entities::PlayerSpawnPoint *>::iterator i = playerSpawnPoint.begin(); i != playerSpawnPoint.end(); ++i)
	{
		entities::PlayerSpawnPoint *e = *i;
		fout << "{\"spawnpoint\", " << e->x << ", " << e->y << "}" << endl;
	}

	for(vector<entities::PowerupSpawnPoint *>::iterator i = powerupSpawnPoint.begin(); i != powerupSpawnPoint.end(); ++i)
	{
		entities::PowerupSpawnPoint *e = *i;
		fout << "{\"powerspawn\", \"" << e->powerups << "\", " << e->enable << ", "
			<< e->x
			<< ", "
			<< e->y
			<< "}"
			<< endl;
	}

	for(vector<entities::Teleporter *>::iterator i = teleporter.begin(); i != teleporter.end(); ++i)
	{
		entities::Teleporter *e = *i;
		fout << "{\"teleporter\", \"" << e->group << ", " << e->active << ", " << e->x << ", " << e->y << "}" << endl;
	}

	for(vector<entities::Wall *>::iterator i = wall.begin(); i != wall.end(); ++i)
	{
		entities::Wall *e = *i;
		fout << "{\"wall\", \"" << e->texture << "\", \"" << e->flags << "\", \"" << e->script1 << "\", \"" << e->script2 << "\", \"" << e->script3 << "\", " << e->x1 << ", " << e->y1 << ", " << e->x2 << ", " << e->y2 << ", " << e->x3 << ", " << e->y3;
		if(e->x4 != NOVALUEDOUBLE && e->y4 != NOVALUEDOUBLE)
			fout << ", " << e->x4 << ", " << e->y4;
		fout << "}" << endl;
	}

	fout.close();
	if(fout.fail())
		return false;

	return true;
}

void trm_select(int x, int y)
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
		void *ve = reinterpret_cast<void *>(e);
		float ex[4] = {e->x1, e->x2, e->x3, e->x4};
		float ey[4] = {e->y1, e->y2, e->y3, e->y4};
		if(util_pip(((e->x4 == NOVALUEDOUBLE || e->y4 == NOVALUEDOUBLE) ? (3) : (4)), ex, ey, x, y))
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
		trm_private_modifyAttempted();
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
		trm_private_modifyAttempted();
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
		trm_private_modifyAttempted();
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
		trm_private_modifyAttempted();
		return;
	}

	modified = true;

	if((xs == xe || ye == ys) || (xs - xe < WALL_MINDISTANCE && xe - xs < WALL_MINDISTANCE && ys - ye < WALL_MINDISTANCE && ye - ys < WALL_MINDISTANCE))
		return;
	wall.push_back(new entities::Wall("", "", "", "", "", xs, ys, xs, ye, xe, ye, xe, ys));
	selection = reinterpret_cast<void *>(wall[wall.size() - 1]);
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
						trm_private_modifyAttempted();
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
						trm_private_modifyAttempted();
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
						trm_private_modifyAttempted();
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
						trm_private_modifyAttempted();
						return 0;
					}

					modified = true;
					selection = NULL;
					wall.erase(i);
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
