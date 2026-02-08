/****************************************************************************
** Meta object code from reading C++ file 'ProcessRunner.h'
**
** Created by: The Qt Meta Object Compiler version 67 (Qt 5.15.13)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include <memory>
#include "../../../ProcessRunner.h"
#include <QtCore/qbytearray.h>
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'ProcessRunner.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 67
#error "This file was generated using the moc from 5.15.13. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
struct qt_meta_stringdata_ProcessRunner_t {
    QByteArrayData data[19];
    char stringdata0[200];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_ProcessRunner_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_ProcessRunner_t qt_meta_stringdata_ProcessRunner = {
    {
QT_MOC_LITERAL(0, 0, 13), // "ProcessRunner"
QT_MOC_LITERAL(1, 14, 17), // "helperPathChanged"
QT_MOC_LITERAL(2, 32, 0), // ""
QT_MOC_LITERAL(3, 33, 14), // "runningChanged"
QT_MOC_LITERAL(4, 48, 10), // "outputLine"
QT_MOC_LITERAL(5, 59, 4), // "line"
QT_MOC_LITERAL(6, 64, 9), // "errorLine"
QT_MOC_LITERAL(7, 74, 8), // "finished"
QT_MOC_LITERAL(8, 83, 8), // "exitCode"
QT_MOC_LITERAL(9, 92, 10), // "exitStatus"
QT_MOC_LITERAL(10, 103, 12), // "handleStdout"
QT_MOC_LITERAL(11, 116, 12), // "handleStderr"
QT_MOC_LITERAL(12, 129, 14), // "handleFinished"
QT_MOC_LITERAL(13, 144, 20), // "QProcess::ExitStatus"
QT_MOC_LITERAL(14, 165, 5), // "start"
QT_MOC_LITERAL(15, 171, 4), // "args"
QT_MOC_LITERAL(16, 176, 4), // "stop"
QT_MOC_LITERAL(17, 181, 10), // "helperPath"
QT_MOC_LITERAL(18, 192, 7) // "running"

    },
    "ProcessRunner\0helperPathChanged\0\0"
    "runningChanged\0outputLine\0line\0errorLine\0"
    "finished\0exitCode\0exitStatus\0handleStdout\0"
    "handleStderr\0handleFinished\0"
    "QProcess::ExitStatus\0start\0args\0stop\0"
    "helperPath\0running"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_ProcessRunner[] = {

 // content:
       8,       // revision
       0,       // classname
       0,    0, // classinfo
      10,   14, // methods
       2,   88, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       5,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    0,   64,    2, 0x06 /* Public */,
       3,    0,   65,    2, 0x06 /* Public */,
       4,    1,   66,    2, 0x06 /* Public */,
       6,    1,   69,    2, 0x06 /* Public */,
       7,    2,   72,    2, 0x06 /* Public */,

 // slots: name, argc, parameters, tag, flags
      10,    0,   77,    2, 0x08 /* Private */,
      11,    0,   78,    2, 0x08 /* Private */,
      12,    2,   79,    2, 0x08 /* Private */,

 // methods: name, argc, parameters, tag, flags
      14,    1,   84,    2, 0x02 /* Public */,
      16,    0,   87,    2, 0x02 /* Public */,

 // signals: parameters
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void, QMetaType::QString,    5,
    QMetaType::Void, QMetaType::QString,    5,
    QMetaType::Void, QMetaType::Int, QMetaType::Int,    8,    9,

 // slots: parameters
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void, QMetaType::Int, 0x80000000 | 13,    8,    9,

 // methods: parameters
    QMetaType::Void, QMetaType::QStringList,   15,
    QMetaType::Void,

 // properties: name, type, flags
      17, QMetaType::QString, 0x00495103,
      18, QMetaType::Bool, 0x00495001,

 // properties: notify_signal_id
       0,
       1,

       0        // eod
};

void ProcessRunner::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<ProcessRunner *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->helperPathChanged(); break;
        case 1: _t->runningChanged(); break;
        case 2: _t->outputLine((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 3: _t->errorLine((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 4: _t->finished((*reinterpret_cast< int(*)>(_a[1])),(*reinterpret_cast< int(*)>(_a[2]))); break;
        case 5: _t->handleStdout(); break;
        case 6: _t->handleStderr(); break;
        case 7: _t->handleFinished((*reinterpret_cast< int(*)>(_a[1])),(*reinterpret_cast< QProcess::ExitStatus(*)>(_a[2]))); break;
        case 8: _t->start((*reinterpret_cast< const QStringList(*)>(_a[1]))); break;
        case 9: _t->stop(); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (ProcessRunner::*)();
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&ProcessRunner::helperPathChanged)) {
                *result = 0;
                return;
            }
        }
        {
            using _t = void (ProcessRunner::*)();
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&ProcessRunner::runningChanged)) {
                *result = 1;
                return;
            }
        }
        {
            using _t = void (ProcessRunner::*)(const QString & );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&ProcessRunner::outputLine)) {
                *result = 2;
                return;
            }
        }
        {
            using _t = void (ProcessRunner::*)(const QString & );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&ProcessRunner::errorLine)) {
                *result = 3;
                return;
            }
        }
        {
            using _t = void (ProcessRunner::*)(int , int );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&ProcessRunner::finished)) {
                *result = 4;
                return;
            }
        }
    }
#ifndef QT_NO_PROPERTIES
    else if (_c == QMetaObject::ReadProperty) {
        auto *_t = static_cast<ProcessRunner *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< QString*>(_v) = _t->helperPath(); break;
        case 1: *reinterpret_cast< bool*>(_v) = _t->running(); break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
        auto *_t = static_cast<ProcessRunner *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setHelperPath(*reinterpret_cast< QString*>(_v)); break;
        default: break;
        }
    } else if (_c == QMetaObject::ResetProperty) {
    }
#endif // QT_NO_PROPERTIES
}

QT_INIT_METAOBJECT const QMetaObject ProcessRunner::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_meta_stringdata_ProcessRunner.data,
    qt_meta_data_ProcessRunner,
    qt_static_metacall,
    nullptr,
    nullptr
} };


const QMetaObject *ProcessRunner::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *ProcessRunner::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_ProcessRunner.stringdata0))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int ProcessRunner::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 10)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 10;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 10)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 10;
    }
#ifndef QT_NO_PROPERTIES
    else if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 2;
    } else if (_c == QMetaObject::QueryPropertyDesignable) {
        _id -= 2;
    } else if (_c == QMetaObject::QueryPropertyScriptable) {
        _id -= 2;
    } else if (_c == QMetaObject::QueryPropertyStored) {
        _id -= 2;
    } else if (_c == QMetaObject::QueryPropertyEditable) {
        _id -= 2;
    } else if (_c == QMetaObject::QueryPropertyUser) {
        _id -= 2;
    }
#endif // QT_NO_PROPERTIES
    return _id;
}

// SIGNAL 0
void ProcessRunner::helperPathChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void ProcessRunner::runningChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void ProcessRunner::outputLine(const QString & _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))) };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}

// SIGNAL 3
void ProcessRunner::errorLine(const QString & _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))) };
    QMetaObject::activate(this, &staticMetaObject, 3, _a);
}

// SIGNAL 4
void ProcessRunner::finished(int _t1, int _t2)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t2))) };
    QMetaObject::activate(this, &staticMetaObject, 4, _a);
}
QT_WARNING_POP
QT_END_MOC_NAMESPACE
