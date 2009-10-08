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

#ifndef TANKBOBSEDITOR_H
#define TANKBOBSEDITOR_H

#include <QtCore/qtimer.h>
#include <Qt/qtimer.h>
#include <GL/gl.h>
#include "ui_tankbobs-editor.h"

#define TE_GLB makeCurrent(); glClear(GL_COLOR_BUFFER_BIT); glLoadIdentity();
#define TE_GLE glFlush();

class Tankbobs_editor : public QMainWindow, private Ui::MainWindow
{
	Q_OBJECT

	public:
		Tankbobs_editor(QWidget *parent = 0);
		void statusAppend(const QString &s);
		static void tsaveAs(void);
		static void tsave(void);
		static void topen(void);
		static void timport(void);

	public slots:
		void selectionCancel();
		void selectionWall();
		void selectionPlayerSpawnPoint();
		void selectionPowerupSpawnPoint();
		void selectionTeleporter();
		void selectionPath();
		void selectionControlPoint();
		void selectionFlag();
		void selectionWayPoint();
		void open();
		void save();
		void saveAs();
		void exit();
		void import();
		void openTextureDirectory();
		void statusClear();

	protected:
		virtual void keyPressEvent(QKeyEvent *e);
		virtual void keyReleaseEvent(QKeyEvent *e);

	private:
		QTimer QTa;
};

#endif
