import QtQuick
import Quickshell

Item {
    id: root
    implicitWidth: 20
    implicitHeight: 22

    property bool active: DnDManager.dndEnabled

    Text {
        anchors.centerIn: parent
        text: active ? "" : ""
        font.pixelSize: 16
        font.family: "MesloLGMDZ Nerd Font"
        color: active ? "#F38BA8" : Theme.fg
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: DnDManager.dndEnabled = !DnDManager.dndEnabled
    }
}
