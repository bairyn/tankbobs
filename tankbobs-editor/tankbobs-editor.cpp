#include <iostream>
#include <QtGui>
#include <vector>
#include <string>
#include <GL/gl.h>
#include "tankbobs-editor.h"
#include "trm.h"
#include "entities.h"
#include "config.h"
#include "util.h"
using namespace std;

extern bool modified;
extern entities::Map tmap;
extern vector<entities::PlayerSpawnPoint *>  playerSpawnPoint;
extern vector<entities::PowerupSpawnPoint *> powerupSpawnPoint;
extern vector<entities::Teleporter *>        teleporter;
extern vector<entities::Wall *>              wall;
//extern vector<void *> selection;

double *x_selected = NULL, *y_selected = NULL;

char order = 0;

// TODO: implement queue for keyXLast, or handle it better
static bool ctrl = false;
static bool shift = false;
// shift translates; control translates vertices.
// with both selected, group select.
static int keyPressLast = 0, keyReleaseLast = 0;
static int entBase = 0, gridBase = 0;
QString file = "";
extern void *selection;  // TODO: use a vector instead of a single pointer
extern int selectionType;
static int x_begin = -1, y_begin = -1, x_end = -1, y_end = -1;
double zoom = 1.0;
static int y_last_zoom = 0;
int x_scroll = 0, y_scroll = 0;

Tankbobs_editor::Tankbobs_editor(QWidget *parent)
{
	QGLFormat fmt;
	fmt.setAlpha(true);
	fmt.setDepth(true);
	fmt.setDirectRendering(true);
	fmt.setDoubleBuffer(true);
	fmt.setSamples(4);
	fmt.setSampleBuffers(true);
	fmt.setRgba(true);
	fmt.setSwapInterval(60);
	QGLFormat::setDefaultFormat(fmt);

	setupUi(this);

	connect(cancel0, SIGNAL(clicked()), this, SLOT(selectionCancel()));
	connect(cancel1, SIGNAL(clicked()), this, SLOT(selectionCancel()));
	connect(wall, SIGNAL(clicked()), this, SLOT(selectionWall()));
	connect(playerSpawnPoint, SIGNAL(clicked()), this, SLOT(selectionPlayerSpawnPoint()));
	connect(powerupSpawnPoint, SIGNAL(clicked()), this, SLOT(selectionPowerupSpawnPoint()));
	connect(teleporter, SIGNAL(clicked()), this, SLOT(selectionTeleporter()));
	connect(actionImport, SIGNAL(triggered()), this, SLOT(import()));
	connect(actionOpen, SIGNAL(triggered()), this, SLOT(open()));
	connect(actionSave, SIGNAL(triggered()), this, SLOT(save()));
	connect(actionSave_As, SIGNAL(triggered()), this, SLOT(saveAs()));
	connect(actionExit, SIGNAL(triggered()), this, SLOT(exit()));
	connect(actionOpenDirectory, SIGNAL(triggered()), this, SLOT(openTextureDirectory()));
	connect(actionClear, SIGNAL(triggered()), this, SLOT(statusClear()));

//	grabKeyboard();
}

void Tankbobs_editor::selectionCancel()
{
	selectionType = e_selectionNone;
}

void Tankbobs_editor::selectionWall()
{
	selectionType = e_selectionWall;
}

void Tankbobs_editor::selectionPlayerSpawnPoint()
{
	selectionType = e_selectionPlayerSpawnPoint;
}

void Tankbobs_editor::selectionPowerupSpawnPoint()
{
	selectionType = e_selectionPowerupSpawnPoint;
}

void Tankbobs_editor::selectionTeleporter()
{
	selectionType = e_selectionTeleporter;
}

void Tankbobs_editor::tsaveAs(void)
{
	QString tmp, def = "Tankbobs Raw Map (*.trm)";
	extern Tankbobs_editor *window;
	tmp = QFileDialog::getSaveFileName(window, tr("Save File"), tr(""), tr("All Files (*);;Tankbobs Raw Map (*.trm)"), &def);
	if(tmp.length())
	{
		file = tmp;
		window->setWindowTitle(QString(file.right(file.lastIndexOf('/'))) + QString(" - ") + QString(file) + QString(" - tankbobs-editor"));
		char *f = reinterpret_cast<char *>(malloc(2000 + 1));
		if(!f || file.length() > 2000)
		{
			if(f)
				free(f);
			QMessageBox::critical(window, "FS error", "The file name is too large for tankbobs-editor.  Please report this problem.");
			fprintf(stderr, "The file name is too large for tankbobs-editor.  Please report this problem.\n");
		}
		strncpy(f, util_qtcp(file).c_str(), 2000);
		if(!trm_save(f))
		{
			free(f);
			QMessageBox::critical(window, "FS error", "Could not save file.");
			fprintf(stderr, "Could not save file.\n");
		}
		free(f);
		modified = false;
	}
}

void Tankbobs_editor::tsave(void)
{
	extern Tankbobs_editor *window;
	if(!file.length())
		return tsaveAs();
	char *f = reinterpret_cast<char *>(malloc(2000 + 1));
	if(!f || file.length() > 2000)
	{
		if(f)
			free(f);
		QMessageBox::critical(window, "FS error", "The file name is too large for tankbobs-editor.  Please report this problem.");
		fprintf(stderr, "The file name is too large for tankbobs-editor.  Please report this problem.\n");
	}
	strncpy(f, util_qtcp(file).c_str(), 2000);
	if(!trm_save(f))
	{
		free(f);
		QMessageBox::critical(window, "FS error", "Could not save file.");
		fprintf(stderr, "Could not save file.\n");
	}
	free(f);
	modified = false;
}

void Tankbobs_editor::topen(void)
{
	extern Tankbobs_editor *window;
	if(modified)
		if(QMessageBox::question(window, "Confirm", "Are you sure you want to continue?\nUnsaved progress might be lost", QMessageBox::Yes | QMessageBox::No) != QMessageBox::Yes)
			return;
	QString tmp, def = "Tankbobs Raw Map (*.trm)";
	tmp = QFileDialog::getOpenFileName(window, tr("Open File"), tr(""), tr("All Files (*);;Tankbobs Raw Map (*.trm)"), &def);
	if(tmp.length())
	{
		file = tmp;
		window->setWindowTitle(QString(file.right(file.lastIndexOf('/'))) + QString(" - ") + QString(file) + QString(" - tankbobs-editor"));
		char *f = reinterpret_cast<char *>(malloc(2000 + 1));
		if(!f || file.length() > 2000)
		{
			if(f)
				free(f);
			QMessageBox::critical(window, "FS error", "The file name is too large for tankbobs-editor.  Please report this problem.");
			fprintf(stderr, "The file name is too large for tankbobs-editor.  Please report this problem.\n");
		}
		strncpy(f, util_qtcp(file).c_str(), 2000);
		if(!trm_open(f, false))
		{
			free(f);
			QMessageBox::critical(window, "FS error", "Could not open file.");
			fprintf(stderr, "Could not open file.\n");
		}
		free(f);
	}
}

void Tankbobs_editor::timport(void)
{
	extern Tankbobs_editor *window;
	if(modified)
		if(QMessageBox::question(window, "Confirm", "Are you sure you want to continue?\nUnsaved progress might be lost", QMessageBox::Yes | QMessageBox::No) != QMessageBox::Yes)
			return;
	QString tmp, def = "Tankbobs Raw Map (*.trm)";
	tmp = QFileDialog::getOpenFileName(window, tr("Open File"), tr(""), tr("All Files (*);;Tankbobs Raw Map (*.trm)"), &def);
	if(tmp.length())
	{
		file = tmp;
		window->setWindowTitle(QString(file.right(file.lastIndexOf('/'))) + QString(" - ") + QString(file) + QString(" - tankbobs-editor"));
		char *f = reinterpret_cast<char *>(malloc(2000 + 1));
		if(!f || file.length() > 2000)
		{
			if(f)
				free(f);
			QMessageBox::critical(window, "FS error", "The file name is too large for tankbobs-editor.  Please report this problem.");
			fprintf(stderr, "The file name is too large for tankbobs-editor.  Please report this problem.\n");
		}
		strncpy(f, util_qtcp(file).c_str(), 2000);
		if(!trm_open(f, true))
		{
			free(f);
			QMessageBox::critical(window, "FS error", "Could not open file.");
			fprintf(stderr, "Could not open file.\n");
		}
		window->setWindowTitle(QString(file.right(file.lastIndexOf('/'))) + QString(" - ") + QString(file) + QString(" - tankbobs-editor"));
		free(f);
	}
}

void Tankbobs_editor::save()
{
	tsave();
}

void Tankbobs_editor::saveAs()
{
	tsaveAs();
}

void Tankbobs_editor::import()
{
	timport();
}

void Tankbobs_editor::open()
{
	topen();
}

void Tankbobs_editor::exit()
{
	glDeleteLists(entBase, e_numSelection);
	QCoreApplication::exit(EXIT_SUCCESS);
}

Editor::Editor(QWidget *parent) : QGLWidget(parent)
{
	connect(&QTa, SIGNAL(timeout()), this, SLOT(updateGL()));
	QTa.start();
}

Texture::Texture(QWidget *parent) : QGLWidget(parent)
{
	connect(&QTa, SIGNAL(timeout()), this, SLOT(updateGL()));
	QTa.start(500);
}

void Editor::exit()
{
	glDeleteLists(entBase, e_numSelection);
	QCoreApplication::exit(EXIT_SUCCESS);
}

void Tankbobs_editor::openTextureDirectory()
{
	QString tmp;
	tmp = QFileDialog::getExistingDirectory(this, tr("Open File"), tr(""));
	if(tmp.length())
	{
		QMessageBox::warning(this, "Not available", "Requested action not available yet");
	}
}

void Tankbobs_editor::statusAppend(const QString &s)
{
	textStatus->append(s);
}

void Tankbobs_editor::statusClear()
{
	textStatus->clear();
}

void Editor::resizeGL(int w, int h)
{
	glViewport(0.0, 0.0, w, h);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(0.0, GRIDSIZE, 0.0, GRIDSIZE, -1.0, 1.0);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}

int Editor::mx(int x)
{
	return static_cast<int>(GRIDSIZE / zoom * static_cast<double>(x) / static_cast<double>(width()));
}

int Editor::my(int y)
{
	return GRIDSIZE / zoom - static_cast<int>(GRIDSIZE / zoom * static_cast<double>(y) / static_cast<double>(height()));
}

void Editor::mousePressEvent(QMouseEvent *e)
{
	x_begin = x_end = mx(e->x());
	y_begin = y_end = my(e->y());

	if(e->buttons() & Qt::MidButton)
		y_last_zoom = e->y();

	if(!((e->buttons() & Qt::RightButton) || (e->buttons() & Qt::MidButton) || (e->button() == Qt::RightButton) || (e->button() == Qt::MidButton)))
	{
		if(ctrl && shift)
		{
			// group select
		}
		else if(ctrl)
		{
			// translate vertices

			// select nearest vertex
			bool selected = x_selected || y_selected;
			if(!selected)
			for(vector<entities::PlayerSpawnPoint *>::iterator i = playerSpawnPoint.begin(); i != playerSpawnPoint.end(); ++i)
			{
				entities::PlayerSpawnPoint *e = *i;

				if(trm_isSelected(e))
				{
					if(config_get_int(c_noModify))
					{
						trm_modifyAttempted();
						return;
					}

					modified = true;

					selected = true;
				}
			}
			if(!selected)
			for(vector<entities::PowerupSpawnPoint *>::iterator i = powerupSpawnPoint.begin(); i != powerupSpawnPoint.end(); ++i)
			{
				entities::PowerupSpawnPoint *e = *i;

				if(trm_isSelected(e))
				{
					if(config_get_int(c_noModify))
					{
						trm_modifyAttempted();
						return;
					}

					modified = true;

					selected = true;
				}
			}
			if(!selected)
			for(vector<entities::Teleporter *>::iterator i = teleporter.begin(); i != teleporter.end(); ++i)
			{
				entities::Teleporter *e = *i;

				if(trm_isSelected(e))
				{
					if(config_get_int(c_noModify))
					{
						trm_modifyAttempted();
						return;
					}

					modified = true;

					selected = true;
				}
			}
			if(!selected)
			for(vector<entities::Wall *>::iterator i = wall.begin(); i != wall.end(); ++i)
			{
				entities::Wall *e = *i;

				if(trm_isSelected(e))
				{
					if(config_get_int(c_noModify))
					{
						trm_modifyAttempted();
						return;
					}

					modified = true;

					selected = true;

					// find the nearest vertex
					x_selected = &e->x1;
					y_selected = &e->y1;
					if(sqrt(pow(*x_selected - x_end, 2) + pow(*y_selected - y_end, 2)) < sqrt(pow(e->x2 - x_end, 2) + pow(e->y2 - y_end, 2)))
					{
						x_selected = &e->x2;
						x_selected = &e->y2;
					}
					if(sqrt(pow(*x_selected - x_end, 2) + pow(*y_selected - y_end, 2)) < sqrt(pow(e->x3 - x_end, 2) + pow(e->y3 - y_end, 2)))
					{
						x_selected = &e->x3;
						x_selected = &e->y3;
					}
					if(e->quad)
					if(sqrt(pow(*x_selected - x_end, 2) + pow(*y_selected - y_end, 2)) < sqrt(pow(e->x4 - x_end, 2) + pow(e->y4 - y_end, 2)))
					{
						x_selected = &e->x4;
						x_selected = &e->y4;
					}
				}
			}

		}
		else if(shift)
		{
			// translate
		}
		else
		{
			// individual select or build
		}
	}
}

void Editor::mouseReleaseEvent(QMouseEvent *e)
{
	x_end = mx(e->x());
	y_end = my(e->y());

	if(e->modifiers() & Qt::ControlModifier)
		ctrl = true;
	else
		ctrl = false;
	if(e->modifiers() & Qt::ShiftModifier)
		shift = true;
	else
		shift = false;

	if(!((e->buttons() & Qt::RightButton) || (e->buttons() & Qt::MidButton) || (e->button() == Qt::RightButton) || (e->button() == Qt::MidButton)))
	{
		x_selected = NULL;
		y_selected = NULL;

		if(!ctrl && !shift)
		{
			switch(selectionType)
			{
				case e_selectionNone:
					trm_select(x_end - x_scroll, y_end - y_scroll);
					break;

				case e_selectionWall:
					trm_newWall(x_begin - x_scroll, y_begin - y_scroll, x_end - x_scroll, y_end - y_scroll);
					break;

				case e_selectionPlayerSpawnPoint:
					trm_newPlayerSpawnPoint(x_end - x_scroll, y_end - y_scroll);
					break;

				case e_selectionPowerupSpawnPoint:
					trm_newPowerupSpawnPoint(x_end - x_scroll, y_end - y_scroll);
					break;

				case e_selectionTeleporter:
					trm_newTeleporter(x_end - x_scroll, y_end - y_scroll);
					break;

				default:
					QMessageBox::critical(this, "Entity type selection error", "The selected entity type was not recognized.");
					fprintf(stderr, "The selected entity type was not recognized.\n");
					this->exit();
					break;
			}

			if(config_get_int(c_autoSelect))
				selectionType = e_selectionNone;
		}
	}

	x_begin = -1;
	y_begin = -1;
}

void Tankbobs_editor::keyPressEvent(QKeyEvent *e)
{
	if(e->key() == Qt::Key_Control)
		ctrl = true;
	if(e->key() == Qt::Key_Shift)
		shift = true;

	keyPressLast = trm_keypress(e->key(), !e->isAutoRepeat(), e);
}

void Tankbobs_editor::keyReleaseEvent(QKeyEvent *e)
{
	if(e->key() == Qt::Key_Control)
		ctrl = false;
	if(e->key() == Qt::Key_Shift)
		shift = false;

	keyReleaseLast = trm_keyrelease(e->key(), e);
}

void Editor::mouseMoveEvent(QMouseEvent *e)
{
	if(x_begin >= 0 && y_begin >= 0)
	{
		int x_last_scroll = x_end;
		int y_last_scroll = y_end;

		x_end = mx(e->x());
		y_end = my(e->y());

		if(e->buttons() & Qt::RightButton)
		{
			x_scroll += x_end - x_last_scroll;
			y_scroll += y_end - y_last_scroll;
			if(x_scroll > MAXSCROLL)
				x_scroll = MAXSCROLL;
			if(x_scroll < MINSCROLL)
				x_scroll = MINSCROLL;
			if(y_scroll > MAXSCROLL)
				y_scroll = MAXSCROLL;
			if(y_scroll < MINSCROLL)
				y_scroll = MINSCROLL;
		}

		if(e->buttons() & Qt::MidButton)
		{
			//double tmp = zoom;
			double z = zoom + ZOOMFACTOR * (y_last_zoom - e->y());
			y_last_zoom = e->y();
			zoom += zoom * zoom * (z - zoom) * ZOOMQUADFACTOR;
			if(zoom < MINZOOM)
				zoom = MINZOOM;
			if(zoom > MAXZOOM)
				zoom = MAXZOOM;
			if(x_scroll < SMALL && x_scroll > -SMALL) x_scroll = SMALL;
			if(y_scroll < SMALL && y_scroll > -SMALL) y_scroll = SMALL;
			//x_scroll += (tmp - zoom) / x_scroll;
			//y_scroll += (tmp - zoom) / y_scroll;
		}

		if(!shift && ctrl)
		{
			*x_selected += x_end - x_last_scroll;
			*y_selected += y_end - y_last_scroll;
		}
		else if(shift && !ctrl)
		{
			// translate all selected
			for(vector<entities::PlayerSpawnPoint *>::iterator i = playerSpawnPoint.begin(); i != playerSpawnPoint.end(); ++i)
			{
				entities::PlayerSpawnPoint *e = *i;

				if(trm_isSelected(e))
				{
					if(config_get_int(c_noModify))
					{
						trm_modifyAttempted();
						return;
					}

					modified = true;

					e->x += x_end - x_last_scroll;
					e->y += y_end - y_last_scroll;
				}
			}
			for(vector<entities::PowerupSpawnPoint *>::iterator i = powerupSpawnPoint.begin(); i != powerupSpawnPoint.end(); ++i)
			{
				entities::PowerupSpawnPoint *e = *i;

				if(trm_isSelected(e))
				{
					if(config_get_int(c_noModify))
					{
						trm_modifyAttempted();
						return;
					}

					modified = true;

					e->x += x_end - x_last_scroll;
					e->y += y_end - y_last_scroll;
				}
			}
			for(vector<entities::Teleporter *>::iterator i = teleporter.begin(); i != teleporter.end(); ++i)
			{
				entities::Teleporter *e = *i;

				if(trm_isSelected(e))
				{
					if(config_get_int(c_noModify))
					{
						trm_modifyAttempted();
						return;
					}

					modified = true;

					e->x += x_end - x_last_scroll;
					e->y += y_end - y_last_scroll;
				}
			}
			for(vector<entities::Wall *>::iterator i = wall.begin(); i != wall.end(); ++i)
			{
				entities::Wall *e = *i;

				if(trm_isSelected(e))
				{
					if(config_get_int(c_noModify))
					{
						trm_modifyAttempted();
						return;
					}

					modified = true;

					e->x1 += x_end - x_last_scroll;
					e->y1 += y_end - y_last_scroll;
					e->x2 += x_end - x_last_scroll;
					e->y2 += y_end - y_last_scroll;
					e->x3 += x_end - x_last_scroll;
					e->y3 += y_end - y_last_scroll;
					e->x4 += x_end - x_last_scroll;
					e->y4 += y_end - y_last_scroll;
				}
			}
		}
	}
}

static void drawCircle(double radius, double c = 0.25, double e = 360.0, double s = 0.0)
{
	glBegin(GL_LINE_LOOP);
		for(double i = s; i < e; i += c)
		{
			glVertex2d(cos(UTIL_RAD(i) * radius), sin(sin(UTIL_RAD(i)) * radius));
		}
	glEnd();
}

static void drawPlayerSpawnPoints(void)
{
	for(vector<entities::PlayerSpawnPoint *>::iterator i = playerSpawnPoint.begin(); i != playerSpawnPoint.end(); ++i)
	{
		entities::PlayerSpawnPoint *e = *i;
		glPushMatrix();
			glPushAttrib(GL_POLYGON_BIT | GL_CURRENT_BIT);
				glTranslated(e->x, e->y, 0.0);
				if(glIsList(entBase + e_selectionPlayerSpawnPoint))
					glCallList(entBase + e_selectionPlayerSpawnPoint);
				if(e == reinterpret_cast<void *>(selection))
				{
					glScaled(1.1 / ZOOM, 1.1 / ZOOM, 1.0);
					glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
					glColor4d(1.0, 0.0, 0.0, 1.0);
					if(glIsList(entBase + e_selectionPlayerSpawnPoint))
						glCallList(entBase + e_selectionPlayerSpawnPoint);
				}
			glPopAttrib();
		glPopMatrix();
	}
}

static void drawPowerupSpawnPoints(void)
{
	for(vector<entities::PowerupSpawnPoint *>::iterator i = powerupSpawnPoint.begin(); i != powerupSpawnPoint.end(); ++i)
	{
		entities::PowerupSpawnPoint *e = *i;
		glPushMatrix();
			glPushAttrib(GL_POLYGON_BIT | GL_CURRENT_BIT);
				glTranslated(e->x, e->y, 0.0);
				if(glIsList(entBase + e_selectionPowerupSpawnPoint))
					glCallList(entBase + e_selectionPowerupSpawnPoint);
				if(e == reinterpret_cast<void *>(selection))
				{
					glScaled(1.1 / ZOOM, 1.1 / ZOOM, 1.0);
					glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
					glColor4d(1.0, 0.0, 0.0, 1.0);
					if(glIsList(entBase + e_selectionPowerupSpawnPoint))
						glCallList(entBase + e_selectionPowerupSpawnPoint);
				}
			glPopAttrib();
		glPopMatrix();
	}
}

static void drawTeleporters(void)
{
	for(vector<entities::Teleporter *>::iterator i = teleporter.begin(); i != teleporter.end(); ++i)
	{
		entities::Teleporter *e = *i;
		glPushMatrix();
			glPushAttrib(GL_POLYGON_BIT | GL_CURRENT_BIT);
				glTranslated(e->x, e->y, 0.0);
				if(glIsList(entBase + e_selectionTeleporter))
					glCallList(entBase + e_selectionTeleporter);
				if(e == reinterpret_cast<void *>(selection))
				{
					glScaled(1.1 / ZOOM, 1.1 / ZOOM, 1.0);
					glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
					glColor4d(1.0, 0.0, 0.0, 1.0);
					if(glIsList(entBase + e_selectionTeleporter))
						glCallList(entBase + e_selectionTeleporter);
				}
			glPopAttrib();
		glPopMatrix();
	}
}

static void drawWalls(void)
{
	for(vector<entities::Wall *>::iterator i = wall.begin(); i != wall.end(); ++i)
	{
		entities::Wall *e = *i;
		glPushAttrib(GL_POLYGON_BIT | GL_CURRENT_BIT);
			glPushMatrix();
				double ax, ay;
				ax = ((!e->quad) ? ((e->x1 + e->x2 + e->x3) / 3) : ((e->x1 + e->x2 + e->x3 + e->x4) / 4));
				ay = ((!e->quad) ? ((e->y1 + e->y2 + e->y3) / 3) : ((e->y1 + e->y2 + e->y3 + e->y4) / 4));
				glTranslated(ax, ay, 0.0);
				if(e == reinterpret_cast<void *>(selection))
				{
					glScaled(1.1 / ZOOM, 1.1 / ZOOM, 1.0);
					glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
					glColor4d(1.0, 0.0, 0.0, 1.0);  // red
					if(!e->quad)
					{
						glBegin(GL_TRIANGLES);
							glVertex2d(ax - e->x1, ay - e->y1);
							glVertex2d(ax - e->x2, ay - e->y2);
							glVertex2d(ax - e->x3, ay - e->y3);
						glEnd();
					}
					else
					{
						glBegin(GL_QUADS);
							glVertex2d(ax - e->x1, ay - e->y1);
							glVertex2d(ax - e->x2, ay - e->y2);
							glVertex2d(ax - e->x3, ay - e->y3);
							glVertex2d(ax - e->x4, ay - e->y4);
						glEnd();
					}
					// -
					if(ctrl && shift)
					{
						glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
						glColor4d(1.0, 0.5, 0.0, 1.0);
						glPushMatrix();
							glTranslated(ax - e->x1, ay - e->y1, 0.0);
							drawCircle(3.0 / zoom);
						glPopMatrix();
						glPushMatrix();
							glTranslated(ax - e->x2, ay - e->y2, 0.0);
							drawCircle(3.0 / zoom);
						glPopMatrix();
						glPushMatrix();
							glTranslated(ax - e->x1, ay - e->y3, 0.0);
							drawCircle(3.0 / zoom);
						glPopMatrix();
						if(!e->quad)
						{
							glPushMatrix();
								glTranslated(ax - e->x4, ay - e->y4, 0.0);
								drawCircle(3.0 / zoom);
							glPopMatrix();
						}
					}
				}
				else
				{
					glColor4d(1.0, 0.0, 0.0, 1.0);
					if(!e->quad)
					{
						glBegin(GL_TRIANGLES);
							glVertex2d(ax - e->x1, ay - e->y1);
							glVertex2d(ax - e->x2, ay - e->y2);
							glVertex2d(ax - e->x3, ay - e->y3);
						glEnd();
					}
					else
					{
						glBegin(GL_QUADS);
							glVertex2d(ax - e->x1, ay - e->y1);
							glVertex2d(ax - e->x2, ay - e->y2);
							glVertex2d(ax - e->x3, ay - e->y3);
							glVertex2d(ax - e->x4, ay - e->y4);
						glEnd();
					}
				}
			glPopMatrix();
		glPopAttrib();
	}
}

static void drawEntity(int e)
{
	#define TANKBOBSEDITOR_DRAWENTITY_ERROR(e) \
	{ \
		extern Tankbobs_editor *window; \
		QMessageBox::critical(window, "Rendering error", "Unknown entity type to draw " + QString::number(e) + "."); \
		fprintf(stderr, "Unknown entity type to draw: %d\n", e); \
	}
	if     (e == 0)
		drawPlayerSpawnPoints();
	else if(e == 1)
		drawPowerupSpawnPoints();
	else if(e == 2)
		drawTeleporters();
	else if(e == 3)
		drawWalls();
	else
		TANKBOBSEDITOR_DRAWENTITY_ERROR(e);
}

const int entityInts[] = {0, 1, 2, 3};

typedef struct
{
	void (*l0)(int);
	const int *l1;
	int l2;
} editorPaintGLCache_t;

static editorPaintGLCache_t editorPaintGLCache;

void Editor::initializeGL()
{
	// update cache
	editorPaintGLCache.l0 = drawEntity;
	editorPaintGLCache.l1 = entityInts;
	editorPaintGLCache.l2 = UTIL_ARRAYELEMENTS(entityInts);

	// initialize gl
	glCullFace(GL_BACK);
	glClearColor(0.0, 0.0, 0.1, 0.0);
	resizeGL(width(), height());
	glColor4d(1.0, 1.0, 1.0, 1.0);

	// initialize grid
	if(!(gridBase = glGenLists(1)))
	{
		QMessageBox::critical(this, "OpenGL error", "No room for display lists.");
		fprintf(stderr, "No room for display lists.\n");
		this->exit();
	}

	glNewList(gridBase, GL_COMPILE);
		glPushAttrib(GL_CURRENT_BIT);
			for(float v = -GRIDSIZE * GRIDLINES; v < GRIDSIZE * GRIDLINES + GRIDSIZE * SMALL; v += GRIDSIZE)
			{
				glColor4d(0.05, 0.5, 0.1, 1.0);
				glBegin(GL_LINES);
					glVertex2d(v, -GRIDSIZE * GRIDLINES);
					glVertex2d(v, +GRIDSIZE * GRIDLINES);
				glEnd();
			}
			for(float h = -GRIDSIZE * GRIDLINES; h < GRIDSIZE * GRIDLINES + GRIDSIZE * SMALL; h += GRIDSIZE)
			{
				glColor4d(0.05, 0.5, 0.1, 1.0);
				glBegin(GL_LINES);
					glVertex2d(-GRIDSIZE * GRIDLINES, h);
					glVertex2d(+GRIDSIZE * GRIDLINES, h);
				glEnd();
			}
			glColor4d(0.1, 1.0, 0.2, 1.0);
			glBegin(GL_LINE_LOOP);
				glVertex2d(0.0, 0.0);
				glVertex2d(GRIDSIZE, 0.0);
				glVertex2d(GRIDSIZE, GRIDSIZE);
				glVertex2d(0.0, GRIDSIZE);
			glEnd();
		glPopAttrib();
	glEndList();

	// intialize entities
	if(!(entBase = glGenLists(e_numSelection)))
	{
		QMessageBox::critical(this, "OpenGL error", "No room for display lists.");
		fprintf(stderr, "No room for display lists.\n");
		this->exit();
	}

	glNewList(entBase + e_selectionPlayerSpawnPoint, GL_COMPILE);
		glPushAttrib(GL_CURRENT_BIT);
			glColor4d(1.0, 1.0, 0.0, 1.0);
			glBegin(GL_QUADS);
				glVertex2d(-PLAYERSPAWNPOINT_WIDTH * 0.5, +PLAYERSPAWNPOINT_HEIGHT * 0.5);
				glVertex2d(-PLAYERSPAWNPOINT_WIDTH * 0.5, -PLAYERSPAWNPOINT_HEIGHT * 0.5);
				glVertex2d(+PLAYERSPAWNPOINT_WIDTH * 0.5, -PLAYERSPAWNPOINT_HEIGHT * 0.5);
				glVertex2d(+PLAYERSPAWNPOINT_WIDTH * 0.5, +PLAYERSPAWNPOINT_HEIGHT * 0.5);
			glEnd();
		glPopAttrib();
	glEndList();

	glNewList(entBase + e_selectionPowerupSpawnPoint, GL_COMPILE);
		glPushAttrib(GL_CURRENT_BIT);
			glColor4d(0.0, 0.0, 1.0, 1.0);
			glBegin(GL_QUADS);
				glVertex2d(-POWERUPSPAWNPOINT_WIDTH * 0.5, +POWERUPSPAWNPOINT_HEIGHT * 0.5);
				glVertex2d(-POWERUPSPAWNPOINT_WIDTH * 0.5, -POWERUPSPAWNPOINT_HEIGHT * 0.5);
				glVertex2d(+POWERUPSPAWNPOINT_WIDTH * 0.5, -POWERUPSPAWNPOINT_HEIGHT * 0.5);
				glVertex2d(+POWERUPSPAWNPOINT_WIDTH * 0.5, +POWERUPSPAWNPOINT_HEIGHT * 0.5);
			glEnd();
		glPopAttrib();
	glEndList();

	glNewList(entBase + e_selectionTeleporter, GL_COMPILE);
		glPushAttrib(GL_CURRENT_BIT);
			glColor4d(0.0, 1.0, 0.0, 1.0);
			glBegin(GL_QUADS);
				glVertex2d(-TELEPORTER_WIDTH * 0.5, +TELEPORTER_HEIGHT * 0.5);
				glVertex2d(-TELEPORTER_WIDTH * 0.5, -TELEPORTER_HEIGHT * 0.5);
				glVertex2d(+TELEPORTER_WIDTH * 0.5, -TELEPORTER_HEIGHT * 0.5);
				glVertex2d(+TELEPORTER_WIDTH * 0.5, +TELEPORTER_HEIGHT * 0.5);
			glEnd();
		glPopAttrib();
	glEndList();
}

void Editor::paintGL()
{
	TE_GLB;
	glScaled(zoom, zoom, 1.0);
	glTranslated(x_scroll, y_scroll, 0.0);

	// handle key press events
	if(keyPressLast)
	{
		switch(keyPressLast)
		{
			default:
				break;
		}
		keyPressLast = 0;
	}

	if(keyReleaseLast)
	{
		switch(keyReleaseLast)
		{
			default:
				break;
		}
		keyReleaseLast = 0;
	}

	// draw all entities
	util_fpermutation(editorPaintGLCache.l0, editorPaintGLCache.l1, editorPaintGLCache.l2, order++);

	// draw grid to aid scrolling
	glCallList(gridBase);

	// draw a wall ghost
	if(!shift && !ctrl)
	{
		if(x_begin >= 0 && y_begin >= 0 && selectionType == e_selectionWall)
		{
			glPushAttrib(GL_POLYGON_BIT | GL_CURRENT_BIT);
				glColor4d(0.425, 0.4, 0.45, 1.0);
				glCullFace(GL_FRONT_AND_BACK);
				glPushMatrix();
					glBegin(GL_QUADS);
						glVertex2d(x_begin - x_scroll, y_begin - y_scroll);
						glVertex2d(x_begin - x_scroll, y_end   - y_scroll);
						glVertex2d(x_end   - x_scroll, y_end   - y_scroll);
						glVertex2d(x_end   - x_scroll, y_begin - y_scroll);
					glEnd();
				glPopMatrix();
			glPopAttrib();
		}
		// or another type of ghost
		if(x_begin >= 0 && y_begin >= 0 && selectionType == e_selectionPlayerSpawnPoint)
		{
			glPushAttrib(GL_POLYGON_BIT | GL_CURRENT_BIT);
				glColor4d(1.0 * 0.225, 1.0 * 0.2, 0.0 * 0.25, 1.0);
				glCullFace(GL_FRONT_AND_BACK);
				glPushMatrix();
					glTranslated(x_end - x_scroll, y_end - y_scroll, 0.0);
					glBegin(GL_QUADS);
						glVertex2d(-PLAYERSPAWNPOINT_WIDTH * 0.5, +PLAYERSPAWNPOINT_HEIGHT * 0.5);
						glVertex2d(-PLAYERSPAWNPOINT_WIDTH * 0.5, -PLAYERSPAWNPOINT_HEIGHT * 0.5);
						glVertex2d(+PLAYERSPAWNPOINT_WIDTH * 0.5, -PLAYERSPAWNPOINT_HEIGHT * 0.5);
						glVertex2d(+PLAYERSPAWNPOINT_WIDTH * 0.5, +PLAYERSPAWNPOINT_HEIGHT * 0.5);
					glEnd();
				glPopMatrix();
			glPopAttrib();
		}
		if(x_begin >= 0 && y_begin >= 0 && selectionType == e_selectionPowerupSpawnPoint)
		{
			glPushAttrib(GL_POLYGON_BIT | GL_CURRENT_BIT);
				glColor4d(0.0 * 0.225, 0.0 * 0.2, 1.0 * 0.25, 1.0);
				glCullFace(GL_FRONT_AND_BACK);
				glPushMatrix();
					glTranslated(x_end - x_scroll, y_end - y_scroll, 0.0);
					glBegin(GL_QUADS);
						glVertex2d(-POWERUPSPAWNPOINT_WIDTH * 0.5, +POWERUPSPAWNPOINT_HEIGHT * 0.5);
						glVertex2d(-POWERUPSPAWNPOINT_WIDTH * 0.5, -POWERUPSPAWNPOINT_HEIGHT * 0.5);
						glVertex2d(+POWERUPSPAWNPOINT_WIDTH * 0.5, -POWERUPSPAWNPOINT_HEIGHT * 0.5);
						glVertex2d(+POWERUPSPAWNPOINT_WIDTH * 0.5, +POWERUPSPAWNPOINT_HEIGHT * 0.5);
					glEnd();
				glPopMatrix();
			glPopAttrib();
		}
		if(x_begin >= 0 && y_begin >= 0 && selectionType == e_selectionTeleporter)
		{
			glPushAttrib(GL_POLYGON_BIT | GL_CURRENT_BIT);
				glColor4d(0.0 * 0.225, 1.0 * 0.2, 0.0 * 0.25, 1.0);
				glCullFace(GL_FRONT_AND_BACK);
				glPushMatrix();
					glTranslated(x_end - x_scroll, y_end - y_scroll, 0.0);
					glBegin(GL_QUADS);
						glVertex2d(-TELEPORTER_WIDTH * 0.5, +TELEPORTER_HEIGHT * 0.5);
						glVertex2d(-TELEPORTER_WIDTH * 0.5, -TELEPORTER_HEIGHT * 0.5);
						glVertex2d(+TELEPORTER_WIDTH * 0.5, -TELEPORTER_HEIGHT * 0.5);
						glVertex2d(+TELEPORTER_WIDTH * 0.5, +TELEPORTER_HEIGHT * 0.5);
					glEnd();
				glPopMatrix();
			glPopAttrib();
		}
	}
	TE_GLE;
}

void Texture::initializeGL()
{
	glCullFace(GL_BACK);
	glClearColor(0.0, 0.0, 0.1, 0.0);
	resizeGL(width(), height());
}

void Texture::resizeGL(int w, int h)
{
	glViewport(0.0, 0.0, (GLint)w, (GLint)h);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(0.0, 1.0, 0.0, 1.0, -1.0, 1.0);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}

void Texture::paintGL()
{
	TE_GLB;
	glBegin(GL_TRIANGLES);
		glVertex3d(25.0, 25.0, 0.0);
		glVertex3d(75.0, 25.0, 0.0);
		glVertex3d(25.0, 75.0, 0.0);
	glEnd();
	TE_GLE;
}
