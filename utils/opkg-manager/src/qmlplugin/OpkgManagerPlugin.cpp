#include <QQmlEngine>

#include "OpkgManagerPlugin.h"
//#include <QQmlEngine>
#include "ProcessRunner.h"
#include <qqml.h>

//void OpkgManagerPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
//{
//	engine->addImportPath("/opt/victronenergy/gui/qml/");
//	qDebug() << "QML import paths:" << engine->importPathList();
//}

void OpkgManagerPlugin::registerTypes(const char *uri) {
	qmlRegisterType<ProcessRunner>(uri, 0, 0, "ProcessRunner");
	qmlRegisterType<ProcessRunner>(uri, 1, 0, "ProcessRunner");
	qmlRegisterSingletonType<FileHelper>(uri, 1, 0, "FileHelper",
		[](QQmlEngine *, QJSEngine *) -> QObject * {
			return new FileHelper();
		});
 
}
