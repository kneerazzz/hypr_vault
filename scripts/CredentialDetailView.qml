import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io

Item {
    id: detailRoot

    property var    credential:        null
    property string masterPassword:    ""

    property string decryptedPassword: ""
    property bool   passwordVisible:   false
    property bool   editMode:          false
    property bool   isDecrypting:      false
    property string errorMessage:      ""

    // Which confirmation dialog is open: "" | "show" | "delete" | "save" | "copy"
    property string confirmMode: ""

    signal deleteRequested(int id)
    signal updateRequested()

    readonly property string scriptDir: "/home/llyod/Documents/Projects/hypr_vault/src/"

    onCredentialChanged: {
        if (credential !== null) {
            decryptedPassword = ""
            passwordVisible   = false
            editMode          = false
            errorMessage      = ""
            confirmMode       = ""
            // Auto-decrypt immediately — password display starts as bullets
            decryptTimer.restart()
        }
    }

    // ── Helpers ────────────────────────────────────────────────────
    function fieldValue(key) {
        if (!credential) return ""
        const v = credential[key]
        if (v === null || v === undefined || v === "" || v === "null") return ""
        return String(v)
    }

    function copyToClipboard(text) {
        clipHelper.text = text
        clipHelper.selectAll()
        clipHelper.copy()
    }

    // ── Processes ──────────────────────────────────────────────────
    Process {
        id: decryptProcess
        property string buf: ""

        stdout: SplitParser { onRead: data => decryptProcess.buf += data }
        stderr: SplitParser { onRead: data => {} }

        onExited: (code) => {
            detailRoot.isDecrypting = false
            if (code === 0) {
                detailRoot.decryptedPassword = decryptProcess.buf.trim()
                detailRoot.errorMessage      = ""
            } else {
                detailRoot.errorMessage = "decryption failed"
            }
            decryptProcess.buf = ""
        }
    }

    Timer {
        id: decryptTimer
        interval: 10
        onTriggered: {
            if (!detailRoot.credential) return
            detailRoot.isDecrypting    = true
            decryptProcess.buf         = ""
            decryptProcess.environment = ({ "VAULT_MASTER_KEY": detailRoot.masterPassword })
            decryptProcess.command     = [
                "node", detailRoot.scriptDir + "index.js",
                "get", String(detailRoot.credential.id)
            ]
            decryptProcess.running = true
        }
    }

    Process {
        id: updateProcess
        stdout: SplitParser { onRead: data => {} }
        stderr: SplitParser { onRead: data => {} }

        onExited: (code) => {
            if (code === 0) {
                detailRoot.editMode     = false
                detailRoot.errorMessage = ""
                detailRoot.updateRequested()
            } else {
                detailRoot.errorMessage = "update failed"
            }
        }
    }

    Timer {
        id: updateTimer
        interval: 10
        property var pendingCommand: []
        onTriggered: {
            updateProcess.environment = ({ "VAULT_MASTER_KEY": detailRoot.masterPassword })
            updateProcess.command     = updateTimer.pendingCommand
            updateProcess.running     = true
        }
    }

    // Hidden clipboard helper
    TextEdit { id: clipHelper; visible: false; text: "" }

    // Auto-clear clipboard after 15 seconds for security
    Timer {
        id: clipboardClearTimer
        interval: 15000 // 15 seconds
        onTriggered: detailRoot.copyToClipboard("") 
    }

    // ══════════════════════════════════════════════════════════════
    // MASTER PASSWORD / TRICK CONFIRM OVERLAY
    // ══════════════════════════════════════════════════════════════
    Rectangle {
        id: confirmOverlay
        anchors.fill: parent
        color: "#0a0a0a"
        visible: detailRoot.confirmMode !== ""
        z: 20

        Column {
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 18

            // Title
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (detailRoot.confirmMode === "delete") return "DELETE CREDENTIAL"
                    if (detailRoot.confirmMode === "save")   return "SAVE CHANGES"
                    if (detailRoot.confirmMode === "copy")   return "COPY PASSWORD"
                    return "REVEAL PASSWORD"
                }
                color: detailRoot.confirmMode === "delete" ? "#cc4444" : "#d0d0d0"
                font { pixelSize: 12; family: "monospace"; letterSpacing: 3 }
            }

            // Subtitle (Kept vague for the trick words)
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (detailRoot.confirmMode === "delete") {
                        return detailRoot.credential ? "\"" + detailRoot.credential.service + "\" will be permanently removed" : ""
                    }
                    if (detailRoot.confirmMode === "save") return "enter master password to confirm update"
                    if (detailRoot.confirmMode === "copy") return "enter passcode to copy"
                    return "enter passcode to view"
                }
                color: "#3a3a3a"
                font { pixelSize: 10; family: "monospace"; letterSpacing: 0.5 }
                wrapMode: Text.WordWrap
            }

            // Password input
            Rectangle {
                width: parent.width; height: 44; radius: 6
                color: "#0f0f0f"
                border.color: confirmPassInput.activeFocus ? "#222222" : "#161616"
                border.width: 1

                Row {
                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "▸"; color: confirmPassInput.activeFocus ? "#555555" : "#252525"
                        font.pixelSize: 10
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    TextInput {
                        id: confirmPassInput
                        width: parent.width - 28
                        anchors.verticalCenter: parent.verticalCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: "#e0e0e0"
                        font { pixelSize: 14; family: "monospace"; letterSpacing: 3 }
                        selectionColor: "#2a2a2a"
                        clip: true
                        Keys.onReturnPressed: submitConfirm()
                        Keys.onEnterPressed:  submitConfirm()
                        Keys.onEscapePressed: {
                            detailRoot.confirmMode = ""
                            confirmPassInput.text  = ""
                            confirmError.text      = ""
                        }
                    }
                }

                onVisibleChanged: {
                    if (visible) {
                        confirmPassInput.text  = ""
                        confirmError.text      = ""
                        Qt.callLater(() => confirmPassInput.forceActiveFocus())
                    }
                }
            }

            // Inline error
            Text {
                id: confirmError
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: ""
                color: "#cc4444"
                font { pixelSize: 10; family: "monospace"; letterSpacing: 1 }
                visible: text.length > 0
            }

            // Buttons
            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: (parent.width - 8) / 2; height: 40; radius: 6
                    color: cancelConfirmArea.containsMouse ? "#141414" : "#0f0f0f"
                    border.color: "#1a1a1a"; border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "CANCEL"
                        color: "#444444"
                        font { pixelSize: 10; family: "monospace"; letterSpacing: 2 }
                    }
                    MouseArea {
                        id: cancelConfirmArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            detailRoot.confirmMode = ""
                            confirmPassInput.text  = ""
                            confirmError.text      = ""
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 8) / 2; height: 40; radius: 6
                    
                    color: {
                        if (detailRoot.confirmMode === "delete") return confirmOkArea.containsMouse ? "#1a0a0a" : "#110808"
                        if (detailRoot.confirmMode === "save")   return confirmOkArea.containsMouse ? "#0a121a" : "#081014"
                        return confirmOkArea.containsMouse ? "#0d1a0d" : "#0a120a"
                    }
                    border.color: {
                        if (detailRoot.confirmMode === "delete") return "#2a1010"
                        if (detailRoot.confirmMode === "save")   return "#101a2a"
                        return "#1a2a1a"
                    }
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (detailRoot.confirmMode === "delete") return "DELETE"
                            if (detailRoot.confirmMode === "save")   return "SAVE"
                            if (detailRoot.confirmMode === "copy")   return "COPY"
                            return "REVEAL"
                        }
                        color: {
                            if (detailRoot.confirmMode === "delete") return "#883333"
                            if (detailRoot.confirmMode === "save")   return "#4aa9de"
                            return "#4ade80"
                        }
                        font { pixelSize: 10; family: "monospace"; letterSpacing: 2 }
                    }
                    MouseArea {
                        id: confirmOkArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: submitConfirm()
                    }
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════
    // MAIN DETAIL VIEW
    // ══════════════════════════════════════════════════════════════
    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.height + 32
        clip: true
        visible: detailRoot.confirmMode === ""

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle { implicitWidth: 2; radius: 1; color: "#222222" }
            background: Rectangle { color: "transparent" }
        }

        Column {
            id: mainCol
            width: parent.width - 32
            x: 16; y: 20
            spacing: 0

            // Service header
            Row {
                width: parent.width
                spacing: 14

                Rectangle {
                    width: 44; height: 44; radius: 8
                    color: "#0f0f0f"
                    border.color: "#1a1a1a"; border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: detailRoot.credential
                              ? detailRoot.credential.service.charAt(0).toUpperCase()
                              : "?"
                        color: "#666666"
                        font { pixelSize: 18; family: "monospace"; weight: Font.Medium }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: detailRoot.fieldValue("service") || "—"
                        color: "#d8d8d8"
                        font { pixelSize: 16; family: "monospace"; weight: Font.Medium }
                    }
                    Text {
                        text: "#" + (detailRoot.credential ? detailRoot.credential.id : "—")
                        color: "#2a2a2a"
                        font { pixelSize: 10; family: "monospace"; letterSpacing: 1 }
                    }
                }
            }

            Item { height: 24 }
            Rectangle { width: parent.width; height: 1; color: "#141414" }
            Item { height: 20 }

            Column {
                width: parent.width
                spacing: 14

                DetailField {
                    width: parent.width
                    label: "USERNAME"
                    value: detailRoot.fieldValue("username") || "—"
                    copyable: detailRoot.fieldValue("username") !== ""
                }

                DetailField {
                    width: parent.width
                    label: "EMAIL"
                    value: {
                        const v = detailRoot.fieldValue("email")
                        return v !== "" ? v : "not set"
                    }
                    copyable: detailRoot.fieldValue("email") !== ""
                    dimmed:   detailRoot.fieldValue("email") === ""
                }

                DetailField {
                    width: parent.width
                    label: "URL"
                    value: {
                        const v = detailRoot.fieldValue("url")
                        return v !== "" ? v : "not set"
                    }
                    copyable: detailRoot.fieldValue("url") !== ""
                    dimmed:   detailRoot.fieldValue("url") === ""
                }

                // PASSWORD
                Column {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: "PASSWORD"
                        color: "#252525"
                        font { pixelSize: 9; family: "monospace"; letterSpacing: 2 }
                    }

                    Rectangle {
                        width: parent.width; height: 40; radius: 6
                        color: "#0c0c0c"
                        border.color: "#161616"; border.width: 1

                        Row {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 8 }
                            spacing: 6

                            // Password text / status
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 72
                                elide: Text.ElideRight
                                text: {
                                    if (detailRoot.isDecrypting)      return "decrypting…"
                                    if (detailRoot.errorMessage)       return detailRoot.errorMessage
                                    if (!detailRoot.decryptedPassword) return "—"
                                    return detailRoot.passwordVisible
                                           ? detailRoot.decryptedPassword
                                           : "•".repeat(Math.min(detailRoot.decryptedPassword.length, 18))
                                }
                                color: detailRoot.errorMessage ? "#883333" : "#cccccc"
                                font {
                                    pixelSize: detailRoot.passwordVisible ? 11 : 13
                                    family: "monospace"
                                    letterSpacing: detailRoot.passwordVisible ? 0.5 : 3
                                }
                            }

                            // Show/hide — requires "see" trick password
                            Rectangle {
                                width: 28; height: 24; radius: 4
                                anchors.verticalCenter: parent.verticalCenter
                                color: eyeArea.containsMouse ? "#1a1a1a" : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }
                                visible: detailRoot.decryptedPassword.length > 0

                                Text {
                                    anchors.centerIn: parent
                                    text: detailRoot.passwordVisible ? "◉" : "◎"
                                    color: detailRoot.passwordVisible ? "#4ade80" : "#3a3a3a"
                                    font.pixelSize: 12
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                MouseArea {
                                    id: eyeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (detailRoot.passwordVisible) {
                                            detailRoot.passwordVisible = false
                                        } else {
                                            detailRoot.confirmMode = "show"
                                        }
                                    }
                                }
                            }

                            // Copy password — requires "copy" trick password
                            Rectangle {
                                width: 28; height: 24; radius: 4
                                anchors.verticalCenter: parent.verticalCenter
                                visible: detailRoot.decryptedPassword.length > 0
                                color: copyPassArea.containsMouse ? "#1a1a1a" : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    id: copyPassIcon
                                    anchors.centerIn: parent
                                    text: "⎘"; color: "#3a3a3a"; font.pixelSize: 12
                                }
                                MouseArea {
                                    id: copyPassArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: detailRoot.confirmMode = "copy"
                                }
                                Timer {
                                    id: copyPassReset
                                    interval: 1500
                                    onTriggered: { copyPassIcon.text = "⎘"; copyPassIcon.color = "#3a3a3a" }
                                }
                            }
                        }
                    }
                }
            }

            Item { height: 28 }
            Rectangle { width: parent.width; height: 1; color: "#141414" }
            Item { height: 20 }

            // EDIT / DELETE buttons
            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: (parent.width - 8) / 2; height: 40; radius: 6
                    color: editBtnArea.containsMouse ? "#141414" : "#0e0e0e"
                    border.color: editBtnArea.containsMouse ? "#222222" : "#181818"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: detailRoot.editMode ? "CANCEL EDIT" : "EDIT"
                        color: "#555555"
                        font { pixelSize: 10; family: "monospace"; letterSpacing: 2 }
                    }
                    MouseArea {
                        id: editBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: detailRoot.editMode = !detailRoot.editMode
                    }
                }

                Rectangle {
                    width: (parent.width - 8) / 2; height: 40; radius: 6
                    color: deleteBtnArea.containsMouse ? "#160909" : "#0e0808"
                    border.color: deleteBtnArea.containsMouse ? "#2a1212" : "#1a1010"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "DELETE"
                        color: "#663333"
                        font { pixelSize: 10; family: "monospace"; letterSpacing: 2 }
                    }
                    MouseArea {
                        id: deleteBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // Require master password confirm before deleting
                        onClicked: detailRoot.confirmMode = "delete"
                    }
                }
            }

            // COLLAPSIBLE EDIT FORM
            Item {
                width: parent.width
                height: detailRoot.editMode ? editFormContent.height + 24 : 0
                clip: true
                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                Column {
                    id: editFormContent
                    width: parent.width
                    y: 20
                    spacing: 10

                    Rectangle { width: parent.width; height: 1; color: "#141414"; y: -10 }

                    Text {
                        text: "EDIT CREDENTIAL"
                        color: "#2a2a2a"
                        font { pixelSize: 9; family: "monospace"; letterSpacing: 2 }
                    }

                    EditField {
                        id: editService;  width: parent.width; placeholder: "service name *"
                        initialValue: detailRoot.fieldValue("service")
                        required: true
                    }
                    EditField {
                        id: editUsername; width: parent.width; placeholder: "username *"
                        initialValue: detailRoot.fieldValue("username")
                        required: true
                    }
                    EditField {
                        id: editEmail;    width: parent.width; placeholder: "email (optional)"
                        initialValue: detailRoot.fieldValue("email")
                    }
                    EditField {
                        id: editUrl;      width: parent.width; placeholder: "url (optional)"
                        initialValue: detailRoot.fieldValue("url")
                    }
                    EditField {
                        id: editPassword; width: parent.width
                        placeholder: "new password (leave blank to keep)"
                        isPassword: true
                    }

                    Rectangle {
                        width: parent.width; height: 40; radius: 6
                        color: saveArea.containsMouse ? "#131313" : "#0d0d0d"
                        border.color: "#1e1e1e"; border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "SAVE CHANGES"
                            color: "#555555"
                            font { pixelSize: 10; family: "monospace"; letterSpacing: 2 }
                        }
                        MouseArea {
                            id: saveArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {

                                // validate required fields
                                const serviceValid  = editService.validate()
                                const usernameValid = editUsername.validate()

                                if (!serviceValid || !usernameValid) {
                                    return
                                }

                                detailRoot.confirmMode = "save"
                            }
                        }
                    }
                }
            }

            Item { height: 16 }
        }
    }

    // ── Logic ──────────────────────────────────────────────────────

    function submitConfirm() {
        const entered = confirmPassInput.text
        if (entered.length === 0) return

        const mode = detailRoot.confirmMode
        
        // Determine which password we expect based on the action
        let expectedPassword = detailRoot.masterPassword // Default to actual master password for delete/save
        if (mode === "show") expectedPassword = "see"
        if (mode === "copy") expectedPassword = "copy"

        if (entered !== expectedPassword) {
            confirmError.text = "incorrect passcode"
            confirmPassInput.text = ""
            shakeAnim.restart()
            return
        }

        // Authentication passed
        detailRoot.confirmMode = ""
        confirmPassInput.text  = ""
        confirmError.text      = ""

        if (mode === "show") {
            detailRoot.passwordVisible = true
        } else if (mode === "delete") {
            detailRoot.deleteRequested(detailRoot.credential.id)
        } else if (mode === "save") {
            detailRoot.commitUpdate()
        } else if (mode === "copy") {
            // Execute the clipboard copy and trigger the visual feedback
            detailRoot.copyToClipboard(detailRoot.decryptedPassword)
            copyPassIcon.text  = "✓"
            copyPassIcon.color = "#4ade80"
            copyPassReset.restart()

            // Start the 15-second destruction countdown
            clipboardClearTimer.restart()
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: confirmPassInput; property: "x"; to: -8; duration: 40 }
        NumberAnimation { target: confirmPassInput; property: "x"; to:  8; duration: 40 }
        NumberAnimation { target: confirmPassInput; property: "x"; to: -5; duration: 40 }
        NumberAnimation { target: confirmPassInput; property: "x"; to:  5; duration: 40 }
        NumberAnimation { target: confirmPassInput; property: "x"; to:  0; duration: 40 }
    }

    function commitUpdate() {

        if (!credential) return

        // Final safety validation
        if (!editService.validate() || !editUsername.validate()) {
            detailRoot.editMode = true
            return
        }

        const svc   = editService.currentValue.trim()
        const uname = editUsername.currentValue.trim()
        const mail  = editEmail.currentValue.trim() || "SKIP"
        const url   = editUrl.currentValue.trim()   || "SKIP"
        const pass  = editPassword.currentValue     || "SKIP"

        updateTimer.pendingCommand = [
            "node",
            detailRoot.scriptDir + "index.js",
            "update",
            String(credential.id),
            svc,
            uname,
            mail,
            url,
            pass
        ]

        updateTimer.restart()
    }
}