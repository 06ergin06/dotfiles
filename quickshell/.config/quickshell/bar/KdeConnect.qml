import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell._Window

Item {
    id: root

    property var barWindow: null
    property var devices: []
    implicitWidth: barIcon.implicitWidth
    implicitHeight: barIcon.implicitHeight

    property int connectedCount: {
        var count = 0;
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].isReachable)
                count++;
        }
        return count;
    }

    readonly property string icon: connectedCount > 0 ? "" : ""

    function refreshDevices() {
        listDevices.running = true;
    }

    Process {
        id: listDevices
        command: ["kdeconnect-cli", "--list-devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split('\n').filter(function (l) {
                    return l.trim() !== "";
                });
                var result = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i];
                    if (line.match(/^\d+ device/) || line.includes("No devices"))
                        continue;
                    var name = "", id = "", statusText = "";
                    var match = line.match(/^- (.+?): (.+?) on /);
                    if (match) {
                        name = match[1].trim();
                        id = match[2].trim();
                    }
                    var parMatch = line.match(/\((.+)\)$/);
                    if (parMatch)
                        statusText = parMatch[1];
                    if (name !== "" && id !== "") {
                        result.push({
                            name: name,
                            id: id,
                            status: statusText,
                            isReachable: statusText.includes("reachable"),
                            isPaired: statusText.includes("paired"),
                            battery: "",
                            batteryLow: false
                        });
                    }
                }
                root.devices = result;
                fetchAllBattery();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    console.warn("kdeconnect-cli stderr:", text);
            }
        }
    }

    property var _batteryQueue: []
    property var _deviceBackup: []

    function fetchAllBattery() {
        _deviceBackup = devices.slice();
        _batteryQueue = [];
        for (var i = 0; i < devices.length; i++)
            _batteryQueue.push({
                deviceId: devices[i].id,
                index: i
            });
        fetchNextBattery();
    }

    function fetchNextBattery() {
        if (_batteryQueue.length === 0) {
            root.devices = _deviceBackup;
            return;
        }
        var next = _batteryQueue[0];
        getBatteryProc.command = ["sh", "-c", "kdeconnect-cli --device \"" + next.deviceId + "\" --battery 2>/dev/null | head -5"];
        getBatteryProc.running = true;
    }

    function onBatteryResult(text) {
        var next = _batteryQueue.shift();
        if (!next) {
            fetchNextBattery();
            return;
        }
        var idx = next.index;
        if (idx >= 0 && idx < _deviceBackup.length) {
            var batMatch = text.match(/charge:\s*(\d+)/i);
            if (batMatch) {
                _deviceBackup[idx] = Object.assign({}, _deviceBackup[idx]);
                _deviceBackup[idx].battery = batMatch[1] + "%";
                _deviceBackup[idx].batteryLow = parseInt(batMatch[1]) < 20;
            }
        }
        fetchNextBattery();
    }

    Process {
        id: getBatteryProc
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: root.onBatteryResult(text)
        }
        stderr: StdioCollector {
            onStreamFinished: root.onBatteryResult("")
        }
    }

    function sendFile(deviceId) {
        Quickshell.execDetached(["sh", "-c", 'file=$(zenity --file-selection --title="Select file to send") && [ -n "$file" ] && kdeconnect-cli --device "' + deviceId + '" --share "$file"']);
    }

    function sendSms(deviceId, deviceName) {
        Quickshell.execDetached(["sh", "-c", 'msg=$(zenity --entry --title="SMS to ' + deviceName + '" --text="Message:" --width=400) && [ -n "$msg" ] && phone=$(zenity --entry --title="Phone Number" --text="Number:") && [ -n "$phone" ] && kdeconnect-cli --device "' + deviceId + '" --send-sms "$msg" --destination "$phone"']);
    }

    function pingDevice(deviceId) {
        Quickshell.execDetached(["kdeconnect-cli", "--device", deviceId, "--ping"]);
    }

    function browseDevice(deviceId) {
        Quickshell.execDetached(["kdeconnect-cli", "--device", deviceId, "--list-notifications"]);
    }

    Component.onCompleted: refreshDevices()

    Text {
        id: barIcon
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: 14
        color: Theme.fg
    }

    Item {
        id: anchorPoint
        x: -80
        y: root.height + 16
        width: root.width
        height: 1
    }

    PopupWindow {
        id: kdePopup
        visible: false
        implicitWidth: 340
        implicitHeight: 400
        grabFocus: true

        anchor.window: root.barWindow
        anchor.item: anchorPoint
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Bottom

        color: "transparent"

        PopupContent {
            popupWindow: kdePopup

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: root.icon
                        font.pixelSize: 16
                        color: Theme.fg
                    }
                    Text {
                        text: "KDE Connect"
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.fg
                        Layout.fillWidth: true
                    }
                    Text {
                        text: connectedCount > 0 ? connectedCount + " connected" : "No devices"
                        font.pixelSize: 10
                        color: connectedCount > 0 ? Theme.accent : Theme.fgMuted
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.surface
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 6
                    color: Theme.surface
                    clip: true

                    ListView {
                        anchors.fill: parent
                        anchors.margins: 4
                        model: root.devices
                        spacing: 4

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: parent.width
                            height: 60
                            radius: 8
                            color: ma.containsMouse ? Theme.surfaceVariant : "transparent"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: modelData.isReachable ? "" : ""
                                        font.pixelSize: 14
                                        color: modelData.isReachable ? Theme.accent : Theme.fgMuted
                                    }
                                    Text {
                                        text: modelData.name
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Theme.fg
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: modelData.battery
                                        font.pixelSize: 10
                                        color: modelData.batteryLow ? Theme.error : Theme.fgMuted
                                        visible: modelData.battery !== ""
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Rectangle {
                                        height: 20
                                        width: 40
                                        radius: 4
                                        color: Theme.background
                                        visible: modelData.isReachable

                                        Text {
                                            anchors.centerIn: parent
                                            text: ""
                                            font.pixelSize: 10
                                            color: Theme.fg
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.pingDevice(modelData.id)
                                        }
                                        ToolTip {
                                            visible: ma.containsMouse && modelData.isReachable
                                            text: "Ping device"
                                            delay: 800
                                        }
                                    }

                                    Rectangle {
                                        height: 20
                                        width: 40
                                        radius: 4
                                        color: Theme.background
                                        visible: modelData.isReachable

                                        Text {
                                            anchors.centerIn: parent
                                            text: ""
                                            font.pixelSize: 10
                                            color: Theme.fg
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.sendFile(modelData.id)
                                        }
                                        ToolTip {
                                            visible: ma.containsMouse && modelData.isReachable
                                            text: "Send file"
                                            delay: 800
                                        }
                                    }

                                    Rectangle {
                                        height: 20
                                        width: 40
                                        radius: 4
                                        color: Theme.background
                                        visible: modelData.isReachable

                                        Text {
                                            anchors.centerIn: parent
                                            text: ""
                                            font.pixelSize: 10
                                            color: Theme.fg
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.sendSms(modelData.id, modelData.name)
                                        }
                                        ToolTip {
                                            visible: ma.containsMouse && modelData.isReachable
                                            text: "Send SMS"
                                            delay: 800
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: 6
                    color: Theme.surface

                    Text {
                        anchors.centerIn: parent
                        text: " Refresh"
                        font.pixelSize: 11
                        color: Theme.fg
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.refreshDevices()
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            kdePopup.visible = !kdePopup.visible;
            if (kdePopup.visible)
                refreshDevices();
        }
    }
}
