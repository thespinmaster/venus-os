import QtQuick 2
import QtQuick.Controls 2.15
import com.victron.velib 1.0
import OpkgManager 1.0
 

MbPage {
	property string feedsOutput: ""
	id: root
	title: qsTr("Feeds")
	property var feedsModel: []
	property int opkgRemoveIndex: -1
	property string opkgErrorLine: ""
	property int packageDetailsFontPixelSize: 14
 
	model: feedsModel
	
	Component.onCompleted: {
		opkgRunner.operationName = "get-feeds"
		opkgRunner.start(["get-feeds"])
	}

	delegate: OpkgHeaderDescriptionItem {
		editable: true
		header: root.feedsModel[index].name
		description: "Url: " + root.feedsModel[index].url
		descriptionWrapMode: Text.WrapAtWordBoundaryOrAnywhere
		subpage: {
    	if (!model.builtin) {
        var component=Qt.createComponent("PageSettingsOPKGFeedEdit.qml");
				var feedModel = feedsModel[index]
				console.log("feedName:" + feedModel.name)
				var page = component.createObject(parent, {
						feedIndex: index,
						feedName: feedModel.name,
						feedUrl: feedModel.url,
						feedNameOld: ""
				});
				return page;
    	}
    	return undefined;
		}
	 
	}
	
	pageToolbarHandler: ToolbarHandler {
		leftText: qsTr("Add")
		rightText: {
		  var index = root.currentIndex
			if (index >= 0 && index < feedsModel.length) {
				var builtIn = feedsModel[index].builtin
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
			var index = root.currentIndex
			opkgRemoveIndex = index
			opkgErrorLine = ""
			opkgRunner.operationName = "remove-feed"
			var name = feedsModel[index].name
			toast.createToast(name)
			opkgRunner.start(["remove-feed", name])
		}
	}

//////////////////
// methods

	function addFeed(name, url) {
		feedsModel.push({ name: name, url: url })
		feedsModel = feedsModel.slice(); // trigger QML update
	}
	function removeFeed(index) {
		if (index >= 0 && index < feedsModel.length) {
			feedsModel.splice(index, 1)
			feedsModel = feedsModel.slice();
		}
	}

	function updateFeed(index, name, url) {
		if (index >= 0 && index < feedsModel.length) {
			
			feedsModel[index].name = name
			feedsModel[index].url = url
			feedsModel = feedsModel.slice();
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
 
		feedsModel = feeds.map(function(feed) {
			return { name: feed.name, url: feed.url, builtin: feed.builtin }
		})
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
