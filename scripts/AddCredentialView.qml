import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io

Item {
    id: addRoot

    property string masterPassword: ""
    property bool isGenerating: false
    property string statusMsg: ""

    signal cancelled()
    signal saved()

    // Add process
    Process {
        id: addProcess
        property string buf: ""

        stdout: SplitParser {
            onRead: data => addProcess.buf += data
        }
        
        onExited: (code) => {
            addRoot.isGenerating = false
            if (code === 0) {
                addRoot.statusMsg = ""
                addRoot.saved()
            } else {
                addRoot.statusMsg = "save failed"
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: formCol.height + 32
        clip: true

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
            id: formCol
            width: parent.width - 32
            x: 16
            y: 20
            spacing: 0

            Text {
                text: "NEW CREDENTIAL"
                color: "#3a3a3a"
                font.pixelSize: 11
                font.family: "monospace"
                font.letterSpacing: 3
            }

            Item { height: 20 }

            Column {
                width: parent.width
                spacing: 10

                EditField { id: addService; width: parent.width; placeholder: "service name *" }
                EditField { id: addUsername; width: parent.width; placeholder: "username *" }
                EditField { id: addEmail; width: parent.width; placeholder: "email (optional)" }
                EditField { id: addUrl; width: parent.width; placeholder: "url (optional)" }

                // Password row
                Column {
                    width: parent.width
                    spacing: 6

                    Row {
                        width: parent.width
                        spacing: 8

                        EditField {
                            id: addPassword
                            width: parent.width - 76
                            placeholder: "password"
                            isPassword: !showPassToggle.checked
                        }

                        // Show/hide
                        Rectangle {
                            width: 32
                            height: 40
                            radius: 5
                            color: showPassToggle.containsMouse ? "#141414" : "#0a0a0a"
                            border.color: "#141414"
                            border.width: 1

                            property bool checked: false

                            Text {
                                anchors.centerIn: parent
                                text: parent.checked ? "◉" : "◎"
                                color: "#333333"
                                font.pixelSize: 13
                            }

                            MouseArea {
                                id: showPassToggle
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                property bool checked: false
                                onClicked: {
                                    parent.checked = !parent.checked
                                }
                            }
                        }

                        // Generate button
                        Rectangle {
                            width: 36
                            height: 40
                            radius: 5
                            color: genArea.containsMouse ? "#141414" : "#0a0a0a"
                            border.color: "#141414"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "⚡"
                                font.pixelSize: 13
                                color: "#3a3a3a"
                            }

                            MouseArea {
                                id: genArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    addPassword.currentValue = ""
                                    // Signal we want to use GENERATE
                                    addPassword.isPassword = false
                                    // Will be replaced server-side
                                    addRoot.statusMsg = "will auto-generate secure password"
                                    genModeMarker.active = true
                                }
                            }

                            // Marker for gen mode
                            QtObject {
                                id: genModeMarker
                                property bool active: false
                            }
                        }
                    }

                    // Gen mode indicator
                    Text {
                        visible: genModeMarker.active
                        text: "⚡ strong password will be generated"
                        color: "#2a4a2a"
                        font.pixelSize: 10
                        font.family: "monospace"
                        font.letterSpacing: 1
                    }
                }
            }

            Item { height: 8 }

            // Error / status
            Text {
                width: parent.width
                text: addRoot.statusMsg
                color: addRoot.statusMsg.startsWith("save failed") ? "#883333" : "#2a4a2a"
                font.pixelSize: 10
                font.family: "monospace"
                font.letterSpacing: 1
                wrapMode: Text.WordWrap
                visible: addRoot.statusMsg.length > 0
            }

            Item { height: addRoot.statusMsg.length > 0 ? 12 : 0 }

            Item { height: 20 }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: "#141414"
            }

            Item { height: 16 }

            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 42
                    radius: 6
                    color: cancelArea.containsMouse ? "#141414" : "#0d0d0d"
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
                        id: cancelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addRoot.cancelled()
                    }
                }

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 42
                    radius: 6
                    color: saveNewArea.containsMouse ? "#131313" : "#0d0d0d"
                    border.color: saveNewArea.containsMouse ? "#222222" : "#191919"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: addRoot.isGenerating ? "SAVING..." : "SAVE"
                        color: "#666666"
                        font.pixelSize: 10
                        font.family: "monospace"
                        font.letterSpacing: 2
                    }

                    MouseArea {
                        id: saveNewArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: doSave()
                    }
                }
            }

            Item { height: 20 }
        }
    }

    function doSave() {
        const svc = addService.currentValue.trim()
        const uname = addUsername.currentValue.trim()

        if (!svc || !uname) {
            addRoot.statusMsg = "service and username are required"
            return
        }

        const email = addEmail.currentValue.trim() || "SKIP"
        const url = addUrl.currentValue.trim() || "SKIP"
        const pass = genModeMarker.active ? "GENERATE" : (addPassword.currentValue.trim() || "GENERATE")

        const scriptDir = "/home/llyod/Documents/Projects/hypr_vault/src/"

        addRoot.isGenerating = true
        addProcess.buf = ""
        addProcess.stdin = masterPassword + "\n"
        addProcess.command = [
            "node", scriptDir + "index.js", "add",
            svc, uname, email, url, pass
        ]
        addProcess.running = false
        startAddTimer.restart()
    }

    Timer {
        id: startAddTimer
        interval: 1
        onTriggered: { addProcess.running = true }
    }
}
