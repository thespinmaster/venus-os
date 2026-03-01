import QtQuick 2
import "opkg-utils.js" as OpkgUtils

QtObject {
	
	//dbus -y com.victronenergy.settings /Settings AddSetting OpkgManager/CustomPageSettingsMenuItems MySubMenu '' s 0 0 0
  property VBusItem customMenuItems: VBusItem { bind: "com.victronenergy.settings/Settings/OpkgManager/CustomPageSettingsMenuItems" }
  property bool addedOpkgSettingsSubMenu: false
 
	property int calledFromOnCompleted: 0

	Component.onCompleted: function() {
 
		if (calledFromOnCompleted==0)
			calledFromOnCompleted==1

		addRemoveItems()
	}

	property Connections connection: Connections {
		target: customMenuItems
		function onValueChanged() {
  
			if (calledFromOnCompleted==1) {
				calledFromOnCompleted=2
				return
			}
 
			addRemoveItems()
		}
	}

	function addRemoveItems() {
		
		if (!addedOpkgSettingsSubMenu) {
			addedOpkgSettingsSubMenu=true
			addOpkgSettingsSubMenu()
		}
 
		OpkgUtils.addRemoveCustomModelItems(customMenuItems, getSubMenuItemIndex, addRemoveItem);
	}
	

	function addOpkgSettingsSubMenu() {
		console.log("addOpkgSettingsSubMenu")
		var component = Qt.createComponent("OpkgPageSettingsSubMenu.qml");
		if (component.status === Component.Ready) {
			console.log("adding")
			var instance = component.createObject()
			model.append(instance)
			return
		}
		console.log("addOpkgSettingsSubMenu:NOT READY")
	}

	function addRemoveItem(action, index, qmlFileName) {
		
		if (action=="-") {
			//console.log("hiding index:" + index)
			model.get(index).show = false // if removing just hide
			return
		}

		var component = Qt.createComponent(qmlFileName);
		if (component.status === Component.Ready) {
			var instance = component.createObject()
			if (!instance) { 
				console.log("failed to create not instance:" + qmlItemName); 
				return; 
			}
		}
		else {
			console.log("Error loading component:", component.errorString());
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
 