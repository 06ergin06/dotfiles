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
    property real brightness: 0
    property int brightnessMax: 100
    property int kbdBacklight: 0
    readonly property int kbdBacklightMax: 3
    property bool nlActive: false
    property int nlTemp: 4000

    function refreshBrightness() {
        if (brightnessMax > 100) brightnessPoll.running = true
        else brightnessMaxPoll.running = true
    }

    Process {
        id: brightnessMaxPoll
        command: ["brightnessctl", "max"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(this.text.trim())
                if (!isNaN(val) && val > 0) root.brightnessMax = val
                brightnessPoll.running = true
            }
        }
    }

    Process {
        id: brightnessPoll
        command: ["brightnessctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(this.text.trim())
                if (!isNaN(val)) root.brightness = val / root.brightnessMax
            }
        }
    }

    Process { id: brightnessSet; command: ["true"] }

    Process {
        id: kbdPoll
        command: ["brightnessctl", "-d", "asus::kbd_backlight", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(this.text.trim())
                if (!isNaN(val)) root.kbdBacklight = val
            }
        }
    }

    Process { id: kbdSet; command: ["true"] }

    Process {
        id: nlCheck
        command: ["hyprctl", "getoption", "decoration:screen_shader"]
        stdout: StdioCollector {
            onStreamFinished: nlActive = this.text.indexOf("nightlight.frag") >= 0
        }
    }

    function nlToggle() {
        Quickshell.execDetached(["/home/ergin/.config/quickshell/toggle-nightlight.sh"].concat(nlActive ? [] : [String(nlTemp)]))
        nlStatusTimer.start()
    }

    function nlSetTemp(t) {
        nlTemp = t
        if (nlActive) Quickshell.execDetached(["/home/ergin/.config/quickshell/toggle-nightlight.sh", String(t)])
    }

    Timer {
        id: nlStatusTimer
        interval: 300; repeat: false
        onTriggered: nlCheck.running = true
    }

    function setBrightness(v) {
        root.brightness = v
        brightnessSet.command = ["brightnessctl", "set", String(Math.round(v * brightnessMax))]
        brightnessSet.running = true
    }

    function setKbdBacklight(v) {
        var level = Math.max(0, Math.min(kbdBacklightMax, Math.round(v)))
        root.kbdBacklight = level
        kbdSet.command = ["brightnessctl", "-d", "asus::kbd_backlight", "set", String(level)]
        kbdSet.running = true
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 4

        Text {
            text: root.nlActive ? "" : ""
            font.pixelSize: 16
            color: root.nlActive ? "#f9e2af" : Theme.fg
        }
        Text {
            text: Math.round(brightness * 100) + "%"
            font.pixelSize: 12; color: Theme.fg
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            popup.visible ? popup.visible = false : popup.visible = true
            if (popup.visible) {
                refreshBrightness()
                kbdPoll.running = true
                nlCheck.running = true
            }
        }
    }

    Item {
        id: anchorPoint
        x: -20; y: root.height + 20; width: root.width; height: 1
    }

    PopupWindow {
        id: popup
        visible: false
        implicitWidth: 250
        implicitHeight: 200
        grabFocus: true

        anchor.window: root.barWindow
        anchor.item: anchorPoint
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Bottom

        color: "transparent"

        PopupContent {
            popupWindow: popup

            Flickable {
                anchors.fill: parent
                anchors.margins: 12
                contentHeight: popupColumn.implicitHeight

                ColumnLayout {
                    id: popupColumn
                    width: parent.width
                    spacing: 8

                    Text { text: "Brightness"; font.pixelSize: 11; color: Theme.fgMuted }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 8

                        Text { text: ""; font.pixelSize: 16; color: Theme.fg }

                        SliderBar {
                            Layout.fillWidth: true
                            sliderValue: root.brightness
                            trackColor: Theme.accent
                            onMoved: { root.setBrightness(sliderValue); brightnessPoll.running = true }
                        }

                        Text {
                            text: Math.round(root.brightness * 100) + "%"
                            font.pixelSize: 10; color: Theme.fg
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: 30
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface }

                    Text { text: "Keyboard Backlight"; font.pixelSize: 11; color: Theme.fgMuted }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 8

                        Text { text: ""; font.pixelSize: 16; color: Theme.fg }

                        SliderBar {
                            Layout.fillWidth: true
                            sliderValue: root.kbdBacklight / root.kbdBacklightMax
                            trackColor: Theme.accent
                            onMoved: {
                                var level = Math.round(sliderValue * root.kbdBacklightMax)
                                sliderValue = level / root.kbdBacklightMax
                                root.setKbdBacklight(level)
                            }
                        }

                        Text {
                            text: Math.round(root.kbdBacklight / root.kbdBacklightMax * 100) + "%"
                            font.pixelSize: 10; color: Theme.fg
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: 30
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface }

                    RowLayout {
                        Layout.fillWidth: true

                        Text { text: "Night Light"; font.pixelSize: 11; color: Theme.fgMuted }
                        Item { Layout.fillWidth: true }

                        Rectangle {
                            height: 20; width: 36; radius: 10
                            color: root.nlActive ? Theme.accent : "#555555"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                width: 16; height: 16; radius: 8; color: "#FFFFFF"
                                x: root.nlActive ? parent.width - width - 2 : 2; y: 2
                                Behavior on x { NumberAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.nlToggle()
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        visible: root.nlActive

                        Text { text: "\u2600\uFE0F"; font.pixelSize: 12; color: Theme.fgMuted }

                        SliderBar {
                            Layout.fillWidth: true
                            sliderValue: (root.nlTemp - 3000) / (6500 - 3000)
                            trackColor: "#f9e2af"
                            onMoved: {
                                root.nlTemp = Math.round(3000 + sliderValue * (6500 - 3000))
                                root.nlSetTemp(root.nlTemp)
                            }
                        }

                        Text { text: "\uD83C\uDF19"; font.pixelSize: 12; color: Theme.fgMuted }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.nlActive ? root.nlTemp + "K" : ""
                        font.pixelSize: 10; color: Theme.fgMuted
                        visible: root.nlActive
                    }
                }
            }
        }
    }

    Component.onCompleted: brightnessMaxPoll.running = true
}
