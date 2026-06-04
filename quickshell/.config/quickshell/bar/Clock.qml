import QtQuick
import QtQuick.Layouts
import Quickshell

// ── Saat & Tarih ──────────────────────────────────────────────────────────────
Item {
    id: root

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    property string timeString: ""
    property string dateString: ""
    property bool showDate: false

    Timer {
        id: clockTimer
        interval: 60000
        running: true
        repeat: false
        triggeredOnStart: true
        onTriggered: {
            let d = new Date()
            root.timeString = Qt.formatTime(d, "HH:mm")
            root.dateString = Qt.formatDate(d, "ddd, d MMM")
            let now = new Date()
            let msToNextMinute = (60 - now.getSeconds()) * 1000 - now.getMilliseconds()
            clockTimer.interval = msToNextMinute
            clockTimer.running = true
        }
    }

    Text {
        id: col
        anchors.centerIn: parent
        text: root.showDate ? root.dateString : root.timeString
        font.pixelSize: root.showDate ? 11 : 14
        font.weight: Font.DemiBold
        color: root.showDate ? Theme.fgMuted : Theme.fg
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.showDate = !root.showDate
    }
}
