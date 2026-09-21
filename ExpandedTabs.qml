import QtQuick
import QtQuick.Layouts

Column {
    id: root
    required property var island
    required property var theme
    required property var stats
    required property var pomodoro

    spacing: 10

    Row {
        id: moduleBar
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20

        Text {
            text: "\uF001  Media"
            color: root.island.activeTab === 0 ? root.theme.colFg : root.theme.colMuted
            font { family: root.theme.fontFamily; pixelSize: 12; bold: root.island.activeTab === 0 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.island.activeTab = 0 }
        }
        Text {
            text: "\uF080  Stats"
            color: root.island.activeTab === 1 ? root.theme.colFg : root.theme.colMuted
            font { family: root.theme.fontFamily; pixelSize: 12; bold: root.island.activeTab === 1 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.island.activeTab = 1 }
        }
        Text {
            text: "\uF00A  Tray"
            color: root.island.activeTab === 2 ? root.theme.colFg : root.theme.colMuted
            font { family: root.theme.fontFamily; pixelSize: 12; bold: root.island.activeTab === 2 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.island.activeTab = 2 }
        }
        Text {
            text: "\uF017  Timer"
            color: root.island.activeTab === 3 ? root.theme.colFg : root.theme.colMuted
            font { family: root.theme.fontFamily; pixelSize: 12; bold: root.island.activeTab === 3 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.island.activeTab = 3 }
        }
    }

    Rectangle {
        width: 420; height: 1
        color: root.theme.colDim
        opacity: 0.6
    }

    Item {
        id: tabContent
        width: 420
        // Timer tab needs more vertical room; other tabs stay 200.
        height: root.island.activeTab === 3 ? 300 : 200

        MediaTab {
            anchors.fill: parent
            visible: root.island.activeTab === 0
            theme: root.theme
            island: root.island
        }

        StatsTab {
            anchors.fill: parent
            visible: root.island.activeTab === 1
            theme: root.theme
            stats: root.stats
        }

        TrayTab {
            anchors.fill: parent
            visible: root.island.activeTab === 2
            theme: root.theme
            island: root.island
        }

        PomodoroTab {
            anchors.fill: parent
            visible: root.island.activeTab === 3
            theme: root.theme
            pomodoro: root.pomodoro
        }
    }
}