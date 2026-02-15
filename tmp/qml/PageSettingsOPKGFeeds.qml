import QtQuick 2
import QtQuick.Controls 2.15
import com.victron.velib 1.0
import OpkgHelpers 1.0
 

MbPage {
		property string feedsOutput: ""
	id: pageRoot
	title: qsTr("Feeds")
	property alias feedModel: feedModelStore
	property int opkgRemoveIndex: -1
	property string opkgErrorLine: ""
	property int packageDetailsFontPixelSize: 14

		leftText: qsTr("Add")
		rightText: qsTr("Remove")
		function leftAction() {
			if (opkgRunner.running) {
				return
			}
			pageStack.push(addFeedPage)
		}
		function rightAction() {
			if (opkgRunner.running) {
				return
			}
			opkgRemoveIndex = index
			opkgErrorLine = ""
			opkgRunner.operationName = "remove-feed"
			opkgRunner.start(["remove-feed", name])
	}

	ListModel {
		id: feedModelStore
	}

	function addFeed(name, url) {
		feedModelStore.append({ name: name, url: url })
	}
	function removeFeed(index) {
		if (index >= 0 && index < feedModelStore.count) {
			feedModelStore.remove(index)
		}
	}

	function updateFeed(index, name, url) {
		if (index >= 0 && index < feedModelStore.count) {
			feedModelStore.setProperty(index, "name", name)
			feedModelStore.setProperty(index, "url", url)
		}
	}

	function saveFeed(index, name, url) {
		if (index < 0) {
			addFeed(name, url)
			return
		}
		updateFeed(index, name, url)
	}

	function loadFeedsFromJson(jsonText) {
		feedModelStore.clear()
		var feeds = JSON.parse(jsonText)
		for (var i = 0; i < feeds.length; i++) {
			var feed = feeds[i]
			addFeed(feed.name, feed.url)
		}
	}

	Component.onCompleted: {
		opkgRunner.operationName = "get-feeds"
		opkgRunner.start(["get-feeds"])
	}

	model: feedModelStore

	delegate: MbItem {
		editable: true
		property int verticalMargin: 8
		height: contentColumn.implicitHeight + verticalMargin
		subpage: Component {
			PageSettingsOPKGFeedEdit {
				feedIndex: index
				feedName: name
				feedUrl: url
				updateFeed: pageRoot.saveFeed
			}
		}
		Column {
			id: contentColumn
			width: parent.width - 2 * verticalMargin
			anchors.horizontalCenter: parent.horizontalCenter
			spacing: 2
			Item { height: verticalMargin; width: 1 } // top margin
			Text {
				text: name
				font.bold: true
				color: "#FFFFFF"
				wrapMode: Text.WordWrap
				width: contentColumn.width
			}
			Text {
				text: url
				color: "#FFFFFF"
				wrapMode: Text.WrapAnywhere
				font.pixelSize: packageDetailsFontPixelSize
				width: contentColumn.width-subpageIcon.implicitWidth
			}
			Item { height: verticalMargin; width: 1 } // bottom margin
		}
		MbIcon {
				id: subpageIcon
        display: packageItem.hasSubpage
        anchors {
            right: parent.right; rightMargin: mbStyle.marginDefault
            verticalCenter: parent.verticalCenter
        }
        iconId: "icon-toolbar-enter" + (ListView.isCurrentItem ? "-active" : "")
    }
	}

	Component {
		PageSettingsOPKGFeedEdit {
			feedIndex: -1
			feedName: ""
			feedUrl: ""
			updateFeed: pageRoot.saveFeed
		}
	}

	ProcessRunner {
		id: opkgRunner
		helperPath: "/data/dev/utils/opkg-helpers/src/data/opkg-helpers/opkg-common"
		
		onOutputLine: {
			if (opkgRunner.operationName === "get-feeds") {
				feedsOutput = line
			}
		}
		onErrorLine: {
			opkgErrorLine = line
		}
		onFinished: {
			if (exitCode === 0) {
				if (opkgRunner.operationName === "get-feeds") {
					loadFeedsFromJson(feedsOutput)
					feedsOutput = ""
				} else if (opkgRunner.operationName === "remove-feed") {
					removeFeed(opkgRemoveIndex)
					opkgRemoveIndex = -1
				}
			} else {
				let msg = opkgErrorLine.length ? opkgErrorLine : qsTr("Operation failed")
				toast.createToast(msg)
			}
		}
	}
 
}
