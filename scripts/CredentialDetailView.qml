import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io

Item {
    id: detailRoot

    property var credential: null
    property string masterPassword: ""
    property string decryptedPassword: ""
    property bool passwordVisible: false
    property bool editMode: false
    property bool isDecrypting: false
    property string errorMessage: ""

    signal deleteRequested(int id, string password)
    signal updateRequested(int id, string service, string username, string email, string url, string password)

    onCredentialChanged: {
        if (credential !== null) {
            decryptedPassword = ""
            passwordVisible = false
            editMode = false
            errorMessage = ""
            decryptPassword()
        }
    }

    // Decrypt process
    Process {
        id: decryptProcess
        property string buf: ""

        stdout: SplitParser {
            onRead: data => decryptProcess.buf += data
        }

        onExited: (code) => {
            detailRoot.isDecrypting = false
            if (code === 0) {
                detailRoot.decryptedPassword = decryptProcess.buf.trim()
                decryptProcess.buf = ""
                detailRoot.errorMessage = ""
            } else {
                detailRoot.errorMessage = "decryption failed"
            }
        }
    }

    // Update process
    Process {
        id: updateProcess

        onExited: (code) => {
            if (code === 0) {
                detailRoot.editMode = false
                detailRoot.errorMessage = ""
            } else {
                detailRoot.errorMessage = "update failed"
            }
        }
    }

    // Delete confirm dialog
    Rectangle {
        id: deleteConfirmDialog
        anchors.fill: parent
        color: "#0a0a0a"
        visible: false
        z: 10

        Column {
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 16

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "DELETE CREDENTIAL"
                color: "#d0d0d0"
                font.pixelSize: 12
                font.family: "monospace"
                font.letterSpacing: 3
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "confirm with master password"
                color: "#333333"
                font.pixelSize: 10
                font.family: "monospace"
                font.letterSpacing: 1
                wrapMode: Text.WordWrap
            }

            Rectangle {
                width: parent.width
                height: 44
                radius: 6
                color: "#0f0f0f"
                border.color: deletePassInput.activeFocus ? "#222222" : "#161616"
                border.width: 1

                TextInput {
                    id: deletePassInput
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: "#e0e0e0"
                    font.pixelSize: 14
                    font.family: "monospace"
                    font.letterSpacing: 3
                    clip: true

                    Text {
                        anchors.fill: parent
                        anchors.verticalCenter: parent.verticalCenter
                        text: "master password"
                        color: "#2a2a2a"
                        font.pixelSize: 12
                        font.family: "monospace"
                        visible: deletePassInput.text.length === 0
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 40
                    radius: 6
                    color: cancelDelArea.containsMouse ? "#141414" : "#0f0f0f"
                    border.color: "#1a1a1a"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "CANCEL"
                        color: "#444444"
                        font.pixelSize: 10
                        font.family: "monospace"
                        font.letterSpacing: 2
                    }

                    MouseArea {
                        id: cancelDelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            deleteConfirmDialog.visible = false
                            deletePassInput.text = ""
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 40
                    radius: 6
                    color: confirmDelArea.containsMouse ? "#1a0a0a" : "#110808"
                    border.color: "#2a1010"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "DELETE"
                        color: "#883333"
                        font.pixelSize: 10
                        font.family: "monospace"
                        font.letterSpacing: 2
                    }

                    MouseArea {
                        id: confirmDelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const pass = deletePassInput.text.trim()
                            if (pass.length === 0) return
                            deleteConfirmDialog.visible = false
                            deletePassInput.text = ""
                            detailRoot.deleteRequested(detailRoot.credential.id, pass)
                        }
                    }
                }
            }
        }
    }

    // Main detail view
    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.height + 32
        clip: true
        visible: !deleteConfirmDialog.visible

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 2
                radius: 1
                color: "#222222"
            }
            background: Rectangle { color: "transparent" }
        }

        Column {
            id: mainCol
            width: parent.width - 32
            x: 16
            y: 20
            spacing: 0

            // Service header
            Row {
                width: parent.width
                spacing: 14

                Rectangle {
                    width: 44
                    height: 44
                    radius: 8
                    color: "#0f0f0f"
                    border.color: "#1a1a1a"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: detailRoot.credential ? detailRoot.credential.service.charAt(0).toUpperCase() : "?"
                        color: "#666666"
                        font.pixelSize: 18
                        font.family: "monospace"
                        font.weight: Font.Medium
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: detailRoot.credential ? detailRoot.credential.service : "—"
                        color: "#d8d8d8"
                        font.pixelSize: 16
                        font.family: "monospace"
                        font.weight: Font.Medium
                    }

                    Text {
                        text: "#" + (detailRoot.credential ? detailRoot.credential.id : "—")
                        color: "#2a2a2a"
                        font.pixelSize: 10
                        font.family: "monospace"
                        font.letterSpacing: 1
                    }
                }
            }

            Item { height: 24 }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: "#141414"
            }

            Item { height: 20 }

            // Fields
            Column {
                width: parent.width
                spacing: 16

                // Username
                DetailField {
                    width: parent.width
                    label: "USERNAME"
                    value: detailRoot.credential ? (detailRoot.credential.username || "—") : "—"
                    copyable: true
                }

                // Email
                DetailField {
                    width: parent.width
                    label: "EMAIL"
                    value: detailRoot.credential ? (detailRoot.credential.email || "not set") : "—"
                    copyable: detailRoot.credential && detailRoot.credential.email
                    dimmed: !detailRoot.credential || !detailRoot.credential.email
                }

                // URL
                DetailField {
                    width: parent.width
                    label: "URL"
                    value: detailRoot.credential ? (detailRoot.credential.url || "not set") : "—"
                    copyable: detailRoot.credential && detailRoot.credential.url
                    dimmed: !detailRoot.credential || !detailRoot.credential.url
                }

                // Password field (special)
                Column {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: "PASSWORD"
                        color: "#2a2a2a"
                        font.pixelSize: 9
                        font.family: "monospace"
                        font.letterSpacing: 2
                    }

                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: 6
                        color: "#0c0c0c"
                        border.color: "#161616"
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: detailRoot.isDecrypting
                                    ? "decrypting..."
                                    : (detailRoot.decryptedPassword.length > 0
                                        ? (detailRoot.passwordVisible
                                            ? detailRoot.decryptedPassword
                                            : "•".repeat(Math.min(detailRoot.decryptedPassword.length, 16)))
                                        : (detailRoot.errorMessage || "—"))
                                color: detailRoot.errorMessage ? "#883333" : "#cccccc"
                                font.pixelSize: detailRoot.passwordVisible ? 11 : 13
                                font.family: "monospace"
                                font.letterSpacing: detailRoot.passwordVisible ? 1 : 3
                                elide: Text.ElideRight
                                width: parent.width - 60
                            }

                            Item { Layout.fillWidth: true }

                            // Show/hide toggle
                            Rectangle {
                                width: 28
                                height: 24
                                radius: 4
                                anchors.verticalCenter: parent.verticalCenter
                                color: eyeArea.containsMouse ? "#1a1a1a" : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: detailRoot.passwordVisible ? "◉" : "◎"
                                    color: "#3a3a3a"
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    id: eyeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: detailRoot.passwordVisible = !detailRoot.passwordVisible
                                }
                            }

                            // Copy button
                            Rectangle {
                                width: 28
                                height: 24
                                radius: 4
                                anchors.verticalCenter: parent.verticalCenter
                                color: copyPassArea.containsMouse ? "#1a1a1a" : "transparent"
                                visible: detailRoot.decryptedPassword.length > 0

                                Text {
                                    id: copyPassIcon
                                    anchors.centerIn: parent
                                    text: "⎘"
                                    color: "#3a3a3a"
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    id: copyPassArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Clipboard.text = detailRoot.decryptedPassword
                                        copyPassIcon.text = "✓"
                                        copyPassIcon.color = "#4ade80"
                                        copyReset.restart()
                                    }
                                }

                                Timer {
                                    id: copyReset
                                    interval: 1500
                                    onTriggered: {
                                        copyPassIcon.text = "⎘"
                                        copyPassIcon.color = "#3a3a3a"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item { height: 28 }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: "#141414"
            }

            Item { height: 20 }

            // Action buttons
            Row {
                width: parent.width
                spacing: 8

                // Update button
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 40
                    radius: 6
                    color: updateBtnArea.containsMouse ? "#141414" : "#0e0e0e"
                    border.color: updateBtnArea.containsMouse ? "#222222" : "#181818"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "UPDATE"
                        color: "#555555"
                        font.pixelSize: 10
                        font.family: "monospace"
                        font.letterSpacing: 2
                    }

                    MouseArea {
                        id: updateBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: detailRoot.editMode = !detailRoot.editMode
                    }
                }

                // Delete button
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 40
                    radius: 6
                    color: deleteBtnArea.containsMouse ? "#160909" : "#0e0808"
                    border.color: deleteBtnArea.containsMouse ? "#2a1212" : "#1a1010"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "DELETE"
                        color: "#663333"
                        font.pixelSize: 10
                        font.family: "monospace"
                        font.letterSpacing: 2
                    }

                    MouseArea {
                        id: deleteBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: deleteConfirmDialog.visible = true
                    }
                }
            }

            // Edit form (collapsible)
            Item {
                width: parent.width
                height: detailRoot.editMode ? editFormContent.height + 20 : 0
                clip: true
                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                Column {
                    id: editFormContent
                    width: parent.width
                    y: 20
                    spacing: 10

                    // Divider
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#141414"
                        y: -10
                    }

                    Text {
                        text: "EDIT CREDENTIAL"
                        color: "#2a2a2a"
                        font.pixelSize: 9
                        font.family: "monospace"
                        font.letterSpacing: 2
                    }

                    EditField { id: editService; width: parent.width; placeholder: "service"; initialValue: detailRoot.credential ? (detailRoot.credential.service || "") : "" }
                    EditField { id: editUsername; width: parent.width; placeholder: "username"; initialValue: detailRoot.credential ? (detailRoot.credential.username || "") : "" }
                    EditField { id: editEmail; width: parent.width; placeholder: "email (optional)"; initialValue: detailRoot.credential ? (detailRoot.credential.email || "") : "" }
                    EditField { id: editUrl; width: parent.width; placeholder: "url (optional)"; initialValue: detailRoot.credential ? (detailRoot.credential.url || "") : "" }
                    EditField { id: editPassword; width: parent.width; placeholder: "new password (leave blank to keep)"; isPassword: true }

                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: 6
                        color: saveArea.containsMouse ? "#131313" : "#0d0d0d"
                        border.color: "#1e1e1e"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "SAVE CHANGES"
                            color: "#555555"
                            font.pixelSize: 10
                            font.family: "monospace"
                            font.letterSpacing: 2
                        }

                        MouseArea {
                            id: saveArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: saveUpdate()
                        }
                    }
                }
            }

            Item { height: 16 }
        }
    }

    function decryptPassword() {
        if (!credential) return
        isDecrypting = true

        const scriptDir = "/home/llyod/Documents/Projects/hypr_vault/src"
        decryptProcess.buf = ""
        decryptProcess.environment = { "VAULT_MASTER": masterPassword }
        decryptProcess.command = ["node", scriptDir + "index.js", "get", String(credential.id), "--json"]
        decryptProcess.running = false
        decryptProcess.running = true
    }

    function saveUpdate() {
        if (!credential) return
        const scriptDir = "/home/llyod/Documents/Projects/hypr_vault/src/"

        const svc = editService.currentValue || "SKIP"
        const uname = editUsername.currentValue || "SKIP"
        const mail = editEmail.currentValue || "SKIP"
        const url = editUrl.currentValue || "SKIP"
        const newPass = editPassword.currentValue || "SKIP"

        updateProcess.environment = { "VAULT_MASTER": masterPassword }
        updateProcess.command = [
            "node", scriptDir + "index.js", "update",
            String(credential.id),
            svc, uname, mail, url, newPass
        ]
        updateProcess.running = false
        updateProcess.running = true
    }
}
