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
		void open();
		void save();
		void saveAs();
		void exit();
		void openTextureDirectory();
		void statusClear();

	protected:
		virtual void keyPressEvent(QKeyEvent *e);
		virtual void keyReleaseEvent(QKeyEvent *e);

	private:
		QTimer QTa;
};

#endif
