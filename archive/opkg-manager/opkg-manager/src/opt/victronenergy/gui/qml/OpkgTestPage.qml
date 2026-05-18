import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
import "opkgPageSettingsPackages.js" as Vm
 
MbPage {
	id: root

	property MbStyle mbStyle: MbStyle {}
  property var outputLog
	property VBusItem opkgmanagerServiceItem: VBusItem {
		bind: Utils.path("com.victronenergy.opkgmanager", "/ServiceName")
		onValueChanged: {
			service_status()
		}
	}
 
	function service_status() {
		if (outputLog == undefined)
			return;

		var running = opkgmanagerServiceItem.valid
		var msg = "opkgmanager service is " + (running ? "up" : "down")
		outputLog.log(msg)
	}
	onOutputLogChanged: {
		service_status()
	}
 
	model: packageModel

	ListModel {
		id: packageModel
	}

	delegate: Component {
		OpkgHeaderDescriptionItem {
			header: model.name
			description: (model.installedVersion ? "Installed: " + model.installedVersion + "  " : "") +
						 "Available: " + model.version + "  Feed: " + model.feed
		}
	}
 
	listview.footer: Item {
		id: footerItem
		height: Math.max(0, root.listview.height - (root.listview.count * root.mbStyle.itemHeight))
		Component.onCompleted: root.outputLog = outputLogArea
		anchors {
			left: parent.left
			right: parent.right
		}
 
		OpkgOutputLogArea {
			id: outputLogArea
			mbStyle: root.mbStyle
			fontSize: 16
			anchors {
				top: parent.top; topMargin: root.mbStyle.marginDefault
				left: parent.left; leftMargin: root.mbStyle.marginDefault
				right: parent.right; rightMargin: root.mbStyle.marginDefault
				bottom: parent.bottom
				bottomMargin: root.mbStyle.marginDefault
			}
			width: parent.width
			height: 100
		}

		Rectangle {
			id: outputLogCornerButton
			width: 16
			height: 16
			radius: 8
			color: "#3a3a3a"
			border.width: 1
			border.color: "#9a9a9a"
			anchors {
				right: outputLogArea.right
				bottom: outputLogArea.bottom
				rightMargin: 6
				bottomMargin: 6
			}
			z: 1

			MouseArea {
				anchors.fill: parent
				onClicked: { outputLog.clear() }
			}
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
 		
		leftText: "do test 1"
		//rightText: "do test 2"
		function rightAction() { 

		}

		function leftAction(mouse) {
			processRunner.operationName = "package list"
			processRunner.start(["package", "list"])
		}
 
	}

	OpkgServiceProcess {
		id: processRunner

		onHttpJsonReady: function(jsonText) {
			try {
				packageModel.clear()
				Vm.loadPackagesFromJson(jsonText, packageModel)
				var msg = "Loaded " + packageModel.count + " packages"
				console.log(msg)
				if (root.outputLog)
					root.outputLog.addLine(msg)
			} catch (e) {
				var errMsg = "Error loading packages: " + e
				console.log(errMsg)
				if (root.outputLog)
					root.outputLog.addLine(errMsg)
			}
		}

		onHttpJsonError: function(message) {
			console.log(message)
			if (root.outputLog)
				root.outputLog.addLine(message)
		}

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
					//doStep(processRunner.operationName, true)
					return
				}
 
				if (exitCode === 0 && exitStatus === 0) {
					console.log("todo")
				} else {
 					root.doStep("error")
				}
 
			} catch (err) {
				var msg = `ERROR:${err.lineNumber}: ${err.message}`
				console.log(msg);
				if (root.outputLog)
					root.outputLog.addLine(msg)
			}
			
		}
	}

}