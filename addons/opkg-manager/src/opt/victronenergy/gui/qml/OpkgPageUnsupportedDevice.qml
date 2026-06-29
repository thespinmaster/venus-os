import QtQuick 2
import "opkg-custom-device.js" as CustomDevice

QtObject {

  Component.onCompleted: {

    var setup_menu = create_custom_setup_menu()
    var model = root.model
    if (model.count > 0)
      model.remove(0)

    if (setup_menu) {
      model.insert(0,setup_menu)
    }
  }

  property VeQuickItem vItem: VeQuickItem {}

  function create_custom_setup_menu() {

    var serviceName = root.service.name

    //console.log("create_custom_setup_menu:" + serviceName)

    if (!CustomDevice.isCustomService(root.service))
      return null

    vItem.uid = "dbus/" + serviceName + "/CustomDevicePage"
    vItem.getValue(true)
    var customSetupMenuName = vItem.value
    vItem.uid = ""
    if (customSetupMenuName === undefined)
      return null

    var customSetupMenu = Qt.createComponent(customSetupMenuName + ".qml")
    if (customSetupMenu.status === Component.Error) {
      console.log("ERROR loading " + customSetupMenuName + ": " + customSetupMenu.errorString())
      return null
    }
    if (customSetupMenu.status !== Component.Ready) {
      console.log("Component not ready for " + customSetupMenuName + ": " + customSetupMenu.status)
      return null
    }

    var instance = customSetupMenu.createObject(root,{root: root})

    return instance

  }

}