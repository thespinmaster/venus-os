import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
import "opkgPageSettingsPackages.js" as Vm

MbPage {
	id: root
	title: qsTr("Package details")
 
	property var packageModel
	property var packageListModel
	property int packageIndex: -1
	property bool upgradeAvailable: false
  property var footer

	function refreshPackageModel() {
		if (!packageListModel)
			return
		if (packageIndex < 0 || packageIndex >= packageListModel.count)
			return
		footer = Vm.getFooter(packageModel, showCompact)
		packageModel = packageListModel.get(packageIndex)
		upgradeAvailable = packageModel && Vm.versionGreaterThan(packageModel.version, packageModel.installedVersion)
	}
 
	// protect the back button from being pressed while processing commands.
 	MouseArea {
		x:0; y:-mbTools.height
		width: mbTools.height; height: mbTools.height
		visible: isBusy // isBusy, parent page (OpkgPageSettingsPackages)
	}

	Component.onCompleted: {
		refreshPackageModel()
		console.log("Component.onCompleted:", title)
		//rootWindow.dumpItemTree()
 	}

	Connections {
		target: opkgBridge
		function onRunningChanged() {
			if (!opkgBridge.running)
				refreshPackageModel()
		}
	}
 
	Component.onDestruction: {
		//console.log("Component.onCompleted:", title)
 	}

 	MbItem {
		id: itm
    anchors.fill: parent
		
		OpkgHeaderDescriptionItem {
			id: packageDetails
			header: packageModel == undefined ? "" : packageModel.name
			description: packageModel == undefined ? "" : packageModel.description
			footer: root.footer
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
	  			var upgradeAvailable = root.upgradeAvailable

				if (upgradeAvailable) {
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
 
				var upgradeAvailable = Vm.versionGreaterThan(packageModel.version, packageModel.installedVersion)
				if (upgradeAvailable) {
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
		if (!opkgBridge || opkgBridge.operationName !== "")
			return

		logArea.logLines = [];
		opkgBridge.logCallback = logArea.addLogLine.bind(logArea)
		
		var args = ["package", action, packageModel.name]
		var noAction = noActionSetting.valid ? noActionSetting.value : false;
		if (noAction)
			args.push("--noaction")
		
		console.log("doInstllerAction:" + args)

		opkgBridge.logCallback("--- Starting " + action + " for: " + packageModel.name + " ---")
		opkgBridge.packageIndex = packageIndex
		opkgBridge.operationName = action;
		opkgBridge.start(args);

	}

}
