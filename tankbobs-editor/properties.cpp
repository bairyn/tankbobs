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

#include <QtGui>
#include "trm.h"
#include "entities.h"
#include "config.h"
#include "util.h"
#include "properties.h"

using std::string;

extern entities::Map tmap;
extern vector<entities::PlayerSpawnPoint *>  playerSpawnPoint;
extern vector<entities::PowerupSpawnPoint *> powerupSpawnPoint;
extern vector<entities::Teleporter *>        teleporter;
extern vector<entities::Wall *>              wall;
extern void *selection;

Properties::Properties(QWidget *parent)
{
	setupUi(this);

	autoselect->setChecked(config_get_int(c_autoSelect));
	nomodify->setChecked(config_get_int(c_noModify));
	autonotexture->setChecked(config_get_int(c_autoNoTexture));

	bool selected;
	for(vector<entities::PlayerSpawnPoint *>::iterator i = playerSpawnPoint.begin(); i != playerSpawnPoint.end(); ++i)
	{
		if(selection == reinterpret_cast<void *>(static_cast<entities::PlayerSpawnPoint *>(*i)))
		{
			selected = true;
		}
	}
	for(vector<entities::PowerupSpawnPoint *>::iterator i = powerupSpawnPoint.begin(); i != powerupSpawnPoint.end(); ++i)
	{
		if(selection == reinterpret_cast<void *>(static_cast<entities::PowerupSpawnPoint *>(*i)))
		{
			powerups->setText(QString(reinterpret_cast<entities::PowerupSpawnPoint *>(selection)->powerups.c_str()));

			selected = true;
			powerups->setEnabled(true);
			powerupsLabel->setEnabled(true);
		}
	}
	for(vector<entities::Teleporter *>::iterator i = teleporter.begin(); i != teleporter.end(); ++i)
	{
		if(selection == reinterpret_cast<void *>(static_cast<entities::Teleporter *>(*i)))
		{
			name->setText(QString(reinterpret_cast<entities::Teleporter *>(selection)->name.c_str()));
			targetName->setText(QString(reinterpret_cast<entities::Teleporter *>(selection)->targetName.c_str()));

			selected = true;
			name->setEnabled(true);
			nameLabel->setEnabled(true);
			targetName->setEnabled(true);
			targetNameLabel->setEnabled(true);
		}
	}
	for(vector<entities::Wall *>::iterator i = wall.begin(); i != wall.end(); ++i)
	{
		if(selection == reinterpret_cast<void *>(static_cast<entities::Wall *>(*i)))
		{
			fourVertices->setChecked(reinterpret_cast<entities::Wall *>(selection)->quad);
			level->setText(QString::number(reinterpret_cast<entities::Wall *>(selection)->level));
			texture->setText(reinterpret_cast<entities::Wall *>(selection)->texture.c_str());

			selected = true;
			fourVertices->setEnabled(true);
			texture->setEnabled(true);
			textureLabel->setEnabled(true);
			level->setEnabled(true);
			levelLabel->setEnabled(true);
		}
	}
	if(!selected)
	{
		mapname->setText(QString(tmap.name.c_str()));
		maptitle->setText(QString(tmap.title.c_str()));
		mapdescription->setText(QString(tmap.description.c_str()));
		mapauthors->setText(QString(tmap.authors.c_str()));
		mapversions->setText(QString(tmap.version_s.c_str()));
		mapversion->setText(QString::number(tmap.version));

		mapname->setEnabled(true);
		mapnameLabel->setEnabled(true);
		maptitle->setEnabled(true);
		maptitleLabel->setEnabled(true);
		mapdescription->setEnabled(true);
		mapdescriptionLabel->setEnabled(true);
		mapauthors->setEnabled(true);
		mapauthorsLabel->setEnabled(true);
		mapversions->setEnabled(true);
		mapversionsLabel->setEnabled(true);
		mapversion->setEnabled(true);
		mapversionLabel->setEnabled(true);
	}

	connect(mapname, SIGNAL(textChanged(const QString &)), this, SLOT(mapnameChanged(const QString &)));
	connect(maptitle, SIGNAL(textChanged(const QString &)), this, SLOT(maptitleChanged(const QString &)));
	connect(mapdescription, SIGNAL(textChanged(const QString &)), this, SLOT(mapdescriptionChanged(const QString &)));
	connect(mapauthors, SIGNAL(textChanged(const QString &)), this, SLOT(mapauthorsChanged(const QString &)));
	connect(mapversions, SIGNAL(textChanged(const QString &)), this, SLOT(mapversionsChanged(const QString &)));
	connect(mapversion, SIGNAL(textChanged(const QString &)), this, SLOT(mapversionChanged(const QString &)));
	connect(texture, SIGNAL(textChanged(const QString &)), this, SLOT(textureChanged(const QString &)));
	connect(name, SIGNAL(textChanged(const QString &)), this, SLOT(nameChanged(const QString &)));
	connect(targetName, SIGNAL(textChanged(const QString &)), this, SLOT(targetNameChanged(const QString &)));
	connect(powerups, SIGNAL(textChanged(const QString &)), this, SLOT(powerupsChanged(const QString &)));
	connect(fourVertices, SIGNAL(stateChanged(int)), this, SLOT(fourVerticesChanged(int)));
	connect(level, SIGNAL(textChanged(const QString &)), this, SLOT(levelChanged(const QString &)));
	connect(autoselect, SIGNAL(stateChanged(int)), this, SLOT(autoselectChanged(int)));
	connect(nomodify, SIGNAL(stateChanged(int)), this, SLOT(nomodifyChanged(int)));
	connect(autonotexture, SIGNAL(stateChanged(int)), this, SLOT(autonotextureChanged(int)));
}

void Properties::textureChanged(const QString &text)
{
	reinterpret_cast<entities::Wall *>(selection)->texture = util_qtcp(text);
}

void Properties::nameChanged(const QString &text)
{
	reinterpret_cast<entities::Teleporter *>(selection)->name = util_atoi(util_qtcp(text).c_str());
}

void Properties::targetNameChanged(const QString &text)
{
	reinterpret_cast<entities::Teleporter *>(selection)->targetName = util_atoi(util_qtcp(text).c_str());
}

void Properties::powerupsChanged(const QString &text)
{
	reinterpret_cast<entities::PowerupSpawnPoint *>(selection)->powerups = util_qtcp(text);
}

void Properties::fourVerticesChanged(int state)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);
	if(state)
	{
		w->x4 = (w->x1 + w->x2 + w->x3) / 3;
		w->y4 = (w->y1 + w->y2 + w->y3) / 3;
		w->quad = true;
	}
	else
	{
		w->quad = false;
	}
}

void Properties::levelChanged(const QString &text)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);

	w->level = util_atoi(util_qtcp(text).c_str());
}

void Properties::autoselectChanged(int state)
{
	config_set_int(c_autoSelect, state);
}

void Properties::nomodifyChanged(int state)
{
	config_set_int(c_noModify, state);
}

void Properties::autonotextureChanged(int state)
{
	config_set_int(c_autoNoTexture, state);
}

void Properties::mapnameChanged(const QString &text)
{
	tmap.name = util_qtcp(text);
}

void Properties::maptitleChanged(const QString &text)
{
	tmap.title = util_qtcp(text);
}

void Properties::mapdescriptionChanged(const QString &text)
{
	tmap.description = util_qtcp(text);
}

void Properties::mapauthorsChanged(const QString &text)
{
	tmap.authors = util_qtcp(text);
}

void Properties::mapversionsChanged(const QString &text)
{
	tmap.version_s = util_qtcp(text);
}

void Properties::mapversionChanged(const QString &text)
{
	tmap.version = util_atoi(util_qtcp(text).c_str());
}
