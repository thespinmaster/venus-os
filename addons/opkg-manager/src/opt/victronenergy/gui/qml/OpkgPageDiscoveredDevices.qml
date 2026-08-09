import QtQuick 2
import com.victron.velib 1.0

MbPage {
	id: root

	required property OpkgManager opkgManager

	model: OpkgSafeDelegateModel {

		model: VeQItemSortTableModel {
			model: VeQItemTableModel {
				uids: ["dbus/com.victronenergy.opkgmanager/Discovered"]
				flags: VeQItemTableModel.AddChildren |
						VeQItemTableModel.AddNonLeaves |
						VeQItemTableModel.DontAddItem
			}
			filterRegExp: "\/sid_[^/]+$"
			filterFlags: VeQItemSortTableModel.FilterInvalid
		}

		delegate: MbSubMenu {
			id: discoveredDevice
			description: deviceProps.port

			property var deviceProps: discoveredDevice.model.item.value
										? JSON.parse(discoveredDevice.model.item.value) : ""
			property bool deviceAdded: false

			function onDeviceAddedCallback(added) {
				if (added !== undefined)
					deviceAdded = added
				return deviceAdded
			}

			subpage: Component {
					OpkgPageDiscoveredDevice {
						opkgManager: root.opkgManager
						deviceProps: discoveredDevice.deviceProps
						deviceAddedCallback: discoveredDevice.onDeviceAddedCallback}
				}
			}

	}
}