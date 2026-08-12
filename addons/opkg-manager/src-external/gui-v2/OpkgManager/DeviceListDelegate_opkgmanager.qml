import QtQuick
import Victron.VenusOS
import "qrc:/OpkgManager/OpkgSingleton.js" as OpkgSingleton

DeviceListDelegate {
	id: root

	onDeviceChanged: {
		console.debug("OpkgManager: DeviceListDelegate::onDeviceChanged: isRelead=", OpkgSingleton.getIsReload())

		parent.active = false

		var isReload = OpkgSingleton.getIsReload()
		if (isReload) {
			Global.mainView.swipeView.animationEnabled = false
			Global.mainView.navBar.setCurrentIndex(-1)
		}

		if (!OpkgSingleton.OpkgCustomPageModelExists()) {
			OpkgSingleton.createOpkgCustomPageModel(Global.main)
		} else {
			console.debug("OpkgManager: OpkgSingleton exists")
		}

		if (isReload) {
			OpkgSingleton.setIsReload(false)

			Global.pageManager.popAllPages(1)
			Global.mainView.navBar.setCurrentIndex(0)
		}

	}

	Component.onDestruction: {
		console.debug("OpkgManager device delegate:DESTROYED")
	}

}
