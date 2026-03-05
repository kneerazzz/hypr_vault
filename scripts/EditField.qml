import QtQuick

Item {
    id: editFieldRoot

    property string placeholder:    ""
    property string initialValue:   ""
    property bool   isPassword:     false
    // Read this from outside to get the current value
    readonly property string currentValue: textInput.text

    height: 40

    // Reset text whenever initialValue changes (e.g. new credential loaded)
    onInitialValueChanged: {
        textInput.text = initialValue
    }

    // Also set on completion so declarative initialValue: "..." works
    Component.onCompleted: {
        textInput.text = initialValue
    }

    function clear() { textInput.text = "" }

    Rectangle {
        anchors.fill: parent
        radius: 5
        color: "#0a0a0a"
        border.color: textInput.activeFocus ? "#222222" : "#141414"
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 120 } }

        TextInput {
            id: textInput
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }
            verticalAlignment: TextInput.AlignVCenter
            echoMode: editFieldRoot.isPassword ? TextInput.Password : TextInput.Normal
            passwordCharacter: "•"
            color: "#cccccc"
            font.pixelSize: 12
            font.family: "monospace"
            font.letterSpacing: editFieldRoot.isPassword ? 2 : 0.5
            clip: true

            // Placeholder
            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: editFieldRoot.placeholder
                color: "#2a2a2a"
                font.pixelSize: 11
                font.family: "monospace"
                font.letterSpacing: 0.5
                visible: textInput.text.length === 0
            }
        }
    }
}
