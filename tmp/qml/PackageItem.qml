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
    property color itemTextColor: ListView.isCurrentItem ? mbStyle.textColorSelected : mbStyle.textColor
    property int index: -1
    property int detailsFontPixelSize: 14
    property bool showCompact: false
    property int subpageIconReserveWidth: 24
    property bool hasSubpage: false
    editable: false
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
                iconId: packageItem.iconId
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
            height: visible ? implicitHeight : 0
        }

        Row {
            spacing: mbStyle.marginDefault
            visible: !packageItem.showCompact
            height: visible ? implicitHeight : 0

            Text {
                text: qsTr("Installed: ") + (packageItem.installedVersion.length > 0 ? packageItem.installedVersion : qsTr("Not installed"))
                color: packageItem.itemTextColor
                font.pixelSize: packageItem.detailsFontPixelSize
            }

            Text {
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
        iconId: "icon-toolbar-enter" + (ListView.isCurrentItem ? "-active" : "")
    }
}
