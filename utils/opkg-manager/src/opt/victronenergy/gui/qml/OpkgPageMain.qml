import QtQuick 2
import com.victron.velib 1.0

QtObject {

  property VeQuickItem moveSettingsToTop: VeQuickItem {
    uid: "dbus/com.victronenergy.settings/Settings/OpkgManager/CustomMenus/PageMain/PageSettings"
    onValueChanged: movePageSettingsToTop()
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
 
    var settings = fixedModel.get(0)
    fixedModel.remove(0)
    fixedModel.append(settings)

    model.move(0, 1, 1)
  }
}

