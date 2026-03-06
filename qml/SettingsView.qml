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

            // ── PORTABLE RECOVERY EXPORT ──
            Column {
                id: portableCol
                width: parent.width
                spacing: 8
                
                property bool confirming: false

                Text { text: "SECURE PORTABLE BUNDLE"; color: "#d0d0d0"; font { pixelSize: 12; family: "monospace"; letterSpacing: 2 } }
                
                Text {
                    text: portableCol.confirming ? "Confirm Master Password to authorize export:" : "Creates an encrypted .json lifeboat. Safe for USB/Cloud storage."
                    color: portableCol.confirming ? "#de8a4a" : "#555555"
                    font { family: "monospace"; pixelSize: 10 }
                    wrapMode: Text.WordWrap; width: parent.width
                }

                Rectangle {
                    width: parent.width; height: 40; radius: 6
                    color: "#0a0a0a"; border.color: "#1a1a1a"; border.width: 1
                    TextInput {
                        id: portableInput
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#cccccc"; font { pixelSize: 12; family: "monospace" }
                        echoMode: portableCol.confirming ? TextInput.Password : TextInput.Normal
                        // If not confirming, show path; if confirming, clear for password
                        text: portableCol.confirming ? "" : root.lastPortablePath
                        clip: true
                    }
                }

                Row {
                    spacing: 12
                    Rectangle {
                        width: 160; height: 36; radius: 6
                        color: portableArea.containsMouse ? "#1a120a" : "#110a08"
                        border.color: "#2a1a10"; border.width: 1
                        Text { 
                            anchors.centerIn: parent
                            text: portableCol.confirming ? "CONFIRM & EXPORT" : "CREATE LIFEBOAT"
                            color: "#de8a4a"; font { pixelSize: 10; family: "monospace" } 
                        }
                        MouseArea {
                            id: portableArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!portableCol.confirming) {
                                    // STEP 1: Save the path and switch to password mode
                                    root.setPortablePath(portableInput.text);
                                    portableCol.confirming = true;
                                    portableInput.forceActiveFocus();
                                } else {
                                    // STEP 2: Execute the export with the entered password
                                    root.exportPortableRequested(portableInput.text);
                                    portableCol.confirming = false;
                                }
                            }
                        }
                    }
                    // Cancel button resets the state
                    Rectangle {
                        visible: portableCol.confirming
                        width: 80; height: 36; radius: 6; color: "#1a0a0a"
                        Text { anchors.centerIn: parent; text: "CANCEL"; color: "#cc4444"; font { pixelSize: 10; family: "monospace" } }
                        MouseArea { anchors.fill: parent; onClicked: portableCol.confirming = false }
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