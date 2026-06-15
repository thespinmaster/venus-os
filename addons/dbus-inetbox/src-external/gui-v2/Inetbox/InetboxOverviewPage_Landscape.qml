import QtQuick
import Victron.VenusOS
import QtQuick.Layouts
import "."

Page {
	id: root
 
	property var device: null
	readonly property string deviceServiceUid: device && device.serviceUid ? device.serviceUid : ""
	property real widgetSpacing: 100; //Theme.geometry_overviewPage_widget_content_horizontalMargin

  property color widgetColor_base: Theme.color_boatPage_background
	property color widgetColor: Qt.rgba(
			widgetColor_base.r,
			widgetColor_base.g,
			widgetColor_base.b,
			0.5
	)
 
	function deviceUid(suffix) {
		return deviceServiceUid ? (deviceServiceUid + suffix) : ""
	}

	VeQuickItem {id: statusItem; uid: root.deviceUid("/Values/Status")}
	VeQuickItem {id: heatingCurTemp
		uid: root.deviceUid("/Values/CurrentRoomTemp")
		sourceUnit: Units.unitToVeUnit(VenusOS.Units_Temperature_Celsius)
		displayUnit: Units.unitToVeUnit(Global.systemSettings.temperatureUnit)
	}

	VeQuickItem {
		id: logger
		uid: Global.systemSettings.serviceUid + "/Settings/EventLogger/Log1"
		function log(message) {
		  logger.setValue("Inetbox-" + message)
		}
	}
 
	Image {
		id:bg_image
		source: "qrc:/Inetbox/image_overview_bg.svg"
		width:300
		height:300
		fillMode: Image.PreserveAspectFit   // or PreserveAspectCrop / Stretch
    smooth: true
		x: waterControlContainer.x + waterControlContainer.width
				+ ((energyMixControlContainer.x - (waterControlContainer.x + waterControlContainer.width)) / 2)
				- (width / 2)
		y: waterControlContainer.y + waterControlContainer.height
				+ ((heatingControlContainer.y - (waterControlContainer.y + waterControlContainer.height)) / 2)
				- (height / 2)
	}
	Label {
			id: heatingCurrentTempText2
			text: heatingCurTemp.text
			font.pixelSize: 48
			anchors.centerIn: bg_image
	}

	// Header
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
			//dataItem.uid: root.device.serviceUid + "/Values/Status"
			Layout.leftMargin: 6
		}

		Item { Layout.fillWidth: true }

		Label {
			text: "Motorhome"
			font.pixelSize: Theme.font_listItem_primary_size
			horizontalAlignment: Text.AlignHCenter
		}

		Item { Layout.fillWidth: true }
		/*
		Label {
			id: heatingCurrentTempText
			text: heatingCurTemp.text
		
			font.pixelSize: Theme.font_listItem_primary_size
		}
		*/
	}

// Water
InetboxWaterWidget {
	id: waterControlContainer
	device: root.device
	width: ((parent.width-(Theme.geometry_page_content_horizontalMargin * 2))) / 2
	color: root.widgetColor
	anchors {
		top: header.bottom
		left: parent.left
		leftMargin: Theme.geometry_page_content_horizontalMargin
		rightMargin: root.widgetSpacing
		topMargin: Theme.geometry_overviewPage_widget_content_topMargin
	}
}

InetboxEnergyMixWidget {
	id: energyMixControlContainer
	height: Math.max(waterControlContainer.height, implicitHeight)
	device: root.device
	color: root.widgetColor
	
	anchors {
		top: header.bottom
		right: parent.right
		rightMargin: Theme.geometry_page_content_horizontalMargin
		left: waterControlContainer.right
		leftMargin: root.widgetSpacing
		topMargin: Theme.geometry_overviewPage_widget_content_topMargin
	}
 
}

InetboxHeatingWidget {
	id: heatingControlContainer
	device: root.device
	width: waterControlContainer.width
	color: root.widgetColor
	anchors {
		top: waterControlContainer.bottom
		topMargin: root.widgetSpacing
		left: waterControlContainer.left
		bottom: parent.bottom
		rightMargin: Theme.geometry_overviewPage_widget_content_horizontalMargin
	}
		
}
 
	InetboxAirconWidget {
		id: airconControlContainer
		width: energyMixControlContainer.width
		device: root.device
		color: root.widgetColor
		//border {color: groupBorderColor;width: 1}
		anchors {
			top: energyMixControlContainer.bottom
			left: energyMixControlContainer.left
			bottom: parent.bottom
			rightMargin: Theme.geometry_overviewPage_widget_content_horizontalMargin
			topMargin: root.widgetSpacing
		}
	}
}
