import QtQuick 2
import com.victron.velib 1.0
import OpkgManager 1.0

MbPage {
	id: root
	title: qsTr("Feed")

	property int feedIndex: -1
	property string feedName: ""
	property string feedUrl: ""
	property string feedNameOld: ""
	property var updateFeed
	property bool opkgPending: false
	property string opkgErrorLine: ""
 
	function setItemValue(item, value) {
		console.log("setItemValue" + value)
		if (item && value !== undefined && value !== null) {
			item.value = String(value)
		}
	}

	function refreshFeed() {
		setItemValue(feedNameEdit.item, feedName)
		setItemValue(feedUrlEdit.item, feedUrl)
	}
 
	function onFeedIndexChanged() {
		refreshFeed()
	}
 
	model: VisibleItemModel {
		MbEditBox {
			id: feedNameEdit
			description: qsTr("Name")
			maximumLength: 64
			enableSpaceBar: false
			item.value: feedName
			onEditDone: {
				if (!feedNameOld || feedNameOld=="")
					feedNameOld=feedName
				feedName = newValue
			}
		}

		OpkgEditBoxLargeText {
			id: feedUrlEdit
			description: qsTr("Url")
			maximumLength: 256
			matchString: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ~!@#$%^&*()-_=+[]{}\\;:|/.,<>?"
			enableSpaceBar: false
 
			//textInput.width:200
			item.value: feedUrl
			
			onEditDone: {
				feedUrl = newValue
			}
			
		}
	}
 

	ProcessRunner {
		id: opkgRunner
		onErrorLine: {
			opkgErrorLine = line
		}
		onFinished: {
			if (!opkgPending) {
				return
			}
			opkgPending = false
			if (exitCode === 0 && exitStatus === 0) {
				if (updateFeed) {
					updateFeed(feedIndex, feedName, feedUrl)
				}
				pageStack.pop()
			} else {
				toast.createToast(opkgErrorLine.length ? opkgErrorLine : qsTr("Failed to add feed"))
			}
		}
	}

	
	pageToolbarHandler: ToolbarHandler {
		leftIcon: "icon-toolbar-cancel"
		rightIcon: "icon-toolbar-ok"

		function leftAction() {
			pageStack.pop()
		}

		function rightAction() {
			if (opkgRunner.running) {
				return
			}
			opkgPending = true
			opkgErrorLine = ""
			if (feedIndex == -1) {
				opkgRunner.start(["add-feed", feedName, feedUrl])
			} else {
				opkgRunner.start(["edit-feed", feedName, feedUrl, feedNameOld])
			}
			
		}
	}

}
