import QtQuick 2.0
import com.victron.velib 1.0

MbItem {
    id: packageItem
    property string iconId: ""
    property string name: ""
    property string description: ""
    property string version: ""
    property string feed: ""
    property string installedVersion: ""
    property int index: -1
    property int detailsFontPixelSize: 14
    property bool showCompact: false
    property int subpageIconReserveWidth: 24
    property bool hasSubpage: false
    editable: true
    defaultHeight: Math.max(mbStyle.itemHeight, contentColumn.implicitHeight + mbStyle.marginDefault * 2)

    onIsCurrentItemChanged: {
        if (ListView.isCurrentItem && index >= 0) {
            // Optionally handle selection
        }
    }

    Column {
        id: contentColumn
        anchors {
            left: parent.left; leftMargin: mbStyle.marginDefault
            right: parent.right
            rightMargin: mbStyle.marginDefault + packageItem.subpageIconReserveWidth
            top: parent.top; topMargin: mbStyle.marginDefault
        }
        spacing: 2

        Row {
            spacing: mbStyle.marginDefault
            width: parent.width

            Text {
                text: packageItem.name
                color: packageItem.itemTextColor
                font.bold: !packageItem.showCompact
                elide: Text.ElideRight
                width: parent.width - nameIcon.implicitWidth - parent.spacing
            }

            MbIcon {
                id: nameIcon
                iconId: packageItem.iconId + (packageItem.ListView.isCurrentItem ? "-active" : "")   
                display: packageItem.installedVersion.length > 0 && packageItem.iconId.length > 0
                z: 1
            }
        }

        Text {
            text: packageItem.description
            color: packageItem.itemTextColor
            font.pixelSize: packageItem.detailsFontPixelSize
            wrapMode: Text.Wrap
            width: parent.width
            visible: !packageItem.showCompact
            // Removed height binding to avoid binding loop
        }

        Row {
            spacing: mbStyle.marginDefault
            visible: !packageItem.showCompact
            // Removed height binding to avoid binding loop

            Text {
                text: qsTr("Installed: ") + (packageItem.installedVersion.length > 0 ? packageItem.installedVersion : qsTr(" - "))
                color: packageItem.itemTextColor
                font.pixelSize: packageItem.detailsFontPixelSize
            }

            // Only show Available version if showAvailable is true (set by parent)
            Text {
                visible: typeof packageItem.showAvailable === "undefined" ? true : packageItem.showAvailable
                text: qsTr("Available: ") + packageItem.version
                color: packageItem.itemTextColor
                font.pixelSize: packageItem.detailsFontPixelSize
            }

            Text {
                text: qsTr("Feed: ") + packageItem.feed
                color: packageItem.itemTextColor
                font.pixelSize: packageItem.detailsFontPixelSize
            }
        }
    }

    MbIcon {
        display: packageItem.hasSubpage
        anchors {
            right: parent.right; rightMargin: mbStyle.marginDefault
            verticalCenter: parent.verticalCenter
        }
        iconId: "icon-toolbar-enter" + (packageItem.ListView.isCurrentItem ? "-active" : "")   
    }
}
