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
	
	pageToolbarHandler: ToolbarHandler {
		leftText: qsTr("Add")
		rightText: {
		  var index = pageRoot.currentIndex
			if (index >= 0 && index < pageRoot.feedModel.length) {
				var builtIn = feedModel[index].builtin
				if (!builtIn) {
					return qsTr("Remove")
				}
			}
			return qsTr("")
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
			var index = pageRoot.currentIndex
			opkgRemoveIndex = index
			opkgErrorLine = ""
			opkgRunner.operationName = "remove-feed"
			var name = feedModel[index].name
			toast.createToast(name)
			opkgRunner.start(["remove-feed", name])
		}
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
			return { name: feed.name, url: feed.url, builtin: feed.builtin }
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
		subpage: {
    	if (!pageRoot.feedModel[index].builtin) {
        var page=Qt.createComponent("PageSettingsOPKGFeedEdit.qml");
				var selectedItem=pageRoot.feedModel[index]
				page.name=selectedItem.name
				page.feedName=selectedItem.name
				page.feedUrl=selectedItem.url
				page.feedNameOld=selectedItem.name
				console.debug("zzzz")
				return page
    	}
    	return undefined;
		}
		Column {
			id: contentColumn
			width: parent.width - 2 * verticalMargin
			anchors.horizontalCenter: parent.horizontalCenter
			spacing: 2
 
			Text {
				text: modelData.name
				font.bold: true
				color: pageRoot.currentIndex == index ? mbStyle.textColorSelected : mbStyle.textColor
				wrapMode: Text.WordWrap
				width: contentColumn.width
			}
			Text {
				text: modelData.url
				color: pageRoot.currentIndex == index ? mbStyle.textColorSelected : mbStyle.textColor
				wrapMode: Text.WrapAnywhere
				font.pixelSize: packageDetailsFontPixelSize
				width: contentColumn.width-subpageIcon.implicitWidth
			}
 
		}
		MbIcon {
				id: subpageIcon
        display: pageRoot.feedModel[index].name != "opkg-manager"
        anchors {
            right: parent.right; rightMargin: mbStyle.marginDefault
            verticalCenter: parent.verticalCenter
        }
        iconId: "icon-toolbar-enter" + (pageRoot.currentIndex == index ? "-active" : "")
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
		
		onOutputLine: function(line) {
			if (opkgRunner.operationName === "get-feeds") {
				feedsOutput = line
			}
		}
		onErrorLine: function(line) {
			opkgErrorLine = line
		}
		onFinished: function(exitCode, exitStatus) {
			if (exitCode === 0) {
				console.debug(feedsOutput)
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
