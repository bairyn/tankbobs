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

#ifndef TEXTURE_H
#define TEXTURE_H

#include <QtGui>
#include <QGLWidget>
#include <QtCore/QVariant>
#include <QtGui/QAction>
#include <QtGui/QMainWindow>
#include <QtGui/QWidget>
#include <QtCore/qtimer.h>
#include <Qt/qtimer.h>

class Texture : public QGLWidget
{
	Q_OBJECT

	public:
		Texture(QWidget *parent);

	protected:
		void initializeGL();
		void resizeGL(int w, int h);
		void paintGL();

	private:
		QTimer QTa;
};

#endif
