#ifndef ENTITIES_H
#define ENTITIES_H

#include <iostream>
#include <string>
using namespace std;

#define WALL_MINDISTANCE         3
#define PLAYERSPAWNPOINT_WIDTH   5
#define PLAYERSPAWNPOINT_HEIGHT  5
#define POWERUPSPAWNPOINT_WIDTH  5
#define POWERUPSPAWNPOINT_HEIGHT 5
#define TELEPORTER_WIDTH         5
#define TELEPORTER_HEIGHT        5

namespace entities
{
	class Map
	{
		public:
			int id;
			string name;
			string title;
			string description;  // optional, set to NULL if so
			string authors;
			string version;
			string initscript;
			string exitscript;
			int setid;
			int setorder;
			string setname;
			string settitle;
			string setdescription;
			string setauthors;
			string setversion;
			Map() {id = 1; name = "default"; title = "default"; description = ""; authors = ""; version = ""; setid = 1; setorder = 1; setname = "default"; settitle = "default"; setdescription = ""; setauthors = ""; setversion = "";}
	};

	class Entity
	{
	};

	class PlayerSpawnPoint : private Entity
	{
		public:
			double x, y;
			PlayerSpawnPoint(double PlayerSpawnPoint_x = 0.0, double PlayerSpawnPoint_y = 0.0) : x(PlayerSpawnPoint_x), y(PlayerSpawnPoint_y) {}
	};

	class PowerupSpawnPoint : private Entity
	{
		public:
			double x, y;
			bool enable;
			string powerups;
			PowerupSpawnPoint(double PowerupSpawnPoint_x = 0.0, double PowerupSpawnPoint_y = 0.0, bool PowerupSpawnPoint_enable = false, string PowerupSpawnPoint_powerups = "") : x(PowerupSpawnPoint_x), y(PowerupSpawnPoint_y), enable(PowerupSpawnPoint_enable), powerups(PowerupSpawnPoint_powerups) {}
	};

	class Teleporter : private Entity
	{
		public:
			double x, y;
			int group;
			bool active;
			Teleporter(double Teleporter_x = 0.0, double Teleporter_y = 0.0, int Teleporter_group = 0, bool Teleporter_active = true) : x(Teleporter_x), y(Teleporter_y), group(Teleporter_group), active(Teleporter_active) {}
	};

	class Wall : private Entity
	{
		public:
			string texture;
			string flags;
			string script1;
			string script2;
			string script3;
			double x1;
			double y1;
			double x2;
			double y2;
			double x3;
			double y3;
			double x4;
			double y4;
			Wall(string Wall_texture = "", string Wall_flags = "", string Wall_script1 = "", string Wall_script2 = "", string Wall_script3 = "", double Wall_x1 = 0.0, double Wall_y1 = 0.0, double Wall_x2 = 0.0, double Wall_y2 = 0.0, double Wall_x3 = 0.0, double Wall_y3 = 0.0, double Wall_x4 = 0.0, double Wall_y4 = 0.0) : texture(Wall_texture), flags(Wall_flags), script1(Wall_script1), script2(Wall_script2), script3(Wall_script3), x1(Wall_x1), y1(Wall_y1), x2(Wall_x2), y2(Wall_y2), x3(Wall_x3), y3(Wall_y3), x4(Wall_x4), y4(Wall_y4) {}
	};
}

enum
{
	e_selectionNone,
	e_selectionWall,
	e_selectionPlayerSpawnPoint,
	e_selectionPowerupSpawnPoint,
	e_selectionTeleporter,

	e_numSelection
};

enum
{
	t_none,
	t_translation,
	t_translationVertices,
};

#endif
