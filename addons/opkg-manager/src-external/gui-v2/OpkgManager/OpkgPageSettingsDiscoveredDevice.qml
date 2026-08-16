pragma ComponentBehavior: Bound

import QtQuick 2
import Victron.VenusOS
import "qrc:/OpkgManager/components"

Page {
	id: root
	//% "Add USB serial device"
	title: qsTrId("opkgmanager_add_usb_serial_device")

	required property var opkgManager
	required property string port
	required property string serviceUid
	//required property var deviceAddedCallback

	property string selectedDeviceServicePathName: "" //"Inetbox"
	property var addingDeviceText: progressText.running ? progressText.text : ""
	//property bool deviceAdded: deviceAddedCallback !== undefined ? deviceAddedCallback() : false
	property alias selectedIndex: opkgAvailableServicesModel.selectedIndex

	property var jsonUsbProps: usbPropsItem.valid ? JSON.parse(usbPropsItem.value) : {}

	VeQuickItem {
		id: usbPropsItem
		uid: root.serviceUid + "/UsbProps"
	}

	OpkgProgressText { id: progressText}

	OpkgDbusChildModel {
		id: opkgAvailableServicesModel
		uid: "dbus/com.victronenergy.settings/Settings/OpkgManager/Devices"
		childId: "ProductName"
		valueDelegate: function (model) {
			return {display: model.value, value: model.buddyId}
		}
	}

	GradientListView {
		header: SettingsColumn {

			width: parent.width
			bottomPadding: spacing

			SettingsListHeader {
				//% "Device Options"
				text: qsTrId("opkgmanager_device_options")
			}
			ListRadioButtonGroup {
				id: selectServiceType
				optionModel: opkgAvailableServicesModel.values
				//% "Serial Device Service"
				text: qsTrId("opkgmanager_serial_device_service")
				//% "Press to select service"
				defaultSecondaryText: qsTrId("opkgmanager_press_to_select_service")

				onOptionClicked: function(index) {
					root.selectedDeviceServicePathName = opkgAvailableServicesModel.services[index].value
				}
			}

			SettingsListHeader {
				//% "Device Properties"
				text: qsTrId("opkgmanager_device_properties")
			}
			ListText {
				//% "Port"
				text: qsTrId("opkgmanager_port")
				secondaryText: root.port
			}
		}

		model: root.jsonUsbProps

		delegate: ListText {
				required property var model
				width: parent.width
				text: model.name
				secondaryText: model.value
		}

		footer: SettingsColumn {
			width: parent.width
			topPadding: spacing
			ListButton {
				secondaryText: CommonWords.add_device
				enabled: root.selectedDeviceServicePathName
				onClicked: root.addDevice()
			}
		}
	}

	function addDevice() {
		if (!root.selectedDeviceServicePathName)
			return

		//% "Adding Device"
		var addingDevice = qsTrId("opkgmanager_adding_device")
		progressText.start(addingDevice)

		var sid = root.serviceUid.split('/').pop()

		root.opkgManager.bindDeviceToService(
			sid, root.port, root.selectedDeviceServicePathName, root.jsonUsbProps,
			function(result) {
				progressText.stop()
					//% "Device Added Successfully\nThe service will start shortly..."
					var successMessage = qsTrId("opkgmanager_added_device_success")
					toast.createToast(successMessage, 5000)
				}
		)
		Global.pageManager.popPage()
	}

}
