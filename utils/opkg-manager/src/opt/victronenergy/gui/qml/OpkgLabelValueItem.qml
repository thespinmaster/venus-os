		import QtQuick 2
    
    
    Item {
			id: root
			
			implicitWidth: textItem.width + mbBlock.width + mbStyle.marginDefault
			implicitHeight: Math.max(textItem.height, mbBlock.height)
			property alias label: textItem.text
			property alias value: valueItem.text
			property MbStyle mbStyle: MbStyle {}
			property int fontSize: mbStyle.fontPixelSize

			MbTextValue {
				id: textItem
				text: root.label ?? ""
				font.pixelSize: root.fontSize
				anchors {
					left: parent.left
					verticalCenter: parent.verticalCenter
				}
			}

			MbBlock { 
				id: mbBlock
				height: mbStyle.fontPixelSize + mbStyle.marginItemVertical * 2
				anchors {
					left: textItem.right
					leftMargin: mbStyle.marginDefault		
					verticalCenter: parent.verticalCenter
				}
				MbTextValue { 
					id: valueItem; 
					text: root.value ?? ""
					font.pixelSize: root.fontSize
				}
			}

		}