import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Views: "login" | "list" | "detail" | "addform"
    property string currentView:        "login"
    property string masterPassword:     ""
    property var    credentials:        []
    property var    selectedCredential: null
    property string statusMessage:      ""
    property bool   isLoading:          false

    readonly property string scriptDir: "/home/llyod/Documents/Projects/hypr_vault/src/"

    // ── Root background ────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#0a0a0a"

        Rectangle {
            anchors.fill: parent
            opacity: 0.04
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#ffffff" }
                GradientStop { position: 0.5; color: "#000000" }
                GradientStop { position: 1.0; color: "#ffffff" }
            }
        }
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 1; color: "#1f1f1f"
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── Header ─────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 56
                color: "#0f0f0f"

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 1; color: "#1a1a1a"
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 20; rightMargin: 16 }

                    Rectangle {
                        visible: root.currentView !== "login"
                        width: 36; height: 36; radius: 6
                        color: backArea.containsMouse ? "#1a1a1a" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "←"; color: "#666666"
                            font { pixelSize: 20; family: "monospace" }
                        }
                        MouseArea {
                            id: backArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: navigateBack()
                        }
                    }

                    Item { width: root.currentView !== "login" ? 8 : 0 }

                    RowLayout {
                        spacing: 8
                        Rectangle {
                            width: 8; height: 8; radius: 2
                            color: "#e2e2e2"; rotation: 45
                        }
                        Text {
                            text: "HYPR-VAULT"
                            color: "#e8e8e8"
                            font { pixelSize: 16; family: "monospace"; letterSpacing: 3; weight: Font.Medium }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: root.currentView === "login" ? "#333333" : "#4ade80"
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 6
                        color: closeArea.containsMouse ? "#2a1212" : "transparent"

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeArea.containsMouse ? "#ff6b6b" : "#666666"
                            font {
                                pixelSize: 16
                                family: "monospace"
                            }
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: quitVault()
                        }
                    }
                }
            }
            // ── View container ─────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                LoginView {
                    id: loginView
                    anchors.fill: parent
                    visible:  root.currentView === "login"
                    opacity:  root.currentView === "login" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    onLoginRequested: (pass) => attemptLogin(pass)
                }

                VaultListView {
                    anchors.fill: parent
                    visible:  root.currentView === "list"
                    opacity:  root.currentView === "list" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    credentials: root.credentials
                    isLoading:   root.isLoading

                    onCredentialSelected: (cred) => {
                        root.selectedCredential = cred
                        root.currentView = "detail"
                    }
                    onAddRequested:    { root.currentView = "addform" }
                    onFilterRequested: (type, query) => filterCredentials(type, query)
                    onResetFilter:     loadCredentials()
                }

                CredentialDetailView {
                    anchors.fill: parent
                    visible:  root.currentView === "detail"
                    opacity:  root.currentView === "detail" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    credential:     root.selectedCredential
                    masterPassword: root.masterPassword

                    onDeleteRequested: (id) => deleteCredential(id)
                    onUpdateRequested: () => handleUpdateDone()
                }

                AddCredentialView {
                    anchors.fill: parent
                    visible:  root.currentView === "addform"
                    opacity:  root.currentView === "addform" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    masterPassword: root.masterPassword

                    onCancelled: root.currentView = "list"
                    onSaved: {
                        root.currentView = "list"
                        loadCredentials()
                    }
                }
            }

            // ── Status bar ─────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: root.statusMessage !== "" ? 36 : 0
                color: "#0d0d0d"
                clip: true
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width; height: 1; color: "#161616"
                }
                Text {
                    anchors.centerIn: parent
                    text: root.statusMessage
                    color: "#666666"
                    font { pixelSize: 11; family: "monospace"; letterSpacing: 1 }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // PROCESSES
    // Master password is passed via VAULT_MASTER_KEY env var.
    // - Invisible to `ps aux` (not in argv)
    // - Scoped only to the spawned child process
    // - Quickshell Process.environment sets vars for that run only
    // ═══════════════════════════════════════════════════════════════

    // ── LOGIN ──────────────────────────────────────────────────────
    Process {
        id: loginProcess
        property string buf: ""

        stdout: SplitParser { onRead: data => loginProcess.buf += data }
        stderr: SplitParser { onRead: data => {} }

        onExited: (code) => {
            const buf = loginProcess.buf
            loginProcess.buf = ""
            loginView.busy = false

            if (code === 0) {
                root.masterPassword    = loginTimer.pendingPass
                loginTimer.pendingPass = ""
                loginView.clearField()
                loadCredentials()
            } else {
                root.masterPassword    = ""
                loginTimer.pendingPass = ""
                loginView.errorText    = "incorrect password"
                loginView.shaking      = true
                errorClearTimer.restart()
            }
        }
    }

    Timer {
        id: loginTimer
        interval: 10
        property string pendingPass: ""

        onTriggered: {
            loginProcess.buf         = ""
            loginProcess.environment = ({ "VAULT_MASTER_KEY": pendingPass })
            loginProcess.command     = ["node", root.scriptDir + "index.js", "login"]
            loginProcess.running     = true
        }
    }

    Timer {
        id: errorClearTimer
        interval: 2500
        onTriggered: loginView.errorText = ""
    }

    //Shortcut
    Shortcut {
        sequence: "Ctrl+L"
        onActivated: lockVault()
    }
    Shortcut {
        sequence: "Ctrl+N"
        onActivated: {
            if(root.currentView !== "login"){
                root.currentView = "addform"
            }
            else {
                root.currentView = "login"
            }
        }
    }
    Shortcut {
        sequence: "escape"
        onActivated: navigateBack() 
    }

    Shortcut {
        sequence: "Ctrl+T"
        onActivated: quitVault()
    }

    // ── LIST — no password needed ──────────────────────────────────
    Process {
        id: listProcess
        property string buf: ""

        stdout: SplitParser { onRead: data => listProcess.buf += data }
        stderr: SplitParser { onRead: data => {} }

        onExited: (code) => {
            root.isLoading = false
            const buf = listProcess.buf
            listProcess.buf = ""

            if (code === 0) {
                try {
                    root.credentials   = JSON.parse(buf.trim())
                    root.currentView   = "list"
                    root.statusMessage = ""
                } catch (e) {
                    root.statusMessage = "parse error: " + e.message
                }
            } else {
                root.statusMessage = "failed to load vault"
            }
        }
    }

    Timer {
        id: listTimer
        interval: 10
        onTriggered: {
            listProcess.buf     = ""
            listProcess.command = ["node", root.scriptDir + "index.js", "list", "--json"]
            listProcess.running = true
        }
    }

    // ── FILTER — no password needed ────────────────────────────────
    Process {
        id: filterProcess
        property string buf:    ""
        property string fType:  ""
        property string fQuery: ""

        stdout: SplitParser { onRead: data => filterProcess.buf += data }
        stderr: SplitParser { onRead: data => {} }

        onExited: (code) => {
            root.isLoading = false
            const buf = filterProcess.buf
            filterProcess.buf = ""

            if (code === 0) {
                try {
                    root.credentials   = JSON.parse(buf.trim())
                    root.statusMessage = ""
                } catch (e) {
                    root.statusMessage = "filter parse error"
                }
            } else {
                root.statusMessage = "filter failed"
            }
        }
    }

    Timer {
        id: filterTimer
        interval: 10
        onTriggered: {
            filterProcess.buf     = ""
            filterProcess.command = [
                "node", root.scriptDir + "index.js",
                "filter", filterProcess.fType, filterProcess.fQuery, "--json"
            ]
            filterProcess.running = true
        }
    }

    // ── DELETE ─────────────────────────────────────────────────────
    Process {
        id: deleteProcess
        stdout: SplitParser { onRead: data => {} }
        stderr: SplitParser { onRead: data => {} }

        onExited: (code) => {
            if (code === 0) {
                root.selectedCredential = null
                root.currentView        = "list"
                root.statusMessage      = "credential deleted"
                loadCredentials()
                statusClearTimer.restart()
            } else {
                root.statusMessage = "delete failed"
                statusClearTimer.restart()
            }
        }
    }

    Timer {
        id: deleteTimer
        interval: 10
        property string pendingId: ""

        onTriggered: {
            deleteProcess.environment = ({ "VAULT_MASTER_KEY": root.masterPassword })
            deleteProcess.command     = ["node", root.scriptDir + "index.js", "delete", pendingId]
            deleteProcess.running     = true
        }
    }

    Timer {
        id: statusClearTimer
        interval: 2200
        onTriggered: root.statusMessage = ""
    }

    // ═══════════════════════════════════════════════════════════════
    // FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    function attemptLogin(pass) {
        if (loginProcess.running) return
        loginView.busy         = true
        loginView.errorText    = ""
        loginTimer.pendingPass = pass
        loginTimer.restart()
    }

    function loadCredentials() {
        root.isLoading = true
        listTimer.restart()
    }

    function filterCredentials(type, query) {
        root.isLoading       = true
        filterProcess.fType  = type
        filterProcess.fQuery = query
        filterTimer.restart()
    }

    function deleteCredential(id) {
        deleteTimer.pendingId = String(id)
        deleteTimer.restart()
    }

    function handleUpdateDone() {
        root.selectedCredential = null
        root.currentView        = "list"
        root.statusMessage      = "credential updated"
        loadCredentials()
        statusClearTimer.restart()
    }

    function lockVault() {
        // If we are already logged out, do nothing
        if (root.currentView === "login") return
        
        // Wipe sensitive data from memory and reset views
        root.masterPassword     = ""
        root.credentials        = []
        root.selectedCredential = null
        root.currentView        = "login"
        
        // Optional: Give visual feedback
        root.statusMessage      = "vault locked"
        statusClearTimer.restart()
    }

    function navigateBack() {
        if (root.currentView === "detail" || root.currentView === "addform") {
            root.currentView        = "list"
            root.selectedCredential = null
        } else if (root.currentView === "list") {
            root.currentView    = "login"
            root.masterPassword = ""
            root.credentials    = []
        }
    }

    function quitVault() {
        // Stop running processes
        if (loginProcess.running)  loginProcess.running  = false
        if (listProcess.running)   listProcess.running   = false
        if (filterProcess.running) filterProcess.running = false
        if (deleteProcess.running) deleteProcess.running = false

        root.masterPassword     = ""
        root.credentials        = []
        root.selectedCredential = null

        Qt.quit()
    }
}
