#include <QApplication>
#include <vector>
#include <fstream>
#include "tankbobs-editor.h"
#include "trm.h"
#include "util.h"
#include "entities.h"
#include "config.h"
#include "properties.h"

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

static void trm_private_modifyAttempted()
{
	window->statusAppend("Modify attempted in read-only mode");
}

bool trm_open(const char *filename)
{
	return false;
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

void trm_keypress(int key, bool initial)
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
						return;
					}

					modified = true;
					selection = NULL;
					playerSpawnPoint.erase(i);
					return;
				}
			}
			for(vector<entities::PowerupSpawnPoint *>::iterator i = powerupSpawnPoint.begin(); i != powerupSpawnPoint.end(); ++i)
			{
				if(selection == reinterpret_cast<void *>(static_cast<entities::PowerupSpawnPoint *>(*i)))
				{
					if(config_get_int(c_noModify))
					{
						trm_private_modifyAttempted();
						return;
					}

					modified = true;
					selection = NULL;
					powerupSpawnPoint.erase(i);
					return;
				}
			}
			for(vector<entities::Teleporter *>::iterator i = teleporter.begin(); i != teleporter.end(); ++i)
			{
				if(selection == reinterpret_cast<void *>(static_cast<entities::Teleporter *>(*i)))
				{
					if(config_get_int(c_noModify))
					{
						trm_private_modifyAttempted();
						return;
					}

					modified = true;
					selection = NULL;
					teleporter.erase(i);
					return;
				}
			}
			for(vector<entities::Wall *>::iterator i = wall.begin(); i != wall.end(); ++i)
			{
				if(selection == reinterpret_cast<void *>(static_cast<entities::Wall *>(*i)))
				{
					if(config_get_int(c_noModify))
					{
						trm_private_modifyAttempted();
						return;
					}

					modified = true;
					selection = NULL;
					wall.erase(i);
					return;
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
	else if(key == Qt::Key_O && !initial)
	{
		selectionType = e_selectionNone;
		Tankbobs_editor::topen();
	}
	else if(key == Qt::Key_T && initial)
	{
		selectionType = e_selectionNone;
		Tankbobs_editor::topen();
	}
}

void trm_keyrelease(int key)
{
}
