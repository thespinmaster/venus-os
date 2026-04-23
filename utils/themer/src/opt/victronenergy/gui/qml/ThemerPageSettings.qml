import QtQuick 2
import "utils.js" as Utils

MbPage {
	title: qsTr("Themes")

  property string bindPrefix: "com.victronenergy.settings"

  model: VisibleItemModel {
    MbItemOptions {
      description: qsTr("Current Theme")
      bind:  Utils.path(bindPrefix, "/Settings/Themer/Theme")
      writeAccessLevel: User.AccessUser
      possibleValues: [
        MbOption { description: qsTr("Default"); value: "" },
        MbOption { description: qsTr("Dark"); value: "Dark" }
      ]
    }
  }

}