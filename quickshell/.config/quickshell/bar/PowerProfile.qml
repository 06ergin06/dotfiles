import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

// ── Güç Profili ──────────────────────────────────────────────────────────────
Item {
    id: root

    implicitWidth: 20
    implicitHeight: 20

    readonly property string profileIcon: {
        if (PowerProfiles.profile === PowerProfile.PowerSaver) return ""
        if (PowerProfiles.profile === PowerProfile.Performance) return ""
        return "" // balanced
    }
    
    readonly property color iconColor: Theme.fg

    Text {
        anchors.centerIn: parent
        text: root.profileIcon
        font.pixelSize: 14
        color: root.iconColor
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (PowerProfiles.profile === PowerProfile.PowerSaver) {
                PowerProfiles.profile = PowerProfile.Balanced
            } else if (PowerProfiles.profile === PowerProfile.Balanced) {
                PowerProfiles.profile = PowerProfile.Performance
            } else {
                PowerProfiles.profile = PowerProfile.PowerSaver
            }
        }
    }
}