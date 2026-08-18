import QtQuick 2
import Victron.VenusOS
import "qrc:/OpkgManager/components/OpkgSingleton.js" as OpkgSingleton

QtObject {
	id: root

	//Component.onDestruction: {
		//console.debug("OpkgCustomPageModel: DESTROYED: ", root)
	//}

	Component.onCompleted: {
		//console.debug("OpkgCustomPageModel: CREATED", root)
		if (allPagesLoaded)
			root.syncPages()
	}

	property bool allPagesLoaded: Global.mainView != undefined
															&& Global.mainView.swipeView != undefined
															&& Global.mainView.swipeView.ready

	property bool _inSyncPages: false
	property var _customPages: []
	property var _customPageItems : ({})

	property VeQuickItem _customPagesItem: VeQuickItem {
		uid: !!Global.systemSettings ? Global.systemSettings.serviceUid + "/Settings/OpkgManager/CustomPages" : ""
		onValueChanged: root.onCustomPagesChanged(value)
	}

	property Connections connections: Connections {
		target: Global.mainView?.swipeView?.contentModel ?? null

		function onModelUpdated() {
			if (root._inSyncPages)
				return
			//Coalesces multiple calls
			Qt.callLater(function () { root.syncPages() })
		}
	}

	function onCustomPagesChanged(value) {

		if (_customPagesItem.uid == "" || value == undefined || typeof(value) !== "string")
			return

		//console.debug("OpkgCustomPageModel: onCustomPagesChanged:", "pages=", value, "allPagesLoaded=", allPagesLoaded)

		var customPagesArray = JSON.parse(value)
		if (!customPagesArray) {
			console.error("OpkgCustomPageModel: Unable to parse data from", value)
			return
		}

		if (allPagesLoaded == false) {
			_customPages = customPagesArray
			return
		}

		root.syncPages(customPagesArray)
	}

	function syncPages(customPages) {
		//console.debug("OpkgCustomPageModel: syncPages in:", root._inSyncPages)
		if (root._inSyncPages)
			return

		_inSyncPages = true

		if (customPages === undefined)
			customPages = _customPages;

		const model = Global.mainView.swipeView.contentModel

		//
		// Build current page lookup from the SwipeView model
		//
		const currentPages = {}

		for (let i = 0; i < model.count; ++i) {
			const page = model.get(i)
			if (page.url)
				currentPages[page.url] = page
		}

		//
		// Build requested page lookup
		//
		const requestedPages = {}

		for (var url of customPages)
			requestedPages[url] = true

		//
		// Remove custom pages that no longer exist
		//
		for (var url of _customPages) {
			if (requestedPages[url])
				continue

			const page = _customPageItems[url]
			if (removePage(page))
				delete _customPageItems[url]
		}

		//
		// Add new custom pages.
		// Insert backwards so final order matches customPages.
		//
		//console.debug("OpkgCustomPageModel: syncPages customPages:", customPages.length )
		for (var i = customPages.length - 1; i >= 0; --i) {
			const url = customPages[i]

			if (currentPages[url])
				continue // page already exists

			var page = _customPageItems[url]
			if (!page) {
				page = OpkgSingleton.createPage(url, Global.mainView, {view:Global.mainView.swipeView})
				if (!page) continue
				_customPageItems[url] = page
			}
			//console.debug("OpkgCustomPageModel: syncPages insertItem:", page )
			Global.mainView.swipeView.insertItem(0, page)
		}

		//
		// Update NavBar pages from the final SwipeView model
		//

		Global.mainView.navBar.pages.length = model.count
		for (var i = 0; i < model.count; ++i)
			Global.mainView.navBar.pages[i] = model.get(i)

		_customPages = customPages.slice()
		_inSyncPages = false
	}

	function removePage(page) {
		const swipeView = Global.mainView.swipeView

		for (let i = 0; i < swipeView.contentChildren.length; ++i) {
			if (swipeView.contentChildren[i] === page) {
				swipeView.removeItem(page)
				return true
			}
		}

		return false
	}

	onAllPagesLoadedChanged: {
		//console.debug("OpkgCustomPageModel: onAllPagesLoadedChanged:",
		//"allPagesLoaded=", allPagesLoaded,
		//"hadCustomPages=", _customPageItems.length>0,
		//)

		OpkgSingleton.setIsReload(true)
		if (allPagesLoaded == false) {
			var hadCustomPages = _customPageItems.length>0
			_customPageItems = ({})
			if (hadCustomPages)
				OpkgSingleton.clearCache()
			return;
		}

		if (root._inSyncPages)
			return
		//Coalesces multiple calls
		Qt.callLater(function () { root.syncPages() })
	}

}
