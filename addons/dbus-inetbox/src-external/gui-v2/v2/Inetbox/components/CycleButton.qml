import QtQuick
import Victron.VenusOS

Item {
		id: root

    required property VeQuickItem binding
    property int currentIndex
    readonly property var currentValue: binding?.value
		property alias icon: button.icon
		property var model: []

		property alias text: button.text
		property alias valueText: valueLabel.text

		property alias valueColor: valueLabel.color
		property real fontPixelSize: 24

		property CycleButtonGroup group
		property bool _syncingFromBinding: false

		implicitHeight: button.height
		implicitWidth: valueLabel.x + valueLabel.width
		icon.color: model === undefined
				? "dimgrey"
				: model[currentIndex].color
					? model[currentIndex].color
					: Theme.color_font_primary

		icon.height: 24
		icon.width: 24
		onCurrentIndexChanged: {
			if (_syncingFromBinding || !binding || !model || currentIndex < 0 || currentIndex >= model.length)
				return

			const nextValue = model[currentIndex].value
			if (nextValue !== currentValue)
				binding.setValue(nextValue)
		}
		onCurrentValueChanged: {
			if (!model || model.length === 0)
				return
			for (var i = 0; i < model.length; i++) {
				if (model[i].value == currentValue) {
					if (currentIndex !== i) {
						_syncingFromBinding = true
						currentIndex = i
						_syncingFromBinding = false
					}
					return
				}
			}
		}

		Label {
			//% "Waiting for data..."
			text: qsTrId("inetbox_loading")
			visible: root.binding && !root.binding.valid
			anchors {fill: root}
		}

		Button {
			id: button
			flat: true
			font.pixelSize: root.fontPixelSize
			visible: !root.binding || root.binding.valid

			onClicked: {
				root.currentIndex = (root.currentIndex === root.model.length - 1)
				? 0
				: root.currentIndex + 1;
			}

			anchors {
				left: parent.left
				verticalCenter: parent.verticalCenter
			}
			onImplicitWidthChanged: {
				if (root.group === undefined) return
				if (implicitWidth > root.group._maxTextWidth)
					root.group._maxTextWidth = implicitWidth;
			}
		}

		Label {
			id: valueLabel
			visible: !root.binding || root.binding.valid
			text: root.model[root.currentIndex].valueText ?? ""
			font.pixelSize: root.fontPixelSize
			color: "dimgrey"
			width: root.group === undefined ? undefined: root.group.valueWidth
			anchors {
				left: root.group == undefined ? button.right : button.left
				leftMargin: root.group == undefined ? 0 : root.group._maxTextWidth + 10
				verticalCenter: button.verticalCenter
			}
		}
	}