import QtQuick
import Victron.VenusOS

import "."

Page {
	id: root
	
	property bool cancelled: false

	Component.onCompleted: {
		console.log("Component.onCompleted:")
	}

	Flow {
		id: testButtonFlow
		anchors {
			top: parent.top
			left: parent.left
			right: parent.right
			leftMargin: Theme.geometry_page_content_horizontalMargin
			rightMargin: Theme.geometry_page_content_horizontalMargin
			topMargin: Theme.geometry_overviewPage_widget_content_topMargin
		}
		spacing: 10

		MomentaryButton {
			id: btnTestOpkgBridge
			text: "Test OpkgBridge (Heavy Load)"
			leftPadding: 12; rightPadding: 12
			onClicked: {
				opkgBridge.start("package", "remove", "opkg-manager", "--noaction", "-V4")
			}
		}

		MomentaryButton {
			id: btnTestReader
			text: "Test Reader"
			implicitWidth: 150
			onClicked: {
				dataReader.readAll("packages")
			}
		}

		MomentaryButton {
			id: btnTestErrorFormatting
			text: "Test Error Formatting"
			leftPadding: 12; rightPadding: 12
			onClicked: {
				logViewer.clear()
				logViewer.log("Starting test test-error-formatting")
				opkgBridge.start("test", "test-error-formatting")
			}
		}

		MomentaryButton {
			id: btnTestIsWorking
			text: "Test isWorking (...)"
			leftPadding: 12; rightPadding: 12
			onClicked: {
				logViewer.clear()
				logViewer.log("Checking USB device...")
				workingAnimationDoneTimer.restart()
			}
		}

		MomentaryButton {
			id: btnCancel
			text: "Cancel"
			implicitWidth: 150
			enabled: opkgBridge.running
			onClicked: {
				opkgBridge.stop()
			}
		}
	}

	OpkgLogViewer {
		id: logViewer
		anchors {
			top: testButtonFlow.bottom
			topMargin: 10
			left: parent.left
			right: parent.right
			bottom: parent.bottom
			leftMargin: Theme.geometry_page_content_horizontalMargin
			rightMargin: Theme.geometry_page_content_horizontalMargin

		}
	}

	Timer {
		id: workingAnimationDoneTimer
		interval: 2200
		repeat: false
		onTriggered: {
			logViewer.log("USB device check complete")
		}
	}
	OpkgBridge {
		id: opkgBridge
		traceEnabled: true

		onRunningChanged: {
			logViewer.log("onRunningChanged: " + running)
			//if (running)
				//logViewer.clear()
		}

		onError: function(line) {
			logViewer.log("error " + line)
		}

		onOutput: function(line) {
			//if (!root.cancelled)
				logViewer.log(line)

		}

		onFinished: function(result) {
			logViewer.log("onFinished: exitCode:" + result.exitCode + ", exitStatus:" + result.exitStatus)
		}
	}

	OpkgJsonReader {
		id: dataReader
		//uidPrefix: BackendConnection.uidPrefix()

		onJsonReady: function(jsonData, jsonText, name) {
			if (name !== "packages") {
				return
			}

			logViewer.log(jsonText)
		}
		onJsonError: function(error, name) {
			if (name !== "packages") {
				return
			}
			Global.showToastNotification(VenusOS.Notification_Warning, error, 3000)
		}
	}

 }
