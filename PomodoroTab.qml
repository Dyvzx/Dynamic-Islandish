import QtQuick

Item {
    id: root
    required property var theme
    required property var pomodoro

    readonly property string display:
        root.pomodoro ? root.pomodoro.display : "00:00"
    readonly property real progress:
        root.pomodoro ? (root.pomodoro.progress || 0) : 0
    readonly property string state:
        root.pomodoro ? root.pomodoro.state : "idle"

    // Presets: 30 s, 1 min, 5 min. Clicking ADDS to the current total.
    readonly property var presets: [
        { secs: 30,     value: "30", unit: "sec" },
        { secs: 60,     value: "1",  unit: "min" },
        { secs: 5 * 60, value: "5",  unit: "min" }
    ]

    Row {
        anchors.centerIn: parent
        spacing: 24

        // ============================================================
        // LEFT: running timer display and progress
        // ============================================================
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            width: 260

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.display
                color: "#ffffff"
                font { family: root.theme.fontFamily; pixelSize: 44; bold: true }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width; height: 6; radius: 3
                color: "#1c1c1e"

                Rectangle {
                    width: parent.width * root.progress
                    height: parent.height
                    radius: parent.radius
                    color: root.theme.colGreen
                    Behavior on width { NumberAnimation { duration: 250 } }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.state === "running"  ? "Running"
                    : root.state === "finished" ? "Done"
                    : "Ready"
                color: root.theme.colMuted
                font { family: root.theme.fontFamily; pixelSize: 12 }
            }
        }

        // ============================================================
        // RIGHT: stacked Google-Timer-style preset buttons + Start
        // ============================================================
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Repeater {
                model: root.presets

                Rectangle {
                    id: presetBtn
                    width: 120
                    height: 52
                    radius: 10

                    color: "#12ffffff"
                    border.color: "#1affffff"
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.value
                            color: "#ffffff"
                            font {
                                family: root.theme.fontFamily
                                pixelSize: 20
                                bold: true
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.unit
                            color: root.theme.colMuted
                            font {
                                family: root.theme.fontFamily
                                pixelSize: 10
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.pomodoro) return
                            // Add this preset's seconds to the current
                            // total. Each click accumulates.
                            root.pomodoro.addPreset(modelData.secs)
                        }
                    }
                }
            }

            // ----- Start / Pause / Restart button -----
            Rectangle {
                id: startBtn
                width: 120; height: 40; radius: 20
                color: "#2affffff"
                border.color: "#4affffff"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.state === "running"  ? "Pause"
                        : root.state === "finished" ? "Restart"
                        : "Start"
                    color: "#ffffff"
                    font { family: root.theme.fontFamily; pixelSize: 13; bold: true }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.pomodoro) return
                        if (root.pomodoro.state === "running")
                            root.pomodoro.pause()
                        else
                            root.pomodoro.start()
                    }
                }
            }

            // ----- Reset button -----
            Rectangle {
                width: 120; height: 30; radius: 15
                color: "#12ffffff"
                border.color: "#1affffff"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Reset"
                    color: root.theme.colFg
                    font { family: root.theme.fontFamily; pixelSize: 12 }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (root.pomodoro) root.pomodoro.reset() }
                }
            }
        }
    }
}