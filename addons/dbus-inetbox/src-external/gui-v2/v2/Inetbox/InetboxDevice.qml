/*
** Copyright (C) 2023 Victron Energy B.V.
** See LICENSE.txt for license information.
*/

import QtQuick
import Victron.VenusOS

/*
	Provides a list of settings for a gps device.
*/
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
			secondaryText: dataItem.valid && dataItem.value == 1 ? "Ok" : "--"
		}
			ListNavigation {
				topInset: Theme.geometry_listItem_itemSeparator_height
				//% "Overview Page"
				text: qsTrId("inetbox_devicelist_overview_page")
 
			}
	}

}
