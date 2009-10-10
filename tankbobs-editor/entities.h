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
#define PATH_WIDTH               5
#define PATH_HEIGHT              5
#define CONTROLPOINT_WIDTH       5
#define CONTROLPOINT_HEIGHT      5
#define FLAG_WIDTH               5
#define FLAG_HEIGHT              5
#define WAYPOINT_WIDTH           5
#define WAYPOINT_HEIGHT          5

namespace entities
{
	class Map
	{
		public:
			string name;
			string title;
			string description;
			string authors;
			string version_s;
			int version;
			bool staticCamera;
			Map() {name = "default"; title = "default"; description = ""; authors = ""; version_s = ""; version = 0; staticCamera = false;}
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
			string powerups;
			int linked;
			double repeat;
			double initial;
			int focus;
			PowerupSpawnPoint(double PowerupSpawnPoint_x = 0.0, double PowerupSpawnPoint_y = 0.0, string PowerupSpawnPoint_powerups = "", int PowerupSpawnPoint_linked = false, double PowerupSpawnPoint_repeat = 0.0, double PowerupSpawnPoint_initial = 0.0, int PowerupSpawnPoint_focus = false) : x(PowerupSpawnPoint_x), y(PowerupSpawnPoint_y), powerups(PowerupSpawnPoint_powerups), linked(PowerupSpawnPoint_linked), repeat(PowerupSpawnPoint_repeat), initial(PowerupSpawnPoint_initial), focus(PowerupSpawnPoint_focus) {}
	};

	class Teleporter : private Entity
	{
		public:
			//string name;  // these can't go here for C++ class initilazation order issues
			//string targetName;
			double x, y;
			string targetName;
			string target;
			bool enabled;
			Teleporter(double Teleporter_x = 0.0, double Teleporter_y = 0.0, string Teleporter_targetName = "", string Teleporter_target = "", bool Teleporter_enabled = false) : x(Teleporter_x), y(Teleporter_y), targetName(Teleporter_targetName), target(Teleporter_target), enabled(Teleporter_enabled) {}
	};

	class Wall : private Entity
	{
		public:
			//bool quad;
			double x1;
			double y1;
			bool quad;
			double x2;
			double y2;
			double x3;
			double y3;
			double x4;
			double y4;
			double tx1;
			double ty1;
			double tx2;
			double ty2;
			double tx3;
			double ty3;
			double tx4;
			double ty4;
			string texture;
			int level;
			string target;
			bool path;
			bool detail;
			bool staticW;
			Wall(double Wall_x1 = 0.0, double Wall_y1 = 0.0, bool Wall_quad = false, double Wall_x2 = 0.0, double Wall_y2 = 0.0, double Wall_x3 = 0.0, double Wall_y3 = 0.0, double Wall_x4 = 0.0, double Wall_y4 = 0.0, double Wall_tx1 = 0.0, double Wall_ty1 = 1.0, double Wall_tx2 = 0.0, double Wall_ty2 = 0.0, double Wall_tx3 = 1.0, double Wall_ty3 = 0.0, double Wall_tx4 = 1.0, double Wall_ty4 = 1.0, string Wall_texture = "", int Wall_level = 0, string Wall_target = "", bool Wall_path = false, bool Wall_detail = false, bool Wall_staticW = true) : x1(Wall_x1), y1(Wall_y1), quad(Wall_quad), x2(Wall_x2), y2(Wall_y2), x3(Wall_x3), y3(Wall_y3), x4(Wall_x4), y4(Wall_y4), tx1(Wall_tx1), ty1(Wall_ty1), tx2(Wall_tx2), ty2(Wall_ty2), tx3(Wall_tx3), ty3(Wall_ty3), tx4(Wall_tx4), ty4(Wall_ty4), texture(Wall_texture), level(Wall_level), target(Wall_target), path(Wall_path), detail(Wall_detail), staticW(Wall_staticW) {}  // note that static walls are default
	};

	class Path : private Entity
	{
		public:
			double x, y;
			string targetName;
			string target;
			bool enabled;
			double time;
			Path(double Path_x = 0.0, double Path_y = 0.0, string Path_targetName = "", string Path_target = "", bool Path_enabled = false, double Path_time = 0) : x(Path_x), y(Path_y), targetName(Path_targetName), target(Path_target), enabled(Path_enabled), time(Path_time) {}

	};

	class ControlPoint : private Entity
	{
		public:
			double x, y;
			bool red;
			ControlPoint(double ControlPoint_x = 0.0, double ControlPoint_y = 0.0, bool ControlPoint_red = false) : x(ControlPoint_x), y(ControlPoint_y), red(ControlPoint_red) {}

	};

	class Flag : private Entity
	{
		public:
			double x, y;
			bool red;
			Flag(double Flag_x = 0.0, double Flag_y = 0.0, bool Flag_red = false) : x(Flag_x), y(Flag_y), red(Flag_red) {}

	};

	class WayPoint : private Entity
	{
		public:
			double x, y;
			WayPoint(double WayPoint_x = 0.0, double WayPoint_y = 0.0) : x(WayPoint_x), y(WayPoint_y) {}
	};
}

enum
{
	e_selectionNone,
	e_selectionWall,
	e_selectionPlayerSpawnPoint,
	e_selectionPowerupSpawnPoint,
	e_selectionTeleporter,
	e_selectionPath,
	e_selectionControlPoint,
	e_selectionFlag,
	e_selectionWayPoint,

	e_numSelection
};

enum
{
	t_none,
	t_translation,
	t_translationVertices,
};

#endif
