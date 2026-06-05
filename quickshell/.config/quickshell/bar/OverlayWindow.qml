import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    visible: false

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "#80000000"

    default property alias data: inner.data

    Item {
        id: inner
        anchors.fill: parent
        focus: visible

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.visible = false
                event.accepted = true
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }
}
