/****************************************************************************
** Meta object code from reading C++ file 'ProcessRunner.h'
**
** Created by: The Qt Meta Object Compiler version 68 (Qt 6.4.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include <memory>
#include "../../../ProcessRunner.h"
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'ProcessRunner.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 68
#error "This file was generated using the moc from 6.4.2. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_BEGIN_MOC_NAMESPACE
QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
namespace {
struct qt_meta_stringdata_ProcessRunner_t {
    uint offsetsAndSizes[42];
    char stringdata0[14];
    char stringdata1[18];
    char stringdata2[1];
    char stringdata3[15];
    char stringdata4[11];
    char stringdata5[5];
    char stringdata6[10];
    char stringdata7[9];
    char stringdata8[9];
    char stringdata9[11];
    char stringdata10[21];
    char stringdata11[13];
    char stringdata12[13];
    char stringdata13[15];
    char stringdata14[21];
    char stringdata15[6];
    char stringdata16[5];
    char stringdata17[5];
    char stringdata18[11];
    char stringdata19[8];
    char stringdata20[14];
};
#define QT_MOC_LITERAL(ofs, len) \
    uint(sizeof(qt_meta_stringdata_ProcessRunner_t::offsetsAndSizes) + ofs), len 
Q_CONSTINIT static const qt_meta_stringdata_ProcessRunner_t qt_meta_stringdata_ProcessRunner = {
    {
        QT_MOC_LITERAL(0, 13),  // "ProcessRunner"
        QT_MOC_LITERAL(14, 17),  // "helperPathChanged"
        QT_MOC_LITERAL(32, 0),  // ""
        QT_MOC_LITERAL(33, 14),  // "runningChanged"
        QT_MOC_LITERAL(48, 10),  // "outputLine"
        QT_MOC_LITERAL(59, 4),  // "line"
        QT_MOC_LITERAL(64, 9),  // "errorLine"
        QT_MOC_LITERAL(74, 8),  // "finished"
        QT_MOC_LITERAL(83, 8),  // "exitCode"
        QT_MOC_LITERAL(92, 10),  // "exitStatus"
        QT_MOC_LITERAL(103, 20),  // "operationNameChanged"
        QT_MOC_LITERAL(124, 12),  // "handleStdout"
        QT_MOC_LITERAL(137, 12),  // "handleStderr"
        QT_MOC_LITERAL(150, 14),  // "handleFinished"
        QT_MOC_LITERAL(165, 20),  // "QProcess::ExitStatus"
        QT_MOC_LITERAL(186, 5),  // "start"
        QT_MOC_LITERAL(192, 4),  // "args"
        QT_MOC_LITERAL(197, 4),  // "stop"
        QT_MOC_LITERAL(202, 10),  // "helperPath"
        QT_MOC_LITERAL(213, 7),  // "running"
        QT_MOC_LITERAL(221, 13)   // "operationName"
    },
    "ProcessRunner",
    "helperPathChanged",
    "",
    "runningChanged",
    "outputLine",
    "line",
    "errorLine",
    "finished",
    "exitCode",
    "exitStatus",
    "operationNameChanged",
    "handleStdout",
    "handleStderr",
    "handleFinished",
    "QProcess::ExitStatus",
    "start",
    "args",
    "stop",
    "helperPath",
    "running",
    "operationName"
};
#undef QT_MOC_LITERAL
} // unnamed namespace

Q_CONSTINIT static const uint qt_meta_data_ProcessRunner[] = {

 // content:
      10,       // revision
       0,       // classname
       0,    0, // classinfo
      11,   14, // methods
       3,  105, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       6,       // signalCount

 // signals: name, argc, parameters, tag, flags, initial metatype offsets
       1,    0,   80,    2, 0x06,    4 /* Public */,
       3,    0,   81,    2, 0x06,    5 /* Public */,
       4,    1,   82,    2, 0x06,    6 /* Public */,
       6,    1,   85,    2, 0x06,    8 /* Public */,
       7,    2,   88,    2, 0x06,   10 /* Public */,
      10,    0,   93,    2, 0x06,   13 /* Public */,

 // slots: name, argc, parameters, tag, flags, initial metatype offsets
      11,    0,   94,    2, 0x08,   14 /* Private */,
      12,    0,   95,    2, 0x08,   15 /* Private */,
      13,    2,   96,    2, 0x08,   16 /* Private */,

 // methods: name, argc, parameters, tag, flags, initial metatype offsets
      15,    1,  101,    2, 0x02,   19 /* Public */,
      17,    0,  104,    2, 0x02,   21 /* Public */,

 // signals: parameters
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void, QMetaType::QString,    5,
    QMetaType::Void, QMetaType::QString,    5,
    QMetaType::Void, QMetaType::Int, QMetaType::Int,    8,    9,
    QMetaType::Void,

 // slots: parameters
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void, QMetaType::Int, 0x80000000 | 14,    8,    9,

 // methods: parameters
    QMetaType::Void, QMetaType::QStringList,   16,
    QMetaType::Void,

 // properties: name, type, flags
      18, QMetaType::QString, 0x00015103, uint(0), 0,
      19, QMetaType::Bool, 0x00015001, uint(1), 0,
      20, QMetaType::QString, 0x00015103, uint(5), 0,

       0        // eod
};

Q_CONSTINIT const QMetaObject ProcessRunner::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_meta_stringdata_ProcessRunner.offsetsAndSizes,
    qt_meta_data_ProcessRunner,
    qt_static_metacall,
    nullptr,
    qt_incomplete_metaTypeArray<qt_meta_stringdata_ProcessRunner_t,
        // property 'helperPath'
        QtPrivate::TypeAndForceComplete<QString, std::true_type>,
        // property 'running'
        QtPrivate::TypeAndForceComplete<bool, std::true_type>,
        // property 'operationName'
        QtPrivate::TypeAndForceComplete<QString, std::true_type>,
        // Q_OBJECT / Q_GADGET
        QtPrivate::TypeAndForceComplete<ProcessRunner, std::true_type>,
        // method 'helperPathChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'runningChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'outputLine'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<const QString &, std::false_type>,
        // method 'errorLine'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<const QString &, std::false_type>,
        // method 'finished'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>,
        // method 'operationNameChanged'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'handleStdout'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'handleStderr'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'handleFinished'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>,
        QtPrivate::TypeAndForceComplete<QProcess::ExitStatus, std::false_type>,
        // method 'start'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<const QStringList &, std::false_type>,
        // method 'stop'
        QtPrivate::TypeAndForceComplete<void, std::false_type>
    >,
    nullptr
} };

void ProcessRunner::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<ProcessRunner *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->helperPathChanged(); break;
        case 1: _t->runningChanged(); break;
        case 2: _t->outputLine((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1]))); break;
        case 3: _t->errorLine((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1]))); break;
        case 4: _t->finished((*reinterpret_cast< std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<int>>(_a[2]))); break;
        case 5: _t->operationNameChanged(); break;
        case 6: _t->handleStdout(); break;
        case 7: _t->handleStderr(); break;
        case 8: _t->handleFinished((*reinterpret_cast< std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<QProcess::ExitStatus>>(_a[2]))); break;
        case 9: _t->start((*reinterpret_cast< std::add_pointer_t<QStringList>>(_a[1]))); break;
        case 10: _t->stop(); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (ProcessRunner::*)();
            if (_t _q_method = &ProcessRunner::helperPathChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 0;
                return;
            }
        }
        {
            using _t = void (ProcessRunner::*)();
            if (_t _q_method = &ProcessRunner::runningChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 1;
                return;
            }
        }
        {
            using _t = void (ProcessRunner::*)(const QString & );
            if (_t _q_method = &ProcessRunner::outputLine; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 2;
                return;
            }
        }
        {
            using _t = void (ProcessRunner::*)(const QString & );
            if (_t _q_method = &ProcessRunner::errorLine; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 3;
                return;
            }
        }
        {
            using _t = void (ProcessRunner::*)(int , int );
            if (_t _q_method = &ProcessRunner::finished; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 4;
                return;
            }
        }
        {
            using _t = void (ProcessRunner::*)();
            if (_t _q_method = &ProcessRunner::operationNameChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 5;
                return;
            }
        }
    }else if (_c == QMetaObject::ReadProperty) {
        auto *_t = static_cast<ProcessRunner *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< QString*>(_v) = _t->helperPath(); break;
        case 1: *reinterpret_cast< bool*>(_v) = _t->running(); break;
        case 2: *reinterpret_cast< QString*>(_v) = _t->operationName(); break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
        auto *_t = static_cast<ProcessRunner *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setHelperPath(*reinterpret_cast< QString*>(_v)); break;
        case 2: _t->setOperationName(*reinterpret_cast< QString*>(_v)); break;
        default: break;
        }
    } else if (_c == QMetaObject::ResetProperty) {
    } else if (_c == QMetaObject::BindableProperty) {
    }
}

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
        if (_id < 11)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 11;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 11)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 11;
    }else if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 3;
    }
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

// SIGNAL 5
void ProcessRunner::operationNameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}
QT_WARNING_POP
QT_END_MOC_NAMESPACE
