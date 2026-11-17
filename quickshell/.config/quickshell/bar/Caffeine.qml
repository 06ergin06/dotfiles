import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    implicitWidth: 20
    implicitHeight: 20

    property bool active: false

    // Sadece açılışta bir kez kontrol et; sonrasında durum tıklamayla takip edilir.
    // 2 sn'lik-repeat Timer hem boşa process doğuruyordu hem de eski Qt API
    // uyarılarına (Process.Buffer / onExited paramsiz) yol açıyordu.
    Process {
        id: checkProcess
        command: ["pidof", "hypridle"]
        onExited: (exitCode, exitStatus) => {
            root.active = (exitCode !== 0)
        }
    }

    Timer {
        id: startupCheck
        interval: 1000
        repeat: false
        onTriggered: checkProcess.running = true
    }

    Component.onCompleted: startupCheck.start()

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
