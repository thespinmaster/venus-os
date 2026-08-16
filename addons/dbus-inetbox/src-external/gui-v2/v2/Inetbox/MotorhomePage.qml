import QtQuick
import Victron.VenusOS
import Victron.Gauges
import QtQuick.Controls 2.12

SwipeViewPage {
	id: root
	readonly property bool pluginReady: !GuiPluginLoader.busy && GuiPluginLoader.plugin("Inetbox").name === "Inetbox"

	//% "Motorhome"
	title: qsTrId("inetbox_motorhome")
	iconSource: "qrc:/Inetbox/images/motorhome.svg"
	url: "qrc:/Inetbox/MotorhomePage.qml"

	fullScreenWhenIdle: true
	topLeftButton: VenusOS.StatusBar_LeftButton_ControlsInactive

	Component.onCompleted: {
		console.log("Inetbox: onCompleted:",
		"page=", url,
		"version=", inetboxDevice.version,
		"device.firstObject=", devices.firstObject)
		inetboxDevice.device = devices.firstObject
	}
	Component.onDestruction: {
		console.log("Inetbox: onDestruction:", "page=", url, "version=", inetboxDevice.version)
	}

	FilteredDeviceModel {
		id: devices
		serviceTypes: ["inetbox"]
		function onFirstObjectChanged() {
			inetboxDevice.device = devices.firstObject
		}

	}

	GaugeModel { id: tankGauges } // aka storage tanks

	Loader {
		id: pageLoader

		anchors.fill: parent
		sourceComponent: Theme.screenSize === Theme.Portrait ? portraitComponent : landscapeComponent
		focus: true

		Component {
			id: landscapeComponent

			MotorhomePage_Landscape {
				title: root.title
				inetbox: inetboxDevice
				gaugeModel: tankGauges
				animationEnabled: root.animationEnabled
			}
		}

		Component {
			id: portraitComponent

			MotorhomePage_Portrait {
				title: root.title
				inetbox: inetboxDevice
				gaugeModel: tankGauges
				animationEnabled: root.animationEnabled
			}
		}
	}

	////////////////////////////////////////////
	// Components
	////////////////////////////////////////////
	component VeQuickItemTemperature: VeQuickItem {
			sourceUnit: Units.unitToVeUnit(VenusOS.Units_Temperature_Celsius)
			displayUnit: Units.unitToVeUnit(Global.systemSettings.temperatureUnit)
	}

////////////////////////////////////////////
// Data
////////////////////////////////////////////

	QtObject {
		id: inetboxDevice

		property var device : null
		property string version: GuiPluginLoader.plugin("Inetbox").version

		property bool heatingOn: heatingModeItem.valid && heatingModeItem.value != "off"
		property bool airconOn: airconModeItem.valid && airconModeItem.value != "off"
		readonly property real targetTemperature: (heatingOn ? heatingTargetTempItem.value : airconTargetTemperatureItem.value) ?? NaN

		onHeatingOnChanged: exclusiveHeating(airconModeItem)
		onAirconOnChanged: exclusiveHeating(heatingModeItem)

		property VeQuickItemTemperature currentTemperatureItem: VeQuickItemTemperature {uid: inetboxDevice.deviceUid("CurrentRoomTemp")}
		property VeQuickItemTemperature waterCurrentTemperatureItem: VeQuickItemTemperature {uid: inetboxDevice.deviceUid("WaterCurrentTemp")}
		property VeQuickItem waterTargetTemperatureItem: VeQuickItem { uid: inetboxDevice.deviceUid("WaterTargetTemp")}
		property VeQuickItem heatingModeItem: VeQuickItem { uid: inetboxDevice.deviceUid("HeatingMode")}
		property VeQuickItemTemperature heatingTargetTempItem: VeQuickItemTemperature {uid: inetboxDevice.deviceUid("HeatingTargetTemp")}

		property VeQuickItem airconModeItem: VeQuickItem {uid: inetboxDevice.deviceUid("AirconMode")}
		property VeQuickItemTemperature airconTargetTemperatureItem: VeQuickItemTemperature { uid: inetboxDevice.deviceUid("AirconTargetTemp")}
		property VeQuickItem airconFanSpeedItem: VeQuickItem {uid: inetboxDevice.deviceUid("AirconFanSpeed")}
		property VeQuickItem energyMixItem: VeQuickItem {uid: inetboxDevice.deviceUid("EnergyMixCombined")}

		function deviceUid(value) {

			var uid = device && device.serviceUid ? (device.serviceUid + "/Values/" + value) : ""
			console.log("Inetbox: uid=",uid)
			return uid
		}

		function exclusiveHeating(itemToTurnOff) {
			console.log("MH:exclusiveHeating:", itemToTurnOff)
			if (heatingOn === true && airconOn === true)
				itemToTurnOff.setValue("off")
		}
		function updateTargetTemperature(value) {

			if (heatingOn) {
				heatingTargetTempItem.setValue(value)
			} else if (airconOn) {
				airconTargetTemperatureItem.setValue(value)
			}
		}

		property var waterModeModel: [{
					value: "0",
					//% "Off"
					valueText: qsTrId("inetbox_off"),
					color: "grey"
				}, {
					value: "40.0",
					//% "Eco"
					valueText:  qsTrId("inetbox_eco"),
					//color: "white"
				}, {
					value: "60.0",
					//% "Hot"
					valueText: qsTrId("inetbox_hot"),
					//color: "white"
				}, {
					value: "200.0",
					//% "Boost"
					valueText: qsTrId("inetbox_boost"),
					//color: "white"
				}
			]

		property var heatingModeModel: [{
					value: "off",
					//% "Off"
					valueText: qsTrId("inetbox_off"),
					color: "grey"
				}, {
					value: "eco",
					//% "Eco"
					valueText: qsTrId("inetbox_eco"),
					//color: "white"
				}, {
					value: "high",
					//% "High"
					valueText: qsTrId("inetbox_high"),
					//color: "white"
				}
			]

		property var airconModeModel: [{
				value: "off",
				//% "Off"
				valueText: qsTrId("inetbox_off"),
				color: "grey"
			}, {
				value: "cool",
				//% "Cool"
				valueText: qsTrId("inetbox_cool"),
				//color: "white"
			}, {
				value: "vent",
				//% "Vent"
				valueText:  qsTrId("inetbox_vent"),
				//color: "white"
			}, {
				value: "hot",
				//% "Hot"
				valueText: qsTrId("inetbox_hot"),
				//color: "white"
			}, {
				value: "auto",
				//% "Auto"
				valueText: qsTrId("inetbox_auto"),
				//color: "white"
			}
		]

		property var airconFanSpeedModel: [{
				value: "low",
				//% "Low"
				valueText: qsTrId("inetbox_low"),
				//color: "white"
			}, {
				value: "mid",
				//% "Mid"
				valueText: qsTrId("inetbox_mid"),
				//color: "white"
			}, {
				value: "high",
				//% "High"
				valueText: qsTrId("inetbox_high"),
				//color: "white"
			}, {
				value: "night",
				//% "Night"
				valueText: qsTrId("inetbox_night"),
				//color: "white"
			}, {
				value: "auto",
				//% "Auto"
				valueText: qsTrId("inetbox_auto"),
				//color: "lightseagreen"
			}
		]

		property var energyMixModel: [{
				value: "gas",
				//% "Gas"
				valueText: qsTrId("inetbox_gas"),
				color: Theme.colorScheme == Theme.Dark ? '#ffab03' :  '#c58300'
			}, {
				value: "mix1",
				//% "Mix1"
				valueText: qsTrId("inetbox_mix1"),
				color: "green"
			}, {
				value: "mix2",
				//% "Mix2"
				valueText: qsTrId("inetbox_mix2"),
				color: "green"
			}, {
				value: "el1",
				//% "El1"
				valueText: qsTrId("inetbox_el1"),
				color: "lightskyblue"
			}, {
				value: "el2",
				//% "El2"
				valueText: qsTrId("inetbox_el2"),
				color: "lightskyblue"
			}
		]
	}

}
