import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    property var items: []
    property string filterText: ""

    readonly property var filteredItems: {
        if (filterText === "")
            return items;
        var lower = filterText.toLowerCase();
        return items.filter(function (item) {
            return item.text.toLowerCase().includes(lower);
        });
    }

    function refresh() {
        listProcess.running = true;
    }

    Process {
        id: listProcess
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split('\n').filter(function (l) {
                    return l.trim() !== "";
                });
                var result = [];
                for (var i = 0; i < lines.length; i++) {
                    var match = lines[i].match(/^(\d+)\s+(.+)/);
                    if (match) {
                        result.push({
                            id: parseInt(match[1]),
                            text: match[2].replace(/^\[.*?\]\s*/, ''),
                            raw: match[2]
                        });
                    }
                }
                root.items = result;
            }
        }
    }

    function copyItem(id) {
        Quickshell.execDetached(["sh", "-c", "cliphist decode " + id + " | wl-copy"]);
        overlay.visible = false;
    }

    function deleteItem(id) {
        Quickshell.execDetached(["sh", "-c", "cliphist delete-id " + id]);
        refresh();
    }

    function clearAll() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        items = [];
        overlay.visible = false;
    }

    OverlayWindow {
        id: overlay

        Rectangle {
            id: clipPopup
            implicitWidth: 350
            implicitHeight: 420
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

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        height: 28
                        topPadding: 8; bottomPadding: 8; leftPadding: 8; rightPadding: 8
                        placeholderText: "Search clipboard..."
                        color: Theme.fg
                        placeholderTextColor: Theme.fgMuted
                        font.pixelSize: 12
                        background: Rectangle { radius: 6; color: Theme.surface }
                        onTextChanged: root.filterText = text
                    }

                    Rectangle {
                        height: 28; width: 56; radius: 6; color: Theme.surface
                        visible: items.length > 0

                        Text {
                            anchors.centerIn: parent
                            text: "Clear"; font.pixelSize: 10; color: Theme.error
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clearAll()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 6
                    color: Theme.surface

                    ListView {
                        id: itemList
                        anchors.fill: parent
                        anchors.margins: 4
                        model: root.filteredItems
                        spacing: 2
                        focus: true
                        clip: true

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (itemList.currentIndex >= 0 && itemList.currentIndex < root.filteredItems.length) {
                                    root.copyItem(root.filteredItems[itemList.currentIndex].id);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                itemList.currentIndex = Math.max(0, itemList.currentIndex - 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                itemList.currentIndex = Math.min(root.filteredItems.length - 1, itemList.currentIndex + 1);
                                event.accepted = true;
                            }
                        }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: parent.width; height: 40; radius: 6
                            color: {
                                if (index === itemList.currentIndex) return Theme.accent;
                                if (ma.containsMouse) return Theme.surfaceVariant;
                                return "transparent";
                            }

                            RowLayout {
                                anchors.fill: parent; anchors.margins: 6; spacing: 6

                                Text {
                                    Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                                    text: modelData.text; font.pixelSize: 11; color: Theme.fg
                                    elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap
                                }

                                Rectangle {
                                    width: 20; height: 20; radius: 4; color: Theme.background
                                    visible: ma.containsMouse

                                    Text { anchors.centerIn: parent; text: ""; font.pixelSize: 10; color: Theme.error }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.deleteItem(modelData.id)
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
                                    root.copyItem(modelData.id);
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            active: true
                            policy: ScrollBar.AsNeeded
                        }
                    }
                }
            }
        }
    }

    GlobalShortcut {
        name: "quickshell:clipboard-toggle"
        description: "Toggle Clipboard Manager"
        onPressed: root.toggle()
    }

    Component.onCompleted: { refresh() }

    function toggle() {
        overlay.visible = !overlay.visible;
        if (overlay.visible) {
            refresh();
            itemList.currentIndex = 0;
            itemList.forceActiveFocus();
        }
    }
}
