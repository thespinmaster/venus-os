import QtQuick 2
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
		opkgBridge.operationName = "feed list"
		opkgBridge.start(["feed", "list"])
	}

	Component.onDestruction: {


		if (opkgBridge)
				opkgBridge.cleanup()
	}


	//Define Edit feeds Page
  Component { id: editFeedPageComponent
		MbPage {
				
				title: qsTr("Edit Feed")
				property var feedModel: root.feedsModel[root.currentIndex]
				property bool isNew: false
 
				model: VisibleItemModel {

					MbEditBox {
						id: feedNameEdit
						readonly: !userHasWriteAccess || (isNew ? false : feedModel?.builtin ?? true)
						useVirtualKeyboard: false
						description: qsTr("Name")
						maximumLength: 20
						enableSpaceBar: false
 
						item.value: (!isNew && root.feedsModel) ? feedModel.name : ""

					}
				
					OpkgEditBoxLargeText {
						id: feedUrlEdit
						readonly: !userHasWriteAccess || (isNew ? false : feedModel?.builtin ?? true)
						description: qsTr("Url")
						maximumLength: 256
						matchString: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ~!@#$%^&*()-_=+[]{}\\;:|/.,<>?"
						enableSpaceBar: false
						item.value:  (!isNew && root.feedsModel) ? feedModel.url : ""
					}

					MbTextDescription {
						text: "(Readonly)"
						opacity: 0.5
						isCurrentItem: false
						width: parent ? parent.width : 0
						horizontalAlignment: Text.AlignHCenter
						//anchors.horizontalCenter: parent.horizontalCenter
						visible: !isNew && feedModel?.builtin
					}
				}
			
				pageToolbarHandler: ToolbarHandler {
					leftIcon: (feedModel?.builtin) ? "" : "icon-toolbar-cancel"
					rightIcon: (feedModel?.builtin) ? "" :"icon-toolbar-ok"
					function leftAction() { pageStack.pop() }
					function rightAction() {
						root.add_update_feed(isNew, feedNameEdit.item.value, feedUrlEdit.item.value)		 
					}
				}
			
			}
	}
 
	delegate: OpkgHeaderDescriptionItem {
		editable: true
		header: modelData.name
		description: "Url: " + modelData.url
		descriptionWrapMode: Text.WrapAtWordBoundaryOrAnywhere
		showCompact: root.showCompact
		subpage: editFeedPageComponent
		//hasSubpage: subpage != undefined && !modelData.builtin
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
			if (opkgBridge.running) {
				return
			}
			
			var page = editFeedPageComponent.createObject(pageStack, { isNew: true });
			if (page) {
				pageStack.push(page);
			}
		}
		function rightAction() {
			if (opkgBridge.running) {
				return
			}
			opkgBridge.operationName = "feed remove"
 
			var name = feedsModel[root.currentIndex].name
			opkgBridge.start(["feed", "remove", name])
		}
	}

	//////////////////
	// methods
 
  function add_update_feed(isNew, name, url) {
		if (!opkgBridge || opkgBridge.running) {
				return
			}
			if (!isValid()) {
				return
			}
			
			opkgBridge.feedName = name || ""
			opkgBridge.feedUrl = url || ""
			if (isNew) {
 
				opkgBridge.operationName="feed add"
				//console.log("add_update_feed:add-feed,feedName:" + opkgBridge.feedName + ",feedUrl:" + opkgBridge.feedUrl)

				opkgBridge.start(["feed", "add", opkgBridge.feedName, opkgBridge.feedUrl])
			} else {
				opkgBridge.operationName="feed edit"
				var curFeedName = feedsModel[root.currentIndex].name || ""
				//console.log("add_update_feed:edit-feed,feedName:" + opkgBridge.feedName + ",feedUrl:" + opkgBridge.feedUrl + ",curFeedName:" +curFeedName + ",idx:" +root.currentIndex)

				opkgBridge.start(["feed", "edit", opkgBridge.feedName, opkgBridge.feedUrl, curFeedName])
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
			feedsModel.push({ name: name, url: url, builtin: false })
		else if (root.currentIndex >= 0 && root.currentIndex < feedsModel.length) {
			var feed = feedsModel[root.currentIndex]
			feed.name = name
			feed.url = url
		}
		feedsModel = feedsModel.slice();
	}
 
	function loadFeedsFromFile(file) {
		try {
			var filePath = (typeof file === "string") ? file.trim() : "";
			if (!filePath || filePath.length === 0) {
				console.log("loadFeedsFromFile: No feeds file path returned:");
				throw new Error("No feeds file path returned");
			}
			//console.log("FileHelper:" + filePath);

			var jsonText = FileHelper.readFile(filePath);
			if (typeof jsonText !== "string" || jsonText.length === 0) {
				throw new Error("Failed to read feeds file: File is empty or not a string: " + filePath);
			}
			
			var feeds = JSON.parse(jsonText);
			feedsModel = feeds.map(function(feed) {
				return { name: feed.name, url: feed.url, builtin: feed.builtin };
			}).filter(function(f) { return f !== null; });

		} catch (err) {
			console.log("ERROR:loadFeedsFromFile:" + err.message);
			toast.createToast("Error loading feeds: " + err.message);
			feedsModel = [];
		}
	}

	OpkgBridge {
		id: opkgBridge

		property string feedName: ""
		property string feedUrl: ""
		property string opkgErrorLine: ""
		property string feedsPath: "/tmp/opkg-manager/feeds.json"

		function reset() {
			feedName=""
			feedUrl=""
			opkgErrorLine=""
			operationName=""
		}

		onErrorLine: function(line) {
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
					case "feed list":
						//console.log("onFinished: get-feeds:")
						loadFeedsFromFile(feedsPath)
						
						break;
					case "feed remove":
						removeFeed()
						toast.createToast("remove succeeded")
						break;
					case "feed add":
					case "feed edit":
						var isNew = operationName == "feed add"
	
						updateFeed(isNew, feedName, feedUrl)
						toast.createToast((isNew ? "add" : "edit") +  " succeeded")
						//pageStack.pop()
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
