import QtQuick 2
import Theming 1.0

QtObject {
 
	Component.onCompleted: {
		if (icon && icon.iconId) {
			icon.iconId = Qt.binding(function() { 
        !root.ListView.isCurrentItem && Themer.iconSuffixNormal 
          ? icon.opacity = 0.25 
          : icon.opacity = 1
        return root.iconId 
              ? root.iconId + (root.ListView.isCurrentItem 
                ? Themer.iconSuffixSelected 
                : Themer.iconSuffixNormal) 
              : ""
			})
		}
	}
}
