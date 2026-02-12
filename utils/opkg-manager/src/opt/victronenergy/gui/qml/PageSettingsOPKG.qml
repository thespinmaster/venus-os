import QtQuick 2

import com.victron.velib 1.0
import net.connman 0.1
import OpkgManager 1.0
import "utils.js" as Utils
import QtQuick.Controls
import QtQuick.Layouts 1.0

MbPage {
  
	// "√✔⚠✘✗★☆⬤●▲▼►◄" useful symbols

 	property string packagesOutput: ""
	property string packagesErrorLine: ""
	property bool showCompact: compactSetting.valid && compactSetting.value !== 0
 
	property bool installInProgress: packageRunner.operationName !== ""
	property var logAreaRef
  property var selectedPackage

	id: root
	title: qsTr("Open Package Manager")

	VBusItem {
		id: compactSetting
		bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgManager/ShowCompact")
	}
	ListModel { id: packageModel}

	Component.onCompleted: {
		loadPackages("list-packages", "")
	}
 
	pageToolbarHandler: ToolbarHandler {
 
		function centerAction() {
			loadPackages("list-packages-update", "update")
		}

		centerText: qsTr("Refresh Feeds")  

	}

	function loadPackages(operationName, args) {
		if (packageRunner.running) {
			return
		}
		packageModel.clear()
		packagesOutput = ""
		packagesErrorLine = ""
		packageRunner.operationName = operationName
		packageRunner.start(["list-packages", args])
	}

	function loadPackagesFromJson(jsonText) {
		packageModel.clear()
		var packages = JSON.parse(jsonText)
		for (var i = 0; i < packages.length; i++) {
			var pkg = packages[i]
			packageModel.append({
				name: pkg.name || "",
				description_short: pkg.description_short || "",
				description_long: pkg.description_long || "",
				version: pkg.version || "",
				feed: pkg.feed || "",
				installedVersion: pkg.installedVersion || ""
			})
		}
		// No need to call refreshPackageItems
	}

	// load packages from a JSON file using FileHelper.readFile
	function loadPackagesFromFile(filePath) {
		try {
			var jsonText = FileHelper.readFile(filePath);
			if (!jsonText || jsonText.length === 0) {
				toast.createToast(qsTr("Failed to read package list file 1: ") + filePath);
				return;
			}
			loadPackagesFromJson(jsonText);
			if (packageRunner.operationName === "list-packages-update") {
				toast.createToast(qsTr("Refresh completed"));
			}
 
		} catch (err) {
			console.debug("ERROR reading package list file:", err);
			toast.createToast(qsTr("Failed to read package list file 2: ") + filePath);
		}
	}

	model: packageModel

	function getDescription(modelData) {
			if (showCompact)
				return
				
			var installed = modelData.installedVersion.length > 0
			return modelData.description_short + "\n" +
					"Installed: " + (installed ? modelData.installedVersion : " - ")  + 
					"  Available: " + modelData.version + 
					"  Feed: " + modelData.feed
	}
	function getDetailDescription(modelData) {
		return getDescription(modelData)
	}

	delegate: OpkgHeaderDescritionItem {
		id: packageItem
		header: (model.installedVersion.length > 0 ? "✔ " : "") + model.name
		description: root.getDescription(modelData)
		showCompact: root.showCompact
		hasSubpage: true
		property bool showAvailable: root.versionGreaterThan(model.version, model.installedVersion)
		property var modelData: model

		subpage: Component {
			
			MbPage {
				id: mypage
				title: qsTr("Details")
				anchors.fill: parent
				ColumnLayout {
					anchors.fill: parent
					spacing: 0
					OpkgHeaderDescritionItem {
						id: packageDetails
						header: packageItem.header
						description: root.getDetailDescription(packageItem.modelData)

					}
					Item {
						id: logArea
						Layout.fillWidth: true
						Layout.fillHeight: true
						property var logLines: ["logs...."]
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
							color: "#ced9dd"
							border.color: "#cccccc"
							radius: 6
							
							Flickable {
								id: logFlickable
								anchors.fill: parent
								contentWidth: logText.width
								contentHeight: logText.height
								clip: true
								Column {
									width: logFlickable.width - 12
									spacing: 0
									anchors.left: parent.left
									anchors.right: parent.right
									anchors.top: parent.top
									anchors.margins: 6
									Text {
										id: logText
										text: logArea.logLines.join("\n")
										font.pixelSize: 13
										color: "#000000"
										wrapMode: Text.Wrap
										width: logFlickable.width - 12
										horizontalAlignment: Text.AlignLeft
										verticalAlignment: Text.AlignTop

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
					var item = packageItem.modelData
					if (item) {
						console.debug("yep")
					} else {
						console.debug("nope")
					}
					return qsTr("hello")
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
			}
		}

	}

	ProcessRunner {
		id: packageRunner
		helperPath: "/data/dev/utils/opkg-manager/src/data/opkg-manager/opkg-common"
 
		property string lastOutputLine: ""
 
		onOutputLine: function(line) {
			lastOutputLine = line
		}
		onErrorLine: function(line) {
			packagesErrorLine = line
		}
		// Now expects the helper to output the file path of the JSON file
		onFinished: function(exitCode, exitStatus) {
			console.debug("exitCode=" + String(exitCode) + ", exitStatus=" + String(exitStatus))
			if (exitCode === 0 && exitStatus === 0) {
				if (packageRunner.operationName === "list-packages" || packageRunner.operationName === "list-packages-update") {
					// lastOutputLine should be the file path
					var filePath = lastOutputLine.trim();
 
					if (filePath.length > 0) {
						loadPackagesFromFile(filePath);
					} else {
						toast.createToast(qsTr("No package list file path returned"));
					}
				}
			} else {
				let msg = packagesErrorLine.length ? packagesErrorLine : qsTr("Operation failed");
				toast.createToast(msg);
			}
			packageRunner.operationName = "";
		}
	}
		// Version comparison helper
	function versionGreaterThan(v1, v2) {
		if (!v2 && v1) return true;
		if (!v1 || !v2) return false;
		var a = v1.split('.').map(Number);
		var b = v2.split('.').map(Number);
		for (var i = 0; i < Math.max(a.length, b.length); i++) {
			var n1 = a[i] || 0;
			var n2 = b[i] || 0;
			if (n1 > n2) return true;
			if (n1 < n2) return false;
		}
		return false;
	}
}
