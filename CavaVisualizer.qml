import QtQuick
import Quickshell.Services.Mpris

Item {
    id: cavaViz
    required property var theme
    required property var cava
    required property bool activeAudio

    // ---- Layout mode ----
    // compact: true  → fixed 142 px footprint (matches CompactClock),
    //                  art on left, bars on right, wide gap between.
    // compact: false → natural intrinsic width (art + gap + bars),
    //                  used in the expanded Media tab.
    property bool compact: true

    readonly property real compactWidth: 142
    readonly property real naturalWidth:
        (showArt ? artSize : 0)
        + (showArt ? artGap : 0)
        + (barCount * barWidth + Math.max(0, barCount - 1) * barSpacing)

    implicitWidth:  compact ? compactWidth : naturalWidth
    implicitHeight: 24

    // ---- Configurable geometry ----
    property real barWidth: 3
    property real barSpacing: 2
    property real minBarHeight: 3
    property real maxBarHeight: 22

    // ---- Album art frame ----
    property bool showArt: true
    property real artSize: 24
    property real artGap: 10

    readonly property int barCount: cava ? cava.barCount : 12

    // ---- Current MPRIS player ----
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
        visible: cavaViz.showArt
        width: cavaViz.showArt ? cavaViz.artSize : 0
        height: cavaViz.artSize
        radius: 6
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: cavaViz.theme.colBgSoft
        clip: true

        Behavior on color { ColorAnimation { duration: 220 } }

        Image {
            id: artImg
            anchors.fill: parent
            source: cavaViz.artUrl
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            visible: source !== "" && status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            visible: !artImg.visible
            text: "\uF001"
            color: cavaViz.theme.colMuted
            font {
                family: cavaViz.theme.fontFamily
                pixelSize: 12
            }
        }
    }

    // ---- Right: CAVA bars ----
    Row {
        id: barsRow
        spacing: cavaViz.barSpacing
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: cavaViz.barCount

            Rectangle {
                id: bar
                width: cavaViz.barWidth
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter

                readonly property real level: {
                    if (!cavaViz.cava) return 0
                    if (!cavaViz.activeAudio) return 0
                    var v = cavaViz.cava.bars[index]
                    return (v === undefined) ? 0 : v
                }

                height: cavaViz.minBarHeight
                    + (cavaViz.maxBarHeight - cavaViz.minBarHeight) * level

                color: cavaViz.activeAudio
                    ? cavaViz.theme.mediaColor
                    : cavaViz.theme.colDim

                Behavior on height { NumberAnimation { duration: 70; easing.type: Easing.OutQuad } }
                Behavior on color  { ColorAnimation  { duration: 220 } }
            }
        }
    }
}