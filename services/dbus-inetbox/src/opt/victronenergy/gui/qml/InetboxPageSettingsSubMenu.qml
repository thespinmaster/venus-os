import QtQuick 2
 
MbSubMenu {
  description: qsTr("Inetbox")
  subpage: Component { InetboxPageSettings {} }

  property var pageStack
  property var mbTools
}

