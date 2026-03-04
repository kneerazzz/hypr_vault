import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

ShellRoot {
    PanelWindow {
        id: vaultPanel

        anchors {
            right: true
            top: true
            bottom: true
        }

        implicitWidth: 480
        color: "transparent"
        exclusiveZone: visible ? width : 0

        WlrLayershell.namespace: "hypr-vault"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        VaultWidget {
            anchors.fill: parent
        }
    }
}
