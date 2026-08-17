import QtQuick
import Victron.VenusOS

DevicePage {
	id: root
	serviceUid: bindPrefix

	property string bindPrefix

	InetboxModel {id: inetboxModel; serviceUid: root.bindPrefix}


	settingsModel: VisibleItemModel {
		// ListText {
		// 	text: CommonWords.status
		// 	dataItem.uid: root.bindPrefix + "/State"
		// 	preferredVisible: dataItem.valid
		// 	secondaryText: {
		// 		switch (dataItem.value) {
		// 		case 0:
		// 			return CommonWords.ok
		// 		case 1:
		// 			return CommonWords.open_circuit
		// 		case 2:
		// 			//% "Short circuited"
		// 			return qsTrId("temperature_short_circuited")
		// 		case 3:
		// 			//% "Reverse polarity"
		// 			return qsTrId("temperature_reverse_polarity")
		// 		case 5:
		// 			//% "Sensor battery low"
		// 			return qsTrId("temperature_sensor_battery_low")
		// 		case 4: // status = Unknown
		// 		default:
		// 			return CommonWords.unknown_status
		// 		}
		// 	}
		// }

		ListText {
			//% "Connected"
			text: qsTrId("inetbox_connected")
			dataItem.uid: root.bindPrefix + "/Connected"
			secondaryText: dataItem.valid && dataItem.value == 1 ? CommonWords.ok : "--"
		}

		ListTemperature {
			//% "Current Room Temperature"
			text: qsTrId("inetbox_room_current_temperature")
			dataItem.uid: root.bindPrefix + "/Values/CurrentRoomTemp"
			decimals: 0
		}

		ListTemperature {
			//% "Target Room Temperature"
			text: qsTrId("inetbox_room_target_temperature")
			dataItem.uid: root.bindPrefix + "/Values/HeatingTargetTemp"
			decimals: 0
		}

		ListTemperature {
			//% "Current Water Temperature"
			text: qsTrId("inetbox_water_current_temperature")
			dataItem.uid: root.bindPrefix + "/Values/WaterCurrentTemp"
			decimals: 0
		}
		ListText {
			//% "Water"
			text: qsTrId("inetbox_energy_water")
			dataItem.uid:  bindPrefix + "/Values/WaterTargetTemp"
			secondaryText: inetboxModel.valueTextFromModelValue(inetboxModel.waterModeModel, dataItem.value)
		}

		ListText {
			//% "Heating"
			text: qsTrId("inetbox_energy_heating")
			dataItem.uid: root.bindPrefix + "/Values/HeatingMode"
			secondaryText: inetboxModel.valueTextFromModelValue(inetboxModel.heatingModeModel, dataItem.value)
		}
		ListText {
			//% "Aircon"
			text: qsTrId("inetbox_energy_aircon")
			dataItem.uid: root.bindPrefix + "/Values/HeatingMode"
			secondaryText: inetboxModel.valueTextFromModelValue(inetboxModel.airconModeModel, dataItem.value)
			preferredVisible: dataItem.valid
		}

		ListText {
			//% "Fan speed"
			text: qsTrId("inetbox_energy_fan_speed")
			dataItem.uid: root.bindPrefix + "/Values/AirconFanSpeed"
			secondaryText: inetboxModel.valueTextFromModelValue(inetboxModel.airconFanSpeedModel, dataItem.value)
			preferredVisible: dataItem.valid
		}

		ListNavigation {
			text: CommonWords.setup
			onClicked: {
				Global.pageManager.pushPage(inetboxSetupPage)
			}
		}
	}

	Component {
		id: inetboxSetupPage
		Page {
			id: root

			GradientListView {
				model: VisibleItemModel {
					ListSwitch {
						id: showAircon
						//% "Show aircon"
						text: qsTrId("inetbox_show_aircon")
						dataItem.uid: inetboxModel.settingsPrefix + "/ShowAircon"
					}
				}
			}

		}
	}
}
