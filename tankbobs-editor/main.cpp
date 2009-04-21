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

#include <QApplication>
#include "tankbobs-editor.h"
#include "config.h"

Tankbobs_editor *window = NULL;

int main(int argc, char **argv)
{
	QApplication app(argc, argv);
	int result = config_args(argc, argv);
	if(!result)
		return result;
	Q_INIT_RESOURCE(res);
	window = new Tankbobs_editor;
	window->show();
	result = app.exec();
	Q_CLEANUP_RESOURCE(res);
	return result;
}
