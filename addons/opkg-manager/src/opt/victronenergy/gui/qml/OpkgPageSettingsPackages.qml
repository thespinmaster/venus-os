import QtQuick 2
import com.victron.velib 1.0
import OpkgManager 1.0
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
  
	function refreshPackages(option) {
		var action = option ? " " + option : ""
		Vm.loadPackages(opkgBridge, packagesModel, "package list" + action, option)
	}
	Component.onCompleted: refreshPackages()

	Component.onDestruction: {
		if (opkgBridge)
			opkgBridge.cleanup()
		
		//console.log("calling gc()")
		//gc()
 
	}
 
	delegate: Component {
		OpkgHeaderDescriptionItem {
			
			id: headerItem

			header: model.name
			description: model.description
			footer: Vm.getFooter(model, showCompact)
			showCompact: root.showCompact
			subpage: Component {
				OpkgPageSettingsPackageInstall {
					packageModel: packagesModel.get(index)
					packageListModel: packagesModel
					packageIndex: index
				}
			}
		}
	}
 
	pageToolbarHandler: ToolbarHandler {
 
		function leftAction(mouse) {
			if (!mouse)
				return
			refreshPackages("update")
		}

		leftText: qsTr("Refresh")

	}
 
	OpkgBridge {
		id: opkgBridge
		
		property string packagesPath: "/tmp/opkg-manager/packages.json"
 
		property string lastOutputLine: ""
		property string packagesErrorLine: ""
		property var logCallback
		property var packageModel
		property int packageIndex: -1

		onOutputLine: function(line) {
			if (logCallback) {
				logCallback(line)
				return
			}
			console.log(line)
			lastOutputLine = line
		}

		onRunningChanged: function() {
 
			switch (opkgBridge.operationName) {
				case "install":
				case "upgrade":

				case "set-feed":
				case "remove":
					isBusy = true
					// PageStatus.Inactive   0
					curPage.status = 0
					break
				default:
					if (isBusy) {
						isBusy = false
						// PageStatus.Active = 2
						curPage.status = 2
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
 
			//console.log("opkgBridge.running:" + opkgBridge.running)
			try {
 
				if (exitCode === 0 && exitStatus === 0) {
					switch (opkgBridge.operationName) {
						case "package list":
						case "package list update":
 
							Vm.loadPackagesFromFile(packagesPath, packagesModel, FileHelper);
							if (opkgBridge.operationName === "package list update")
								toast.createToast(qsTr("Refresh completed"))

							break;
						case "remove":
						case "install":
						case "upgrade":
						
							if (logCallback)
								logCallback("Refreshing package list")
							
							refreshPackages()

							if (logCallback)
								logCallback("--- Finished " + opkgBridge.operationName + ". Exit code: " + exitCode + ", status: " + exitStatus + " ---")
							logCallback = undefined
							break
 
						default:
							break
					}
				} else {
					let msg = packagesErrorLine.length ? packagesErrorLine : qsTr("Operation failed")
					toast.createToast(msg)
				}
				opkgBridge.operationName = ""
			} catch (err) {
				console.log("ERROR:OpkgPageSettingsPackages:" + err.message + ", " + err.stack)
				
				toast.createToast(qsTr(err.message))
			
			} finally {
				packageModel = null
				packageIndex = -1
			}
 
		}
		
	}

}