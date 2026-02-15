import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils

MbPage {
	id: root
	title: qsTr("Open Package Manager Settings")

  model: VisibleItemModel {
    MbSwitch {
      name: qsTr("Compact rows")
      bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgHelpers/ShowCompact")
    }
    MbSwitch {
      name: qsTr("No Action")
      // description: "For testing installs, does not install" // Removed, MbSwitch does not have a description property
      bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgHelpers/NoAction")
    }
    MbSubMenu {
      description: qsTr("Feeds")
      subpage: Component { PageSettingsOPKGFeeds {} }
    }
    
  }
}
