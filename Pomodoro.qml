import QtQuick

QtObject {
    id: pomodoro

    // States: "idle", "running", "finished"
    property string state: "idle"

    // Default to zero — presets add to this.
    property int durationSec: 0
    property int remainingSec: 0

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
        // If we're starting after a finish, reload the duration.
        if (remainingSec <= 0)
            remainingSec = durationSec
        // Do not start if there's nothing to run.
        if (remainingSec <= 0) return
        state = "running"
        tick.restart()
    }

    function pause() {
        if (state === "running")
            state = "idle"
        tick.stop()
    }

    // Reset clears everything back to zero / ready.
    function reset() {
        tick.stop()
        durationSec = 0
        remainingSec = 0
        state = "idle"
    }

    function dismiss() {
        reset()
    }

    // Add `secs` seconds to the current duration and remaining time.
    // Does NOT start the timer. If the timer was running, it stops it
    // so the user can keep accumulating time before pressing Start.
    function addPreset(secs) {
        if (secs === undefined || secs <= 0) return
        tick.stop()
        durationSec += secs
        remainingSec += secs
        state = "idle"
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
                tick.stop()
            }
        }
    }
}