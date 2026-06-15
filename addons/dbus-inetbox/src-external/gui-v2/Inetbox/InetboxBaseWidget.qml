import QtQuick
import Victron.VenusOS

Rectangle {
  id: root

  property bool isLoading: false
  property string headerText: ""
  property string headerIconSource: ""
  property string headerValueText: ""
  property Device device: null
  readonly property real contentSpacing: 12
  readonly property bool hasBodyContent: contentContainer.implicitHeight > 0
  property alias headerExtraContent: headerExtraContainer.data
  property int portraitBottomMargin: Theme.geometry_overviewPage_widget_content_bottomMargin_small
  property int landscapeBottomMargin: Theme.geometry_overviewPage_widget_content_bottomMargin_large
  property int bottomMargin: Theme.screenSize === Theme.Portrait
                        ? root.portraitBottomMargin
                        : root.landscapeBottomMargin

  default property alias contentData: contentContainer.data
  
  color: Theme.color_overviewPage_widget_background
  radius: 24
  implicitHeight: Theme.geometry_overviewPage_widget_content_topMargin
                  + headerRow.implicitHeight
                  + (root.hasBodyContent ? root.contentSpacing : 0)
                  + bottomMargin
                  + contentContainer.implicitHeight

  Item {
    id: contentArea
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
      bottom: parent.bottom
      topMargin: Theme.geometry_overviewPage_widget_content_topMargin
      leftMargin: Theme.geometry_overviewPage_widget_content_horizontalMargin
      rightMargin: Theme.geometry_overviewPage_widget_content_horizontalMargin
      bottomMargin: root.bottomMargin
    }

    Item {
      id: headerRow
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        rightMargin: Theme.geometry_overviewPage_widget_content_horizontalMargin
      }
      implicitHeight: Math.max(headerWidget.implicitHeight, headerValueLabel.implicitHeight, headerExtraContainer.implicitHeight)

      WidgetHeader {
        id: headerWidget
        text: root.headerText
        icon.source: root.headerIconSource
        anchors {
          left: parent.left
          verticalCenter: parent.verticalCenter
        }
      }

      Item {
        id: headerExtraContainer
        visible: !root.isLoading
        anchors {
          left: headerWidget.right
          leftMargin: root.contentSpacing
          right: headerValueLabel.visible ? headerValueLabel.left : parent.right
          rightMargin: headerValueLabel.visible ? root.contentSpacing : 0
          verticalCenter: parent.verticalCenter
        }
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
      }

      Label {
        id: headerValueLabel
        visible: !root.isLoading && root.headerValueText.trim().length > 0
        text: root.headerValueText
        font.pixelSize: Theme.font_listItem_primary_size
        anchors {
          right: parent.right
          verticalCenter: parent.verticalCenter
        }
      }
    }

    Item {
      id: loadingContainer
      visible: root.isLoading
      anchors {
        top: headerRow.bottom
        topMargin: root.hasBodyContent ? root.contentSpacing : 0
        left: parent.left
        right: parent.right
        bottom: parent.bottom
      }

      Label {
        id: loadingLabel
        //% "Waiting for data..."
        text: qsTrId("inetbox_label_waiting_for_data")
        anchors.centerIn: parent
      }
    }

    Column {
      id: contentContainer
      visible: !root.isLoading
      anchors {
        top: headerRow.bottom
        topMargin: root.contentSpacing
        left: parent.left
        right: parent.right
        bottom: parent.bottom
        
      }
      spacing: root.contentSpacing
    }
  }
}
