/*
** Copyright (C) 2024 Victron Energy B.V.
** See LICENSE.txt for license information.
*/

import QtQuick
import Victron.VenusOS

DeviceListDelegate {
	id: root
 
	onClicked: {
		Global.pageManager.pushPage("qrc:/Inetbox/InetboxDevice.qml",
									{ bindPrefix: root.device.serviceUid })
	}

	VeQuickItem {
		id: productName
		uid: root.device.serviceUid + "/ProductName"
	}

	VeQuickItem {
		id: state

		readonly property string textValue: VenusOS.system_stateToText(value)

		uid: root.device.serviceUid + "/State"
	}
}
