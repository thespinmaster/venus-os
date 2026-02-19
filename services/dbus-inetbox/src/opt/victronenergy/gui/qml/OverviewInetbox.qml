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
	property string inetboxPrefix: "com.victronenergy.dbus_inetbox"
	property VBusItem _systemState: VBusItem { bind: Utils.path(systemPrefix, "/SystemState/State") }
	property bool hasSystemState: _systemState.valid
  property int headerFont: 20
	property int groupFont: 12
  property int textFont: 12
	property color selectedColor: "#6491CC"
	property color selectedTextColor: "#FFFFFF"
	property color backgroundColor: "#171820"
	property color fontColor: "#FFFFFF"
	property color groupBackgroundColor: "#1C3749"
	property color headerFontColor: "#FFFFFF"
	
	// Inetbox DBus bindings
	VBusItem { id: customNameItem; bind: Utils.path(inetboxPrefix, "/CustomName") }
	VBusItem { id: waterTargetTempItem; bind: Utils.path(inetboxPrefix, "/Values/WaterTargetTemp") }
	VBusItem { id: waterCurrentTempItem; bind: Utils.path(inetboxPrefix, "/Values/WaterCurrentTemp") }
	VBusItem { id: energyMixItem; bind: Utils.path(inetboxPrefix, "/Values/EnergyMixCombined") }
	VBusItem { id: heatingModeItem; bind: Utils.path(inetboxPrefix, "/Values/HeatingMode") }
	VBusItem { id: heatingTargetTempItem; bind: Utils.path(inetboxPrefix, "/Values/HeatingTargetTemp") }
	VBusItem { id: heatingCurrentTempItem; bind: Utils.path(inetboxPrefix, "/Values/HeatingCurrentTemp") }
	VBusItem { id: airconModeItem; bind: Utils.path(inetboxPrefix, "/Values/AirconMode") }
	VBusItem { id: airconFanSpeedItem; bind: Utils.path(inetboxPrefix, "/Values/AirconFanSpeed") }
	VBusItem { id: airconTargetTempItem; bind: Utils.path(inetboxPrefix, "/Values/AirconTargetTemp") }
	VBusItem { id: airconCurrentTempItem; bind: Utils.path(inetboxPrefix, "/Values/AirconCurrentTemp") }
	VBusItem { id: themeItem; bind: Utils.path(settingsPrefix, "/Settings/Devices/dbus_inetbox/Theme") }
  VBusItem { id: showAirconItem; bind: Utils.path(settingsPrefix, "/Settings/Devices/dbus_inetbox/ShowAircon") }
  VBusItem { id: metricItem; bind: Utils.path(settingsPrefix, "/Settings/Devices/dbus_inetbox/Metric") }
property string settingsPrefix: "com.victronenergy.settings/Settings/Devices/dbus_inetbox/Port"
	function applyTheme(themeName) {
		switch (themeName) {
		case "dark":
			backgroundColor = "#171820"
			fontColor = "#FFFFFF"
			groupBackgroundColor = "#1C3749"
			headerFontColor = "#FFFFFF"
			selectedColor = "#6491CC"
			selectedTextColor = "#FFFFFF"
			break
		case "veBlue1":
			backgroundColor = "#4891CC"
			fontColor = "#4891CC"
			groupBackgroundColor = "#f0f2f5"
			headerFontColor = "#FFFFFF"
			selectedColor = "#4891CC"
			selectedTextColor = "#FFFFFF"
			break
		case "veBlue2":
			backgroundColor = "#FFFFFF"
			fontColor = "#FFFFFF"
			groupBackgroundColor = "#4891CC"
			headerFontColor = "#4891CC"
			selectedColor = "#FFFFFF"
			selectedTextColor = "#4891CC"
			break
		case "light":
		default:
			backgroundColor = "#FFFFFF"
			fontColor = "#FFFFFF"
			groupBackgroundColor = "#4891CC"
			headerFontColor = "#4891CC"
			selectedColor = "#FFFFFF"
			selectedTextColor = "#4891CC"
			break
		
		
		}
	}

	function formatTemp(value) {
		var num = parseFloat(value)
		if (isNaN(num)) {
			return "--"
		}
		if (metricItem.value === 0) {
			return (num * 9 / 5 + 32).toFixed(1) + "°F"
		}
		return num.toFixed(1) + "°C"
	}
/*
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
	
*/
	/*
	Component.onCompleted: {
		console.debug("njka:Theme:" + themeItem.value)
		console.debug("njka:Theme:" + showAircon.value)
	}
	*/

	Component.onCompleted: applyTheme(themeItem.value)

	Connections {
		target: themeItem
		function onValueChanged() {
			applyTheme(themeItem.value)
		}
	}

	Rectangle {
			id: rectangle
			anchors.fill: parent
			color: backgroundColor
			
			// Header
			Text {
					id: header
					text: customNameItem.value || qsTr("Truma")
					color: headerFontColor
					font.pixelSize: headerFont
					font.bold: true
					anchors.top: parent.top
					anchors.left: parent.left
					anchors.topMargin: 0
					anchors.horizontalCenter: parent.horizontalCenter
					horizontalAlignment: Text.AlignHCenter
			}

			Text {
				id: heatingCurrentTempText
				text: formatTemp(heatingCurrentTempItem.value)
				color: headerFontColor
				font.pixelSize: textFont
				anchors.top: parent.top
				anchors.topMargin: 6
				anchors.right: parent.right
				anchors.rightMargin: 6
			}

			Connections {
				target: heatingCurrentTempItem
				function onValueChanged() {
					heatingCurrentTempText.text = formatTemp(heatingCurrentTempItem.value)
				}
			}

			Connections {
				target: metricItem
				function onValueChanged() {
					heatingCurrentTempText.text = formatTemp(heatingCurrentTempItem.value)
				}
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
				color: groupBackgroundColor
				radius: 12

				Text {
					text: "Water"
					color: fontColor
					font.pixelSize: groupFont
					font.bold: true
					anchors.top: parent.top
					anchors.topMargin: 6
					anchors.left: parent.left
					anchors.leftMargin: 6
				}

				ButtonGroupControl {
					id: buttonControl
					textColor: fontColor
					selectedTextColor: root.selectedTextColor
					selectedColor: root.selectedColor
					model: ["Off", "Eco", "Hot", "Boost"]
					valueMapping: ["0", "40", "60", "200"]
					Component.onCompleted: setIndexFromValue(waterTargetTempItem.value)
					onActivated: waterTargetTempItem.setValue(getValueAtIndex(currentIndex))
					anchors.left: parent.left
					anchors.leftMargin: 6
					anchors.right: waterCurrentTempDisplay.left
					anchors.rightMargin: 6
					anchors.top: parent.top
					anchors.topMargin: 30
				}

				Text {
					id: waterCurrentTempDisplay
					text: formatTemp(waterCurrentTempItem.value)
					color: fontColor
					font.pixelSize: textFont
					anchors.right: parent.right
					anchors.rightMargin: 6
					anchors.top: parent.top
					anchors.topMargin: 6

					Connections {
						target: waterCurrentTempItem
						function onValueChanged() {
							waterCurrentTempDisplay.text = formatTemp(waterCurrentTempItem.value)
						}
					}		

					Connections {
						target: metricItem
						function onValueChanged() {
							waterCurrentTempDisplay.text = formatTemp(waterCurrentTempItem.value)
						}
					}
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
				anchors.top: waterControlContainer.top
				anchors.topMargin: waterControlContainer.topMargin
				anchors.left: waterControlContainer.right
				anchors.leftMargin: 8
				width: parent.width / 1.8 - 12
				height: energyMixButtonControl.height + 40
				color: groupBackgroundColor
				radius: 12

				Text {
					text: "Energy Mix"
					color: fontColor
					font.pixelSize: groupFont
					font.bold: true
					anchors.top: parent.top
					anchors.topMargin: 6
					anchors.left: parent.left
					anchors.leftMargin: 6
				}

				ButtonGroupControl {
					id: energyMixButtonControl
					textColor: fontColor
					selectedTextColor: root.selectedTextColor
					selectedColor: root.selectedColor
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
				color: groupBackgroundColor
				
				radius: 12

				Text {
					text: "Heating"
					color: fontColor
					font.pixelSize: groupFont
					font.bold: true
					anchors.top: parent.top
					anchors.topMargin: 6
					anchors.left: parent.left
					anchors.leftMargin: 6
				}

				ButtonGroupControl {
					id: heatingButtonControl
					textColor: fontColor
					selectedTextColor: root.selectedTextColor
					selectedColor: root.selectedColor
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
					color: fontColor
					font.pixelSize: textFont
					anchors.top: heatingButtonControl.bottom
					anchors.topMargin: 10
					anchors.left: parent.left
					anchors.leftMargin: 6
				}

				Slider {
					id: heatingSlider
					from: 5
					to: 30
					stepSize: 1
					snapMode: Slider.SnapAlways
					value: heatingTargetTempItem.value || 20
					onPressedChanged: if (!pressed) heatingTargetTempItem.setValue(value)
					background: Rectangle {
						x: heatingSlider.leftPadding
						y: heatingSlider.topPadding + heatingSlider.availableHeight / 2 - height / 2
						width: heatingSlider.availableWidth
						height: 6
						radius: 3
						color: Qt.rgba(root.selectedColor.r, root.selectedColor.g, root.selectedColor.b, 0.25)
						Rectangle {
							width: heatingSlider.visualPosition * parent.width
							height: parent.height
							radius: 3
							color: root.selectedColor
						}
					}
					anchors.left: parent.left
					anchors.right: tempValueLabel.left
					anchors.rightMargin: 4
					anchors.top: heatingButtonControl.bottom
					anchors.topMargin: 30
					anchors.leftMargin: 6
			}

			Text {
				id: tempValueLabel
				text: formatTemp(heatingSlider.value).replace(".0", "")
				color: fontColor
				font.pixelSize: textFont
				anchors.right: parent.right
				anchors.rightMargin: 6
				anchors.top: heatingButtonControl.bottom
				anchors.topMargin: 29
				anchors.verticalCenter: heatingSlider.verticalCenter
			}

			Connections {
				target: metricItem
				function onValueChanged() {
					tempValueLabel.text = formatTemp(heatingSlider.value).replace(".0", "")
				}
			}
		}

		// Aircon
		Rectangle {
			id: airconControlContainer
			visible: !!showAirconItem.value
			anchors.top: waterControlContainer.bottom
			anchors.topMargin: 10
			anchors.left: heatingControlContainer.right
			anchors.leftMargin: 8
			width: energyMixControlContainer.width
			height: airconHeader.height + airconModeButtonControl.height + airconFanButtonControl.height + airconTargetTemp.height + airconSlider.height + 50
			color: groupBackgroundColor
			radius: 12

			Text {
				id: airconHeader
				text: "Aircon"
				color: fontColor
				font.pixelSize: groupFont
				font.bold: true
				anchors.top: parent.top
				anchors.topMargin: 6
				anchors.left: parent.left
				anchors.leftMargin: 6
			}

			ButtonGroupControl {
				id: airconModeButtonControl
				textColor: fontColor
				selectedTextColor: root.selectedTextColor
				selectedColor: root.selectedColor
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
				textColor: fontColor
				selectedTextColor: root.selectedTextColor
				selectedColor: root.selectedColor
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
				color: fontColor
				font.pixelSize: textFont
				anchors.top: airconFanButtonControl.bottom
				anchors.topMargin: 10
				anchors.left: parent.left
				anchors.leftMargin: 6
			}

			Slider {
				id: airconSlider
				from: 16
				to: 30
				stepSize: 1
				snapMode: Slider.SnapAlways
				value: airconTargetTempItem.value || 16
				onPressedChanged: if (!pressed) airconTargetTempItem.setValue(value)
				background: Rectangle {
					x: airconSlider.leftPadding
					y: airconSlider.topPadding + airconSlider.availableHeight / 2 - height / 2
					width: airconSlider.availableWidth
					height: 6
					radius: 3
					color: Qt.rgba(root.selectedColor.r, root.selectedColor.g, root.selectedColor.b, 0.25)
					Rectangle {
						width: airconSlider.visualPosition * parent.width
						height: parent.height
						radius: 3
						color: root.selectedColor
					}
				}
				anchors.left: parent.left
				anchors.right: airconTempValueLabel.left
				anchors.rightMargin: 4
				anchors.top: airconFanButtonControl.bottom
				anchors.topMargin: 30
				anchors.leftMargin: 6
			}

			Text {
					id: airconTempValueLabel
					text: formatTemp(airconSlider.value).replace(".0", "")
					color: fontColor
					font.pixelSize: textFont
					anchors.right: parent.right
					anchors.rightMargin: 6
					anchors.top: airconFanButtonControl.bottom
					anchors.topMargin: 29
					anchors.verticalCenter: airconSlider.verticalCenter
				}

				Connections {
					target: metricItem
					function onValueChanged() {
						airconTempValueLabel.text = formatTemp(airconSlider.value).replace(".0", "")
					}
				}
			}

	}
}
