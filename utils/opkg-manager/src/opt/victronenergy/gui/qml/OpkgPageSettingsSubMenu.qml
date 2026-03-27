import QtQuick 2
 
MbSubMenu {
  description: qsTr("Open Package Manager")
  subpage: Component { PageSettingsOpkg {} }
  z:1
  property var pageStack
  property var mbTools
 

}

