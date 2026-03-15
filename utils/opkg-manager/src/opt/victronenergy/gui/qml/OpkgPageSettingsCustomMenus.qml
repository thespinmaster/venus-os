import QtQuick 2
import "opkg-utils.js" as OpkgUtils

QtObject {

	//dbus -y com.victronenergy.settings /Settings AddSetting OpkgManager/CustomPageSettingsMenuItems MySubMenu '' s 0 0 0
  property VBusItem customMenuItems: VBusItem { bind: "com.victronenergy.settings/Settings/OpkgManager/CustomPageSettingsMenuItems" }
 
	//Just declaring the type is enough for the qt compiler to
	// load the component into the cache at startup, resulting in quicker loading
	property OpkgPageSettingsSubMenu cached1: null

	Component.onCompleted: {
		Qt.callLater(addOpkgSettingsSubMenu)
	}
 
	property Connections connection: Connections {
		target: customMenuItems
		function onValueChanged() {
			Qt.callLater(addRemoveItems("onValueChanged"))
		}
	}
 
	function addRemoveItems() {
		OpkgUtils.addRemoveCustomModelItems(customMenuItems, getSubMenuItemIndex, addRemoveItem);
	}
 
	function addOpkgSettingsSubMenu() {
		var component = Qt.createComponent("OpkgPageSettingsSubMenu.qml");
		
		if (component.status === Component.Ready) {
				
				// Notes:
				// QT BUG 1
				// If we use *any* other parent than null we get parenting issues (instance overlays index 0)
				// QT BUG 2
				// If we use null without accessing the listview.children[0] (also generalItem.parent)
				// we get random crashes. We can force the crash by using calling gc() (Garbish Collection)
				// The fix is to referece the listview's first child (guessing the items container)
				// Also note that generalItem (first child) is the *only* item in the model that has its parent set.
				var container = listview.children[0]
				var incubator = component.incubateObject(container); // incubateObject is non blocking
				if (incubator.status === Component.Ready) {
					model.insert(0, incubator.object) //temporary
				}
				// model.insert(0,incubator.object) //temporary
				//model.append(instance)
				return
		}
 
		console.log("OpkgPageSettingsSubMenu.qml - Status: " + component.status + ", Error: " + component.errorString())
	}

	function addRemoveItem(action, index, qmlFileName) {
		
		if (action == "-") {
			//console.log("hiding index:" + index)
			model.get(index).show = false // if removing just hide
			return
		}

		var component = Qt.createComponent(qmlFileName);
		if (component.status === Component.Ready) {
			var constainer = listview.children[0] // see notes in addOpkgSettingsSubMenu
			var incubator = component.incubateObject(null); // incubateObject is non blocking
			//var instance = component.createObject(listview)
			if (incubator.status !== Component.Ready) {
				console.error("Failed to create component instance:" + qmlItemName); 
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

	function getSubMenuItemIndex(description) {
		for (var i = 0; i < model.count; i++)
			if (model.get(i).description === description)
				return i
		return -1
	}
 
}
 