import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar
    anchors.top: true
    anchors.left: true
    anchors.right: true

    required property var islandState

    // Bar reserved height:
    //   - If the island is collapsed (hidden by user, or locked), the
    //     bar reserves only the tiny "lockedBarHeight".
    //   - Otherwise it reserves the full top-bar height, minus the
    //     4 px gap that no longer exists when notch mode is on.
    readonly property int notchGapCompensation:
        islandState.notchMode ? 4 : 0

    readonly property int fullHeight:
        islandState.topBarHeight - notchGapCompensation

    implicitHeight: islandState.collapsed
        ? islandState.lockedBarHeight
        : fullHeight

    // Only animate the notch-mode transition; the collapsed toggle
    // must be instantaneous so the reservation and the island's own
    // height change in the same frame, with no visible lag.
    Behavior on implicitHeight {
        enabled: !islandState.collapsed
        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
    }

    color: "transparent"

    Item {
        anchors.fill: parent
        opacity: islandState.collapsed ? 0 : 1
        Behavior on opacity {
            enabled: !islandState.collapsed
            NumberAnimation { duration: 200 }
        }
    }
}