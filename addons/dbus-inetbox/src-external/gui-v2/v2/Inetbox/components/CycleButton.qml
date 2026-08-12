import QtQuick
import Victron.VenusOS

Item {
		id: control

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

		implicitHeight: button.height
		implicitWidth: valueLabel.x + valueLabel.width
		icon.color: control.model[control.currentIndex].color
		icon.height: 24
		icon.width: 24
		onCurrentIndexChanged: {
			if (binding && currentIndex >= -1 && currentIndex <= model.length)
				 	binding.setValue(model[currentIndex].value)
		}
		onCurrentValueChanged: {
			for (var i = 0; i < model.length; i++) {
				if (model[i].value == currentValue) {
					currentIndex = i
					return
				}
			}
		}

		Label {
			//% "Waiting for data..."
			text: qsTrId("inetbox_loading")
			visible: control.binding && !control.binding.valid
			anchors {fill: control}
		}

		Button {
			id: button
			flat: true
			font.pixelSize: control.fontPixelSize
			visible: !control.binding || control.binding.valid

			onClicked: {
				control.currentIndex = (control.currentIndex === control.model.length - 1)
				? 0
				: control.currentIndex + 1;
			}

			anchors {
				left: parent.left
				verticalCenter: parent.verticalCenter
			}
			onImplicitWidthChanged: {
				if (control.group === undefined) return
				if (implicitWidth > control.group._maxTextWidth)
					control.group._maxTextWidth = implicitWidth;
			}
		}

		Label {
			id: valueLabel
			visible: !control.binding || control.binding.valid
			text: control.model[control.currentIndex].valueText ?? ""
			font.pixelSize: control.fontPixelSize
			color: "dimgrey"
			width: control.group === undefined ? undefined: control.group.valueWidth
			anchors {
				left: control.group == undefined ? button.right : button.left
				leftMargin: control.group == undefined ? 0 : control.group._maxTextWidth + 10
				verticalCenter: button.verticalCenter
			}
		}
	}