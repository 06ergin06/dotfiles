import QtQuick

Rectangle {
    id: root
    property var popupWindow

    anchors.fill: parent
    focus: true
    color: Theme.background
    radius: Theme.barRadius
    border.color: Theme.border
    border.width: 1

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape && root.popupWindow) {
            root.popupWindow.visible = false
            event.accepted = true
        }
    }

    onActiveFocusChanged: {
        if (!activeFocus && root.popupWindow && root.popupWindow.visible)
            root.popupWindow.visible = false
    }
}
