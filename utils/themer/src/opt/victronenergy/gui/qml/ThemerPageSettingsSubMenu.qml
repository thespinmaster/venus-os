import QtQuick 2
 
MbSubMenu {
  description: qsTr("Themer")
  subpage: Component { ThemerPageSettings {} }
  property var pageStack
  property var mbTools
}