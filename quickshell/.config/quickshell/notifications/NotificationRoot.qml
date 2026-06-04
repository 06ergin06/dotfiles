import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../bar"

Scope {
    id: root

    Connections {
        target: DnDManager

        function onDndEnabledChanged() {
            if (DnDManager.dndEnabled) {
                var children = notifColumn.children
                for (var i = children.length - 1; i >= 0; i--) {
                    var child = children[i]
                    if (child.hasOwnProperty("dismissGracefully")) {
                        child.dismissGracefully()
                    }
                }
            }
        }
    }

    NotificationServer {
        id: notifServer
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        persistenceSupported: true
        imageSupported: true

        onNotification: (notification) => {
            if (DnDManager.dndEnabled) return
            notification.tracked = true

            var bubble = bubbleComponent.createObject(notifColumn, {
                notification: notification
            })
        }

        Component.onCompleted: {
            Quickshell.execDetached(["bash", "-c", "systemctl --user stop mako 2>/dev/null; true"])
        }
    }

    Component {
        id: bubbleComponent

        NotificationBubble {
            width: notifWindow.width - Theme.barPaddingH * 2

            onDismissed: {
                if (typeof notification.dismiss === "function") {
                    notification.dismiss()
                }
            }
        }
    }

    PanelWindow {
        id: notifWindow
        anchors {
            top: true
            right: true
        }
        implicitWidth: 380
        implicitHeight: notifColumn.children.length > 0
            ? Math.min(notifColumn.height + notifColumn.anchors.topMargin + 8, 600)
            : 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.exclusiveZone: 0

        Behavior on implicitHeight {
            NumberAnimation { duration: 200 }
        }

        Column {
            id: notifColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: Theme.barHeight + 4
            }
            spacing: 6
        }
    }
}
