import QtQuick 2
import Victron.VenusOS

Page {
	id: page
	title: qsTr("Open Package Manager")

	Component.onDestruction: opkgManager?.cleanup()

	OpkgManager {
		id: opkgManager
		traceEnabled: true
		function showToastNotification(level, message, duration) {
			Global.showToastNotification(VenusOS.Notification_Warning, message, duration)
			console.log("opkgManager:" + level + ", " + message)
		}

	}

	GradientListView {
		id: settingsListView

		model: VisibleItemModel {

			ListNavigation {
				//% "Packages"
				text: "Packages"
				onClicked: Global.pageManager.pushPage("qrc:/OpkgManager/OpkgPageSettingsPackages.qml",
					{title: text, opkgManager: opkgManager})
			}
			ListNavigation {
				//% "Feeds"
				text: "Feeds"
				onClicked: Global.pageManager.pushPage("qrc:/OpkgManager/OpkgPageSettingsFeeds.qml",
					{title: text, opkgManager: opkgManager})
			}

			ListNavigation {
				topInset: Theme.geometry_listItem_itemSeparator_height
				bottomInset: Theme.geometry_listItem_itemSeparator_height
				//% "Custom Devices"
				text: "Custom Devices"
				onClicked: Global.pageManager.pushPage("qrc:/OpkgManager/OpkgPageSettingsCustomDevicesList.qml",
					{title: text, opkgManager: opkgManager})
			}

			ListSwitch {
				dataItem.uid: opkgManager.showCompactSetting.uid
				text: "Show Compact"
			}
			ListSwitch {
				dataItem.uid: opkgManager.noActionSetting.uid
				text: "No Action"
			}

			ListNavigation {
				topInset: Theme.geometry_listItem_itemSeparator_height
				bottomInset: Theme.geometry_listItem_itemSeparator_height
				//% "Tests"
				text: "Tests"
				onClicked: Global.pageManager.pushPage("qrc:/OpkgManager/OpkgManagerTestPage.qml", {title: text})
			}

			ListLink {
				id: documentation

				//% "Documentation"
				text: qsTrId("pagecontrollableloads_documentation")
				url: "https://thespinmaster.github.io/venus-os-addons/"
			}
		}
	}

}
