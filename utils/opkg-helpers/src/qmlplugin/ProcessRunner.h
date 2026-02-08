#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QStringList>

class ProcessRunner : public QObject
{
	Q_OBJECT
	Q_PROPERTY(QString helperPath READ helperPath WRITE setHelperPath NOTIFY helperPathChanged)
	Q_PROPERTY(bool running READ running NOTIFY runningChanged)

public:
	explicit ProcessRunner(QObject *parent = nullptr);

	QString helperPath() const;
	void setHelperPath(const QString &path);

	bool running() const;

	Q_INVOKABLE void start(const QStringList &args);
	Q_INVOKABLE void stop();

signals:
	void helperPathChanged();
	void runningChanged();
	void outputLine(const QString &line);
	void errorLine(const QString &line);
	void finished(int exitCode, int exitStatus);

private slots:
	void handleStdout();
	void handleStderr();
	void handleFinished(int exitCode, QProcess::ExitStatus exitStatus);

private:
	void emitLines(QByteArray &buffer, const QByteArray &chunk, bool isError);

	QProcess m_process;
	QString m_helperPath;
	QByteArray m_stdoutBuffer;
	QByteArray m_stderrBuffer;
};
