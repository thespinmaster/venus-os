
//functionality
// empty (add to end) undefinded
// add at top (value is string) (top) (insert 0) ^
// add before item name (value is name) (insert index) opp +
// replace item (value starts with "+")  (insert index) opp *
// remove item (value starts with "-")  (remove index) opp -
function addRemoveCustomModelItems(customItems, getItemIndexCallback, addRemoveItemCallback) {

  if (!customItems.valid || customItems.value.length === 0) {
    return;
  }
 
  if (customItems == undefined)
    return
 
  for (var prop in customItems.value) {

    var qmlItemName = prop
    var qmlItemValue = customItems.value[qmlItemName]

    _doItemAction(qmlItemName, qmlItemValue, getItemIndexCallback, addRemoveItemCallback)
  }
}

function _doItemAction(qmlItemName, qmlItemValue, getItemIndexCallback, addRemoveItemCallback) {
  //console.log("_doItemOperation:" + qmlItemName + ", opp:" + operation + ", value:" + qmlItemValue)
  
  var index = -1
  if (!qmlItemName.endsWith(".qml")) {
    qmlItemName = qmlItemName + ".qml";
  }
  index = getItemIndexCallback(qmlItemName)
 
  if (index > -1)
    return
 
  var action = undefined
  if (qmlItemValue?.length > 0)
  {
    action = qmlItemValue[0]
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
      if (!qmlItemValue.endsWith(".qml")) {
        qmlItemValue = qmlItemValue + ".qml";
      }
      qmlItemValue = qmlItemValue.substring(1)
      index = getItemIndexCallback(qmlItemValue)
      break
    default:
      console.log("invalid operation:")
      return
  }

  if (index == -1) {
    console.log("index not found:" + qmlItemValue)
    return
  }
  
  addRemoveItemCallback(action, index, qmlItemName)
 
}

