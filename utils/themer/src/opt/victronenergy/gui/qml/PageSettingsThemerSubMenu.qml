import QtQuick 2
 
MbSubMenu {
  description: qsTr("Themer")
  subpage: Component { PageSettingsThemer {} }
  property var pageStack
  property var mbTools
}