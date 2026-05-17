import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
 
import "opkgPageSettingsPackages.js" as Vm

MbPage {
	id: root
	title: qsTr("Open Package Manager")
	model: packagesModel

	property var curPage: pageStack ? (pageStack.currentPage || pageStack.currentItem) : undefined
  property bool showCompact: compactSetting.valid && compactSetting.value !== 0
	property bool isBusy: false

	ListModel { id: packagesModel }
  
	VBusItem {
		id: compactSetting
		bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgManager/ShowCompact")
	}

	VBusItem {
		id: noActionSetting
		bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgManager/NoAction")
	}
 
	Component.onCompleted: {
		Vm.loadPackages(processRunner, packagesModel, "package list", "")
 
	}

	Component.onDestruction: {
		if (processRunner)
			processRunner.cleanup()
		
		//console.log("calling gc()")
		//gc()
 
	}
 
	delegate: Component {
		OpkgHeaderDescriptionItem {
			id: headerItem
			header: model.name
			description: Vm.getDescription(model, showCompact, false)
			showCompact: root.showCompact
			subpage: Component { OpkgPageSettingsPackageInstall { packageModel: packagesModel.get(index)}}
		}
	}
 
	pageToolbarHandler: ToolbarHandler {
 
		function leftAction(mouse) {
			if (!mouse)
				return
 
			Vm.loadPackages(processRunner, packagesModel, "package list update", "update")
		}

		leftText: qsTr("Refresh")  

	}
 
	OpkgServiceProcess {
		id: processRunner
 
		property string packagesErrorLine: ""
		property var logCallback
 
		onOutputLine: function(line) {
			if (logCallback) {
				logCallback(line)
			}
		}

		onRunningChanged: function() {
 
			switch (processRunner.operationName) {
					case "package install":
					case "package upgrade":
					case "package set":
					case "package remove":
					isBusy = true
					curPage.status = PageStatus.Inactive
					break
				default:
					if (isBusy) {
						isBusy = false
						curPage.status = PageStatus.Active
					}
					break
			}
		}
		onErrorLine: function(line) {
			console.log("ERROR:OpkgPageSettingsPackages:" + line)
			if (logCallback) {
				logCallback(line)
				return
			}
			packagesErrorLine = line
		}

		onFinished: function(exitCode, exitStatus) {
 
			//console.log("processRunner.running:" + processRunner.running)
			try {
 
				if (exitCode === 0 && exitStatus === 0) {
					switch (processRunner.operationName) {
						case "package list":
						case "package list update":
 
							Vm.loadPackagesFromJson(jsonResult, packagesModel);
 
							if (processRunner.operationName === "package list update") {
								toast.createToast(qsTr("Refresh completed"))
							}

							break;
						case "package install":
						case "package upgrade":
						case "package set":
						case "package remove":
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
				console.log("ERROR:OpkgPageSettingsPackages:" + err.message + ", " + err.stack)
				
				toast.createToast(qsTr(err.message))
			}
 
		}
		
	}

}