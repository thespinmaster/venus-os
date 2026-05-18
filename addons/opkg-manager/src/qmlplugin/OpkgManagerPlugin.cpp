#include <QQmlEngine>

#include "OpkgManagerPlugin.h"
//#include <QQmlEngine>
#include "OpkgBridge.h"
#include <qqml.h>

//void OpkgManagerPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
//{
//	engine->addImportPath("/opt/victronenergy/gui/qml/");
//	qDebug() << "QML import paths:" << engine->importPathList();
//}

void OpkgManagerPlugin::registerTypes(const char *uri) {
	qmlRegisterType<OpkgBridge>(uri, 0, 0, "OpkgBridge");
	qmlRegisterType<OpkgBridge>(uri, 1, 0, "OpkgBridge");
	qmlRegisterSingletonType<FileHelper>(uri, 1, 0, "FileHelper",
		[](QQmlEngine *, QJSEngine *) -> QObject * {
			return new FileHelper();
		});
 
}
