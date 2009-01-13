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
		void mouseMoveEvent(QMoveEvent *e);
		void initializeGL(void);
		void resizeGL(int w, int h);
		void paintGL(void);

	private:
		QTimer QTa;
		int mx(int);
		int my(int);
};

#endif
