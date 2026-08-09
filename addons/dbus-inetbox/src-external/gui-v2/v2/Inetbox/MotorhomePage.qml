/*
** Copyright (C) 2025 Victron Energy B.V.
** See LICENSE.txt for license information.
*/

import QtQuick
import Victron.VenusOS
import QtQuick.Controls 2.12

SwipeViewPage {
	id: root
	readonly property bool pluginReady: !GuiPluginLoader.busy && GuiPluginLoader.plugin("Inetbox").name === "Inetbox"

	//% "Motorhome"
	title: qsTrId("inetbox_motorhome")
	iconSource: "qrc:/Inetbox/image_motorhome.svg"
	url: "qrc:/Inetbox/Motorhome.qml"

	fullScreenWhenIdle: true
	topLeftButton: VenusOS.StatusBar_LeftButton_ControlsInactive
	property var device : null

	Component.onCompleted: {
		console.log("OpkgCustomPageModel: onCompleted:", "page=", url, "version=", pageLoader.plugin_version)
		addDevice()
	}
	Component.onDestruction: {
		console.log("OpkgCustomPageModel: onDestruction:", "page=", url, "version=", pageLoader.plugin_version)
	}

	FilteredDeviceModel {
		id: inetboxDevices
		serviceTypes: ["inetbox"]
		onRowsRemoved: function() {
			root.addDevice()
		}
		onRowsInserted: function() {
			root.addDevice()
		}
	}

	function addDevice() {
		console.log("addDevice in")
		var device = null
		for (var i = 0; i < inetboxDevices.count; i++) {
			device = inetboxDevices.deviceAt(i)
			if (device && device.connected)
				break
		}
		if (device)
			console.log("INETBOX-DEVICE FOUND:", device)
		else
			console.log("INETBOX-DEVICE NOT FOUND")

		pageLoader.device = device
	}

	Loader {
		id: pageLoader
		property Device device
		property string plugin_version: GuiPluginLoader.plugin("Inetbox").version

		anchors.fill: parent
		sourceComponent: Theme.screenSize === Theme.Portrait ? portraitComponent : landscapeComponent
		focus: true

		Component {
			id: landscapeComponent

			MotorhomePage_Landscape {
				animationEnabled: root.animationEnabled
			}
		}
		Component {
			id: portraitComponent

			MotorhomePage_Portrait {
				animationEnabled: root.animationEnabled
			}
		}
	}

}
