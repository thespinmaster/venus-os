import QtQuick 2
import com.victron.velib 1.0

OpkgPageDeviceDetails {
	id: root

	property string summary: root.connected ? "Ok" : "Not Connected"

}
