import QtQuick 2
import Qt.labs.components.native 1.0
import com.victron.velib 1.0


PageStackWindow {
  id: rootWindow

  property VBusItem customPages: VBusItem { bind: "com.victronenergy.settings/Settings/Themes/CustomOverviewPages" }
	
	property TmStyle mtheme: TmStyle {}

  Rectangle { anchors.fill: parent; color: mtheme.themeBackgroundColor; z: -1}
  
  Component.onCompleted: {
    addRemoveCustomPages()
  }

  function addRemoveCustomPages() {
    if (!(overviewModel && customPages.valid)) 
      return

    var items = customPages.value.split(",");
    for (var i = 0; i < items.length; i++) {
      var item = items[i].trim();

      if (!item.endsWith(".qml"))
        item += ".qml";
        
      if (item.startsWith("-")) {
        item = item.substring(1).trim();
        var idx = findModelIndex(overviewModel, item);
        if (idx !== -1)
          overviewModel.remove(idx);
        
      } else {
        var parts = item.split(":");
        if (parts.length === 0)
          continue

        var idx = -1
        var newItem = parts[parts.length-1].trim();
        if (parts.length === 2) {
          var insertBefore = parts[0].trim();
          idx = findModelIndex(overviewModel, insertBefore); 
        }
        if (idx !== -1) {
          overviewModel.insert(idx, { pageSource: newItem });
        } else {
          overviewModel.append({ pageSource: newItem });
        }
      }
    }

  }

  function findModelIndex(model, itemName) {
    if (!model) // overviewModel
      return -1;
    for (var j = 0; j < model.count; j++) {
      var modelItem = model.get(j);
      if (modelItem && modelItem.pageSource === itemName) {
        return j;
      }
    }
    return -1;
  }
}