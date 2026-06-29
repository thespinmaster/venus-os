import QtQuick 2
import QtQuick.Layouts
import Victron.VenusOS

Page {
	id: root
	title: qsTr("Custom Devices")
	tryPop: opkgManager.tryPop
	required property OpkgManager opkgManager
	property var devicesModel

	VeQuickItemAdapter {
		id: customDevices
		uid: systemSettingsServiceUid + "/Settings/CustomDevicesList"
		onValueChanged: {
			root.createCustomDevicesModel()
		}
	}

	function createCustomDevicesModel() {
		var deviceList = customDevices.value
		if (!deviceList?.length)
			return
		//console.log("deviceList:" + deviceList)
		root.devicesModel = deviceList.split(",")
	}

	Component {
		id: removalDialogComponent

		ModalWarningDialog {
			id: warningDialog
			//% "Remove Custom Device?"
			title: "Remove Custom Device?"
			dialogDoneOptions: VenusOS.ModalDialog_DoneOptions_OkAndCancel
			icon.color: Theme.color_orange
			acceptText: CommonWords.remove
			property string sid

			onAccepted: {
				var theRoot = root
				var sidValue = sid
				theRoot.opkgManager.removeDevice(sidValue, function(result) {
					if (!result.success)
						return
					var array = theRoot.devicesModel
					const index = array.indexOf(sidValue);
					if (index > -1) {
						array.splice(index, 1);
						theRoot.devicesModel = array
					}

				})
			}
		}
	}

	GradientListView {
		id: settingsListView
		clip: true
		anchors.fill: parent
		model: root.devicesModel

		header: ListNavigation {
			bottomInset: Theme.geometry_listItem_itemSeparator_height
			bottomPadding: bottomInset + topPadding

			//% "Add IP address"
			text: "Add Device"
			iconSource: "qrc:/images/icon_plus_32.svg"
			iconColor: Theme.color_ok
			//showAccessLevel: root.writeAccessLevel
			hasSubMenu: false
				onClicked: Global.pageManager.pushPage("qrc:/OpkgManager/OpkgPageSettingsCustomDevicesSetup.qml",
					{title: text, opkgManager: root.opkgManager})
		}

		delegate: OpkgCustomDeviceListItem {}
	}

}