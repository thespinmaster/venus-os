import QtQuick 2
import "file:/opt/victronenergy/gui/qml"

MbSubMenu {
  description: qsTr("Open Package Manager")
  subpage: Component { OpkgPageSettings {} }
}

