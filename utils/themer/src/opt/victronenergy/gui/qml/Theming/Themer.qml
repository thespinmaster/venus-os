pragma Singleton
import QtQuick 2
import ".."
import "../utils.js" as Utils

QtObject {
  
	property string bindThemerPrefix: "com.victronenergy.settings/Settings/Themer/"

	property VBusItem darkModeItem: VBusItem { bind: "com.victronenergy.settings/Settings/GuiMods/DarkMode" }
	property VBusItem themeItem: VBusItem { bind: Utils.path(bindThemerPrefix, "Theme") }
 
	property VBusItem textColorItem: VBusItem {}
	property VBusItem backgroundColorItem: VBusItem {}
  property VBusItem backgroundColorSelectedItem: VBusItem {}
	property VBusItem background2ColorItem: VBusItem {}
	property VBusItem iconSuffixNormalItem: VBusItem {}
 	property VBusItem iconSuffixSelectedItem: VBusItem {}
 	property VBusItem borderColoItem: VBusItem {}
  
	Component.onCompleted: {
		updateBindings()
	}

 	property Connections connections: Connections{
		target: themeItem
		function onValueChanged() {
			updateBindings()
		}
	}
	
  function updateBindings() {
		//console.log("themeItem:onValueChanged:" + themeItem.value)
 
		var themePath = Utils.path(bindThemerPrefix, themeItem.valid ? themeItem.value : "")
		textColorItem.bind = Utils.path(themePath, "/TextColor")
		backgroundColorItem.bind = Utils.path(themePath, "/BackgroundColor")
		backgroundColorSelectedItem.bind = Utils.path(themePath, "/BackgroundColorSelected")
		background2ColorItem.bind = Utils.path(themePath, "/BackgroundColor2")
		
		iconSuffixNormalItem.bind = Utils.path(themePath, "/IconSuffixNormal")
		iconSuffixSelectedItem.bind = Utils.path(themePath, "/IconSuffixSelected")
		borderColoItem.bind = Utils.path(themePath, "/BorderColor")

	}
	
	property string textColor: resolveColor(textColorItem, "#000000", '#FFFFFF' )
  
	property string windowBackgroundColor : resolveColor(backgroundColorItem, '#FFFFFF', '#202020')

	property string backgroundColor: resolveColor(backgroundColorItem, 'transparent', 'transparent')
	//property string backgroundColorSelected: resolveColor(backgroundColorSelectedItem, '#4790d0', "#202020")
	property string backgroundColor2: resolveColor(background2ColorItem, 'transparent', "#303030" )
	
	property string iconSuffixNormal: resolveIconSuffix(iconSuffixNormalItem, "", "-active")
	property string backgroundColorSelected: resolveColor(backgroundColorSelectedItem, '#4790d0', "#4790d0")

	property string iconSuffixSelected: resolveIconSuffix(iconSuffixSelectedItem, '-active','')
	property string borderColor: resolveColor(borderColoItem, "#ddd", "#505050")

	function resolveIconSuffix(item, defaultLight, defaultDark) {
		var useDefaults = !item?.valid
		var darkMode = false
		var iconSuffix 
 
		if (useDefaults) 	{
				var darkMode = darkModeItem.valid && darkModeItem.value == 1
 
				if (darkMode) {
					iconSuffix = defaultDark
				} else {
					iconSuffix = defaultLight
				}
		} else {
			iconSuffix = item.value
		}
		
		return iconSuffix

	}

  function resolveColor(item, defaultLight, defaultDark) {
 
		var useDefaults = !item?.valid
		var darkMode = false
		var clr
 
		if (useDefaults) {
			darkMode = darkModeItem.valid && darkModeItem.value == 1
			clr = darkMode ? defaultDark : defaultLight
		} else {
			clr = item.value
		}
 
		//console.log(item.bind)
		//console.log(   "useDefaults:" + useDefaults + ", darkMode:" + darkMode + ", valid:" + item.valid + ", value:" + item.value)
		//console.log("  clr: " + clr)
		return clr
	}

}