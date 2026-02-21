import QtQuick 2


/*
 * common style properties
 */
QtObject {
 
	property VBusItem darkModeItem: VBusItem { bind: "com.victronenergy.settings/Settings/GuiMods/DarkMode" }
	
	property VBusItem themeTextColorItem: VBusItem { bind: "com.victronenergy.settings/Settings/Themes/Text" }
	property VBusItem themeBackgroundColorItem: VBusItem { bind: "com.victronenergy.settings/Settings/Themes/BackgroundColor" }
	property VBusItem themeBackground2ColorItem: VBusItem { bind: "com.victronenergy.settings/Settings/Themes/BackgroundColor2" }

	property string themeTextColor: resolveColor(themeTextColorItem, "#FFFFFF", "#000000")
 
  property string themeBackgroundColor: resolveColor(themeBackgroundColorItem, "transparent", "#202020")
	property string themeBackgroundColor2: resolveColor(themeBackground2ColorItem, "#FFFFFF", "#ff0000")
	
  function resolveColor(item, defaultLight, defaultDark) {
		return item.valid ? item.value : 
				(darkModeItem.valid && darkModeItem.value == 1 ? defaultLight : defaultDark ) 
	}
	 
}
