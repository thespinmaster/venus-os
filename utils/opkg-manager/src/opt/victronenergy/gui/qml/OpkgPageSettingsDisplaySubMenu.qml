import QtQuick 2
import "file:/opt/victronenergy/gui/qml"

 
MbSwitch {
  bind: "com.victronenergy.settings/Settings/OpkgManager/CustomMenus/PageMain/PageSettings"
  name: qsTr("Move settings to top")
  valueFalse: ""
  valueTrue: "^"
  property var pageStack
  property var mbTools
}

