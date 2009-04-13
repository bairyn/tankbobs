#include <QApplication>
#include "tankbobs-editor.h"
#include "config.h"

Tankbobs_editor *window = NULL;

int main(int argc, char **argv)
{
	QApplication app(argc, argv);
	int result = config_args(argc, argv);
	if(!result)
		return result;
	Q_INIT_RESOURCE(res);
	window = new Tankbobs_editor;
	window->show();
	result = app.exec();
	Q_CLEANUP_RESOURCE(res);
	return result;
}
