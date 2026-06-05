import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell._Window

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    property var barWindow: null
    property int backlight: 0
    readonly property int backlightMax: 3

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: kbdPoll.running = true
    }

    Process {
        id: kbdPoll
        command: ["brightnessctl", "-d", "asus::kbd_backlight", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(this.text.trim())
                if (!isNaN(val)) root.backlight = val
            }
        }
    }

    Process { id: kbdSet; command: ["true"] }

    function setBacklight(v) {
        var level = Math.max(0, Math.min(backlightMax, Math.round(v)))
        root.backlight = level
        kbdSet.command = ["brightnessctl", "-d", "asus::kbd_backlight", "set", String(level)]
        kbdSet.running = true
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 4

        Text {
            text: ""
            font.pixelSize: 16
            color: backlight > 0 ? Theme.fg : Theme.fgMuted
        }
        Text {
            text: backlight > 0 ? backlight + "/" + backlightMax : "Off"
            font.pixelSize: 12
            color: backlight > 0 ? Theme.fg : Theme.fgMuted
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.visible ? popup.visible = false : popup.visible = true
    }

    Item {
        id: anchorPoint
        x: -20; y: root.height + 20; width: root.width; height: 1
    }

    PopupWindow {
        id: popup
        visible: false
        implicitWidth: 250
        implicitHeight: 100
        grabFocus: true

        anchor.window: root.barWindow
        anchor.item: anchorPoint
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Bottom

        color: "transparent"

        PopupContent {
            popupWindow: popup

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: "Keyboard Backlight"
                    font.pixelSize: 11; color: Theme.fgMuted
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text { text: ""; font.pixelSize: 16; color: Theme.fg }

                    SliderBar {
                        Layout.fillWidth: true
                        sliderValue: root.backlight / root.backlightMax
                        trackColor: Theme.accent
                        onMoved: {
                            var level = Math.round(sliderValue * root.backlightMax)
                            sliderValue = level / root.backlightMax
                            root.setBacklight(level)
                        }
                    }

                    Text {
                        text: root.backlight + "/" + root.backlightMax
                        font.pixelSize: 10; color: Theme.fg
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 30
                    }
                }
            }
        }
    }

    Component.onCompleted: kbdPoll.running = true
}
