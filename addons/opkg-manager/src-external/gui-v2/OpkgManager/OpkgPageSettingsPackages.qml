import QtQuick 2
import Victron.VenusOS

Page {
	id: root
	title: qsTr("Packages")
	tryPop: opkgManager.tryPop

	required property var opkgManager
	property bool _loading: true

	Component.onCompleted: root.refreshPackages()

	Label {
		text: "Loading..."
		visible: root._loading
		anchors.centerIn: parent
		font.pixelSize: Theme.font_size_body3
	}

	GradientListView {
		id: settingsListView
		clip: true
		visible : !root._loading
		anchors {
			top: parent.top
			left: parent.left
			right: parent.right
			bottom: actionsRow.top
		}

		delegate: ListNavigation {
			required property var modelData

			indicatorColor: (modelData.installedVersion && modelData.availableVersion
											? Theme.color_orange
											: (modelData.installedVersion
													? Theme.color_blue
													: Qt.rgba(0,0,0,0)))
			text: modelData.packageName + "  " + modelData.installedVersion
			caption: root.opkgManager.showCompact ? "" : modelData.description
			onClicked: Global.pageManager.pushPage(
				"qrc:/OpkgManager/OpkgPageSettingsPackageInstall.qml",
				{ title: text,
					opkgManager: root.opkgManager,
					model: root.opkgManager.snapshotObject(modelData),
					loadPackagesModelCallback: root.onLoadPackagesModel}

			)
		}
	}

	function refreshPackages(force) {
		_loading = true
		opkgManager.loadPackages(force, function(result) {
				if (result.success)
					onLoadPackagesModel(result.data)
				_loading = false
			})
	}

	function onLoadPackagesModel(packages, refreshPackageName, refreshModelCallback) {
		settingsListView.model = packages;

		// Refresh the model
		if (refreshModelCallback)
			for (var i = 0; i < packages.length; i++) {
				if (packages[i].packageName == refreshPackageName) {
					refreshModelCallback(packages[i])}
		}
	}

	OpkgActionsRow {
		id: actionsRow
		buttonModel: [
			{
				text:"Refresh",
				enabled: root.opkgManager ? (!root.opkgManager.running && visible) : false,
				onClicked: function() {
					root.refreshPackages(true)
				}
			}
		]
	}

}