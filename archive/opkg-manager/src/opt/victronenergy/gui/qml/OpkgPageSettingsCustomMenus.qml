import QtQuick 2
import "opkg-utils.js" as OpkgUtils

QtObject {
	 
	property Connections connections: Connections{
		target: root
		function on_SubpageInstanceChanged() { _onSubpageInstanceChanged()}
	}
 
 	readonly property string baseDbusCustomMenusPath: "dbus/com.victronenergy.settings/Settings/OpkgManager/CustomMenus/"

	property VeQuickItem customItems: VeQuickItem {
		onValueChanged: _addItems()
	}	

  function _addItems() {

    if (customItems.value === undefined)
      return

    OpkgUtils.addRemoveCustomItemsQuick(customItems, _subpageInstance.model , undefined, undefined, _getComponentArgs);
 
    customItems.uid = null
  }

  function _getComponentArgs() {
    // rootWindow.pageStack 3.66
    // pageStack 3.71
    //console.log("PPP:" + Object.keys(_subpageInstance))
    //console.log("yyy:" + _subpageInstance.listview.contentItem + ", " + _subpageInstance.listview.children[0])
    var pStack = rootWindow.pageStack ?? pageStack //3.71 fix
		return {parent: _subpageInstance.listview.contentItem, args: { pageStack: pStack, mbTools: mbTools, toast: toast}}
  }

  function _onSubpageInstanceChanged()
  {
    if (_subpageInstance == null)
      return
 
    var pageName = _subpageInstance.toString()
    pageName = pageName.split("_")[0]
		if (pageName)
    	customItems.uid = baseDbusCustomMenusPath + pageName
		//console.log("customItems.uid:" + customItems.uid)
  }
 
}
 