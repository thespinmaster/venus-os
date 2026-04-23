import QtQuick 2
import com.victron.velib 1.0

MbPage {
	id: root
	title: qsTr("Ne-shunt Settings")

  model: VisibleItemModel {
    MbSwitch {
      bind: "com.victronenergy.settings/Settings/OpkgManager/CustomMenus/PageMain/PageSettings"
      name: qsTr("Show Overview Page")
      valueFalse: "-"
      valueTrue: ""
    }
 
  }
}

