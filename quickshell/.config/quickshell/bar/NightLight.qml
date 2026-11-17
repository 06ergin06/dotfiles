import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell._Window

Item {
    id: root
    implicitWidth: 20
    implicitHeight: 20

    property var barWindow: null
    property bool active: NightLightService.active
    property int currentTemp: NightLightService.temperature

    function toggle() { NightLightService.toggle() }
    function setTemp(t) { NightLightService.setTemperature(t) }

    Text {
        anchors.centerIn: parent
        text: active ? "" : ""
        font.pixelSize: 18
        color: active ? "#f9e2af" : Theme.fg

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                nlMenu.visible = !nlMenu.visible
            }
        }
    }

    Item {
        id: anchorPoint
        x: -50; y: root.height + 20; width: 1; height: 1
    }

    PopupWindow {
        id: nlMenu
        visible: false
        implicitWidth: 220
        implicitHeight: 140
        grabFocus: true

        anchor.window: root.barWindow
        anchor.item: anchorPoint
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Bottom

        color: "transparent"

        PopupContent {
            popupWindow: nlMenu

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: "Night Light: " + currentTemp + "K"
                    font.pixelSize: 12; color: Theme.fg
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text { text: "\u2600\uFE0F"; font.pixelSize: 12; color: Theme.fgMuted }

                    SliderBar {
                        Layout.fillWidth: true
                        sliderValue: (currentTemp - 3000) / (6500 - 3000)
                        trackColor: "#f9e2af"
                        onMoved: {
                            var temp = Math.round(3000 + sliderValue * (6500 - 3000))
                            root.setTemp(temp)
                        }
                    }

                    Text { text: "\uD83C\uDF19"; font.pixelSize: 12; color: Theme.fgMuted }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 6
                    color: root.active ? "#33a6e3a1" : "#33cdd6f4"
                    border.color: root.active ? "#a6e3a1" : Theme.fgMuted
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.active ? "\uD83C\uDF19  Turn Off" : "\u2600\uFE0F  Turn On"
                        font.pixelSize: 12
                        color: root.active ? "#a6e3a1" : Theme.fgMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggle()
                    }
                }
            }
        }
    }
}
