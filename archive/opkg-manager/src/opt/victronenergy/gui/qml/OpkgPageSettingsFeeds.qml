import QtQuick 2
import com.victron.velib 1.0
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
		processRunner.operationName = "feed list"
		processRunner.start(["feed", "list"])
	}

	Component.onDestruction: {


		if (processRunner)
				processRunner.cleanup()
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
						readonly: !userHasWriteAccess || (feedModel?.builtin ?? true)
						useVirtualKeyboard: false
						description: qsTr("Name")
						maximumLength: 20
						enableSpaceBar: false
 
						item.value: (!isNew && root.feedsModel) ? feedModel.name : ""

					}
				
					OpkgEditBoxLargeText {
						id: feedUrlEdit
						readonly: !userHasWriteAccess || (feedModel?.builtin ?? true)
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
						visible: feedModel?.builtin
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
			if (processRunner.running) {
				return
			}
			
			var page = editFeedPageComponent.createObject(pageStack, { isNew: true });
			if (page) {
				pageStack.push(page);
			}
		}
		function rightAction() {
			if (processRunner.running) {
				return
			}
			processRunner.operationName = "feed remove"
 
			var name = feedsModel[root.currentIndex].name
			processRunner.start(["feed", "remove", name])
		}
	}

	//////////////////
	// methods
 
  function add_update_feed(isNew, name, url) {
		if (!processRunner || processRunner.running) {
				return
			}
			if (!isValid()) {
				return
			}
			
			processRunner.feedName = name || ""
			processRunner.feedUrl = url || ""
			if (isNew) {
 
				processRunner.operationName="feed add"
				//console.log("add_update_feed:add-feed,feedName:" + processRunner.feedName + ",feedUrl:" + processRunner.feedUrl)

				processRunner.start(["feed", "add", processRunner.feedName, processRunner.feedUrl])
			} else {
				processRunner.operationName="feed edit"
				var curFeedName = feedsModel[root.currentIndex].name || ""
				//console.log("add_update_feed:edit-feed,feedName:" + processRunner.feedName + ",feedUrl:" + processRunner.feedUrl + ",curFeedName:" +curFeedName + ",idx:" +root.currentIndex)

				processRunner.start(["feed", "edit", processRunner.feedName, processRunner.feedUrl, curFeedName])
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
			var feed = feedsModel[root.currentIndex]
			feed.name = name
			feed.url = url
		}
		feedsModel = feedsModel.slice();
	}
 
	function loadFeedsFromJson(jsonText) {
		try {
			if (typeof jsonText !== "string" || jsonText.length === 0) {
				throw new Error("Failed to load feeds JSON: empty response");
			}
			
			var feeds = JSON.parse(jsonText);
			feedsModel = feeds.map(function(feed) {
				return { name: feed.name, url: feed.url, builtin: feed.builtin };
			}).filter(function(f) { return f !== null; });

		} catch (err) {
			console.log("ERROR:loadFeedsFromJson:" + err.message);
			toast.createToast("Error loading feeds: " + err.message);
			feedsModel = [];
		}
	}

	OpkgServiceProcess {
		id: processRunner

		property string feedName: ""
		property string feedUrl: ""
		property string opkgErrorLine: ""

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
						loadFeedsFromJson(jsonResult)
						
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
