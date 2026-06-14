import QtQuick

Item {
    id: sliderRoot
    implicitHeight: 20
    implicitWidth: 100

    property real sliderValue: 0
    property bool dragging: false
    property color trackColor: "#888"

    signal moved

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: 4
        radius: 2
        color: "#555"
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        height: 4
        radius: 2
        color: trackColor
        width: handleItem.x + handleItem.width / 2
    }

    Rectangle {
        id: handleItem
        x: (sliderRoot.width - width) * sliderValue
        y: sliderRoot.height / 2 - height / 2
        width: 14
        height: 14
        radius: 7
        color: "#FFFFFF"
        Behavior on x {
            enabled: !sliderRoot.dragging
            NumberAnimation {
                duration: 80
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => {
            sliderRoot.dragging = true;
            var frac = Math.max(0, Math.min(1, mouse.x / sliderRoot.width));
            sliderRoot.sliderValue = frac;
            sliderRoot.moved();
        }
        onPositionChanged: mouse => {
            if (pressed) {
                var frac = Math.max(0, Math.min(1, mouse.x / sliderRoot.width));
                sliderRoot.sliderValue = frac;
                sliderRoot.moved();
            }
        }
        onReleased: {
            sliderRoot.dragging = false;
        }
    }
}
