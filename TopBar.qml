import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar
    anchors.top: true
    anchors.left: true
    anchors.right: true

    required property var islandState

    // Bar reserves full height only when the island is visible AND
    // not revealed-from-hidden. Both the bar and the island read the
    // same `collapsed` flag so their reservations stay in sync.
    implicitHeight: islandState.collapsed
        ? islandState.lockedBarHeight
        : islandState.topBarHeight

    Behavior on implicitHeight {
        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
    }

    color: "transparent"

    Item {
        anchors.fill: parent
        opacity: islandState.collapsed ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}