import QtQuick 2
import "utils.js" as Utils
import com.victron.velib 1.0

MbSubMenu {
	description: qsTr("Serial Device")
	visible: false

	property var root

	VBusItem {
		id: temp
		bind: Utils.path(root.bindPrefix, "/Temperature")
		displayUnit: user.temperatureUnit
	}

	Component.onCompleted: {
		root.summary = Qt.binding(function() { return temp.format()})
	}
}
