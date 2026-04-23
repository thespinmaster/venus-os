import QtQuick 2
import "opkg-utils.js" as OpkgUtils

QtObject {

  property VeQuickItem customPages: VeQuickItem { 
		uid: "dbus/com.victronenergy.settings/Settings/OpkgManager/CustomOverviewPages"
		onValueChanged: {

			if (value == undefined)
				return
 
			OpkgUtils.addRemoveCustomItemsQuick(customPages, overviewModel, getPageIndex, addRemoveItem, null);
		}
	}
  
	property VeQuickItem customMenuItems: VeQuickItem {
		uid: "dbus/com.victronenergy.settings/Settings/OpkgManager/CustomMenus"
		onValueChanged: {
			OpkgUtils.initCreateComponent(customMenuItems) 
			}
	}	
 
	function addRemoveItem(model, action, index, pageFileName) {
		//console.log("AAA:addRemoveItem:" + pageFileName)
		if (action==="-") {
			overviewModel.remove(index)
			return
		}

		if (!OpkgUtils.qmlFileExists(pageFileName)) {
			console.log("Skipping missing custom overview page: " + pageFileName)
			return
		}

		if (action==="*") { // replace
			//overviewModel.get(index).pageSource === pageFileName
			overviewModel.setProperty(index, "pageSource", pageFileName)
			return
		}
 
		overviewModel.append({"pageSource": pageFileName})
		if (index==-2) { 
			return // add to end
		}
 
		// Then move all the pages behind index
		overviewModel.move(index, overviewModel.count - 2, overviewModel.count - 2)
 
	}

	function getPageIndex(model, page) {
		for (var i = 0; i < model.count; i++)
			if (model.get(i).pageSource === page)
				return i
		return -1
	}
	
	function addRemoveCustomOverviewPages(customPages) {
		if (customPages == undefined)
			return
		
		// sample data
		//var customPages = "OverviewInetbox:1,-OverviewTiles";
		var items = customPages.split(",");
		for (var i = 0; i < items.length; i++) {
			var item = items[i].trim();
			if (!item)
				continue;
			var pageSpec = item;
			var insertAt = undefined;
			if (item.indexOf(":") !== -1) {
				var parts = item.split(":");
				pageSpec = parts[0];
				insertAt = parts[1];
			}
			var show = true;
			var pageName = pageSpec;
			if (pageSpec.charAt(0) === "-") {
				show = false;
				pageName = pageSpec.substring(1);
			}
			var index = undefined;
			if (insertAt !== undefined) {
				// If insertAt is a number, use as index
				var idx = parseInt(insertAt, 10);
				if (!isNaN(idx)) {
					index = idx;
				} else {
					// Otherwise, find the index of the page with that name
					for (var j = 0; j < overviewModel.count; j++) {
						if (overviewModel.get(j).pageSource.replace(".qml", "") === insertAt) {
							index = j + 1;
							break;
						}
					}
				}
			}
			// If index is out of bounds, append at end
			if (index !== undefined && (index < 0 || index > overviewModel.count)) {
				index = undefined;
			}
			// Add .qml if not present
			if (! pageName.endsWith(".qml")) {
				pageName = pageName + ".qml";
			}
			extraOverview(pageName, show, index);
		}

	}
 
}