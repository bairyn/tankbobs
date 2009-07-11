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

#ifndef TRM_H
#define TRM_H

int  trm_isSelected(void *e);
void trm_setSelected(void *e);
void trm_clearAndSetSelected(void *e);
bool trm_open(const char *filename, bool import);
bool trm_save(const char *filename);
void trm_select(int x, int y);
void trm_newPlayerSpawnPoint(int x, int y);
void trm_newPowerupSpawnPoint(int x, int y);
void trm_newTeleporter(int x, int y);
void trm_newWall(int xs, int ys, int xe, int ye);
void trm_newPath(int x, int y);
void trm_newControlPoint(int x, int y);
void trm_newFlag(int x, int y);
int  trm_keypress(int key, bool initial, QKeyEvent *e);
int  trm_keyrelease(int key, QKeyEvent *e);
void trm_modifyAttempted();
bool trm_isWall(void *e);
bool trm_isTeleporter(void *e);
bool trm_isPlayerSpawnPoint(void *e);
bool trm_isPowerupSpawnPoint(void *e);
bool trm_isPath(void *e);
bool trm_isControlPoint(void *e);
bool trm_isFlag(void *e);

//#define TEMAXBUF 1024
#define TEMAXBUF 100000
#define GRIDSIZE 100.0
#define GRIDLINES 4  // approximate number of grid lines drawn on each side
#define ZOOMFACTOR 0.02  // 2% per pixel
#define ZOOMQUADFACTOR 0.75
#define MINZOOM 0.125
#define MAXZOOM 1.2
#define MINSCROLL -GRIDSIZE * GRIDLINES
#define MAXSCROLL  GRIDSIZE * GRIDLINES

#define ZOOM ((zoom) > (1.0) ? (zoom) : (1.0))

#endif
