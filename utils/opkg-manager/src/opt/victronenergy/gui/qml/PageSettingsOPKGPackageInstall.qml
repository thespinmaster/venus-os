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

 MbItem {
		id: itm
    anchors.fill: parent
		
		OpkgHeaderDescriptionItem {
			id: packageDetails
			header: (root.model?.name) || ""
			description: Vm.getDescription(model, false, true)
			showCompact: false
			hasSubpage: false
			editable: false
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.leftMargin: itm.mbStyle.marginDefault
			anchors.rightMargin: itm.mbStyle.marginDefault
		}
	
		// Non-selectable, scrollable log area (direct child of MbPage)
		Item {
			id: logArea
			anchors {
				top: packageDetails.bottom
				left: parent.left
				right: parent.right
				bottom: parent.bottom
				bottomMargin: 0 // adjust this value to match your toolbar height
			}

			property var logLines: []
			function addLogLine(line) {

				logLines.push(line)
				logText.text = logLines.join("\n")

				if (logFlickable.contentHeight > logArea.height)
					logFlickable.contentY = logFlickable.contentHeight - logFlickable.height
			}
	
			Rectangle {
				anchors.fill: parent
				anchors.leftMargin: itm.mbStyle.marginDefault
				anchors.rightMargin: itm.mbStyle.marginDefault

				color: itm.mbStyle.themer?.backgroundColor2 || "#cecece"
				border.color: "#767676"
				radius: 8
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
				var hasInstalled = item.installedVersion?.length > 0
				var hasUpgrade = Vm.versionGreaterThan(item.version, item.version)
				//console.log(hasInstalled + ", " + hasUpgrade)
				if (hasUpgrade) {
					return qsTr("Upgrade")
				} else if (!hasInstalled) {
					return qsTr("Install")
				}
			}
			return qsTr("")
		}
		function leftAction() {
			var item = root.model
			var action=""
			if (item) {
				var hasInstalled = item.installedVersion?.length > 0
				var hasUpgrade = Vm.versionGreaterThan(item.version, item.version)
				if (hasUpgrade) {
					action = "upgrade"
				} else if (!hasInstalled) {
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
