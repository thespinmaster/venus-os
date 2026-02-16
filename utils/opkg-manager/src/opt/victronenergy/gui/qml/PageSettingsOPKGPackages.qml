import QtQuick 2

import com.victron.velib 1.0
import net.connman 0.1
import OpkgManager 1.0
import "utils.js" as Utils
import QtQuick.Controls
import QtQuick.Layouts 1.0
import "PageSettingsOPKGPackages.js" as Vm

MbPage {
	id: root
	title: qsTr("Open Package Manager")
	model: packageModel
  property bool showCompact: compactSetting.valid && compactSetting.value !== 0
	
	ListModel { id: packageModel}
  
	VBusItem {
		id: compactSetting
		bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgManager/ShowCompact")
	}
   
	Component.onCompleted: {
		//packageModel.append({ subpage: "setup", description: "Options"})
		//packageModel.append({index:1, header: "Item 2", description: "Some text\nSome more text" , version: "1.0.1", installedVersion: "1.0.0"})
		//packageModel.append({index:2, header: "Item 3", description: "Some text\nSome more text" , version: "2.0.1", installedVersion: "2.0.0"})
 
		Vm.loadPackages(processRunner, packageModel, "list-packages", "")
 
	}

	Component { id: opkgPackageInstallComponentFactory; PageSettingsOPKGPackageInstall {} }

	delegate: Component {
		OpkgHeaderDescriptionItem {
			header: model.name
			description: Vm.getDescription(model, showCompact, false)
			showCompact: root.showCompact
			subpage: { 
				return opkgPackageInstallComponentFactory
									.createObject(parent, { model: model, processRunner: processRunner });
			}
		}
	}
 
	pageToolbarHandler: ToolbarHandler {
 
		function centerAction() {
			Vm.loadPackages(processRunner, packageModel, "list-packages-update", "update")
		}

		centerText: qsTr("Refresh Feeds")  

	}
 
///////////////////////
// methods

	ProcessRunner {
		id: processRunner
		helperPath: "/data/dev/utils/opkg-manager/src/data/opkg-manager/opkg-common"
 
		property string lastOutputLine: ""
		property string packagesErrorLine: ""
		property var logCallback

		onOutputLine: function(line) {
			if (logCallback) {
				logCallback(line)
				return
			}
			lastOutputLine = line
		}

		onErrorLine: function(line) {
			if (logCallback) {
				logCallback(line)
				return
			}
			packagesErrorLine = line
		}
		// Now expects the helper to output the file path of the JSON file
		onFinished: function(exitCode, exitStatus) {
			try {
				console.debug("exitCode=" + String(exitCode) + ", exitStatus=" + String(exitStatus))
				if (exitCode === 0 && exitStatus === 0) {
					switch (processRunner.operationName) {
						case "list-packages":
						case "list-packages-update":
 
							Vm.loadPackagesFromFile(lastOutputLine, FileHelper, packageModel);
 
							if (processRunner.operationName === "list-packages-update") {
								toast.createToast(qsTr("Refresh completed"));
							}

							break;
						case "install":
						case "upgrade":
						case "remove":
							// handle remove if needed
							if (logCallback)
								logCallback.addLogLine("--- Finished " + processRunner.operationName + ". Exit code: " + exitCode + ", status: " + exitStatus + " ---"); 
							logCallback = undefined
							break;
						default:
							break;
					}
				} else {
					let msg = packagesErrorLine.length ? packagesErrorLine : qsTr("Operation failed");
					toast.createToast(msg);
				}
				processRunner.operationName = "";
			} catch (err) {
				console.log("ERROR:" + err.message);
				toast.createToast(qsTr(err.message));
			}
		}

	}

}