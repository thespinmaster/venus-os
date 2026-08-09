import QtQuick
import Victron.VenusOS

/*
	Provides a list of settings for custom device.
*/
DevicePage {
	id: root
	property string bindPrefix
	serviceUid: bindPrefix
}
