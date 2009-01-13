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

char order = 0;

static int entBase = 0;
QString file = "";
extern void *selection;
extern int selectionType;
static int x_begin = -1, y_begin = -1, x_end, y_end;

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

void Tankbobs_editor::open()
{
	topen();
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
}

void Tankbobs_editor::topen(void)
{
	extern Tankbobs_editor *window;
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
		if(!trm_open(f))
		{
			free(f);
			QMessageBox::critical(window, "FS error", "Could not open file.");
			fprintf(stderr, "Could not open file.\n");
		}
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
	glOrtho(0.0, 100.0, 0.0, 100.0, -1.0, 1.0);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}

int Editor::mx(int x)
{
	return static_cast<int>(100.0 * static_cast<double>(x) / static_cast<double>(width()));
}

int Editor::my(int y)
{
	return 100 - static_cast<int>(100.0 * static_cast<double>(y) / static_cast<double>(height()));
}

void Editor::mousePressEvent(QMouseEvent *e)
{
	x_begin = mx(e->x());
	y_begin = my(e->y());
}

void Editor::mouseReleaseEvent(QMouseEvent *e)
{
	x_end = mx(e->x());
	y_end = my(e->y());

	switch(selectionType)
	{
		case e_selectionNone:
			trm_select(x_end, y_end);
			break;

		case e_selectionWall:
			trm_newWall(x_begin, y_begin, x_end, y_end);
			break;

		case e_selectionPlayerSpawnPoint:
			trm_newPlayerSpawnPoint(x_end, y_end);
			break;

		case e_selectionPowerupSpawnPoint:
			trm_newPowerupSpawnPoint(x_end, y_end);
			break;

		case e_selectionTeleporter:
			trm_newTeleporter(x_end, y_end);
			break;

		default:
			QMessageBox::critical(this, "Entity type selection error", "The selected entity type was not recognized.");
			fprintf(stderr, "The selected entity type was not recognized.\n");
			this->exit();
			break;
	}

	x_begin = -1;
	y_begin = -1;

	if(config_get_int(c_autoSelect))
		selectionType = e_selectionNone;
}

void Tankbobs_editor::keyPressEvent(QKeyEvent *e)
{
	trm_keypress(e->key(), !e->isAutoRepeat());
}

void Tankbobs_editor::keyReleaseEvent(QKeyEvent *e)
{
	trm_keyrelease(e->key());
}

void Editor::mouseMoveEvent(QMoveEvent *e)
{
	x_end = mx(e->pos().x());
	y_end = my(e->pos().y());
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
					glScaled(1.1, 1.1, 1.0);
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
					glScaled(1.1, 1.1, 1.0);
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
					glScaled(1.1, 1.1, 1.0);
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
				ax = ((e->x4 == NOVALUEDOUBLE || e->y4 == NOVALUEDOUBLE) ? ((e->x1 + e->x2 + e->x3) / 3) : ((e->x1 + e->x2 + e->x3 + e->x4) / 4));
				ay = ((e->x4 == NOVALUEDOUBLE || e->y4 == NOVALUEDOUBLE) ? ((e->y1 + e->y2 + e->y3) / 3) : ((e->y1 + e->y2 + e->y3 + e->y4) / 4));
				glTranslated(ax, ay, 0.0);
				if(e->x4 == NOVALUEDOUBLE || e->y4 == NOVALUEDOUBLE)
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
				if(e == reinterpret_cast<void *>(selection))
				{
					glScaled(1.1, 1.1, 1.0);
					glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
					glColor4d(1.0, 0.0, 0.0, 1.0);
					if(e->x4 == NOVALUEDOUBLE || e->y4 == NOVALUEDOUBLE)
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
	util_fpermutation(editorPaintGLCache.l0, editorPaintGLCache.l1, editorPaintGLCache.l2, order++);
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





/*


void Tankbobs_editor::doSomething()
{
    int value1, value2;
    Qt::CheckState state;
    QString str;

    textEdit->append( "Path to file: " + lineEdit->text() );

    value1 = spinBox1->value();
    value2 = spinBox2->value();

    textEdit->append( "Number 1 value: " + QString::number(value1) );
    textEdit->append( "Number 2 value: " + QString::number(value2) );

    state = checkBox->checkState();

    str = "Checkbox says: ";
    if ( state == Qt::Checked ) str += "yes";
    else str += "no";
    textEdit->append( str );

    textEdit->append( "ComboBox current text: " + comboBox->currentText() );
    textEdit->append( "ComboBox current item: " + QString::number(comboBox->currentIndex()) );
}





void Tankbobs_editor::about()
{
    QMessageBox::about(this,"About myQtApp",
                "This app was coded for educational purposes.\n"
                "Number 1 is: " + QString::number(spinBox1->value()) + "\n\n"
                "Bye.\n");
}


*/
