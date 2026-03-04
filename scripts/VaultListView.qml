import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: listRoot

    property var credentials: []
    property bool isLoading: false
    property bool filterActive: false

    signal credentialSelected(var credential)
    signal addRequested()
    signal filterRequested(string type, string query)
    signal resetFilter()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Action bar
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: "#0c0c0c"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#161616"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 8

                // Filter toggle
                Rectangle {
                    id: filterToggle
                    width: 36
                    height: 32
                    radius: 6
                    color: listRoot.filterActive
                        ? "#1a1a1a"
                        : (filterToggleArea.containsMouse ? "#141414" : "transparent")
                    border.color: listRoot.filterActive ? "#2a2a2a" : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "⊟"
                        color: listRoot.filterActive ? "#aaaaaa" : "#444444"
                        font.pixelSize: 14
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        id: filterToggleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: filterPanel.visible = !filterPanel.visible
                    }
                }

                // Count / status
                Text {
                    text: listRoot.filterActive
                        ? listRoot.credentials.length + " filtered"
                        : listRoot.credentials.length + " entries"
                    color: "#333333"
                    font.pixelSize: 11
                    font.family: "monospace"
                    font.letterSpacing: 1
                }

                Item { Layout.fillWidth: true }

                // Add button
                Rectangle {
                    height: 32
                    width: addBtnText.width + 24
                    radius: 6
                    color: addArea.containsMouse ? "#1c1c1c" : "#141414"
                    border.color: addArea.containsMouse ? "#2a2a2a" : "#1a1a1a"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "+"
                            color: "#666666"
                            font.pixelSize: 16
                            font.family: "monospace"
                        }

                        Text {
                            id: addBtnText
                            text: "ADD"
                            color: "#666666"
                            font.pixelSize: 11
                            font.family: "monospace"
                            font.letterSpacing: 2
                        }
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

        // Filter panel (collapsible)
        Rectangle {
            id: filterPanel
            Layout.fillWidth: true
            height: visible ? 96 : 0
            visible: false
            color: "#090909"
            clip: true

            states: [
                State {
                    name: "shown"
                    when: filterPanel.visible
                    PropertyChanges { target: filterPanel; height: 96 }
                },
                State {
                    name: "hidden"
                    when: !filterPanel.visible
                    PropertyChanges { target: filterPanel; height: 0 }
                }
            ]
            transitions: [
                Transition {
                    from: "hidden"; to: "shown"
                    NumberAnimation { properties: "height"; duration: 200; easing.type: Easing.OutCubic }
                },
                Transition {
                    from: "shown"; to: "hidden"
                    NumberAnimation { properties: "height"; duration: 200; easing.type: Easing.OutCubic }
                }
            ]

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#161616"
            }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // Filter type selector
                Row {
                    spacing: 6

                    Repeater {
                        model: ["service", "username", "email"]
                        delegate: Rectangle {
                            height: 24
                            width: filterTypeText.width + 16
                            radius: 4
                            color: filterTypeGroup.selected === modelData
                                ? "#1e1e1e"
                                : (filterTypeHover.containsMouse ? "#141414" : "transparent")
                            border.color: filterTypeGroup.selected === modelData
                                ? "#2a2a2a"
                                : "transparent"
                            border.width: 1

                            Text {
                                id: filterTypeText
                                anchors.centerIn: parent
                                text: modelData
                                color: filterTypeGroup.selected === modelData
                                    ? "#aaaaaa"
                                    : "#444444"
                                font.pixelSize: 10
                                font.family: "monospace"
                                font.letterSpacing: 1
                            }

                            MouseArea {
                                id: filterTypeHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: filterTypeGroup.selected = modelData
                            }
                        }
                    }
                }

                // Filter input row
                Row {
                    width: parent.width
                    spacing: 8

                    // Type selection state
                    QtObject {
                        id: filterTypeGroup
                        property string selected: "service"
                    }

                    Rectangle {
                        width: parent.width - 60
                        height: 32
                        radius: 5
                        color: "#0f0f0f"
                        border.color: filterInput.activeFocus ? "#222222" : "#161616"
                        border.width: 1

                        TextInput {
                            id: filterInput
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#cccccc"
                            font.pixelSize: 12
                            font.family: "monospace"
                            clip: true

                            Text {
                                anchors.fill: parent
                                anchors.verticalCenter: parent.verticalCenter
                                text: "search..."
                                color: "#2a2a2a"
                                font.pixelSize: 12
                                font.family: "monospace"
                                visible: filterInput.text.length === 0
                            }

                            Keys.onReturnPressed: doFilter()
                        }
                    }

                    Rectangle {
                        width: 48
                        height: 32
                        radius: 5
                        color: goArea.containsMouse ? "#1a1a1a" : "#111111"
                        border.color: "#1a1a1a"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "GO"
                            color: "#555555"
                            font.pixelSize: 10
                            font.family: "monospace"
                            font.letterSpacing: 2
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

                // Clear filter
                Text {
                    visible: listRoot.filterActive
                    text: "✕ clear filter"
                    color: "#333333"
                    font.pixelSize: 10
                    font.family: "monospace"
                    font.letterSpacing: 1

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

        // Credentials list
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Loading state
            Column {
                anchors.centerIn: parent
                spacing: 12
                visible: listRoot.isLoading

                Item {
                    width: 20
                    height: 20
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "transparent"
                        border.color: "#222222"
                        border.width: 2

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: "#555555"
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        RotationAnimator on rotation {
                            from: 0
                            to: 360
                            duration: 1200
                            loops: Animation.Infinite
                            running: listRoot.isLoading
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "decrypting..."
                    color: "#2a2a2a"
                    font.pixelSize: 11
                    font.family: "monospace"
                    font.letterSpacing: 2
                }
            }

            // Empty state
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: !listRoot.isLoading && listRoot.credentials.length === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "vault is empty"
                    color: "#222222"
                    font.pixelSize: 13
                    font.family: "monospace"
                    font.letterSpacing: 2
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "add your first secret"
                    color: "#1a1a1a"
                    font.pixelSize: 10
                    font.family: "monospace"
                    font.letterSpacing: 1.5
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
                        implicitWidth: 2
                        radius: 1
                        color: "#222222"
                    }

                    background: Rectangle {
                        color: "transparent"
                    }
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    height: 56
                    color: itemArea.containsMouse ? "#0f0f0f" : "transparent"

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        height: 1
                        color: "#111111"
                    }

                    // Left service color indicator
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: itemArea.containsMouse ? 28 : 0
                        color: "#333333"
                        Behavior on height { NumberAnimation { duration: 150 } }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        // Service initial badge
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 6
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#0f0f0f"
                            border.color: "#1a1a1a"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: (modelData.service || "?").charAt(0).toUpperCase()
                                color: "#555555"
                                font.pixelSize: 13
                                font.family: "monospace"
                                font.weight: Font.Medium
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: modelData.service || "—"
                                color: "#d0d0d0"
                                font.pixelSize: 12
                                font.family: "monospace"
                                font.weight: Font.Medium
                            }

                            Text {
                                text: modelData.username || modelData.email || "—"
                                color: "#3a3a3a"
                                font.pixelSize: 10
                                font.family: "monospace"
                                elide: Text.ElideRight
                                width: 240
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            color: itemArea.containsMouse ? "#444444" : "#1e1e1e"
                            font.pixelSize: 18
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

    function doFilter() {
        const q = filterInput.text.trim()
        if (q.length === 0) return
        listRoot.filterActive = true
        listRoot.filterRequested(filterTypeGroup.selected, q)
    }
}
