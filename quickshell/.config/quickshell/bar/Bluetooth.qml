import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell._Window

Item {
    id: root
    implicitWidth: 20
    implicitHeight: 22

    property var barWindow: null
    property var adapter: Bluetooth.defaultAdapter

    Canvas {
        id: btIcon
        anchors.centerIn: parent
        width: 18
        height: 18

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var cx = width / 2
            var cy = height / 2
            var s = Math.min(width, height) * 0.38

            var on = root.adapter && root.adapter.enabled
            ctx.strokeStyle = on ? "#FFFFFF" : "#66FFFFFF"
            ctx.lineWidth = 2
            ctx.lineCap = "round"

            // Bluetooth rune: "B" shape with two vertical lines and two diagonals
            // Center vertical
            ctx.beginPath()
            ctx.moveTo(cx, cy - s * 1.1)
            ctx.lineTo(cx, cy + s * 1.1)
            ctx.stroke()

            // Top-right diagonal
            ctx.beginPath()
            ctx.moveTo(cx, cy - s * 0.5)
            ctx.lineTo(cx + s * 0.9, cy - s * 0.15)
            ctx.stroke()

            // Bottom-right diagonal  
            ctx.beginPath()
            ctx.moveTo(cx, cy + s * 0.5)
            ctx.lineTo(cx + s * 0.9, cy + s * 0.15)
            ctx.stroke()

            // Top-left diagonal
            ctx.beginPath()
            ctx.moveTo(cx, cy - s * 0.5)
            ctx.lineTo(cx - s * 0.9, cy + s * 0.15)
            ctx.stroke()

            // Bottom-left diagonal
            ctx.beginPath()
            ctx.moveTo(cx, cy + s * 0.5)
            ctx.lineTo(cx - s * 0.9, cy - s * 0.15)
            ctx.stroke()
        }
    }

    Connections {
        target: adapter
        function onEnabledChanged() { btIcon.requestPaint() }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            btMenu.visible ? btMenu.visible = false : btMenu.visible = true
        }
    }

    Item {
        id: anchorPoint
        x: -40
        y: root.height + 20
        width: root.width
        height: 1
    }

    PopupWindow {
        id: btMenu
        visible: false
        implicitWidth: 280
        implicitHeight: 350
        grabFocus: true

        anchor.window: root.barWindow
        anchor.item: anchorPoint
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Bottom

        color: "transparent"

        Rectangle {
            id: popupContent
            anchors.fill: parent
            focus: true

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    btMenu.visible = false
                    event.accepted = true
                }
            }

            onActiveFocusChanged: {
                if (!activeFocus && btMenu.visible) {
                    btMenu.visible = false
                }
            }

            color: Theme.background
            radius: Theme.barRadius
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Header with toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Bluetooth"
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.fg
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        id: toggle
                        width: 40
                        height: 20
                        radius: 10
                        color: root.adapter && root.adapter.enabled ? Theme.accent : "#555555"

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            color: "#FFFFFF"
                            x: root.adapter && root.adapter.enabled ? toggle.width - width - 2 : 2
                            y: 2

                            Behavior on x { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.adapter) {
                                    root.adapter.enabled = !root.adapter.enabled
                                }
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.surface
                }

                // Device list
                    Text {
                        text: root.adapter && root.adapter.enabled ? "Devices" : "Bluetooth off"
                        font.pixelSize: 11
                        color: Theme.fgMuted
                    }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.adapter ? root.adapter.devices : null
                    spacing: 4

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 36
                        color: modelData.connected ? Theme.surfaceVariant : "transparent"
                        radius: 6

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 6

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                        text: modelData.name || modelData.deviceName || modelData.address || "Unknown"
                                    font.pixelSize: 12
                                    color: Theme.fg
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: {
                                        if (modelData.connected) return "Connected"
                                        if (modelData.pairing) return "Pairing..."
                                        if (modelData.paired) return "Paired"
                                        return "Unpaired"
                                    }
                                    font.pixelSize: 10
                                    color: modelData.connected ? Theme.accent : Theme.fgMuted
                                }
                            }

                            Rectangle {
                                visible: modelData.paired || modelData.connected
                                width: 50
                                height: 24
                                radius: 4
                                color: modelData.connected ? "#33F38BA8" : Theme.surface

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.connected ? "Connected" : "Connect"
                                    font.pixelSize: 10
                                    color: modelData.connected ? "#F38BA8" : Theme.fg
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.connected) {
                                            modelData.disconnect()
                                        } else {
                                            modelData.connect()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
