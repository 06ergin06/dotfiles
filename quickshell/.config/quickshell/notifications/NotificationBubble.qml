import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../bar"

Rectangle {
    id: bubble
    required property var notification

    signal dismissed()

    implicitWidth: 360
    implicitHeight: layout.implicitHeight + 20

    radius: 8
    color: Theme.background
    border.color: Theme.borderAccent
    border.width: 1
    clip: false

    property bool hovered: false
    property bool isDismissing: false

    Timer {
        id: dismissTimer
        interval: 5000
        running: !bubble.hovered && !bubble.isDismissing
        onTriggered: dismissGracefully()
    }

    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }

    ColumnLayout {
        id: layout
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 22
                height: 22
                radius: 11
                color: Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: {
                        var name = bubble.notification.appName || "?"
                        return name.charAt(0).toUpperCase()
                    }
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.accentFg
                }
            }

            Text {
                Layout.fillWidth: true
                text: bubble.notification.appName || "Unknown"
                font.pixelSize: 12
                font.bold: true
                color: Theme.accent
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 6
                height: 6
                radius: 3
                color: {
                    switch (bubble.notification.urgency) {
                        case NotificationUrgency.Critical: return Theme.error
                        case NotificationUrgency.Low: return Theme.fgMuted
                        default: return Theme.accent
                    }
                }
            }
        }

        Text {
            id: summaryLabel
            Layout.fillWidth: true
            text: bubble.notification.summary || ""
            font.pixelSize: 13
            font.bold: true
            color: Theme.fg
            wrapMode: Text.Wrap
            maximumLineCount: 1
            elide: Text.ElideRight
        }

        Text {
            id: bodyLabel
            Layout.fillWidth: true
            text: bubble.notification.body || ""
            font.pixelSize: 12
            font.weight: Font.Normal
            color: "#DDDDDD"
            wrapMode: Text.Wrap
            maximumLineCount: 5
            elide: Text.ElideRight
        }
    }

    height: layout.implicitHeight + 20

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: bubble.hovered = true
        onExited: bubble.hovered = false
        onClicked: dismissGracefully()
    }

    function dismissGracefully() {
        if (isDismissing) return
        isDismissing = true
        dismissTimer.stop()
        opacity = 0
        dismissed()

        fadeDestroyTimer.start()
    }

    Timer {
        id: fadeDestroyTimer
        interval: 350
        onTriggered: bubble.destroy()
    }
}
