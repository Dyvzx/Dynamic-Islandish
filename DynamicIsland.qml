import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris

PanelWindow {
    id: island
    anchors.top: true
    anchors.left: true
    anchors.right: true

    required property var theme
    required property var stats
    required property var audioMon
    required property var islandState

    implicitHeight: islandState.collapsed
        ? islandState.lockedIslandHeight
        : (island.isExpanded ? Screen.height : islandState.islandHeight)

    Behavior on implicitHeight {
        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
    }

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property bool isExpanded: false
    property int activeTab: 0
    property int compactWidget: 0

    property int liveVolume: 0
    property bool liveMuted: false

    // Register ourselves with IslandState so it can drive expanded state
    // from the right-click hide/wrap handler.
    Component.onCompleted: islandState.island = island

    // When the island collapses, drop out of expanded state so the
    // next time it's revealed it comes back as a compact pill.
    Connections {
        target: islandState

        function onCollapsedChanged() {
            if (islandState.collapsed) island.isExpanded = false
        }
        function onLockedChanged() {
            if (islandState.locked) island.isExpanded = false
        }
        function onIslandHiddenChanged() {
            // Nothing extra — IslandState handles reveal state itself.
        }
    }

    Process {
        id: volMonProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                if (parts.length >= 2) {
                    var v = parseFloat(parts[1])
                    if (!isNaN(v)) island.liveVolume = Math.round(v * 100)
                    island.liveMuted = data.includes("[MUTED]")
                }
            }
        }
        Component.onCompleted: running = true
    }
    Timer {
        interval: 250
        running: !island.isExpanded && !islandState.collapsed
        repeat: true
        onTriggered: volMonProc.running = true
    }

    readonly property bool mediaPlaying: {
        var ps = Mpris.players ? Mpris.players.values : []
        for (var i = 0; i < ps.length; i++)
            if (ps[i] && ps[i].isPlaying) return true
        return false
    }

    readonly property bool activeAudio:
        !liveMuted && (
            mediaPlaying ||
            (audioMon.audioActive && audioMon.audioApp !== "")
        )

    // ---- Reveal hot-zone (only when the user has hidden the island) ----
    Item {
        id: revealZone
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width:  220
        height: islandState.lockedIslandHeight
        visible: islandState.hiddenByUser
        enabled: islandState.hiddenByUser
        z: 100

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    // Right-click on the reveal hot-zone restores the
                    // island as a compact pill (turns hide-island OFF).
                    islandState.rightClickHideOrWrap()
                } else {
                    islandState.revealIsland()
                }
            }
        }
    }

    // Fullscreen dismiss layer when expanded.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        visible: island.isExpanded && !islandState.collapsed
        enabled: island.isExpanded && !islandState.collapsed
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                // Right-click on the dismiss layer: hide if not hidden,
                // otherwise wrap to compact.
                islandState.rightClickHideOrWrap()
                return
            }
            island.isExpanded = false
            if (islandState.islandHidden)
                islandState.hideIslandAgain()
        }
    }

    // ---- Locked: notch shape (only when locked via swipe-up) ----
    Rectangle {
        id: lockedNotch
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 120
        height: 9
        visible: islandState.lockedDown
        enabled: islandState.lockedDown

        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: 16
        bottomRightRadius: 16

        color: "#0a0a0a"
        border.color: "#2a2a2c"
        border.width: 1

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 1
            anchors.rightMargin: 1
            height: 1
            color: "#10ffffff"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: islandState.locked = false
        }

        DragHandler {
            id: unlockDrag
            target: null
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.TouchScreen
            dragThreshold: 10

            property bool unlocked: false

            onActiveChanged: {
                if (active) unlocked = false
            }
            onActiveTranslationChanged: {
                if (!active || unlocked) return
                if (activeTranslation.y > 25) {
                    unlocked = true
                    islandState.locked = false
                }
            }
        }
    }

    // ---- Island body ----
    Item {
        id: islandBody
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 4

        width:  bg.width
        height: bg.height
        visible: !islandState.collapsed

        Behavior on width  { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

        Rectangle {
            id: bg
            anchors.horizontalCenter: parent.horizontalCenter

            width: island.isExpanded
                ? Math.max(expandedBody.width + 28, 460)
                : (island.compactWidget === 0
                    ? compactVisualizer.implicitWidth + 44
                    : compactClockHolder.implicitWidth + 44)

            height: island.isExpanded
                ? expandedBody.height + 28
                : 36

            radius: island.isExpanded ? 22 : height / 2
            color: theme.colBg
            border.color: "#1c1c1e"
            border.width: 1
            clip: true

            Behavior on radius { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

            Item {
                id: compactClick
                anchors.fill: parent
                visible: !island.isExpanded
                enabled: !island.isExpanded

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            // Right-click on compact pill:
                            //   hide-island OFF → wrap (already compact, no-op)
                            //   hide-island ON  → fully hide
                            islandState.rightClickHideOrWrap()
                            return
                        }
                        // Left click → expand
                        island.isExpanded = true
                    }

                    onWheel: function(w) {
                        if (w.angleDelta.y > 0)
                            island.compactWidget = (island.compactWidget - 1 + 2) % 2
                        else if (w.angleDelta.y < 0)
                            island.compactWidget = (island.compactWidget + 1) % 2
                        w.accepted = true
                    }
                }

                DragHandler {
                    id: lockDrag
                    target: null
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.TouchScreen
                    dragThreshold: 10

                    property bool locked: false

                    onActiveChanged: {
                        if (active) locked = false
                    }
                    onActiveTranslationChanged: {
                        if (!active || locked) return
                        if (islandState.collapsed) return    // already collapsed, don't re-lock
                        if (activeTranslation.y < -30) {
                            locked = true
                            islandState.locked = true
                        }
                    }
                }
            }

            Item {
                anchors.fill: parent
                opacity: island.isExpanded ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
                visible: opacity > 0

                CompactVisualizer {
                    id: compactVisualizer
                    anchors.centerIn: parent
                    theme: island.theme
                    activeAudio: island.activeAudio
                    liveVolume: island.liveVolume
                    visible: island.compactWidget === 0
                    opacity: island.compactWidget === 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }

                Item {
                    id: compactClockHolder
                    anchors.centerIn: parent
                    visible: island.compactWidget === 1
                    opacity: island.compactWidget === 1 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    implicitWidth: compactClock.implicitWidth
                    implicitHeight: compactClock.implicitHeight

                    CompactClock {
                        id: compactClock
                        anchors.centerIn: parent
                        theme: island.theme
                    }
                }
            }

            Column {
                id: expandedBody
                anchors.centerIn: parent
                spacing: 10
                opacity: island.isExpanded ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220 } }
                visible: opacity > 0

                ExpandedTabs {
                    id: tabContent
                    island: island
                    theme: island.theme
                    stats: island.stats
                }
            }
        }
    }
}