import QtQuick 2

Rectangle {
	id: root

	property var mbStyle
	property var logLines: []
	property bool isWorking: false
	property int dotCount: 1
	property string baseWorking: ""
 
	property alias fontSize: logText.font.pixelSize

	color: mbStyle && mbStyle.themer ? (mbStyle.themer.backgroundColor2 || "#cecece") : "#cecece"
	radius: 4

	onHeightChanged: scrollToBottom()

	Flickable {
		id: logFlickable
		anchors.fill: parent
		contentWidth: logText.width
		contentHeight: logColumn.height
		clip: true

		Column {
			id: logColumn
			width: logFlickable.width - 12
			spacing: 0

			Text {
				id: logText
				text: root.logLines && root.logLines.join("\n")
				font.pixelSize: 13
				color: root.mbStyle ? root.mbStyle.textColor : "#000000"
				wrapMode: Text.Wrap
				width: logFlickable.width - 12
				horizontalAlignment: Text.AlignLeft
				verticalAlignment: Text.AlignTop
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.margins: 6
			}

			Rectangle {
				width: logFlickable.width - 12
				height: 10
				color: "transparent"
			}
		}
	}

	Timer {
		id: progressTimer
		interval: 400
		running: root.isWorking
		repeat: true
		onTriggered: {
			if (root.logLines.length > 0) {
				root.dotCount = root.dotCount % 3 + 1
				root.logLines[root.logLines.length - 1] = root.baseWorking + Array(root.dotCount + 1).join(".")
				root.refreshText()
			}
		}
	}

	function refreshText() {
		logText.text = logLines.join("\n")
		scrollToBottom()
	}

	function scrollToBottom() {
		if (logFlickable.contentHeight > root.height)
			logFlickable.contentY = logFlickable.contentHeight - logFlickable.height
	}

	function startIsWorking(line, clear) {
		if (clear)
			root.clear()
		log(line)
		baseWorking = line
		isWorking = true
		dotCount = 1
	}

	function stopIsWorking(clear) {
		if (clear) {
			root.logLines = []
			logText.text = ""
			return
		}

		if (!isWorking)
			return

		isWorking = false
		progressTimer.stop()
		root.logLines[root.logLines.length - 1] = baseWorking
		root.refreshText()
		dotCount = 1
	}

	function clear() {
		stopIsWorking(true)
	}
	function log(line) {
		stopIsWorking()
		root.logLines.push(line)
		root.refreshText()
	}
	function addLine(line) { log(line) }
}
