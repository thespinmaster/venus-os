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
      {text: qsTrId("inetbox_option_off"), value: "off" },
      //% "Vent"
      {text: qsTrId("inetbox_option_vent"), value: "vent" },
      //% "Cool"
      {text: qsTrId("inetbox_option_cool"), value: "cool" },
      //% "Hot"
      {text: qsTrId("inetbox_option_hot"), value: "hot" },
      //% "Auto"
      {text: qsTrId("inetbox_option_auto"), value: "auto" }
    ]
  }

  ButtonGroupControl {
    bind: root.device && root.device.serviceUid ? (root.device.serviceUid + "/Values/AirconFanSpeed") : ""
		model: [
      //% "Low"
      {text: qsTrId("inetbox_option_low"), value: "low" },
      //% "Mid"
      {text: qsTrId("inetbox_option_mid"), value: "mid" },
      //% "High"
      {text: qsTrId("inetbox_option_high"), value: "high" },
      //% "Night"
      {text: qsTrId("inetbox_option_night"), value: "night" },
      //% "Auto"
      {text: qsTrId("inetbox_option_auto"), value: "auto" }
    ]
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
    icon.source: "qrc:/Inetbox/image_temperature.svg"
  }

  TemperatureSlider {
    width: parent.width
    snapMode: Controls.Slider.SnapAlways
    switchableOutput: airconSwitchableOutput

    measurementText: airconMeasurement.valid ? airconMeasurement.value.toFixed(airconSwitchableOutput.decimals) + Units.degreesSymbol : ""

  }

}