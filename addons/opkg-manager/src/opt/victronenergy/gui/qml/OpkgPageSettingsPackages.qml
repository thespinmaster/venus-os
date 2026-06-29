pragma ComponentBehavior: Bound
import QtQuick 2

MbPage {
	id: root
	title: qsTr("Packages")
	//tryPop: opkgManager.tryPop
	model
	: packagesModel
	required property var opkgManager
	property bool _loading: true
	property var curPage: pageStack ? (pageStack.currentPage || pageStack.currentItem) : undefined
	property var packagesModel: []

	onOpkgManagerChanged: {
		root.refreshPackages()
	}

	Label {
		text: "Loading..."
		visible: root._loading
		anchors.centerIn: parent
		//font.pixelSize: Theme.font_size_body3
		onVisibleChanged: {
			root.listview.visible = !_loading
		}
	}


	delegate: OpkgHeaderDescriptionItem {
		required property var modelData
		id: headerItem
		header: modelData.packageName
		description: modelData.description
		showCompact: opkgManager.showCompact
		indicatorColor: (modelData.installedVersion && modelData.availableVersion
								? Qt.color("orange")
								: (modelData.installedVersion
									? Qt.color("#2969a1")
									: null))
		subpage: Component {
			OpkgPageSettingsPackageInstall {
				opkgManager: root.opkgManager
				model: root.opkgManager.snapshotObject(modelData)
				loadPackagesModelCallback: root.onLoadPackagesModel}
		}
	}

	function refreshPackages(force) {
		_loading = true

		root.opkgManager.loadPackages(force, function(result) {
			if (result.success)
				onLoadPackagesModel(result.data)
			_loading = false
		})
	}

	function onLoadPackagesModel(packages, refreshPackageName, refreshModelCallback) {
		root.packagesModel = packages

		// Refresh the model
		if (refreshModelCallback)
			for (var i = 0; i < packages.length; i++) {
				if (packages[i].packageName == refreshPackageName) {
					refreshModelCallback(packages[i])}
		}
	}

	pageToolbarHandler: ToolbarHandler {

		leftText: qsTr("Refresh")
		function leftAction(mouse) {
			if (!mouse)
				return
			if (root.opkgManager.running)
				return
			refreshPackages(true)
		}

	}

}