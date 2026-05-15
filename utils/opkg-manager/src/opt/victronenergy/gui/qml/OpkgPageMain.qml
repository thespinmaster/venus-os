import QtQuick 2
import com.victron.velib 1.0
import OpkgManager 1.0
import "opkg-custom-service.js" as CustomService

QtObject {
 
  property VeQuickItem moveSettingsToTop: VeQuickItem {
    uid: "dbus/com.victronenergy.settings/Settings/OpkgManager/CustomMenus/PageMain/PageSettings"
    onValueChanged: movePageSettingsToTop()
  }	
 
  property VeQuickItem vItem: VeQuickItem {}
 
  function onBeforeCreateDevicePage(service, page) {
    // console.log("onBeforeCreateDevicePage:" + service.name + ", page:" + page) 

    var serviceName = service.name
  
    if (!CustomService.isCustomService(service))
      return page
 
    vItem.uid = "dbus/" + serviceName + "/CustomDevicePage"
    vItem.getValue(true)
    var customPageName = vItem.value
    vItem.uid = ""
    if (customPageName === undefined)
      return page
 
    var customPage = Qt.createComponent(customPageName + ".qml")
    if (customPage.status === Component.Error) {
      console.log("ERROR loading " + customPageName + ": " + customPage.errorString())
      return page
    }
    if (customPage.status !== Component.Ready) {
      console.log("Component not ready for " + customPageName + ": " + customPage.status)
      return page
    }
 
    return customPage
 
  }

  function onRemoveDBusService(first, last) {
    console.log(`onRemoveDBusService: first=${first}, last=${last}`)
    
    var args = ["remove-devices"]
 
    for (var i = first; i <= last; i++) {
      var page = deviceList.page(i)
      var service = page.service
 
      if (service.connected || !CustomService.isCustomService(service))
          continue
      
      if (!CustomService.tryAddCustomService(args, service))
        continue
    }
 
    if (args.length == 1) {
      return
    }
 
    processRunner.waitForFinished() //just in case
    processRunner.start(args)
    
    console.log("removeDevice:out:" + args)
  }

  Component.onCompleted: movePageSettingsToTop()
  
  function movePageSettingsToTop() { 
    
    var action = moveSettingsToTop.value
    var fixedModel = model.get(1)

    if (action == "^") {
      // move to top
      if (fixedModel.delegate) {
        console.log("moveFixedModel: already moved")
        return // already moved or not expected
      }
        
 
    } else {
      // revert
      fixedModel = model.get(0)
      if (fixedModel.delegate) {
        console.log("moveFixedModel: already reverted")
        return // already moved or not expected
      }
    }
 
    fixedModel.move(0, 2, 1)
    model.move(0, 1, 1)
  }
 
  property ProcessRunner processRunner: ProcessRunner {
		helperPath: "/data/dev/utils/opkg-manager/src/data/opkg-manager/process-runner/serial-device-installer"
    
    onOutputLine: function(line) { 
      console.log("REMOVE:" + line)
    }
    /*
    onErrorLine: function(line) {
      console.log("ERROR:" + line)
    }
    */
  }
 
}

