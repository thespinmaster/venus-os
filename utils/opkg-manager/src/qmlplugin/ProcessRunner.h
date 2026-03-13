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
	Q_PROPERTY(bool stopping READ stopping NOTIFY stoppingChanged)
	Q_PROPERTY(QString operationName READ operationName WRITE setOperationName NOTIFY operationNameChanged)

public:
	explicit ProcessRunner(QObject *parent = nullptr);

	QString helperPath() const;
	void setHelperPath(const QString &path);

	bool stopping() const;
	bool running() const;

	QString operationName() const;
	void setOperationName(const QString &name);

	Q_INVOKABLE void start(const QStringList &args);
	Q_INVOKABLE void stop();
	Q_INVOKABLE void stopAndWait();
	Q_INVOKABLE void cleanup(); // Call this from QML on page destruction

signals:
	void helperPathChanged();
	void runningChanged();
	void stoppingChanged();
	void outputLine(const QString &line);
	void errorLine(const QString &line);
	void finished(int exitCode, int exitStatus);
	void operationNameChanged();
	void processError(const QString &errorString); // New signal for errors

private slots:
	void handleStdout();
	void handleStderr();
	void handleFinished(int exitCode, QProcess::ExitStatus exitStatus);
	void handleError(QProcess::ProcessError error); // New slot

private:
	void emitLines(QByteArray &buffer, const QByteArray &chunk, bool isError);

	QProcess m_process;
	QString m_helperPath;
	QString m_operationName;
	QByteArray m_stdoutBuffer;
	QByteArray m_stderrBuffer;
	bool m_stopping = false;
};
