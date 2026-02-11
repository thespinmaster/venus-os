#include "OpkgManagerPlugin.h"

#include "ProcessRunner.h"

#include <qqml.h>

void OpkgManagerPlugin::registerTypes(const char *uri)
{
	qmlRegisterType<ProcessRunner>(uri, 0, 0, "ProcessRunner");
	qmlRegisterType<ProcessRunner>(uri, 1, 0, "ProcessRunner");
	qmlRegisterSingletonType<FileHelper>(uri, 1, 0, "FileHelper",
		[](QQmlEngine *, QJSEngine *) -> QObject * {
			return new FileHelper();
		});
}
