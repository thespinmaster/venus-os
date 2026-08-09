import QtQuick
import Victron.VenusOS
import QtQuick.Layouts
import "."

Page {
	id: root
	title: "Inetbox"

	property var device: deviceLoader.device
	readonly property string deviceServiceUid: device && device.serviceUid ? device.serviceUid : ""
	property real widgetSpacing: Theme.geometry_overviewPage_widget_content_horizontalMargin

	property color widgetColor:  Theme.color_background_secondary


	function deviceUid(suffix) {
		return deviceServiceUid ? (deviceServiceUid + suffix) : ""
	}

	VeQuickItem {id: statusItem; uid: root.deviceUid("/Values/Status")}
	VeQuickItem {id: heatingCurTemp
		uid: root.deviceUid("/Values/CurrentRoomTemp")
		sourceUnit: Units.unitToVeUnit(VenusOS.Units_Temperature_Celsius)
		displayUnit: Units.unitToVeUnit(Global.systemSettings.temperatureUnit)
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
			//dataItem.value: 0// item.valid && item.value == "ON" ? 1 : 0
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
/*
		Label {
			text: "Motorhome"
			font.pixelSize: Theme.font_listItem_primary_size
			horizontalAlignment: Text.AlignHCenter
		}
*/

		Item { Layout.fillWidth: true }

		Label {
			id: heatingCurrentTempText
			text: heatingCurTemp.text

			font.pixelSize: Theme.font_listItem_primary_size
		}

	}

	// Water
	InetboxWaterWidget {
		id: waterControlContainer
		device: root.device
		bottomMargin: 0
		width: ((parent.width - (Theme.geometry_page_content_horizontalMargin * 2))) / 2
		color: root.widgetColor

		anchors {
			top: header.bottom
			left: parent.left
			leftMargin: Theme.geometry_page_content_horizontalMargin
			right: parent.right
			rightMargin: Theme.geometry_page_content_horizontalMargin
			topMargin: Theme.geometry_overviewPage_widget_content_topMargin
		}
	}

	InetboxEnergyMixWidget {
		id: energyMixControlContainer
		device: root.device
		color: root.widgetColor

		anchors {
			top: waterControlContainer.bottom
			topMargin: Theme.geometry_overviewPage_widget_content_topMargin
			right: waterControlContainer.right
			left: waterControlContainer.left
		}

	}

	InetboxHeatingWidget {
		id: heatingControlContainer
		device: root.device
		bottomMargin: 0
		color: root.widgetColor

		anchors {
			top: energyMixControlContainer.bottom
			topMargin: Theme.geometry_overviewPage_widget_content_topMargin
			left: waterControlContainer.left
			right: waterControlContainer.right
		}
	}

	InetboxAirconWidget {
		id: airconControlContainer
		device: root.device
		color: root.widgetColor
		//border {color: groupBorderColor;width: 1}
		anchors {
			top: heatingControlContainer.bottom
			topMargin: Theme.geometry_overviewPage_widget_content_topMargin
			left: waterControlContainer.left
			right: waterControlContainer.right
		}
	}
}
