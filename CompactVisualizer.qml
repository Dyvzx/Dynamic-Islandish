import QtQuick
import Quickshell.Services.Mpris

Row {
    id: compactVisualizer
    required property var theme
    required property bool activeAudio
    required property int liveVolume

    spacing: 0

    // Current MPRIS player (same selection rule Theme.qml uses).
    readonly property var player: {
        var ps = Mpris.players ? Mpris.players.values : []
        if (!ps || ps.length === 0) return null
        for (var i = 0; i < ps.length; i++)
            if (ps[i] && ps[i].isPlaying) return ps[i]
        return ps[0]
    }

    readonly property string artUrl: {
        var p = player
        return (p && p.trackArtUrl) ? String(p.trackArtUrl) : ""
    }

    // ---- Left: album art ----
    Rectangle {
        id: artFrame
        width: 24
        height: 24
        radius: 6
        anchors.verticalCenter: parent.verticalCenter
        color: compactVisualizer.theme.colBgSoft
        clip: true

        Behavior on color { ColorAnimation { duration: 220 } }

        Image {
            id: artImg
            anchors.fill: parent
            source: compactVisualizer.artUrl
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            visible: source !== "" && status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            visible: !artImg.visible
            text: "\uF001"
            color: compactVisualizer.theme.colMuted
            font {
                family: compactVisualizer.theme.fontFamily
                pixelSize: 12
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: compactVisualizer.activeAudio
                ? compactVisualizer.theme.mediaColor
                : "#1affffff"
            Behavior on border.color { ColorAnimation { duration: 220 } }
        }
    }

    // ---- Middle: spacer pushes the visualizer to the right ----
    // Widened to make this widget's total implicit width match the
    // clock widget's width, so the compact pill stays the same size
    // when toggling between the two via mouse wheel.
    Item {
        width: 100
        height: 1
    }

    // ---- Right: mini visualizer ----
    Row {
        id: bars
        spacing: 2
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: 4
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
                    if (!compactVisualizer.activeAudio) return 3
                    var t = visualizerTick.counter
                    var base = 5
                    var swing = Math.max(4, compactVisualizer.liveVolume * 0.10)
                    var wave = Math.abs(Math.sin((t + barRect.phase) * 0.9))
                    return base + swing * wave
                }
                Behavior on height { NumberAnimation { duration: 120 } }
            }
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
