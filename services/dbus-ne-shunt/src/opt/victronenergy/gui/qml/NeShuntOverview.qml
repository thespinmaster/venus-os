import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
import "opkg-custom-service.js" as CustomService

OverviewPage {
  id: root
 
  property string settingsPrefix: "com.victronenergy.settings/Settings/Devices/dbus_neshunt/"
  property MbStyle mbStyle: MbStyle {isCurrentItem: true}
  property string vebusPrefix
 
  VBusItem { id: customNameItem; bind: vebusPrefix ? Utils.path(vebusPrefix, "/CustomName") : undefined}
  VBusItem { id: internalLightItem; bind: vebusPrefix ? Utils.path(vebusPrefix, "/SwitchableOutput/InternalLights/State") : undefined }
  VBusItem { id: externalLightItem; bind: vebusPrefix ? Utils.path(vebusPrefix, "/SwitchableOutput/ExternalLights/State") : undefined }
  VBusItem { id: waterPumpItem; bind: vebusPrefix ? Utils.path(vebusPrefix, "/SwitchableOutput/WaterPump/State") : undefined }
  VBusItem { id: auxPowerItem; bind: vebusPrefix ? Utils.path(vebusPrefix, "/SwitchableOutput/Aux/State") : undefined }
  
  VBusItem { id: internalLightCustomNameItem; bind: vebusPrefix ? Utils.path(vebusPrefix, "/SwitchableOutput/InternalLights/Settings/CustomName") : undefined }
  VBusItem { id: externalLightCustomNameItem; bind: vebusPrefix ? Utils.path(vebusPrefix, "/SwitchableOutput/ExternalLights/Settings/CustomName") : undefined }
  VBusItem { id: waterPumpCustomNameItem; bind: vebusPrefix ? Utils.path(vebusPrefix, "/SwitchableOutput/WaterPump/Settings/CustomName") : undefined }
  VBusItem { id: auxPowerCustomNameItem; bind: vebusPrefix ? Utils.path(vebusPrefix, "/SwitchableOutput/Aux/Settings/CustomName") : undefined }
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
      text: internalLightCustomNameItem.value && internalLightCustomNameItem.length > 0 || qsTr("Indoor Lights") 
      checked: internalLightItem.valid && internalLightItem.value != 0
      onCheckedChanged: { internalLightItem.setValue(checked ? 1 : 0)}
      iconId: "ne-shunt-inside-light"
    }
    LargeRoundButton {
      text: externalLightCustomNameItem.value && externalLightCustomNameItem.length > 0 || qsTr("Outdoor Light")
      checked: externalLightItem.valid && externalLightItem.value != 0
      onCheckedChanged: { externalLightItem.setValue(checked ? 1 : 0)}
      iconId: "ne-shunt-outside-light"
    }
    LargeRoundButton {
      text: waterPumpCustomNameItem.value && waterPumpCustomNameItem.length > 0 || qsTr("Water Pump")
      checked: waterPumpItem.valid && waterPumpItem.value != 0

      onCheckedChanged: { waterPumpItem.setValue(checked ? 1 : 0)}
      iconId: "ne-shunt-water-pump"
    }
    LargeRoundButton {
      text: auxPowerCustomNameItem.value && auxPowerCustomNameItem.length > 0 || qsTr("Aux Power")
      checked: auxPowerItem.valid && auxPowerItem.value != 0
      onCheckedChanged: { auxPowerItem.setValue(checked ? 1 : 0)}
      iconId: "ne-shunt-aux-power"
      longPressDuration: 3000
    }
  }

  Component.onCompleted: discoverNeShunt()
  
	Connections {
		target: DBusServices
		function onDbusServiceFound(service) { tryAddService(service) }
	}

	function tryAddService(service) {

    if (!vebusPrefix) {
      if (service.type === DBusService.DBUS_SERVICE_TEMPERATURE_SENSOR && 
          service.name.includes(".dbus_ne_shunt_cdt_")) {
        vebusPrefix = service.name
      }
    }
	}
 
	function discoverNeShunt() {
		for (var i = 0; i < DBusServices.count; i++) { 
      tryAddService(DBusServices.at(i))
    }  
	}

}