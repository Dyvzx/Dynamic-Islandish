import QtQuick
import Quickshell.Hyprland

Item {
    id: root
    required property var theme
    required property var island

    readonly property var currentPlayer: root.theme.currentPlayer()

    Column {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10
        width: parent.width

        // ============ Media player ============
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14

            Rectangle {
                width: 56; height: 56; radius: 10
                color: root.theme.colBgSoft
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                Image {
                    id: artImg
                    anchors.fill: parent
                    source: {
                        var p = root.currentPlayer
                        return (p && p.trackArtUrl) ? p.trackArtUrl : ""
                    }
                    fillMode: Image.PreserveAspectCrop
                    visible: source !== "" && status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: !artImg.visible
                    text: "\uF001"
                    color: root.theme.colMuted
                    font { family: root.theme.fontFamily; pixelSize: 22 }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var p = root.currentPlayer
                        if (p) focusPlayer(p)
                    }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                width: 300

                Text {
                    id: titleText
                    width: parent.width
                    text: {
                        var p = root.currentPlayer
                        if (p && (p.trackTitle || p.trackArtists))
                            return p.trackTitle || "Unknown title"
                        if (root.island.audioMon.audioActive && root.island.audioMon.audioApp.length > 0)
                            return root.island.audioMon.audioApp
                        return "Nothing playing"
                    }
                    color: root.theme.colFg
                    font { family: root.theme.fontFamily; pixelSize: 14; bold: true }
                    elide: Text.ElideRight

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var p = root.currentPlayer
                            if (p) focusPlayer(p)
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: {
                        var p = root.currentPlayer
                        if (p && p.trackArtists)
                            return root.theme.artistString(p.trackArtists)
                        if (root.island.audioMon.audioActive)
                            return "via PipeWire"
                        return ""
                    }
                    color: root.theme.colMuted
                    font { family: root.theme.fontFamily; pixelSize: 12 }
                    elide: Text.ElideRight
                }
            }
        }

        // ============ Progress bar ============
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.theme.fmtTime(progressBar.current)
                color: root.theme.colMuted
                font { family: root.theme.fontFamily; pixelSize: 10 }
            }

            Rectangle {
                id: progressBar
                width: 280; height: 4; radius: 2
                color: root.theme.colDim
                anchors.verticalCenter: parent.verticalCenter

                property var player: root.currentPlayer
                property real total: (player && player.length > 0) ? player.length : 0
                property real current: (player && player.position) ? player.position : 0

                Connections {
                    target: progressBar.player
                    ignoreUnknownSignals: true
                    function onPositionChanged() {
                        if (progressBar.player && progressBar.player.position !== undefined)
                            progressBar.current = progressBar.player.position
                    }
                }

                Timer {
                    interval: 250
                    repeat: true
                    running: progressBar.player && progressBar.player.isPlaying
                    onTriggered: {
                        var p = progressBar.player
                        if (!p) return
                        if (p.position !== undefined &&
                            Math.abs(p.position - progressBar.current) > 1.5) {
                            progressBar.current = p.position
                        } else {
                            progressBar.current += 0.25
                        }
                        if (progressBar.total > 0 &&
                            progressBar.current > progressBar.total)
                            progressBar.current = progressBar.total
                    }
                }

                property real prog: total > 0 ? Math.min(1, current / total) : 0

                Rectangle {
                    width: parent.width * parent.prog
                    height: parent.height
                    radius: parent.radius
                    color: root.theme.colFg
                }

                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: root.theme.colFg
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width * parent.prog - width / 2
                    visible: progressMouse.containsMouse || progressMouse.pressed
                }

                MouseArea {
                    id: progressMouse
                    anchors.fill: parent
                    anchors.topMargin: -8
                    anchors.bottomMargin: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton

                    function seekTo(mx) {
                        var p = progressBar.player
                        if (!p || !progressBar.total || progressBar.total <= 0) return
                        if (!p.canSeek) return
                        var ratio = Math.max(0, Math.min(1, mx / progressBar.width))
                        var target = ratio * progressBar.total
                        progressBar.current = target
                        p.position = target
                    }

                    onClicked: function(mouse) { seekTo(mouse.x) }
                    onPositionChanged: function(mouse) { if (pressed) seekTo(mouse.x) }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.theme.fmtTime(progressBar.total)
                color: root.theme.colMuted
                font { family: root.theme.fontFamily; pixelSize: 10 }
            }
        }

        // ============ Transport controls ============
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 30

            Text {
                text: "\uF048"
                color: root.theme.colFg
                font { family: root.theme.fontFamily; pixelSize: 18 }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { var p = root.currentPlayer; if (p && p.canGoPrevious) p.previous() }
                }
            }
            Text {
                text: {
                    var p = root.currentPlayer
                    return (p && p.isPlaying) ? "\uF04C" : "\uF04B"
                }
                color: root.theme.colFg
                font { family: root.theme.fontFamily; pixelSize: 22 }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { var p = root.currentPlayer; if (p && p.canTogglePlaying) p.togglePlaying() }
                }
            }
            Text {
                text: "\uF051"
                color: root.theme.colFg
                font { family: root.theme.fontFamily; pixelSize: 18 }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { var p = root.currentPlayer; if (p && p.canGoNext) p.next() }
                }
            }
        }
    }

    // ============ Feature toggles ============
    // Row of three buttons, centered horizontally, sitting just above
    // the workspaces row.
    //   [ hide island ]  [ media pop-ups ]  [ notifications ]
    Row {
        id: toggleRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: wsContainer.top
        anchors.bottomMargin: 8
        spacing: 10

        // ---- 1. Hide-island toggle ----
        Rectangle {
            id: hideBtn
            width: 26; height: 26; radius: 13

            readonly property bool active:
                root.island !== undefined &&
                root.island.islandState !== undefined &&
                root.island.islandState.islandHidden

            color: active ? "#2affffff" : "#12ffffff"
            border.color: active ? "#4affffff" : "#1affffff"
            border.width: 1

            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 160 } }

            Text {
                anchors.centerIn: parent
                text: "\uF065"
                color: hideBtn.active ? "#ffffff" : root.theme.colMuted
                font { family: root.theme.fontFamily; pixelSize: 13; bold: true }
                Behavior on color { ColorAnimation { duration: 160 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.island && root.island.islandState)
                        root.island.islandState.toggleIslandHidden()
                }
            }

            Rectangle {
                visible: hideHover.hovered
                color: "#2a2a2a"
                radius: 4
                border.color: root.theme.colMuted
                border.width: 1
                anchors.top: parent.bottom
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                width: hideTip.width + 12
                height: hideTip.height + 6
                z: 10

                Text {
                    id: hideTip
                    anchors.centerIn: parent
                    text: hideBtn.active ? "Hide island: ON" : "Hide island: OFF"
                    color: root.theme.colFg
                    font { family: root.theme.fontFamily; pixelSize: 11 }
                }
            }

            HoverHandler { id: hideHover }
        }

        // ---- 2. Media pop-ups toggle ----
        Rectangle {
            id: mediaPopupBtn
            width: 26; height: 26; radius: 13

            readonly property bool active:
                root.island !== undefined &&
                root.island.islandState !== undefined &&
                root.island.islandState.mediaPopupsEnabled

            color: active ? "#2a30d158" : "#12ffffff"
            border.color: active ? "#5530d158" : "#1affffff"
            border.width: 1

            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 160 } }

            Text {
                anchors.centerIn: parent
                text: "\uF001"
                color: mediaPopupBtn.active ? "#30d158" : root.theme.colMuted
                font { family: root.theme.fontFamily; pixelSize: 13; bold: true }
                Behavior on color { ColorAnimation { duration: 160 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.island && root.island.islandState)
                        root.island.islandState.toggleMediaPopups()
                }
            }

            Rectangle {
                visible: mediaPopupHover.hovered
                color: "#2a2a2a"
                radius: 4
                border.color: root.theme.colMuted
                border.width: 1
                anchors.top: parent.bottom
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                width: mediaPopupTip.width + 12
                height: mediaPopupTip.height + 6
                z: 10

                Text {
                    id: mediaPopupTip
                    anchors.centerIn: parent
                    text: mediaPopupBtn.active
                        ? "Media pop-ups: ON"
                        : "Media pop-ups: OFF"
                    color: root.theme.colFg
                    font { family: root.theme.fontFamily; pixelSize: 11 }
                }
            }

            HoverHandler { id: mediaPopupHover }
        }

        // ---- 3. Notifications toggle ----
        Rectangle {
            id: notifBtn
            width: 26; height: 26; radius: 13

            readonly property bool active:
                root.island !== undefined &&
                root.island.islandState !== undefined &&
                root.island.islandState.notificationsEnabled

            color: active ? "#2af7768e" : "#12ffffff"
            border.color: active ? "#55f7768e" : "#1affffff"
            border.width: 1

            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 160 } }

            Text {
                anchors.centerIn: parent
                text: "\uF0F3"
                color: notifBtn.active ? "#f7768e" : root.theme.colMuted
                font { family: root.theme.fontFamily; pixelSize: 13; bold: true }
                Behavior on color { ColorAnimation { duration: 160 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.island && root.island.islandState)
                        root.island.islandState.toggleNotifications()
                }
            }

            Rectangle {
                visible: notifHover.hovered
                color: "#2a2a2a"
                radius: 4
                border.color: root.theme.colMuted
                border.width: 1
                anchors.top: parent.bottom
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                width: notifTip.width + 12
                height: notifTip.height + 6
                z: 10

                Text {
                    id: notifTip
                    anchors.centerIn: parent
                    text: notifBtn.active
                        ? "Notifications: ON"
                        : "Notifications: OFF"
                    color: root.theme.colFg
                    font { family: root.theme.fontFamily; pixelSize: 11 }
                }
            }

            HoverHandler { id: notifHover }
        }
    }

    // ============ Workspaces ============
    WorkspaceRow {
        id: wsContainer
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        theme: root.theme
    }

    function focusPlayer(player) {
        if (!player) return
        var id = player.identity || ""
        if (id.length === 0) return
        var classMap = {
            "Brave": "brave-browser", "Mozilla Firefox": "firefox", "Firefox": "firefox",
            "Chromium": "chromium", "Google Chrome": "google-chrome",
            "VLC media player": "vlc", "Spotify": "Spotify", "mpv": "mpv", "Discord": "discord"
        }
        var cls = classMap[id] || id
        Hyprland.dispatch("hl.dsp.focus({ window = \"class:" + cls + "\" })")
    }
}