import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
	id:root

    background: Rectangle {
        color: "grey"
    }
    anchors.fill: parent

    RowLayout {
        id: mainRow
        spacing: 1
        anchors {
            left: parent.left
            right: parent.right
        }

        RoomTempsColumnLayout {}
        TankLevelsColumnLayout {model: tankModel; Layout.preferredWidth:200}

        InputLoadsColumnLayout {}
        BatteryInfoColumnLayout {}
        OutputLoadsColumnLayout {}

    }

    component RoomTempsColumnLayout: ColumnLayout {
        spacing: 1
        Rectangle {
            color: "red"
            width: 100
            height: 100
        }
        Rectangle {
            color: "green"
            width: 40
            height: 40
        }
    }

    property var tankModel: [
			  {color:"green", name:"Battery",tankType:2, icon: dummySvg, level: 0.5},
        {color:"green", name:"Gas",tankType:1, icon: dummySvg, level: 0.5},
        {color:"green",name:"Frest water",tankType:1, icon:dummySvg,  level: 0.8},
        {color:"green",name:"Grey Waste",tankType:1, icon: dummySvg, level: 0.2},
    ]

	component TankLevelsColumnLayout: ColumnLayout {
		id: tanks

		property alias model: repeater.model
		property real levelThickness: 6
		spacing: 1

		// Helper to measure text dimensions off-screen
		TextMetrics {
			id: labelMetrics
		}

		// Dynamically computes the width of the longest name in the model
		readonly property real maxLabelWidth: {
			var maxW = 0;
			if (model) {
				for (var i = 0; i < model.length; i++) {
					if (model[i].tankType === 2) continue
					labelMetrics.text = model[i].name;
					maxW = Math.max(maxW, labelMetrics.width);
				}
			}
			return maxW;
		}

		Repeater {
			id: repeater

			Loader {
				id: tankLoader

				// 1. Only instantiate the component if it's not a battery
				active: true;// .tankType !== 2 //VenusOS.Tank_Type_Battery
				// 2. Hide the Loader so ColumnLayout completely ignores it (no extra spacing)
				visible: active

				// 3. Attach layout properties to the Loader (the direct child of the Layout)
				//Layout.fillWidth: true
				Layout.fillHeight: true

				sourceComponent: Row {
			id: row
			Layout.fillHeight: true
			spacing: 6

			//property int gaugeStatus: Theme.getValueStatus(model.level, model.valueType)
			property color valueColor: "steelblue" // Theme.statusColorValue(row.gaugeStatus)
			property color levelColor: "lightblue" //Theme.statusColorValue(row.gaugeStatus, true)

			// 1. [name] Right-aligned, sized dynamically to the longest string
			Label {
				id: lbl
				text: modelData.name
				horizontalAlignment: Text.AlignRight
				anchors.verticalCenter: parent.verticalCenter
				width: maxLabelWidth
			}

			// 2. [Icon]
			Image {
				id: img
				source: modelData.icon
				anchors.verticalCenter: parent.verticalCenter
				fillMode: Image.PreserveAspectFit
			}

			// Background fill
			Rectangle {
				id: levelBack
				anchors.verticalCenter: parent.verticalCenter

				width: tanks.Layout.preferredWidth - (lbl.width + img.width + row.spacing)
				height: 22//levelThickness
				color: row.levelColor
				radius: height / 2
				Rectangle {

					anchors.left: parent.left
					height: parent.height
					width: levelBack.width * Math.max(0, Math.min(1, modelData.level))
					color: row.valueColor
					radius: height / 2
				}
			}
		}

			}

		}
	}


    property string info

    Label {
        anchors {top:mainRow.bottom}
        text:"info:" + info
    }
    component InputLoadsColumnLayout: ColumnLayout {
        id: inputLoad
        width: 100

        spacing: 1

        Repeater {
            model: ["red", "white", "blue"]

            Rectangle {
                color: modelData
                width: parent.width
                Layout.fillHeight: true
            }
        }
    }

    component BatteryInfoColumnLayout: ColumnLayout {
        Rectangle {
            id: battery
            border.color: "yellow"
            color: "steelblue"
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    component OutputLoadsColumnLayout: ColumnLayout {
        id: outputLoad
        width: 100

        spacing: 1

        Repeater {
            model: ["red", "white", "blue"]

            Rectangle {
                color: modelData
                width: parent.width
                Layout.fillHeight: true
            }
        }
    }

    component Label: Text {color: "white"}
    property string dummySvg: "data:image/svg+xml;utf8," + "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'>" + "<circle cx='12' cy='12' r='11' fill='#3498db' stroke='#FF0000' stroke-width='2'/>" + "</svg>"
}
