import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
import QtQuick.Controls

OverviewPage {
	id: root

	property variant sys: theSystem
	property string settingsPrefix: "com.victronenergy.settings"
	property string systemPrefix: "com.victronenergy.system"
	property string platformPrefix: "com.victronenergy.platform"
	property string inetboxPrefix: ""
	property VBusItem _systemState: VBusItem { bind: Utils.path(systemPrefix, "/SystemState/State") }
	property bool hasSystemState: _systemState.valid
  
	// Inetbox DBus bindings
	VBusItem { id: waterTargetTempItem; bind: Utils.path(inetboxPrefix, "/Values/WaterTargetTemp") }
 
	Connections {
		target: DBusServices
		
		function onDbusServiceFound(service) { 
			console.debug("njka:onDbusServiceFound:" + service.name)
			findInetboxService(service) 
		}
		function onDbusServiceConnected(service) {
			console.debug("njka:onDbusServiceConnected:" + service.name)
			findInetboxService(service)
		}
		function onDbusServiceDisconnected(service) {
			if (inetboxPrefix === service.name) {
				inetboxPrefix = ""
			}
		}
	}

	Component.onCompleted: {
		discoverServices()
		inetboxDiscoveryTimer.start()
	}

	Timer {
		id: inetboxDiscoveryTimer
		interval: 1000
		repeat: true
		running: false
		onTriggered: {
			if (inetboxPrefix === "") {
				discoverServices()
			} else {
				stop()
			}
		}
	}

	function findInetboxService(service) {
		console.debug("findInetboxService")
		
		if (service.name.indexOf("com.victronenergy.dbus_inetbox") === 0) {
			if (inetboxPrefix === "") {
				inetboxPrefix = service.name
				console.debug("Found inetbox service: " + inetboxPrefix)
				
			}
		}
	}

	function discoverServices() {
		// Scan existing services for inetbox
		console.debug("njka:discoverServices:" + DBusServices.count.toString())
		for (var i = 0; i < DBusServices.count; i++) {
			console.error("njka:discoverServices")
			var service = DBusServices.at(i)
			if (service.name.indexOf("com.victronenergy.dbus_inetbox") === 0) {
				inetboxPrefix = service.name
				console.debug("Discovered inetbox service: " + inetboxPrefix)
				break
			}
		}
	}
	 
	
	Rectangle {
			id: rectangle
				anchors.fill: parent
				color: "#1C3749"
			
			// Header
			Text {
					id: header
					width: 188
					height: 30
					color: "#FFFFFF"
					text: qsTr("Test")
					anchors.top: parent.top
					anchors.topMargin: 0
					font.pixelSize: 20
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
					anchors.horizontalCenter: parent.horizontalCenter
					font.styleName: "Bold"
			}
   

	}
}
