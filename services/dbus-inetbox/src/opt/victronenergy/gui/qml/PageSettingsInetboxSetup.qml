import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
import OpkgManager 1.0

MbPage {
	id: root
	title: qsTr("Inetbox Setup")

	property string settingsPrefix: "com.victronenergy.settings/Settings/Devices/dbus_inetbox"
	property string currentPort: portName?.value || "None"
  property string step: ""
  property int fontSize: 14
  property string devicePort
  property string applyingDeviceLog
	property var deviceModel: null
  
	VBusItem { id: portName; bind: Utils.path(settingsPrefix, "/Port") }
 
	MbItem {
		id:header
		height: root.height
		width: root.width
		
		MbTextDescription {
			id: portText
			text: "Current Port: " + currentPort
			width: root.width
			font.pixelSize: portText.mbStyle.fontPixelSize - 2
			anchors.top: parent.top; 
			anchors.topMargin: mbStyle.marginDefault 
			anchors.leftMargin: mbStyle.marginDefault
			anchors.left: parent.left; 
			anchors.right: parent.right
			anchors.bottomMargin: mbStyle.marginDefault 
		}

		 
		Rectangle {
			id: usbDeviceRect
			color: "#e7e5e5"
			radius: 4
			anchors {
				top: portText.bottom; topMargin: portText.mbStyle.marginDefault
				left: parent.left; leftMargin: portText.mbStyle.marginDefault
				right: parent.right; rightMargin: portText.mbStyle.marginDefault
			}
			width: parent.width
			//height: (header.height - portText.height - portText.anchors.topMargin - portText.anchors.bottomMargin) * 0.5
	    height: (portText.mbStyle.fontPixelSize * 4) + portText.mbStyle.marginDefault *2
			Text {
				id: usbDeviceInfo
				anchors {
					left: parent.left; leftMargin: portText.mbStyle.marginDefault
					right: parent.right; rightMargin: portText.mbStyle.marginDefault
					bottom: parent.bottom; bottomMargin: portText.mbStyle.marginDefault
					top: parent.top; topMargin: portText.mbStyle.marginDefault
				}
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignLeft
				text: root.getInfoText()
				font.pixelSize: portText.mbStyle.fontPixelSize - 3
				property bool animating: false
				property int dotCount: 1
				Timer {
					id: statusTimer
					interval: 400
					running: usbDeviceInfo.animating
					repeat: true
					onTriggered: {
						usbDeviceInfo.dotCount = usbDeviceInfo.dotCount % 3 + 1;
					}
				}
			}
		}
		Rectangle {
			id: usbLogRect
			color: "#e7e5e5"
			radius: 4
			anchors {
				top: usbDeviceRect.bottom; topMargin: portText.mbStyle.marginDefault
				left: parent.left; leftMargin: portText.mbStyle.marginDefault
				right: parent.right; rightMargin: portText.mbStyle.marginDefault
				bottom: parent.bottom; bottomMargin: portText.mbStyle.marginDefault 
			}
			width: parent.width
			 
	 
			Text {
				id: usbLog
				anchors {
					left: parent.left; leftMargin: portText.mbStyle.marginDefault
					right: parent.right; rightMargin: portText.mbStyle.marginDefault
					bottom: parent.bottom; bottomMargin: portText.mbStyle.marginDefault
					top: parent.top; topMargin: portText.mbStyle.marginDefault
				}
				wrapMode: Text.WordWrap
				horizontalAlignment: Text.AlignLeft
				text: ""
				font.pixelSize: portText.mbStyle.fontPixelSize - 3
			}
		}

	}


	pageToolbarHandler: ToolbarHandler {
 		
		leftText: root.step != "" ? "Cancel" : "Detect Usb Device"
		rightText: root.step == "get-device-done" ? "Apply" : ""

		function rightAction() {
			root.doStep("apply-device")
		}

		function leftAction() {
			
			if (step == "") {
				root.doStep("get-device")
			} else  {
				root.doStep()
			}
 
		}
 
	}
 
	function doStep(step, done) {
		step = (step || "") + (done ? "-done" : "")
		root.step = step
 
		console.log("doStep:" + step)

		switch (step) {
		case "":
			deviceModel = null
		case "apply-device-done":
		case "get-device-done":
			processRunner.stop()
			processRunner.operationName = ""
			usbDeviceInfo.animating = false
			
			break
		case "get-device":
			if (processRunner.operationName)
				return
			processRunner.operationName = step
			processRunner.start([step])
			usbDeviceInfo.animating = step == "get-device"
			usbDeviceInfo.dotCount = 1
		case "apply-device":
			if (processRunner.operationName)
				return
			processRunner.operationName = step
			processRunner.start([step])
			break
		default:
			console.log("Error:doStep:invalid-step")
			break
		}
	}

  function getInfoText() {
		if (processRunner.operationName=="get-device")
			return "Plug in device " + Array(usbDeviceInfo.dotCount + 1).join(".")
		if (processRunner.operationName=="apply-device")
			return processRunner.output
		if (!deviceModel)
			return ""//"Device: None"

		var info
		info = "Port: " + (deviceModel?.port || "") + "\n" +
			"Vendor: " + (deviceModel?.vendor_db || deviceModel?.vendor || deviceModel?.vendor_id || "") + "\n" +
			"Model: " + (deviceModel?.model_db || deviceModel?.model || deviceModel?.model_id  || "") + "\n" +
			"Serial: " + (deviceModel?.serial || deviceModel?.serial_short || "") + "\n" 
			//"Revision: " + (deviceModel?.revision || deviceModel?.revision || "") + "\n"
		
		return info
	}

	function loadDeviceFromJson(jsonText) {
		var device = JSON.parse(jsonText)
		root.deviceModel = device[0]
	}

	ProcessRunner {
		id: processRunner
		helperPath: "/data/dev/utils/opkg-manager/src/data/opkg-manager/serial-device-installer-qml"
 
		property string output: ""
		property string packagesErrorLine: ""
		property var logCallback

		onOutputLine: function(line) {
 
			if (processRunner.operationName == "apply-device")
				usbDevice
				output += line

		}

		onErrorLine: function(line) {
			console.error("PageSettingsInetboxSetup:" + line)
 
			packagesErrorLine = line
		}
		// Now expects the helper to output the file path of the JSON file
		onFinished: function(exitCode, exitStatus) {
			console.log("onFinished")
			try {
				
				if (exitCode === 0 && exitStatus === 0) {
					switch (processRunner.operationName) {
						case "get-device":
							//console.log(">>>" + lastOutputLine + "<<<")
							loadDeviceFromJson(output)
							doStep(processRunner.operationName, true)
							break;
						case "apply_device":
							doStep(processRunner.operationName, true)
							break;
					}
				} else {
					let msg = packagesErrorLine.length ? packagesErrorLine : qsTr("Operation failed");
					usbDeviceInfo.animating = false;
					toast.createToast(msg);
 
				}
				processRunner.operationName = "";
			} catch (err) {
				console.log("ERROR:" + err.lineNumber + ":" + err.message);
				usbDeviceInfo.animating = false;
				//toast.createToast(qsTr(err.message));
			}
			output = ""
		}
		
	}

}