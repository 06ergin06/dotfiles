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
    property real sinkVolume: 0
    property bool sinkMuted: false
    property real sourceVolume: 0
    property bool sourceMuted: false
    property var sinkList: []
    property var sourceList: []
    property string sinkDefaultName: ""
    property string sourceDefaultName: ""

    readonly property string icon: {
        if (sinkMuted || sinkVolume < 0.01) return ""
        if (sinkVolume < 0.33) return ""
        return ""
    }

    Timer {
        interval: 5000
        running: volMenu.visible
        repeat: true
        onTriggered: {
            sinkPoll.running = true
            srcPoll.running = true
            statusPoll.running = true
        }
    }

    function refreshVolume() { sinkPoll.running = true; srcPoll.running = true }
    function refreshStatus() { statusPoll.running = true }

    function pollDevice(proc, volProp, mutedProp, sliderRef) {
        return {
            proc: proc,
            onFinished: function(text) {
                var match = text.match(/Volume:\s*([\d.]+)/)
                if (match) {
                    root[volProp] = parseFloat(match[1])
                    if (!sliderRef.dragging) sliderRef.sliderValue = root[volProp]
                }
                root[mutedProp] = text.includes("MUTED")
            }
        }
    }

    Process {
        id: sinkPoll
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                var match = this.text.match(/Volume:\s*([\d.]+)/)
                if (match) {
                    root.sinkVolume = parseFloat(match[1])
                    if (!volSlider.dragging) volSlider.sliderValue = root.sinkVolume
                }
                root.sinkMuted = this.text.includes("MUTED")
            }
        }
    }

    Process {
        id: srcPoll
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: {
                var match = this.text.match(/Volume:\s*([\d.]+)/)
                if (match) {
                    root.sourceVolume = parseFloat(match[1])
                    if (!micSlider.dragging) micSlider.sliderValue = root.sourceVolume
                }
                root.sourceMuted = this.text.includes("MUTED")
            }
        }
    }

    Process { id: sinkSetVol; command: ["true"] }
    Process { id: sinkSetMute; command: ["true"] }
    Process { id: srcSetVol; command: ["true"] }
    Process { id: srcSetMute; command: ["true"] }
    Process { id: setDefaultSink; command: ["true"] }
    Process { id: setDefaultSource; command: ["true"] }

    Process {
        id: statusPoll
        command: ["wpctl", "status"]
        stdout: StdioCollector { onStreamFinished: root.parseDevices(this.text) }
    }

    Component.onCompleted: { sinkPoll.running = true; srcPoll.running = true }

    function setSinkVolume(v) {
        sinkVolume = v
        sinkSetVol.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)]
        sinkSetVol.running = true
    }

    function toggleSinkMute() {
        sinkMuted = !sinkMuted
        sinkSetMute.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", sinkMuted ? "1" : "0"]
        sinkSetMute.running = true
    }

    function setSourceVolume(v) {
        sourceVolume = v
        srcSetVol.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", v.toFixed(2)]
        srcSetVol.running = true
    }

    function toggleSourceMute() {
        sourceMuted = !sourceMuted
        srcSetMute.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", sourceMuted ? "1" : "0"]
        srcSetMute.running = true
    }

    function parseDevices(text) {
        var lines = text.split('\n')
        var sinks = [], sources = [], section = ""
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (line.indexOf('├─ Sinks:') >= 0) { section = "sinks"; continue }
            if (line.indexOf('├─ Sources:') >= 0) { section = "sources"; continue }
            if (line.indexOf('├─ Filters:') >= 0) { section = "filters"; continue }
            if (line.match(/^\s*[├└]─/)) { section = ""; continue }
            if (section === "") continue

            var match = line.match(/│\s+(\*)?\s*(\d+)\.\s+(.+)/)
            if (!match) continue
            var rawName = match[3].trim()
            var displayName = rawName.replace(/\s*\[.*/, '').trim()
            var id = parseInt(match[2])
            var isDefault = match[1] === '*'

            if (section === "sinks") {
                sinks.push({ id: id, name: displayName, isDefault: isDefault })
                if (isDefault) root.sinkDefaultName = displayName
            } else if (section === "sources") {
                sources.push({ id: id, name: displayName, isDefault: isDefault })
                if (isDefault) root.sourceDefaultName = displayName
            } else if (section === "filters") {
                var isSource = rawName.indexOf('Audio/Source') >= 0
                if (isSource) {
                    var cleanName = displayName
                        .replace(/[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}/, '')
                        .replace(/^[._]+/, '')
                    if (cleanName.indexOf('bluez') === 0) cleanName = "Bluetooth Headset"
                    var sourceName = cleanName + " (Mic)"
                    sources.push({ id: id, name: sourceName, isDefault: isDefault })
                    if (isDefault) root.sourceDefaultName = sourceName
                }
            }
        }
        root.sinkList = sinks
        root.sourceList = sources
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 4
        Text {
            text: root.icon
            font.pixelSize: 16; font.family: "MesloLGMDZ Nerd Font"; color: Theme.fg
        }
        Text {
            text: sinkMuted ? "Mute" : Math.round(sinkVolume * 100) + "%"
            font.pixelSize: 12
            color: sinkMuted ? Theme.error : Theme.fg
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            volMenu.visible ? volMenu.visible = false : volMenu.visible = true
            if (volMenu.visible) {
                refreshVolume()
                refreshStatus()
            }
        }
        onWheel: event => {
            var delta = event.angleDelta.y > 0 ? 0.05 : -0.05
            root.setSinkVolume(Math.max(0, Math.min(1, sinkVolume + delta)))
        }
    }

    Item {
        id: anchorPoint
        x: -40; y: root.height + 20; width: root.width; height: 1
    }

    PopupWindow {
        id: volMenu
        visible: false
        implicitWidth: 300
        implicitHeight: 300
        grabFocus: true

        anchor.window: root.barWindow
        anchor.item: anchorPoint
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Bottom

        color: "transparent"

        PopupContent {
            popupWindow: volMenu

            Flickable {
                anchors.fill: parent
                anchors.margins: 12
                contentHeight: contentColumn.height

                ColumnLayout {
                    id: contentColumn
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Output" + (sinkDefaultName ? ": " + sinkDefaultName : "")
                        font.pixelSize: 11; color: Theme.fgMuted; elide: Text.ElideRight
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 8

                        Text {
                            text: root.icon
                            font.pixelSize: 18; font.family: "MesloLGMDZ Nerd Font"
                            color: sinkMuted ? Theme.error : Theme.fg
                            Layout.preferredWidth: 22; horizontalAlignment: Text.AlignHCenter
                        }

                        SliderBar {
                            id: volSlider
                            Layout.fillWidth: true
                            sliderValue: sinkVolume
                            trackColor: sinkMuted ? Theme.error : Theme.accent
                            onMoved: root.setSinkVolume(sliderValue)
                        }

                        Rectangle {
                            width: 40; height: 24; radius: 4
                            color: sinkMuted ? "#333333" : Theme.surface
                            border.color: sinkMuted ? Theme.error : "transparent"
                            border.width: sinkMuted ? 1 : 0

                            Text {
                                anchors.centerIn: parent
                                text: "Mute"; font.pixelSize: 10
                                color: sinkMuted ? Theme.error : Theme.fg
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleSinkMute()
                            }
                        }
                    }

                    Repeater {
                        model: sinkList
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width; height: 28; radius: 4
                            color: modelData.isDefault ? Theme.surfaceVariant : "transparent"

                            RowLayout {
                                anchors.fill: parent; anchors.margins: 6; spacing: 6
                                Rectangle {
                                    width: 6; height: 6; radius: 3
                                    color: modelData.isDefault ? Theme.accent : "transparent"
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.pixelSize: 11; color: Theme.fg; elide: Text.ElideRight
                                }
                                Rectangle {
                                    width: 32; height: 16; radius: 3
                                    visible: !modelData.isDefault; color: Theme.surface
                                    Text { anchors.centerIn: parent; text: "Use"; font.pixelSize: 9; color: Theme.fg }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            setDefaultSink.command = ["wpctl", "set-default", String(modelData.id)]
                                            setDefaultSink.running = true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface }

                    Text {
                        text: "Input" + (sourceDefaultName ? ": " + sourceDefaultName : "")
                        font.pixelSize: 11; color: Theme.fgMuted; elide: Text.ElideRight
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 8

                        Text {
                            text: ""
                            font.pixelSize: 16; font.family: "MesloLGMDZ Nerd Font"
                            color: sourceMuted ? Theme.error : Theme.fg
                        }

                        SliderBar {
                            id: micSlider
                            Layout.fillWidth: true
                            sliderValue: sourceVolume
                            trackColor: sourceMuted ? Theme.error : Theme.accent
                            onMoved: root.setSourceVolume(sliderValue)
                        }

                        Rectangle {
                            width: 50; height: 24; radius: 4
                            color: sourceMuted ? "#33F38BA8" : Theme.surface

                            Text {
                                anchors.centerIn: parent
                                text: sourceMuted ? "Muted" : "Unmuted"
                                font.pixelSize: 10
                                color: sourceMuted ? "#F38BA8" : Theme.fg
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleSourceMute()
                            }
                        }
                    }

                    Repeater {
                        model: sourceList
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width; height: 28; radius: 4
                            color: modelData.isDefault ? Theme.surfaceVariant : "transparent"

                            RowLayout {
                                anchors.fill: parent; anchors.margins: 6; spacing: 6
                                Rectangle {
                                    width: 6; height: 6; radius: 3
                                    color: modelData.isDefault ? Theme.accent : "transparent"
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.pixelSize: 11; color: Theme.fg; elide: Text.ElideRight
                                }
                                Rectangle {
                                    width: 32; height: 16; radius: 3
                                    visible: !modelData.isDefault; color: Theme.surface
                                    Text { anchors.centerIn: parent; text: "Use"; font.pixelSize: 9; color: Theme.fg }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            setDefaultSource.command = ["wpctl", "set-default", String(modelData.id)]
                                            setDefaultSource.running = true
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
