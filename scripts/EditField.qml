import QtQuick

Item {
    id: editFieldRoot

    property string placeholder: ""
    property string initialValue: ""
    property bool isPassword: false
    property string currentValue: textInput.text

    height: 40

    onInitialValueChanged: {
        if (initialValue && textInput.text === "") {
            textInput.text = initialValue
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 5
        color: "#0a0a0a"
        border.color: textInput.activeFocus ? "#222222" : "#141414"
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 120 } }

        TextInput {
            id: textInput
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            echoMode: editFieldRoot.isPassword ? TextInput.Password : TextInput.Normal
            passwordCharacter: "•"
            color: "#cccccc"
            font.pixelSize: 12
            font.family: "monospace"
            font.letterSpacing: editFieldRoot.isPassword ? 2 : 0.5
            clip: true
            verticalAlignment: TextInput.AlignVCenter

            Text {
                anchors.fill: parent
                anchors.verticalCenter: parent.verticalCenter
                text: editFieldRoot.placeholder
                color: "#222222"
                font.pixelSize: 11
                font.family: "monospace"
                font.letterSpacing: 0.5
                visible: textInput.text.length === 0
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
