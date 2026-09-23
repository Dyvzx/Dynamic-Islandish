import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: notifMon

    // Currently visible notification (or null)
    property var current: null

    // Queue of pending notifications
    property var queue: []

    // Auto-dismiss timeout (ms) if notification doesn't specify one
    property int defaultTimeout: 5000

    // Signals emitted by the monitor
    signal notificationAdded(var notif)
    signal notificationDismissed(var notif)

    // ---- D-Bus monitor: watch for Notify() calls ----
    property Process dbusMon: Process {
        command: [
            "dbus-monitor",
            "--session",
            "interface='org.freedesktop.Notifications',member='Notify'"
        ]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (data === undefined || data === null) return
                notifMon._parseLine(data)
            }
        }
    }

    // ---- Parser state ----
    property int _argIndex: 0
    property var _pending: ({})

    function _parseLine(line) {
        var t = line.trim()
        if (t.length === 0) return

        // Start of a Notify call — reset the accumulator
        if (t.indexOf("member=Notify") !== -1) {
            _pending = ({})
            _argIndex = 0
            return
        }

        // ---- String argument ----
        if (t.indexOf("string ") === 0) {
            var s = _parseQuoted(t.substring(7))
            switch (_argIndex) {
                case 0: _pending.appName    = s; break
                case 1: _pending.replacesId = s; break
                case 2: _pending.appIcon    = s; break
                case 3: _pending.summary    = s; break
                case 4: _pending.body       = s; break
            }
            _argIndex++
            return
        }

        // ---- uint32 / int32 argument ----
        if (t.indexOf("uint32 ") === 0) {
            var u = parseInt(t.substring(7), 10)
            if (_argIndex === 1) { _pending.replacesId = u; _argIndex++ }
            else if (_argIndex >= 5) { _pending.timeout = u; _argIndex++ }
            return
        }
        if (t.indexOf("int32 ") === 0) {
            var i32 = parseInt(t.substring(6), 10)
            if (_argIndex === 1) { _pending.replacesId = i32; _argIndex++ }
            else if (_argIndex >= 5) { _pending.timeout = i32; _argIndex++ }
            return
        }

        // ---- boolean argument ----
        if (t.indexOf("boolean ") === 0) {
            _argIndex++
            return
        }

        // ---- End of argument list ----
        if (t === "]") {
            if (_pending.summary !== undefined || _pending.body !== undefined) {
                _pending.id = Date.now()
                _pending.timestamp = _pending.id
                notifMon._enqueue(_pending)
            }
            _pending = ({})
            _argIndex = 0
            return
        }
    }

    // Parse a D-Bus quoted string like:  "hello"   →   hello
    //                                     ""        →   (empty)
    //                                     "a\"b"    →   a"b
    function _parseQuoted(s) {
        s = s.trim()
        if (s.length === 0) return ""

        // Must start with a quote
        if (s.charAt(0) !== "\"") return s

        // Walk the string respecting backslash escapes
        var out = ""
        var i = 1
        while (i < s.length) {
            var c = s.charAt(i)
            if (c === "\\" && i + 1 < s.length) {
                var n = s.charAt(i + 1)
                switch (n) {
                    case "n":  out += "\n"; break
                    case "t":  out += "\t"; break
                    case "r":  out += "\r"; break
                    case "\"": out += "\""; break
                    case "\\": out += "\\"; break
                    default:   out += n
                }
                i += 2
                continue
            }
            if (c === "\"") {
                // Closing quote — stop here, discard trailing tokens
                break
            }
            out += c
            i++
        }
        return out
    }

    function _enqueue(n) {
        if (n.urgency === undefined) n.urgency = "normal"

        // Deduplicate by summary+body within 500ms
        for (var i = 0; i < queue.length; i++) {
            var q = queue[i]
            if (q.summary === n.summary && q.body === n.body &&
                (n.timestamp - q.timestamp) < 500) {
                return
            }
        }

        queue = queue.concat([n])
        notificationAdded(n)
        _showNext()
    }

    function _showNext() {
        if (current === null && queue.length > 0) {
            current = queue[0]
            queue = queue.slice(1)
            _scheduleDismiss()
        }
    }

    function dismissCurrent() {
        if (current === null) return
        var n = current
        current = null
        notificationDismissed(n)
        _dismissTimer.stop()
        _showNext()
    }

    function dismissAll() {
        queue = []
        dismissCurrent()
    }

    property Timer _dismissTimer: Timer {
        interval: notifMon.current
            ? (notifMon.current.timeout > 0
                ? notifMon.current.timeout
                : notifMon.defaultTimeout)
            : notifMon.defaultTimeout
        repeat: false
        running: notifMon.current !== null
        onTriggered: notifMon.dismissCurrent()
    }

    function _scheduleDismiss() {
        _dismissTimer.restart()
    }
}