import QtQuick 2
import Victron.VenusOS
import "qrc:/OpkgManager/components"

Page {
	id: root

	required property OpkgManager opkgManager
	property string devicesUid: opkgManager.serviceUid + "/Discovered"

	OpkgDbusChildModel {
		id: devicesModel
		uid: root.devicesUid
		childId: "Port"
	}

 	GradientListView {
		id: listview
		header: PrimaryListLabel {
			horizontalAlignment: Text.AlignHCenter
			preferredVisible: listview.count === 0
			//% "No Usb devices discovered"
			text: qsTrId("opkgmanager_no_devices_discovered")
		}

		model: devicesModel

		delegate: ListNavigation {
			id: device
			required property var model

			text: CommonWords.device_info_title // "Device"
			secondaryText: model.value

			onClicked: Global.pageManager.pushPage("qrc:/OpkgManager/OpkgPageSettingsDiscoveredDevice.qml",
				{"title": text,
				opkgManager: root.opkgManager,
				port: model.value,
				serviceUid: model.buddy.uid}
			 )
		}
	}
}