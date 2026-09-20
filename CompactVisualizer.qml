import QtQuick

Row {
    id: compactVisualizer
    required property var theme
    required property bool activeAudio
    required property int liveVolume

    spacing: 3

    Repeater {
        model: 5
        Rectangle {
            id: barRect
            width: 3
            radius: 1.5
            color: compactVisualizer.activeAudio
                ? compactVisualizer.theme.mediaColor
                : compactVisualizer.theme.colDim
            anchors.verticalCenter: parent.verticalCenter
            property int phase: index

            Behavior on color { ColorAnimation { duration: 220 } }

            height: {
                if (!compactVisualizer.activeAudio) return 2
                var t = visualizerTick.counter
                var base = 4
                var swing = Math.max(4, compactVisualizer.liveVolume * 0.10)
                var wave = Math.abs(Math.sin((t + barRect.phase) * 0.9))
                return base + swing * wave
            }
            Behavior on height { NumberAnimation { duration: 120 } }
        }
    }

    Timer {
        id: visualizerTick
        interval: 120
        running: compactVisualizer.activeAudio && compactVisualizer.visible
        repeat: true
        property int counter: 0
        onTriggered: counter++
    }
}