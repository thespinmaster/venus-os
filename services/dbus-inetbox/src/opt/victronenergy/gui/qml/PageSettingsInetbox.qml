import QtQuick 2
import com.victron.velib 1.0
import net.connman 0.1
import "utils.js" as Utils

MbPage {
	id: root
	title: qsTr("Inetbox")

	model: VisibleItemModel {
		MbSwitch {
			id: inetboxEnabled
			name: qsTr("Enabled")
			bind: "com.victronenergy.settings/Settings/Devices/dbus_inetbox/Enabled"
		}
		MbSwitch {
			id: showAirconEnabled
			name: qsTr("Show Aircon")
			bind: "com.victronenergy.settings/Settings/Devices/dbus_inetbox/ShowAircon"
		}
		MbEditBox {
			id: name
			description: qsTr("Name")
			item {
				bind: "com.victronenergy.settings/Settings/Devices/dbus_inetbox/CustomName"
				invalidate: false
			}
			show: item.valid
			maximumLength: 32
			enableSpaceBar: true
		}

		MbItemOptions {
			description: qsTr("Theme")
			bind: Utils.path("com.victronenergy.settings", "/Settings/Devices/dbus_inetbox/Theme")
			possibleValues: [
				MbOption { description: qsTr("Dark"); value: "dark" },
				MbOption { description: qsTr("VE Blue 1"); value: "veBlue1" },
				MbOption { description: qsTr("VE Blue 2"); value: "veBlue2" },
				MbOption { description: qsTr("Light"); value: "light" }
			]
		}

    MbSubMenu {
      description: qsTr("Setup")
      subpage: Component { PageSettingsInetboxDeviceSetup {} }
    }
		
	}
}
