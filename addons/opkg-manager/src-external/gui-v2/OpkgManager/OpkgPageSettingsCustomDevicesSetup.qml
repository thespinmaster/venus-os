import QtQuick 2
import Victron.VenusOS

Page {
	id: root
	tryPop: opkgManager.tryPop

	required property var opkgManager
 	property var servicesOptions: []
	property string selectedServiceTypePath: "TestService"
	property string stage: "detect-device"
	property bool cancellable: !selectedServiceTypePath || (deviceModel && opkgManager.running) ? false : opkgManager.running
	property var deviceModel
	property var shiftDown: false
	property var usbPropsModel

	readonly property int hMargin: Theme.geometry_page_content_horizontalMargin + Theme.geometry_listItem_content_horizontalMargin
	readonly property int vMargin: Theme.geometry_listItem_content_verticalMargin

	VeQuickItem {
		id: customDevicesPath
		uid: Global.systemSettings.serviceUid + "/Settings/OpkgManager/CustomDevicesList"
		onValueChanged: root.createCustomDevicesModel()
	}

	Component.onCompleted: {
		opkgManager.setOutputLog(logViewer)
		serialDevice.currentIndex = 0
		//var data = {port: "ttyUSB0", service: "", process: "",
		//	usbProps: "ID_VENDOR=FTDI,ID_MODEL=Inetbox,ID_SERIAL=Inetbox_a767e4c176"}
		//loadDeviceModelFromJson(data)
 	}

	Component.onDestruction: {
		if (opkgManager)
			opkgManager.setOutputLog(null)
 	}

	Keys.onPressed: function(event) {
		if (event.key === Qt.Key_Shift)
				root.shiftDown = true
	}
	Keys.onReleased: function(event) {
		if (event.key === Qt.Key_Shift)
				root.shiftDown = false
	}

	function detectDevice() {
		var completionCallback = function(result) {
				if (!result.cancelled && stage == "detect-device" && result.data)
					loadDeviceModelFromJson(result.data)
				onStageCompleted(result.success, result.cancelled)
			}

		var reconnect = root.shiftDown
		root.cancellable = true

		logViewer.clear()
		logViewer.log("Please insert (or re-insert) the usb device...")

		opkgManager.detectDevice(root.selectedServiceTypePath, reconnect, completionCallback)
	}

	function applyDevice() {
		logViewer.clear()
		var completionCallback = function(result) {
			onStageCompleted(result.success, result.cancelled)
		}

		opkgManager.applyDevice(
			root.selectedServiceTypePath,
			root.deviceModel.port,
			root.deviceModel.usbProps, completionCallback)
	}

	function onStageCompleted(succeeded, cancelled) {

		if (cancelled) {
			logViewer.baseWorking = "Cancelled"
			logViewer.stopIsWorking()
			return
		}
		if (succeeded)
			root.stage += "-done"
	}

	function cancel() {
		deviceModel = null

		if (root.stage == "detect-device") {
			if (opkgManager.running)
				opkgManager.cancel()
		} else if (root.stage.endsWith("-done")) {
			if (opkgManager.running)
				return

			logViewer.clear()
			root.stage = root.stage.slice(0, -5);
		}
	}

 	function updateStage() {
		if (stage == "detect-device") {
				detectDevice()
		} else if (stage == "detect-device-done") {
				applyDevice()
		}
	}

	function loadDeviceModelFromJson(data) {
		const model = [];

		root.deviceModel = data

		model.push({ label: "Port:", value: root.deviceModel.port })

		if (root.deviceModel.service) {
			model.push({label: "Service:", value: root.deviceModel.service})
		} else if (root.deviceModel.process) {
			model.push({label: "Process:", value: root.deviceModel.process})
		}

		root.deviceModel.usbProps.split(',').forEach(s => {
			let [k, v] = s.split('=');
			k = (k.startsWith('ID_') ? k.slice(3) : k)
				.toLowerCase().split('_')
				.map(w => w[0].toUpperCase() + w.slice(1)).join(' ');
			model.push({label: k + ":", value: v})
		});

		root.usbPropsModel = model

	}

	function createCustomDevicesModel() {
		var values = []
		var seen = {}

		var entries = customDevicesPath.value.split(",")
		for (var i = 0; i < entries.length; i++) {
			var pathName = (entries[i] || "").trim()
			if (!pathName || seen[pathName])
				continue

			seen[pathName] = true
			values.push({
				display: pathName,
				value: Global.systemSettings.serviceUid + "/Settings/OpkgManager/CustomDevices/" + pathName
			})
		}

		root.servicesOptions = values
	}

	BaseListView {
		id: optionsList

		anchors {
			top: parent.top; topMargin: root.vMargin
			left: parent.left; leftMargin: Theme.geometry_listItem_content_horizontalMargin
			right: parent.right; rightMargin: Theme.geometry_listItem_content_horizontalMargin
		}
		height: serialDevice.height
		model: VisibleItemModel {

			ListRadioButtonGroup {
				id: serialDevice
				//% "Service"
				text: qsTr("Serial Device")
				// currentValue
				optionModel: root.servicesOptions
				//% "Select"
				defaultSecondaryText: "Select"
				currentIndex: {
					for (let i = 0; i < optionModel.length; ++i)
						if (optionModel[i].value === selectedServiceTypePath)
							return i
					return -1
				}
				onOptionClicked: function(index) {
					selectedServiceTypePath = optionModel[index].value
				}
			}

		}
	}

	// Usb Device Props
	Rectangle {
		id: usbDeviceRect
		color: Theme.color_listItem_background
		border.color:  Theme.color_gray2
		radius: Theme.geometry_listItem_radius
		visible: root.usbPropsModel != undefined
		anchors {
			top: optionsList.bottom; topMargin : Theme.geometry_listItem_content_verticalSpacing
			left: parent.left; leftMargin: root.hMargin
			right: parent.right; rightMargin:  root.hMargin
		}
		width: parent.width
		height: usbPropsFlow.implicitHeight + Theme.geometry_listItem_content_verticalMargin * 2
		Flow {
			id: usbPropsFlow
			height: usbPropsFlow.implicitHeight
			anchors {
				top: parent.top; topMargin: Theme.geometry_listItem_content_verticalMargin
				left: parent.left; leftMargin: Theme.geometry_listItem_content_horizontalMargin
				right: parent.right; rightMargin: Theme.geometry_listItem_content_horizontalMargin
				bottom: parent.bottom; bottomMargin: Theme.geometry_listItem_content_verticalMargin
			}
			spacing: Theme.geometry_button_spacing * 2
			flow: Flow.LeftToRight
			Repeater {
				model: root.usbPropsModel
				delegate: Row {
					spacing: Theme.geometry_button_spacing
					Label {
						background: Rectangle {
							color: Theme.color_gray3;
							radius: Theme.geometry_overviewPage_widget_battery_background_radius}
						padding: Theme.geometry_button_padding
						text: modelData.label
						font.pixelSize: Theme.font_size_caption
					}
					Label {
						text: modelData.value
						anchors.verticalCenter: parent.verticalCenter
						font.pixelSize: Theme.font_size_caption
					}
				}
			}
		}

	}

	// Non-selectable, scrollable log area
	OpkgLogViewer {
		id: logViewer

		anchors {
			top: usbDeviceRect.visible ? usbDeviceRect.bottom : optionsList.bottom ; topMargin: root.vMargin
			bottom: actionsRow.top; bottomMargin: root.vMargin
			left: parent.left; leftMargin: root.hMargin
			right: parent.right; rightMargin: root.hMargin
		}
	}

	OpkgActionsRow {
		id: actionsRow
		buttonModel: [
			{ text: root.deviceModel ? "Apply" : "Detect USB device",
				enabled: root.selectedServiceTypePath && !root.opkgManager.running,
				onClicked: root.updateStage},
			{ text: "Cancel",
				enabled: !root.deviceModel && root.opkgManager.running || root.stage.endsWith("-done"),
				onClicked: root.cancel}
		]
	}


}
