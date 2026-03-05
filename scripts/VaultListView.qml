import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: listRoot

    property var  credentials:   []
    property bool isLoading:     false
    property bool filterActive:  false

    signal credentialSelected(var credential)
    signal addRequested()
    signal filterRequested(string type, string query)
    signal resetFilter()

    // ── Filter type state lives at Item scope, not inside Row ──────
    property string selectedFilterType: "service"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Action bar ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: "#0c0c0c"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1
                color: "#161616"
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                spacing: 8

                // Filter toggle
                Rectangle {
                    width: 40; height: 36; radius: 6
                    color: filterPanel.visible
                           ? "#1a1a1a"
                           : (filterToggleArea.containsMouse ? "#141414" : "transparent")
                    border.color: filterPanel.visible ? "#2a2a2a" : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "⊟"
                        color: filterPanel.visible ? "#aaaaaa" : "#444444"
                        font.pixelSize: 16
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    MouseArea {
                        id: filterToggleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (filterPanel.visible) {
                                listRoot.closeFilterPanel()
                            } else {
                                filterPanel.visible = true
                                filterInput.forceActiveFocus()
                            }
                        }
                    }
                }

                // Entry count
                Text {
                    text: listRoot.filterActive
                          ? listRoot.credentials.length + " filtered"
                          : listRoot.credentials.length + " entries"
                    color: "#555555"
                    font { pixelSize: 14; family: "monospace"; letterSpacing: 1 }
                }

                Item { Layout.fillWidth: true }

                // Add button
                Rectangle {
                    height: 36
                    width: addLabel.width + 28
                    radius: 6
                    color: addArea.containsMouse ? "#1c1c1c" : "#141414"
                    border.color: addArea.containsMouse ? "#2a2a2a" : "#1a1a1a"
                    border.width: 1
                    Behavior on color        { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "+"; color: "#666666"; font { pixelSize: 17; family: "monospace" } }
                        Text { id: addLabel; text: "ADD"; color: "#666666"; font { pixelSize: 12; family: "monospace"; letterSpacing: 2 } }
                    }
                    MouseArea {
                        id: addArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: listRoot.addRequested()
                    }
                }
            }
        }

        // ── Filter panel ───────────────────────────────────────────
        Rectangle {
            id: filterPanel
            Layout.fillWidth: true
            height: 0
            Layout.preferredHeight: height
            visible: false
            color: "#090909"
            clip: true

            onVisibleChanged: {
                if (visible) {
                    heightAnim.to = 100
                } else {
                    heightAnim.to = 0
                }
                heightAnim.restart()
            }

            NumberAnimation {
                id: heightAnim
                target: filterPanel
                property: "height"
                duration: 200
                easing.type: Easing.OutCubic
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1
                color: "#161616"
            }

            Column {
                anchors { fill: parent; margins: 14 }
                spacing: 8

                // Filter type pills
                Row {
                    spacing: 6
                    Repeater {
                        model: ["service", "username", "email"]
                        delegate: Rectangle {
                            required property string modelData
                            height: 24
                            width: pillLabel.width + 16
                            radius: 4
                            color: listRoot.selectedFilterType === modelData
                                   ? "#1e1e1e"
                                   : (pillArea.containsMouse ? "#141414" : "transparent")
                            border.color: listRoot.selectedFilterType === modelData
                                          ? "#2a2a2a" : "transparent"
                            border.width: 1

                            Text {
                                id: pillLabel
                                anchors.centerIn: parent
                                text: modelData
                                color: listRoot.selectedFilterType === modelData
                                       ? "#aaaaaa" : "#555555"
                                font { pixelSize: 14; family: "monospace"; letterSpacing: 1 }
                            }
                            MouseArea {
                                id: pillArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: listRoot.selectedFilterType = modelData
                            }
                        }
                    }
                }

                // Search input + GO — UNCHANGED
                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: parent.width - 58; height: 32; radius: 5
                        color: "#0f0f0f"
                        border.color: filterInput.activeFocus ? "#222222" : "#161616"
                        border.width: 1

                        TextInput {
                            id: filterInput
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#cccccc"
                            font { pixelSize: 14; family: "monospace" }
                            clip: true
                            Keys.onReturnPressed: doFilter()
                            Keys.onEscapePressed: listRoot.closeFilterPanel()

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "search..."
                                color: "#444444"
                                font { pixelSize: 14; family: "monospace" }
                                visible: filterInput.text.length === 0
                            }
                        }
                    }

                    Rectangle {
                        width: 46; height: 32; radius: 5
                        color: goArea.containsMouse ? "#1a1a1a" : "#111111"
                        border.color: "#1a1a1a"; border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "GO"
                            color: "#777777"
                            font { pixelSize: 12; family: "monospace"; letterSpacing: 2 }
                        }
                        MouseArea {
                            id: goArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: doFilter()
                        }
                    }
                }

                // Clear filter link
                Text {
                    visible: listRoot.filterActive
                    text: "✕ clear filter"
                    color: "#333333"
                    font { pixelSize: 10; family: "monospace"; letterSpacing: 1 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            listRoot.filterActive = false
                            filterInput.text = ""
                            listRoot.resetFilter()
                        }
                    }
                }
            }
        }

        // ── Credentials list ───────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Loading spinner
            Column {
                anchors.centerIn: parent
                spacing: 12
                visible: listRoot.isLoading

                Item {
                    width: 20; height: 20
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "transparent"
                        border.color: "#222222"; border.width: 2

                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: "#555555"
                            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                        }

                        RotationAnimator on rotation {
                            from: 0; to: 360
                            duration: 1200
                            loops: Animation.Infinite
                            running: listRoot.isLoading
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "loading..."
                    color: "#2a2a2a"
                    font { pixelSize: 11; family: "monospace"; letterSpacing: 2 }
                }
            }

            // Empty state
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: !listRoot.isLoading && listRoot.credentials.length === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: listRoot.filterActive ? "no matches" : "vault is empty"
                    color: "#222222"
                    font { pixelSize: 13; family: "monospace"; letterSpacing: 2 }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: listRoot.filterActive ? "try a different query" : "add your first secret"
                    color: "#1a1a1a"
                    font { pixelSize: 10; family: "monospace"; letterSpacing: 1.5 }
                }
            }

            // List
            ListView {
                anchors.fill: parent
                visible: !listRoot.isLoading && listRoot.credentials.length > 0
                model: listRoot.credentials
                spacing: 0
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 2; radius: 1
                        color: "#222222"
                    }
                    background: Rectangle { color: "transparent" }
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    height: 62
                    color: itemArea.containsMouse ? "#0f0f0f" : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    // Separator
                    Rectangle {
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 }
                        height: 1
                        color: "#111111"
                    }

                    // Hover accent bar
                    Rectangle {
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        width: 2
                        height: itemArea.containsMouse ? 28 : 0
                        color: "#333333"
                        Behavior on height { NumberAnimation { duration: 150 } }
                    }

                    Row {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                        spacing: 12

                        // Avatar badge
                        Rectangle {
                            width: 36; height: 36; radius: 7
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#0f0f0f"
                            border.color: "#1a1a1a"; border.width: 1

                            // ── CHANGED: brighter avatar letter ──
                            Text {
                                anchors.centerIn: parent
                                text: (modelData.service || "?").charAt(0).toUpperCase()
                                color: "#aaaaaa"
                                font { pixelSize: 15; family: "monospace"; weight: Font.Medium }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            // ── CHANGED: matches detail panel service name ──
                            Text {
                                text: modelData.service || "—"
                                color: "#e8e8e8"
                                font { pixelSize: 15; family: "monospace"; weight: Font.Medium }
                            }

                            // ── CHANGED: matches detail panel sub-label ──
                            Text {
                                text: modelData.username || modelData.email || "—"
                                color: "#888888"
                                font { pixelSize: 12; family: "monospace" }
                                elide: Text.ElideRight
                                width: listRoot.width - 110
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // ── CHANGED: more visible arrow ──
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            color: itemArea.containsMouse ? "#aaaaaa" : "#444444"
                            font.pixelSize: 20
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                    }

                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: listRoot.credentialSelected(modelData)
                    }
                }
            }
        }
    }

    //Shortcut
    Shortcut {
        sequence: "Ctrl+F"
        onActivated: {
            if(listRoot.filterActive){
                listRoot.closeFilterPanel()
            }
            else {
                filterPanel.visible = true
                filterInput.forceActiveFocus()
            }
        }
    }

    function doFilter() {
        const q = filterInput.text.trim()
        if (q.length === 0) return
        listRoot.filterActive = true
        listRoot.filterRequested(listRoot.selectedFilterType, q)
    }
    function closeFilterPanel() {
        filterPanel.visible = false
        if (listRoot.filterActive) {
            listRoot.filterActive = false
            filterInput.text = ""
            listRoot.resetFilter()
        }
    }
}
