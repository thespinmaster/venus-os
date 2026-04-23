import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils

MbPage {
	id: root
  title: service ? service.description : ""

	property variant service
	property string bindPrefix
  property string sdiRuleId

	property VBusItem vItemSdiRuleId: VBusItem {
		bind: Utils.path(root.bindPrefix, "/SdiRuleID")
		onValueChanged: {
			if (vItemSdiRuleId.value && vItemSdiRuleId.value.length > 0)
				root.sdiRuleId = vItemSdiRuleId.value
		}
	}
 
	//summary: "heating"
 
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
			id: deviceMenu
			description: qsTr("Device")
			subpage: Component {
				PageDeviceInfo {
					title: deviceMenu.description
					bindPrefix: root.bindPrefix

					MbItemValue {
						description: qsTr("Serial device installer ID")
						item.text: root.sdiRuleId
					}
				}
			}
		}
 
	}
 
}
