#include "ProcessRunner.h"

#include <QByteArray>

ProcessRunner::ProcessRunner(QObject *parent)
	: QObject(parent)
	, m_helperPath("/data/opkg-helpers/opkg-common")
{
	m_process.setProcessChannelMode(QProcess::SeparateChannels);

	connect(&m_process, &QProcess::readyReadStandardOutput, this, &ProcessRunner::handleStdout);
	connect(&m_process, &QProcess::readyReadStandardError, this, &ProcessRunner::handleStderr);
	connect(&m_process,
			QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
			this,
			&ProcessRunner::handleFinished);
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
	if (running()) {
		return;
	}

	m_stdoutBuffer.clear();
	m_stderrBuffer.clear();

	m_process.setProgram(m_helperPath);
	m_process.setArguments(args);
	m_process.start();

	emit runningChanged();
}

void ProcessRunner::stop()
{
	if (!running()) {
		return;
	}

	m_process.terminate();
	if (!m_process.waitForFinished(2000)) {
		m_process.kill();
	}
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

	emit finished(exitCode, static_cast<int>(exitStatus));
	emit runningChanged();
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
