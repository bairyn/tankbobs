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
			enable->setText(QString::number(reinterpret_cast<entities::PowerupSpawnPoint *>(selection)->enable));

			selected = true;
			powerups->setEnabled(true);
			powerupsLabel->setEnabled(true);
			enable->setEnabled(true);
			enableLabel->setEnabled(true);
		}
	}
	for(vector<entities::Teleporter *>::iterator i = teleporter.begin(); i != teleporter.end(); ++i)
	{
		if(selection == reinterpret_cast<void *>(static_cast<entities::Teleporter *>(*i)))
		{
			group->setText(QString::number(reinterpret_cast<entities::Teleporter *>(selection)->group));
			active->setText(QString::number(reinterpret_cast<entities::Teleporter *>(selection)->active));

			selected = true;
			group->setEnabled(true);
			groupLabel->setEnabled(true);
			active->setEnabled(true);
			activeLabel->setEnabled(true);
		}
	}
	for(vector<entities::Wall *>::iterator i = wall.begin(); i != wall.end(); ++i)
	{
		if(selection == reinterpret_cast<void *>(static_cast<entities::Wall *>(*i)))
		{
			fourVertices->setChecked(reinterpret_cast<entities::Wall *>(selection)->x4 != NOVALUEDOUBLE && reinterpret_cast<entities::Wall *>(selection)->y4 != NOVALUEDOUBLE);
			detail->setChecked(reinterpret_cast<entities::Wall *>(selection)->flags.find("detail") != string::npos);
			structural->setChecked(reinterpret_cast<entities::Wall *>(selection)->flags.find("structural") != string::npos);
			backmost->setChecked(reinterpret_cast<entities::Wall *>(selection)->flags.find("backmost") != string::npos);
			back->setChecked(reinterpret_cast<entities::Wall *>(selection)->flags.find("back") != string::npos);
			backleast->setChecked(reinterpret_cast<entities::Wall *>(selection)->flags.find("backleast") != string::npos);
			topleast->setChecked(reinterpret_cast<entities::Wall *>(selection)->flags.find("topleast") != string::npos);
			top->setChecked(reinterpret_cast<entities::Wall *>(selection)->flags.find("top") != string::npos);
			topmost->setChecked(reinterpret_cast<entities::Wall *>(selection)->flags.find("topmost") != string::npos);
			backmostmore->setChecked(reinterpret_cast<entities::Wall *>(selection)->flags.find("backmostmore") != string::npos);
			backmostmost->setChecked(reinterpret_cast<entities::Wall *>(selection)->flags.find("backmostmost") != string::npos);
			missiles->setChecked(reinterpret_cast<entities::Wall *>(selection)->flags.find("missiles") != string::npos);
			nopass->setChecked(reinterpret_cast<entities::Wall *>(selection)->flags.find("nopass") != string::npos);
			damage->setChecked(reinterpret_cast<entities::Wall *>(selection)->flags.find("damage") != string::npos);
			touch->setChecked(reinterpret_cast<entities::Wall *>(selection)->flags.find("touch") != string::npos);
			texture->setText(QString(reinterpret_cast<entities::Wall *>(selection)->texture.c_str()));
			script1->setText(QString(reinterpret_cast<entities::Wall *>(selection)->script1.c_str()));
			script2->setText(QString(reinterpret_cast<entities::Wall *>(selection)->script2.c_str()));
			script3->setText(QString(reinterpret_cast<entities::Wall *>(selection)->script3.c_str()));

			selected = true;
			texture->setEnabled(true);
			textureLabel->setEnabled(true);
			script1->setEnabled(true);
			script1Label->setEnabled(true);
			script2->setEnabled(true);
			script2Label->setEnabled(true);
			script3->setEnabled(true);
			script3Label->setEnabled(true);
			detail->setEnabled(true);
			structural->setEnabled(true);
			nopass->setEnabled(true);
			missiles->setEnabled(true);
			damage->setEnabled(true);
			touch->setEnabled(true);
			backmost->setEnabled(true);
			back->setEnabled(true);
			backleast->setEnabled(true);
			topleast->setEnabled(true);
			top->setEnabled(true);
			topmost->setEnabled(true);
			backmostmore->setEnabled(true);
			backmostmost->setEnabled(true);
		}
	}
	if(!selected)
	{
		mapid->setText(QString::number(tmap.id));
		mapname->setText(QString(tmap.name.c_str()));
		maptitle->setText(QString(tmap.title.c_str()));
		mapdescription->setText(QString(tmap.description.c_str()));
		mapauthors->setText(QString(tmap.authors.c_str()));
		mapversion->setText(QString(tmap.version.c_str()));
		setid->setText(QString::number(tmap.setid));
		setorder->setText(QString::number(tmap.setorder));
		setname->setText(QString(tmap.setname.c_str()));
		settitle->setText(QString(tmap.settitle.c_str()));
		setdescription->setText(QString(tmap.setdescription.c_str()));
		setauthors->setText(QString(tmap.setauthors.c_str()));
		setversion->setText(QString(tmap.setversion.c_str()));

		mapid->setEnabled(true);
		mapidLabel->setEnabled(true);
		mapname->setEnabled(true);
		mapnameLabel->setEnabled(true);
		maptitle->setEnabled(true);
		maptitleLabel->setEnabled(true);
		mapdescription->setEnabled(true);
		mapdescriptionLabel->setEnabled(true);
		mapauthors->setEnabled(true);
		mapauthorsLabel->setEnabled(true);
		mapversion->setEnabled(true);
		mapversionLabel->setEnabled(true);
		setid->setEnabled(true);
		setidLabel->setEnabled(true);
		setorder->setEnabled(true);
		setorderLabel->setEnabled(true);
		setname->setEnabled(true);
		setnameLabel->setEnabled(true);
		settitle->setEnabled(true);
		settitleLabel->setEnabled(true);
		setdescription->setEnabled(true);
		setdescriptionLabel->setEnabled(true);
		setauthors->setEnabled(true);
		setauthorsLabel->setEnabled(true);
		setversion->setEnabled(true);
		setversionLabel->setEnabled(true);
	}

	connect(mapid, SIGNAL(textChanged(const QString &)), this, SLOT(mapidChanged(const QString &)));
	connect(mapname, SIGNAL(textChanged(const QString &)), this, SLOT(mapnameChanged(const QString &)));
	connect(maptitle, SIGNAL(textChanged(const QString &)), this, SLOT(maptitleChanged(const QString &)));
	connect(mapdescription, SIGNAL(textChanged(const QString &)), this, SLOT(mapdescriptionChanged(const QString &)));
	connect(mapauthors, SIGNAL(textChanged(const QString &)), this, SLOT(mapauthorsChanged(const QString &)));
	connect(mapversion, SIGNAL(textChanged(const QString &)), this, SLOT(mapversionChanged(const QString &)));
	connect(mapinitscript, SIGNAL(textChanged(const QString &)), this, SLOT(mapinitscriptChanged(const QString &)));
	connect(mapexitscript, SIGNAL(textChanged(const QString &)), this, SLOT(mapexitscriptChanged(const QString &)));
	connect(setid, SIGNAL(textChanged(const QString &)), this, SLOT(setidChanged(const QString &)));
	connect(setorder, SIGNAL(textChanged(const QString &)), this, SLOT(setorderChanged(const QString &)));
	connect(setname, SIGNAL(textChanged(const QString &)), this, SLOT(setnameChanged(const QString &)));
	connect(settitle, SIGNAL(textChanged(const QString &)), this, SLOT(settitleChanged(const QString &)));
	connect(setdescription, SIGNAL(textChanged(const QString &)), this, SLOT(setdescriptionChanged(const QString &)));
	connect(setauthors, SIGNAL(textChanged(const QString &)), this, SLOT(setauthorsChanged(const QString &)));
	connect(setversion, SIGNAL(textChanged(const QString &)), this, SLOT(setversionChanged(const QString &)));
	connect(texture, SIGNAL(textChanged(const QString &)), this, SLOT(textureChanged(const QString &)));
	connect(script1, SIGNAL(textChanged(const QString &)), this, SLOT(script1Changed(const QString &)));
	connect(script2, SIGNAL(textChanged(const QString &)), this, SLOT(script2Changed(const QString &)));
	connect(script3, SIGNAL(textChanged(const QString &)), this, SLOT(script3Changed(const QString &)));
	connect(group, SIGNAL(textChanged(const QString &)), this, SLOT(groupChanged(const QString &)));
	connect(active, SIGNAL(textChanged(const QString &)), this, SLOT(activeChanged(const QString &)));
	connect(powerups, SIGNAL(textChanged(const QString &)), this, SLOT(powerupsChanged(const QString &)));
	connect(enable, SIGNAL(textChanged(const QString &)), this, SLOT(enableChanged(const QString &)));
	connect(fourVertices, SIGNAL(stateChanged(int)), this, SLOT(fourVerticesChanged(int)));
	connect(detail, SIGNAL(stateChanged(int)), this, SLOT(detailChanged(int)));
	connect(structural, SIGNAL(stateChanged(int)), this, SLOT(structuralChanged(int)));
	connect(backmost, SIGNAL(stateChanged(int)), this, SLOT(backmostChanged(int)));
	connect(back, SIGNAL(stateChanged(int)), this, SLOT(backChanged(int)));
	connect(backleast, SIGNAL(stateChanged(int)), this, SLOT(backleastChanged(int)));
	connect(topleast, SIGNAL(stateChanged(int)), this, SLOT(topleastChanged(int)));
	connect(top, SIGNAL(stateChanged(int)), this, SLOT(topChanged(int)));
	connect(topmost, SIGNAL(stateChanged(int)), this, SLOT(topmostChanged(int)));
	connect(backmostmore, SIGNAL(stateChanged(int)), this, SLOT(backmostmoreChanged(int)));
	connect(backmostmost, SIGNAL(stateChanged(int)), this, SLOT(backmostmostChanged(int)));
	connect(missiles, SIGNAL(stateChanged(int)), this, SLOT(missilesChanged(int)));
	connect(nopass, SIGNAL(stateChanged(int)), this, SLOT(nopassChanged(int)));
	connect(damage, SIGNAL(stateChanged(int)), this, SLOT(damageChanged(int)));
	connect(touch, SIGNAL(stateChanged(int)), this, SLOT(touchChanged(int)));
	connect(autoselect, SIGNAL(stateChanged(int)), this, SLOT(autoselectChanged(int)));
	connect(nomodify, SIGNAL(stateChanged(int)), this, SLOT(nomodifyChanged(int)));
	connect(autonotexture, SIGNAL(stateChanged(int)), this, SLOT(autonotextureChanged(int)));
}

void Properties::textureChanged(const QString &text)
{
	reinterpret_cast<entities::Wall *>(selection)->texture = util_qtcp(text);
}

void Properties::script1Changed(const QString &text)
{
	reinterpret_cast<entities::Wall *>(selection)->script1 = util_qtcp(text);
}

void Properties::script2Changed(const QString &text)
{
	reinterpret_cast<entities::Wall *>(selection)->script2 = util_qtcp(text);
}

void Properties::script3Changed(const QString &text)
{
	reinterpret_cast<entities::Wall *>(selection)->script3 = util_qtcp(text);
}

void Properties::groupChanged(const QString &text)
{
	reinterpret_cast<entities::Teleporter *>(selection)->group = util_atoi(util_qtcp(text).c_str());
}

void Properties::activeChanged(const QString &text)
{
	reinterpret_cast<entities::Teleporter *>(selection)->active = util_atoi(util_qtcp(text).c_str());
}

void Properties::powerupsChanged(const QString &text)
{
	reinterpret_cast<entities::PowerupSpawnPoint *>(selection)->powerups = util_qtcp(text);
}

void Properties::enableChanged(const QString &text)
{
	reinterpret_cast<entities::PowerupSpawnPoint *>(selection)->enable = util_atoi(util_qtcp(text).c_str());
}

void Properties::fourVerticesChanged(int state)
{
	entities::Wall *w = reinterpret_cast<entities::Wall *>(selection);
	if(state)
	{
		w->x4 = (w->x1 + w->x2 + w->x3) / 3;
		w->y4 = (w->y1 + w->y2 + w->y3) / 3;
	}
	else
	{
		w->x4 = NOVALUEDOUBLE;
		w->y4 = NOVALUEDOUBLE;
	}
}

void Properties::detailChanged(int state)
{
	string s("detail");
	string &f = reinterpret_cast<entities::Wall *>(selection)->flags;
	int pos = static_cast<signed int>(f.find(s));
	if(state)
	{
		/* add detail */
		f.append(s);
	}
	else
	{
		/* take away detail */
		f.erase(pos, s.length());
	}
}

void Properties::structuralChanged(int state)
{
	string s("structural");
	string &f = reinterpret_cast<entities::Wall *>(selection)->flags;
	int pos = static_cast<signed int>(f.find(s));
	if(state)
	{
		/* add detail */
		f.append(s);
	}
	else
	{
		/* take away detail */
		f.erase(pos, s.length());
	}
}

void Properties::backmostChanged(int state)
{
	string s("backmost");
	string &f = reinterpret_cast<entities::Wall *>(selection)->flags;
	int pos = static_cast<signed int>(f.find(s));
	if(state)
	{
		/* add detail */
		f.append(s);
	}
	else
	{
		/* take away detail */
		f.erase(pos, s.length());
	}
}

void Properties::backChanged(int state)
{
	string s("back");
	string &f = reinterpret_cast<entities::Wall *>(selection)->flags;
	int pos = static_cast<signed int>(f.find(s));
	if(state)
	{
		/* add detail */
		f.append(s);
	}
	else
	{
		/* take away detail */
		f.erase(pos, s.length());
	}
}

void Properties::backleastChanged(int state)
{
	string s("backleast");
	string &f = reinterpret_cast<entities::Wall *>(selection)->flags;
	int pos = static_cast<signed int>(f.find(s));
	if(state)
	{
		/* add detail */
		f.append(s);
	}
	else
	{
		/* take away detail */
		f.erase(pos, s.length());
	}
}

void Properties::topleastChanged(int state)
{
	string s("topleast");
	string &f = reinterpret_cast<entities::Wall *>(selection)->flags;
	int pos = static_cast<signed int>(f.find(s));
	if(state)
	{
		/* add detail */
		f.append(s);
	}
	else
	{
		/* take away detail */
		f.erase(pos, s.length());
	}
}

void Properties::topChanged(int state)
{
	string s("top");
	string &f = reinterpret_cast<entities::Wall *>(selection)->flags;
	int pos = static_cast<signed int>(f.find(s));
	if(state)
	{
		/* add detail */
		f.append(s);
	}
	else
	{
		/* take away detail */
		f.erase(pos, s.length());
	}
}

void Properties::topmostChanged(int state)
{
	string s("topmost");
	string &f = reinterpret_cast<entities::Wall *>(selection)->flags;
	int pos = static_cast<signed int>(f.find(s));
	if(state)
	{
		/* add detail */
		f.append(s);
	}
	else
	{
		/* take away detail */
		f.erase(pos, s.length());
	}
}

void Properties::backmostmoreChanged(int state)
{
	string s("backmostmore");
	string &f = reinterpret_cast<entities::Wall *>(selection)->flags;
	int pos = static_cast<signed int>(f.find(s));
	if(state)
	{
		/* add detail */
		f.append(s);
	}
	else
	{
		/* take away detail */
		f.erase(pos, s.length());
	}
}

void Properties::backmostmostChanged(int state)
{
	string s("backmostmost");
	string &f = reinterpret_cast<entities::Wall *>(selection)->flags;
	int pos = static_cast<signed int>(f.find(s));
	if(state)
	{
		/* add detail */
		f.append(s);
	}
	else
	{
		/* take away detail */
		f.erase(pos, s.length());
	}
}

void Properties::missilesChanged(int state)
{
	string s("missiles");
	string &f = reinterpret_cast<entities::Wall *>(selection)->flags;
	int pos = static_cast<signed int>(f.find(s));
	if(state)
	{
		/* add detail */
		f.append(s);
	}
	else
	{
		/* take away detail */
		f.erase(pos, s.length());
	}
}

void Properties::nopassChanged(int state)
{
	string s("nopass");
	string &f = reinterpret_cast<entities::Wall *>(selection)->flags;
	int pos = static_cast<signed int>(f.find(s));
	if(state)
	{
		/* add detail */
		f.append(s);
	}
	else
	{
		/* take away detail */
		f.erase(pos, s.length());
	}
}

void Properties::damageChanged(int state)
{
	string s("damage");
	string &f = reinterpret_cast<entities::Wall *>(selection)->flags;
	int pos = static_cast<signed int>(f.find(s));
	if(state)
	{
		/* add detail */
		f.append(s);
	}
	else
	{
		/* take away detail */
		f.erase(pos, s.length());
	}
}

void Properties::touchChanged(int state)
{
	string s("touch");
	string &f = reinterpret_cast<entities::Wall *>(selection)->flags;
	int pos = static_cast<signed int>(f.find(s));
	if(state)
	{
		/* add detail */
		f.append(s);
	}
	else
	{
		/* take away detail */
		f.erase(pos, s.length());
	}
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

void Properties::mapidChanged(const QString &text)
{
	tmap.id = util_atoi(util_qtcp(text).c_str());
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

void Properties::mapversionChanged(const QString &text)
{
	tmap.version = util_qtcp(text);
}

void Properties::mapinitscriptChanged(const QString &text)
{
	tmap.initscript = util_qtcp(text);
}

void Properties::mapexitscriptChanged(const QString &text)
{
	tmap.exitscript = util_qtcp(text);
}

void Properties::setidChanged(const QString &text)
{
	tmap.setid = util_atoi(util_qtcp(text).c_str());
}

void Properties::setorderChanged(const QString &text)
{
	tmap.setorder = util_atoi(util_qtcp(text).c_str());
}

void Properties::setnameChanged(const QString &text)
{
	tmap.setname = util_qtcp(text);
}

void Properties::settitleChanged(const QString &text)
{
	tmap.settitle = util_qtcp(text);
}

void Properties::setdescriptionChanged(const QString &text)
{
	tmap.setdescription = util_qtcp(text);
}

void Properties::setauthorsChanged(const QString &text)
{
	tmap.setauthors = util_qtcp(text);
}

void Properties::setversionChanged(const QString &text)
{
	tmap.setversion = util_qtcp(text);
}
