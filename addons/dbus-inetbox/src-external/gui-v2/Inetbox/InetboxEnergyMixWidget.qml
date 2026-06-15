import QtQuick
import Victron.VenusOS
import "."

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
      qsTrId("inetbox_option_gas"),
      //% "Mix1"
      qsTrId("inetbox_option_mix1"),
      //% "Mix2"
      qsTrId("inetbox_option_mix2"),
      //% "El1"
      qsTrId("inetbox_option_el1"),
      //% "El2"
      qsTrId("inetbox_option_el2")
    ]
    valueMapping: ["Gas", "Mix1", "Mix2", "EL1", "EL2"]
  }
}
