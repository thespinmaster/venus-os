import QtQuick 2
import Victron.VenusOS
import "qrc:/OpkgManager/OpkgSingleton.js" as OpkgSingleton

Page {
	id: page
	//% "Inetbox settings"
	title: qsTr("inetbox_settings")

	GradientListView {
		id: settingsListView

		model: VisibleItemModel {

			ListSwitch {
				dataItem.uid:!!Global.systemSettings ? Global.systemSettings.serviceUid + "/Settings/Inetbox/ShowMotorhomePage" : ""
				//% "Show Motorhome Page"
				text:  qsTr("inetbox_show_motorhome_page")
			}

			ListText {
				//% "Version"
				text: qsTrId("inetbox_version")
				secondaryText: GuiPluginLoader.plugin("Inetbox").version
			}

			ListLink {
				id: documentation

				//% "Documentation"
				text: qsTrId("pagecontrollableloads_documentation")
				url: "https://thespinmaster.github.io/venus-os-addons/"
			}
		}
	}


}
