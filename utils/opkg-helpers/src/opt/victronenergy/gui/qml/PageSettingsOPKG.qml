import QtQuick 2

import com.victron.velib 1.0
import net.connman 0.1
import OpkgHelpers 1.0
import "utils.js" as Utils
import QtQuick.Controls

MbPage {
	// Version comparison helper
	function versionGreaterThan(v1, v2) {
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
 
	property int selectedIndex: -1
	property var selectedPackage: null

	onSelectedIndexChanged: {
 
			if (selectedIndex > 0  && selectedIndex < packageItems.count) {
					selectedPackage = packageItems.get(selectedIndex)
					console.debug("onSelectedIndexChanged:" + selectedPackage.name)
					
			} else {
					console.debug("selectedPackage:null")
		
					selectedPackage = null
			}
	}

	pageToolbarHandler: ToolbarHandler {
 
		function centerAction() {
			loadPackages("list-packages-update", "update")
		}

		centerText: qsTr("Refresh Feeds")  

	}
	id: root
	title: qsTr("Open Package Manager")
		property string packageIconId: "icon-opkg-helpers-tick"
		property int packageDetailsFontPixelSize: 14

	ListModel {
		id: packageModel
	}
	property string packagesOutput: ""
	property string packagesErrorLine: ""
	property bool showCompact: compactSetting.valid && compactSetting.value !== 0
	property int subpageIconReserveWidth: 24

	VBusItem {
		id: compactSetting
		bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgHelpers/ShowCompact")
	}
 
	Component.onCompleted: {
		loadPackages("list-packages", "")
	}

	function loadPackages(operationName, args) {
 
		if (packageRunner.running) {
			return
		}

		packageModel.clear()
		packageItems.clear()
		 
		packagesOutput = ""
		packagesErrorLine = ""

		packageRunner.operationName = operationName
		packageRunner.start(["list-packages", args])
 
	}

	function refreshPackageItems() {
		packageItems.clear()
		var setupItem = setupItemFactory.createObject(packageItems)
		packageItems.append(setupItem)
		var offset = 1  // because of "Setup" item
		for (var i = 0; i < packageModel.count; i++) {
			var pkg = packageModel.get(i)
			var item = packageItemFactory.createObject(packageItems, {
				"name": pkg.name,
				"description": pkg.description,
				"version": pkg.version,
				"feed": pkg.feed,
				"installedVersion": pkg.installedVersion,
				"iconId" : "icon-opkg-helpers-tick",
				"index" : i + offset
			})
			packageItems.append(item)
		}
	}

	function loadPackagesFromJson(jsonText) {
		packageModel.clear()
		var packages = JSON.parse(jsonText)
		for (var i = 0; i < packages.length; i++) {
			var pkg = packages[i]
			packageModel.append({
				name: pkg.name || "",
				description: pkg.description || "",
				version: pkg.version || "",
				feed: pkg.feed || "",
				installedVersion: pkg.installedVersion || ""
			})
		}
		refreshPackageItems()
	}

	// load packages from a JSON file using FileHelper.readFile
	function loadPackagesFromFile(filePath) {
		try {
			var jsonText = FileHelper.readFile(filePath);
			if (!jsonText || jsonText.length === 0) {
				toast.createToast(qsTr("Failed to read package list file: ") + filePath);
				return;
			}
			loadPackagesFromJson(jsonText);
			if (packageRunner.operationName === "list-packages-update") {
			    toast.createToast(qsTr("Refresh completed")); }
			selectedIndex=0
			selectedPackage=null
		} catch (err) {
			console.debug("ERROR reading package list file:", err);
			toast.createToast(qsTr("Failed to read package list file: ") + filePath);
		}
	}

	model: packageItems

	VisibleItemModel {
		id: packageItems
	}

	Component {
		id: setupItemFactory
		MbSubMenu {
			description: qsTr("Settings")
			subpage: Component { PageSettingsOPKGSettings {} }

				onIsCurrentItemChanged: {
				if (ListView.isCurrentItem) {
						root.selectedIndex = 0
				}
			}
		}
	}

	Component {
		id: packageItemFactory
		OpkgPackageItem {
			iconId: iconId
			name: name
			description: description
			version: version
			feed: feed
			installedVersion: installedVersion
			index: index
			detailsFontPixelSize: root.packageDetailsFontPixelSize
			showCompact: root.showCompact
			subpageIconReserveWidth: root.subpageIconReserveWidth
			hasSubpage: true
			// Only show available version if it is greater than installedVersion
			property bool showAvailable: root.versionGreaterThan(version, installedVersion)
			subpage: Component {
				PageSettingsOPKGPackageInstall {
					selectedPackage: root.selectedPackage
					property bool showUpgrade: root.versionGreaterThan(selectedPackage ? selectedPackage.version : "", selectedPackage ? selectedPackage.installedVersion : "")
				}
			}
			onIsCurrentItemChanged: {
				if (ListView.isCurrentItem) {
					root.selectedIndex = index
				}
			}
		}
	}

	ProcessRunner {
		id: packageRunner
		helperPath: "/data/dev/utils/opkg-helpers/src/data/opkg-helpers/opkg-common"
 
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
}
