import QtQuick 2
import com.victron.velib 1.0

MbPage {
	id: root
	//tryPop: opkgManager.tryPop

	required property var opkgManager
 	property var serviceTypeOptions: []
	property string selectedServiceTypePath: "TestService"
	property string stage: "detect-device"
	property bool cancellable: !selectedServiceTypePath || (deviceModel && opkgManager.running) ? false : opkgManager.running
	property var deviceModel
	property var shiftDown: false
	property var usbPropsModel
	property MbStyle mbStyle: MbStyle {}

	VeQuickItem {
		id: customServicePath
		uid: "dbus/com.victronenergy.settings/Settings/OpkgManager/CustomDevicesList"
		onValueChanged: root.createServiceTypeOptions()
	}

	Component.onCompleted: {
		listview.height = mbStyle.itemHeight
		opkgManager.setOutputLog(logViewer)
		root.createServiceTypeOptions()

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


	function createServiceTypeOptions() {

		for (var i = 0; i < root.serviceTypeOptions.length; i++) {
			if (root.serviceTypeOptions[i])
				root.serviceTypeOptions[i].destroy()
		}

		var options = []
		var seen = {}
		//var entries = Utils.stringToArray(customServicePath.value)
		var entries = customServicePath.value.split(",").map(s => s.trim());
		var stillAvailable = false

		for (var i = 0; i < entries.length; i++) {
			var pathName = (entries[i] || "").trim()
			if (pathName && pathName.length > 0 && !seen[pathName]) {
				seen[pathName] = true
				if (root.selectedServiceTypePath == pathName)
					stillAvailable = true
				var item = serviceTypeOptionFactory.createObject(root, {
					bindPrefix: "dbus/com.victronenergy.settings/Settings/OpkgManager/CustomDevices/" + pathName,
					value: pathName
				})
				options.push(item)
			}
		}

		root.serviceTypeOptions = options

		if (!stillAvailable) {
			root.selectedServiceTypePath = ""
			selectServiceType.localValue = ""
		}
	}

	model: VisibleItemModel {

		MbItemOptions {
			id: selectServiceType
			description: qsTr("Serial Device")
			unknownOptionText: qsTr("Select")
			message: root.serviceTypesModel?.length === 0 ? qsTr("No custom devices currently installed") : ""
			possibleValues: root.serviceTypeOptions
			onOptionSelected: function(newValue) {
				if (!newValue || newValue.length === 0)
					return

				var changed = root.selectedServiceTypePath != "" && root.selectedServiceTypePath != newValue

				root.selectedServiceTypePath = newValue
				//if (changed && deviceModel)
				//	root.doStep("detect-device-done")
			}
		}

	}

	Component {
		id: serviceTypeOptionFactory
		MbOption {
			property string bindPrefix: ""
			property VeQuickItem productNameItem: VeQuickItem {
				uid: bindPrefix ? bindPrefix + "/ProductName" : "" }
			description: productNameItem.value
		}
	}

	// Usb Device Props

	Rectangle {
		id: usbDeviceRect
		color: "red"
		border.color: "#cecece"
		visible: usbPropsModel?.length > 0
		onHeightChanged: root.outputLog ? root.outputLog.scrollToBottom() : 0
		radius: 4
		anchors {
			top: listview.bottom; topMargin: root.mbStyle.marginDefault
			left: parent.left; leftMargin: root.mbStyle.marginDefault
			right: parent.right; rightMargin: root.mbStyle.marginDefault
		}
		width: parent.width
		height: usbPropsFlow.implicitHeight + root.mbStyle.marginDefault
		Flow {
			id: usbPropsFlow
			height: (root.mbStyle.itemHeight + root.mbStyle.marginDefault) * 2
			anchors {
				top: parent.top; topMargin: root.mbStyle.marginItemVertical
				left: parent.left; leftMargin: root.mbStyle.marginDefault
				right: parent.right; rightMargin: root.mbStyle.marginDefault
			}
			spacing: root.mbStyle.marginItemVertical
			flow: Flow.LeftToRight
			Repeater {
				model: root.usbPropsModel
				delegate: OpkgLabelValueItem {
					label: modelData.label
					value: modelData.value
					fontSize: root.mbStyle.fontPixelSize - 4
				}
			}
		}
	}
	// Non-selectable, scrollable log area
	OpkgLogViewer {
		id: logViewer

		anchors {
			top: usbDeviceRect.visible ? usbDeviceRect.bottom : listview.bottom
			topMargin: mbStyle.marginItemVertical
			bottom: parent.bottom; bottomMargin: mbStyle.marginItemVertical
			left: parent.left; leftMargin: mbStyle.marginItemHorizontal
			right: parent.right; rightMargin: mbStyle.marginItemHorizontal
		}
	}

	pageToolbarHandler: ToolbarHandler {
		property bool rightTextVisible: !root.deviceModel && root.opkgManager.running || root.stage.endsWith("-done")
		property bool leftTextVisible: root.selectedServiceTypePath && !root.opkgManager.running

		leftText: leftTextVisible ? (root.deviceModel ? "Apply" : "Detect USB device") : ""
		rightText: rightTextVisible ? "Cancel" : ""

		function rightAction() { root.cancel() }
		function leftAction() { root.updateStage() }
	}

}
