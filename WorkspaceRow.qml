import QtQuick
import Quickshell.Hyprland

Item {
    id: wsContainer
    required property var theme

    width: wsRow.implicitWidth + 24
    height: 26
    z: 200

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "#12ffffff"
        border.color: "#1affffff"
        border.width: 1
    }

    Rectangle {
        id: activePill
        height: parent.height - 8
        y: 4
        width: 24
        radius: height / 2
        color: "#2affffff"
        visible: Hyprland.focusedWorkspace !== null

        x: {
            if (Hyprland.focusedWorkspace === null) return 0
            var idx = Hyprland.focusedWorkspace.id - 1
            if (idx < 0 || idx > 9) return 0
            return 12 + idx * 26 + (24 - width) / 2
        }
        Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    }

    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: 2

        property var urgentWorkspaces: []

        function checkUrgentWindows() {
            var urgent = []
            var clients = Hyprland.clients || []
            for (var i = 0; i < clients.length; i++) {
                var c = clients[i]; if (!c) continue
                var isU = false
                if (c.urgent === true) isU = true
                else if (c.windowProperties && c.windowProperties.urgency === true) isU = true
                if (!isU && c.title) {
                    var t = String(c.title)
                    if (/^\(\d+\)/.test(t) || t.indexOf("●") === 0) isU = true
                }
                if (isU && c.workspace && c.workspace.id !== undefined) {
                    var wid = c.workspace.id
                    if (urgent.indexOf(wid) === -1) urgent.push(wid)
                }
            }
            urgentWorkspaces = urgent
        }
        function handleRawEvent(e) {
            if (e.name === "urgent" || e.name === "windowurgent" ||
                e.name === "createclient" || e.name === "destroyclient" ||
                e.name === "moveclient" || e.name === "activewindowv2" ||
                e.name === "windowtitlev2")
                wsRow.checkUrgentWindows()
        }
        Component.onCompleted: {
            Hyprland.rawEvent.connect(handleRawEvent)
            checkUrgentWindows()
        }
        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: wsRow.checkUrgentWindows()
        }

        Repeater {
            model: 10
            Item {
                id: wsDelegate
                width: 24
                height: 24
                z: 300

                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                property bool isUrgent: wsRow.urgentWorkspaces.indexOf(index + 1) !== -1
                property bool isBusy: ws !== undefined && ws !== null

                Rectangle {
                    id: glowRing
                    anchors.centerIn: parent
                    width: 22; height: 22; radius: 11
                    color: "transparent"
                    border.color: wsContainer.theme.colRed
                    border.width: 1.5
                    visible: wsDelegate.isUrgent
                    opacity: 0

                    SequentialAnimation on opacity {
                        running: wsDelegate.isUrgent
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.95; duration: 600; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 0.20; duration: 600; easing.type: Easing.InOutQuad }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 6
                        height: parent.height + 6
                        radius: width / 2
                        color: wsContainer.theme.colRed
                        opacity: 0.25
                        z: -1
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: index + 1
                    color: {
                        if (wsDelegate.isUrgent) return wsContainer.theme.colRed
                        if (wsDelegate.isActive) return "#ffffff"
                        if (wsDelegate.isBusy)   return "#c8c8cc"
                        return "#5a5a5e"
                    }
                    font {
                        family: wsContainer.theme.fontFamily
                        pixelSize: 13
                        bold: wsDelegate.isActive || wsDelegate.isUrgent
                    }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    anchors.fill: parent
                    z: 400
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (index + 1) + " })")
                }
            }
        }
    }
}