import QtQuick 2

import com.victron.velib 1.0
import OpkgManager 1.0
import "utils.js" as Utils
import QtQuick.Controls
import QtQuick.Layouts 1.0
import "PageSettingsOpkgPackages.js" as Vm

MbPage {
	id: root
	title: qsTr("Open Package Manager")
	model: packagesModel
  property bool showCompact: compactSetting.valid && compactSetting.value !== 0
	
	ListModel { id: packagesModel}
  
	VBusItem {
		id: compactSetting
		bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgManager/ShowCompact")
	}

	VBusItem {
		id: noActionSetting
		bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgManager/NoAction")
	}
 
	Component.onCompleted: {
		Vm.loadPackages(processRunner, packagesModel, "list-packages", "")
	}

	Component.onDestruction: {
		if (processRunner)
			processRunner.cleanup()
		
		//console.log("calling gc()")
		//gc()
 
	}

	Component { id: opkgPackageInstallComponentFactory; PageSettingsOpkgPackageInstall {} }
	
	//Component {
	//		id: opkgPackageInstallComponent
	//		PageSettingsOpkgPackageInstall {
	//				itemModel: model
	//				processRunner: processRunner
	//		}
	//}

	
	delegate: Component {
		OpkgHeaderDescriptionItem {
			id: headerItem
			header: model.name
			description: Vm.getDescription(model, showCompact, false)
			showCompact: root.showCompact
			subpage: Component { PageSettingsOpkgPackageInstall { packageModel: packagesModel.get(index)}}
		}
	}
 
	pageToolbarHandler: ToolbarHandler {
 
		function leftAction() {
			Vm.loadPackages(processRunner, packagesModel, "list-packages-update", "update")
		}

		leftText: qsTr("Refresh")  

	}
 
	ProcessRunner {
		id: processRunner
		//helperPath: "/data/dev/utils/opkg-manager/src/data/opkg-manager/qml/opkg"
 		helperPath: "/data/opkg-manager/qml/opkg"
 
		property string lastOutputLine: ""
		property string packagesErrorLine: ""
		property var logCallback

		onOutputLine: function(line) {
			if (logCallback) {
				logCallback(line)
				return
			}
			console.log(line)
			lastOutputLine = line
		}

		onErrorLine: function(line) {
			console.log("ERROR:PageSettingsOpkgPackages:" + line)
			if (logCallback) {
				logCallback(line)
				return
			}
			packagesErrorLine = line
		}

		onFinished: function(exitCode, exitStatus) {
			try {
				
				if (exitCode === 0 && exitStatus === 0) {
					switch (processRunner.operationName) {
						case "list-packages":
						case "list-packages-update":
 
							Vm.loadPackagesFromFile(lastOutputLine, FileHelper, packagesModel);
 
							if (processRunner.operationName === "list-packages-update") {
								toast.createToast(qsTr("Refresh completed"))
							}

							break;
						case "install":
						case "upgrade":
						case "remove":
							// handle remove if needed
							if (logCallback)
								logCallback("--- Finished " + processRunner.operationName + ". Exit code: " + exitCode + ", status: " + exitStatus + " ---"); 
							logCallback = undefined
							break
						default:
							break
					}
				} else {
					let msg = packagesErrorLine.length ? packagesErrorLine : qsTr("Operation failed")
					toast.createToast(msg)
				}
				processRunner.operationName = ""
			} catch (err) {
				console.log("ERROR:PageSettingsOpkgPackages:" + err.message)
				toast.createToast(qsTr(err.message))
			}
 
		}
		
	}

}