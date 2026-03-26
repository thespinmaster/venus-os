// ButtonGroupControl.qml
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var model: []
    property var valueMapping: []  // Array of values corresponding to each model index
    property int currentIndex: -1
    property string currentText: group.checkedButton ? group.checkedButton.text : ""
    property color textColor: "#FFFFFF"
    property color selectedColor: "#6491CC"
    property color selectedTextColor: "#FFFFFF"

    signal activated(int index, string text)

    implicitHeight: row.implicitHeight
    implicitWidth: row.implicitWidth

    function labelFor(modelData, index) {
        if (Array.isArray(root.model)) {
            return root.model[index] !== undefined ? String(root.model[index]) : ""
        }
        if (modelData && modelData.text !== undefined) {
            return String(modelData.text)
        }
        if (modelData !== undefined) {
            return String(modelData)
        }
        return ""
    }

    function setIndexFromValue(value) {
        if (!value) {
            root.currentIndex = 0
            return
        }
        var strValue = String(value)
        var index = root.valueMapping.indexOf(strValue)
        if (index >= 0) {
            root.currentIndex = index
            if (index < row.children.length) {
                row.children[index].checked = true
            }
        }
    }

    function getValueAtIndex(index) {
        if (index >= 0 && index < root.valueMapping.length) {
            return root.valueMapping[index]
        }
        return ""
    }

    ButtonGroup {
        id: group
        exclusive: true
    }

    Row {
        id: row
        spacing: 0

        Repeater {
            model: root.model

            delegate: Button {
                required property int index
                property bool isFirst: index === 0
                property bool isLast: index === root.model.length - 1
                property bool isOnly: isFirst && isLast

                text: root.labelFor(modelData, index)
                checkable: true
                ButtonGroup.group: group

                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 12
                    color: checked ? root.selectedTextColor : root.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onCheckedChanged: {
                    if (checked) {
                        root.currentIndex = index
                        root.activated(index, text)
                    }
                    bgCanvas.requestPaint()
                }

                background: Item {
                    implicitWidth: 1
                    implicitHeight: 1
                    Canvas {
                        id: bgCanvas
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var lineWidth = 1.5;
                            var offset = lineWidth / 2;
                            var w = width - lineWidth;
                            var h = height - lineWidth;
                            var r = (isOnly || isFirst || isLast) ? h / 2 : 0;
                            var rl = (isOnly || isFirst) ? r : 0;
                            var rr = (isOnly || isLast) ? r : 0;
                            
                            // Fill
                            ctx.beginPath();
                            ctx.moveTo(rl + offset, offset);
                            ctx.lineTo(w - rr + offset, offset);
                            if (rr > 0) ctx.quadraticCurveTo(w + offset, offset, w + offset, rr + offset); else ctx.lineTo(w + offset, offset);
                            ctx.lineTo(w + offset, h - rr + offset);
                            if (rr > 0) ctx.quadraticCurveTo(w + offset, h + offset, w - rr + offset, h + offset); else ctx.lineTo(w + offset, h + offset);
                            ctx.lineTo(rl + offset, h + offset);
                            if (rl > 0) ctx.quadraticCurveTo(offset, h + offset, offset, h - rl + offset); else ctx.lineTo(offset- lineWidth, h + offset);
                            ctx.lineTo(offset - lineWidth, rl + offset);//G
                            if (rl > 0) ctx.quadraticCurveTo(offset, offset, rl + offset, offset); else ctx.lineTo(offset, offset);
                            ctx.closePath();
                            ctx.fillStyle = checked ? root.selectedColor : "transparent";
                            if (checked) ctx.fill();
                            
                            // Stroke only specific sides to avoid double borders
                            ctx.lineWidth = lineWidth;
                            ctx.strokeStyle = root.selectedColor;
                            
                            // Top border
                            ctx.beginPath();
                            ctx.moveTo(rl + offset-lineWidth, offset);
                            ctx.lineTo(w - rr + offset+lineWidth, offset);
                            if (rr > 0) ctx.quadraticCurveTo(w + offset, offset, w + offset, rr + offset);
                            ctx.stroke();
                            
                            // Bottom border
                            ctx.beginPath();
                            if (rr > 0) ctx.moveTo(w + offset, h - rr + offset); else ctx.moveTo(w + offset+lineWidth, h + offset);
                            if (rr > 0) ctx.quadraticCurveTo(w + offset, h + offset, w - rr + offset, h + offset); else ctx.lineTo(w - rr + offset, h + offset);
                            ctx.lineTo(rl + offset-lineWidth, h + offset);
                            if (rl > 0) ctx.quadraticCurveTo(offset, h + offset, offset, h - rl + offset);
                            ctx.stroke();
                            
                            // Left border (only for first button)
                            if (isFirst || isOnly) {
                                ctx.beginPath();
                                ctx.moveTo(offset, rl + offset);
                                if (rl > 0) ctx.quadraticCurveTo(offset, offset, rl + offset, offset);
                                ctx.stroke();
                            }
                            
                            // Right border (only for last button)
                            if (isLast || isOnly) {
                                ctx.beginPath();
                                ctx.moveTo(w + offset, rr + offset);
                                ctx.lineTo(w + offset, h - rr + offset);
                                ctx.stroke();
                            } else {
                                // Half-width right border for middle/non-last buttons
                                ctx.beginPath();
                                ctx.moveTo(w + offset, offset + lineWidth / 2);
                                ctx.lineTo(w + offset, h + offset - lineWidth / 2);
                                ctx.stroke();
                            }
                        }
                    }
                }

                onIsFirstChanged: bgCanvas.requestPaint()
                onIsLastChanged: bgCanvas.requestPaint()
                onIsOnlyChanged: bgCanvas.requestPaint()

                topPadding: 8
                bottomPadding: 8
                leftPadding: 10
                rightPadding: 10
            }
        }
    }
}
