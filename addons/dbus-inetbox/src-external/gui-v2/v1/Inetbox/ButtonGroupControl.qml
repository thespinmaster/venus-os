// ButtonGroupControl.qml
//pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Victron.VenusOS

FocusScope {
	id: root
	focusPolicy: Qt.StrongFocus
	implicitWidth: row.implicitWidth
	implicitHeight: row.implicitHeight

	property alias model: repeater.model
	property alias item: vItem
	property alias value: vItem.value
	property string bind: ""

	VeQuickItem {
		id: vItem
		uid: root.bind
	}

	onActiveFocusChanged: {
		//Reset the focus to the first item when exiting focus.
		if (!root.activeFocus) {
			var isSet = false
			for (var i = 0; i < repeater.count; i++) {
				var itm = repeater.itemAt(i)
				if (!itm) continue
				if (!isSet && itm.enabled) {
					itm.focus = true
					isSet = true
					continue
				}
				itm.focus = false
			}
		}
	}

	ButtonGroup { id: buttonGroup }

	Row {
		id: row
		spacing: 0
		focus: true
		Repeater {
			id: repeater
			model: null
			delegate: repeaterDelegate
		}
	}

	Component {
		id: repeaterDelegate

		RadioDelegate {
			id: control
			focusPolicy:  root.focusPolicy
			text: modelData.text
			font.family: Global.fontFamily
			font.pixelSize: Theme.font_button_size
			indicator: null
			checked: root.value == modelData.value
			ButtonGroup.group: buttonGroup
			KeyNavigationHighlight.active: control.activeFocus
			required property int index
			required property var modelData

			onCheckedChanged: customCanvas.requestPaint()
			onPressedChanged: customCanvas.requestPaint()

			background: Item {
				width: control.width
				height: control.height

				Canvas {
					id: customCanvas
					anchors.fill: parent

					onPaint: {

						var ctx = getContext("2d");
						ctx.clearRect(0, 0, width, height);
						ctx.strokeStyle = enabled ? Theme.color_ok : Theme.color_background_disabled
						ctx.lineWidth = Theme.geometry_button_border_width

						var offset = ctx.lineWidth / Theme.geometry_button_border_width
						var isFirst = control.index === 0
						var isLast = control.index === control.ButtonGroup.group?.buttons.length - 1 ?? 0
						var radius = height / 2

						ctx.beginPath();

						if (isFirst) {
							if (isLast)
								ctx.arc(radius, radius, radius - offset, 2.5 * Math.PI, 1.5 * Math.PI)
							else
								ctx.arc(radius, radius, radius - offset,  1.5 * Math.PI, 2.5 * Math.PI,1)
						}

						if (!isFirst && !isLast) {
							ctx.moveTo(width, offset)
							ctx.lineTo(width, height - offset)
						}

						if (!isFirst || !isLast) {
							var x = isFirst ? width : 0
							ctx.lineTo(x, height - offset)
							ctx.lineTo(x, offset)
						}

						if (isLast)
							ctx.arc(width - radius, radius, radius - offset, 1.5 * Math.PI, 2.5 * Math.PI)

						ctx.closePath()

						if (control.checked || control.down || !enabled) {
							ctx.fillStyle = enabled
								? (control.checked ? (control.down ? Theme.color_darkOk : Theme.color_ok)
									: Theme.color_darkOk)
								: (control.checked ? Theme.color_button_on_background_disabled
									: Theme.color_background_disabled)

							ctx.fill() //fill before stroke
						}

						ctx.stroke()
					}
				}
			}

			contentItem: Text {
				text: control.text
				font: control.font
				color: Theme.color_button_down_text
				//color: enabled ? control.down ? Theme.color_button_down_text : color_button_down
				verticalAlignment: Text.AlignVCenter
			}
		}
	}
}
