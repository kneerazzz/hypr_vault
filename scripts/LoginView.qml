import QtQuick
import QtQuick.Layouts

Item {
    id: loginRoot

    signal loginRequested(string password)

    property bool shaking: false

    SequentialAnimation {
        id: shakeAnim
        running: loginRoot.shaking
        loops: 1

        NumberAnimation { target: contentCol; property: "x"; to: -8; duration: 50 }
        NumberAnimation { target: contentCol; property: "x"; to: 8; duration: 50 }
        NumberAnimation { target: contentCol; property: "x"; to: -6; duration: 50 }
        NumberAnimation { target: contentCol; property: "x"; to: 6; duration: 50 }
        NumberAnimation { target: contentCol; property: "x"; to: 0; duration: 50 }
        ScriptAction { script: loginRoot.shaking = false }
    }

    Column {
        id: contentCol
        anchors.centerIn: parent
        width: parent.width - 48
        spacing: 0

        // Icon area
        Item {
            width: parent.width
            height: 80

            Column {
                anchors.centerIn: parent
                spacing: 12

                // Lock icon made from shapes
                Item {
                    width: 40
                    height: 44
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Shackle
                    Rectangle {
                        x: 8
                        y: 0
                        width: 24
                        height: 20
                        radius: 12
                        color: "transparent"
                        border.color: "#3a3a3a"
                        border.width: 3
                    }

                    // Body
                    Rectangle {
                        x: 0
                        y: 16
                        width: 40
                        height: 28
                        radius: 4
                        color: "#1a1a1a"
                        border.color: "#2a2a2a"
                        border.width: 1

                        Rectangle {
                            anchors.centerIn: parent
                            width: 6
                            height: 6
                            radius: 3
                            color: "#333333"
                        }
                    }
                }
            }
        }

        Item { height: 8 }

        // Title
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "VAULT ACCESS"
            color: "#d0d0d0"
            font.pixelSize: 15
            font.family: "monospace"
            font.letterSpacing: 4
            font.weight: Font.Light
        }

        Item { height: 6 }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "enter master password"
            color: "#555555"
            font.pixelSize: 11
            font.family: "monospace"
            font.letterSpacing: 1.5
        }

        Item { height: 32 }

        // Password input
        Rectangle {
            width: parent.width
            height: 48
            radius: 6
            color: "#0f0f0f"
            border.color: passwordField.activeFocus ? "#2a2a2a" : "#161616"
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: 150 } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "▸"
                    color: passwordField.activeFocus ? "#555555" : "#2a2a2a"
                    font.pixelSize: 10
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                TextInput {
                    id: passwordField
                    width: parent.width - 30
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: "#e0e0e0"
                    font.pixelSize: 15
                    font.family: "monospace"
                    font.letterSpacing: 3
                    selectionColor: "#2a2a2a"
                    clip: true

                    Keys.onReturnPressed: attemptLogin()
                    Keys.onEnterPressed: attemptLogin()
                }
            }
        }

        Item { height: 12 }

        // Login button
        Rectangle {
            id: loginBtn
            width: parent.width
            height: 44
            radius: 6
            color: loginBtnArea.containsMouse ? "#1a1a1a" : "#111111"
            border.color: loginBtnArea.containsMouse ? "#2a2a2a" : "#191919"
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "UNLOCK"
                color: "#aaaaaa"
                font.pixelSize: 11
                font.family: "monospace"
                font.letterSpacing: 3
                font.weight: Font.Medium
            }

            MouseArea {
                id: loginBtnArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: attemptLogin()
            }
        }

        Item { height: 24 }

        // Hint text
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "secrets worth dying for"
            color: "#999999"
            font.pixelSize: 10
            font.family: "monospace"
            font.letterSpacing: 2
            font.italic: true
        }
    }

    function attemptLogin() {
        const pass = passwordField.text.trim()
        if (pass.length === 0) {
            loginRoot.shaking = true
            return
        }
        loginRequested(pass)
        passwordField.text = ""
    }
}
