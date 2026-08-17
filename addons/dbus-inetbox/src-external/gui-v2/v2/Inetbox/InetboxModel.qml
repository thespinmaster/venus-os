import QtQuick
import Victron.VenusOS

QtObject {
	id: root

	property string serviceUid
	property string settingsPrefix: _sidItem.valid ? Global.systemSettings.serviceUid + "/Settings/Devices/" + _sidItem.value : ""

	property VeQuickItem _sidItem: VeQuickItem {
		uid: root.serviceUid ? root.serviceUid + "/Sid" : ""
	}

	property var waterModeModel: [{
			"value": "0",
			//% "Off"
			"valueText": qsTrId("inetbox_off"),
			"color": "grey"
		}, {
			"value": "40.0",
			//% "Eco"
			"valueText": qsTrId("inetbox_eco"),
		}, {
			"value": "60.0",
			//% "Hot"
			"valueText": qsTrId("inetbox_hot"),
		}, {
			"value": "200.0",
			//% "Boost"
			"valueText": qsTrId("inetbox_boost"),
		}]

	property var heatingModeModel: [{
			"value": "off",
			//% "Off"
			"valueText": qsTrId("inetbox_off"),
			"color": "grey"
		}, {
			"value": "eco",
			//% "Eco"
			"valueText": qsTrId("inetbox_eco"),
		}, {
			"value": "high",
			//% "High"
			"valueText": qsTrId("inetbox_high"),
		}]

	property var airconModeModel: [{
			"value": "off",
			//% "Off"
			"valueText": qsTrId("inetbox_off"),
			"color": "grey"
		}, {
			"value": "cool",
			//% "Cool"
			"valueText": qsTrId("inetbox_cool"),
		}, {
			"value": "vent",
			//% "Vent"
			"valueText": qsTrId("inetbox_vent"),
		}, {
			"value": "Vent",
			"valueText": qsTrId("inetbox_hot"),
		}, {
			"value": "auto",
			//% "Auto"
			"valueText": qsTrId("inetbox_auto"),
		}]

	property var airconFanSpeedModel: [{
			"value": "low",
			//% "Low"
			"valueText": qsTrId("inetbox_low"),
		}, {
			"value": "mid",
			//% "Mid"
			"valueText": qsTrId("inetbox_mid"),
		}, {
			"value": "high",
			//% "High"
			"valueText": qsTrId("inetbox_high"),
		}, {
			"value": "night",
			//% "Night"
			"valueText": qsTrId("inetbox_night"),
		}, {
			"value": "auto",
			//% "Auto"
			"valueText": qsTrId("inetbox_auto"),
		}]

	property var energyMixModel: [{
			"value": "gas",
			//% "Gas"
			"valueText": qsTrId("inetbox_gas"),
			//"color": '#ffab03'
		}, {
			"value": "mix1",
			//% "Mix1"
			"valueText": qsTrId("inetbox_mix1"),
			//"color": "green"
		}, {
			"value": "mix2",
			//% "Mix2"
			"valueText": qsTrId("inetbox_mix2"),
			//"color": "green"
		}, {
			"value": "el1",
			//% "El1"
			"valueText": qsTrId("inetbox_el1"),
			//"color": "lightskyblue"
		}, {
			"value": "el2",
			//% "El2"
			"valueText": qsTrId("inetbox_el2"),
			//"color": "lightskyblue"
		}]
	function valueTextFromModelValue(model, value, name) {
		for (var i = 0; i < model.length; i++)
			if (value == model[i].value) {
				return model[i].valueText;
			}
		return "--";
	}
}
