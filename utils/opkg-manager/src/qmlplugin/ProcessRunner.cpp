#include "ProcessRunner.h"

#include <QByteArray>


ProcessRunner::ProcessRunner(QObject *parent)
	: QObject(parent)
	, m_helperPath("/data/opkg-manager/opkg-qml")
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
	if (m_stopping)
		return;
	if (!running())
		return;

	m_stopping = true;
	emit stoppingChanged();
	m_process.terminate();
}

void ProcessRunner::cleanup()
{
	// Call this from QML when the page is destroyed or navigation occurs
	if (running()) {
		m_stopping = true;
		emit stoppingChanged();
		m_process.terminate();
		if (!m_process.waitForFinished(2000)) {
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
	m_process.terminate();
	if (!m_process.waitForFinished(2000)) {
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
	emit processError(errorString);
	cleanup();
}

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
