import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Networking
import Quickshell._Window

// ── Ağ Durumu ─────────────────────────────────────────────────────────────────
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    property var barWindow: null

    property var wifiDevice: null
    property string ssid: ""
    property bool connected: wifiDevice ? wifiDevice.connected : false

    readonly property string icon: {
        if (!connected) return "⚠"
        return ""
    }

    Repeater {
        model: Networking.devices
        Item {
            required property var modelData
            Component.onCompleted: {
                if (modelData.type === DeviceType.Wifi) {
                    root.wifiDevice = modelData
                }
            }
        }
    }

    Repeater {
        model: root.wifiDevice ? root.wifiDevice.networks : null
        Item {
            required property var modelData
            property bool isConnected: modelData.connected
            onIsConnectedChanged: {
                if (isConnected) root.ssid = modelData.name
            }
            Component.onCompleted: {
                if (isConnected) root.ssid = modelData.name
            }
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 4

        Text {
            text: root.icon
            font.pixelSize: 14
            color: Theme.fg
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (wifiMenu.visible) {
                wifiMenu.visible = false
                return
            }

            if (root.wifiDevice) {
                root.wifiDevice.scannerEnabled = true
            }

            wifiMenu.visible = true
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
        id: wifiMenu
        visible: false
        implicitWidth: 250
        implicitHeight: 300
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
                    wifiMenu.visible = false
                    event.accepted = true
                }
            }

            onActiveFocusChanged: {
                if (!activeFocus && wifiMenu.visible) {
                    wifiMenu.visible = false
                }
            }

            color: Theme.background
            radius: Theme.barRadius
            border.color: Theme.border
            border.width: 1

            ListView {
                anchors.fill: parent
                anchors.margins: 10
                clip: true
                model: root.wifiDevice ? root.wifiDevice.networks : null
                spacing: 5

                delegate: Rectangle {
                    width: parent.width
                    height: 30
                    color: modelData.connected ? Theme.surfaceVariant : "transparent"
                    radius: 6

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 5

                        Text {
                            text: modelData.name
                            color: Theme.fg
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            text: modelData.connected ? "" : ""
                            color: Theme.fg
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!modelData.connected) {
                                modelData.connect()
                            }
                            wifiMenu.visible = false
                        }
                    }
                }
            }
        }

    }
}
