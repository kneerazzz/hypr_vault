import QtQuick

Item {
    id: loginRoot

    signal loginRequested(string password)

    // Parent controls these
    property bool   busy:      false
    property string errorText: ""
    property bool   shaking:   false

    function clearField() { passwordField.text = "" }
    function focusField()  { passwordField.forceActiveFocus() }

    onVisibleChanged: if (visible) Qt.callLater(focusField)

    // ── Shake ──────────────────────────────────────────────────────
    SequentialAnimation {
        id: shakeAnim
        running: loginRoot.shaking
        loops: 1
        NumberAnimation { target: contentCol; property: "x"; to: -10; duration: 45 }
        NumberAnimation { target: contentCol; property: "x"; to:  10; duration: 45 }
        NumberAnimation { target: contentCol; property: "x"; to:  -6; duration: 45 }
        NumberAnimation { target: contentCol; property: "x"; to:   6; duration: 45 }
        NumberAnimation { target: contentCol; property: "x"; to:   0; duration: 45 }
        ScriptAction { script: loginRoot.shaking = false }
    }

    // ── Layout ─────────────────────────────────────────────────────
    Column {
        id: contentCol
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 300)
        spacing: 0

        // Lock icon
        Item {
            width: parent.width
            height: 80

            Item {
                width: 40; height: 44
                anchors.centerIn: parent

                Rectangle {           // shackle
                    x: 8; y: 0
                    width: 24; height: 20; radius: 12
                    color: "transparent"
                    border.color: loginRoot.busy ? "#4a4a4a" : "#333333"
                    border.width: 3
                    Behavior on border.color { ColorAnimation { duration: 300 } }
                }
                Rectangle {           // body
                    x: 0; y: 16
                    width: 40; height: 28; radius: 4
                    color: "#141414"
                    border.color: "#222222"; border.width: 1
                    Rectangle {       // keyhole
                        anchors.centerIn: parent
                        width: 6; height: 6; radius: 3
                        color: "#2e2e2e"
                    }
                }
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "VAULT ACCESS"
            color: "#d0d0d0"
            font { pixelSize: 15; family: "monospace"; letterSpacing: 4; weight: Font.Light }
        }

        Item { height: 6 }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "enter master password"
            color: "#444444"
            font { pixelSize: 11; family: "monospace"; letterSpacing: 1.5 }
        }

        Item { height: 28 }

        // Password field
        Rectangle {
            width: parent.width; height: 48; radius: 6
            color: "#0f0f0f"
            border.color: passwordField.activeFocus ? "#2a2a2a" : "#161616"
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Row {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "▸"
                    color: passwordField.activeFocus ? "#555555" : "#252525"
                    font.pixelSize: 10
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                TextInput {
                    id: passwordField
                    width: parent.width - 28
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: "#e0e0e0"
                    font { pixelSize: 15; family: "monospace"; letterSpacing: 3 }
                    selectionColor: "#2a2a2a"
                    clip: true
                    enabled: !loginRoot.busy
                    Keys.onReturnPressed: submitPassword()
                    Keys.onEnterPressed:  submitPassword()
                }
            }
        }

        Item { height: 10 }

        // Error label
        Item {
            width: parent.width
            height: loginRoot.errorText.length > 0 ? 20 : 0
            clip: true
            Behavior on height { NumberAnimation { duration: 180 } }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: loginRoot.errorText
                color: "#cc4444"
                font { pixelSize: 11; family: "monospace"; letterSpacing: 1 }
            }
        }

        Item { height: loginRoot.errorText.length > 0 ? 8 : 14 }

        // Unlock button
        Rectangle {
            width: parent.width; height: 44; radius: 6
            color: loginRoot.busy ? "#0e0e0e"
                   : (btnArea.containsMouse ? "#1a1a1a" : "#111111")
            border.color: loginRoot.busy ? "#181818"
                          : (btnArea.containsMouse ? "#2a2a2a" : "#1a1a1a")
            border.width: 1
            Behavior on color        { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: loginRoot.busy ? "VERIFYING…" : "UNLOCK"
                color: loginRoot.busy ? "#383838" : "#aaaaaa"
                font { pixelSize: 11; family: "monospace"; letterSpacing: 3; weight: Font.Medium }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            MouseArea {
                id: btnArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !loginRoot.busy
                onClicked: submitPassword()
            }
        }

        Item { height: 24 }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "secrets worth dying for"
            color: "#2a2a2a"
            font { pixelSize: 10; family: "monospace"; letterSpacing: 2; italic: true }
        }
    }

    // ── Internal ───────────────────────────────────────────────────
    function submitPassword() {
        // Never trim — passwords may have meaningful spaces
        const pass = passwordField.text
        if (pass.length === 0) {
            loginRoot.shaking = true
            return
        }
        // Parent decides success/failure; it calls clearField() on success
        // or sets errorText + shaking on failure
        loginRequested(pass)
    }
}
