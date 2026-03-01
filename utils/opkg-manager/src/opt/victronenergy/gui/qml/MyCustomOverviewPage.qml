import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils
import QtQuick.Controls
import "opkg-utils.js" as OpkgUtils

 OverviewPage {
			id: root
	
	Rectangle {
			id: rectangle
			anchors.fill: parent
			color: "#00ff00"
	}

	Component.onCompleted: {
		console.log("hello world")
	}
}
 