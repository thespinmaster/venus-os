import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils

MbPage {
	id: root

	property variant service
	property string bindPrefix
 
	title: service ? service.description : ""
	summary: "heating"
 
	model: VisibleItemModel {
		MbItemOptions {
			id: status
			description: qsTr("Status")
			bind: service.path("/Status")
			readonly: true
			show: item.valid
			possibleValues: [
				MbOption { description: qsTr("Ok"); value: 0 },
				MbOption { description: qsTr("Open circuit"); value: 1 },
				MbOption { description: qsTr("Short circuited"); value: 2 },
				MbOption { description: qsTr("Reverse polarity"); value: 3 },
				MbOption { description: qsTr("Unknown"); value: 4 }
 
			]
		}
     
		MbSubMenu {
			id: setupMenu

			description: qsTr("Setup")
			subpage: Component {
				InetboxSetupPage {
					title: setupMenu.description
				}
			}
		}

		MbSubMenu {
			id: deviceMenu
			description: qsTr("Device")
			subpage: Component {
				PageDeviceInfo {
					title: deviceMenu.description
					bindPrefix: root.bindPrefix
				}
			}
		}

		MbSubMenu {
			id: usbPropsMenu
			description: qsTr("Serial Device")
			subpage: Component {
				OpkgPageSerialDeviceInfo {
					title: usbPropsMenu.description
					bindPrefix: root.bindPrefix
				}
				
			}
		}
	}


}
