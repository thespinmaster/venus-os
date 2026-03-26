import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils

OverviewPage {
  id: root
 
  property string settingsPrefix: "com.victronenergy.settings/Settings/Devices/dbus_neshunt/"
  property MbStyle mbStyle: MbStyle {isCurrentItem: true}
  
  VBusItem { id: customNameItem; bind: Utils.path(inetboxPrefix, "/CustomName") }
  
    // Header
    Text {
        id: header
        text: customNameItem.value || qsTr("Ne-Shunt")
        color: mbStyle.textColor
        font.bold: true
        font.pixelSize: 14
        //font.bold: true
        anchors {
          top: parent.top
          left: parent.left
          topMargin: 4
          horizontalCenter: parent.horizontalCenter
        }
        horizontalAlignment: Text.AlignHCenter
    }

    // Centered row of 4 LargeRoundButton instances
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      spacing: 20

      LargeRoundButton {
        text: "Indoor Lights"
        iconId: "ne-shunt-inside-light"
      }
      LargeRoundButton {
        text: "Outside Light"
        iconId: "ne-shunt-outside-light"
      }
      LargeRoundButton {
        text: "Water Pump"
        iconId: "ne-shunt-water-pump"
      }
      LargeRoundButton {
        text: "Aux Power"
        iconId: "ne-shunt-aux-power"
        longPressDuration: 3000
      }
    }
 
}