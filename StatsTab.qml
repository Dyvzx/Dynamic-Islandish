import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    required property var theme
    required property var stats

    QtObject {
        id: tabStats
        property int volume: 0
        property bool muted: false
        function updateVolume() { volumeProcTab.running = true }

        property Process volumeProcTab: Process {
            command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
            stdout: SplitParser {
                onRead: data => {
                    if (!data) return
                    var parts = data.trim().split(/\s+/)
                    if (parts.length >= 2) {
                        var vol = parseFloat(parts[1])
                        if (!isNaN(vol)) tabStats.volume = Math.round(vol * 100)
                        tabStats.muted = data.includes("[MUTED]")
                    }
                }
            }
            Component.onCompleted: running = true
        }
        property Process muteProcTab: Process {
            command: ["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"]
            stdout: StdioCollector { onStreamFinished: tabStats.updateVolume() }
        }
        property Process upProcTab: Process {
            command: ["sh", "-c", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+"]
            stdout: StdioCollector { onStreamFinished: tabStats.updateVolume() }
        }
        property Process downProcTab: Process {
            command: ["sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"]
            stdout: StdioCollector { onStreamFinished: tabStats.updateVolume() }
        }
        property Timer tick: Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: tabStats.updateVolume()
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 10

        Rectangle {
            id: cpuCard
            width: 140; height: 96; radius: 14
            color: "#12ffffff"
            border.color: "#1affffff"
            border.width: 1
            property real ratio: Math.max(0, Math.min(1, root.stats.cpuUsage / 100))

            Column {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "CPU"
                    color: root.theme.colMuted
                    font { family: root.theme.fontFamily; pixelSize: 11; bold: true }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.stats.cpuUsage + "%"
                    color: "#ffffff"
                    font { family: root.theme.fontFamily; pixelSize: 22; bold: true }
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 92; height: 3; radius: 1.5
                    color: "#1c1c1e"
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * cpuCard.ratio
                        height: parent.height
                        radius: parent.radius
                        color: "#ffffff"
                        Behavior on width { NumberAnimation { duration: 260 } }
                    }
                }
            }
        }

        Rectangle {
            id: memCard
            width: 140; height: 96; radius: 14
            color: "#12ffffff"
            border.color: "#1affffff"
            border.width: 1
            property real ratio: root.stats.totalMemGB > 0
                ? Math.max(0, Math.min(1, root.stats.usedMemGB / root.stats.totalMemGB))
                : 0

            Column {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "MEM"
                    color: root.theme.colMuted
                    font { family: root.theme.fontFamily; pixelSize: 11; bold: true }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.stats.usedMemGB.toFixed(1) + "G"
                    color: "#ffffff"
                    font { family: root.theme.fontFamily; pixelSize: 22; bold: true }
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 92; height: 3; radius: 1.5
                    color: "#1c1c1e"
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * memCard.ratio
                        height: parent.height
                        radius: parent.radius
                        color: "#ffffff"
                        Behavior on width { NumberAnimation { duration: 260 } }
                    }
                }
            }
        }

        Rectangle {
            id: volCard
            width: 140; height: 96; radius: 14
            color: "#12ffffff"
            border.color: "#1affffff"
            border.width: 1
            property real ratio: Math.max(0, Math.min(1, tabStats.volume / 100))

            Column {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tabStats.muted ? "VOL (muted)" : "VOL"
                    color: root.theme.colMuted
                    font { family: root.theme.fontFamily; pixelSize: 11; bold: true }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tabStats.muted ? "MUTED" : (tabStats.volume + "%")
                    color: "#ffffff"
                    font {
                        family: root.theme.fontFamily
                        pixelSize: tabStats.muted ? 16 : 22
                        bold: true
                    }
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 92; height: 3; radius: 1.5
                    color: "#1c1c1e"
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * volCard.ratio
                        height: parent.height
                        radius: parent.radius
                        color: "#ffffff"
                        Behavior on width { NumberAnimation { duration: 260 } }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                onClicked: tabStats.muteProcTab.running = true
                onWheel: function(w) {
                    if (w.angleDelta.y > 0) tabStats.upProcTab.running = true
                    else tabStats.downProcTab.running = true
                }
            }
        }
    }
}