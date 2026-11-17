pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property int temperature: 4000

    property int _pendingTemp: 4000

    // hyprsunset arka planda çalışan bir daemon; renk sıcaklığını
    // Hyprland'in CTM arayüzü üzerinden uygular (shader derlemesi yok).
    Process {
        id: daemon
        command: ["hyprsunset", "--identity"]
        running: false
        onExited: (exitCode, exitStatus) => restartTimer.start()
    }

    Timer {
        id: restartTimer
        interval: 1000
        repeat: false
        onTriggered: if (!daemon.running) daemon.running = true
    }

    // Başlangıçta daemon zaten çalışıyorsa ikinci bir tane başlatma.
    Process {
        id: findDaemon
        command: ["pgrep", "-x", "hyprsunset"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() === "") {
                    daemon.running = true
                } else {
                    root._ipc(["identity"])
                }
            }
        }
    }

    Process {
        id: ipc
        command: ["true"]
    }

    // Sürükleme sırasında her harekette hyprctl süreci açmamak için
    // ~16 güncelleme/sn'ye yumuşak throttle.
    Timer {
        id: tempThrottle
        interval: 60
        repeat: false
        onTriggered: root._applyTemperature(root._pendingTemp)
    }

    function _ipc(args) {
        ipc.command = ["hyprctl", "hyprsunset"].concat(args)
        ipc.running = true
    }

    function _applyTemperature(t) {
        var clamped = Math.max(3000, Math.min(6500, Math.round(t)))
        root.temperature = clamped
        if (root.active)
            root._ipc(["temperature", String(clamped)])
    }

    function setTemperature(t) {
        root._applyTemperature(t)
    }

    function setTemperatureThrottled(t) {
        root._pendingTemp = Math.max(3000, Math.min(6500, Math.round(t)))
        root.temperature = root._pendingTemp
        if (!tempThrottle.running)
            tempThrottle.start()
    }

    function setEnabled(enabled) {
        root.active = enabled
        if (enabled) {
            root._applyTemperature(root.temperature)
        } else {
            root._ipc(["identity"])
        }
    }

    function toggle() {
        root.setEnabled(!root.active)
    }

    Component.onCompleted: {
        findDaemon.running = true
    }
}
