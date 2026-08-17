import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.impl as CP
import Victron.VenusOS
import Victron.Gauges
import "./components" as IC

Page {
	id: root

	required property var inetboxModel
	required property bool animationEnabled
	required property GaugeModel gaugeModel

	property string image_boat_glow: "qrc:/images/boat_glow.png"

	// Tank Levels
	RowLayout {
		id: mainRow
		spacing: 20

		anchors {
			left: parent.left
			leftMargin: 20
			right: parent.right
		}
		IC.MotorhomeTankLevels {
			model: root.gaugeModel
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.preferredWidth: 0.8
		}
		IC.MotorhomePower {
			Layout.fillWidth: true
			animationEnabled: root.animationEnabled
		}
	}

	Component {
		id: dateSelectorDialog
		DateSelectorDialog {}
	}

	//  width: 225
	//  rotation: 250.5
  //  topMargin: root.inetboxOffsetY + 198

	IC.ScheduleButton {
		icon.source: "qrc:/images/icon_manualstart_timer_24.svg"
		mainColor: '#387dc5'
		anchors {
			right: bg_image2.right
			rightMargin: 200
			top: bg_image2.top
			topMargin: 50
		}

		onClicked: {
			Global.dialogLayer.open(dateSelectorDialog)
			return
		}
	}

	ColumnLayout {
		anchors {
			left: parent.left; leftMargin: 40
			top: mainRow.bottom; topMargin: 10
			right: bg_image.right
			bottom: bg_image.bottom; bottomMargin:40
		}

		IC.MotorhomeInetbox {
			model: root.inetboxModel
			color: "transparent"
			targetTemperatureSlider.hideTicks: Theme.screenSize !== Theme.Portrait
			buttonOffsetX: 30
			Layout.fillHeight: true
			Layout.fillWidth: true
			Layout.leftMargin: 80
		}
	}

	// version
	Label {
		color: "grey"
		anchors {
			right: parent.right
			rightMargin: 50
			bottom: bg_image.bottom
		}
		text: root.inetboxModel.version
	}

	// left image
	CP.ColorImage {
		id: bg_image
		height: 370
		mirror: true
		rotation: 180
		source:root.image_boat_glow
		width: 800
		z: -1
		anchors {
			left: parent.left
			leftMargin: 20
			top: mainRow.bottom
			topMargin: -35
		}
	}

	//right image
	CP.ColorImage {
		id: bg_image2
		height: 370
		mirror: true
		//rotation: 180
		source: root.image_boat_glow
		width: 800
		z: -1
		anchors {
			right: parent.right
			leftMargin: 20
			top: mainRow.bottom
			topMargin: 50
		}
	}
}
