#pragma once

#include <QObject>
#include <QHash>
#include <QProcess>
#include <QString>
#include <QStringList>
// #define TRACE

class OpkgBridge : public QObject
{
	Q_OBJECT
	Q_PROPERTY(bool running READ running NOTIFY runningChanged)
	Q_PROPERTY(bool stopping READ stopping NOTIFY stoppingChanged)
	Q_PROPERTY(QString operationName READ operationName WRITE setOperationName NOTIFY operationNameChanged)
	Q_PROPERTY(bool traceEnabled READ traceEnabled WRITE setTraceEnabled NOTIFY traceEnabledChanged)

public:
	Q_INVOKABLE bool waitForFinished(int msecs = -1);
	explicit OpkgBridge(QObject *parent = nullptr);

	bool stopping() const;
	bool running() const;

	QString operationName() const;
	void setOperationName(const QString &name);

	bool traceEnabled() const;
	void setTraceEnabled(bool enabled);

	Q_INVOKABLE void start(const QStringList &args);
	Q_INVOKABLE void stop();
	Q_INVOKABLE void stopAndWait();
	Q_INVOKABLE void cleanup(); // Call this from QML on page destruction

signals:
	void runningChanged();
	void stoppingChanged();
	void outputLine(const QString &line);
	void errorLine(const QString &line);
	void finished(int exitCode, int exitStatus);
	void operationNameChanged();
	void traceEnabledChanged();
	void processError(const QString &errorString); // New signal for errors

private slots:
	void handleStdout();
	void handleStderr();
	void handleFinished(int exitCode, QProcess::ExitStatus exitStatus);
	void handleError(QProcess::ProcessError error); // New slot

private:
	bool resolveCommand(const QStringList &args,
			   QString &helperPath,
			   QStringList &helperArgs,
			   QString &operationName,
			   QString &error) const;

	void emitLines(QByteArray &buffer, const QByteArray &chunk, bool isError);
#ifdef TRACE
	void trace(const QString &message, bool isError = false);
#else
	void trace(const QString &, bool = false);
#endif

	QProcess m_process;
	QString m_operationName;
	QByteArray m_stdoutBuffer;
	QByteArray m_stderrBuffer;
	bool m_stopping = false;
	bool m_traceEnabled = false;
};
