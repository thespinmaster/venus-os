import QtQuick 2.15
import QtQuick.Templates 2.15 as T
import QtQuick.Controls as Controls
import QtQuick.Layouts

Rectangle {
	id: root

	color: "black"
	anchors.fill: parent

	property real maxTankLabelWidth: 0

	Item {

		Text {
			y: temp.y - 120
			x: temp.x + 80
			text: temp.value
			color: "white"
		}
		MinimalSlider {
			id: temp
			anchors.top: parent.top
			anchors.topMargin: 200

			from: 5
			to: 32
			stepSize: 1

			angle: 250 // Slanted 25 degrees

			//onValueChanged: console.log("Value changed to:", value)
		}
 
		anchors {
			fill: parent
			leftMargin: 5
			topMargin: 5
		}
	}

	component MinimalSlider: T.Slider {
		id: control

		property real angle: 0
		//property color trackColor: "#E0E0E0"
		property color progressColor: "#2196F3"
		property color handleColor: '#911e88e5'
		property color handlePressedColor: "#1565C0"
		property color tickColor: '#ffffff'

		property bool hideProgress: true
		property bool hideTicks: true

		property real tickThickness: 2
		property real tickLength: tickThickness
		property real tickRadius: tickLength / 2
		property real tickAngle: 0

		property real handleDiameter: 24
		property real trackThickness: 2

		// Default sizing
		implicitWidth: Math.max(implicitBackgroundWidth + leftPadding + rightPadding, implicitHandleWidth + leftPadding + rightPadding)
		implicitHeight: Math.max(implicitBackgroundHeight + topPadding + bottomPadding, implicitHandleHeight + topPadding + bottomPadding)

		// Reserve horizontal padding so the circle handle doesn't clip at min/max edges
		padding: 0
		leftPadding: handleDiameter / 2
		rightPadding: handleDiameter / 2

		// Apply rotation slant around center
		transformOrigin: Item.Center
		rotation: angle

		// --- Track / Background Delegate ---
		background: Item {
			x: control.leftPadding
			y: control.topPadding + control.availableHeight / 2 - height / 2
			implicitWidth: 200 // default width
			implicitHeight: control.trackThickness
			width: control.availableWidth
			height: implicitHeight

			// Active Progress Fill
			Rectangle {
				width: control.visualPosition * parent.width
				height: parent.height
				color: control.progressColor

				opacity: control.hideProgress ? (control.pressed ? 1.0 : 0.0) : 1.0
				Behavior on opacity  {
					enabled: control.hideProgress
					NumberAnimation {
						duration: control.pressed ? 2000 : 150
						// Optional: Easing curves make the transition feel even smoother
						easing.type: control.pressed ? Easing.OutCubic : Easing.InQuad
					}
				}
			}

			// Tick Marks (Visible when slider is pressed)
			Item {
				anchors.fill: parent

				opacity: control.hideTicks ? (control.pressed ? 1.0 : 0.0) : 1.0
				Behavior on opacity  {
					enabled: control.hideTicks
					NumberAnimation {
						duration: control.pressed ? 2000 : 150
						// Optional: Easing curves make the transition feel even smoother
						easing.type: control.pressed ? Easing.OutCubic : Easing.InQuad
					}
				}

				Repeater {
					model: (control.stepSize > 0 && control.to > control.from) ? Math.floor((control.to - control.from) / control.stepSize) + 1 : 0

					delegate: Rectangle {
						id: tick
						rotation: control.tickAngle
						transformOrigin: Item.Center
						required property int index
						property real range: control.to - control.from
						property real fraction: range > 0 ? (index * control.stepSize) / range : 0

						x: fraction * parent.width - (width / 2)
						anchors.verticalCenter: parent.verticalCenter
						width: control.tickThickness
						height: control.tickLength
						color: control.tickColor
						radius: control.tickThickness
					}
				}
			}
		}

		// --- Circular Handle Delegate ---
		handle: Rectangle {
			x: control.leftPadding + control.visualPosition * control.availableWidth - width / 2
			y: control.topPadding + control.availableHeight / 2 - height / 2
			implicitWidth: control.handleDiameter
			implicitHeight: control.handleDiameter
			radius: width / 2
			color: control.pressed ? control.handlePressedColor : control.handleColor

			border.color: "#FFFFFF"
			border.width: 2
		}
	}



}
