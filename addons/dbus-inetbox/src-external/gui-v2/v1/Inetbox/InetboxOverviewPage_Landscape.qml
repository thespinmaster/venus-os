import QtQuick
import Victron.VenusOS
import QtQuick.Layouts
//import "qrc:/Inetbox/" as Inetbox //Inetbox.InetboxBackground

Page { // the blue shadows
	id: root

	property var device: deviceLoader.device
	readonly property string deviceServiceUid: device && device.serviceUid ? device.serviceUid : ""
	property real widgetSpacing: 20;
  property color widgetColor_base: Theme.color_overviewPage_widget_background
	// property color widgetColor: Qt.rgba(
	// 		widgetColor_base.r,
	// 		widgetColor_base.g,
	// 		widgetColor_base.b,
	// 		0.6
	// )
  property color widgetColor: "#00000000"

	function deviceUid(suffix) {
		return deviceServiceUid ? (deviceServiceUid + suffix) : ""
	}

	VeQuickItem {id: statusItem; uid: root.deviceUid("/Values/Status")}
	VeQuickItem {id: heatingCurTemp
		uid: root.deviceUid("/Values/CurrentRoomTemp")
		sourceUnit: Units.unitToVeUnit(VenusOS.Units_Temperature_Celsius)
		displayUnit: Units.unitToVeUnit(Global.systemSettings.temperatureUnit)
	}

	Image {
		id: bg_image
		source: "qrc:/Inetbox/image_overview_bg.jpg"
		anchors.fill: parent
	}

	Label {
		id: heatingCurrentTempText2
		text: heatingCurTemp.text
		font.pixelSize: 48
		x: waterControlContainer.x + waterControlContainer.width
		 		+ ((energyMixControlContainer.x - (waterControlContainer.x + waterControlContainer.width)) / 2)
		 		- (width / 2)
		y: waterControlContainer.y + waterControlContainer.height
		 		+ ((heatingControlContainer.y - (waterControlContainer.y + waterControlContainer.height)) / 2)
		 		- (height / 2)
	}
 
	RowLayout {
		id: header
		anchors {
			top: parent.top
			left: parent.left
			right: parent.right
			leftMargin: Theme.geometry_page_content_horizontalMargin
			rightMargin: Theme.geometry_page_content_horizontalMargin
			topMargin: Theme.geometry_overviewPage_widget_content_topMargin
		}
		spacing: 6
		Led {
			id: aliveLed
			dataItem.uid: root.deviceUid("/Values/Alive")
			color: "#58cf08"
			implicitWidth: 16
			implicitHeight: 16
		}

		Label {
			text: statusItem.value
			font.pixelSize: Theme.font_listItem_primary_size
			Layout.leftMargin: 6
		}

		Label {
			text: "Motorhome"
			anchors.left: parent.left
			anchors.right: parent.right
			font.pixelSize: Theme.font_listItem_primary_size
			horizontalAlignment: Text.AlignHCenter
		}

	}

	GridLayout {
		anchors {
			fill: parent
			// top: header.bottom
			// left: parent.left
			// right: parent.right
			// bottom: parent.bottom
			margins: 20 // Padding around the edges of the page
		}

		columns: 2
		rowSpacing: 100 // Space between top and bottom rows
		columnSpacing: 200 // Space between left and right columns

		// Top Left
		// Water
		InetboxWaterWidget {
			id: waterControlContainer
			device: root.device
			Layout.fillWidth: true
			color: root.widgetColor
			//rotation: 180

		}
		// Top Right
		InetboxEnergyMixWidget {
			id: energyMixControlContainer
			Layout.fillWidth: true
			device: root.device
			color: root.widgetColor
			//rotation: 180
			//mirror: true
		}

		// Bottom Left
		InetboxHeatingWidget {
			id: heatingControlContainer
			device: root.device
			color: root.widgetColor
			Layout.fillWidth: true
			implicitHeight: airconControlContainer.height
			//mirror: true
		}

		// Bottom Right
		InetboxAirconWidget {
			id: airconControlContainer
			device: root.device
			color: root.widgetColor
			Layout.fillWidth: true
			//Layout.fillHeight: true
		}
	}

}
