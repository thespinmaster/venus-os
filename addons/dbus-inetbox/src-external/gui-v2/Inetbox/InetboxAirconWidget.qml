import QtQuick
import QtQuick.Controls as Controls
import Victron.VenusOS
import "."

// Aircon
InetboxBaseWidget {
	id: root
  isLoading: !airconModeButtonControl.item.valid
  //% "Aircon"
  headerText: qsTrId("inetbox_header_aircon")
  headerIconSource: "qrc:/Inetbox/image_aircon.svg"

	//border {color: groupBorderColor;width: 1}

  readonly property string airconSwitchableOutputUid: root.device && root.device.serviceUid
      ? root.device.serviceUid + "/SwitchableOutput/aircon"
      : ""

  SwitchableOutput {
    id: airconSwitchableOutput
    uid: root.airconSwitchableOutputUid
  }

  VeQuickItem {
    id: airconMeasurement
    uid: root.airconSwitchableOutputUid ? (root.airconSwitchableOutputUid + "/Measurement") : ""
  }

  ButtonGroupControl {
    id: airconModeButtonControl
    bind: root.device && root.device.serviceUid ? (root.device.serviceUid + "/Values/AirconMode") : ""
		model: [
      //% "Off"
      qsTrId("inetbox_option_off"),
      //% "Vent"
      qsTrId("inetbox_option_vent"),
      //% "Cool"
      qsTrId("inetbox_option_cool"),
      //% "Hot"
      qsTrId("inetbox_option_hot"),
      //% "Auto"
      qsTrId("inetbox_option_auto")
    ]
		valueMapping: ["off", "vent", "cool", "hot", "auto"]
  }

  ButtonGroupControl {
    bind: root.device && root.device.serviceUid ? (root.device.serviceUid + "/Values/AirconFanSpeed") : ""
		model: [
      //% "Low"
      qsTrId("inetbox_option_low"),
      //% "Mid"
      qsTrId("inetbox_option_mid"),
      //% "High"
      qsTrId("inetbox_option_high"),
      //% "Night"
      qsTrId("inetbox_option_night"),
      //% "Auto"
      qsTrId("inetbox_option_auto")
    ]
		valueMapping: ["low", "mid", "high", "night", "auto"]
  }

  Item {
    width: 1
    height: Theme.screenSize === Theme.Landscape
    ? Theme.geometry_overviewPage_widget_content_topMargin
    : 0
  }

  WidgetHeader {
    //% "Target Temperature"
    text: qsTrId("inetbox_header_target_temp")
    icon.source: "qrc:/Inetbox/image_temp.svg"
  }

  TemperatureSlider {
    width: parent.width
    snapMode: Controls.Slider.SnapAlways
    switchableOutput: airconSwitchableOutput

    measurementText: airconMeasurement.valid ? airconMeasurement.value.toFixed(airconSwitchableOutput.decimals) + Units.degreesSymbol : ""

  }

}