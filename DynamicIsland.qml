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
    required property var pomodoro

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

    readonly property bool timerRunning:  pomodoro && pomodoro.state === "running"
    readonly property bool timerFinished: pomodoro && pomodoro.state === "finished"

    property bool _hiddenBeforeTimerDone: false

    readonly property color ringColor:
        island.activeAudio ? theme.mediaColor : "#30d158"

    Component.onCompleted: islandState.island = island

    onTimerFinishedChanged: {
        if (timerFinished) {
            island._hiddenBeforeTimerDone =
                islandState.islandHidden && !islandState.revealedWhileHidden
            if (island._hiddenBeforeTimerDone)
                islandState.revealIsland()
        }
    }

    Connections {
        target: islandState
        function onCollapsedChanged() {
            if (islandState.collapsed) island.isExpanded = false
        }
        function onLockedChanged() {
            if (islandState.locked) island.isExpanded = false
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
                if (mouse.button === Qt.RightButton)
                    islandState.rightClickHideOrWrap()
                else
                    islandState.revealIsland()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        visible: island.isExpanded && !islandState.collapsed
        enabled: island.isExpanded && !islandState.collapsed
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                islandState.rightClickHideOrWrap()
                return
            }
            island.isExpanded = false
        }
    }

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

            onActiveChanged: { if (active) unlocked = false }
            onActiveTranslationChanged: {
                if (!active || unlocked) return
                if (activeTranslation.y > 25) {
                    unlocked = true
                    islandState.locked = false
                }
            }
        }
    }

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
                : (compactTimerDone.visible
                    ? compactTimerDone.width + 44
                    : (island.compactWidget === 0
                        ? compactVisualizer.implicitWidth + 44
                        : compactClockHolder.implicitWidth + 44))

            height: island.isExpanded
                ? expandedBody.height + 28
                : 36

            radius: island.isExpanded ? 22 : height / 2
            color: theme.colBg
            border.color: island.timerRunning ? "transparent" : "#1c1c1e"
            border.width: 1
            clip: true

            Behavior on radius { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

            Item {
                id: compactTimerDone
                anchors.centerIn: parent
                width: timerDoneRow.implicitWidth
                height: timerDoneRow.implicitHeight
                visible: island.timerFinished && !island.isExpanded

                Row {
                    id: timerDoneRow
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uF017"
                        color: island.ringColor
                        font { family: theme.fontFamily; pixelSize: 18; bold: true }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Timer done"
                        color: theme.colFg
                        font { family: theme.fontFamily; pixelSize: 13; bold: true }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "click to stop"
                        color: theme.colMuted
                        font { family: theme.fontFamily; pixelSize: 11 }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                visible: island.timerFinished && !island.isExpanded
                enabled: island.timerFinished && !island.isExpanded
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var wasHidden = island._hiddenBeforeTimerDone
                    island.pomodoro.dismiss()
                    island._hiddenBeforeTimerDone = false
                    if (wasHidden && !islandState.islandHidden)
                        islandState.hideIsland()
                    else if (wasHidden)
                        islandState.hideIslandAgain()
                }
            }

            Item {
                anchors.fill: parent
                visible: !island.isExpanded && !island.timerFinished

                opacity: (island.isExpanded || island.timerFinished) ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 200 } }

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
                    pomodoro: island.pomodoro
                }
            }

            Item {
                id: compactClick
                anchors.fill: parent
                visible: !island.isExpanded && !island.timerFinished
                enabled: !island.isExpanded && !island.timerFinished

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            islandState.rightClickHideOrWrap()
                            return
                        }
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

                    onActiveChanged: { if (active) locked = false }
                    onActiveTranslationChanged: {
                        if (!active || locked) return
                        if (islandState.collapsed) return
                        if (activeTranslation.y < -30) {
                            locked = true
                            islandState.locked = true
                        }
                    }
                }
            }
        }

        // ---- Sand-clock timer ring ----
        // Two arms anchored at the BOTTOM-CENTER (d = perim/2), sweeping
        // outward along the pill's perimeter:
        //   * Arm A sweeps COUNTER-CLOCKWISE (negative distances).
        //   * Arm B sweeps CLOCKWISE (positive distances).
        // Each covers halfLen = perim * remaining / 2, so at full time
        // the two tips meet at the top-center (full ring), and as time
        // runs down the tips retract back toward the bottom-center —
        // i.e., the "sand" drains from the TOP DOWN, top empties first.
        Canvas {
            id: timerRing
            anchors.fill: bg
            visible: island.timerRunning
            antialiasing: true
            renderStrategy: Canvas.Cooperative
            z: 10

            Connections {
                target: island.pomodoro
                function onProgressChanged() { timerRing.requestPaint() }
                function onStateChanged()    { timerRing.requestPaint() }
            }
            Connections {
                target: island
                function onRingColorChanged() { timerRing.requestPaint() }
            }
            onWidthChanged:  requestPaint()
            onHeightChanged: requestPaint()
            onVisibleChanged: if (visible) requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.clearRect(0, 0, width, height)

                var stroke = 2.5
                var inset  = stroke / 2
                var w = width  - stroke
                var h = height - stroke
                var x = inset
                var y = inset

                var r = Math.min(bg.radius, Math.min(w, h) / 2)
                if (r < 0) r = 0

                var remaining = 1.0 - (island.pomodoro ? island.pomodoro.progress : 1)
                if (remaining < 0) remaining = 0
                if (remaining > 1) remaining = 1

                var straightW = Math.max(0, w - 2 * r)
                var straightH = Math.max(0, h - 2 * r)
                var quarter   = Math.PI * r / 2
                var perim     = 2 * straightW + 2 * straightH + 4 * quarter

                var cx = x + w / 2
                var cy = y + h / 2

                // Segment table traced CLOCKWISE from top-center.
                var segs = [
                    { len: straightW / 2, kind: "line",
                      x1: cx, y1: y, x2: x + w - r, y2: y },
                    { len: quarter, kind: "arc",
                      ccx: x + w - r, ccy: y + r, a1: -Math.PI/2, a2: 0 },
                    { len: straightH, kind: "line",
                      x1: x + w, y1: y + r, x2: x + w, y2: y + h - r },
                    { len: quarter, kind: "arc",
                      ccx: x + w - r, ccy: y + h - r, a1: 0, a2: Math.PI/2 },
                    { len: straightW, kind: "line",
                      x1: x + w - r, y1: y + h, x2: x + r, y2: y + h },
                    { len: quarter, kind: "arc",
                      ccx: x + r, ccy: y + h - r, a1: Math.PI/2, a2: Math.PI },
                    { len: straightH, kind: "line",
                      x1: x, y1: y + h - r, x2: x, y2: y + r },
                    { len: quarter, kind: "arc",
                      ccx: x + r, ccy: y + r, a1: Math.PI, a2: Math.PI * 1.5 },
                    { len: straightW / 2, kind: "line",
                      x1: x + r, y1: y, x2: cx, y2: y }
                ]

                function ptAtDist(d) {
                    d = ((d % perim) + perim) % perim
                    var acc = 0
                    for (var i = 0; i < segs.length; i++) {
                        var s = segs[i]
                        if (d <= acc + s.len) {
                            var t = (d - acc) / s.len
                            if (s.kind === "line") {
                                return { x: s.x1 + (s.x2 - s.x1) * t,
                                         y: s.y1 + (s.y2 - s.y1) * t }
                            } else {
                                var a = s.a1 + (s.a2 - s.a1) * t
                                return { x: s.ccx + r * Math.cos(a),
                                         y: s.ccy + r * Math.sin(a) }
                            }
                        }
                        acc += s.len
                    }
                    return { x: cx, y: y }
                }

                var halfLen = perim * remaining / 2
                var steps = 64

                ctx.lineWidth   = stroke
                ctx.lineCap     = "round"
                ctx.lineJoin    = "round"
                ctx.strokeStyle = island.ringColor

                if (halfLen < 0.01) return

                // ---- Arm A: anchored at BOTTOM-center, sweeping CCW ----
                // At full time (remaining = 1, halfLen = perim/2), it goes
                // all the way around to the top-center the "left way".
                // As time runs down, its tip retracts back to bottom-center.
                ctx.beginPath()
                for (var i = 0; i <= steps; i++) {
                    var dA = perim / 2 - (halfLen * i) / steps
                    var pA = ptAtDist(dA)
                    if (i === 0) ctx.moveTo(pA.x, pA.y)
                    else         ctx.lineTo(pA.x, pA.y)
                }
                ctx.stroke()

                // ---- Arm B: anchored at BOTTOM-center, sweeping CW ----
                ctx.beginPath()
                for (var j = 0; j <= steps; j++) {
                    var dB = perim / 2 + (halfLen * j) / steps
                    var pB = ptAtDist(dB)
                    if (j === 0) ctx.moveTo(pB.x, pB.y)
                    else         ctx.lineTo(pB.x, pB.y)
                }
                ctx.stroke()
            }
        }
    }
}