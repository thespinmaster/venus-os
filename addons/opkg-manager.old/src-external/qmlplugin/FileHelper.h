#pragma once
#include <QObject>
#include <QString>
#include <QFile>
#include <QIODevice>
#include <QTextStream>

class FileHelper : public QObject {
    Q_OBJECT
public:
    Q_INVOKABLE static QString readFile(const QString &filePath);
};