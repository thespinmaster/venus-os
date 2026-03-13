import QtQuick 2
import "opkg-utils.js" as OpkgUtils

QtObject {
	
	//dbus -y com.victronenergy.settings /Settings AddSetting OpkgManager/CustomPageSettingsMenuItems MySubMenu '' s 0 0 0
  property VBusItem customMenuItems: VBusItem { bind: "com.victronenergy.settings/Settings/OpkgManager/CustomPageSettingsMenuItems" }
 
	Component.onCompleted: addOpkgSettingsSubMenu()
 
	property Connections connection: Connections {
		target: customMenuItems
		function onValueChanged() {
 
			//console.log("OpkgPageSettingsCustomMenus:onValueChanged")
			addRemoveItems("onValueChanged")
		}
	}
 
	function addRemoveItems() {
		OpkgUtils.addRemoveCustomModelItems(customMenuItems, getSubMenuItemIndex, addRemoveItem);
	}
 
	function addOpkgSettingsSubMenu() {
		//console.log("generalItem.parentItem:"+ generalItem.parentItem==undefined)
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
				var instance = component.createObject(null)
				model.insert(0,instance) //temporary
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
			var instance = component.createObject(listview)
			if (!instance) { 
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
			model.append(instance)
		} else {
			model.insert(index, instance)
		}
	}

	function getSubMenuItemIndex(description) {
		for (var i = 0; i < model.count; i++)
			if (model.get(i).description === description)
				return i
		return -1
	}
 
}
 