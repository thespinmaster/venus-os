pragma Singleton
import QtQuick 2
import com.victron.velib 1.0

QtObject {

	readonly property VeQItemSortTableModel deviceList: VeQItemSortTableModel {
		model: VeQItemTableModel {
			uids: ["dbus/com.victronenergy.settings/Settings/Devices"]
			flags: VeQItemTableModel.AddChildren |
					VeQItemTableModel.AddNonLeaves |
					VeQItemTableModel.DontAddItem
		}
		dynamicSortFilter: true
		filterRegExp: "^dbus\/com\.victronenergy\.settings\/Settings\/Devices\/sid_[^/]+$"
		filterFlags: VeQItemSortTableModel.FilterOffline
	}

	// readonly property VeQItemSortTableModel deviceList: VeQItemSortTableModel {

	// 	dynamicSortFilter: true
	// 	filterFlags: VeQItemSortTableModel.FilterOffline
	// 	filterRole: VeQItemTableModel.IdRole
	// 	filterRegExp: "^com\.victronenergy\..*\.sid_.*"

	// 	model: VeQItemTableModel {
	// 		uids: ["dbus"]
	// 		flags: VeQItemTableModel.AddChildren |
	// 					VeQItemTableModel.AddNonLeaves |
	// 					VeQItemTableModel.DontAddItem
	// 	}

	// }

	// function sidFromUID(uid) {
	// 	var indexOfSid= uid.lastIndexOf('.sid_')
	// 	if (indexOfSid == -1)
	// 		return ""
	// 	indexOfSid += 5

	// 	var idx = uid.indexOf("_", indexOfSid) // +4 for sid_
	// 	console.log(idx)
	// 	idx = idx === -1 ? uid.length : idx
	// 	return uid.substring(indexOfSid,idx)
	// }


}