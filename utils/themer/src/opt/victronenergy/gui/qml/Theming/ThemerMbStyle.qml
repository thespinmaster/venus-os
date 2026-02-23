import QtQuick 2
import Theming 1.0

QtObject {
 
 	Component.onCompleted: {
    //console.log("ThemerMbStyle:Component.onCompleted")
		if (textColor) {
			textColor = Qt.binding(function() { return Themer.textColor})
		}
		if (borderColor) {
			borderColor = Qt.binding(function() { return Themer.borderColor})
		}
		
		themer = Themer
	}

}
