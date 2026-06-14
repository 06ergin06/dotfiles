import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

// ── Aktif pencere başlığı ─────────────────────────────────────────────────────
Item {
    id: root

    implicitWidth: label.implicitWidth + 8
    implicitHeight: label.implicitHeight

    readonly property string title: {
        const win = Hyprland.focusedWindow;
        if (!win)
            return "";
        return win.class || win.title || "";
    }

    Text {
        id: label
        anchors.centerIn: parent

        text: root.title
        elide: Text.ElideRight
        maximumLineCount: 1
        width: Math.min(implicitWidth, 300)

        color: Theme.fg
        font.pixelSize: 13
        font.weight: Font.Medium

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
        opacity: root.title !== "" ? 1 : 0
    }
}
