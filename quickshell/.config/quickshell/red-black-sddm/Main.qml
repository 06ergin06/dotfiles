import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#0A0A0A"

    TextConstants { id: textConstants }

    Connections {
        target: sddm
        onLoginSucceeded: {
            errorText.text = textConstants.loginSucceeded
            errorText.color = "#4CAF50"
        }
        onLoginFailed: {
            errorText.text = textConstants.loginFailed
            errorText.color = "#DC143C"
        }
    }

    Repeater {
        model: screenModel
        Background {
            x: geometry.x; y: geometry.y
            width: geometry.width; height: geometry.height
            source: config.background
            fillMode: Image.PreserveAspectCrop
            onStatusChanged: {
                if (status == Image.Error && source != config.defaultBackground)
                    source = config.defaultBackground
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#CC000000"
    }

    Clock {
        id: clock
        anchors { top: parent.top; topMargin: 60; horizontalCenter: parent.horizontalCenter }
        color: "#FFFFFF"
        timeFont.pixelSize: 72
        dateFont.pixelSize: 16
        opacity: 0.85
    }

    Rectangle {
        id: loginCard
        width: 380
        height: childrenRect.height + 56
        radius: 20
        color: "#E61A1A1A"
        border.color: "#33DC143C"
        border.width: 1
        anchors.centerIn: parent

        Column {
            id: cardColumn
            anchors { left: parent.left; top: parent.top; right: parent.right; margins: 28 }
            spacing: 10

            Rectangle {
                id: avatar
                width: 68; height: 68; radius: 34
                color: "#2A2A2A"
                border.color: "#DC143C"
                border.width: 2
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.centerIn: parent
                    text: {
                        var user = userModel.lastUser || "?"
                        return user.charAt(0).toUpperCase()
                    }
                    font.pixelSize: 30; font.bold: true
                    color: "#DC143C"
                }
            }

            Text {
                text: textConstants.welcomeText.arg(sddm.hostName)
                color: "#AAAAAA"
                font.pixelSize: 13
                anchors.horizontalCenter: parent.horizontalCenter
            }

            TextBox {
                id: nameInput
                width: parent.width
                height: 42
                radius: 10
                color: "#2A2A2A"
                borderColor: "#333333"
                focusColor: "#DC143C"
                hoverColor: "#DC143C"
                textColor: "#EAEAEA"
                font.pixelSize: 14
                text: userModel.lastUser

                KeyNavigation.tab: passwordInput
                KeyNavigation.backtab: rebootBtn
            }

            PasswordBox {
                id: passwordInput
                width: parent.width
                height: 42
                radius: 10
                color: "#2A2A2A"
                borderColor: "#333333"
                focusColor: "#DC143C"
                hoverColor: "#DC143C"
                textColor: "#EAEAEA"
                font.pixelSize: 14
                tooltipBG: "#1A1A1A"

                KeyNavigation.tab: sessionCombo
                KeyNavigation.backtab: nameInput

                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        sddm.login(nameInput.text, passwordInput.text, sessionCombo.currentIndex)
                        event.accepted = true
                    }
                }
            }

            Text {
                id: errorText
                width: parent.width
                text: "\u00a0"
                font.pixelSize: 11
                color: "#AAAAAA"
                height: 14
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Button {
                id: loginBtn
                width: parent.width
                height: 42
                radius: 10
                color: "#DC143C"
                textColor: "#FFFFFF"
                text: textConstants.login
                font.pixelSize: 14
                font.bold: true

                KeyNavigation.tab: shutdownBtn
                KeyNavigation.backtab: passwordInput

                onClicked: sddm.login(nameInput.text, passwordInput.text, sessionCombo.currentIndex)
            }

            Row {
                width: parent.width
                spacing: 8

                Button {
                    id: shutdownBtn
                    width: (parent.width - 8) / 2
                    height: 34
                    radius: 8
                    color: "#1A1A1A"
                    activeColor: "#2A2A2A"
                    pressedColor: "#333333"
                    textColor: "#AAAAAA"
                    text: "\u23fb  Shutdown"
                    font.pixelSize: 11
                    onClicked: sddm.powerOff()
                    KeyNavigation.tab: rebootBtn
                    KeyNavigation.backtab: loginBtn
                }

                Button {
                    id: rebootBtn
                    width: (parent.width - 8) / 2
                    height: 34
                    radius: 8
                    color: "#1A1A1A"
                    activeColor: "#2A2A2A"
                    pressedColor: "#333333"
                    textColor: "#AAAAAA"
                    text: "\u21bb  Reboot"
                    font.pixelSize: 11
                    onClicked: sddm.reboot()
                    KeyNavigation.backtab: shutdownBtn
                    KeyNavigation.tab: nameInput
                }
            }
        }
    }

    Row {
        id: bottomBar
        anchors { bottom: parent.bottom; bottomMargin: 24; horizontalCenter: parent.horizontalCenter }
        spacing: 16
        visible: sessionModel.count > 1

        Rectangle {
            height: 30
            width: sessionLabel.width + sessionCombo.width + 24
            radius: 8
            color: "#1A1A1A"
            border.color: "#333333"
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 6
                spacing: 8

                Text {
                    id: sessionLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Session:"
                    font.pixelSize: 11
                    color: "#AAAAAA"
                }

                ComboBox {
                    id: sessionCombo
                    width: 120
                    height: 22
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 11
                    color: "#EAEAEA"
                    model: sessionModel
                    index: sessionModel.lastIndex
                    arrowIcon: "angle-down.png"
                }
            }
        }
    }

    Component.onCompleted: {
        if (nameInput.text == "")
            nameInput.focus = true
        else
            passwordInput.focus = true
    }
}
