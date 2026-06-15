#include "OpkgBridge.h"

#include <QByteArray>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QHash>
#include <QStandardPaths>

#include <QProcess>

// #define TRACE

#include <exception>

#ifdef Q_OS_UNIX
#include <dlfcn.h>
#include <signal.h>
#endif

namespace {

struct ActionSpec {
	QString helperPath;
	QStringList prefixArgs;
};

struct FamilySpec {
	QString defaultHelperPath;
	QHash<QString, ActionSpec> actions;
};

QString runnerPath(const QString &scriptName);



static QString loadedPluginPath()
{
#ifdef Q_OS_UNIX
	Dl_info info = {};
	if (dladdr(reinterpret_cast<const void *>(&loadedPluginPath), &info) != 0 && info.dli_fname) {
		const QString rawPath = QDir::cleanPath(QString::fromLocal8Bit(info.dli_fname));
		const QString canonicalPath = QFileInfo(rawPath).canonicalFilePath();
		return canonicalPath.isEmpty() ? rawPath : canonicalPath;
	}
#endif
	return QString();
}

static QString detectRunnerRoot()
{
	const QString runnerBridgeSubpath = QStringLiteral("/data/opkg-manager/opkg-bridge");
	const QString pluginDirToRoot = QStringLiteral("../../../../../");

	const QString deployed = runnerBridgeSubpath;
	const QString pluginPath = loadedPluginPath();

	if (!pluginPath.isEmpty()) {
		const QString pluginDir = QFileInfo(pluginPath).absolutePath();
		const QString relativeDerivedRoot = 
			QDir(pluginDir).absoluteFilePath(pluginDirToRoot + runnerBridgeSubpath);
		const QString derivedRoot = QDir::cleanPath(relativeDerivedRoot);
		const QString canonicalDerivedRoot = QFileInfo(derivedRoot).canonicalFilePath();
		const QString candidate = canonicalDerivedRoot.isEmpty() ? derivedRoot : canonicalDerivedRoot;

		if (QFileInfo::exists(candidate)) {
			qWarning() << "[OpkgBridge] detectRunnerRoot: using plugin-derived path:" << candidate;
			return candidate;
		}

		qWarning() << "[OpkgBridge] detectRunnerRoot: plugin-derived path does not exist:"
				   << candidate << "- falling back to default:" << deployed;
	} else {
		qWarning() << "[OpkgBridge] detectRunnerRoot: unable to resolve plugin path, falling back to default:"
			   << deployed;
	}

	if (QFileInfo::exists(deployed)) {
		qWarning() << "[OpkgBridge] detectRunnerRoot: using deployed path:" << deployed;
		return deployed;
	}

	qWarning() << "[OpkgBridge] detectRunnerRoot: default path missing, returning:" << deployed;
	return deployed;
}

QString runnerPath(const QString &scriptName)
{
	static const QString root = detectRunnerRoot();
	return QDir(root).filePath(scriptName);
}

const QHash<QString, FamilySpec> &commandRegistry()
{
	static const QHash<QString, FamilySpec> registry = []() {
		QHash<QString, FamilySpec> map;

		FamilySpec device;
		device.defaultHelperPath = runnerPath(QStringLiteral("device"));
		device.actions.insert(QStringLiteral("detect"), ActionSpec {});
		device.actions.insert(QStringLiteral("apply"), ActionSpec {});
		device.actions.insert(QStringLiteral("remove"), ActionSpec {});
		map.insert(QStringLiteral("device"), device);

		FamilySpec feed;
		feed.defaultHelperPath = runnerPath(QStringLiteral("feed"));
		feed.actions.insert(QStringLiteral("list"),
					ActionSpec { runnerPath(QStringLiteral("json_helper")),
						QStringList() << QStringLiteral("feed") });
		feed.actions.insert(QStringLiteral("add"), ActionSpec {});
		feed.actions.insert(QStringLiteral("edit"), ActionSpec {});
		feed.actions.insert(QStringLiteral("remove"), ActionSpec {});
		feed.actions.insert(QStringLiteral("set"), ActionSpec {});
		feed.actions.insert(QStringLiteral("type"), ActionSpec {});
		map.insert(QStringLiteral("feed"), feed);

		FamilySpec package;
		package.defaultHelperPath = runnerPath(QStringLiteral("package"));
		package.actions.insert(QStringLiteral("list"),
					  ActionSpec { runnerPath(QStringLiteral("json_helper")),
						  QStringList() << QStringLiteral("package") });
		package.actions.insert(QStringLiteral("install"), ActionSpec {});
		package.actions.insert(QStringLiteral("remove"), ActionSpec {});
		package.actions.insert(QStringLiteral("upgrade"), ActionSpec {});
		map.insert(QStringLiteral("package"), package);

		return map;
	}();

	return registry;
}

} // namespace


OpkgBridge::OpkgBridge(QObject *parent)
	: QObject(parent)
	, m_operationName("")
	, m_stopping(false)
{
    m_process.setProcessChannelMode(QProcess::SeparateChannels);

    connect(&m_process, &QProcess::readyReadStandardOutput, this, &OpkgBridge::handleStdout);
    connect(&m_process, &QProcess::readyReadStandardError, this, &OpkgBridge::handleStderr);
    connect(&m_process,
	    QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
	    this,
	    &OpkgBridge::handleFinished);
    connect(&m_process, QOverload<QProcess::ProcessError>::of(&QProcess::errorOccurred),
	    this, &OpkgBridge::handleError);
}
bool OpkgBridge::stopping() const
{
	return m_stopping;
}
QString OpkgBridge::operationName() const
{
	return m_operationName;
}

void OpkgBridge::setOperationName(const QString &name)
{
	if (m_operationName == name)
		return;
	m_operationName = name;
	emit operationNameChanged();
}

bool OpkgBridge::traceEnabled() const
{
	return m_traceEnabled;
}

void OpkgBridge::setTraceEnabled(bool enabled)
{
	if (m_traceEnabled == enabled)
		return;
	m_traceEnabled = enabled;
	emit traceEnabledChanged();
}

bool OpkgBridge::running() const
{
	return m_process.state() != QProcess::NotRunning;
}

bool OpkgBridge::waitForFinished(int msecs)
{
	if (!running()) {
		return true;
	}
	return m_process.waitForFinished(msecs);
}

void OpkgBridge::start(const QStringList &args)
{
	if (m_stopping)
		return;
	if (running()) {
		return;
	}

	m_stdoutBuffer.clear();
	m_stderrBuffer.clear();
	QString helperPath;
	QStringList helperArgs;
	QString publicOperation;
	QString error;

	if (!resolveCommand(args, helperPath, helperArgs, publicOperation, error)) {
		emit processError(error);
		emit errorLine(error);
		return;
	}

	try {
#ifdef TRACE
		trace(QString("start(): command=%1 program=%2 args=%3")
			      .arg(publicOperation, helperPath, helperArgs.join(" ")));
#endif

		m_process.setProgram(helperPath);
		m_process.setArguments(helperArgs);
		m_process.start();
	} catch (const std::exception &e) {
		emit processError(QString("Exception: %1").arg(e.what()));
		emit errorLine(QString("Exception: %1").arg(e.what()));
		return;
	}

	emit runningChanged();
}

bool OpkgBridge::resolveCommand(const QStringList &args,
				   QString &helperPath,
				   QStringList &helperArgs,
				   QString &operationName,
				   QString &error) const
{
	if (args.size() < 2) {
		error = QStringLiteral("Invalid args: expected '<family> <action> [args...]'");
		return false;
	}

	const QString family = args.at(0).trimmed();
	const QString action = args.at(1).trimmed();

	if (family.isEmpty() || action.isEmpty()) {
		error = QStringLiteral("Invalid args: family and action are required");
		return false;
	}

	const auto &registry = commandRegistry();
	const auto familyIt = registry.constFind(family);
	if (familyIt == registry.cend()) {
		error = QStringLiteral("Unable to resolve helper for command='%1' args=%2")
				.arg(family, args.join(QStringLiteral(" ")));
		return false;
	}

	const auto actionIt = familyIt->actions.constFind(action);
	if (actionIt == familyIt->actions.cend()) {
		error = QStringLiteral("Unsupported %1 command: %2").arg(family, action);
		return false;
	}

	helperPath = actionIt->helperPath.isEmpty() ? familyIt->defaultHelperPath : actionIt->helperPath;
	helperArgs = actionIt->prefixArgs;
	helperArgs << action;
	for (int i = 2; i < args.size(); ++i) {
		helperArgs << args.at(i);
	}

	operationName = QStringLiteral("%1 %2").arg(family, action);
	return true;
}

void OpkgBridge::stop()
{
	if (m_stopping) {
			   #ifdef TRACE
			   trace("stop(): ignored because already stopping");
			   #endif
		return;
	}
	if (!running()) {
			   #ifdef TRACE
			   trace("stop(): ignored because process is not running");
			   #endif
		return;
	}

	m_stopping = true;
	emit stoppingChanged();


#ifdef Q_OS_UNIX
	const qint64 pid = m_process.processId();
#ifdef TRACE
	trace(QString("stop(): pid=%1 sending SIGTERM").arg(pid));
#endif
	if (pid > 0 && ::kill(static_cast<pid_t>(pid), SIGTERM) == 0) {
#ifdef TRACE
		trace("stop(): SIGTERM sent successfully");
#endif
		return;
	}
#ifdef TRACE
	trace("stop(): SIGTERM failed, falling back to terminate()", true);
#endif
#endif

	#ifdef TRACE
	trace("stop(): calling m_process.terminate()");
	#endif
	m_process.terminate();
}

void OpkgBridge::cleanup()
{
	// Call this from QML when the page is destroyed or navigation occurs
	if (running()) {
		m_stopping = true;
		emit stoppingChanged();
		#ifdef TRACE
		trace("cleanup(): calling m_process.terminate()");
		#endif
		m_process.terminate();
		if (!m_process.waitForFinished(2000)) {
			   #ifdef TRACE
			   trace("cleanup(): terminate() timed out, calling kill()", true);
			   #endif
			m_process.kill();
			m_process.waitForFinished(2000);
		}
		m_stopping = false;
		emit stoppingChanged();
		emit runningChanged();
	}
	m_stdoutBuffer.clear();
	m_stderrBuffer.clear();
}

void OpkgBridge::stopAndWait()
{
	if (!running()) {
		return;
	}
	if (m_stopping)
		return;

	m_stopping = true;
	emit stoppingChanged();
	#ifdef TRACE
	trace("stopAndWait(): calling m_process.terminate()");
	#endif
	m_process.terminate();
	if (!m_process.waitForFinished(2000)) {
			   #ifdef TRACE
			   trace("stopAndWait(): terminate() timed out, calling kill()", true);
			   #endif
		m_process.kill();
	}
	m_stopping = false;
	emit stoppingChanged();
	emit runningChanged();
}

void OpkgBridge::handleStdout()
{
	emitLines(m_stdoutBuffer, m_process.readAllStandardOutput(), false);
}

void OpkgBridge::handleStderr()
{
	emitLines(m_stderrBuffer, m_process.readAllStandardError(), true);
}

void OpkgBridge::handleFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
	if (!m_stdoutBuffer.isEmpty()) {
		emitLines(m_stdoutBuffer, QByteArray("\n"), false);
	}
	if (!m_stderrBuffer.isEmpty()) {
		emitLines(m_stderrBuffer, QByteArray("\n"), true);
	}

	#ifdef TRACE
	trace(QString("handleFinished(): exitCode=%1 exitStatus=%2")
			.arg(exitCode)
			.arg(static_cast<int>(exitStatus)));
	#endif

	m_stopping = false;
	emit stoppingChanged();

	emit finished(exitCode, static_cast<int>(exitStatus));
	emit runningChanged();
	// Reset operationName after completion
	if (!m_operationName.isEmpty()) {
		setOperationName("");
	}
}

void OpkgBridge::handleError(QProcess::ProcessError error)
{
	QString errorString;
	switch (error) {
	case QProcess::FailedToStart:
		errorString = QString("Process failed to start: program='%1' args=[%2]")
				      .arg(m_process.program(), m_process.arguments().join(QStringLiteral(", ")));
		break;
	case QProcess::Crashed:
		errorString = "Process crashed.";
		break;
	case QProcess::Timedout:
		errorString = "Process timed out.";
		break;
	case QProcess::ReadError:
		errorString = "Process read error.";
		break;
	case QProcess::WriteError:
		errorString = "Process write error.";
		break;
	case QProcess::UnknownError:
	default:
		errorString = "Unknown process error.";
		break;
	}
	#ifdef TRACE
	trace(QString("handleError(): %1").arg(errorString), true);
	#endif
	emit processError(errorString);
	cleanup();
}

#ifdef TRACE
void OpkgBridge::trace(const QString &message, bool isError)
{
	if (!m_traceEnabled)
		return;

	const QString line = QString("[OpkgBridge] %1").arg(message);
	qInfo().noquote() << line;
	if (isError) {
		emit errorLine(line);
	} else {
		emit outputLine(line);
	}
}
#else
void OpkgBridge::trace(const QString &, bool) {}
#endif

void OpkgBridge::emitLines(QByteArray &buffer, const QByteArray &chunk, bool isError)
{
	buffer.append(chunk);

	int newlineIndex = -1;
	while ((newlineIndex = buffer.indexOf('\n')) != -1) {
		QByteArray line = buffer.left(newlineIndex);
		buffer.remove(0, newlineIndex + 1);
		if (!line.isEmpty() && line.endsWith('\r')) {
			line.chop(1);
		}
		const QString text = QString::fromLocal8Bit(line);
		if (isError) {
			emit errorLine(text);
		} else {
			emit outputLine(text);
		}
	}
}
