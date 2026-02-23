import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
import OpkgManager 1.0
import QtQuick.Controls
 
MbPage {
	id: root
	title: qsTr("Inetbox Device Setup")
 
	property string settingsPrefix: "com.victronenergy.settings/Settings/Devices/dbus_inetbox"
	property string currentPort: ""
  property string step: ""
  property int fontSize: 14
  property string devicePort
  property string applyingDeviceLog
	property var deviceModel: null
  property var theme:
	
	VBusItem { id: portName; bind: Utils.path(settingsPrefix, "/Port") }
 
	Component.onCompleted: getPortState()
 
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
			color: header.mbStyle.themer?.backgroundColor2 || "#cecece"
			radius: 4
			anchors {
				top: portText.bottom; topMargin: portText.mbStyle.marginDefault
				left: parent.left; leftMargin: portText.mbStyle.marginDefault
				right: parent.right; rightMargin: portText.mbStyle.marginDefault
			}
			width: parent.width
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
				font.pixelSize: portText.mbStyle.fontPixelSize - 3
				text: getInfoText()
			}
		}
		Rectangle {
			id: outputLog
			color: header.mbStyle.themer?.backgroundColor2 || "#cecece"
			radius: 4
			anchors {
				top: usbDeviceRect.bottom; topMargin: portText.mbStyle.marginDefault
				left: parent.left; leftMargin: portText.mbStyle.marginDefault
				right: parent.right; rightMargin: portText.mbStyle.marginDefault
				bottom: parent.bottom; bottomMargin: portText.mbStyle.marginDefault 
			}
			width: parent.width
			Flickable {
				id: logFlickable
				anchors.fill: parent
				contentWidth: logText.width
				contentHeight: logText.height
				clip: true
				Column {
					width: logFlickable.width - 12
					spacing: 0
					Text {
						id: logText
						text: outputLog.logLines.join("\n")
						font.pixelSize: 13
						color: portText.mbStyle.textColor
						wrapMode: Text.Wrap
						width: logFlickable.width - 12
						horizontalAlignment: Text.AlignLeft
						verticalAlignment: Text.AlignTop
						anchors.left: parent.left
						anchors.right: parent.right
						anchors.margins: 6
					}
					Rectangle {
						width: logFlickable.width - 12
						height: 10 // bottom padding to prevent clipping
						color: "transparent"
					}
				}
			}
			property var logLines: []
			property bool isWorking: false
			property int dotCount: 1
			property string baseWorking:""

			Timer {
				id: progressTimer
				interval: 400
				running: outputLog.isWorking
				repeat: true
				onTriggered: {
					
					if (outputLog.logLines.length > 0) {
					
						// Update dotCount first
						outputLog.dotCount = outputLog.dotCount % 3 + 1
						outputLog.logLines[outputLog.logLines.length - 1] = outputLog.baseWorking + Array(outputLog.dotCount +1).join(".")
						logText.text = outputLog.logLines.join("\n")
					}
				
				}
			}

			function startIsWorking(line, clear) {
				if (clear) 
					outputLog.clear()
				addLine(line)
				baseWorking=line
				isWorking=true
				dotCount=1
			}

			function stopIsWorking(clear) {
				if (clear) {
					outputLog.logLines=[]
					logText.text = ""
					return
				}
					
				if (!isWorking)
					return
				isWorking=false
				progressTimer.stop()
				outputLog.logLines[outputLog.logLines.length - 1] = baseWorking
				logText.text = outputLog.logLines.join("\n")
				dotCount=1
			}

			function clear() { 			
				stopIsWorking(true)
			}

			function addLine(line) {
				// Stop isWorking animation when a new line is added
				stopIsWorking()
				logLines.push(line)
				logText.text = logLines.join("\n")
				if (logFlickable.contentHeight > outputLog.height)
					logFlickable.contentY = logFlickable.contentHeight - logFlickable.height
			}
		}

	}

	pageToolbarHandler: ToolbarHandler {
 		
		leftText: root.step == "canceling" ? "" : 
				(root.step != "" ? "Cancel" : "Detect Usb Device")
		rightText: root.showApply() ? "Apply" : ""

		function rightAction() {
			root.doStep("apply-device")
		}

		function leftAction() {			
			if (step == "") {
				root.doStep("detect-device")
			} else  {
				root.doStep()
			}
		}
 
	}
 
	function showApply() {
		return true
	 	if (root.step != "detect-device-done")
			return false
		if (root.step == "cancelling")
			return false

		if (!deviceModel)
			return false
		if (deviceModel.port.length==0)
			return false
		if (deviceModel.process.length > 0) 
			return false 
		return true
	}

	function doStep(step, done) {

		step = (step || "") + (done ? "-done" : "")
		root.step = step
 
		//console.log("doStep:" + step)

		switch (step) {
		case "canceling-done":

			outputLog.baseWorking = "Cancelled"
			outputLog.stopIsWorking()
			root.step=""
			break
		case "":
			deviceModel = null
		case "apply-device-done":		
		case "detect-device-done":
 
			if (processRunner.operationName == "") 
				return

			if (step == "" && processRunner.running) {
				root.step="canceling"
				outputLog.startIsWorking("Canceling")
				processRunner.operationName = root.step
				processRunner.stop()
			}
			break
		case "detect-device":
			if (processRunner.operationName)
				return
			if (step == "detect-device")
				outputLog.startIsWorking("Please insert (or re-insert) the usb device", true)

			processRunner.operationName = step
			processRunner.start([step])

		case "apply-device":
			if (processRunner.operationName)
				return
			processRunner.operationName = step
			outputLog.clear()
			processRunner.start([step])
			break
		default:
			console.log("Error:doStep:invalid-step")
			break
		}
	}
 
  function getInfoText() {

		if (processRunner.operationName=="detect-device")
			return ""

		if (processRunner.operationName=="apply-device")
			return processRunner.output
		
		if (!deviceModel)
			return ""

/*
{
	"port":"ttyUSB0",
	"process":"",
  "ID_MODEL":"Intetbox",
  "ID_SERIAL":"FTDI_Intetbox_BG02CS2X",
  "ID_MODEL_ID":"6001",
  "ID_VENDOR_ID":"0403",
  "ID_VENDOR_FROM_DATABASE":"",
  "ID_SERIAL_SHORT":"BG02CS2X",
  "ID_MODEL_FROM_DATABASE":"",
  "ID_VENDOR":"FTDI"
}
*/
		
		var info = "Port:\t" + (deviceModel.port || "") + "\n" +
			"Vendor:\t" + (deviceModel.ID_VENDOR_FROM_DATABASE || deviceModel.ID_VENDOR || deviceModel.ID_VENDOR_ID || "") + "\n" +
			"Model:\t" + (deviceModel.ID_MODEL_FROM_DATABASE || deviceModel.ID_MODEL || deviceModel.ID_MODEL_ID  || "") + "\n" +
			"Serial:\t" + (deviceModel.ID_SERIAL || deviceModel?.ID_SERIAL_SHORT || "") + "\n" 
			"Process:\t" + deviceModel.process || "none"
			//"Revision: " + (deviceModel?.revision || deviceModel?.revision || "") + "\n"
		
		return info
	}
 
	function getPortState() {
		//TODO
		currentPort = portName?.value || "None"
	}
	
	function loadDeviceFromJson(jsonText) {
		console.log(jsonText)
		root.deviceModel = JSON.parse(jsonText)		
	}

	ProcessRunner {
		id: processRunner
		helperPath: "/data/dev/utils/opkg-manager/src/data/opkg-manager/serial-device-installer-qml"
 
		property string jsonString: ""
		property string packagesErrorLine: ""
 
		onOutputLine: function(line) {
 			if (processRunner.stopping) {
				console.log("stopping:" + line)
				return
			}
				
			if (jsonString) {
				jsonString += line
			} else if (line.charAt(0) === "{") {
				jsonString += line
			} else {
				outputLog.addLine(line)
			}
 
		}

		onErrorLine: function(line) {
			console.error("PageSettingsInetboxSetup:" + line)
			outputLog.addLine(line)
			packagesErrorLine = line
		}
		
		// Now expects the helper to output the file path of the JSON file
		onFinished: function(exitCode, exitStatus) {
			console.log("onFinished:" + processRunner.operationName + ", " + exitCode + ", " + exitStatus)
 
			try {   

				if (processRunner.operationName == "canceling") {
					doStep(processRunner.operationName, true)
					return
				}

				if (exitCode === 0 && exitStatus === 0) {
					switch (processRunner.operationName) {
						case "canceling":
		
						case "detect-device":
						case "apply_device":
						
							if (jsonString) 
								loadDeviceFromJson(jsonString)
							doStep(processRunner.operationName, true)
							break;
					}
				} else {
					let msg = packagesErrorLine.length ? packagesErrorLine : qsTr("Operation failed");
					outputLog.stopIsWorking = false;
					toast.createToast(msg);
					root.doStep()
				}
 
			} catch (err) {
				let msg = "ERROR:" + err.lineNumber + ":" + err.message
				console.log(msg);
				outputLog.stopIsWorking;
				outputLog.addLine(msg)
				root.doStep()
				//toast.createToast(qsTr(err.message));
			} finally {
				jsonString=""
				packagesErrorLine=""
				processRunner.operationName = "";
			}
			
		}
		
	}

}