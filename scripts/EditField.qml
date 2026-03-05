import QtQuick

Item {
    id: editFieldRoot

    property string placeholder:  ""
    property string initialValue: ""
    property bool   isPassword:   false
    property bool   required:     false

    property string errorMessage: ""

    readonly property string currentValue: textInput.text

    height: errorText.visible ? 64 : 46

    onInitialValueChanged: textInput.text = initialValue
    Component.onCompleted: textInput.text = initialValue

    function clear()      { textInput.text = "" }
    function setValue(v)  { textInput.text = v  }

    function validate() {
        if (required && textInput.text.trim() === "") {
            errorMessage = "This field is required"
            return false
        }
        errorMessage = ""
        return true
    }

    property bool revealPassword: false

    Column {
        anchors.fill: parent
        spacing: 4

        Rectangle {
            width: parent.width
            height: 46
            radius: 6
            color: "#111111"

            border.color:
                errorMessage !== "" ? "#ff5555"
                : textInput.activeFocus ? "#303030"
                : "#1a1a1a"
            border.width: 1

            Behavior on border.color {
                ColorAnimation { duration: 120 }
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 8

                TextInput {
                    id: textInput

                    width: parent.width - (editFieldRoot.isPassword ? 36 : 6)
                    anchors.verticalCenter: parent.verticalCenter
                    verticalAlignment: TextInput.AlignVCenter

                    echoMode: editFieldRoot.isPassword && !editFieldRoot.revealPassword
                              ? TextInput.Password
                              : TextInput.Normal

                    passwordCharacter: "•"

                    color: "#e4e4e4"
                    font.pixelSize: 14
                    font.family: "monospace"

                    clip: true

                    onTextChanged: {
                        if (errorMessage !== "")
                            errorMessage = ""
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: editFieldRoot.placeholder
                        color: "#555555"
                        font.pixelSize: 14
                        font.family: "monospace"
                        visible: textInput.text.length === 0
                    }
                }

                Rectangle {
                    visible: editFieldRoot.isPassword
                    width: 30; height: 26; radius: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: revealArea.containsMouse ? "#1f1f1f" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: editFieldRoot.revealPassword ? "🙈" : "👁"
                        font.pixelSize: 12
                        color: "#777777"
                    }

                    MouseArea {
                        id: revealArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: editFieldRoot.revealPassword = !editFieldRoot.revealPassword
                    }
                }
            }
        }

        Text {
            id: errorText
            text: editFieldRoot.errorMessage
            visible: errorMessage !== ""
            color: "#ff5555"
            font.pixelSize: 11
            font.family: "monospace"
        }
    }
}
