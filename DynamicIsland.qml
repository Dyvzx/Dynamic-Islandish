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
    required property var notificationMon

    implicitHeight: islandState.collapsed
        ? islandState.lockedIslandHeight
        : (island.isExpanded || island.powerMenuOpen
            ? island.screen.height
            : islandState.islandHeight)

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

    property bool powerMenuOpen: false

    property int liveVolume: 0
    property bool liveMuted: false

    readonly property bool timerRunning: pomodoro && pomodoro.state === "running"

    readonly property bool notificationActive:
        notificationMon && notificationMon.current !== null

    readonly property bool notificationShowing:
        islandState.notificationsEnabled && notificationActive

    // ---- Media reveal ----
    property int mediaRevealDuration: 4000
    property bool mediaRevealActive: false
    property bool _prevMediaPlaying: false
    property bool _mediaRevealForcedVisualizer: false

    property bool _mediaPrevHidden: false
    property bool _mediaPrevLocked: false
    property bool _mediaPrevRevealed: false

    readonly property bool mediaRevealShowing:
        mediaRevealActive
        && !isExpanded
        && !notificationShowing
        && !powerMenuOpen

    readonly property int mediaRevealWidget:
        _mediaRevealForcedVisualizer ? 0 : compactWidget

    // ---- Notification reveal snapshot ----
    property bool _notifPrevHidden: false
    property bool _notifPrevLocked: false
    property bool _notifPrevRevealed: false

    readonly property color ringColor:
        island.activeAudio ? theme.mediaColor : "#30d158"

    Component.onCompleted: islandState.island = island

    // ============================================================
    // System commands
    // ============================================================
    Process {
        id: sysCmdProc
        command: ["sh", "-c", "true"]
    }

    function _runSystemCmd(cmd) {
        sysCmdProc.command = ["sh", "-c", cmd]
        sysCmdProc.running = false
        sysCmdProc.running = true
    }

    function lockSession() {
        _runSystemCmd("hyprlock")
        island.powerMenuOpen = false
    }
    function suspend()  { _runSystemCmd("systemctl suspend");  island.powerMenuOpen = false }
    function reboot()   { _runSystemCmd("systemctl reboot");   island.powerMenuOpen = false }
    function powerOff() { _runSystemCmd("systemctl poweroff"); island.powerMenuOpen = false }

    // ============================================================
    // Wheel: toggle widget, restart reveal window if active.
    // ============================================================
    function cycleCompactWidget(delta) {
        if (island.mediaRevealActive && island._mediaRevealForcedVisualizer) {
            island._mediaRevealForcedVisualizer = false
            island.compactWidget = 1
            mediaRevealTimer.restart()
            return
        }

        if (delta > 0)
            island.compactWidget = (island.compactWidget - 1 + 2) % 2
        else if (delta < 0)
            island.compactWidget = (island.compactWidget + 1) % 2

        if (island.mediaRevealActive)
            mediaRevealTimer.restart()
    }

    // ============================================================
    // Media playing: rising edge → fresh reveal
    // ============================================================
    onMediaPlayingChanged: {
        if (mediaPlaying && !_prevMediaPlaying) {
            if (islandState.mediaPopupsEnabled && !island.powerMenuOpen) {
                island._mediaRevealForcedVisualizer = true
                mediaRevealActive = true
                mediaRevealTimer.restart()
            }
        }
        _prevMediaPlaying = mediaPlaying
    }

    Timer {
        id: mediaRevealTimer
        interval: island.mediaRevealDuration
        repeat: false
        onTriggered: island.mediaRevealActive = false
    }

    onMediaRevealActiveChanged: {
        if (mediaRevealActive) {
            if (!notificationShowing) {
                _mediaPrevHidden   = islandState.islandHidden
                _mediaPrevLocked   = islandState.locked
                _mediaPrevRevealed = islandState.revealedWhileHidden

                if (islandState.hiddenByUser)
                    islandState.revealIsland()

                if (islandState.locked)
                    islandState.locked = false
            }
        } else {
            if (!notificationShowing) {
                if (_mediaPrevLocked)
                    islandState.locked = true

                if (_mediaPrevHidden)
                    islandState.hideIslandAgain()
                else if (_mediaPrevRevealed)
                    islandState.revealedWhileHidden = true
            }

            _mediaPrevHidden   = false
            _mediaPrevLocked   = false
            _mediaPrevRevealed = false
            _mediaRevealForcedVisualizer = false
        }
    }

    // ============================================================
    // Notifications
    // ============================================================
    onNotificationActiveChanged: {
        if (notificationActive && islandState.notificationsEnabled) {
            island._notifPrevHidden   = islandState.islandHidden
            island._notifPrevLocked   = islandState.locked
            island._notifPrevRevealed = islandState.revealedWhileHidden

            if (islandState.hiddenByUser)
                islandState.revealIsland()

            if (islandState.locked)
                islandState.locked = false
        } else {
            if (island._notifPrevLocked)
                islandState.locked = true

            if (island._notifPrevHidden)
                islandState.hideIslandAgain()
            else if (island._notifPrevRevealed)
                islandState.revealedWhileHidden = true

            island._notifPrevHidden   = false
            island._notifPrevLocked   = false
            island._notifPrevRevealed = false
        }
    }

    Connections {
        target: islandState
        function onNotificationsEnabledChanged() {
            if (!islandState.notificationsEnabled) {
                if (island.notificationMon)
                    island.notificationMon.dismissAll()

                if (island._notifPrevLocked)
                    islandState.locked = true
                if (island._notifPrevHidden)
                    islandState.hideIslandAgain()
                else if (island._notifPrevRevealed)
                    islandState.revealedWhileHidden = true

                island._notifPrevHidden   = false
                island._notifPrevLocked   = false
                island._notifPrevRevealed = false
            }
        }
    }

    function dismissNotification() {
        if (island.notificationMon)
            island.notificationMon.dismissCurrent()
    }

    Connections {
        target: islandState
        function onCollapsedChanged() {
            if (islandState.collapsed) {
                island.isExpanded = false
                island.powerMenuOpen = false
            }
        }
        function onLockedChanged() {
            if (islandState.locked) {
                island.isExpanded = false
                island.powerMenuOpen = false
            }
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
    }

    Timer {
        interval: 250
        running: !island.isExpanded && !islandState.collapsed
        repeat: true
        onTriggered: {
            volMonProc.running = false
            volMonProc.running = true
        }
        Component.onCompleted: if (running) volMonProc.running = true
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

    // Backdrop — full-screen; dismisses the power menu when clicking
    // anywhere outside the pill. Sits above the desktop surface but
    // below islandBody (z: 50).
    MouseArea {
        anchors.fill: parent
        visible: island.powerMenuOpen && !islandState.collapsed
        enabled: visible
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: 1
        onClicked: function(mouse) { island.powerMenuOpen = false }
    }

    // Expanded-island backdrop — also full screen.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        visible: island.isExpanded && !islandState.collapsed && !island.powerMenuOpen
        enabled: visible
        z: 0
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                islandState.rightClickHideOrWrap()
                return
            }
            island.isExpanded = false
        }
    }

    // ============================================================
    // Locked notch — click or drag down to unlock.
    // ============================================================
    Rectangle {
        id: lockedNotch
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 120
        height: 9
        visible: islandState.lockedDown
        enabled: islandState.lockedDown
        z: 5

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

    // ============================================================
    // Island body — compact pill stays centered; power pill sits
    // to its LEFT with the same height. z: 50 so it's above the
    // backdrops (z: 0 and 1) and its buttons are clickable.
    // ============================================================
    Item {
        id: islandBody
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 4

        width:  bg.width
        height: bg.height
        visible: !islandState.collapsed
        z: 50

        // ============================================================
        // Compact pill
        // ============================================================
        Rectangle {
            id: bg
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

            width: island.isExpanded
                ? Math.max(expandedBody.width + 28, 460)
                : (compactNotification.visible
                    ? compactNotification.width + 44
                    : (compactMediaReveal.visible
                        ? compactMediaReveal.width + 44
                        : (island.compactWidget === 0
                            ? compactVisualizer.implicitWidth + 44
                            : compactClockHolder.implicitWidth + 44)))

            height: island.isExpanded
                ? expandedBody.height + 28
                : 36

            radius: island.isExpanded ? 22 : height / 2
            color: theme.colBg
            border.color: island.timerRunning ? "transparent" : "#1c1c1e"
            border.width: 1
            clip: true

            Behavior on width  { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            Behavior on radius { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

            // ---- Notification ----
            Item {
                id: compactNotification
                anchors.centerIn: parent
                width: notifContent.implicitWidth
                height: notifContent.implicitHeight
                visible: island.notificationShowing
                         && !island.isExpanded
                         && !island.powerMenuOpen

                NotificationIsland {
                    id: notifContent
                    anchors.centerIn: parent
                    theme: island.theme
                    notif: island.notificationMon ? island.notificationMon.current : null
                    accent: island.ringColor

                    onDismissRequested: island.dismissNotification()
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    z: -1

                    onClicked: function(mouse) { island.dismissNotification() }
                }
            }

            // ---- Media reveal ----
            Item {
                id: compactMediaReveal
                anchors.centerIn: parent
                visible: island.mediaRevealShowing

                implicitWidth: mediaRevealClockHolder.visible
                    ? mediaRevealClockHolder.implicitWidth
                    : mediaRevealVisualizer.implicitWidth
                implicitHeight: mediaRevealClockHolder.visible
                    ? mediaRevealClockHolder.implicitHeight
                    : mediaRevealVisualizer.implicitHeight

                width: implicitWidth
                height: implicitHeight

                CompactVisualizer {
                    id: mediaRevealVisualizer
                    anchors.centerIn: parent
                    theme: island.theme
                    activeAudio: island._mediaRevealForcedVisualizer
                        ? true
                        : island.activeAudio
                    liveVolume: island.liveVolume
                    visible: island.mediaRevealWidget === 0
                }

                Item {
                    id: mediaRevealClockHolder
                    anchors.centerIn: parent
                    visible: island.mediaRevealWidget === 1
                    implicitWidth: mediaRevealClock.implicitWidth
                    implicitHeight: mediaRevealClock.implicitHeight

                    CompactClock {
                        id: mediaRevealClock
                        anchors.centerIn: parent
                        theme: island.theme
                    }
                }
            }

            // ---- Idle compact widgets ----
            Item {
                anchors.fill: parent
                visible: !island.isExpanded
                         && !island.notificationShowing
                         && !island.mediaRevealShowing

                opacity: visible ? 1 : 0
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

            // ---- Expanded tabs ----
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

            // ---- Compact gestures ----
            Item {
                id: compactClick
                anchors.fill: parent
                visible: !island.isExpanded && !island.notificationShowing
                enabled: visible

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function(mouse) {
                        if (island.powerMenuOpen) {
                            island.powerMenuOpen = false
                            return
                        }
                        if (mouse.button === Qt.RightButton) {
                            islandState.rightClickHideOrWrap()
                            return
                        }
                        island.mediaRevealActive = false
                        island.isExpanded = true
                    }

                    onWheel: function(w) {
                        if (Math.abs(w.angleDelta.x) > Math.abs(w.angleDelta.y)) {
                            if (w.angleDelta.x < -30 && !island.powerMenuOpen) {
                                island.mediaRevealActive = false
                                island.powerMenuOpen = true
                            } else if (w.angleDelta.x > 30 && island.powerMenuOpen) {
                                island.powerMenuOpen = false
                            }
                            w.accepted = true
                            return
                        }
                        island.cycleCompactWidget(w.angleDelta.y)
                        w.accepted = true
                    }
                }

                DragHandler {
                    id: swipeDrag
                    target: null
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.TouchScreen
                    dragThreshold: 10

                    property bool triggered: false

                    onActiveChanged: { if (active) triggered = false }

                    onActiveTranslationChanged: {
                        if (!active || triggered) return
                        if (islandState.collapsed) return
                        if (island.powerMenuOpen) return

                        var dx = activeTranslation.x
                        var dy = activeTranslation.y

                        if (Math.abs(dx) > Math.abs(dy)) {
                            if (dx < -40) {
                                triggered = true
                                island.mediaRevealActive = false
                                island.powerMenuOpen = true
                            }
                        } else {
                            if (dy < -30) {
                                triggered = true
                                island.mediaRevealActive = false
                                islandState.locked = true
                            }
                        }
                    }
                }
            }
        }

        // ============================================================
        // Timer ring
        // ============================================================
        Canvas {
            id: timerRing
            anchors.fill: bg
            visible: island.timerRunning && bg.visible
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

                ctx.beginPath()
                for (var i = 0; i <= steps; i++) {
                    var dA = perim / 2 - (halfLen * i) / steps
                    var pA = ptAtDist(dA)
                    if (i === 0) ctx.moveTo(pA.x, pA.y)
                    else         ctx.lineTo(pA.x, pA.y)
                }
                ctx.stroke()

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

        // ============================================================
        // Power pill — same height as the compact pill, sits to its
        // left. Grows leftward on open (width + opacity animation).
        // ============================================================
        Rectangle {
            id: powerPill

            anchors.top: bg.top
            height: bg.height

            readonly property int fullWidth: menuContent.implicitWidth + 20
            readonly property int stubWidth: bg.height

            width: island.powerMenuOpen ? fullWidth : stubWidth

            anchors.right: bg.left
            anchors.rightMargin: 8

            z: 30

            visible: island.powerMenuOpen || opacity > 0.01
            enabled: island.powerMenuOpen

            opacity: island.powerMenuOpen ? 1 : 0

            Behavior on width   { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            radius: height / 2
            color: theme.colBg
            border.color: "#1c1c1e"
            border.width: 1
            clip: true

            PowerMenu {
                id: menuContent
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                theme: island.theme

                onLockRequested:     island.lockSession()
                onSuspendRequested:  island.suspend()
                onRebootRequested:   island.reboot()
                onPowerOffRequested: island.powerOff()
                onCancelRequested:   island.powerMenuOpen = false
            }
        }
    }
}