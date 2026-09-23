import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: pomodoro

    // States: "idle", "running", "finished"
    property string state: "idle"

    // Default to zero — presets add to this.
    property int durationSec: 0
    property int remainingSec: 0

    // Text used for the "timer finished" notification.
    property string notifyTitle: "Timer done"
    property string notifyBody: "Your pomodoro has finished."
    property string notifyAppName: "Pomodoro"

    readonly property real progress:
        durationSec > 0 ? 1.0 - (remainingSec / durationSec) : 0

    readonly property string display:
        pomodoro.formatHms(remainingSec)

    function formatHms(sec) {
        if (sec < 0) sec = 0
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return (m < 10 ? "0" + m : "" + m) + ":" +
               (s < 10 ? "0" + s : "" + s)
    }

    function start(seconds) {
        if (seconds !== undefined && seconds > 0)
            durationSec = seconds
        if (remainingSec <= 0)
            remainingSec = durationSec
        if (remainingSec <= 0) return
        state = "running"
    }

    function pause() {
        if (state === "running")
            state = "idle"
    }

    function reset() {
        durationSec = 0
        remainingSec = 0
        state = "idle"
    }

    function dismiss() {
        reset()
    }

    function addPreset(secs) {
        if (secs === undefined || secs <= 0) return
        durationSec += secs
        remainingSec += secs
        state = "idle"
    }

    // ------------------------------------------------------------
    // Fire a desktop notification when the timer finishes.
    //
    // Uses notify-send so dunst receives it on D-Bus, then the
    // NotificationMonitor picks it up and the island shows it —
    // exactly like a normal system notification.
    //
    // `-a` sets app name, `-i` sets an icon. The icon is a Nerd
    // Font glyph-free name (dunst can't render font icons), so we
    // use the freedesktop standard "alarm" icon; if the icon theme
    // doesn't have it, dunst/the island will fall back to the
    // built-in bell glyph.
    // ------------------------------------------------------------
    property Process _notifyProc: Process {
        id: _notifyProc
        command: ["sh", "-c", "true"]   // replaced at fire time
    }

    function _fireFinishedNotification() {
        // Escape single quotes in user-provided strings so the shell
        // command doesn't break.
        function esc(s) {
            return String(s).replace(/'/g, "'\\''")
        }

        var cmd =
            "notify-send " +
            "-a '" + esc(notifyAppName) + "' " +
            "-i 'alarm' " +
            "-u normal " +
            "'" + esc(notifyTitle) + "' " +
            "'" + esc(notifyBody) + "'"

        _notifyProc.command = ["sh", "-c", cmd]
        _notifyProc.running = false
        _notifyProc.running = true
    }

    onStateChanged: {
        if (state === "finished")
            _fireFinishedNotification()
    }

    property Timer tick: Timer {
        interval: 1000
        repeat: true
        running: pomodoro.state === "running"
        onTriggered: {
            if (pomodoro.remainingSec > 0)
                pomodoro.remainingSec -= 1
            if (pomodoro.remainingSec <= 0) {
                pomodoro.remainingSec = 0
                pomodoro.state = "finished"
            }
        }
    }
}