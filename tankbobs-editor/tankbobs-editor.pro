######################################################################
# Automatically generated by qmake (2.01a) Fri Nov 14 17:06:49 2008
######################################################################

DESTDIR = build
TEMPLATE = app
TARGET = 
DEPENDPATH += .
INCLUDEPATH += . /usr/include/

# Input
HEADERS += config.h editor.h entities.h properties.h tankbobs-editor.h texture.h trm.h util.h
FORMS += tankbobs-editor.ui properties.ui
SOURCES += config.cpp main.cpp properties.cpp tankbobs-editor.cpp trm.cpp util.cpp
RESOURCES += res.qrc

CONFIG += qt debug
QT += opengl
