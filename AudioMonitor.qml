import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: audioMon

    // True when the default sink is actively producing samples.
    // Flips to false within ~1 graph quantum of real silence — no
    // Chromium/Electron keep-alive lag, no parec buffering.
    property bool audioActive: false

    // Internal: latest raw reading (bypasses the debounce timer)
    property bool _rawRunning: false

    property Process stateProc: Process {
        command: ["sh", "-c",
            "wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null " +
            "| grep -m1 'node.state' " +
            "| grep -oP '\"[^\"]*\"$' | tr -d '\"'"
        ]
        stdout: SplitParser {
            onRead: data => {
                var s = data.trim()
                audioMon._rawRunning = (s === "running")
            }
        }
    }

    property Timer pollTimer: Timer {
        interval: 150
        running: true
        repeat: true
        onTriggered: {
            stateProc.running = false
            stateProc.running = true
        }
    }

    // Debounce: turn on instantly, turn off only after 300ms of continuous idle.
    // Worst-case stop latency = 150 (poll) + ~20 (spawn) + 300 (debounce) ≈ 470ms.
    property Timer offDelay: Timer {
        interval: 300
        repeat: false
        onTriggered: audioMon.audioActive = false
    }

    on_RawRunningChanged: {
        if (_rawRunning) {
            offDelay.stop()
            audioActive = true
        } else {
            offDelay.restart()
        }
    }
}