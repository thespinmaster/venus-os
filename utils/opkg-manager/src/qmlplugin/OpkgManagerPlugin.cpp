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

	// Register QML files as types
  /*
	qmlRegisterType(QUrl("qrc:/OpkgManager/resources/OpkgEditBoxLargeText.qml"), uri, 1, 0, "OpkgEditBoxLargeText");
	qmlRegisterType(QUrl("qrc:/OpkgManager/resources/OpkgHeaderDescriptionItem.qml"), uri, 1, 0, "OpkgHeaderDescriptionItem");
	qmlRegisterType(QUrl("qrc:/OpkgManager/resources/OpkgObjectCustomOverviewPages.qml"), uri, 1, 0, "OpkgObjectCustomOverviewPages");
	qmlRegisterType(QUrl("qrc:/OpkgManager/resources/OpkgPageSettingsCustomMenus.qml"), uri, 1, 0, "OpkgPageSettingsCustomMenus");
	qmlRegisterType(QUrl("qrc:/OpkgManager/resources/OpkgPageSettingsSubMenu.qml"), uri, 1, 0, "OpkgPageSettingsSubMenu");
	qmlRegisterType(QUrl("qrc:/OpkgManager/resources/OpkgPageSettings.qml"), uri, 1, 0, "OpkgPageSettings");
	qmlRegisterType(QUrl("qrc:/OpkgManager/resources/PageSettingsOpkgFeeds.qml"), uri, 1, 0, "PageSettingsOpkgFeeds");
	qmlRegisterType(QUrl("qrc:/OpkgManager/resources/PageSettingsOpkgPackageInstall.qml"), uri, 1, 0, "PageSettingsOpkgPackageInstall");
	qmlRegisterType(QUrl("qrc:/OpkgManager/resources/PageSettingsOpkgPackages.qml"), uri, 1, 0, "PageSettingsOpkgPackages");
	*/

	qmlRegisterType(QUrl("file:/opt/victronenergy/gui/qml/OpkgEditBoxLargeText.qml"), "", 1, 0, "OpkgEditBoxLargeText");
	qmlRegisterType(QUrl("file:/opt/victronenergy/gui/qml/OpkgHeaderDescriptionItem.qml"), "", 1, 0, "OpkgHeaderDescriptionItem");
	qmlRegisterType(QUrl("file:/opt/victronenergy/gui/qml/OpkgObjectCustomOverviewPages.qml"), "", 1, 0, "OpkgObjectCustomOverviewPages");
	qmlRegisterType(QUrl("file:/opt/victronenergy/gui/qml/OpkgPageSettingsCustomMenus.qml"), "", 1, 0, "OpkgPageSettingsCustomMenus");
	qmlRegisterType(QUrl("file:/opt/victronenergy/gui/qml/OpkgPageSettingsSubMenu.qml"), "", 1, 0, "OpkgPageSettingsSubMenu");
	qmlRegisterType(QUrl("file:/opt/victronenergy/gui/qml/OpkgPageSettings.qml"), "", 1, 0, "OpkgPageSettings");
	qmlRegisterType(QUrl("file:/opt/victronenergy/gui/qml/PageSettingsOpkgFeeds.qml"), "", 1, 0, "PageSettingsOpkgFeeds");
	qmlRegisterType(QUrl("file:/opt/victronenergy/gui/qml//PageSettingsOpkgPackageInstall.qml"), "", 1, 0, "PageSettingsOpkgPackageInstall");
	qmlRegisterType(QUrl("file:/opt/victronenergy/gui/qml/PageSettingsOpkgPackages.qml"), "", 1, 0, "PageSettingsOpkgPackages");
}
