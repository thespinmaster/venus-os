import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils

MbPage {
	id: root
	title: qsTr("Package details")

	property var selectedPackage

	property var logAreaRef: null
	VBusItem {
		id: noActionSetting
		bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgManager/NoAction")
	}
	property bool installInProgress: installRunner.operationName !== ""
	pageToolbarHandler: ToolbarHandler {

		leftText: {
			var item = root.selectedPackage
			if (item) {
				var hasInstalled = item.installedVersion && item.installedVersion.length > 0
				var hasAvailable = item.version && item.version.length > 0
				if (hasInstalled && hasAvailable) {
					return qsTr("Upgrade")
				} else if (!hasInstalled && hasAvailable) {
					return qsTr("Install")
				}
			}
		}
		function leftAction() {
			var item = root.selectedPackage
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

			doAction(action) 
		}

		rightText: {
        var item = root.selectedPackage;
        if (item && item.installedVersion) {
						return qsTr("Remove");
				}
        return qsTr("");
		}
 
		function rightAction() { doAction("remove") }

		function doAction(action)
		{
			if (action == "" || !root.selectedPackage || !root.selectedPackage.name || !root.logAreaRef) {
				return;
			}

			// Clear log area
			root.logAreaRef.logLines = [];
			root.logAreaRef.addLogLine("--- Starting " + action + " for: " + root.selectedPackage.name + " ---");

			var noAction = noActionSetting.valid && noActionSetting.value !== undefined && noActionSetting.value !== null ? !!noActionSetting.value : false;

			var args = [action + "-package", root.selectedPackage.name];
			if (noAction) {
				args.push("--noaction");
			}
			installRunner.operationName = action;
			installRunner.start(args);
		}
	}
	ProcessRunner {
		id: installRunner
		helperPath: "/data/dev/utils/opkg-manager/src/data/opkg-manager/opkg-common"
 
		onOutputLine: function(line) {
			if (root.logAreaRef) root.logAreaRef.addLogLine(line);
		}
		onErrorLine: function(line) {
			if (root.logAreaRef) root.logAreaRef.addLogLine("ERROR: " + line);
		}
		onFinished: function(exitCode, exitStatus) {
			if (root.logAreaRef) {
				root.logAreaRef.addLogLine("--- Finished " + installRunner.operationName + ". Exit code: " + exitCode + ", status: " + exitStatus + " ---"); 
			}
			installRunner.operationName = "";
			root.selectedPackage.installedVersion = root.selectedPackage.version
		}
	}

	OpkgPackageItem {
		id: packageDetails
		name: root.selectedPackage.name
		description: root.selectedPackage.description
		version: root.selectedPackage.version
		feed: root.selectedPackage.feed
		installedVersion: root.selectedPackage.installedVersion
		detailsFontPixelSize: 14
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
		Component.onCompleted: {
			root.logAreaRef = logArea;
		 
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
