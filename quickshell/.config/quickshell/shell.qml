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

        function refreshBrightness() {
            bar.refreshBrightness()
        }

        function refreshVolume() {
            bar.refreshVolume()
        }
    }
}
