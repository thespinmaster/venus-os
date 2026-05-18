#include "ProcessRunner.h"

#include <QByteArray>
#include <QDebug>
#include <QStandardPaths>

#include <QProcess>

// #define TRACE

#ifdef Q_OS_UNIX
#include <signal.h>
#endif


ProcessRunner::ProcessRunner(QObject *parent)
	: QObject(parent)
	, m_helperPath("/data/opkg-manager/process-runner")
	, m_operationName("")
	, m_stopping(false)
{
    m_process.setProcessChannelMode(QProcess::SeparateChannels);

    connect(&m_process, &QProcess::readyReadStandardOutput, this, &ProcessRunner::handleStdout);
    connect(&m_process, &QProcess::readyReadStandardError, this, &ProcessRunner::handleStderr);
    connect(&m_process,
	    QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
	    this,
	    &ProcessRunner::handleFinished);
    connect(&m_process, QOverload<QProcess::ProcessError>::of(&QProcess::errorOccurred),
	    this, &ProcessRunner::handleError);
}
bool ProcessRunner::stopping() const
{
	return m_stopping;
}
QString ProcessRunner::operationName() const
{
	return m_operationName;
}

void ProcessRunner::setOperationName(const QString &name)
{
	if (m_operationName == name)
		return;
	m_operationName = name;
	emit operationNameChanged();
}

bool ProcessRunner::traceEnabled() const
{
	return m_traceEnabled;
}

void ProcessRunner::setTraceEnabled(bool enabled)
{
	if (m_traceEnabled == enabled)
		return;
	m_traceEnabled = enabled;
	emit traceEnabledChanged();
}

QString ProcessRunner::helperPath() const
{
	return m_helperPath;
}

void ProcessRunner::setHelperPath(const QString &path)
{
	if (m_helperPath == path) {
		return;
	}

	m_helperPath = path;
	emit helperPathChanged();
}

bool ProcessRunner::running() const
{
	return m_process.state() != QProcess::NotRunning;
}

bool ProcessRunner::waitForFinished(int msecs)
{
	if (!running()) {
		return true;
	}
	return m_process.waitForFinished(msecs);
}

void ProcessRunner::start(const QStringList &args)
{
	if (m_stopping)
		return;
	if (running()) {
		return;
	}

	m_stdoutBuffer.clear();
	m_stderrBuffer.clear();

	try {
#ifdef TRACE
		trace(QString("start(): program=%1 args=%2").arg(m_helperPath, args.join(" ")));
#endif

		m_process.setProgram(m_helperPath);
		m_process.setArguments(args);
		m_process.start();
	} catch (const std::exception &e) {
		emit processError(QString("Exception: %1").arg(e.what()));
		return;
	}

	emit runningChanged();
}
void ProcessRunner::stop()
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

void ProcessRunner::cleanup()
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

void ProcessRunner::stopAndWait()
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

void ProcessRunner::handleStdout()
{
	emitLines(m_stdoutBuffer, m_process.readAllStandardOutput(), false);
}

void ProcessRunner::handleStderr()
{
	emitLines(m_stderrBuffer, m_process.readAllStandardError(), true);
}

void ProcessRunner::handleFinished(int exitCode, QProcess::ExitStatus exitStatus)
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

void ProcessRunner::handleError(QProcess::ProcessError error)
{
	QString errorString;
	switch (error) {
	case QProcess::FailedToStart:
		errorString = "Process failed to start.";
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
void ProcessRunner::trace(const QString &message, bool isError)
{
	if (!m_traceEnabled)
		return;

	const QString line = QString("[ProcessRunner] %1").arg(message);
	qInfo().noquote() << line;
	if (isError) {
		emit errorLine(line);
	} else {
		emit outputLine(line);
	}
}
#else
void ProcessRunner::trace(const QString &, bool) {}
#endif

void ProcessRunner::emitLines(QByteArray &buffer, const QByteArray &chunk, bool isError)
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
