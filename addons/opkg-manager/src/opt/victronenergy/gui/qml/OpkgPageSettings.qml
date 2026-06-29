import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils

MbPage {
	id: root
	title: qsTr("Open Package Manager")

	OpkgManager {
		id: opkgManager
		function showToastNotification(level, message, duration) {
			Global.showToastNotification(VenusOS.Notification_Warning, message, duration)
		}
	}

	Component.onDestruction: {
		if (opkgManager)
			opkgManager.cleanup()
	}

	model: VisibleItemModel {
		MbSubMenu {
			description: qsTr("Packages")
			subpage: Component { OpkgPageSettingsPackages {opkgManager:root.opkgManager} }
		}
		MbSubMenu {
			description: qsTr("Feeds")
			subpage: Component { OpkgPageSettingsFeeds {opkgManager:root.opkgManager} }
		}

		MbSubMenu {
			id:cdi
			description: qsTr("Usb Serial Device Installer")
			subpage: Component {OpkgPageSettingsDeviceSetup {title:cdi.description; opkgManager:root.opkgManager} }
		}

		MbSwitch {
			name: qsTr("Show Compact")
			bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgManager/ShowCompact")
		}
		MbSwitch {
			name: qsTr("No Action")
			// description: "For testing installs, does not install"
			bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgManager/NoAction")
		}

	}
}
