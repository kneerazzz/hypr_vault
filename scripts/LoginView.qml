import QtQuick

Item {
id: loginRoot

    signal loginRequested(string password)

    property bool busy: false
    property string errorText: ""
    property bool shaking: false

    property string displayError: ""
    property string footerLine: ""
    property bool unlocked: false

    function clearField() { passwordField.text = "" }
    function focusField() { passwordField.forceActiveFocus() }

    onVisibleChanged: if (visible) Qt.callLater(focusField)

    Component.onCompleted: {
        const lines = [
            "restricted access",
            "classified storage",
            "authorized users only",
            "encrypted vault",
            "trust nothing",
            "secure memory",
            "protected archive",
            "silence is security",
            "keep it secret",
            "secrets worth dying for"
        ]

        footerLine = lines[Math.floor(Math.random() * lines.length)]
    }

    onErrorTextChanged: {
        if (errorText !== "") {

            const teases = [
                "access denied.",
                "authentication failed.",
                "incorrect password.",
                "credentials rejected.",
                "that wasn't the key.",
                "invalid authorization.",
                "vault remains locked.",
                "permission denied.",
                "wrong credentials.",
                "security check failed.",
                "nice guess.",
                "system unimpressed.",
                "denied by security.",
                "this vault isn't that easy.",
                "not even close.",
                "attempt recorded.",
                "brute force won't help.",
                "authentication mismatch.",
                "try harder."
            ]

            displayError = teases[Math.floor(Math.random() * teases.length)]
            shaking = true
        } else {
            displayError = ""
        }
    }

    SequentialAnimation {
        running: loginRoot.shaking
        loops: 1

        NumberAnimation { target: contentCol; property: "x"; to: -10; duration: 45 }
        NumberAnimation { target: contentCol; property: "x"; to: 10; duration: 45 }
        NumberAnimation { target: contentCol; property: "x"; to: -6; duration: 45 }
        NumberAnimation { target: contentCol; property: "x"; to: 6; duration: 45 }
        NumberAnimation { target: contentCol; property: "x"; to: 0; duration: 45 }

        ScriptAction { script: loginRoot.shaking = false }
    }

    Column {
        id: contentCol
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 300)
        spacing: 0

        Item {
            width: parent.width
            height: 80

            Item {
                width: 40
                height: 44
                anchors.centerIn: parent

                Rectangle {
                    id: shackle
                    x: 8
                    y: loginRoot.unlocked ? -8 : 0
                    width: 24
                    height: 20
                    radius: 12
                    color: "transparent"
                    border.color: "#888888"
                    border.width: 3

                    Behavior on y {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    x: 0
                    y: 16
                    width: 40
                    height: 28
                    radius: 4
                    color: "#1a1a1a"
                    border.color: "#333333"
                    border.width: 1

                    Rectangle {
                        anchors.centerIn: parent
                        width: 6
                        height: 6
                        radius: 3
                        color: "#444444"
                    }
                }
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "VAULT ACCESS"
            color: "#ffffff"

            font {
                pixelSize: 16
                family: "monospace"
                letterSpacing: 5
                weight: Font.Medium
            }
        }

        Item { height: 8 }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Never Trust neer"
            color: "#888888"

            font {
                pixelSize: 11
                family: "monospace"
                letterSpacing: 2
            }
        }

        Item { height: 28 }

        Rectangle {
            width: parent.width
            height: 48
            radius: 6
            color: "#111111"
            border.color: passwordField.activeFocus ? "#4a4a4a" : "#222222"
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "▸"
                    color: passwordField.activeFocus ? "#888888" : "#444444"
                    font.pixelSize: 12
                }

                TextInput {
                    id: passwordField
                    width: parent.width - 28
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: "#ffffff"
                    enabled: !loginRoot.busy

                    font {
                        pixelSize: 16
                        family: "monospace"
                        letterSpacing: 4
                    }

                    Keys.onReturnPressed: submitPassword()
                    Keys.onEnterPressed: submitPassword()
                }

                Rectangle {
                    width: 2
                    height: passwordField.height * 0.6
                    color: "#cccccc"
                    visible: passwordField.activeFocus
                    anchors.verticalCenter: passwordField.verticalCenter

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: passwordField.activeFocus
                        NumberAnimation { to: 0; duration: 450 }
                        NumberAnimation { to: 1; duration: 450 }
                    }
                }
            }
        }

        Item { height: 10 }

        Item {
            width: parent.width
            height: loginRoot.displayError.length > 0 ? 24 : 0
            clip: true

            Text {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                horizontalAlignment: Text.AlignHCenter
                text: loginRoot.displayError
                color: "#e05555"

                font {
                    pixelSize: 11
                    family: "monospace"
                    letterSpacing: 1.5
                }
            }
        }

        Item { height: loginRoot.displayError.length > 0 ? 8 : 14 }

        Rectangle {
            width: parent.width
            height: 44
            radius: 6

            color: loginRoot.busy
                ? "#111111"
                : (btnArea.containsMouse ? "#222222" : "#161616")

            border.color: loginRoot.busy
                        ? "#222222"
                        : (btnArea.containsMouse ? "#444444" : "#2a2a2a")

            border.width: 1

            Text {
                anchors.centerIn: parent
                text: loginRoot.busy ? "VERIFYING…" : "UNLOCK"
                color: loginRoot.busy ? "#555555" : "#cccccc"

                font {
                    pixelSize: 12
                    family: "monospace"
                    letterSpacing: 4
                    weight: Font.Medium
                }
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

        Item { height: 28 }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            text: loginRoot.footerLine
            color: "#555555"

            font {
                pixelSize: 12
                family: "monospace"
                letterSpacing: 2
                italic: true
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        opacity: 0.06
        z: 100
        color: "transparent"

        Repeater {
            model: parent.height / 3

            Rectangle {
                width: parent.width
                height: 1
                y: index * 3
                color: "#ffffff"
                opacity: 0.15
            }
        }
    }

    function submitPassword() {

        const pass = passwordField.text

        if (pass.length === 0) {

            const emptyMsgs = [
                "password required.",
                "input cannot be empty.",
                "enter credentials first.",
                "no password detected.",
                "provide authentication key."
            ]

            displayError = emptyMsgs[Math.floor(Math.random() * emptyMsgs.length)]
            shaking = true
            return
        }

        loginRequested(pass)
    }
}
