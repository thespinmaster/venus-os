pragma ComponentBehavior: Bound
import QtQuick 2
import com.victron.velib 1.0
import "opkg-custom-device.js" as CustomDevice

QtObject {
	id: root

  property var deviceList

  property Connections dlConn: Connections {
    target: root.deviceList
    function onRowsAboutToBeRemoved(parent, first, last) {
      root.onRemoveDBusService(first, last)
    }
  }

  property OpkgBridge opkgBridge: OpkgBridge {
    onOutput: function(line) {
      //console.log("REMOVE:" + line)
    }
    onError: function(line) {
      //console.log("ERROR:" + line)
    }
  }

  property VeQuickItem moveSettingsToTop: VeQuickItem {
    uid: "dbus/com.victronenergy.settings/Settings/OpkgManager/CustomMenus/PageMain/PageSettings"
    onValueChanged: root.movePageSettingsToTop()
  }

  function onRemoveDBusService(first, last) {
    console.log(`onRemoveDBusService: first=${first}, last=${last}`)

    var args = ["device", "remove", "all"]

    for (var i = first; i <= last; i++) {
      var page = deviceList.page(i)
      var service = page.service

      if (service.connected || !CustomDevice.isCustomDevice(service))
          continue

      if (!CustomDevice.tryAddCustomDevice(args, service))
        continue
    }

    if (args.length == 1) {
      return
    }

    opkgBridge.waitForFinished() //just in case
    opkgBridge.start(args)

    console.log("removeDevice:out:" + args)
  }

  Component.onCompleted: movePageSettingsToTop()

  function movePageSettingsToTop() {

    var action = root.moveSettingsToTop.value
    var fixedModel = model.get(1)

    if (action == "^") {
      // move to top
      if (fixedModel.delegate) {
        // console.log("moveFixedModel: already moved")
        return // already moved or not expected
      }


    } else {
      // revert
      fixedModel = model.get(0)
      if (fixedModel.delegate) {
        //console.log("moveFixedModel: already reverted")
        return // already moved or not expected
      }
    }

    fixedModel.move(0, 2, 1)
    model.move(0, 1, 1)
  }



}
