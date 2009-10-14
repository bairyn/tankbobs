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
extern vector<entities::Path *>              path;
extern vector<entities::ControlPoint *>      controlPoint;
extern vector<entities::Flag *>              flag;
extern vector<entities::WayPoint *>          wayPoint;
extern void *selection;

Properties::Properties(QWidget *parent)
{
	setupUi(this);

	autoselect->setChecked(config_get_int(c_autoSelect));
	nomodify->setChecked(config_get_int(c_noModify));
	autonotexture->setChecked(config_get_int(c_autoNoTexture));
	hideDetail->setChecked(config_get_int(c_hideDetail));

	bool selected;
	for(vector<entities::PlayerSpawnPoint *>::iterator i = playerSpawnPoint.begin(); i != playerSpawnPoint.end(); ++i)
	{
		if(selection == reinterpret_cast<void *>(static_cast<entities::PlayerSpawnPoint *>(*i)))
		{
			misc->setText(QString(reinterpret_cast<entities::PowerupSpawnPoint *>(selection)->misc.c_str()));

			selected = true;
			misc->setEnabled(true);
		}
	}
	for(vector<entities::PowerupSpawnPoint *>::iterator i = powerupSpawnPoint.begin(); i != powerupSpawnPoint.end(); ++i)
	{
		if(selection == reinterpret_cast<void *>(static_cast<entities::PowerupSpawnPoint *>(*i)))
		{
			powerups->setText(QString(reinterpret_cast<entities::PowerupSpawnPoint *>(selection)->powerups.c_str()));
			linked->setChecked(reinterpret_cast<entities::PowerupSpawnPoint *>(selection)->linked);
			repeat->setText(QString::number(reinterpret_cast<entities::PowerupSpawnPoint *>(selection)->repeat));
			initial->setText(QString::number(reinterpret_cast<entities::PowerupSpawnPoint *>(selection)->initial));
			focus->setChecked(reinterpret_cast<entities::PowerupSpawnPoint *>(selection)->focus);
			misc->setText(QString(reinterpret_cast<entities::PowerupSpawnPoint *>(selection)->misc.c_str()));

			selected = true;
			powerups->setEnabled(true);
			powerupsLabel->setEnabled(true);
			linked->setEnabled(true);
			repeat->setEnabled(true);
			repeatLabel->setEnabled(true);
			initial->setEnabled(true);
			initialLabel->setEnabled(true);
			focus->setEnabled(true);
			misc->setEnabled(true);
		}
	}
	for(vector<entities::Teleporter *>::iterator i = teleporter.begin(); i != teleporter.end(); ++i)
	{
		if(selection == reinterpret_cast<void *>(static_cast<entities::Teleporter *>(*i)))
		{
			targetName->setText(QString(reinterpret_cast<entities::Teleporter *>(selection)->targetName.c_str()));
			target->setText(QString(reinterpret_cast<entities::Teleporter *>(selection)->target.c_str()));
			enabled->setChecked(reinterpret_cast<entities::Teleporter *>(selection)->enabled);
			misc->setText(QString(reinterpret_cast<entities::Teleporter *>(selection)->misc.c_str()));

			selected = true;
			targetName->setEnabled(true);
			targetNameLabel->setEnabled(true);
			target->setEnabled(true);
			targetLabel->setEnabled(true);
			enabled->setEnabled(true);
			misc->setEnabled(true);
		}
	}
	for(vector<entities::Wall *>::iterator i = wall.begin(); i != wall.end(); ++i)
	{
		if(selection == reinterpret_cast<void *>(static_cast<entities::Wall *>(*i)))
		{
			fourVertices->setChecked(reinterpret_cast<entities::Wall *>(selection)->quad);
			level->setText(QString::number(reinterpret_cast<entities::Wall *>(selection)->level));
			tx1->setText(QString::number(reinterpret_cast<entities::Wall *>(selection)->tx1));
			ty1->setText(QString::number(reinterpret_cast<entities::Wall *>(selection)->ty1));
			tx2->setText(QString::number(reinterpret_cast<entities::Wall *>(selection)->tx2));
			ty2->setText(QString::number(reinterpret_cast<entities::Wall *>(selection)->ty2));
			tx3->setText(QString::number(reinterpret_cast<entities::Wall *>(selection)->tx3));
			ty3->setText(QString::number(reinterpret_cast<entities::Wall *>(selection)->ty3));
			tx4->setText(QString::number(reinterpret_cast<entities::Wall *>(selection)->tx4));
			ty4->setText(QString::number(reinterpret_cast<entities::Wall *>(selection)->ty4));
			texture->setText(reinterpret_cast<entities::Wall *>(selection)->texture.c_str());
			target->setText(reinterpret_cast<entities::Wall *>(selection)->target.c_str());
			path->setChecked(reinterpret_cast<entities::Wall *>(selection)->path);
			detail->setChecked(reinterpret_cast<entities::Wall *>(selection)->detail);
			staticW->setChecked(reinterpret_cast<entities::Wall *>(selection)->staticW);
			misc->setText(QString(reinterpret_cast<entities::Wall *>(selection)->misc.c_str()));

			selected = true;
			fourVertices->setEnabled(true);
			texture->setEnabled(true);
			textureLabel->setEnabled(true);
			target->setEnabled(true);
			targetLabel->setEnabled(true);
			level->setEnabled(true);
			levelLabel->setEnabled(true);
			txLabel->setEnabled(true);
			tx1->setEnabled(true);
			ty1->setEnabled(true);
			t1Label->setEnabled(true);
			t1cLabel->setEnabled(true);
			tx2->setEnabled(true);
			ty2->setEnabled(true);
			t2Label->setEnabled(true);
			t2cLabel->setEnabled(true);
			tx3->setEnabled(true);
			ty3->setEnabled(true);
			t3Label->setEnabled(true);
			t3cLabel->setEnabled(true);
			tx4->setEnabled(true);
			ty4->setEnabled(true);
			t4Label->setEnabled(true);
			t4cLabel->setEnabled(true);
			detail->setEnabled(true);
			path->setEnabled(true);
			staticW->setEnabled(true);
			misc->setEnabled(true);
		}
	}
	for(vector<entities::Path *>::iterator i = ::path.begin(); i != ::path.end(); ++i)
	{
		if(selection == reinterpret_cast<void *>(static_cast<entities::Path *>(*i)))
		{
			targetName->setText(QString(reinterpret_cast<entities::Path *>(selection)->targetName.c_str()));
			target->setText(QString(reinterpret_cast<entities::Path *>(selection)->target.c_str()));
			time->setText(QString::number(reinterpret_cast<entities::Path *>(selection)->time));
			enabled->setChecked(reinterpret_cast<entities::Path *>(selection)->enabled);
			misc->setText(QString(reinterpret_cast<entities::Path *>(selection)->misc.c_str()));

			selected = true;
			targetName->setEnabled(true);
			targetNameLabel->setEnabled(true);
			target->setEnabled(true);
			targetLabel->setEnabled(true);
			time->setEnabled(true);
			timeLabel->setEnabled(true);
			enabled->setEnabled(true);
			misc->setEnabled(true);
		}
	}
	for(vector<entities::ControlPoint *>::iterator i = ::controlPoint.begin(); i != ::controlPoint.end(); ++i)
	{
		if(selection == reinterpret_cast<void *>(static_cast<entities::ControlPoint *>(*i)))
		{
			red->setChecked(reinterpret_cast<entities::ControlPoint *>(selection)->red);
			misc->setText(QString(reinterpret_cast<entities::ControlPoint *>(selection)->misc.c_str()));

			selected = true;
			red->setEnabled(true);
			misc->setEnabled(true);
		}
	}
	for(vector<entities::Flag *>::iterator i = ::flag.begin(); i != ::flag.end(); ++i)
	{
		if(selection == reinterpret_cast<void *>(static_cast<entities::Flag *>(*i)))
		{
			red->setChecked(reinterpret_cast<entities::Flag *>(selection)->red);
			misc->setText(QString(reinterpret_cast<entities::Flag *>(selection)->misc.c_str()));

			selected = true;
			red->setEnabled(true);
			misc->setEnabled(true);
		}
	}
	for(vector<entities::WayPoint *>::iterator i = wayPoint.begin(); i != wayPoint.end(); ++i)
	{
		if(selection == reinterpret_cast<void *>(static_cast<entities::WayPoint *>(*i)))
		{
			misc->setText(QString(reinterpret_cast<entities::WayPoint *>(selection)->misc.c_str()));

			selected = true;
			misc->setEnabled(true);
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
		staticCamera->setChecked(tmap.staticCamera);
		script->setText(QString(tmap.script.c_str()));

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
		staticCamera->setEnabled(true);
		script->setEnabled(true);
	}

	connect(mapname, SIGNAL(textChanged(const QString &)), this, SLOT(mapnameChanged(const QString &)));
	connect(maptitle, SIGNAL(textChanged(const QString &)), this, SLOT(maptitleChanged(const QString &)));
	connect(mapdescription, SIGNAL(textChanged(const QString &)), this, SLOT(mapdescriptionChanged(const QString &)));
	connect(mapauthors, SIGNAL(textChanged(const QString &)), this, SLOT(mapauthorsChanged(const QString &)));
	connect(mapversions, SIGNAL(textChanged(const QString &)), this, SLOT(mapversionsChanged(const QString &)));
	connect(mapversion, SIGNAL(textChanged(const QString &)), this, SLOT(mapversionChanged(const QString &)));
	connect(staticCamera, SIGNAL(stateChanged(int)), this, SLOT(staticCameraChanged(int)));
	connect(texture, SIGNAL(textChanged(const QString &)), this, SLOT(textureChanged(const QString &)));
	connect(tx1, SIGNAL(textChanged(const QString &)), this, SLOT(tx1Changed(const QString &)));
	connect(ty1, SIGNAL(textChanged(const QString &)), this, SLOT(ty1Changed(const QString &)));
	connect(tx2, SIGNAL(textChanged(const QString &)), this, SLOT(tx2Changed(const QString &)));
	connect(ty2, SIGNAL(textChanged(const QString &)), this, SLOT(ty2Changed(const QString &)));
	connect(tx3, SIGNAL(textChanged(const QString &)), this, SLOT(tx3Changed(const QString &)));
	connect(ty3, SIGNAL(textChanged(const QString &)), this, SLOT(ty3Changed(const QString &)));
	connect(tx4, SIGNAL(textChanged(const QString &)), this, SLOT(tx4Changed(const QString &)));
	connect(ty4, SIGNAL(textChanged(const QString &)), this, SLOT(ty4Changed(const QString &)));
	connect(targetName, SIGNAL(textChanged(const QString &)), this, SLOT(targetNameChanged(const QString &)));
	connect(target, SIGNAL(textChanged(const QString &)), this, SLOT(targetChanged(const QString &)));
	connect(powerups, SIGNAL(textChanged(const QString &)), this, SLOT(powerupsChanged(const QString &)));
	connect(fourVertices, SIGNAL(stateChanged(int)), this, SLOT(fourVerticesChanged(int)));
	connect(enabled, SIGNAL(stateChanged(int)), this, SLOT(enabledChanged(int)));
	connect(level, SIGNAL(textChanged(const QString &)), this, SLOT(levelChanged(const QString &)));
	connect(time, SIGNAL(textChanged(const QString &)), this, SLOT(timeChanged(const QString &)));
	connect(repeat, SIGNAL(textChanged(const QString &)), this, SLOT(repeatChanged(const QString &)));
	connect(initial, SIGNAL(textChanged(const QString &)), this, SLOT(initialChanged(const QString &)));
	connect(autoselect, SIGNAL(stateChanged(int)), this, SLOT(autoselectChanged(int)));
	connect(nomodify, SIGNAL(stateChanged(int)), this, SLOT(nomodifyChanged(int)));
	connect(autonotexture, SIGNAL(stateChanged(int)), this, SLOT(autonotextureChanged(int)));
	connect(hideDetail, SIGNAL(stateChanged(int)), this, SLOT(hideDetailChanged(int)));
	connect(path, SIGNAL(stateChanged(int)), this, SLOT(pathChanged(int)));
	connect(detail, SIGNAL(stateChanged(int)), this, SLOT(detailChanged(int)));
	connect(staticW, SIGNAL(stateChanged(int)), this, SLOT(staticWChanged(int)));
	connect(linked, SIGNAL(stateChanged(int)), this, SLOT(linkedChanged(int)));
	connect(focus, SIGNAL(stateChanged(int)), this, SLOT(focusChanged(int)));
	connect(red, SIGNAL(stateChanged(int)), this, SLOT(redChanged(int)));
	connect(script, SIGNAL(textChanged(const QString &)), this, SLOT(scriptChanged(const QString &)));
	connect(misc, SIGNAL(textChanged(const QString &)), this, SLOT(miscChanged(const QString &)));
}

void Properties::textureChanged(const QString &text)
{
	reinterpret_cast<entities::Wall *>(selection)->texture = util_qtcp(text);
}

void Properties::tx1Changed(const QString &text)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);

	w->tx1 = atof(util_qtcp(text).c_str());
}

void Properties::ty1Changed(const QString &text)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);

	w->ty1 = atof(util_qtcp(text).c_str());
}

void Properties::tx2Changed(const QString &text)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);

	w->tx2 = atof(util_qtcp(text).c_str());
}

void Properties::ty2Changed(const QString &text)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);

	w->ty2 = atof(util_qtcp(text).c_str());
}

void Properties::tx3Changed(const QString &text)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);

	w->tx3 = atof(util_qtcp(text).c_str());
}

void Properties::ty3Changed(const QString &text)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);

	w->ty3 = atof(util_qtcp(text).c_str());
}

void Properties::tx4Changed(const QString &text)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);

	w->tx4 = atof(util_qtcp(text).c_str());
}

void Properties::ty4Changed(const QString &text)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);

	w->ty4 = atof(util_qtcp(text).c_str());
}

void Properties::targetNameChanged(const QString &text)
{
	if(trm_isPath(selection))
	{
		reinterpret_cast<entities::Path *>(selection)->targetName = util_qtcp(text);
	}
	if(trm_isTeleporter(selection))
	{
		reinterpret_cast<entities::Teleporter *>(selection)->targetName = util_qtcp(text);
	}
}

void Properties::targetChanged(const QString &text)
{
	if(trm_isPath(selection))
	{
		reinterpret_cast<entities::Path *>(selection)->target = util_qtcp(text);
	}
	if(trm_isTeleporter(selection))
	{
		reinterpret_cast<entities::Teleporter *>(selection)->target = util_qtcp(text);
	}
	if(trm_isWall(selection))
	{
		reinterpret_cast<entities::Wall *>(selection)->target = util_qtcp(text);
	}
}

void Properties::scriptChanged(const QString &text)
{
	tmap.script = util_qtcp(text);
}

void Properties::miscChanged(const QString &text)
{
	if(trm_isPlayerSpawnPoint(selection))
	{
		reinterpret_cast<entities::PlayerSpawnPoint *>(selection)->misc = util_qtcp(text);
	}
	if(trm_isPowerupSpawnPoint(selection))
	{
		reinterpret_cast<entities::PowerupSpawnPoint *>(selection)->misc = util_qtcp(text);
	}
	if(trm_isPath(selection))
	{
		reinterpret_cast<entities::Path *>(selection)->misc = util_qtcp(text);
	}
	if(trm_isTeleporter(selection))
	{
		reinterpret_cast<entities::Teleporter *>(selection)->misc = util_qtcp(text);
	}
	if(trm_isWall(selection))
	{
		reinterpret_cast<entities::Wall *>(selection)->misc = util_qtcp(text);
	}
	if(trm_isControlPoint(selection))
	{
		reinterpret_cast<entities::ControlPoint *>(selection)->misc = util_qtcp(text);
	}
	if(trm_isFlag(selection))
	{
		reinterpret_cast<entities::Flag *>(selection)->misc = util_qtcp(text);
	}
	if(trm_isWayPoint(selection))
	{
		reinterpret_cast<entities::WayPoint *>(selection)->misc = util_qtcp(text);
	}
}

void Properties::powerupsChanged(const QString &text)
{
	reinterpret_cast<entities::PowerupSpawnPoint *>(selection)->powerups = util_qtcp(text);
}

void Properties::linkedChanged(int state)
{
	entities::PowerupSpawnPoint *o = reinterpret_cast<entities::PowerupSpawnPoint *>(selection);

	if(state)
	{
		o->linked = true;
	}
	else
	{
		o->linked = false;
	}
}

void Properties::focusChanged(int state)
{
	entities::PowerupSpawnPoint *o = reinterpret_cast<entities::PowerupSpawnPoint *>(selection);

	if(state)
	{
		o->focus = true;
	}
	else
	{
		o->focus = false;
	}
}

void Properties::redChanged(int state)
{
	if(trm_isControlPoint(selection))
	{
		entities::ControlPoint *o = reinterpret_cast<entities::ControlPoint *>(selection);

		if(state)
		{
			o->red = true;
		}
		else
		{
			o->red = false;
		}
	}
	else if(trm_isFlag(selection))
	{
		entities::Flag *o = reinterpret_cast<entities::Flag *>(selection);

		if(state)
		{
			o->red = true;
		}
		else
		{
			o->red = false;
		}
	}
}

void Properties::repeatChanged(const QString &text)
{
	entities::PowerupSpawnPoint *o = reinterpret_cast<entities::PowerupSpawnPoint *>(selection);

	o->repeat = atof(util_qtcp(text).c_str());
}

void Properties::initialChanged(const QString &text)
{
	entities::PowerupSpawnPoint *o = reinterpret_cast<entities::PowerupSpawnPoint *>(selection);

	o->initial = atof(util_qtcp(text).c_str());
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

void Properties::enabledChanged(int state)
{
	if(trm_isPath(selection))
	{
		entities::Path *p = reinterpret_cast<entities::Path *>(selection);

		p->enabled = state;
	}
	if(trm_isTeleporter(selection))
	{
		entities::Teleporter *t = reinterpret_cast<entities::Teleporter *>(selection);

		t->enabled = state;
	}
}

void Properties::detailChanged(int state)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);

	if(state)
	{
		w->detail = true;
	}
	else
	{
		w->detail = false;
	}
}

void Properties::pathChanged(int state)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);

	if(state)
	{
		w->path = true;
	}
	else
	{
		w->path = false;
	}
}


void Properties::staticWChanged(int state)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);

	if(state)
	{
		w->staticW = true;
	}
	else
	{
		w->staticW = false;
	}
}

void Properties::levelChanged(const QString &text)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);

	w->level = util_atoi(util_qtcp(text).c_str());
}

void Properties::timeChanged(const QString &text)
{
	entities::Path *p = reinterpret_cast<entities::Path *>(selection);

	p->time = atof(util_qtcp(text).c_str());
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

void Properties::hideDetailChanged(int state)
{
	config_set_int(c_hideDetail, state);
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

void Properties::staticCameraChanged(int state)
{
	tmap.staticCamera = state;
}
