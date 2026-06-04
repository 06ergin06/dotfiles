import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 4

        Repeater {
            model: Hyprland.workspaces

            delegate: Rectangle {
                required property var modelData

                readonly property bool isActive:
                    modelData.id === Hyprland.focusedWorkspace?.id

                width: 14
                height: 14
                radius: 7

                color: isActive
                    ? Theme.accent
                    : (modelData.windows > 0 ? Theme.fgMuted : Theme.background)

                border.width: isActive ? 0 : 1
                border.color: modelData.windows > 0 ? Theme.fgMuted : Theme.border

                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.exec(["hyprctl", "dispatch", "workspace", modelData.id.toString()])
                }
            }
        }
    }
}
