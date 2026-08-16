import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.impl as CP
import Victron.VenusOS
import Victron.Gauges
import "./components" as IC

Page {
	id: root

	required property var inetbox
	required property bool animationEnabled
	required property GaugeModel gaugeModel

	property string image_boat_glow: "qrc:/images/boat_glow.png"

	// Tank Levels
	RowLayout {
		id: mainRow
		spacing: 20

		anchors {
			left: parent.left
			leftMargin: 20
			right: parent.right
		}
		IC.MotorhomeTankLevels {
			model: root.gaugeModel
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.preferredWidth: 0.8
		}
		IC.MotorhomePower {
			Layout.fillWidth: true
			animationEnabled: root.animationEnabled
		}
	}

	Component {
		id: dateSelectorDialog
		DateSelectorDialog {}
	}

	//  width: 225
	//  otation: 250.5
  //  topMargin: root.inetboxOffsetY + 198

	IC.ScheduleButton {
		icon.source: "qrc:/images/icon_manualstart_timer_24.svg"
		mainColor: '#387dc5'
		anchors {
			right: bg_image2.right
			rightMargin: 200
			top: bg_image2.top
			topMargin: 50
		}

		onClicked: {
			Global.dialogLayer.open(dateSelectorDialog)
			return
		}
	}

	ColumnLayout {
		anchors {
			left: parent.left; leftMargin: 40
			top: mainRow.bottom; topMargin: 10
			right: bg_image.right
			bottom: bg_image.bottom; bottomMargin:40
		}

		IC.MotorhomeInetbox {
			model: root.inetbox
			color: "transparent"
			targetTemperatureSlider.hideTicks: Theme.screenSize !== Theme.Portrait
			buttonOffsetX: 30
			Layout.fillHeight: true
			Layout.fillWidth: true
			Layout.leftMargin: 80
		}
	}

	// // Room Temps
	// ColumnLayout {
	// 	id: mainTemps
	// 	anchors {
	// 		top: mainRow.bottom
	// 		left: parent.left
	// 		leftMargin: 40
	// 		topMargin: 10
	// 	}
	// 	QuantityLabel {
	// 		id: tempValue
	// 		font.pixelSize: 44
	// 		unit: Global.systemSettings.temperatureUnit

	// 		value: inetbox.currentTemperatureItem.value ?? NaN
	// 	}

	// 	QuantityLabel {
	// 		font.pixelSize: 24
	// 		value: targetTemperatureSlider.pressed ? targetTemperatureSlider.value : inetbox.targetTemperature ?? NaN
	// 		visible: inetbox.heatingOn | inetbox.airconOn
	// 		unit: Global.systemSettings.temperatureUnit
	// 		unitColor: Theme.color_overviewPage_widget_battery_font_secondary
	// 	}
	// }

	// IC.CycleButtonGroup {
	// 	id: cycleButtonGroup
	// }

	// // Water
	// IC.CycleButton {
	// 	id: waterHeaterCycleButton
	// 	group: cycleButtonGroup
	// 	icon.source: "qrc:/Inetbox/images/freshwater.svg"
	// 	//% "Water"
	// 	text: qsTrId("inetbox_energy_water")
	// 	binding: inetbox.waterTargetTemperatureItem
	// 	anchors {
	// 		left: parent.left
	// 		leftMargin: 150
	// 		top: mainRow.bottom
	// 		topMargin: root.inetboxOffsetY
	// 	}
	// 	model: inetbox.waterModeModel
	// }
	// QuantityLabel {
	// 	//id: waterHeaterCurrentTemperature
	// 	font.pixelSize: 24
	// 	visible: inetbox.waterCurrentTemperatureItem.valid
	// 	unit: Global.systemSettings.temperatureUnit
	// 	value: inetbox.waterCurrentTemperatureItem.value ?? NaN
	// 	anchors {
	// 		left: waterHeaterCycleButton.right
	// 		verticalCenter: waterHeaterCycleButton.verticalCenter
	// 	}
	// }
	// // Heating
	// IC.CycleButton {
	// 	id: heatingCycleButton
	// 	group: cycleButtonGroup
	// 	icon.source: "qrc:/Inetbox/images/heating.svg"
	// 	binding: root.inetbox.heatingModeItem

	// 	//% "Heating"
	// 	text: qsTrId("inetbox_energy_heating")
	// 	anchors {
	// 		left: waterHeaterCycleButton.left
	// 		leftMargin: root.buttonOffsetX
	// 		top: waterHeaterCycleButton.bottom
	// 		topMargin: root.buttonOffsetY
	// 	}
	// 	model: root.inetbox.heatingModeModel
	// }
	// // Aircon mode
	// IC.CycleButton {
	// 	id: airconModeCycleButton
	// 	group: cycleButtonGroup
	// 	icon.source: "qrc:/Inetbox/images/aircon.svg"
	// 	binding: root.inetbox.airconModeItem
	// 	//% "Aircon"
	// 	text: qsTrId("inetbox_energy_aircon")
	// 	anchors {
	// 		left: heatingCycleButton.left
	// 		leftMargin: root.buttonOffsetX
	// 		top: heatingCycleButton.bottom
	// 		topMargin: root.buttonOffsetY
	// 	}
	// 	model: root.inetbox.airconModeModel
	// }
	// // Aircon Fan Speed
	// IC.CycleButton {
	// 	id: airconFanSpeedCycleButton
	// 	group: cycleButtonGroup
	// 	visible: root.inetbox.airconFanSpeedItem.valid
	// 	icon.source: "qrc:/Inetbox/images/fan.svg"
	// 	icon.color: airconModeCycleButton.icon.color
	// 	binding: root.inetbox.airconFanSpeedItem
	// 	//% "Fan speed"
	// 	text: qsTrId("inetbox_energy_fan_speed")

	// 	anchors {
	// 		left: airconModeCycleButton.right
	// 		top: airconModeCycleButton.top
	// 	}
	// 	model: root.inetbox.airconFanSpeedModel
	// }
	// // EnergyMix
	// IC.CycleButton {
	// 	id: energyMixButton
	// 	group: cycleButtonGroup
	// 	icon.source: "qrc:/Inetbox/images/energy_mix.svg"
	// 	binding: root.inetbox.energyMixItem
	// 	//% "Energy Mix"
	// 	text: qsTrId("inetbox_energy_mix")

	// 	anchors {
	// 		left: airconModeCycleButton.left
	// 		leftMargin: root.buttonOffsetX //* root.xOffset
	// 		top: airconModeCycleButton.bottom
	// 		topMargin: root.buttonOffsetY
	// 	}
	// 	model: root.inetbox.energyMix
	// }

	// version
	Label {
		color: "grey"
		anchors {
			right: parent.right
			rightMargin: 50
			bottom: bg_image.bottom
		}
		text: root.inetbox.version
	}

	// left image
	CP.ColorImage {
		id: bg_image
		height: 370
		mirror: true
		rotation: 180
		source:root.image_boat_glow
		width: 800
		z: -1
		anchors {
			left: parent.left
			leftMargin: 20
			top: mainRow.bottom
			topMargin: -35
		}
	}

	//right image
	CP.ColorImage {
		id: bg_image2
		height: 370
		mirror: true
		//rotation: 180
		source: root.image_boat_glow
		width: 800
		z: -1
		anchors {
			right: parent.right
			leftMargin: 20
			top: mainRow.bottom
			topMargin: 50
		}
	}
}
