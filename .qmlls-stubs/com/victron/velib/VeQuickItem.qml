import QtQuick 2.15

QtObject {
    property string uid: ""
    property var value: undefined
    property string text: ""
    property string invalidText: "--"
    property string unit: ""
    property bool valid: value !== undefined
    signal valueChanged()

    function setValue(v) {
        value = v
        valueChanged()
    }
}
