
.pragma library

function initCreateComponent(customItems) {
  
  if (customItems.value === undefined)
    return
  
  for (var path in customItems.value) {
    var parts = path.split("/");
    var qmlItemName = parts[parts.length - 1]; // "OpkgPageSettingsSubMenu"
    //console.log("caching:" + qmlItemName + ".qml")
    var cmo=Qt.createComponent(qmlItemName + ".qml")
    cmo.destroy()
  }

}

function qmlFileExists(qmlFileName) {
  var component = Qt.createComponent(qmlFileName)
  var exists = component.status === 1

  if (!exists) {
    console.log("QML file not found or invalid: " + qmlFileName)
    console.log(component.errorString())
  }

  component.destroy()
  return exists
}

//functionality
// empty (add to end) undefinded
// add at top (value is string) (top) (insert 0) ^
// add before item name (value is name) (insert index) opp +
// replace item (value starts with "+")  (insert index) opp *
// remove item (value starts with "-")  (remove index) opp -
function addRemoveCustomItems(customItems, model, getItemIndexCallback, addRemoveItemCallback, getComponentArgs) {
  if (!customItems.valid || customItems.value.length === 0) {
    return;
  }
  addRemoveCustomItemsQuick(customItems, model, getItemIndexCallback, addRemoveItemCallback, getComponentArgs)
}

function addRemoveCustomItemsQuick(customItems, model, getItemIndexCallback, addRemoveItemCallback, getComponentArgs) {
 
  if (customItems == undefined)
    return
  
  //if (!getItemIndexCallback || !addRemoveItemCallback)
  //  throw Error("model cannot be undefinded or null") 
  
  if (!getItemIndexCallback) {
    if (!getComponentArgs)
      throw Error("getComponentArgs callback not set") 
 
    getItemIndexCallback = modelGetItemIndex 
  }
 
  if (!addRemoveItemCallback)
    addRemoveItemCallback = modelAddRemoveItem
 
  for (var prop in customItems.value) {
 
    var qmlItemName = prop
    var qmlItemValue = customItems.value[qmlItemName]
    
    _doItemAction(qmlItemName, qmlItemValue, model, getItemIndexCallback, addRemoveItemCallback, getComponentArgs)
  }
}

function modelGetItemIndex(model, description) {
  for (var i = 0; i < model.count; i++)
    if (model.get(i).description === description)
      return i
  return -1
}

function dumpInstanceProperties(instance) {
  if (!instance) {
    console.log("dumpInstanceProperties: no instance provided")
    return
  }

  Object.keys(instance).forEach(function(key) {
    try {
      var val = instance[key].toString()

      if (val.indexOf("function()") === 0)
        return
 
      console.log("instance." + key + ":", val)
    } catch (error) {
      console.log("instance." + key + ": <error reading value: " + error + ">");
    }
  })
}

function modelAddRemoveItem(model, action, index, qmlFileName, getComponentArgs) {

  if (action == "-") {
    //console.log("hiding index:" + index)
    model.get(index).show = false // if removing just hide
    return
  }
  // Component.Ready = 1

  //Must call getComponentArgs *Before* createComponent
  // some kind of invisible context causes parenting issues
 
  var component = Qt.createComponent(qmlFileName)

  if (component.status === 1) {
 
    var componentArgs = getComponentArgs()
    var instance = component.createObject(componentArgs.parent, componentArgs.args) // incubateObject is non blocking
    instance.y = -instance.height-10 //make sure the item is not initialy visible
  }
  else {
    console.error("Failed to create component:", component.errorString());
    return
  }
  
  if (action == "*")
    model.get(index).show = false // if replacing just hide

  if (index==-2) {
    //console.log("---------------------------------")
    //dumpInstanceProperties(instance)
    //console.log("---------------------------------")
    model.append(instance)
  
    //var m=model.get(model.count-2)
    //dumpInstanceProperties(m)
  } else {
    model.insert(index, instance)
  }
  //console.log("UUU:" + p.dumpItemTree())
}
 
function _doItemAction(qmlItemName, qmlItemValue, model, getItemIndexCallback, addRemoveItemCallback, createComponentCallback) {
  //console.log("_doItemOperation:" + qmlItemName + ", opp:" + operation + ", value:" + qmlItemValue)
  
  var index = -1
  var action = undefined

  if (qmlItemValue?.length > 0)
    action = qmlItemValue[0]

  if (!qmlItemName.endsWith(".qml")) {
    qmlItemName += ".qml";
  }

  switch (action) {
    case "":
    case undefined:
      index=-2 // insert at end
      break
    case "^":
      index=0 // insert at start
      break
    case "-": // remove @ item
    case "+": // insert @ item
    case "*": // replace @ item
      qmlItemValue = qmlItemValue.substring(1)
      index = getItemIndexCallback(model, qmlItemValue)
      break
    default:
      console.log("invalid operation: action='" + action + "', qmlItemName:'" + qmlItemName + "', qmlItemValue:'" + qmlItemValue + "'")
      return
  }

  if (index == -1) {
    console.log("index not found:" + qmlItemValue)
    return
  }
  
  addRemoveItemCallback(model, action, index, qmlItemName, createComponentCallback)
 
}

