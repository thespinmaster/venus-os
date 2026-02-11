import QtQuick 2
import QtQuick.Controls 2.15
import com.victron.velib 1.0
import OpkgManager 1.0
 

MbPage {
		property string feedsOutput: ""
	id: pageRoot
	title: qsTr("Feeds")
	property var feedModel: []
	property int opkgRemoveIndex: -1
	property string opkgErrorLine: ""
	property int packageDetailsFontPixelSize: 14

		leftText: qsTr("Add")
		rightText: {
			qsTr("Remove")
		}
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
			var name = feedModel[index].name
			toast.createToast(name)
			opkgRunner.start(["remove-feed", name])
	}



	function addFeed(name, url) {
		pageRoot.feedModel.push({ name: name, url: url })
		pageRoot.feedModel = pageRoot.feedModel.slice(); // trigger QML update
	}
	function removeFeed(index) {
		if (index >= 0 && index < pageRoot.feedModel.length) {
			pageRoot.feedModel.splice(index, 1)
			pageRoot.feedModel = pageRoot.feedModel.slice();
		}
	}

	function updateFeed(index, name, url) {
		if (index >= 0 && index < pageRoot.feedModel.length) {
			pageRoot.feedModel[index].name = name
			pageRoot.feedModel[index].url = url
			pageRoot.feedModel = pageRoot.feedModel.slice();
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
		var feeds = JSON.parse(jsonText)
		pageRoot.feedModel = feeds.map(function(feed) {
			return { name: feed.name, url: feed.url }
		})
	}

	Component.onCompleted: {
		opkgRunner.operationName = "get-feeds"
		opkgRunner.start(["get-feeds"])
	}


	model: feedModel

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
		helperPath: "/data/dev/utils/opkg-manager/src/data/opkg-manager/opkg-common"
		
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
