import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
import QtQuick.Controls

OverviewPage {
		id: root

	property string settingsPrefix: "com.victronenergy.settings/Settings/Devices/dbus_inetbox/"
 
	property string inetboxPrefix
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
	VBusItem { id: themeItem; bind: Utils.path(settingsPrefix, "Theme"); onValueChanged: applyTheme() }

  VBusItem { id: showAirconItem; bind: Utils.path(settingsPrefix, "ShowAircon") }
  //VBusItem { id: metricItem; bind: Utils.path(settingsPrefix, "Metric") }
 
	property MbStyle mbStyle: MbStyle {}
	Component.onCompleted: {
		applyTheme()
		discoverInetboxService()
	}
	
	Connections {
		target: DBusServices
		function onDbusServiceFound(service) { tryAddService(service) }
	}

	function applyTheme() {
		if (!themeItem.valid || themeItem.value.length == 0)
			return
 
		//console.log("applyTheme:" + themeName)

		switch (themeItem.value) {
		case "dark":
			backgroundColor = "#181818"
			fontColor = "#FFFFFF"
			groupBackgroundColor = "#313131"//"#1C3749"
			headerFontColor = "#FFFFFF"
			selectedColor = "#4790d0"
			selectedTextColor = "#FFFFFF"
			break
		case "veBlue1":
			backgroundColor = "#4790d0"
			fontColor = "#4891CC"
			groupBackgroundColor = "#f0f2f5"
			headerFontColor = "#FFFFFF"
			selectedColor = "#4790d0"
			selectedTextColor = "#FFFFFF"
			break
		case "veBlue2":
			backgroundColor = "#FFFFFF"
			fontColor = "#FFFFFF"
			groupBackgroundColor = "#4790d0"
			headerFontColor = "#4891CC"
			selectedColor = "#FFFFFF"
			selectedTextColor = "#4790d0"
			break
		case "light":
		default:
			backgroundColor = "#FFFFFF"
			fontColor = "#FFFFFF"
			groupBackgroundColor = "#4790d0"
			headerFontColor = "#4790d0"
			selectedColor = "#FFFFFF"
			selectedTextColor = "#4790d0"
			break
		
		
		}
	}

	function formatTemp(value, round) {
		var num = parseFloat(value)
		if (!round)
			round=0

		if (isNaN(num)) {
			return "--"
		}
		if (user.temperatureUnit === Unit.Fahrenheit) {
			return (num * 9 / 5 + 32).toFixed(round) + "°F"
		}
		return num.toFixed(1) + "°C"
	}
 
	function tryAddService(service) {

		if (!inetboxPrefix && service.type === DBusService.DBUS_SERVICE_TEMPERATURE_SENSOR && 
				service.name.includes(".dbus_inetbox_cdt_")) {
			console.log("found inetbox service")
			inetboxPrefix = service.name
			return true
		}
	}
 
	function discoverInetboxService() {
		for (var i = 0; i < DBusServices.count; i++) { 
			console.log ("Service:" + DBusServices.at(i).name)
      tryAddService(DBusServices.at(i))
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
					//font.bold: true
					anchors {
						top: parent.top
						left: parent.left
						topMargin: 0
						horizontalCenter: parent.horizontalCenter
					}
					horizontalAlignment: Text.AlignHCenter
			}

			Text {
				id: heatingCurrentTempText
				text: formatTemp(heatingCurrentTempItem.value, 1)
				color: headerFontColor
				font.pixelSize: textFont
				anchors {
					top: parent.top
					topMargin: 6
					right: parent.right
					rightMargin: 6
				}
			}

			Connections {
				target: heatingCurrentTempItem
				function onValueChanged() {
					heatingCurrentTempText.text = formatTemp(heatingCurrentTempItem.value,1)
				}
			}

      // Water
			Rectangle {
				id: waterControlContainer
				anchors {
					top: header.bottom
					topMargin: 2
					left: parent.left
					leftMargin: 8
				}
				width: parent.width / 2.2 - 16
				height: buttonControl.height + 40
				color: groupBackgroundColor
				radius: 12

				Text {
					text: "Water"
					color: fontColor
					font.pixelSize: groupFont
					//font.bold: true
					anchors {
						top: parent.top
						topMargin: 6
						left: parent.left
						leftMargin: 6
					}
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
					anchors {
						top: parent.top
						topMargin: 30
						left: parent.left
						leftMargin: 6
						right: waterCurrentTempDisplay.left
						rightMargin: 6
					}
 
				}

				Text {
					id: waterCurrentTempDisplay
					text: formatTemp(waterCurrentTempItem.value)
					color: fontColor
					font.pixelSize: textFont
					anchors {
						top: parent.top
						topMargin: 6
						right: parent.right
						rightMargin: 6
					}
					Connections {
						target: waterCurrentTempItem
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
				anchors {
					top: waterControlContainer.top
					topMargin: waterControlContainer.topMargin
					left: waterControlContainer.right
					leftMargin: 8
				}
				width: parent.width / 1.8 - 12
				height: energyMixButtonControl.height + 40
				color: groupBackgroundColor
				radius: 12

				Text {
					text: "Energy Mix"
					color: fontColor
					font.pixelSize: groupFont
					//font.bold: true
					anchors {
						top: parent.top
						topMargin: 6
						left: parent.left
						leftMargin: 6
					}
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
					anchors {
						left: parent.left
						leftMargin: 6
						right: parent.right
						rightMargin: 6
						top: parent.top
						topMargin: 30
					}
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
				anchors {
					top: waterControlContainer.bottom
					topMargin: 10
					left: parent.left
					leftMargin: 8
				}
				width: waterControlContainer.width
				height: heatingButtonControl.height + heatingSlider.height + 70
				color: groupBackgroundColor
				
				radius: 12

				Text {
					text: "Heating"
					color: fontColor
					font.pixelSize: groupFont
					//font.bold: true
					anchors {
						top: parent.top
						topMargin: 6
						left: parent.left
						leftMargin: 6
					}
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
					anchors {
						left: parent.left
						leftMargin: 6
						right: parent.right
						rightMargin: 6
						top: parent.top
						topMargin: 30
					}
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
					anchors {
						top: heatingButtonControl.bottom
						topMargin: 10
						left: parent.left
						leftMargin: 6
					}
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
					anchors {
						left: parent.left
						leftMargin: 6
						right: tempValueLabel.left
						rightMargin: 4
						top: heatingButtonControl.bottom
						topMargin: 30
						
					}
			}

			Text {
				id: tempValueLabel
				text: formatTemp(heatingSlider.value,0)
				color: fontColor
				font.pixelSize: textFont
				anchors {
						right: parent.right
						rightMargin: 6
						top: heatingButtonControl.bottom
						topMargin: 29
						verticalCenter: heatingSlider.verticalCenter
				}
			}

		}

		// Aircon
		Rectangle {
			id: airconControlContainer
			visible: !!showAirconItem.value
			anchors {
				top: waterControlContainer.bottom
				topMargin: 10
				left: heatingControlContainer.right
				leftMargin: 8
			}
			width: energyMixControlContainer.width
			height: airconHeader.height + airconModeButtonControl.height + airconFanButtonControl.height + airconTargetTemp.height + airconSlider.height + 50
			color: groupBackgroundColor
			radius: 12

			Text {
				id: airconHeader
				text: "Aircon"
				color: fontColor
				font.pixelSize: groupFont
				//font.bold: true
				anchors {
					top: parent.top
					topMargin: 6
					left: parent.left
					leftMargin: 6
				}
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
				anchors {
					left: parent.left
					leftMargin: 6
					right: parent.right
					rightMargin: 6
					top: parent.top
					topMargin: 30
				}
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
				anchors {
					left: parent.left
					leftMargin: 6
					right: parent.right
					rightMargin: 6
					top: airconModeButtonControl.bottom
					topMargin: 12
				}
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
				anchors {
					top: airconFanButtonControl.bottom
					topMargin: 10
					left: parent.left
					leftMargin: 6
				}
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
				anchors {
					left: parent.left
					leftMargin: 6
					right: airconTempValueLabel.left
					rightMargin: 4
					top: airconFanButtonControl.bottom
					topMargin: 30
				}
			}

			Text {
					id: airconTempValueLabel
					text: formatTemp(airconSlider.value,0).replace(".0", "")
					color: fontColor
					font.pixelSize: textFont
					anchors {
						leftMargin: 6
						right: parent.right
						rightMargin: 6
						top: airconFanButtonControl.bottom
						topMargin: 29
						verticalCenter: airconSlider.verticalCenter
					}
				}

			}

	}
}
