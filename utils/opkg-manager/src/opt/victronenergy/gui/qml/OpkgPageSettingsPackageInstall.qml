import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
import "opkgPageSettingsPackages.js" as Vm

MbPage {
	id: root
	title: qsTr("Package details")
 
	property var packageModel
	
	// protect the back button from being pressed while processing commands.
 	MouseArea {
		x:0; y:-mbTools.height
		width: mbTools.height; height: mbTools.height
		visible: isBusy // isBusy, parent page (OpkgPageSettingsPackages)
	}

	Component.onCompleted: {
		console.log("Component.onCompleted:", title)
		//rootWindow.dumpItemTree()
 	}
 
	Component.onDestruction: {
		//console.log("Component.onCompleted:", title)
 	}

 	MbItem {
		id: itm
    anchors.fill: parent
		
		OpkgHeaderDescriptionItem {
			id: packageDetails
			header: packageModel?.name || ""
			description: Vm.getDescription(packageModel, false, true)
			showCompact: false
			hasSubpage: false
			editable: false
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.leftMargin: itm.mbStyle.marginDefault
			anchors.rightMargin: itm.mbStyle.marginDefault
		}
	
		// Non-selectable, scrollable log area
		Item {
			id: logArea
			anchors {
				top: packageDetails.bottom
				left: parent.left
				right: parent.right
				bottom: parent.bottom
				bottomMargin: 2
			}

			property var logLines: []
			Component.onCompleted: {
				if (!logLines) logLines = [];
			}
			function addLogLine(line) {

				logLines.push(line)
				logText.text = logLines.join("\n")

				if (logFlickable.contentHeight > logArea.height)
					logFlickable.contentY = logFlickable.contentHeight - logFlickable.height
			}
	
			Rectangle {
				property color clr: itm.mbStyle.valueColor
				anchors.fill: parent
				anchors.topMargin: 2
				anchors.leftMargin: itm.mbStyle.marginDefault
				anchors.rightMargin: itm.mbStyle.marginDefault

				color: itm.mbStyle.themer?.backgroundColor2 || "transparent"
				border.color: itm.mbStyle.themer?.borderColor || Qt.rgba(clr.r, clr.g, clr.b, 0.5) 
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
							color: itm.mbStyle.themer?.textColor || itm.mbStyle.textColor
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
 
			if (packageModel) {
				//console.log("ver1:" + packageModel.version + ", installed ver:" +  packageModel.installedVersion)
				var hasUpgrade = Vm.versionGreaterThan(packageModel.version, packageModel.installedVersion)
 
				if (hasUpgrade) {
					return qsTr("Upgrade")
				} else if (!packageModel.installedVersion?.length > 0) {
					return qsTr("Install")
				}
			}
			return qsTr("")
		}
		function leftAction(mouse) {
 			if (!mouse  || leftAction==="")
				return
			var action=""

			if (packageModel) {
 
				var hasUpgrade = Vm.versionGreaterThan(packageModel.version, packageModel.installedVersion)
				if (hasUpgrade) {
					action = "upgrade"
				} else if (!packageModel.installedVersion?.length > 0) {
					action = "install"
				}
			}

			doInstllerAction(action) 
		}

		rightText: {
 
        if (packageModel && packageModel.installedVersion) {
						return qsTr("Remove");
				}
        return qsTr("");
		}
 
		function rightAction(mouse) { 
			if (!mouse || rightText==="")
				return
			doInstllerAction("remove") 
		}

	}

	function doInstllerAction(action) {
		if (!processRunner || processRunner.operationName !== "")
			return

		logArea.logLines = [];
		processRunner.logCallback = logArea.addLogLine.bind(logArea)
		
		var noAction = noActionSetting.valid ? noActionSetting.value : false;

		Vm.doInstllerAction(processRunner, action, packageModel.name, noAction)

	}

}
