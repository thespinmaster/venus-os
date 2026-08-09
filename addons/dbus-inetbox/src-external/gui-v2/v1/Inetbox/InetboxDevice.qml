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
			dataItem.uid: bindPrefix + "/Connected"
			secondaryText: dataItem.valid && dataItem.value == 1 ? "Ok" : "--"
		}
			ListNavigation {
				topInset: Theme.geometry_listItem_itemSeparator_height
				//% "Overview Page"
				text: qsTrId("inetbox_devicelist_overview_page")
				//qrc:/qt/qml/Victron/VenusOS/pages/boat/BoatPage.qml:-1 No such file or directory
				// /pages/battery/BatteryListPage.qml
				// /pages/boat/BoatPage.qml
				onClicked: Global.pageManager.pushPage(
					"qrc:/qt/qml/Victron/VenusOS/boat/BoatPage.qml",
					{"title": text})
				// onClicked: Global.pageManager.pushPage(
				// 	"qrc:/Inetbox/InetboxOverviewPage_Landscape.qml",
				// 	{"title": text})
			}
	}

}
