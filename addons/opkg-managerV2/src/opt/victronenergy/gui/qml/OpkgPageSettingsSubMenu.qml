import QtQuick 2
 
MbSubMenu {
  description: qsTr("Open Package Manager")
  subpage: Component { OpkgPageSettings {} }
 
  property var pageStack
  property var mbTools
  property Toast toast
}

