import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Item {
    id: root

    property var barWindow: null
    property var items: []
    property string filterText: ""

    readonly property var filteredItems: {
        if (filterText === "")
            return items;
        var lower = filterText.toLowerCase();
        return items.filter(function (item) {
            return item.name.toLowerCase().includes(lower) || item.exec.toLowerCase().includes(lower);
        });
    }

    Process {
        id: listProcess
        command: ["/home/ergin/.config/quickshell/list-apps.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split('\n').filter(function (l) {
                    return l.trim() !== "";
                });
                var result = [];
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split('|');
                    if (parts.length >= 2) {
                        result.push({
                            name: parts[0],
                            exec: parts[1],
                            iconPath: parts.length >= 3 ? parts[2] : ""
                        });
                    }
                }
                root.items = result;
            }
        }
    }

    PanelWindow {
        id: launcherWindow
        visible: false

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        color: "#80000000"

        Item {
            anchors.fill: parent
            focus: visible

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    launcherWindow.visible = false;
                    event.accepted = true;
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: launcherWindow.visible = false
            }

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
                        topPadding: 8
                        bottomPadding: 8
                        leftPadding: 12
                        rightPadding: 12
                        placeholderText: "Launch application..."
                        color: Theme.fg
                        placeholderTextColor: Theme.fgMuted
                        font.pixelSize: 14
                        background: Rectangle {
                            radius: 8
                            color: Theme.surface
                            border.color: Theme.border
                            border.width: 1
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
                                launcherWindow.visible = false;
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
                                    launcherWindow.visible = false;
                                    event.accepted = true;
                                }
                            }

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                width: parent.width
                                height: 44
                                radius: 8
                                color: {
                                    if (index === itemList.currentIndex)
                                        return Theme.accent;
                                    if (ma.containsMouse)
                                        return Theme.surfaceVariant;
                                    return "transparent";
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 10

                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 6
                                        color: Theme.background

                                        Image {
                                            anchors.centerIn: parent
                                            width: 24
                                            height: 24
                                            source: modelData.iconPath !== "" ? "file://" + modelData.iconPath : ""
                                            sourceSize.width: 24
                                            sourceSize.height: 24
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            visible: status === Image.Ready
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: ""
                                            font.pixelSize: 16
                                            color: Theme.fgMuted
                                            visible: modelData.iconPath === "" || parent.children[0].status !== Image.Ready
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
                                            text: modelData.exec
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
    }

    GlobalShortcut {
        name: "quickshell:launcher-toggle"
        description: "Toggle Application Launcher"
        onPressed: root.toggle()
    }

    Component.onCompleted: {}

    function toggle() {
        launcherWindow.visible = !launcherWindow.visible;
        if (launcherWindow.visible) {
            listProcess.running = true;
            searchField.text = "";
            root.filterText = "";
            itemList.currentIndex = 0;
            searchField.forceActiveFocus();
        }
    }

    function launchItem(item) {
        var cmd = item.exec;
        Quickshell.execDetached(["sh", "-c", cmd]);
        launcherWindow.visible = false;
    }
}
