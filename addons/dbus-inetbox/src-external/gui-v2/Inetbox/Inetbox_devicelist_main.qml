import QtQuick
import Victron.VenusOS

Page {
	id: root

	//% "Simple"
	title: qsTrId("inetbox_page_title_simple")

	VeQuickItem {
		id: logger
		uid: Global.systemSettings.serviceUid + "/Settings/EventLogger/Log1"
    function log(message) {
      logger.setValue("Simple-" + message)
    }
	}

  Component.onCompleted: {
    logger.log("Component.onCompleted")
  }
  Component.onDestruction: {
    logger.log("Component.onDestruction")
  }

	GradientListView {
		id: settingsListView

		model: VisibleItemModel {
			ListSwitch {
				property bool value
				//% "Switch"
				text: qsTrId("inetbox_settings_switch")
				checked: value
				onClicked: {
					value = !checked
					console.log("Switch now checked?", checked)
				}
			}
      
      ListNavigation {
				topInset: Theme.geometry_listItem_itemSeparator_height
				//% "Overview Page"
				text: qsTrId("inetbox_devicelist_overview_page")
				onClicked: Global.pageManager.pushPage("qrc:/Inetbox/InetboxOverviewPage_Landscape.qml", {"title": text})
			}
		}
	}
}
