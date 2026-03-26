import QtQuick 2
 
MbSubMenu {
  description: qsTr("Inetbox")
  subpage: Component { PageSettingsInetbox {} }

  property var pageStack
  property var mbTools
}

