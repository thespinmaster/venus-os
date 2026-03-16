import QtQuick 2
import Theming 1.0

QtObject {
 
 	Component.onCompleted: {
 
		if (textColor) {
			textColor = Qt.binding(function() { return Themer.textColor})
		}
		if (borderColor) {
			borderColor = Qt.binding(function() { return Themer.borderColor})
		}
		if (backgroundColor) {
			backgroundColor = Qt.binding(function() { return isCurrentItem ? Themer.backgroundColorSelected : Themer.backgroundColor })
		}
		themer = Themer
	}
 
}
