import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root

    // State: "login" | "list" | "detail"
    property string currentView: "login"
    property string masterPassword: ""
    property var credentials: []
    property var selectedCredential: null
    property string statusMessage: ""
    property bool isLoading: false
    property bool isLoggingIn: false  // Guard to prevent multiple login attempts

    // Node script path (adjust if needed)
    readonly property string scriptDir: "/home/llyod/Documents/Projects/hypr_vault/src/"

    Rectangle {
        anchors.fill: parent
        color: "#0a0a0a"

        // Subtle noise texture overlay
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            opacity: 0.04
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#ffffff" }
                GradientStop { position: 0.5; color: "#000000" }
                GradientStop { position: 1.0; color: "#ffffff" }
            }
        }

        // Left edge accent line
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: "#1f1f1f"
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header bar
            Rectangle {
                Layout.fillWidth: true
                height: 56
                color: "#0f0f0f"

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: "#1a1a1a"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 16

                    // Back button
                    Rectangle {
                        visible: root.currentView !== "login"
                        width: 28
                        height: 28
                        radius: 6
                        color: backMouseArea.containsMouse ? "#1a1a1a" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "←"
                            color: "#666666"
                            font.pixelSize: 16
                            font.family: "monospace"
                        }

                        MouseArea {
                            id: backMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (root.currentView === "detail") {
                                    root.currentView = "list"
                                    root.selectedCredential = null
                                } else if (root.currentView === "list") {
                                    root.currentView = "login"
                                    root.masterPassword = ""
                                    root.credentials = []
                                }
                            }
                        }
                    }

                    Item { width: root.currentView !== "login" ? 8 : 0 }

                    // Logo / title
                    RowLayout {
                        spacing: 8

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 2
                            color: "#e2e2e2"
                            rotation: 45
                        }

                        Text {
                            text: "HYPR-VAULT"
                            color: "#e8e8e8"
                            font.pixelSize: 13
                            font.family: "monospace"
                            font.letterSpacing: 3
                            font.weight: Font.Medium
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Status indicator
                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: root.currentView === "login" ? "#333333" : "#4ade80"
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                }
            }

            // View container
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                LoginView {
                    anchors.fill: parent
                    visible: root.currentView === "login"
                    opacity: root.currentView === "login" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    onLoginRequested: (pass) => {
                        attemptLogin(pass)
                    }
                }

                VaultListView {
                    anchors.fill: parent
                    visible: root.currentView === "list"
                    opacity: root.currentView === "list" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    credentials: root.credentials
                    isLoading: root.isLoading

                    onCredentialSelected: (cred) => {
                        root.selectedCredential = cred
                        root.currentView = "detail"
                    }

                    onAddRequested: {
                        root.currentView = "addform"
                    }

                    onFilterRequested: (type, query) => {
                        filterCredentials(type, query)
                    }

                    onResetFilter: {
                        loadCredentials()
                    }
                }

                CredentialDetailView {
                    anchors.fill: parent
                    visible: root.currentView === "detail"
                    opacity: root.currentView === "detail" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    credential: root.selectedCredential

                    onDeleteRequested: (id, pass) => {
                        deleteCredential(id, pass)
                    }

                    onUpdateRequested: (id, service, username, email, url, pass) => {
                        updateCredential(id, service, username, email, url, pass)
                    }
                }

                AddCredentialView {
                    anchors.fill: parent
                    visible: root.currentView === "addform"
                    opacity: root.currentView === "addform" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }


                    onCancelled: {
                        root.currentView = "list"
                    }

                    onSaved: {
                        root.currentView = "list"
                        loadCredentials()
                    }
                }
            }

            // Status bar
            Rectangle {
                Layout.fillWidth: true
                height: root.statusMessage !== "" ? 36 : 0
                color: "#0d0d0d"
                clip: true

                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: "#161616"
                }

                Text {
                    anchors.centerIn: parent
                    text: root.statusMessage
                    color: "#666666"
                    font.pixelSize: 11
                    font.family: "monospace"
                    font.letterSpacing: 1
                }
            }
        }
    }

    // Process for listing credentials

    // List process — command set imperatively in timer
    Process {
        id: listProcess
        property string buf: ""

        stdout: SplitParser {
            onRead: data => listProcess.buf += data
        }

        onExited: (code) => {
            root.isLoading = false
            if (code === 0) {
                try {
                    root.credentials = JSON.parse(listProcess.buf.trim())
                    listProcess.buf = ""
                    root.currentView = "list"
                    root.statusMessage = ""
                } catch (e) {
                    root.statusMessage = "parse error"
                }
            } else {
                root.statusMessage = "failed to load vault"
            }
        }
    }

    // Filter process — command set imperatively in timer
    Process {
        id: filterProcess
        property string buf: ""
        property string filterType: ""
        property string filterQuery: ""

        stdout: SplitParser {
            onRead: data => filterProcess.buf += data
        }

        onExited: (code) => {
            root.isLoading = false
            if (code === 0) {
                try {
                    root.credentials = JSON.parse(filterProcess.buf.trim())
                    filterProcess.buf = ""
                    root.statusMessage = ""
                } catch (e) {
                    root.statusMessage = "filter parse error"
                }
            }
        }
    }

    // Login process
    Process {
        id: loginProcess
        property string buf: ""

        stdout: SplitParser {
            onRead: data => loginProcess.buf += data
        }

        onExited: (code) => {
            loginProcess.buf = ""
            root.isLoggingIn = false  // Reset guard flag
            if (code === 0) {
                root.masterPassword = startLoginTimer.loginPassword
                startListTimer.restart()
            } else {
                root.isLoading = false
                root.masterPassword = ""
                root.currentView = "login"
                root.statusMessage = "wrong password"
                statusClearTimer.restart()
            }
        }
    }

    // Delete process
    Process {
        id: deleteProcess
        stdout: SplitParser { onRead: data => {} }

        onExited: (code) => {
            if (code === 0) {
                root.statusMessage = "deleted"
                root.currentView = "list"
                root.selectedCredential = null
                loadCredentials()
                statusClearTimer.restart()
            } else {
                root.statusMessage = "delete failed"
            }
        }
    }

    Timer {
        id: statusClearTimer
        interval: 2000
        onTriggered: root.statusMessage = ""
    }

    // All running=true calls are ONLY inside timers — never synchronously
    Timer {
        id: startListTimer
        interval: 10
        onTriggered: {
            listProcess.buf = ""
            listProcess.command = ["node", root.scriptDir + "index.js", "list", "--json"]
            listProcess.running = true
        }
    }

    Timer {
        id: startFilterTimer
        interval: 10
        onTriggered: {
            filterProcess.buf = ""
            filterProcess.command = [
                "node", root.scriptDir + "index.js",
                "filter", filterProcess.filterType, filterProcess.filterQuery, "--json"
            ]
            filterProcess.running = true
        }
    }

    Timer {
        id: startLoginTimer
        interval: 10
        property string loginPassword: ""
        onTriggered: {
            loginProcess.buf = ""
            loginProcess.command = ["node", root.scriptDir + "index.js", "login", "--json"]
            loginProcess.stdin = loginPassword + "\n"
            loginProcess.running = true
        }
    }

    Timer {
        id: startDeleteTimer
        interval: 10
        onTriggered: { deleteProcess.running = true }
    }

    function loadCredentials() {
        root.isLoading = true
        startListTimer.restart()
    }

    function filterCredentials(type, query) {
        root.isLoading = true
        filterProcess.filterType = type
        filterProcess.filterQuery = query
        startFilterTimer.restart()
    }

    function deleteCredential(id, pass) {
        deleteProcess.stdin = pass + "\n"
        deleteProcess.command = ["node", root.scriptDir + "index.js", "delete", String(id)]
        startDeleteTimer.restart()
    }

    function attemptLogin(pass) {
        if (root.isLoggingIn) return

        root.isLoggingIn = true
        root.isLoading = true

        startLoginTimer.loginPassword = pass
        startLoginTimer.restart()
    }
}