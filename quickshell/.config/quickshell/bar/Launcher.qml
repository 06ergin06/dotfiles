import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root

    property var items: []
    property string filterText: ""

    readonly property var filteredItems: {
        if (filterText === "")
            return items;
        var lower = filterText.toLowerCase();
        return items.filter(function (item) {
            return item.name.toLowerCase().includes(lower) || item.execString.toLowerCase().includes(lower);
        });
    }

    function reloadItems() {
        var list = DesktopEntries.applications.values.filter(function (entry) {
            return entry && entry.name && entry.command.length > 0;
        });
        list.sort(function (a, b) { return a.name.localeCompare(b.name); });
        root.items = list;
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.reloadItems() }
    }

    Component.onCompleted: root.reloadItems()

    OverlayWindow {
        id: overlay

        Rectangle {
            id: launcherPopup
            implicitWidth: 500
            implicitHeight: 480
            radius: Theme.barRadius
            color: Theme.background
            anchors.centerIn: parent

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => mouse.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    height: 36
                    topPadding: 8; bottomPadding: 8; leftPadding: 12; rightPadding: 12
                    placeholderText: "Launch application..."
                    color: Theme.fg
                    placeholderTextColor: Theme.fgMuted
                    font.pixelSize: 14
                    background: Rectangle {
                        radius: 8; color: Theme.surface
                        border.color: Theme.border; border.width: 1
                    }
                    onTextChanged: {
                        root.filterText = text;
                        itemList.currentIndex = 0;
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            itemList.currentIndex = 0;
                            itemList.forceActiveFocus();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (itemList.currentIndex >= 0 && itemList.currentIndex < root.filteredItems.length) {
                                root.launchItem(root.filteredItems[itemList.currentIndex]);
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            overlay.visible = false;
                            event.accepted = true;
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: Theme.surface

                    ListView {
                        id: itemList
                        anchors.fill: parent
                        anchors.margins: 4
                        model: root.filteredItems
                        spacing: 2
                        focus: true
                        clip: true
                        currentIndex: 0

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (itemList.currentIndex >= 0 && itemList.currentIndex < root.filteredItems.length) {
                                    root.launchItem(root.filteredItems[itemList.currentIndex]);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                if (itemList.currentIndex <= 0) {
                                    searchField.forceActiveFocus();
                                } else {
                                    itemList.currentIndex = itemList.currentIndex - 1;
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                itemList.currentIndex = Math.min(root.filteredItems.length - 1, itemList.currentIndex + 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                overlay.visible = false;
                                event.accepted = true;
                            }
                        }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: itemList.width
                            height: 44
                            radius: 8
                            color: {
                                if (index === itemList.currentIndex) return Theme.accent;
                                if (ma.containsMouse) return Theme.surfaceVariant;
                                return "transparent";
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10

                                Rectangle {
                                    width: 32; height: 32; radius: 6; color: Theme.background

                                    Image {
                                        id: appIcon
                                        anchors.centerIn: parent
                                        width: 24; height: 24
                                        source: modelData.icon !== "" ? Quickshell.iconPath(modelData.icon) : ""
                                        sourceSize.width: 24; sourceSize.height: 24
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        visible: status === Image.Ready
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: ""
                                        font.pixelSize: 16
                                        color: Theme.fgMuted
                                        visible: modelData.icon === "" || appIcon.status !== Image.Ready
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        color: index === itemList.currentIndex ? Theme.accentFg : Theme.fg
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.execString
                                        font.pixelSize: 10
                                        color: index === itemList.currentIndex ? Theme.accentFg : Theme.fgMuted
                                        elide: Text.ElideRight
                                        visible: root.filterText !== ""
                                    }
                                }
                            }

                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    itemList.currentIndex = index;
                                    root.launchItem(modelData);
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            active: true
                            policy: ScrollBar.AsNeeded
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: filteredItems.length + " applications"
                    font.pixelSize: 10
                    color: Theme.fgMuted
                }
            }
        }
    }

    GlobalShortcut {
        name: "quickshell:launcher-toggle"
        description: "Toggle Application Launcher"
        onPressed: root.toggle()
    }

    function toggle() {
        overlay.visible = !overlay.visible;
        if (overlay.visible) {
            searchField.text = "";
            root.filterText = "";
            itemList.currentIndex = 0;
            searchField.forceActiveFocus();
        }
    }

    function launchItem(item) {
        item.execute();
        overlay.visible = false;
    }
}
