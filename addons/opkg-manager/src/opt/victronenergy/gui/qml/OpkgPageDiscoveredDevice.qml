import QtQuick 2
import com.victron.velib 1.0

MbPage {
	id: root
	title: "Add USB serial device"

	required property var opkgManager
	required property var deviceProps
	required property var deviceAddedCallback

	property string selectedServiceTypePath: "" //"Inetbox"
	property var addingDeviceText: progressText.running ? progressText.text : ""
	property bool deviceAdded: deviceAddedCallback !== undefined ? deviceAddedCallback() : false

	pageToolbarHandler: addDeviceToolbarHandler

	model: VisualModels {
		VisibleItemModel {
			MbItemOptions {
				id: selectServiceType
				description: qsTr("Serial Device Service")
				unknownOptionText: qsTr("Press to select service")
				message: root.serviceTypesModel?.length === 0 ? qsTr("No custom devices currently installed") : ""
				value: root.selectedServiceTypePath
				onOptionSelected: function (newValue) {
					root.onSerialDeviceServiceSelected(newValue) }
				//Fix for spacebar not working after DelegateModel use!
				Keys.onSpacePressed: { edit() }
			}
			MbItemRow { description: qsTr("Port")
				values: [MbTextBlock { item.text: deviceProps.port} ]}
		}

		DelegateModel {
			id: usbProps
			model: root.deviceProps.usbProps
			delegate: MbItemRow { description: modelData.name
				values: [MbTextBlock { item.text: modelData.value} ]}
		}

	}

	VeQItemSortTableModel {
		id: customDevices
		model: VeQItemChildModel {

			model: VeQItemSortTableModel {
				model: VeQItemTableModel {
					uids: ["dbus/com.victronenergy.settings/Settings/OpkgManager/Devices"]
					flags: VeQItemTableModel.AddChildren |
							VeQItemTableModel.AddNonLeaves |
							VeQItemTableModel.DontAddItem
				}
				dynamicSortFilter: true
				filterFlags: VeQItemSortTableModel.FilterOffline
			}
			childId: "ProductName"
		}
		dynamicSortFilter: true
		filterFlags: VeQItemSortTableModel.FilterInvalid
		onRowCountChanged: buildCustomDeviceOptions()
	}

	Component  { id: mbOptionLoader; MbOption {}}

	OpkgProgressText { id: progressText}

	function buildCustomDeviceOptions() {

		var devices = []
		for (var i = 0; i < customDevices.model.rowCount; i++) {
			var currentIndex = customDevices.model.index(i, 0)
			var uid = customDevices.model.data(currentIndex, VeQItemTableModel.UniqueIdRole)
			var productName = customDevices.model.getValue(i, VeQItemTableModel.ValueColumn)

			const parts = uid.split("/");
			const value = parts[parts.length - 2];
			var params =  { value: value, description: productName }
			var device = mbOptionLoader.createObject(root, params)
			devices.push(device)
		}
		selectServiceType.possibleValues = devices
	}

	function onSerialDeviceServiceSelected(newValue)	{
		var changed = root.selectedServiceTypePath != "" && root.selectedServiceTypePath != newValue
		console.log("onSerialDeviceServiceSelected:" + newValue)
		root.selectedServiceTypePath = newValue
		//if (changed && deviceModel)
		//	root.doStep("detect-device-done")
	}

	function addDevice() {
		if (root.deviceAdded || !root.selectedServiceTypePath)
			return

		var checkStable = 1

		progressText.start("Adding Device")

		root.opkgManager.bindDeviceToService(
			deviceProps.hash, deviceProps.port, root.selectedServiceTypePath, checkStable,
			function(result) {
				progressText.stop()
				if (result.success) {
						deviceAddedCallback(true)
					toast.createToast("Device Added Successfully\nThe service will start shortly...", 5000)
				}
			}
		)
		//pageStack.pop();
	}
	function cancel() {
		pageStack.pop();
	}

	ToolbarHandler {
		id: addDeviceToolbarHandler
	  leftText: progressText.running
			? root.addingDeviceText
		 	: !root.deviceAdded && root.selectedServiceTypePath
				? qsTr("Save")
				: ""
		rightText: qsTr("Cancel")
		function leftAction() { root.addDevice() }
		function rightAction() { root.cancel() }
	}
}
