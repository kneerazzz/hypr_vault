import QtQuick

Item {
    id: fieldRoot
    property string label: ""
    property string value: ""
    property bool copyable: false
    property bool dimmed: false

    height: 70

    Column {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 8

        Text {
            text: fieldRoot.label
            color: "#6b6b6b"
            font.pixelSize: 12
            font.family: "monospace"
            font.letterSpacing: 3
        }

        Rectangle {
            width: parent.width
            height: 42
            radius: 6
            color: "#111111"
            border.color: "#1f1f1f"
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: fieldRoot.value
                    color: fieldRoot.dimmed ? "#555555" : "#e5e5e5"
                    font.pixelSize: 15
                    font.family: "monospace"
                    font.italic: fieldRoot.dimmed
                    elide: Text.ElideRight
                    width: parent.width - (fieldRoot.copyable ? 44 : 10)
                }

                Rectangle {
                    visible: fieldRoot.copyable
                    width: 30
                    height: 26
                    radius: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: copyArea.containsMouse ? "#1f1f1f" : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    Text {
                        id: copyIcon
                        anchors.centerIn: parent
                        text: "⎘"
                        color: "#7a7a7a"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: copyArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            textCopier.text = fieldRoot.value
                            textCopier.selectAll()
                            textCopier.copy()

                            copyIcon.text = "✓"
                            copyIcon.color = "#4ade80"

                            resetTimer.restart()
                            
                            // Start the 15-second destruction countdown
                            clipboardClearTimer.restart()
                        }
                    }

                    // Reverts the icon back from the green checkmark
                    Timer {
                        id: resetTimer
                        interval: 1500
                        onTriggered: {
                            copyIcon.text = "⎘"
                            copyIcon.color = "#7a7a7a"
                        }
                    }
                }
            }
        }
    }

    TextEdit {
        id: textCopier
        visible: false
        text: ""
    }

    // Auto-clear clipboard after 15 seconds
    Timer {
        id: clipboardClearTimer
        interval: 15000 
        onTriggered: {
            textCopier.text = ""
            textCopier.selectAll()
            textCopier.copy()
        }
    }
}