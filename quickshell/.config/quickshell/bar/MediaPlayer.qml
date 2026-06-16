import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win
    visible: false

    // Screen selection based on focus
    property var activeScreen: {
        const monName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === monName)
                return Quickshell.screens[i];
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    screen: activeScreen

    anchors.left: true

    implicitWidth: 280
    implicitHeight: 340
    color: "transparent"

    // Wayland Layer Shell settings
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    property bool active: false

    function toggle() {
        if (active) {
            active = false;
        } else {
            win.screen = activeScreen;
            win.visible = true;
            active = true;
        }
    }

    // Media properties
    property string playbackStatus: "Offline"
    property string trackTitle: "No media playing"
    property string trackArtist: ""
    property string trackArt: ""
    property int activeArt: 0 // 0 = placeholder, 1 = art1, 2 = art2

    onTrackArtChanged: {
        if (trackArt === "") {
            activeArt = 0;
            art1.source = "";
            art2.source = "";
            return;
        }

        if (activeArt === 1) {
            art2.source = trackArt;
        } else {
            art1.source = trackArt;
        }
    }

    function parseMetadata(data) {
        var parts = data.trim().split("||");
        if (parts.length >= 3) {
            playbackStatus = parts[0];
            var newTitle = parts[1] !== "" ? parts[1] : "Unknown Title";
            var newArtist = parts[2];
            var newArt = (parts.length >= 4 && parts[3] !== "") ? parts[3] : "";

            // If the song is the same, we lock the cover art to prevent downgrading.
            // We only update it if we didn't have a cover loaded yet (trackArt was empty).
            if (newTitle === trackTitle && newArtist === trackArtist) {
                if (trackArt === "" && newArt !== "") {
                    trackArt = newArt;
                }
            } else {
                // Different song! Accept the new cover art (even if empty).
                trackArt = newArt;
            }

            trackTitle = newTitle;
            trackArtist = newArtist;
        }
    }

    Process {
        id: metadataProcess
        command: ["sh", "-c", "while true; do playerctl metadata --follow --format '{{status}}||{{title}}||{{artist}}||{{mpris:artUrl}}' 2>/dev/null; echo 'Offline||No media playing||||'; sleep 3; done"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                win.parseMetadata(data);
            }
        }
    }

    Rectangle {
        id: card
        width: 260
        height: 320
        radius: Theme.barRadius
        color: Theme.background
        border.color: Theme.border
        border.width: 1

        anchors.verticalCenter: parent.verticalCenter
        x: active ? 10 : -width - 20

        Behavior on x {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutQuint
            }
        }

        onXChanged: {
            if (!active && x <= -width) {
                win.visible = false;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // Album Art Container (Centered, Square)
            Rectangle {
                width: 170
                height: 170
                radius: 12
                color: Theme.surface
                clip: true
                Layout.alignment: Qt.AlignHCenter

                // First image layer for cross-fade
                Image {
                    id: art1
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    cache: false
                    opacity: win.activeArt === 1 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    onStatusChanged: {
                        if (status === Image.Ready) {
                            win.activeArt = 1;
                        }
                    }
                }

                // Second image layer for cross-fade
                Image {
                    id: art2
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    cache: false
                    opacity: win.activeArt === 2 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    onStatusChanged: {
                        if (status === Image.Ready) {
                            win.activeArt = 2;
                        }
                    }
                }

                // Placeholder icon
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.pixelSize: 56
                    font.family: "MesloLGMDZ Nerd Font"
                    color: Theme.fgMuted
                    opacity: win.activeArt === 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
            }

            // Metadata info (Centered Text)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Layout.alignment: Qt.AlignHCenter

                Text {
                    Layout.fillWidth: true
                    text: win.trackTitle
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.fg
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: win.trackArtist !== "" ? win.trackArtist : "Unknown Artist"
                    font.pixelSize: 11
                    color: Theme.fgMuted
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    visible: win.playbackStatus !== "Offline"
                }
            }

            // Playback Controls (Centered Buttons)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 24

                // Previous Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: prevMa.containsMouse ? Theme.surfaceVariant : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.pixelSize: 14
                        font.family: "MesloLGMDZ Nerd Font"
                        color: prevMa.containsMouse ? Theme.accent : Theme.fg
                    }

                    MouseArea {
                        id: prevMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["playerctl", "previous"])
                    }
                }

                // Play/Pause Button
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: Theme.surface

                    Text {
                        anchors.centerIn: parent
                        text: win.playbackStatus === "Playing" ? "" : ""
                        font.pixelSize: 14
                        font.family: "MesloLGMDZ Nerd Font"
                        color: playMa.containsMouse ? Theme.accent : Theme.fg
                    }

                    MouseArea {
                        id: playMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["playerctl", "play-pause"])
                    }
                }

                // Next Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: nextMa.containsMouse ? Theme.surfaceVariant : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.pixelSize: 14
                        font.family: "MesloLGMDZ Nerd Font"
                        color: nextMa.containsMouse ? Theme.accent : Theme.fg
                    }

                    MouseArea {
                        id: nextMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["playerctl", "next"])
                    }
                }
            }
        }
    }

    GlobalShortcut {
        name: "quickshell:mediaplayer-toggle"
        description: "Toggle Media Player Overlay"
        onPressed: win.toggle()
    }
}
