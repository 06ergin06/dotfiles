import QtQuick
import Quickshell
import Quickshell.Io
import "bar"
import "notifications"

ShellRoot {
    Bar {
        id: bar
    }

    NotificationRoot {}

    Launcher {
        id: launcher
    }

    MediaPlayer {
        id: media
    }

    IpcHandler {
        target: "quickshell"
        enabled: true

        function toggleEmoji() {
            bar.emojiSelector.toggle()
        }

        function toggleClipboard() {
            bar.clipboard.toggle()
        }

        function toggleLauncher() {
            launcher.toggle()
        }

        function toggleMediaPlayer() {
            media.toggle()
        }

        function refreshBrightness() {
            bar.refreshBrightness()
        }

        function refreshVolume() {
            bar.refreshVolume()
        }
    }
}
