import QtQuick
import QtQuick.Controls

Item {
    id: settingsRoot

    property string message: ""
    property bool   isBusy:  false

    signal verifyRequested()
    signal exportRequested(string path)
    signal importRequested(string path)

    // Clear messages when view opens
    onVisibleChanged: {
        if (visible) {
            message = ""
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: contentCol.height + 40
        clip: true

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle { implicitWidth: 2; radius: 1; color: "#222222" }
            background: Rectangle { color: "transparent" }
        }

        Column {
            id: contentCol
            width: parent.width - 32
            x: 16
            y: 20
            spacing: 24

            Text {
                text: "VAULT SETTINGS & TOOLS"
                color: "#888888"
                font.pixelSize: 14
                font.family: "monospace"
                font.letterSpacing: 4
                font.weight: Font.Medium
            }

            Rectangle { width: parent.width; height: 1; color: "#141414" }

            // ── VERIFY VAULT ──────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 8

                Text { 
                    text: "INTEGRITY CHECK"
                    color: "#d0d0d0"
                    font.pixelSize: 12
                    font.family: "monospace"
                    font.letterSpacing: 2
                }
                Text {
                    text: "Validates AES-GCM auth tags to detect data corruption or tampering."
                    color: "#555555"
                    font.pixelSize: 10
                    font.family: "monospace"
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Rectangle {
                    width: 140
                    height: 36
                    radius: 6
                    color: verifyArea.containsMouse ? "#161616" : "#0f0f0f"
                    border.color: "#222222"
                    border.width: 1
                    
                    Text { 
                        anchors.centerIn: parent
                        text: "VERIFY"
                        color: "#4ade80"
                        font.pixelSize: 11
                        font.family: "monospace"
                        font.letterSpacing: 2 
                    }
                    
                    MouseArea {
                        id: verifyArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { 
                            settingsRoot.isBusy = true
                            settingsRoot.message = "verifying..."
                            settingsRoot.verifyRequested() 
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#141414" }

            // ── EXPORT VAULT ──────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 8

                Text { 
                    text: "EXPORT VAULT"
                    color: "#d0d0d0"
                    font.pixelSize: 12
                    font.family: "monospace"
                    font.letterSpacing: 2 
                }
                Text {
                    text: "Creates a portable JSON file of encrypted vault data."
                    color: "#555555"
                    font.pixelSize: 10
                    font.family: "monospace"
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 6
                    color: "#0a0a0a"
                    border.color: exportInput.activeFocus ? "#333333" : "#1a1a1a"
                    border.width: 1
                    
                    TextInput {
                        id: exportInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#cccccc"
                        font.pixelSize: 12
                        font.family: "monospace"
                        text: "/home/llyod/Documents/vault/vault_export.json"
                        clip: true
                    }
                }

                Rectangle {
                    width: 140
                    height: 36
                    radius: 6
                    color: exportArea.containsMouse ? "#161616" : "#0f0f0f"
                    border.color: "#222222"
                    border.width: 1
                    
                    Text { 
                        anchors.centerIn: parent
                        text: "EXPORT"
                        color: "#4aa9de"
                        font.pixelSize: 11
                        font.family: "monospace"
                        font.letterSpacing: 2 
                    }
                    
                    MouseArea {
                        id: exportArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { 
                            settingsRoot.isBusy = true
                            settingsRoot.message = "exporting..."
                            settingsRoot.exportRequested(exportInput.text) 
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#141414" }

            // ── IMPORT VAULT ──────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 8

                Text { 
                    text: "IMPORT VAULT"
                    color: "#d0d0d0"
                    font.pixelSize: 12
                    font.family: "monospace"
                    font.letterSpacing: 2 
                }
                Text {
                    text: "Merges a previously exported JSON file back into the database."
                    color: "#555555"
                    font.pixelSize: 10
                    font.family: "monospace"
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 6
                    color: "#0a0a0a"
                    border.color: importInput.activeFocus ? "#333333" : "#1a1a1a"
                    border.width: 1
                    
                    TextInput {
                        id: importInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#cccccc"
                        font.pixelSize: 12
                        font.family: "monospace"
                        text: "/home/llyod/Documents/vault/vault_export.json"
                        clip: true
                    }
                }

                Rectangle {
                    width: 140
                    height: 36
                    radius: 6
                    color: importArea.containsMouse ? "#1a0a0a" : "#110808"
                    border.color: "#2a1010"
                    border.width: 1
                    
                    Text { 
                        anchors.centerIn: parent
                        text: "IMPORT"
                        color: "#cc4444"
                        font.pixelSize: 11
                        font.family: "monospace"
                        font.letterSpacing: 2 
                    }
                    
                    MouseArea {
                        id: importArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { 
                            settingsRoot.isBusy = true
                            settingsRoot.message = "importing..."
                            settingsRoot.importRequested(importInput.text) 
                        }
                    }
                }
            }

            // ── System Output Message ──
            Text {
                width: parent.width
                text: settingsRoot.message
                color: settingsRoot.message.indexOf("error") !== -1 || settingsRoot.message.indexOf("WARNING") !== -1 ? "#e05555" : "#aaaaaa"
                font.pixelSize: 11
                font.family: "monospace"
                font.letterSpacing: 1
                wrapMode: Text.WordWrap
            }
        }
    }
}