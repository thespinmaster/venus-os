import QtQuick 2.0
import com.victron.velib 1.0

MbItem {
    id: packageItem
    property string header: ""
    property string description: ""
    property int detailsFontPixelSize: 14
    property bool showCompact: false
    property color itemTextColor: ListView.isCurrentItem ? mbStyle.textColorSelected : mbStyle.textColor
    
    editable: true
    defaultHeight: Math.max(mbStyle.itemHeight, contentColumn.implicitHeight + mbStyle.marginDefault * 2)
 
    Column {
        id: contentColumn
        anchors {
            left: parent.left; leftMargin: mbStyle.marginDefault
            right: parent.right
            rightMargin: mbStyle.marginDefault //+ packageItem.subpageIconReserveWidth
            top: parent.top; topMargin: mbStyle.marginDefault
        }
        spacing: 2

        Text {
            text: packageItem.header
            color: packageItem.itemTextColor
            font.bold: !packageItem.showCompact
            elide: Text.ElideRight

        }

        Text {
            text: packageItem.description
            color: packageItem.itemTextColor
            font.pixelSize: packageItem.detailsFontPixelSize
            wrapMode: Text.Wrap
            width: parent.width
            visible: !packageItem.showCompact
        }
 
    }
 
}
