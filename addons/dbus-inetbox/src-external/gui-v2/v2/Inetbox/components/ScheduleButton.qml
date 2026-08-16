import QtQuick 2.15
import QtQuick.Templates 2.15 as T
import QtQuick.Controls as Controls
import QtQuick.Layouts

	Controls.Button {
		id: control
		width: 44
		height: 44

		// Base color
		property color mainColor: "#387DC5"
		property real iconOpacity: 1

		icon.width: 24
		icon.height: 24

		// Content layout (Icon + Text centered together)
		contentItem: Image {
				id: iconDisplay
				anchors.centerIn: parent
				opacity: control.iconOpacity
				source: control.icon.source
				sourceSize.width: control.icon.width
				sourceSize.height: control.icon.height
				width: control.icon.width
				height: control.icon.height
				fillMode: Image.PreserveAspectFit

				// Only visible if an icon path is provided
				visible: source.toString() !== ""
				// Both icon and text shift down slightly when pressed for extra tactile depth
				transform: Translate {
					y: control.down ? 1 : 0
				}

		}

		background: Item {
			id: bg

			// 1. Outer Lip (Surrounding rim)
			Rectangle {
				anchors.fill: parent
				radius: width / 2
				color: Qt.darker(control.mainColor, 1.2)
				border.color: Qt.lighter(control.mainColor, 1.2)
				border.width: 1
			}

			// 2. Concave Bowl
			Rectangle {
				anchors.fill: parent
				anchors.margins: 3
				radius: width / 2

				gradient: Gradient {
					orientation: Gradient.Vertical

					GradientStop {
						position: 0.0
						color: control.down ? Qt.darker(control.mainColor, 1.5) : Qt.darker(control.mainColor, 1.3)
					}

					GradientStop {
						position: 0.5
						color: control.down ? Qt.darker(control.mainColor, 1.15) : control.mainColor
					}

					GradientStop {
						position: 1.0
						color: control.down ? control.mainColor : Qt.lighter(control.mainColor, 1.25)
					}
				}

				// 3. Inner shadow rim
				Rectangle {
					anchors.fill: parent
					radius: width / 2
					color: "transparent"
					border.color: Qt.rgba(0, 0, 0, control.down ? 0.4 : 0.2)
					border.width: 2
				}
			}
		}
	}
