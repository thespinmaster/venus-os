import QtQuick 2
import Victron.VenusOS
// import "qrc:/OpkgManager/components"
import "qrc:/OpkgManager/components/OpkgSingleton.js" as OpkgSingleton

Page {
	id: page
	//% "Inetbox settings"
	title: qsTrId("inetbox_settings")

	property var customPagesArray: customPagesItem.valid ? JSON.parse(customPagesItem.value): []
	property bool loaded

	VeQuickItem {
		id: customPagesItem
		uid: !!Global.systemSettings ? Global.systemSettings.serviceUid + "/Settings/OpkgManager/CustomPages" : ""
	}

	GradientListView {
		id: settingsListView

		model: VisibleItemModel {

			ListSwitch {
				dataItem.uid:!!Global.systemSettings ? Global.systemSettings.serviceUid + "/Settings/Inetbox/ShowMotorhomePage" : ""
				//% "Show Motorhome Page"
				text: qsTrId("inetbox_show_motorhome_page")
				writeAccessLevel: VenusOS.User_AccessType_User
				onCheckedChanged: {
							OpkgSingleton.toggleCustomPage("qrc:/Inetbox/MotorhomePage.qml", checked)
					}
				}

			ListText {
				text: qsTrId("opkg_version")
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
