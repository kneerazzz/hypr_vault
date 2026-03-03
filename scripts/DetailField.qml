import QtQuick
import Quickshell

Item {
    id: fieldRoot

    property string label: ""
    property string value: ""
    property bool copyable: false
    property bool dimmed: false

    height: 52

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
            height: 36
            radius: 5
            color: "#0c0c0c"
            border.color: "#141414"
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: fieldRoot.value
                    color: fieldRoot.dimmed ? "#282828" : "#aaaaaa"
                    font.pixelSize: 12
                    font.family: "monospace"
                    elide: Text.ElideRight
                    width: parent.width - (fieldRoot.copyable ? 36 : 8)
                    font.italic: fieldRoot.dimmed
                }

                Rectangle {
                    visible: fieldRoot.copyable
                    width: 28
                    height: 24
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: copyArea.containsMouse ? "#1a1a1a" : "transparent"

                    Text {
                        id: copyIcon
                        anchors.centerIn: parent
                        text: "⎘"
                        color: "#333333"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: copyArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Clipboard.text = fieldRoot.value
                            copyIcon.text = "✓"
                            copyIcon.color = "#4ade80"
                            resetTimer.restart()
                        }
                    }

                    Timer {
                        id: resetTimer
                        interval: 1500
                        onTriggered: {
                            copyIcon.text = "⎘"
                            copyIcon.color = "#333333"
                        }
                    }
                }
            }
        }
    }
}
