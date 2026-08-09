import QtQuick
import QtQuick.Controls
import Victron.VenusOS


// EnergyMix
InetboxBaseWidget {
	id: root
	isLoading: !energyMixButtonControl.item.valid
	//% "Energy Mix"
	headerText: qsTrId("inetbox_header_energy_mix")
	headerIconSource: "qrc:/images/acloads.svg"
	headerExtraContent: Item {
		id: headerEnergyMixHost
		visible: Theme.screenSize === Theme.Portrait
		implicitWidth: energyMixButtonControl.implicitWidth
		implicitHeight: energyMixButtonControl.implicitHeight
	}

	//border {color: groupBorderColor;width: 1}

	Item {
		id: bodyEnergyMixHost
		visible: Theme.screenSize !== Theme.Portrait
		implicitWidth: visible ? energyMixButtonControl.implicitWidth : 0
		implicitHeight: visible ? energyMixButtonControl.implicitHeight : 0
	}

	ButtonGroupControl {
		id: energyMixButtonControl
		parent: Theme.screenSize === Theme.Portrait ? headerEnergyMixHost : bodyEnergyMixHost
		bind: root.device && root.device.serviceUid ? (root.device.serviceUid + "/Values/EnergyMixCombined") : ""
		model: [
			//% "Gas"
			{text: qsTrId("inetbox_option_gas"), value: "Gas"},
			//% "Mix1"
			{text: qsTrId("inetbox_option_mix1"), value: "Mix1"},
			//% "Mix2"
			{text: qsTrId("inetbox_option_mix2"), value: "Mix2"},
			//% "El1"
			{text: qsTrId("inetbox_option_el1"), value: "EL1"},
			//% "El2"
			{text: qsTrId("inetbox_option_el2"), value: "EL2"},
		]
	}
}
