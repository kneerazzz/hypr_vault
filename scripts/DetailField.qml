import QtQuick

Item {
    id: fieldRoot

    property string label:    ""
    property string value:    ""
    property bool   copyable: false
    property bool   dimmed:   false

    height: 56

    Column {
        anchors.fill: parent
        spacing: 5

        Text {
            text: fieldRoot.label
            color: "#252525"
            font.pixelSize: 9
            font.family: "monospace"
            font.letterSpacing: 2
        }

        Rectangle {
            width: parent.width
            height: 38
            radius: 5
            color: "#0c0c0c"
            border.color: "#141414"
            border.width: 1

            Row {
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 8
                }
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: fieldRoot.value
                    color: fieldRoot.dimmed ? "#2e2e2e" : "#aaaaaa"
                    font.pixelSize: 12
                    font.family: "monospace"
                    font.italic: fieldRoot.dimmed
                    elide: Text.ElideRight
                    width: parent.width - (fieldRoot.copyable ? 40 : 8)
                }

                Rectangle {
                    visible: fieldRoot.copyable
                    width: 28; height: 24; radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: copyArea.containsMouse ? "#1a1a1a" : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        id: copyIcon
                        anchors.centerIn: parent
                        text: "⎘"; color: "#333333"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: copyArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Use Qt's clipboard — works in all Quickshell versions
                            textCopier.text  = fieldRoot.value
                            textCopier.selectAll()
                            textCopier.copy()
                            copyIcon.text  = "✓"
                            copyIcon.color = "#4ade80"
                            resetTimer.restart()
                        }
                    }

                    Timer {
                        id: resetTimer
                        interval: 1500
                        onTriggered: { copyIcon.text = "⎘"; copyIcon.color = "#333333" }
                    }
                }
            }
        }
    }

    // Hidden TextEdit used as clipboard bridge — selectAll + copy() is
    // guaranteed to work regardless of Quickshell Clipboard API version
    TextEdit {
        id: textCopier
        visible: false
        text: ""
    }
}
