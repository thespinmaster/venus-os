import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
 
// portPath: required  i.e. "Devices/dbus_inetbox/Port"
// title: optional

MbPage {
	id: root
 
  property string step: ""
	property var deviceModel
	property var outputLog
 	property var serviceTypesModel: []
	property var usbPropsModel: []
	property string toolbarRightText: ""
	property string toolbarLeftText: ""
 	property string selectedServiceTypePath: ""
  property bool shiftDown: false
  property MbStyle mbStyle: MbStyle {}
 
	VBusItem {
		id: customServicePath
		bind: "com.victronenergy.settings/Settings/OpkgManager/AvailableCustomServices"
		onValueChanged: root.createCustomServicesModel()
	}
 
 	onStepChanged: refreshToolbarState()
	onDeviceModelChanged: refreshToolbarState()
	onSelectedServiceTypePathChanged: refreshToolbarState()
	
	model: VisibleItemModel {
 
		MbSubMenu {
			id: selectServiceType
			description: qsTr("Serial Device")
			item.text: qsTr("Select")

			subpage: Component {
				MbPage {
					title: qsTr("Select Serial Device")

					model: VisualModels {
						DelegateModel {
							model: root.serviceTypesModel

							delegate: MbSubMenu {
								id: deviceOption
								property string pathName: modelData.pathName
								
								property VBusItem productName: VBusItem { bind: (modelData.bindPrefix || "") + "/ProductName" }
                description: productName.value
 
								onSelected: onSerialDeviceSelected(pathName)
								onClicked: onSerialDeviceSelected(pathName)
							}
						}

						VisibleItemModel {
							MbItemRow {
								show: root.serviceTypesModel.length === 0
								description: qsTr("No custom devices currently installed")
							}
						}
					}
				}
			}
		}
 
	}

	function onSerialDeviceSelected() {
		if (!pathName || pathName.length === 0)
			return

		var changed = root.selectedServiceTypePath != "" && root.selectedServiceTypePath != pathName

		root.selectedServiceTypePath = pathName
		selectServiceType.item.text = description
		if (changed && deviceModel) {
			root.doStep("device-detect-done")
		}
		if (pageStack.currentPage !== root)
			pageStack.pop()

	}

	function refreshToolbarState() {
    
		root.toolbarRightText = root.showApply() ? "Apply" : ""
 
		if (root.step == "canceling") {
			root.toolbarLeftText = ""
			return
		}

		if (root.selectedServiceTypePath && root.step == "") {
			root.toolbarLeftText = "Detect Usb Device"
			return
		}
		if (root.step != "") {
			root.toolbarLeftText = "Cancel"
			return
		}
		root.toolbarLeftText = ""
 
	}
 
	function createCustomServicesModel() {
		var values = []
		var seen = {}
 
		var entries = Utils.stringToArray(customServicePath.value)
		for (var i = 0; i < entries.length; i++) {
			var pathName = (entries[i] || "").trim()
			if (!pathName || seen[pathName])
				continue

			seen[pathName] = true
			values.push({
				pathName: pathName,
				bindPrefix: "com.victronenergy.settings/Settings/OpkgManager/CustomServices/" + pathName
			})

		}
 
		root.serviceTypesModel = values
	}
 
	listview.footer: Item {
		id: footerItem
		height: Math.max(0, root.listview.height - (root.listview.count * root.mbStyle.itemHeight))
		Component.onCompleted: root.outputLog = outputLogArea
		anchors {
			left: parent.left
			right: parent.right
		}
 
		Rectangle {
			id: usbDeviceRect
			color: "transparent"
			border.color:  "#cecece"
			onHeightChanged: root.outputLog ? root.outputLog.scrollToBottom() : 0
			radius: 4
			anchors {
				top: parent.top; topMargin: root.mbStyle.marginDefault
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
		
		OpkgOutputLogArea {
			id: outputLogArea
			mbStyle: root.mbStyle

			anchors {
				top: usbDeviceRect.bottom; topMargin: root.mbStyle.marginDefault
				left: parent.left; leftMargin: root.mbStyle.marginDefault
				right: parent.right; rightMargin: root.mbStyle.marginDefault
				bottom: parent.bottom
				bottomMargin: root.mbStyle.marginDefault
			}
			width: parent.width
		}
	}

	Keys.onPressed: function(event) {
		if (event.key === Qt.Key_Shift)
				root.shiftDown = true
	}

	Keys.onReleased: function(event) {
		if (event.key === Qt.Key_Shift)
				root.shiftDown = false
	}

	pageToolbarHandler: ToolbarHandler {
 		
		leftText: root.toolbarLeftText
		rightText: root.toolbarRightText
		function rightAction() { root.doStep("device-apply") }

		function leftAction(mouse) {
			if (step == "") {
				root.doStep("device-detect")
			} else  {
				root.doStep()
			}
		}

		function centerAction() {
			root.centerAction()
		}
 
	}
 
	function loadDeviceModelFromJson(jsonText) {
 
		root.deviceModel = JSON.parse(jsonText)

		var items = [{label: "Port:", value: root.deviceModel.port }]
 
		if (root.deviceModel.service) {
			var serviceItem = { label: "Service:", value: root.deviceModel.service }
			items.push(serviceItem)
		} else if (root.deviceModel.process) {
			var processItem = { label: "Process:", value: root.deviceModel.process }
			items.push(processItem)
		}
		
		var usbPropsItems = parseUsbProps(root.deviceModel.usbProps)
		root.usbPropsModel = items.concat(usbPropsItems)
	}

	function formatUsbPropLabel(key) {

		var words = key.replace(/^ID_/i, "").replace(/_ID$/i, "").split("_")
		var labelParts = []

		for (var i = 0; i < words.length; i++) {
			if (!words[i])
				continue
			var word = words[i].toLowerCase()
			if (words[i] == "id")
				word="ID"
			else
				word = word.charAt(0).toUpperCase() + word.slice(1)

			labelParts.push(word)
		}

		if (labelParts.length === 0)
			return key + ":"

		return labelParts.join(" ") + ":"
	}
 
	function parseUsbProps(usbProps) {
		//KISS, alternative is a json parser in bash.
		var usbPropItems = []

		if (!usbProps || typeof usbProps !== "string")
			return usbPropItems

		var pairs = Utils.stringToArray(usbProps)
		for (var i = 0; i < pairs.length; i++) {
			var entry = pairs[i]
			if (!entry)
				continue

			var idx = entry.indexOf("=")
			if (idx <= 0)
				continue

			var key = entry.slice(0, idx)
			var value = entry.slice(idx + 1)
			if (!value || value.length == 0)
				continue
			var label = formatUsbPropLabel(key)
			usbPropItems.push({
				label: formatUsbPropLabel(key),
				value: value
			})
		}

		return usbPropItems
	}
 
	function reset_page() { root.selectedServiceTypePath = "" }
 
	onStatusChanged: {
		if (root.status == 0 && pageStack.find(function(page) { return page === root }) === null)
			reset_page()
	}
 
	Component.onCompleted: refreshToolbarState()
 
	function showApply() {
 
	 	if (root.step != "device-detect-done")
		if (root.step == "cancelling")
			return false
 		
		if (!root.selectedServiceTypePath)
			return false
 
		if (!root.deviceModel || !root.deviceModel.port)
			return false

		if (!root.deviceModel.usbProps || root.deviceModel.usbProps.length == 0)
			return false

		if (!root.deviceModel.sid) {
			if (!root.deviceModel.process=="[Unstable]")
				return false
		}

		return true
	}

	function doStep(step, done) {

		step = (step || "") + (done ? "-done" : "")
		root.step = step
		
		if (processRunner.stopping)
			return
 
		switch (step) {
		case "error": // don't clear output.
			root.step = ""
			processRunner.operationName = ""
			processRunner.stop() 
			break;
		case "canceling-done":

			if (root.outputLog) {
				root.outputLog.baseWorking = "Cancelled"
				root.outputLog.stopIsWorking()
			}
			root.step=""
			break
		case "":
			deviceModel = null
			usbPropsModel = null
		case "device-apply-done":
		case "device-detect-done":
			if (step == "" && processRunner.running) {
				root.step = "canceling"
				if (root.outputLog)
					root.outputLog.startIsWorking("Canceling")
				processRunner.operationName = "canceling"
				processRunner.stop()
			} else if (step == "" && root.outputLog) {
				
				root.outputLog.clear()
			
			}
			break
		case "device-detect":
			if (processRunner.operationName || root.step == "canceling")
				return
			if (step == "device-detect" && root.outputLog)
				root.outputLog.startIsWorking("Please insert (or re-insert) the usb device", true)
			
			var reconnect=""
			
			if (root.shiftDown)
				reconnect = "true"
 
			processRunner.operationName = "device detect"
			processRunner.start(["device", "detect", root.selectedServiceTypePath, reconnect])
			break
		case "device-apply":
			if (processRunner.operationName)
				return
			processRunner.operationName = "device apply"
			if (root.outputLog)
				root.outputLog.clear()
			 
			processRunner.start(["device", "apply", root.selectedServiceTypePath, root.deviceModel.port, root.deviceModel.usbProps])
			break
		case "service-running":
		  root.outputLog.addLine("Service Running")
			break
		default:
			console.log("ERROR:doStep:invalid-step")
			break
		}
	}
 
	OpkgServiceProcess {
		id: processRunner
		onOutputLine: function(line) {
			if (processRunner.stopping) {
				console.log("stopping:" + line)
				return
			}
			
			if (line.endsWith("...")) {
				root.outputLog.startIsWorking(line.slice(0,-3))
				return
			}
 
			if (root.outputLog.isWorking && line.startsWith("~~")) {
				root.outputLog.baseWorking = line.slice(2)
				return
			}

			if (root.outputLog)
				root.outputLog.addLine(line)
		}

		onErrorLine: function(line) {
			// console.error(line) // temp code
			if (processRunner.stopping)
				return
			console.error("OpkgPageSettingsDeviceSetup:ERROR:" + line)
			if (root.outputLog)
				root.outputLog.addLine(line)
		}
 
		onFinished: function(exitCode, exitStatus) {
			console.log("onFinished:" + processRunner.operationName + ", " + exitCode + ", " + exitStatus)
 
			try {   

				if (processRunner.operationName == "canceling") {
					doStep(processRunner.operationName, true)
					return
				}
 
				if (exitCode === 0 && exitStatus === 0) {
					if (processRunner.operationName == "device detect" && jsonResult) {
						loadDeviceModelFromJson(jsonResult)
					}  
					doStep(processRunner.operationName, true)
 
				} else {
 					root.doStep("error")
				}
 
			} catch (err) {
				var msg = `ERROR:${err.lineNumber}: ${err.message}`
				console.log(msg);
				if (root.outputLog)
					root.outputLog.addLine(msg)
				
				root.doStep("error")
			}
			
		}
	}

}