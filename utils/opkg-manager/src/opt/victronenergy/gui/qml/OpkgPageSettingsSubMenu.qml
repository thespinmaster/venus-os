import QtQuick 2
import Qt.labs.components.native 1.0
import com.victron.velib 1.0

MbSubMenu {
  description: qsTr("Open Package Manager")
  subpage: Component { PageSettingsOpkg {} }
}

