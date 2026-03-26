import QtQuick 2
import com.victron.velib 1.0

QtObject {

  property VeQuickItem moveSettingsToTop: VeQuickItem {
    uid: "dbus/com.victronenergy.settings/Settings/OpkgManager/CustomMenus/PageMain/PageSettings"
    onValueChanged: movePageSettingsToTop()
  }	

  function getTopModel(createIfNotFound) {
    var models = model.models
    //console.log("getTopModel:models.length:" + models.length)
    for (var i = 0; i < models.length; i++) {
      var viewModel = models[i]
      //console.log("getTopModel:viewModel.objectName:" + viewModel.objectName)
      if (viewModel.objectName == "opkgSettingsModel")
        return viewModel
    }
    if (createIfNotFound === true) {
      //console.log("getTopModel:createQmlObject")
      var topModel = Qt.createQmlObject('import com.victron.velib 1.0; VisibleItemModel {objectName:"opkgSettingsModel"}', root);
      model.insert(0, topModel)
      return topModel
    }
  }

  function findPageMainIndex(viewModel) {
    for (var i = 0; i < viewModel.count; i++) {
      var item = viewModel.get(i)
      if (item.subpage && item.subpage.url) {
        var urlObj=item.subpage.url.toString()
        if (urlObj.endsWith("/PageMain.qml")) {
          return i
        }
      }
    }
    return -1
  }

  function movePageSettingsToTop() {
    if (model == undefined) {
      //console.log("movePageSettingsToTop:model:undefined")
      return
    }

    var action = moveSettingsToTop.value
    //console.log("movePageSettingsToTop:action:" + action)

    if (action == "") {
      var topModel = getTopModel(false)
      if (topModel === undefined) {
        //console.log("movePageSettingsToTop:topModel:undefinded: exiting" )
        return
      }
        
      var models = model.models
      var bottemModel = models[models.length-1]
      var pageMainIndex = findPageMainIndex(topModel)
      if (pageMainIndex == -1) {
        //console.log("movePageSettingsToTop:topModel:pageMainIndex=-1: exiting" )
        return
      }
        
      var pageMain = topModel.get(pageMainIndex)
      topModel.remove(pageMainIndex)
      bottemModel.append(pageMain)
      //console.log("pageMain:" + pageMain)
      //console.log("bottemModel:" + bottemModel)
      //console.log("movePageSettingsToTop:restored settings page: exiting" )
      return
    }

    if (action == undefined || !(action == "^" || action == "-")) {
      //console.log("movePageSettingsToTop:action: exiting")
      return
    }
 
    var models = model.models
    var bottemModel = models[models.length-1]
    var pageMainIndex = findPageMainIndex(bottemModel)
 
    if (pageMainIndex === -1) {
      //console.log("movePageSettingsToTop:bottemModel:pageMainIndex=-1: exiting" )
      return
    }

    var pageMain = bottemModel.get(pageMainIndex)
    bottemModel.remove(pageMainIndex)
    if (action == "-") {
      //console.log("movePageSettingsToTop:action: exiting" )
      return
    }
    //console.log("movePageSettingsToTop:appending" )
    var topModel = getTopModel(true)
    //console.log("movePageSettingsToTop:topModel:" + topModel )
    topModel.append(pageMain)
    
    //console.log("pageMain:" + pageMain)
    //console.log("bottemModel:" + bottemModel)
  }

  Component.onCompleted: movePageSettingsToTop()

}

