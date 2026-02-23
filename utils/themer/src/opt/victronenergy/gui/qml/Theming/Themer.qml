pragma Singleton
import QtQuick 2
import ".."
import Theming 1.0
 
QtObject {

	property VBusItem darkModeItem: VBusItem { bind: "com.victronenergy.settings/Settings/GuiMods/DarkMode" }
	
	property VBusItem textColorItem: VBusItem { bind: "com.victronenergy.settings/Settings/Themes/Text" }
	property VBusItem backgroundColorItem: VBusItem { bind: "com.victronenergy.settings/Settings/Themes/BackgroundColor" }
	property VBusItem background2ColorItem: VBusItem { bind: "com.victronenergy.settings/Settings/Themes/BackgroundColor2" }
	property VBusItem iconSuffixNormalItem: VBusItem { bind: "com.victronenergy.settings/Settings/Themes/IconSuffixNormal" }
 	property VBusItem iconSuffixSelectedItem: VBusItem { bind: "com.victronenergy.settings/Settings/Themes/IconSuffixSelected" }
 	property VBusItem borderColoItem: VBusItem { bind: "com.victronenergy.settings/Settings/Themes/BorderColor" }
 
	property string textColor: resolveColor(textColorItem, "#FFFFFF", "#000000")
 
  property string backgroundColor: resolveColor(backgroundColorItem, "transparent", "#202020")
	property string backgroundColor2: resolveColor(background2ColorItem, "#FFFFFF", "#ff0000")
	
	property string iconSuffixNormal: iconSuffixNormalItem.valid ? (iconSuffixNormalItem.value.length > 0 ? "-" + iconSuffixNormalItem.value : "") : ""
	property string iconSuffixSelected: iconSuffixSelectedItem.valid ? (iconSuffixSelectedItem.value.length > 0 ? "-" + iconSuffixSelectedItem.value : "") : "-active"
	property string borderColor: resolveColor(borderColoItem, "#ddd", "#2B2B2B")

 
  function resolveColor(item, defaultLight, defaultDark) {
		return item.valid ? item.value : 
				(darkModeItem.valid && darkModeItem.value == 1 ? defaultLight : defaultDark ) 
	}

}