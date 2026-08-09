import QtQuick 2
import Victron.VenusOS
import "qrc:/OpkgManager/OpkgSingleton.js" as OpkgSingleton

Page {
	id: page
	title: qsTr("Open Package Manager")

	GradientListView {
		id: settingsListView

		model: VisibleItemModel {

			ListSwitch {
				dataItem.uid:!!Global.systemSettings ? Global.systemSettings.serviceUid + "/Settings/Inetbox/ShowMotorhomePage" : ""
				text: "Show Motorhome Page"
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
