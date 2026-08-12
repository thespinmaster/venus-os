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

	ColumnLayout {
		id: mainRow
		spacing: 10
		anchors {
			left: parent.left
			leftMargin: 15
			right: parent.right
			rightMargin: 15
		}

		IC.MotorhomeTankLevels {
			model: root.gaugeModel
			Layout.fillWidth: true
		}

		// Power
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
						Layout.fillHeight: true
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

		Rectangle {
			Layout.fillWidth: true
			implicitHeight: inetboxColumn.implicitHeight + inetboxColumn.anchors.margins * 2
			color: Theme.color_background_secondary
			radius: Theme.geometry_button_radius

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
						font.pixelSize: 36
						alignment: Qt.AlignBottom
						Layout.alignment: Qt.AlignBottom
						unit: Global.systemSettings.temperatureUnit
						value: inetbox.currentTemperatureItem.value ?? NaN
					}

					QuantityLabel {
						font.pixelSize: 18
						alignment: Qt.AlignBottom
						Layout.alignment: Qt.AlignBottom
						Layout.bottomMargin: 5 // HACK QuantityLabel does not expose baseline
						value: targetTemperatureSlider.pressed ? targetTemperatureSlider.value : inetbox.targetTemperature ?? NaN
						visible: inetbox.heatingOn | inetbox.airconOn
						unit: Global.systemSettings.temperatureUnit
						unitColor: Theme.color_overviewPage_widget_battery_font_secondary
					}

					IC.MinimalSlider {
						id: targetTemperatureSlider
						hideTicks: false
						visible: inetbox.heatingOn || inetbox.airconOn
						value: inetbox.targetTemperature
						Layout.alignment: Qt.AlignVCenter
						Layout.fillWidth: true

						onPressedChanged: {
							if (!pressed) // only update when button is released
								inetbox.updateTargetTemperature(value);
						}
						from: inetbox.heatingOn ? 5 : 16
						to: inetbox.heatingOn ? 30 : 31
						stepSize: 1
					}
				}

				IC.CycleButtonGroup { id: cycleButtonGroup }

				// Water
				RowLayout {
					Layout.topMargin: 10
					IC.CycleButton {
						id: waterHeaterCycleButton
						group: cycleButtonGroup
						icon.source: "qrc:/Inetbox/images/freshwater.svg"
						binding: inetbox.waterTargetTemperatureItem
						model: inetbox.waterModeModel
						//% "Water"
						text: qsTrId("inetbox_option_energy_water")
					}
					QuantityLabel {
						//id: waterHeaterCurrentTemperature
						font.pixelSize: 24
						visible: inetbox.waterCurrentTemperatureItem.valid
						unit: Global.systemSettings.temperatureUnit
						value: inetbox.waterCurrentTemperatureItem.value ?? NaN
					}
				}

				// Heating
				IC.CycleButton {
					id: heatingCycleButton
					group: cycleButtonGroup
					icon.source: "qrc:/Inetbox/images/heating.svg"
					binding: inetbox.heatingModeItem
					model: inetbox.heatingModeModel
					//% "Heating"
					text: qsTrId("inetbox_option_energy_heating")
				}

				// Aircon mode
				IC.CycleButton {
					id: airconModeCycleButton
					group: cycleButtonGroup
					icon.source: "qrc:/Inetbox/images/aircon.svg"
					binding: inetbox.airconModeItem
					model: inetbox.airconModeModel
					//% "Aircon"
					text: qsTrId("inetbox_option_energy_aircon")
				}

				// Aircon Fan Speed
				IC.CycleButton {
					id: airconFanSpeedCycleButton
					group: cycleButtonGroup
					visible: inetbox.airconFanSpeedItem.valid
					icon.source: "qrc:/Inetbox/images/fan.svg"
					icon.color: airconModeCycleButton.icon.color
					binding: inetbox.airconFanSpeedItem
					model: inetbox.airconFanSpeedModel
					Layout.leftMargin: 40
					//% "Fan speed"
					text: qsTrId("inetbox_option_energy_fan_speed")
				}

				// EnergyMix
				IC.CycleButton {
					id: energyMixButton
					group: cycleButtonGroup
					icon.source: "qrc:/Inetbox/images/energy_mix.svg"
					binding: inetbox.energyMixItem
					model: inetbox.energyMixModel
					//% "Energy Mix"
					text: qsTrId("inetbox_option_energy_mix")
				}
			}
		}
	}
}
