import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
import QtQuick.Controls

OverviewPage {
		id: root

	property variant sys: theSystem
	property string settingsPrefix: "com.victronenergy.settings"
	property string systemPrefix: "com.victronenergy.system"
	property string platformPrefix: "com.victronenergy.platform"
	property string inetboxPrefix: ""
	property VBusItem _systemState: VBusItem { bind: Utils.path(systemPrefix, "/SystemState/State") }
	property bool hasSystemState: _systemState.valid
 
	// Inetbox DBus bindings
	VBusItem { id: waterTargetTempItem; bind: Utils.path(inetboxPrefix, "/Values/WaterTargetTemp") }
	VBusItem { id: energyMixItem; bind: Utils.path(inetboxPrefix, "/Values/EnergyMixCombined") }
	VBusItem { id: heatingModeItem; bind: Utils.path(inetboxPrefix, "/Values/HeatingMode") }
	VBusItem { id: heatingTargetTempItem; bind: Utils.path(inetboxPrefix, "/Values/HeatingTargetTemp") }
	VBusItem { id: heatingCurrentTempItem; bind: Utils.path(inetboxPrefix, "/Values/HeatingCurrentTemp") }
	VBusItem { id: airconModeItem; bind: Utils.path(inetboxPrefix, "/Values/AirconMode") }
	VBusItem { id: airconFanSpeedItem; bind: Utils.path(inetboxPrefix, "/Values/AirconFanSpeed") }
	VBusItem { id: airconTargetTempItem; bind: Utils.path(inetboxPrefix, "/Values/AirconTargetTemp") }
	VBusItem { id: airconCurrentTempItem; bind: Utils.path(inetboxPrefix, "/Values/AirconCurrentTemp") }

	Connections {
		target: DBusServices
		
		function onDbusServiceFound(service) { 
			console.debug("njka:onDbusServiceFound:" + service.name)
			findInetboxService(service) 
		}
		function onDbusServiceConnected(service) {
			console.debug("njka:onDbusServiceConnected:" + service.name)
			findInetboxService(service)
		}
		function onDbusServiceDisconnected(service) {
			console.debug("njka:onDbusServiceDisconnected:" + service.name)
			if (inetboxPrefix === service.name) {
				inetboxPrefix = ""
			}
		}
	}

	Component.onCompleted: {
		discoverServices()
		inetboxDiscoveryTimer.start()
	}

	Timer {
		id: inetboxDiscoveryTimer
		interval: 1000
		repeat: true
		running: false
		onTriggered: {
			if (inetboxPrefix === "") {
				discoverServices()
			} else {
				stop()
			}
		}
	}

	function findInetboxService(service) {
		console.debug("findInetboxService")
		
		if (service.name.indexOf("com.victronenergy.dbus_inetbox") === 0) {
			if (inetboxPrefix === "") {
				inetboxPrefix = service.name
				console.debug("Found inetbox service: " + inetboxPrefix)
				
			}
		}
	}

	function discoverServices() {
		// Scan existing services for inetbox
		console.debug("njka:discoverServices:" + DBusServices.count.toString())
		for (var i = 0; i < DBusServices.count; i++) {
			
			var service = DBusServices.at(i)
			console.debug("njka: service: " + i.toString() + ", " + service.name)
			if (service.name.indexOf("com.victronenergy.dbus_inetbox") === 0) {
				inetboxPrefix = service.name
				console.debug("Discovered inetbox service: " + inetboxPrefix)
				break
			}
		}
	}
	 
	
	Rectangle {
			id: rectangle
				anchors.fill: parent
				color: "#1C3749"
			
			// Header
			Text {
					id: header
					width: 188
					height: 30
					color: "#FFFFFF"
					text: qsTr("Truma")
					anchors.top: parent.top
					anchors.topMargin: 0
					font.pixelSize: 20
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
					anchors.horizontalCenter: parent.horizontalCenter
					font.styleName: "Bold"
			}
      // Water
			Rectangle {
				id: waterControlContainer
				anchors.top: header.bottom
				anchors.topMargin: 2
				anchors.left: parent.left
				anchors.leftMargin: 8
				width: parent.width / 2.2 - 16
				height: buttonControl.height + 40
				color: "#171820"
				radius: 12

				Text {
					text: "Water"
					color: "#FFFFFF"
					font.pixelSize: 14
					font.bold: true
					anchors.top: parent.top
					anchors.topMargin: 6
					anchors.left: parent.left
					anchors.leftMargin: 6
				}

				ButtonGroupControl {
					id: buttonControl
					model: ["Off", "Eco", "Hot", "Boost"]
					valueMapping: ["0", "40", "60", "200"]
					Component.onCompleted: setIndexFromValue(waterTargetTempItem.value)
					onActivated: waterTargetTempItem.setValue(getValueAtIndex(currentIndex))
					anchors.left: parent.left
					anchors.leftMargin: 6
					anchors.right: parent.right
					anchors.rightMargin: 6
					anchors.top: parent.top
					anchors.topMargin: 30
				}
				
				Connections {
					target: waterTargetTempItem
					function onValueChanged() {
						buttonControl.setIndexFromValue(waterTargetTempItem.value)
					}
				}
			}

      // Energy Mix
			Rectangle {
				id: energyMixControlContainer
				anchors.top: header.bottom
				anchors.topMargin: waterControlContainer.topMargin
				anchors.left: waterControlContainer.right
				anchors.leftMargin: 8
				width: parent.width / 1.8 - 12
				height: energyMixButtonControl.height + 40
				color: "#171820"
				radius: 12

				Text {
					text: "Energy Mix"
					color: "#FFFFFF"
					font.pixelSize: 14
					font.bold: true
					anchors.top: parent.top
					anchors.topMargin: 6
					anchors.left: parent.left
					anchors.leftMargin: 6
				}

				ButtonGroupControl {
					id: energyMixButtonControl
					model: ["Gas", "Mix1", "Mix2", "El1", "El2"]
					valueMapping: ["gas|0", "mix|900", "mix|1800", "electricity|900", "electricity|1800"]
					Component.onCompleted: setIndexFromValue(energyMixItem.value)
					onActivated: energyMixItem.setValue(getValueAtIndex(currentIndex))
					anchors.left: parent.left
					anchors.leftMargin: 6
					anchors.right: parent.right
					anchors.rightMargin: 6
					anchors.top: parent.top
					anchors.topMargin: 30
				}
				
				Connections {
					target: energyMixItem
					function onValueChanged() {
						energyMixButtonControl.setIndexFromValue(energyMixItem.value)
					}
				}
			}

			// Heating
			Rectangle {
				id: heatingControlContainer
				anchors.top: waterControlContainer.bottom
				anchors.topMargin: 10
				anchors.left: parent.left
				anchors.leftMargin: 8
				width: waterControlContainer.width
				height: heatingButtonControl.height + heatingSlider.height + 70
				color: "#171820"
				
				radius: 12

				Text {
					text: "Heating"
					color: "#FFFFFF"
					font.pixelSize: 14
					font.bold: true
					anchors.top: parent.top
					anchors.topMargin: 6
					anchors.left: parent.left
					anchors.leftMargin: 6
				}

				ButtonGroupControl {
					id: heatingButtonControl
					model: ["Off", "Eco", "High"]
					valueMapping: ["Off", "eco", "high"]

					Component.onCompleted: setIndexFromValue(heatingModeItem.value)
					onActivated: heatingModeItem.setValue(getValueAtIndex(currentIndex))
					anchors.left: parent.left
					anchors.leftMargin: 6
					anchors.right: parent.right
					anchors.rightMargin: 6
					anchors.top: parent.top
					anchors.topMargin: 30
				}
				
				Connections {
					target: heatingModeItem
					function onValueChanged() {
						heatingButtonControl.setIndexFromValue(heatingModeItem.value)
					}
				}

				Text {
					text: "Target Temp"
					color: "#FFFFFF"
					font.pixelSize: 12
					anchors.top: heatingButtonControl.bottom
					anchors.topMargin: 10
					anchors.left: parent.left
					anchors.leftMargin: 6
				}

				Slider {
					id: heatingSlider
					from: 5
					to: 30
					value: heatingTargetTempItem.value || 20
					onPressedChanged: if (!pressed) heatingTargetTempItem.setValue(value)
					anchors.left: parent.left
					anchors.right: tempValueLabel.left
					anchors.rightMargin: 4
					anchors.top: heatingButtonControl.bottom
					anchors.topMargin: 30
					anchors.leftMargin: 6
				}

				Text {
					id: tempValueLabel
					text: heatingSlider.value.toFixed(0) + "°C"
					color: "#FFFFFF"
					font.pixelSize: 14
					anchors.right: parent.right
					anchors.rightMargin: 6
					anchors.top: heatingButtonControl.bottom
					anchors.topMargin: 30
					anchors.verticalCenter: heatingSlider.verticalCenter
				}
			}

			// Aircon
			Rectangle {
				id: airconControlContainer
				anchors.top: waterControlContainer.bottom
				anchors.topMargin: 10
				anchors.left: heatingControlContainer.right
				anchors.leftMargin: 8
				width: energyMixControlContainer.width
				height: airconHeader.height + airconModeButtonControl.height + airconFanButtonControl.height + airconTargetTemp.height + airconSlider.height + 50
				color: "#171820"
				radius: 12

				Text {
					id: airconHeader
					text: "Aircon"
					color: "#FFFFFF"
					font.pixelSize: 14
					font.bold: true
					anchors.top: parent.top
					anchors.topMargin: 6
					anchors.left: parent.left
					anchors.leftMargin: 6
				}

				ButtonGroupControl {
					id: airconModeButtonControl
					model: ["Off", "Vent", "Cool", "Hot", "Auto"]
					valueMapping: ["off", "vent", "cool", "hot", "auto"]
					Component.onCompleted: setIndexFromValue(airconModeItem.value)
					onActivated: airconModeItem.setValue(getValueAtIndex(currentIndex))
					anchors.left: parent.left
					anchors.leftMargin: 6
					anchors.right: parent.right
					anchors.rightMargin: 6
					anchors.top: parent.top
					anchors.topMargin: 30
				}
				
				Connections {
					target: airconModeItem
					function onValueChanged() {
						airconModeButtonControl.setIndexFromValue(airconModeItem.value)
					}
				}

				ButtonGroupControl {
					id: airconFanButtonControl
					model: ["Low", "Mid", "High", "Night", "Auto"]
					valueMapping: ["low", "mid", "high", "night", "auto"]
					Component.onCompleted: setIndexFromValue(airconFanSpeedItem.value)
					onActivated: airconFanSpeedItem.setValue(getValueAtIndex(currentIndex))
					anchors.left: parent.left
					anchors.leftMargin: 6
					anchors.right: parent.right
					anchors.rightMargin: 6
					anchors.top: airconModeButtonControl.bottom
					anchors.topMargin: 12
				}
				
				Connections {
					target: airconFanSpeedItem
					function onValueChanged() {
						airconFanButtonControl.setIndexFromValue(airconFanSpeedItem.value)
					}
				}

				Text {
					id: airconTargetTemp
					text: "Target Temp"
					color: "#FFFFFF"
					font.pixelSize: 12
					anchors.top: airconFanButtonControl.bottom
					anchors.topMargin: 10
					anchors.left: parent.left
					anchors.leftMargin: 6
				}

				Slider {
					id: airconSlider
					from: 16
					to: 30
					value: airconTargetTempItem.value || 16
					onPressedChanged: if (!pressed) airconTargetTempItem.setValue(value)
					anchors.left: parent.left
					anchors.right: airconTempValueLabel.left
					anchors.rightMargin: 4
					anchors.top: airconFanButtonControl.bottom
					anchors.topMargin: 30
					anchors.leftMargin: 6
				}

				Text {
					id: airconTempValueLabel
					text: airconSlider.value.toFixed(0) + "°C"
					color: "#FFFFFF"
					font.pixelSize: 14
					anchors.right: parent.right
					anchors.rightMargin: 6
					anchors.top: airconFanButtonControl.bottom
					anchors.topMargin: 30
					anchors.verticalCenter: airconSlider.verticalCenter
				}
			}

	}
}
