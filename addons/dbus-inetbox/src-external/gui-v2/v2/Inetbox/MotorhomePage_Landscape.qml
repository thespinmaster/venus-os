import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import QtQuick.Controls.impl as CP
import Victron.VenusOS
import Victron.Gauges
import "./components" as IC

Page {
	id: root

	required property var inetbox
	required property bool animationEnabled
	required property GaugeModel gaugeModel

	property int buttonOffsetX: 30
	property int buttonOffsetY: 10
	property real xOffset: 1.2

	property real backgroundOffsetY: 20
	property real inetboxOffsetY: 100

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
		Rectangle {
			Layout.fillWidth: true
			implicitHeight: powerRow.implicitHeight + powerRow.anchors.margins * 2

			color: Theme.color_background_secondary
			radius: Theme.geometry_button_radius
			RowLayout {
				id: powerRow
				anchors.fill: parent
				anchors.margins: 4
				// Input loads
				ColumnLayout {
					id: dcInputLoads
					spacing: 1

					IC.MotorhomeGaugeQuantityRow {
						id: solarYield
						visible: Global.solarInputs.inputCount > 0
						alignment: Qt.AlignLeft | Qt.AlignTop
						icon.source: "qrc:/images/solaryield.svg"
						quantityLabel.sourceType: VenusOS.ElectricalQuantity_Source_Any
						quantityLabel.dataObject: Global.system.solar
					}

					IC.MotorhomeGaugeQuantityRow {
						id: dcInGaugeQuantity
						visible: Global.dcInputs.model.count > 0
						alignment: Qt.AlignLeft | Qt.AlignBottom
						icon.source: Global.dcInputs.model.count === 1 ? VenusOS.dcMeter_iconForType(Global.dcInputs.model.firstMeterType) : VenusOS.dcMeter_iconForMultipleTypes()
						quantityLabel.sourceType: VenusOS.ElectricalQuantity_Source_Dc
						quantityLabel.dataObject: Global.dcInputs
					}

					IC.MotorhomeGaugeQuantityRow {
						id: acInGaugeQuantity
						visible: Global.acInputs.findValidSource() !== VenusOS.AcInputs_InputSource_NotAvailable
						//visible: true
						alignment: Qt.AlignLeft | Qt.AlignVCenter
						icon.source: Global.acInputs.sourceIcon(Global.acInputs.highlightedInput?.source ?? Global.acInputs.findValidSource())
						quantityLabel.sourceType: VenusOS.ElectricalQuantity_Source_AcInputOnly
						quantityLabel.dataObject: Global.acInputs.highlightedInput
					}
				}

				// Battery
				ColumnLayout {
					IC.MotorhomeBattery {
						id: batteryWidget
						animationEnabled: root.animationEnabled
						size: VenusOS.OverviewWidget_Size_XS
						topPadding: 0
						Layout.fillWidth: true
						Layout.preferredWidth: 0
					}
				}

				// Output loads
				ColumnLayout {
					id: outputLoads
					spacing: 1

					IC.MotorhomeGaugeQuantityRow {
						id: acLoadGauge
						visible: Global.system.hasAcLoads
						alignment: Qt.AlignRight | Qt.AlignVCenter
						icon.source: "qrc:/images/acloads.svg"
						quantityLabel.sourceType: VenusOS.ElectricalQuantity_Source_Ac
						quantityLabel.dataObject: Global.system.load.ac
					}

					IC.MotorhomeGaugeQuantityRow {
						id: dcLoadGauge
						visible: Global.system.dc.hasPower
						alignment: Qt.AlignRight | Qt.AlignVCenter
						icon.source: "qrc:/images/dcloads.svg"
						quantityLabel.sourceType: VenusOS.ElectricalQuantity_Source_Dc
						quantityLabel.dataObject: Global.system.dc
					}
				}
			}
		}
	}

	// Room Temps
	ColumnLayout {
		id: mainTemps
		anchors {
			top: mainRow.bottom
			left: parent.left
			leftMargin: 40
			topMargin: 10
		}
		QuantityLabel {
			id: tempValue
			font.pixelSize: 44
			unit: Global.systemSettings.temperatureUnit

			value: inetbox.currentTemperatureItem.value ?? NaN
		}

		QuantityLabel {
			font.pixelSize: 24
			value: targetTemperatureSlider.pressed ? targetTemperatureSlider.value : inetbox.targetTemperature ?? NaN
			visible: inetbox.heatingOn | inetbox.airconOn
			unit: Global.systemSettings.temperatureUnit
			unitColor: Theme.color_overviewPage_widget_battery_font_secondary
		}
	}

	IC.MinimalSlider {
		id: targetTemperatureSlider

		visible: inetbox.heatingOn || inetbox.airconOn
		anchors {
			left: parent.left
			leftMargin: 5
			top: parent.top
			topMargin: root.inetboxOffsetY + 198
		}
		value: inetbox.targetTemperature
		//onValueChanged: inetbox.updateTargetTemperatureValue(value)
		onPressedChanged: {
			if (!pressed)
				inetbox.updateTargetTemperature(value);
				snapMode: true
		}
		from: inetbox.heatingOn ? 5 : 16
		to: inetbox.heatingOn ? 30 : 31
		stepSize: 1
		width: 225
		rotation: 250.5
	}

	IC.CycleButtonGroup {
		id: cycleButtonGroup
	}

	// Water
	IC.CycleButton {
		id: waterHeaterCycleButton
		group: cycleButtonGroup
		icon.source: "qrc:/Inetbox/images/freshwater.svg"
		//% "Water"
		text: qsTrId("inetbox_option_energy_water")
		binding: inetbox.waterTargetTemperatureItem
		anchors {
			left: parent.left
			leftMargin: 150
			top: mainRow.bottom
			topMargin: root.inetboxOffsetY
		}
		model: [{
				"value": "0",
				"valueText": qsTrId("inetbox_option_off"),
				"color": "grey"
			}, {
				"value": "40.0",
				"valueText": qsTrId("inetbox_option_eco"),
				"color": "white"
			}, {
				"value": "60.0",
				"valueText": qsTrId("inetbox_option_hot"),
				"color": "white"
			}, {
				"value": "200.0",
				"valueText": qsTrId("inetbox_option_boost"),
				"color": "white"
			}]
	}
	QuantityLabel {
		//id: waterHeaterCurrentTemperature
		font.pixelSize: 24
		visible: inetbox.waterCurrentTemperatureItem.valid
		unit: Global.systemSettings.temperatureUnit
		value: inetbox.waterCurrentTemperatureItem.value ?? NaN
		anchors {
			left: waterHeaterCycleButton.right
			verticalCenter: waterHeaterCycleButton.verticalCenter
		}
	}

	// Heating
	IC.CycleButton {
		id: heatingCycleButton
		group: cycleButtonGroup
		icon.source: "qrc:/Inetbox/images/heating.svg"
		binding: inetbox.heatingModeItem

		//% "Heating"
		text: qsTrId("inetbox_option_energy_heating")
		anchors {
			left: waterHeaterCycleButton.left
			leftMargin: root.buttonOffsetX
			top: waterHeaterCycleButton.bottom
			topMargin: root.buttonOffsetY
		}
		model: [{
				"value": "off",
				"valueText": qsTrId("inetbox_option_off"),
				"color": "grey"
			}, {
				"value": "eco",
				"valueText": qsTrId("inetbox_option_eco"),
				"color": "white"
			}, {
				"value": "high",
				"valueText": qsTrId("inetbox_option_high"),
				"color": "white"
			}]
	}
	// Aircon mode
	IC.CycleButton {
		id: airconModeCycleButton
		group: cycleButtonGroup
		icon.source: "qrc:/Inetbox/images/aircon.svg"
		binding: inetbox.airconModeItem
		//% "Aircon"
		text: qsTrId("inetbox_option_energy_aircon")
		anchors {
			left: heatingCycleButton.left
			leftMargin: root.buttonOffsetX
			top: heatingCycleButton.bottom
			topMargin: root.buttonOffsetY
		}
		model: [{
				"value": "off",
				"valueText": qsTrId("inetbox_option_off"),
				"color": "grey"
			}, {
				"value": "cool",
				"valueText": qsTrId("inetbox_option_cool"),
				"color": "white"
			}, {
				"value": "vent",
				"valueText": qsTrId("inetbox_option_vent"),
				"color": "white"
			}, {
				"value": "hot",
				"valueText": qsTrId("inetbox_option_hot"),
				"color": "white"
			}, {
				"value": "auto",
				"valueText": qsTrId("inetbox_option_auto"),
				"color": "white"
			}]
	}
	// Aircon Fan Speed
	IC.CycleButton {
		id: airconFanSpeedCycleButton
		group: cycleButtonGroup
		visible: inetbox.airconFanSpeedItem.valid
		icon.source: "qrc:/Inetbox/images/fan.svg"
		icon.color: airconModeCycleButton.icon.color
		binding: inetbox.airconFanSpeedItem
		//% "Fan speed"
		text: qsTrId("inetbox_option_energy_fan_speed")

		anchors {
			left: airconModeCycleButton.right
			top: airconModeCycleButton.top
		}
		model: [{
				"value": "low",
				"valueText": qsTrId("inetbox_option_low"),
				"color": "white"
			}, {
				"value": "mid",
				"valueText": qsTrId("inetbox_option_mid"),
				"color": "white"
			}, {
				"value": "high",
				"valueText": qsTrId("inetbox_option_high"),
				"color": "white"
			}, {
				"value": "night",
				"valueText": qsTrId("inetbox_option_night"),
				"color": "white"
			}, {
				"value": "auto",
				"valueText": qsTrId("inetbox_option_auto"),
				"color": "lightseagreen"
			}]
	}
	// EnergyMix
	IC.CycleButton {
		id: energyMixButton
		group: cycleButtonGroup
		icon.source: "qrc:/Inetbox/images/energy_mix.svg"
		binding: inetbox.energyMixItem
		//% "Energy Mix"
		text: qsTrId("inetbox_option_energy_mix")

		anchors {
			left: airconModeCycleButton.left
			leftMargin: root.buttonOffsetX //* root.xOffset
			top: airconModeCycleButton.bottom
			topMargin: root.buttonOffsetY
		}
		model: [{
				"value": "gas",
				"valueText": qsTrId("inetbox_option_gas"),
				"color": '#ffab03'
			}, {
				"value": "mix1",
				"valueText": qsTrId("inetbox_option_mix1"),
				"color": "green"
			}, {
				"value": "mix2",
				"valueText": qsTrId("inetbox_option_mix2"),
				"color": "green"
			}, {
				"value": "el1",
				"valueText": qsTrId("inetbox_option_el1"),
				"color": "lightskyblue"
			}, {
				"valueText": qsTrId("inetbox_option_el2"),
				"color": "lightskyblue"
			}]
	}

	// version
	Label {
		color: "grey"
		anchors {
			right: parent.right
			rightMargin: 50
			bottom: bg_image.bottom
		}
		text: inetbox.version
	}

	// left image
	CP.ColorImage {
		id: bg_image
		height: 380
		mirror: true
		rotation: 180
		source: image_boat_glow
		width: 800
		z: -1
		anchors {
			left: parent.left
			leftMargin: 20
			top: mainRow.bottom
			topMargin: -20
		}
	}

	//right image
	CP.ColorImage {
		id: bg_image2
		height: 380
		mirror: true
		//rotation: 180
		source: image_boat_glow
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
