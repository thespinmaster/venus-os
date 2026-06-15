import QtQuick
import Victron.VenusOS
import "."

// Water
InetboxBaseWidget {
  id: root
  isLoading: !waterModeControl.item.valid
  
  //% "Water"
  headerText: qsTrId("inetbox_header_water")
  headerIconSource: "qrc:/images/freshWater.svg"
  headerValueText: waterCurTemp.text
  headerExtraContent: Item {
    id: headerWaterModeHost
    visible: Theme.screenSize === Theme.Portrait
    implicitWidth: waterModeControl.implicitWidth
    implicitHeight: waterModeControl.implicitHeight
  }
  
  //border {color: groupBorderColor;width: 1}

  VeQuickItem {
    id: waterCurTemp
    uid: root.device && root.device.serviceUid ? (root.device.serviceUid + "/Values/WaterCurrentTemp") : ""

    sourceUnit: Units.unitToVeUnit(VenusOS.Units_Temperature_Celsius)
    displayUnit: Units.unitToVeUnit(Global.systemSettings.temperatureUnit)
  }
  
  Item {
    id: bodyWaterModeHost
    visible: Theme.screenSize !== Theme.Portrait
    implicitWidth: visible ? waterModeControl.implicitWidth : 0
    implicitHeight: visible ? waterModeControl.implicitHeight : 0
  }
 
  ButtonGroupControl {
    id: waterModeControl
    parent: Theme.screenSize === Theme.Portrait ? headerWaterModeHost : bodyWaterModeHost

    bind: root.device && root.device.serviceUid ? (root.device.serviceUid + "/Values/WaterTargetTemp") : ""
    model: [
      //% "Off"
      qsTrId("inetbox_option_off"),
      //% "Eco"
      qsTrId("inetbox_option_eco"),
      //% "Hot"
      qsTrId("inetbox_option_hot"),
      //% "Boost"
      qsTrId("inetbox_option_boost")
    ]
    valueMapping: ["0", "40.0", "60.0", "200.0"]
  }
  
}
