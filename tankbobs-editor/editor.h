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

#ifndef EDITOR_H
#define EDITOR_H

#include <QtGui>
#include <QGLWidget>
#include <QtCore/QVariant>
#include <QtGui/QAction>
#include <QtGui/QMainWindow>
#include <QtGui/QWidget>
#include <QtCore/qtimer.h>
#include <Qt/qtimer.h>
#include <GL/gl.h>

class Editor : public QGLWidget
{
	Q_OBJECT

	public:
		Editor(QWidget *parent);
		void exit(void);

	protected:
		void mousePressEvent(QMouseEvent *e);
		void mouseReleaseEvent(QMouseEvent *e);
		void mouseMoveEvent(QMouseEvent *e);
		void initializeGL(void);
		void resizeGL(int w, int h);
		void paintGL(void);

	private:
		QTimer QTa;
		int mx(int);
		int my(int);
};

#endif
