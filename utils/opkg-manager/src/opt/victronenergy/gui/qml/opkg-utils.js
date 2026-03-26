
.pragma library

function initCreateComponent(customItems) {
  
  if (customItems.value === undefined)
    return
 
  for (var path in customItems.value) {
    var parts = path.split("/");
    var qmlItemName = parts[parts.length - 1]; // "OpkgPageSettingsSubMenu"
    console.log("caching:" + qmlItemName + ".qml")
    var cmo=Qt.createComponent(qmlItemName + ".qml")
    cmo.destroy()
  }

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
  console.log("YYY:addRemoveCustomItemsQuick")
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
  
  console.log("YYY:addRemoveCustomItemsQuick 2")
  for (var prop in customItems.value) {
    console.log("YYY:prop:" + prop)
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
    //console.log("AAA:" + componentArgs.parent)
    var incubator = component.incubateObject(null, componentArgs.args) // incubateObject is non blocking
    //var incubator = component.incubateObject(componentArgs.parent, componentArgs.args) // in

    if (incubator.status !== 1) {
      console.error("Failed to create component instance:" + qmlFileName)
      return; 
    }
  }
  else {
    console.error("Failed to create component:", component.errorString());
    return
  }
  
  if (action == "*")
    model.get(index).show = false // if replacing just hide

  if (index==-2) {
    model.append(incubator.object)
  } else {
    model.insert(index, incubator.object)
  }
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
      console.log("invalid operation: action=" + action)
      return
  }

  if (index == -1) {
    console.log("index not found:" + qmlItemValue)
    return
  }
  
  addRemoveItemCallback(model, action, index, qmlItemName, createComponentCallback)
 
}

