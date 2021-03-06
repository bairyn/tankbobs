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

#ifndef PROPERTIES_H
#define PROPERTIES_H

#include <QtCore/qtimer.h>
#include <Qt/qtimer.h>
#include <GL/gl.h>
#include "ui_properties.h"

#define TE_GLB makeCurrent(); glClear(GL_COLOR_BUFFER_BIT); glLoadIdentity();
#define TE_GLE glFlush();

class Properties : public QDialog, private Ui::PropertiesDialog
{
	Q_OBJECT

	public:
		Properties(QWidget *parent = 0);

	public slots:
		void mapnameChanged(const QString &text);
		void maptitleChanged(const QString &text);
		void mapdescriptionChanged(const QString &text);
		void mapsongChanged(const QString &text);
		void mapauthorsChanged(const QString &text);
		void mapversionsChanged(const QString &text);
		void mapversionChanged(const QString &text);
		void staticCameraChanged(int state);
		void powerupsChanged(const QString &text);
		void levelChanged(const QString &text);
		void timeChanged(const QString &text);
		void textureChanged(const QString &text);
		void thtChanged(const QString &text);
		void tvtChanged(const QString &text);
		void thsChanged(const QString &text);
		void tvsChanged(const QString &text);
		void trChanged(const QString &text);
		void targetChanged(const QString &text);
		void targetNameChanged(const QString &text);
		void repeatChanged(const QString &text);
		void initialChanged(const QString &text);
		void fourVerticesChanged(int state);
		void autoselectChanged(int state);
		void nomodifyChanged(int state);
		void autonotextureChanged(int state);
		void hideDetailChanged(int state);
		void pathChanged(int state);
		void detailChanged(int state);
		void staticWChanged(int state);
		void enabledChanged(int state);
		void linkedChanged(int state);
		void focusChanged(int state);
		void redChanged(int state);
		void scriptChanged(const QString &text);
		void miscChanged(const QString &text);
};

#endif
