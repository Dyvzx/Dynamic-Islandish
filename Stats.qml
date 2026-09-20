import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: stats
    property int cpuUsage: 0
    property real usedMemGB: 0
    property real totalMemGB: 16
    property real lastCpuIdle: 0
    property real lastCpuTotal: 0

    property Process cpuProc: Process {
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var p = data.trim().split(/\s+/)
                var idle = parseInt(p[4]) + parseInt(p[5])
                var total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)
                if (stats.lastCpuTotal > 0)
                    stats.cpuUsage = Math.round(
                        100 * (1 - (idle - stats.lastCpuIdle) / (total - stats.lastCpuTotal))
                    )
                stats.lastCpuTotal = total
                stats.lastCpuIdle = idle
            }
        }
        Component.onCompleted: running = true
    }

    property Process memProc: Process {
        command: ["sh", "-c", "free -m | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                if (parts.length >= 3) {
                    var totalMiB = parseFloat(parts[1])
                    var usedMiB  = parseFloat(parts[2])
                    if (!isNaN(totalMiB) && totalMiB > 0)
                        stats.totalMemGB = totalMiB / 1024
                    if (!isNaN(usedMiB))
                        stats.usedMemGB = usedMiB / 1024
                }
            }
        }
        Component.onCompleted: running = true
    }

    property Timer tick: Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: { stats.cpuProc.running = true; stats.memProc.running = true }
    }
}