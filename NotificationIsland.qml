import QtQuick

Item {
    id: notifIsland
    required property var theme
    required property var notif       // the notification object
    required property color accent    // ring color (matches island)

    implicitWidth: contentRow.implicitWidth
    implicitHeight: contentRow.implicitHeight

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 12

        // ---- App icon / fallback glyph ----
        Rectangle {
            width: 28; height: 28; radius: 8
            color: "#1c1c1e"
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: iconImg
                anchors.fill: parent
                anchors.margins: 4
                source: notifIsland.notif && notifIsland.notif.appIcon
                    ? notifIsland.notif.appIcon : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: source !== "" && status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: !iconImg.visible
                text: "\uF0F3"   // bell icon
                color: notifIsland.accent
                font { family: notifIsland.theme.fontFamily; pixelSize: 14 }
            }
        }

        // ---- Text column ----
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            width: Math.min(420, Math.max(summaryText.implicitWidth,
                                          bodyText.implicitWidth))

            Text {
                id: summaryText
                width: parent.width
                text: notifIsland.notif ? (notifIsland.notif.summary || "") : ""
                color: notifIsland.theme.colFg
                font { family: notifIsland.theme.fontFamily; pixelSize: 13; bold: true }
                elide: Text.ElideRight
            }
            Text {
                id: bodyText
                width: parent.width
                text: notifIsland.notif ? (notifIsland.notif.body || "") : ""
                color: notifIsland.theme.colMuted
                font { family: notifIsland.theme.fontFamily; pixelSize: 11 }
                elide: Text.ElideRight
                visible: text !== ""
            }
        }

        // ---- Dismiss "X" ----
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\uF00D"
            color: notifIsland.theme.colMuted
            font { family: notifIsland.theme.fontFamily; pixelSize: 12 }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: notifIsland.dismissRequested()
            }
        }
    }

    signal dismissRequested()
}
