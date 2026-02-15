import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
import "PageSettingsOPKGPackages.js" as Vm

MbPage {
	id: root
	title: qsTr("Package details")
	property bool installInProgress: processRunner && processRunner.operationName !== ""
 
	property var model
	property var processRunner

	VBusItem {
		id: noActionSetting
		bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgManager/NoAction")
	}

 Item {
    anchors.fill: parent

		OpkgHeaderDescriptionItem {
			id: packageDetails
			header: root.model ? root.model.name : ""
			description: Vm.getDescription(model, false, true)
			showCompact: false
			hasSubpage: false
			editable: false
		}
	
		// Non-selectable, scrollable log area (direct child of MbPage)
		Item {
			id: logArea
			anchors.top: packageDetails.bottom
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 0 // adjust this value to match your toolbar height
			property var logLines: []
			function addLogLine(line) {
				logLines.push(line)
				logText.text = logLines.join("\n")
				logFlickable.contentY = logFlickable.contentHeight - logFlickable.height
			}
	
			Rectangle {
				anchors.fill: parent
				color: "#f8f8f8"
				border.color: "#cccccc"
				radius: 4
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
							text: logArea.logLines.join("\n")
							font.pixelSize: 13
							color: "#333"
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
			}
		}
 }
 
	pageToolbarHandler: ToolbarHandler {

		leftText: {
			var item = root.model
			if (item) {
				var hasInstalled = item.installedVersion && item.installedVersion.length > 0
				var hasAvailable = item.version && item.version.length > 0
				if (hasInstalled && hasAvailable) {
					return qsTr("Upgrade")
				} else if (!hasInstalled && hasAvailable) {
					return qsTr("Install")
				}
			}
			return qsTr("")
		}
		function leftAction() {
			var item = root.model
			var action=""
			if (item) {
				var hasInstalled = item.installedVersion && item.installedVersion.length > 0
				var hasAvailable = item.version && item.version.length > 0
				if (hasInstalled && hasAvailable) {
					action = "upgrade"
				} else if (!hasInstalled && hasAvailable) {
					action = "install"
				}
			}

			doInstllerAction(action) 
		}

		rightText: {
        var item = root.model;
        if (item && item.installedVersion) {
						return qsTr("Remove");
				}
        return qsTr("");
		}
 
		function rightAction() { doInstllerAction("remove") }

	}

	function doInstllerAction(action)
	{
		if (!processRunner || installInProgress)
			return

		logArea.logLines = [];
		processRunner.logCallback = logArea.addLogLine.bind(logArea)
		
		var noAction = noActionSetting.valid ? noActionSetting.value : false;
 
		Vm.doInstllerAction(processRunner, action, root.model.name, noAction)

	}

}
