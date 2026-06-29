import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
import "opkgPageSettingsPackages.js" as Vm

MbPage {
	id: root

	property MbStyle mbStyle: MbStyle {}
  property var outputLog

	onOutputLogChanged: {

	}
  Component.onCompleted: {
		Vm.loadPackages(opkgBridge, packageModel, "package list", "")
	}
	model: packageModel

	ListModel {
		id: packageModel
	}

	delegate: Component {
		OpkgHeaderDescriptionItem {
			header: model.name
			description: model.description
			footer: Vm.getFooter(model)
		}
	}

	listview.footer: Item {
		id: footerItem
		height: Math.max(0, root.listview.height - (root.listview.count * root.mbStyle.itemHeight))
		Component.onCompleted: root.outputLog = outputLogArea
		anchors {
			left: parent.left
			right: parent.right
		}

		OpkgOutputLogArea {
			id: outputLogArea
			mbStyle: root.mbStyle
			fontSize: 16
			anchors {
				top: parent.top; topMargin: root.mbStyle.marginDefault
				left: parent.left; leftMargin: root.mbStyle.marginDefault
				right: parent.right; rightMargin: root.mbStyle.marginDefault
				bottom: parent.bottom
				bottomMargin: root.mbStyle.marginDefault
			}
			width: parent.width
			height: 100
		}

		Rectangle {
			id: outputLogCornerButton
			width: 16
			height: 16
			radius: 8
			color: "#3a3a3a"
			border.width: 1
			border.color: "#9a9a9a"
			anchors {
				right: outputLogArea.right
				bottom: outputLogArea.bottom
				rightMargin: 6
				bottomMargin: 6
			}
			z: 1

			MouseArea {
				anchors.fill: parent
				onClicked: { outputLog.clear() }
			}
		}
	}

	Keys.onPressed: function(event) {
		if (event.key === Qt.Key_Shift)
				root.shiftDown = true
	}

	Keys.onReleased: function(event) {
		if (event.key === Qt.Key_Shift)
				root.shiftDown = false
	}

	pageToolbarHandler: ToolbarHandler {

		leftText: "do test 1"
		//rightText: "do test 2"
		function rightAction() {

		}

		function leftAction(mouse) {
			Vm.loadPackages(opkgBridge, packageModel, "package list", "")
		}

	}

	OpkgBridge {
		id: opkgBridge

		property string opkgErrorLine: ""
    property string packagesPath: "/tmp/opkg-manager/packages.json"

		function reset() {

			opkgErrorLine=""
			operationName=""
		}
		onProcessError: function(line) {
			console.log(line)
		}
		onError: function(line) {
			console.log(line)
			opkgErrorLine = line
		}
		onFinished: function(exitCode, exitStatus) {
			console.log("onFinished:" + operationName + ", " + exitCode)

			try {

				if (exitCode !== 0) {
					let msg = opkgErrorLine.length ? opkgErrorLine : qsTr("Operation failed")
					toast.createToast(msg)
					reset()
					return
				}

			switch (operationName) {
				case "package list":
						//console.log("onFinished: get-feeds:")
						packageModel.clear()
						Vm.loadPackagesFromFile(packagesPath, packageModel, FileHelper)
						break;

				}

			} catch (err) {
				console.log("ERROR:" + err.message);
				if (toast != undefined)
					toast.createToast(qsTr(err.message));
			}

			reset()
		}
	}
}