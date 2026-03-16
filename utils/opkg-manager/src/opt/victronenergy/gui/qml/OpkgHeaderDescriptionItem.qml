import QtQuick 2
import com.victron.velib 1.0

MbItem {
	id: root
	width: (pageStack && pageStack.currentPage && pageStack.currentPage.width)
    || (pageStack && pageStack.currentItem && pageStack.currentItem.width)
    || 0
    
    defaultHeight: Math.max(mbStyle.itemHeight, columnRoot.implicitHeight + mbStyle.marginDefault * 2)
    //subpage: model && model.subpage ? model.subpage : undefined
 
	property string description
    property string header
    property bool showCompact: false
    property int descriptionWrapMode: Text.WordWrap
	property VBusItem item: VBusItem {}
	property string iconId: "icon-toolbar-enter"
    property int spacing : 0

    Column {
        id: columnRoot
        width: parent ? parent.width : undefined
        height: implicitHeight
        spacing: spacing
        property bool isCurrentItem: root.ListView.isCurrentItem
        anchors {
            top: parent.top; topMargin: mbStyle.marginDefault
            bottom: parent.bottom; bottomMargin: mbStyle.marginDefault
        }
 
        MbTextDescription {
            id: header 
            text: root.header || ""
            isCurrentItem: root.ListView.isCurrentItem
            visible: root.header || !root.showCompact
            //font.bold: !root.showCompact
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: mbStyle.marginDefault
        }

        MbTextDescription {
            id: description
            visible: !root.header || !(root.showCompact)
            text: root.description ? root.description : ""
            isCurrentItem: root.ListView.isCurrentItem
            wrapMode: root.descriptionWrapMode
            font.pixelSize: root.header ? 12 : mbStyle.fontPixelSize
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: mbStyle.marginDefault
        }
    }
 
	MbIcon {
		id: icon

		display: hasSubpage
		anchors {
			right: root.right; rightMargin: mbStyle.marginDefault
			verticalCenter: parent.verticalCenter
		}
		iconId: root.iconId ? root.iconId + (root.ListView.isCurrentItem ? "-active" : "") : ""
	}
}
