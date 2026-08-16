import QtQuick
import QtQuick.Layouts
import Victron.VenusOS

Rectangle {
	id: root

	color: Theme.color_background_secondary
	radius: Theme.geometry_button_radius
	implicitHeight: inetboxColumn.implicitHeight + inetboxColumn.anchors.margins * 2

	property alias targetTemperatureSlider: targetTemperatureSlider
	property var model
	property real buttonOffsetX: 0

	ColumnLayout {
		id: inetboxColumn
		anchors.fill: parent
		anchors.margins: 4
		// Room Temps
		RowLayout {
			id: mainTemps
			spacing: 10
			QuantityLabel {
				id: tempValue
				font.pixelSize: Theme.screenSize === Theme.Portrait ? 36 : 44
				alignment: Qt.AlignBottom
				Layout.alignment: Qt.AlignBottom
				unit: Global.systemSettings.temperatureUnit
				value: root.model.currentTemperatureItem.value ?? NaN
			}

			QuantityLabel {
				font.pixelSize: tempValue.font.pixelSize / 2
				alignment: Qt.AlignBottom
				Layout.alignment: Qt.AlignBottom
				Layout.bottomMargin: 5 // HACK QuantityLabel does not expose baseline
				value: targetTemperatureSlider.pressed ? targetTemperatureSlider.value : root.model.targetTemperature ?? NaN
				visible: root.model.heatingOn | root.model.airconOn
				unit: Global.systemSettings.temperatureUnit
				unitColor: Theme.color_overviewPage_widget_battery_font_secondary
			}

			MinimalSlider {
				id: targetTemperatureSlider
				hideTicks: false
				visible: root.model.heatingOn || root.model.airconOn
				value: root.model.targetTemperature
				Layout.alignment: Qt.AlignVCenter
				Layout.fillWidth: true

				onPressedChanged: {
					if (!pressed) // only update when button is released
						root.model.updateTargetTemperature(value);
				}
				from: root.model.heatingOn ? 5 : 16
				to: root.model.heatingOn ? 30 : 31
				stepSize: 1
			}
		}

		CycleButtonGroup {
			id: cycleButtonGroup
		}

		// Water
		RowLayout {
			id: waterRow
			Layout.topMargin: 10
			Layout.leftMargin: mainTemps.x + root.buttonOffsetX
			CycleButton {
				id: waterHeaterCycleButton
				group: cycleButtonGroup
				icon.source: "qrc:/Inetbox/images/freshwater.svg"
				binding: root.model.waterTargetTemperatureItem
				model: root.model.waterModeModel
				//% "Water"
				text: qsTrId("inetbox_energy_water")
			}
			QuantityLabel {
				//id: waterHeaterCurrentTemperature
				font.pixelSize: 24
				visible: root.model.waterCurrentTemperatureItem.valid
				unit: Global.systemSettings.temperatureUnit
				value: root.model.waterCurrentTemperatureItem.value ?? NaN
				Layout.leftMargin: Theme.screenSize === Theme.Portrait ? 0 : 40
			}
		}

		// Heating
		CycleButton {
			id: heatingCycleButton
			group: cycleButtonGroup
			icon.source: "qrc:/Inetbox/images/heating.svg"
			binding: root.model.heatingModeItem
			model: root.model.heatingModeModel
			//% "Heating"
			text: qsTrId("inetbox_energy_heating")
			Layout.leftMargin: waterRow.x + root.buttonOffsetX
		}

		// Aircon mode
		RowLayout {
			CycleButton {
				id: airconModeCycleButton
				group: cycleButtonGroup
				icon.source: "qrc:/Inetbox/images/aircon.svg"
				binding: root.model.airconModeItem
				model: root.model.airconModeModel
				//% "Aircon"
				text: qsTrId("inetbox_energy_aircon")
				Layout.leftMargin: heatingCycleButton.x + root.buttonOffsetX
			}
			Loader {
				active: Theme.screenSize !== Theme.Portrait
				Layout.leftMargin: 40
				sourceComponent: airconFanSpeedCycleButtonFactory
			}
		}
		Loader {
			active: Theme.screenSize === Theme.Portrait
			Layout.leftMargin: 40
			sourceComponent: airconFanSpeedCycleButtonFactory
		}

		Component {
			id: airconFanSpeedCycleButtonFactory
			// Aircon Fan Speed
			CycleButton {
				id: airconFanSpeedCycleButton
				group: cycleButtonGroup
				visible: root.model.airconFanSpeedItem.valid
				icon.source: "qrc:/Inetbox/images/fan.svg"
				icon.color: airconModeCycleButton.icon.color
				binding: root.model.airconFanSpeedItem
				model: root.model.airconFanSpeedModel



				//% "Fan speed"
				text: qsTrId("inetbox_energy_fan_speed")
			}
		}
		// EnergyMix
		CycleButton {
			id: energyMixButton
			group: cycleButtonGroup
			icon.source: "qrc:/Inetbox/images/energy_mix.svg"
			binding: root.model.energyMixItem
			model: root.model.energyMixModel
			//% "Energy Mix"
			text: qsTrId("inetbox_energy_mix")
			Layout.leftMargin: airconModeCycleButton.x + root.buttonOffsetX

		}
	}
}
