import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// ── Bar Penceresi ─────────────────────────────────────────────────────────────
Scope {
    id: root
    property alias emojiSelector: emojiHandler
    property alias clipboard: clipHandler
    property var brightnessItems: []
    property var volumeItems: []

    function refreshBrightness() {
        for (var i = 0; i < brightnessItems.length; i++) {
            brightnessItems[i].refreshBrightness()
        }
    }

    function refreshVolume() {
        for (var i = 0; i < volumeItems.length; i++) {
            volumeItems[i].refreshVolume()
        }
    }

    Loader {
        id: emojiLoader
        active: false
        source: "EmojiSelector.qml"
    }

    Loader {
        id: clipLoader
        active: false
        source: "Clipboard.qml"
    }

    QtObject {
        id: emojiHandler
        function toggle() {
            if (!emojiLoader.active) emojiLoader.active = true
            if (emojiLoader.item) emojiLoader.item.toggle()
        }
    }

    QtObject {
        id: clipHandler
        function toggle() {
            if (!clipLoader.active) clipLoader.active = true
            if (clipLoader.item) clipLoader.item.toggle()
        }
    }

    // Her ekrana bir bar aç
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            // Katman ayarları
            anchors {
                top: true
                left: true
                right: true
            }
            exclusiveZone: Theme.barHeight   // Pencereler barın tam altında açılsın
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            implicitHeight: Theme.barHeight
            color: "transparent"

            // ── Dış kapsayıcı ───────────────────────────────────
            Item {
                anchors.fill: parent

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: Theme.barHeight
                    radius: Theme.barRadius
                    color: Theme.background

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.barPaddingH
                        anchors.rightMargin: Theme.barPaddingH
                        anchors.topMargin: Theme.barPaddingV
                        anchors.bottomMargin: Theme.barPaddingV
                        spacing: 0

                        RowLayout {
                            id: leftSection
                            Layout.alignment: Qt.AlignVCenter
                            spacing: Theme.itemSpacing
                            Workspaces {}
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            id: rightSection
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Rectangle {
                                height: Theme.pillMinHeight
                                radius: Theme.pillRadius
                                color: Theme.surface
                                border.color: Theme.border
                                border.width: 1
                                visible: awItem.title !== ""
                                implicitWidth: awItem.implicitWidth + Theme.pillPaddingH * 2

                                ActiveWindow {
                                    id: awItem
                                    anchors.centerIn: parent
                                }
                            }

                            Rectangle {
                                height: Theme.pillMinHeight
                                radius: Theme.pillRadius
                                color: Theme.surface
                                border.color: Theme.border
                                border.width: 1
                                implicitWidth: netItem.implicitWidth + Theme.pillPaddingH * 2

                                Network {
                                    id: netItem
                                    anchors.centerIn: parent
                                    barWindow: win
                                }
                            }

                            Rectangle {
                                height: Theme.pillMinHeight
                                radius: Theme.pillRadius
                                color: Theme.surface
                                border.color: Theme.border
                                border.width: 1
                                implicitWidth: btItem.implicitWidth + Theme.pillPaddingH * 2

                                Bluetooth {
                                    id: btItem
                                    anchors.centerIn: parent
                                    barWindow: win
                                }
                            }

                            Rectangle {
                                height: Theme.pillMinHeight
                                radius: Theme.pillRadius
                                color: Theme.surface
                                border.color: Theme.border
                                border.width: 1
                                implicitWidth: dndItem.implicitWidth + Theme.pillPaddingH * 2

                                DoNotDisturb {
                                    id: dndItem
                                    anchors.centerIn: parent
                                }
                            }

                            Rectangle {
                                height: Theme.pillMinHeight
                                radius: Theme.pillRadius
                                color: Theme.surface
                                border.color: Theme.border
                                border.width: 1
                                implicitWidth: volItem.implicitWidth + Theme.pillPaddingH * 2

                                Volume {
                                    id: volItem
                                    anchors.centerIn: parent
                                    barWindow: win
                                    Component.onCompleted: root.volumeItems.push(this)
                                }
                            }

                            Rectangle {
                                height: Theme.pillMinHeight
                                radius: Theme.pillRadius
                                color: Theme.surface
                                border.color: Theme.border
                                border.width: 1
                                implicitWidth: brItem.implicitWidth + Theme.pillPaddingH * 2

                                Brightness {
                                    id: brItem
                                    anchors.centerIn: parent
                                    barWindow: win
                                    Component.onCompleted: root.brightnessItems.push(this)
                                }
                            }

                            Rectangle {
                                height: Theme.pillMinHeight
                                radius: Theme.pillRadius
                                color: Theme.surface
                                border.color: Theme.border
                                border.width: 1
                                implicitWidth: batItem.implicitWidth + Theme.pillPaddingH * 2

                                Battery {
                                    id: batItem
                                    anchors.centerIn: parent
                                }
                            }

                            Rectangle {
                                height: Theme.pillMinHeight
                                radius: Theme.pillRadius
                                color: Theme.surface
                                border.color: Theme.border
                                border.width: 1
                                implicitWidth: ppItem.implicitWidth + Theme.pillPaddingH * 2

                                PowerProfile {
                                    id: ppItem
                                    anchors.centerIn: parent
                                }
                            }

                            Rectangle {
                                height: Theme.pillMinHeight
                                radius: Theme.pillRadius
                                color: Theme.surface
                                border.color: Theme.border
                                border.width: 1
                                implicitWidth: kdeItem.implicitWidth + Theme.pillPaddingH * 2

                                KdeConnect {
                                    id: kdeItem
                                    anchors.centerIn: parent
                                    barWindow: win
                                }
                            }

                            Rectangle {
                                height: Theme.pillMinHeight
                                radius: Theme.pillRadius
                                color: Theme.surface
                                border.color: Theme.border
                                border.width: 1
                                implicitWidth: powerLabel.implicitWidth + Theme.pillPaddingH * 2

                                Text {
                                    id: powerLabel
                                    anchors.centerIn: parent
                                    text: "⏻"
                                    font.pixelSize: 14
                                    color: Theme.fg
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["wlogout"])
                                }
                            }
                        }
                    }

                    // Saati tüm barın tam merkezine sabitliyoruz (sol-sağ bölümlerin uzunluklarından bağımsız)
                    Clock {
                        anchors.centerIn: parent
                        z: 1
                    }
                }
            }
        }
    }
}
