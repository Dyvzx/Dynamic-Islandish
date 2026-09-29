import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: cavaMon

    // Number of bars cava is configured to output. Must match the
    // `bars = N` line in the config below.
    readonly property int barCount: 12

    // Smoothed, normalized bar values in [0, 1].
    property var bars: {
        var a = []
        for (var i = 0; i < barCount; i++) a.push(0)
        return a
    }

    // Whether cava is currently producing output (i.e. audio is playing).
    property bool active: false

    // Raw reading before smoothing.
    property var _raw: {
        var a = []
        for (var i = 0; i < barCount; i++) a.push(0)
        return a
    }

    // ---- cava config, written to a temp file on first run ----
    // We use raw output so parsing is trivial: each frame is
    // barCount newline-terminated integers.
    readonly property string configPath: "/tmp/qs-cava.conf"

    property Process _writeConf: Process {
        command: ["sh", "-c", String.raw`
cat > /tmp/qs-cava.conf <<'EOF'
[general]
framerate = 60
bars = 12

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
frame_delimiter = 10
EOF
`]
        running: true
    }

    // ---- cava process ----
    property Process cava: Process {
        command: ["cava", "-p", cavaMon.configPath]
        running: true

        stdout: SplitParser {
            onRead: data => cavaMon._onLine(data)
        }

        onExited: {
            // Restart after a short delay if cava dies.
            cavaRestart.restart()
        }
    }

    property Timer cavaRestart: Timer {
        interval: 1500
        repeat: false
        onTriggered: cavaMon.cava.running = true
    }

    // ---- parsing ----
    function _onLine(line) {
        if (line === undefined || line === null) return
        var parts = line.split(";")
        if (parts.length < barCount) return

        var raw = []
        var anyNonZero = false
        for (var i = 0; i < barCount; i++) {
            var v = parseInt(parts[i], 10)
            if (isNaN(v)) v = 0
            raw.push(Math.max(0, Math.min(100, v)) / 100)
            if (v > 2) anyNonZero = true
        }
        _raw = raw
        active = anyNonZero
    }

    // ---- smoothing: 60 fps decay toward raw ----
    property Timer smoother: Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: cavaMon._tick()
    }

    function _tick() {
        var b = bars.slice()
        var r = _raw
        var changed = false
        for (var i = 0; i < barCount; i++) {
            // Fast attack, slower release for a nicer look.
            var target = r[i]
            var cur = b[i]
            var next = (target > cur)
                ? cur + (target - cur) * 0.55
                : cur + (target - cur) * 0.18
            if (Math.abs(next - cur) > 0.0005) changed = true
            b[i] = next
        }
        if (changed) bars = b

        // If nothing's playing for a while, force everything down.
        if (!active) {
            var allZero = true
            for (var k = 0; k < barCount; k++) {
                if (b[k] > 0.005) { allZero = false; break }
            }
            if (allZero) {
                var z = []
                for (var j = 0; j < barCount; j++) z.push(0)
                bars = z
            }
        }
    }

    Component.onCompleted: {
        // Ensure the config exists before cava starts.
        _writeConf.running = true
    }
}