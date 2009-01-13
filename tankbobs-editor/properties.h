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
		void mapidChanged(const QString &text);
		void mapnameChanged(const QString &text);
		void maptitleChanged(const QString &text);
		void mapdescriptionChanged(const QString &text);
		void mapauthorsChanged(const QString &text);
		void mapversionChanged(const QString &text);
		void mapinitscriptChanged(const QString &text);
		void mapexitscriptChanged(const QString &text);
		void setidChanged(const QString &text);
		void setorderChanged(const QString &text);
		void setnameChanged(const QString &text);
		void settitleChanged(const QString &text);
		void setdescriptionChanged(const QString &text);
		void setauthorsChanged(const QString &text);
		void setversionChanged(const QString &text);
		void textureChanged(const QString &text);
		void script1Changed(const QString &text);
		void script2Changed(const QString &text);
		void script3Changed(const QString &text);
		void groupChanged(const QString &text);
		void activeChanged(const QString &text);
		void powerupsChanged(const QString &text);
		void enableChanged(const QString &text);
		void fourVerticesChanged(int state);
		void detailChanged(int state);
		void structuralChanged(int state);
		void backmostChanged(int state);
		void backChanged(int state);
		void backleastChanged(int state);
		void topleastChanged(int state);
		void topChanged(int state);
		void topmostChanged(int state);
		void backmostmoreChanged(int state);
		void backmostmostChanged(int state);
		void missilesChanged(int state);
		void nopassChanged(int state);
		void damageChanged(int state);
		void touchChanged(int state);
		void autoselectChanged(int state);
		void nomodifyChanged(int state);
		void autonotextureChanged(int state);
};

#endif
