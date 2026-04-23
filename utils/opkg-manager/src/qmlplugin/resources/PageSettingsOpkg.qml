import QtQuick 2
import com.victron.velib 1.0
import "file:/opt/victronenergy/gui/qml"
import "file:/opt/victronenergy/gui/qml/utils.js" as Utils


MbPage {
	id: root
	title: qsTr("Open Package Manager")

	Component.onCompleted: {
		console.debug("Component.onCompleted: OpkgPageSettings")
	}

  model: VisibleItemModel {
    MbSubMenu {
      description: qsTr("Packages")
      subpage: Component { PageSettingsOpkgPackages {} }
    }
		MbSubMenu {
      description: qsTr("Feeds")
      subpage: Component { PageSettingsOpkgFeeds {} }
    }
    MbSwitch {
      name: qsTr("Compact rows")
      bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgManager/ShowCompact")
    }
    MbSwitch {
      name: qsTr("No Action")
      // description: "For testing installs, does not install" // Removed, MbSwitch does not have a description property
      bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgManager/NoAction")
    }

    
  }
}
