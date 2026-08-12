 import QtQuick
import Victron.VenusOS

DevicePage {
	id: root

	property string bindPrefix

	serviceUid: bindPrefix
	Component.onCompleted: {
		guiPluginIntegrationsColumn.visible = false
	}
	settingsModel: VisibleItemModel {

		ListText {
			//% "Connected"
			text: qsTrId("inetbox_connected")
			dataItem.uid: root.bindPrefix + "/Connected"
			secondaryText: dataItem.valid && dataItem.value == 1 ? CommonWords.ok : "--"
		}
			ListNavigation {
				topInset: Theme.geometry_listItem_itemSeparator_height
				//% "Overview Page"
				text: qsTrId("inetbox_overview_page")

			}
	}

}
