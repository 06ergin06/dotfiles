import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

// ── Pil Göstergesi ────────────────────────────────────────────────────────────
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    property var bat: UPower.displayDevice
    property bool showRemaining: false

    property int percent: bat ? Math.round(bat.percentage * 100) : 0
    property bool charging: bat ? (bat.state === UPowerDeviceState.Charging) : false
    property bool present: bat ? (bat.isPresent || bat.percentage > 0) : false

    readonly property real remainingSeconds: bat ? (charging ? bat.timeToFull : bat.timeToEmpty) : 0

    readonly property string remainingText: {
        const seconds = Math.max(0, Math.round(root.remainingSeconds))
        if (!seconds) return "--"
        const hours = Math.floor(seconds / 3600)
        const minutes = Math.floor((seconds % 3600) / 60)
        if (hours > 0) return `~${hours}h ${minutes}m`
        return `~${Math.max(1, minutes)}m`
    }

    readonly property string valueText: root.showRemaining ? root.remainingText : (root.percent + "%")

    readonly property string icon: {
        if (charging) return ""
        if (percent >= 90) return ""
        if (percent >= 75) return ""
        if (percent >= 50) return ""
        if (percent >= 25) return ""
        return ""
    }

    readonly property color iconColor: {
        if (percent <= 15) return Theme.error
        return Theme.fg
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 3
        visible: root.present

        Text {
            id: batteryIcon
            text: root.icon
            font.pixelSize: 13
            color: root.iconColor
        }

        Text {
            text: root.valueText
            font.pixelSize: 11
            color: root.iconColor
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.showRemaining = !root.showRemaining
    }
}
