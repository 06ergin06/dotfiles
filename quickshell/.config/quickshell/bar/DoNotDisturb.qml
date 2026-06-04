import QtQuick
import Quickshell

Canvas {
    id: dndBtn
    implicitWidth: 20
    implicitHeight: 20

    property bool active: DnDManager.dndEnabled

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var cx = width / 2
        var cy = height / 2
        var s = Math.min(width, height)

        ctx.strokeStyle = active ? "#F38BA8" : "#FFFFFF"
        ctx.lineWidth = 1.8
        ctx.fillStyle = active ? "#33F38BA8" : "transparent"

        // Bell shape
        ctx.beginPath()
        // Top dome (semi-circle)
        ctx.arc(cx, cy - 1, s * 0.3, Math.PI, 0, false)
        // Right side
        ctx.lineTo(cx + s * 0.22, cy + s * 0.2)
        // Bottom flare right
        ctx.lineTo(cx + s * 0.32, cy + s * 0.35)
        // Bottom flare left
        ctx.lineTo(cx - s * 0.32, cy + s * 0.35)
        // Left side
        ctx.lineTo(cx - s * 0.22, cy + s * 0.2)
        ctx.closePath()
        ctx.fill()
        ctx.stroke()

        // Clapper
        ctx.beginPath()
        ctx.arc(cx, cy + s * 0.32, s * 0.06, 0, Math.PI * 2, false)
        ctx.fillStyle = active ? "#F38BA8" : "#FFFFFF"
        ctx.fill()

        if (active) {
            // Slash line
            ctx.beginPath()
            ctx.moveTo(cx - s * 0.35, cy - s * 0.3)
            ctx.lineTo(cx + s * 0.35, cy + s * 0.38)
            ctx.strokeStyle = "#F38BA8"
            ctx.lineWidth = 2.2
            ctx.stroke()
        }
    }

    onActiveChanged: requestPaint()

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            DnDManager.dndEnabled = !DnDManager.dndEnabled
        }
    }
}
