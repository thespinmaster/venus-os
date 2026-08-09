import QtQuick
import QtQuick.Controls as Controls
import Victron.VenusOS
import "."

// Heating
InetboxBaseWidget {
  id: root
  isLoading: !heatingModeControl.item.valid
  //% "Heating"
  headerText: qsTrId("inetbox_header_heating")
  headerIconSource: "qrc:/Inetbox/image_heating.svg"
  headerExtraContent: Item {
    id: headerHeatingModeHost
    visible: Theme.screenSize === Theme.Portrait
    implicitWidth: heatingModeControl.implicitWidth
    implicitHeight: heatingModeControl.implicitHeight
  }

  readonly property string heatingSwitchableOutputUid: root.device && root.device.serviceUid
      ? root.device.serviceUid + "/SwitchableOutput/heating"
      : ""

  SwitchableOutput {
    id: heatingSwitchableOutput
    uid: root.heatingSwitchableOutputUid
  }

  VeQuickItem {
    id: heatingMeasurement
    uid: root.heatingSwitchableOutputUid ? (root.heatingSwitchableOutputUid + "/Measurement") : ""
  }

  //border {color: groupBorderColor;width: 1}

  Item {
    id: bodyHeatingModeHost
    visible: Theme.screenSize !== Theme.Portrait
    implicitWidth: visible ? heatingModeControl.implicitWidth : 0
    implicitHeight: visible ? heatingModeControl.implicitHeight : 0
  }

  ButtonGroupControl {
    id: heatingModeControl
    parent: Theme.screenSize === Theme.Portrait ? headerHeatingModeHost : bodyHeatingModeHost
    bind: root.device && root.device.serviceUid ? (root.device.serviceUid + "/Values/HeatingMode") : ""
		anchors {
      bottomMargin:0
    }

    model: [
      //% "Off"
      {text: qsTrId("inetbox_option_off"), value:"off" },
      //% "Eco"
      {text: qsTrId("inetbox_option_eco"), value:"eco" },
      //% "High"
      {text: qsTrId("inetbox_option_high"), value:"high" }
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
    switchableOutput: heatingSwitchableOutput
    measurementText: heatingMeasurement.valid ? heatingMeasurement.value.toFixed(heatingSwitchableOutput.decimals) + Units.degreesSymbol : ""
  }

}