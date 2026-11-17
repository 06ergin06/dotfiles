import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    implicitWidth: 20
    implicitHeight: 20

    property bool active: false

    Process {
        id: checkProcess
        command: ["pidof", "hypridle"]
        stdout: Process.Buffer
        onExited: {
            root.active = (exitCode !== 0); // If pidof fails (exit code 1), hypridle is not running -> active = true
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: checkProcess.running = true
        Component.onCompleted: checkProcess.running = true
    }

    Text {
        anchors.centerIn: parent
        text: ""
        font.pixelSize: 14
        font.family: "MesloLGMDZ Nerd Font"
        color: active ? "#F9E2AF" : Theme.fg // Yellow when caffeine is active
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.active) {
                Quickshell.execDetached(["sh", "-c", "hyprctl dispatch 'hl.dsp.exec_cmd(\"hypridle\")'"])
                root.active = false
            } else {
                Quickshell.execDetached(["pkill", "hypridle"])
                root.active = true
            }
        }
    }
}
