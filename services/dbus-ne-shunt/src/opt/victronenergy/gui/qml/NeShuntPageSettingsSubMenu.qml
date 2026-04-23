import QtQuick 2
 
MbSubMenu {
  description: qsTr("Ne-Shunt")
  subpage: Component { NeShuntPageSettings {} }
  property var pageStack
  property var mbTools
  property bool isCustom: true
}