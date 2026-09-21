import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

QtObject {
    id: theme

    property color colBg:      "#0a0a0a"
    property color colBgSoft:  "#141414"
    property color colFg:      "#ffffff"
    property color colMuted:   "#7c7c80"
    property color colDim:     "#3a3a3c"
    property color colRed:     "#f7768e"
    property color colGreen:   "#9ece6a"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    property bool wallpaperIsDark: true
    readonly property color adaptiveFg: wallpaperIsDark ? "#ffffff" : "#1a1b26"

    property color mediaColor: "#ffffff"
    property string _lastArtUrl: ""

    function _parseHex(hex) {
        var h = String(hex).trim()
        if (!h) return ""
        if (h[0] !== "#") h = "#" + h
        if (h.length >= 7) return h.substring(0, 7)
        return ""
    }

    function _ensureVisible(hex) {
        var h = hex.substring(1)
        var r = parseInt(h.substring(0, 2), 16) / 255
        var g = parseInt(h.substring(2, 4), 16) / 255
        var b = parseInt(h.substring(4, 6), 16) / 255

        var max = Math.max(r, g, b)
        var min = Math.min(r, g, b)
        var delta = max - min
        var v = max
        var s = (max === 0) ? 0 : delta / max
        var hue = 0
        if (delta !== 0) {
            if (max === r)      hue = ((g - b) / delta) % 6
            else if (max === g) hue = (b - r) / delta + 2
            else                hue = (r - g) / delta + 4
            hue *= 60
            if (hue < 0) hue += 360
        }

        var minV = 0.55
        var minS = 0.35
        if (v < minV) v = minV
        if (delta !== 0 && s < minS) s = minS

        var c = v * s
        var x = c * (1 - Math.abs(((hue / 60) % 2) - 1))
        var m = v - c
        var rp = 0, gp = 0, bp = 0
        if      (hue <  60) { rp = c; gp = x; bp = 0 }
        else if (hue < 120) { rp = x; gp = c; bp = 0 }
        else if (hue < 180) { rp = 0; gp = c; bp = x }
        else if (hue < 240) { rp = 0; gp = x; bp = c }
        else if (hue < 300) { rp = x; gp = 0; bp = c }
        else                { rp = c; gp = 0; bp = x }

        function toHex(n) {
            var str = Math.round((n + m) * 255).toString(16)
            return str.length === 1 ? "0" + str : str
        }
        return "#" + toHex(rp) + toHex(gp) + toHex(bp)
    }

    function refreshMediaColor() {
        var p = currentPlayer()
        var url = (p && p.trackArtUrl) ? String(p.trackArtUrl) : ""

        if (url === _lastArtUrl) return
        _lastArtUrl = url

        if (!url) {
            mediaColor = "#ffffff"
            return
        }

        var cmd =
            "src=" + JSON.stringify(url) + "; " +
            "if [ \"${src#http}\" != \"$src\" ]; then " +
                "tmp=$(mktemp /tmp/qs-art-XXXXXX); " +
                "curl -sL \"$src\" -o \"$tmp\" 2>/dev/null; src=\"$tmp\"; " +
            "elif [ \"${src#file://}\" != \"$src\" ]; then " +
                "src=\"${src#file://}\"; " +
            "fi; " +
            "stable=/tmp/qs-art-current; " +
            "cp -- \"$src\" \"$stable\" 2>/dev/null || exit 1; " +
            "bin=$(command -v magick || command -v convert); " +
            "[ -z \"$bin\" ] && echo \"no magick/convert\" 1>&2 && exit 1; " +
            "\"$bin\" \"$stable\" -resize 1x1 -format '%[hex:p{0,0}]' info:- 2>/dev/null"

        _colorProc.command = ["sh", "-c", cmd]
        _colorProc.running = false
        _colorProc.running = true
    }

    property Process _colorProc: Process {
        id: _colorProc
        stdout: SplitParser {
            onRead: data => {
                var raw = data.trim()
                var hex = theme._parseHex(raw)
                if (hex !== "") {
                    var fixed = theme._ensureVisible(hex)
                    theme.mediaColor = fixed
                }
            }
        }
        stderr: SplitParser {
            onRead: data => console.log("art stderr:", data)
        }
    }

    property Timer _artPoller: Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: theme.refreshMediaColor()
    }
    Component.onCompleted: refreshMediaColor()

    function currentPlayer() {
        var ps = Mpris.players ? Mpris.players.values : []
        if (!ps || ps.length === 0) return null
        for (var i = 0; i < ps.length; i++)
            if (ps[i] && ps[i].isPlaying) return ps[i]
        return ps[0]
    }

    function artistString(a) {
        if (!a) return ""
        if (typeof a === "string") return a
        if (a.length === undefined) return String(a)
        var out = ""
        for (var i = 0; i < a.length; i++) { if (i > 0) out += ", "; out += a[i] }
        return out
    }

    function fmtTime(sec) {
        if (!sec || sec < 0) return "0:00"
        var s = Math.floor(sec)
        return Math.floor(s/60) + ":" + ("0"+(s%60)).slice(-2)
    }
}