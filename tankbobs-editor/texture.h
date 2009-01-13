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
