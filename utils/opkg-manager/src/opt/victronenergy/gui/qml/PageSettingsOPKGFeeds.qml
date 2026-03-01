import QtQuick 2
import QtQuick.Controls 2.15
import com.victron.velib 1.0
import OpkgManager 1.0
import "utils.js" as Utils

MbPage {
	
	id: root
	title: qsTr("Feeds")
	model: feedsModel
	property var feedsModel: []
	property bool showCompact: compactSetting.valid && compactSetting.value !== 0
 
	VBusItem {
		id: compactSetting
		bind: Utils.path("com.victronenergy.settings", "/Settings/OpkgManager/ShowCompact")
	}

	Component.onCompleted: {
		opkgRunner.operationName = "get-feeds"
		opkgRunner.start(["get-feeds"])
	}

	//Define Edit feeds Page
  Component { id: editFeedPageComponent
		MbPage {
				
				title: qsTr("Edit Feed")

				property bool isNew: false
			
				model: VisibleItemModel {
					MbEditBox {
						id: feedNameEdit
						description: qsTr("Name")
						maximumLength: 20
						enableSpaceBar: false
						item.value: (!isNew && root.feedsModel && root.feedsModel[root.currentIndex]?.name) ? root.feedsModel[root.currentIndex].name : ""
					}
				
					OpkgEditBoxLargeText {
						id: feedUrlEdit
						description: qsTr("Url")
						maximumLength: 256
						matchString: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ~!@#$%^&*()-_=+[]{}\\;:|/.,<>?"
						enableSpaceBar: false
						item.value:  (!isNew && root.feedsModel && root.feedsModel[root.currentIndex]?.url) ? root.feedsModel[root.currentIndex].url : ""
					}
				}
			
				pageToolbarHandler: ToolbarHandler {
					leftIcon: "icon-toolbar-cancel"
					rightIcon: "icon-toolbar-ok"

					function leftAction() { pageStack.pop() }
					function rightAction() {
						root.process_add_update(isNew, feedNameEdit.item.value, feedUrlEdit.item.value)		 
					}
				}
			
			}
	}
 
	delegate: OpkgHeaderDescriptionItem {
		editable: true
		header: feedsModel[index].name
		description: "Url: " + root.feedsModel[index].url
		descriptionWrapMode: Text.WrapAtWordBoundaryOrAnywhere
		showCompact: root.showCompact
		subpage: {
			if (!root)
				return undefined
    	if (index == -1 || !root.feedsModel[index]?.builtin) {
				return editFeedPageComponent.createObject(parent);
    	}
    	return undefined;
		}
	 
	}
	
	pageToolbarHandler: ToolbarHandler {
		leftText: qsTr("Add")
		rightText: {
			if (root.currentIndex >= 0 && root.currentIndex < feedsModel.length) {
				var builtIn = feedsModel[root.currentIndex].builtin
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
			var page = editFeedPageComponent.createObject(pageStack, { isNew: true });
			if (page) {
				pageStack.push(page);
			}
		}
		function rightAction() {
			if (opkgRunner.running) {
				return
			}
			opkgRunner.operationName = "remove-feed"
 
			var name = feedsModel[root.currentIndex].name
			opkgRunner.start(["remove-feed", name])
		}
	}

	//////////////////
	// methods
  function process_add_update(isNew, name, url)
	{
		if (!opkgRunner || opkgRunner.running) {
				return
			}
			if (!isValid()) {
				return
			}
			
			opkgRunner.feedName = name || ""
			opkgRunner.feedUrl = url || ""
			if (isNew) {
 
				opkgRunner.operationName="add-feed"
				//console.log("process_add_update:add-feed,feedName:" + opkgRunner.feedName + ",feedUrl:" + opkgRunner.feedUrl)

				opkgRunner.start(["add-feed", opkgRunner.feedName, opkgRunner.feedUrl])
			} else {
				opkgRunner.operationName="edit-feed"
				var curFeedName = feedsModel[root.currentIndex].name || ""
				//console.log("process_add_update:edit-feed,feedName:" + opkgRunner.feedName + ",feedUrl:" + opkgRunner.feedUrl + ",curFeedName:" +curFeedName + ",idx:" +root.currentIndex)

				opkgRunner.start(["edit-feed", opkgRunner.feedName, opkgRunner.feedUrl, curFeedName])
			}
			
			function isValid() {
				if (!name?.length > 0) {
					toast.createToast("Error: name is required")
					return false
				}
				if (!url?.length > 0) {
					toast.createToast("Error: Url is required")
					return false
				}
				if (!isValidUrl()) {
					toast.createToast("Error: Url is invalid")
					return false
				}
				return true
			}
			function isValidUrl() {
				// Basic check for http(s):// and at least one dot
				var pattern = /^(https?:\/\/)[^\s/$.?#].[^\s]*$/i;
				return pattern.test(url);
			}
	}

	function removeFeed() {
		if (root.currentIndex >= 0 && root.currentIndex < feedsModel.length) {
			feedsModel.splice(root.currentIndex, 1)
			feedsModel = feedsModel.slice();
		}
	}

	function updateFeed(isNew, name, url) {
		if (isNew)
			feedsModel.push({ name: name, url: url })
		else if (root.currentIndex >= 0 && root.currentIndex < feedsModel.length) {
			feedsModel[root.currentIndex].name = name
			feedsModel[root.currentIndex].url = url
		}
		feedsModel = feedsModel.slice();
	}
 
	function loadFeedsFromFile(file) {
		var filePath = file?.trim();
		if (!filePath?.length) {
			throw new Error("No feeds file path returned");
		}

		var jsonText = FileHelper.readFile(filePath);
		
		if (!jsonText?.length) {
			throw new Error("Failed to read feeds file: File is empty: " + filePath);
		}
		
		var feeds = JSON.parse(jsonText)
 
		feedsModel = feeds.map(function(feed) {
			return { name: feed.name, url: feed.url, builtin: feed.builtin }
		})
	}

	ProcessRunner {
		id: opkgRunner
		helperPath: "/data/dev/utils/opkg-manager/src/data/opkg-manager/qml/opkg"
		
		property string feedName: ""
		property string feedUrl: ""
		property string opkgErrorLine: ""
		property string feedsOutput: ""

		function reset() {
			feedName=""
			feedUrl=""
			opkgErrorLine=""
			feedsOutput=""
		}

		onOutputLine: function(line) {
			if (opkgRunner.operationName === "get-feeds") {
				feedsOutput = line
			}
		}
		onErrorLine: function(line) {
			console.log(line)
			//opkgErrorLine = line
		}
		onFinished: function(exitCode, exitStatus) {
			//console.log("onFinished:" + exitCode)
			if (exitCode !== 0) {
				let msg = opkgErrorLine.length ? opkgErrorLine : qsTr("Operation failed")
				toast.createToast(msg)
				reset()
				return
			}
 
			switch (opkgRunner.operationName) {
				case "get-feeds":
				  loadFeedsFromFile(feedsOutput)
					
					break;
				case "remove-feed":
					removeFeed()
					toast.createToast("remove succeeded")
					break;
				case "add-feed":
				case "edit-feed":
				  var isNew = opkgRunner.operationName == "add-feed"
 
					updateFeed(isNew, feedName, feedUrl)
					toast.createToast((isNew ? "add" : "edit") +  " succeeded")
					//pageStack.pop()
					break;
				break;
			}
			reset()
		}
	}
 
}
