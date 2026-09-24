import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    required property var theme

    signal lockRequested()
    signal suspendRequested()
    signal rebootRequested()
    signal powerOffRequested()
    signal cancelRequested()

    implicitWidth: menuRow.implicitWidth
    implicitHeight: 32

    Row {
        id: menuRow
        anchors.centerIn: parent
        spacing: 6

        MenuButton {
            glyph: "\uF023"
            label: "Lock"
            tint: "#9ece6a"
            theme: root.theme
            onClicked: root.lockRequested()
        }

        MenuButton {
            glyph: "\uF186"
            label: "Sleep"
            tint: "#7aa2f7"
            theme: root.theme
            onClicked: root.suspendRequested()
        }

        MenuButton {
            glyph: "\uF021"
            label: "Reboot"
            tint: "#e0af68"
            theme: root.theme
            onClicked: root.rebootRequested()
        }

        MenuButton {
            glyph: "\uF011"
            label: "Off"
            tint: "#f7768e"
            theme: root.theme
            onClicked: root.powerOffRequested()
        }

        Rectangle {
            id: cancelBtn
            width: 28
            height: 28
            radius: 14
            anchors.verticalCenter: parent.verticalCenter

            color: cancelHover.hovered ? "#1c1c1e" : "transparent"
            border.color: "#1c1c1e"
            border.width: 1

            Behavior on color { ColorAnimation { duration: 140 } }

            Text {
                anchors.centerIn: parent
                text: "\uF00D"
                color: root.theme.colMuted
                font { family: root.theme.fontFamily; pixelSize: 10; bold: true }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.cancelRequested()
            }

            HoverHandler { id: cancelHover }
        }
    }

    component MenuButton: Rectangle {
        id: btn
        required property string glyph
        required property string label
        required property color tint
        required property var theme

        signal clicked()

        width: btnRow.implicitWidth + 20
        height: 28
        radius: 14

        color: btnHover.hovered ? Qt.rgba(tint.r, tint.g, tint.b, 0.22)
                                : "#12ffffff"
        border.color: btnHover.hovered ? tint : "#1affffff"
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        Row {
            id: btnRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.glyph
                color: btn.tint
                font { family: btn.theme.fontFamily; pixelSize: 12; bold: true }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.label
                color: btn.theme.colFg
                font { family: btn.theme.fontFamily; pixelSize: 11; bold: true }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }

        HoverHandler { id: btnHover }
    }
}