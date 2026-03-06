import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io

Item {
    id: addRoot

    property string masterPassword: ""
    property bool   isSaving:       false
    property string statusMsg:      ""
    property bool   genMode:        false

    signal cancelled()
    signal saved()

    readonly property string scriptDir: "/home/llyod/Documents/Projects/hypr_vault/src/"

    // ── Clear all fields every time the view becomes visible ───────
    onVisibleChanged: {
        if (visible) clearAll()
    }

    function clearAll() {
        addService.clear()
        addUsername.clear()
        addEmail.clear()
        addUrl.clear()
        addPassword.clear()
        addRoot.genMode      = false
        addRoot.statusMsg    = ""
        addRoot.isSaving     = false
        showPassRect.checked = false
        genLength.value      = 18
        genLowercase.on      = true
        genUppercase.on      = true
        genNumbers.on        = true
        genSymbols.on        = true
    }

    // ── Live generation process ────────────────────────────────────
    // Spawns node just to call generateStrongPassword with current options.
    // Runs immediately when ⚡ is clicked and on every settings change.
    Process {
        id: genProcess
        property string buf: ""

        stdout: SplitParser { onRead: data => genProcess.buf += data }
        stderr: SplitParser { onRead: data => {} }

        onExited: (code) => {
            if (code === 0) {
                const result = genProcess.buf.trim()
                try {
                    const parsed = JSON.parse(result)
                    if (parsed.password) addPassword.setValue(parsed.password)
                } catch(e) {
                    // fallback: raw output
                    if (result) addPassword.setValue(result)
                }
            }
            genProcess.buf = ""
        }
    }

    Timer {
        id: genTimer
        interval: 80   // short debounce so rapid +/- clicks don't flood processes
        onTriggered: {
            if (!addRoot.genMode) return
            if (genProcess.running) return   // previous still running, skip
            genProcess.buf = ""
            // Pass GENERATE + options via a dummy add-like call is clunky;
            // instead call a dedicated generate subcommand if present,
            // otherwise use the inline generate path with a throwaway add.
            // We use a separate small inline node script for zero latency:
            genProcess.environment = ({})
            genProcess.command = [
                "node", "--input-type=module",
                "--eval",
                "import { generateStrongPassword } from '"
                    + addRoot.scriptDir + "/utils/generate.js';\n"
                + "const p = generateStrongPassword({"
                + "  length: "      + genLength.value    + ","
                + "  useLowercase: " + genLowercase.on   + ","
                + "  useUppercase: " + genUppercase.on   + ","
                + "  useNumbers: "   + genNumbers.on     + ","
                + "  useSymbols: "   + genSymbols.on
                + "});\n"
                + "process.stdout.write(JSON.stringify({ password: p }) + '\\n');"
            ]
            genProcess.running = true
        }
    }

    function requestGenerate() {
        if (addRoot.genMode) genTimer.restart()
    }

    // ── Add process ────────────────────────────────────────────────
    Process {
        id: addProcess
        property string buf: ""

        stdout: SplitParser { onRead: data => addProcess.buf += data }
        stderr: SplitParser { onRead: data => {} }

        onExited: (code) => {
            addRoot.isSaving = false
            if (code === 0) {
                addRoot.statusMsg = ""
                addRoot.saved()
            } else {
                addRoot.statusMsg = "save failed — check master password"
            }
            addProcess.buf = ""
        }
    }

    Timer {
        id: addTimer
        interval: 10
        property var pendingCommand: []

        onTriggered: {
            addProcess.buf         = ""
            addProcess.environment = ({ "VAULT_MASTER_KEY": addRoot.masterPassword })
            addProcess.command     = addTimer.pendingCommand
            addProcess.running     = true
        }
    }

    // ── UI ─────────────────────────────────────────────────────────
    Flickable {
        anchors.fill: parent
        contentHeight: formCol.height + 32
        clip: true

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle { implicitWidth: 2; radius: 1; color: "#222222" }
            background: Rectangle { color: "transparent" }
        }

        Column {
            id: formCol
            width: parent.width - 32
            x: 16; y: 20
            spacing: 0

            Text {
                text: "NEW CREDENTIAL"
                color: "#3a3a3a"
                font { pixelSize: 11; family: "monospace"; letterSpacing: 3 }
            }

            Item { height: 20 }

            Column {
                width: parent.width
                spacing: 10

                EditField { id: addService;  width: parent.width; placeholder: "service name *" }
                EditField { id: addUsername; width: parent.width; placeholder: "username *" }
                EditField { id: addEmail;    width: parent.width; placeholder: "email (optional)" }
                EditField { id: addUrl;      width: parent.width; placeholder: "url (optional)" }

                // ── Password row ───────────────────────────────────
                Column {
                    width: parent.width
                    spacing: 6

                    Row {
                        width: parent.width
                        spacing: 8

                        EditField {
                            id: addPassword
                            width: parent.width - 82
                            placeholder: addRoot.genMode ? "generating…" : "password"
                            isPassword: !showPassRect.checked
                            // In gen mode the field is read-only display
                            enabled: !addRoot.genMode
                        }

                        // Show/hide toggle
                        Rectangle {
                            id: showPassRect
                            property bool checked: false
                            width: 36; height: 40; radius: 5
                            color: showToggle.containsMouse ? "#141414" : "#0a0a0a"
                            border.color: "#141414"; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: showPassRect.checked ? "◉" : "◎"
                                color: "#333333"; font.pixelSize: 13
                            }
                            MouseArea {
                                id: showToggle
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: showPassRect.checked = !showPassRect.checked
                            }
                        }

                        // ⚡ Generate toggle
                        Rectangle {
                            width: 38; height: 40; radius: 5
                            color: addRoot.genMode ? "#0d1a0d" : (genBtn.containsMouse ? "#141414" : "#0a0a0a")
                            border.color: addRoot.genMode ? "#1e3a1e" : "#141414"
                            border.width: 1
                            Behavior on color        { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "⚡"
                                font.pixelSize: 14
                                color: addRoot.genMode ? "#4ade80" : "#3a3a3a"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            MouseArea {
                                id: genBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    addRoot.genMode = !addRoot.genMode
                                    if (addRoot.genMode) {
                                        showPassRect.checked = true   // show generated pass by default
                                        requestGenerate()
                                    } else {
                                        addPassword.clear()
                                    }
                                }
                            }
                        }
                    }

                    // ── Generator options panel (collapsible) ──────
                    Item {
                        width: parent.width
                        height: addRoot.genMode ? genOptionsCol.height + 16 : 0
                        clip: true
                        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                        Column {
                            id: genOptionsCol
                            width: parent.width
                            y: 10
                            spacing: 12

                            Rectangle { width: parent.width; height: 1; color: "#141414" }

                            // Length row
                            Row {
                                width: parent.width
                                spacing: 10

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "LENGTH"
                                    color: "#2a2a2a"
                                    font { pixelSize: 9; family: "monospace"; letterSpacing: 2 }
                                    width: 52
                                }

                                Rectangle {
                                    width: 24; height: 24; radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: minusArea.containsMouse ? "#1a1a1a" : "#0f0f0f"
                                    border.color: "#1a1a1a"; border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "−"; color: "#555555"
                                        font { pixelSize: 14; family: "monospace" }
                                    }
                                    MouseArea {
                                        id: minusArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (genLength.value > 8) {
                                                genLength.value--
                                                requestGenerate()
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 36; height: 24; radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: "#0f0f0f"
                                    border.color: "#1a1a1a"; border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: genLength.value
                                        color: "#aaaaaa"
                                        font { pixelSize: 12; family: "monospace" }
                                    }
                                }

                                Rectangle {
                                    width: 24; height: 24; radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: plusArea.containsMouse ? "#1a1a1a" : "#0f0f0f"
                                    border.color: "#1a1a1a"; border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"; color: "#555555"
                                        font { pixelSize: 14; family: "monospace" }
                                    }
                                    MouseArea {
                                        id: plusArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (genLength.value < 64) {
                                                genLength.value++
                                                requestGenerate()
                                            }
                                        }
                                    }
                                }

                                // Regenerate button
                                Rectangle {
                                    width: 28; height: 24; radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: regenArea.containsMouse ? "#1a1a1a" : "#0f0f0f"
                                    border.color: "#1a1a1a"; border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "↺"; color: "#4ade80"
                                        font { pixelSize: 13; family: "monospace" }
                                    }
                                    MouseArea {
                                        id: regenArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: requestGenerate()
                                    }
                                }

                                QtObject { id: genLength; property int value: 18 }
                            }

                            // Character set toggles: a-z  A-Z  0-9  !@#
                            Row {
                                width: parent.width
                                spacing: 6

                                Repeater {
                                    // model is an array of plain objects — read label and id name
                                    model: [
                                        { label: "a-z", stateId: "genLowercase" },
                                        { label: "A-Z", stateId: "genUppercase" },
                                        { label: "0-9", stateId: "genNumbers"   },
                                        { label: "!@#", stateId: "genSymbols"   }
                                    ]

                                    delegate: Rectangle {
                                        required property var modelData
                                        required property int index

                                        // Map index → the right QtObject
                                        readonly property QtObject stateObj: [
                                            genLowercase, genUppercase, genNumbers, genSymbols
                                        ][index]

                                        width: (parent.width - 18) / 4
                                        height: 28; radius: 5
                                        color: stateObj.on
                                               ? "#0d1a0d"
                                               : (togArea.containsMouse ? "#141414" : "#0a0a0a")
                                        border.color: stateObj.on ? "#1e3a1e" : "#141414"
                                        border.width: 1
                                        Behavior on color        { ColorAnimation { duration: 120 } }
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            color: stateObj.on ? "#4ade80" : "#444444"
                                            font { pixelSize: 10; family: "monospace"; letterSpacing: 1 }
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                        }
                                        MouseArea {
                                            id: togArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                stateObj.on = !stateObj.on
                                                requestGenerate()
                                            }
                                        }
                                    }
                                }

                                // State holders — must be at this Item scope so clearAll() reaches them
                                QtObject { id: genLowercase; property bool on: true }
                                QtObject { id: genUppercase; property bool on: true }
                                QtObject { id: genNumbers;   property bool on: true }
                                QtObject { id: genSymbols;   property bool on: true }
                            }

                            // Live preview hint
                            Text {
                                width: parent.width
                                text: {
                                    let chars = ""
                                    if (genLowercase.on) chars += "a-z "
                                    if (genUppercase.on) chars += "A-Z "
                                    if (genNumbers.on)   chars += "0-9 "
                                    if (genSymbols.on)   chars += "!@# "
                                    return genLength.value + " chars  ·  " + chars.trim()
                                }
                                color: "#253525"
                                font { pixelSize: 9; family: "monospace"; letterSpacing: 0.5 }
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            Item { height: 8 }

            // Status / error message
            Item {
                width: parent.width
                height: addRoot.statusMsg.length > 0 ? statusText.height + 8 : 0
                clip: true
                Behavior on height { NumberAnimation { duration: 180 } }

                Text {
                    id: statusText
                    width: parent.width
                    text: addRoot.statusMsg
                    color: addRoot.statusMsg.startsWith("save failed") ? "#883333" : "#2a4a2a"
                    font { pixelSize: 10; family: "monospace"; letterSpacing: 0.5 }
                    wrapMode: Text.WordWrap
                }
            }

            Item { height: 20 }
            Rectangle { width: parent.width; height: 1; color: "#141414" }
            Item { height: 16 }

            // Cancel / Save
            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: (parent.width - 8) / 2; height: 42; radius: 6
                    color: cancelArea.containsMouse ? "#141414" : "#0d0d0d"
                    border.color: "#1a1a1a"; border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "CANCEL"
                        color: "#444444"
                        font { pixelSize: 10; family: "monospace"; letterSpacing: 2 }
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
                    width: (parent.width - 8) / 2; height: 42; radius: 6
                    color: saveArea.containsMouse ? "#131313" : "#0d0d0d"
                    border.color: saveArea.containsMouse ? "#222222" : "#191919"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: addRoot.isSaving ? "SAVING…" : "SAVE"
                        color: addRoot.isSaving ? "#383838" : "#666666"
                        font { pixelSize: 10; family: "monospace"; letterSpacing: 2 }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        id: saveArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !addRoot.isSaving
                        onClicked: doSave()
                    }
                }
            }

            Item { height: 20 }
        }
    }

    // ── Save ───────────────────────────────────────────────────────
    function doSave() {
        const svc   = addService.currentValue.trim()
        const uname = addUsername.currentValue.trim()

        if (!svc)   { addRoot.statusMsg = "service name is required"; return }
        if (!uname) { addRoot.statusMsg = "username is required";     return }

        const email = addEmail.currentValue.trim() || "SKIP"
        const url   = addUrl.currentValue.trim()   || "SKIP"

        // In gen mode: use the already-generated password sitting in the field.
        // We send it as a literal password (not GENERATE) so the exact shown
        // password is what gets stored — user already saw it and can copy it.
        const pass = addPassword.currentValue.trim() || "GENERATE"

        addRoot.isSaving  = true
        addRoot.statusMsg = ""

        addTimer.pendingCommand = [
            "node", addRoot.scriptDir + "index.js", "add",
            svc, uname, email, url, pass
            // no genOptions arg needed — pass is already the final string
        ]
        addTimer.restart()
    }
}