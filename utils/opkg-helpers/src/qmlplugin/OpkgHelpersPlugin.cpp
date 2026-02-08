#include "OpkgHelpersPlugin.h"

#include "ProcessRunner.h"

#include <qqml.h>

void OpkgHelpersPlugin::registerTypes(const char *uri)
{
	qmlRegisterType<ProcessRunner>(uri, 0, 0, "ProcessRunner");
	qmlRegisterType<ProcessRunner>(uri, 1, 0, "ProcessRunner");
}
