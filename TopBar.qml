import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar
    anchors.top: true
    anchors.left: true
    anchors.right: true

    required property var islandState

    implicitHeight: islandState.locked ? islandState.lockedBarHeight
                                       : islandState.topBarHeight

    Behavior on implicitHeight {
        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
    }

    color: "transparent"

    // Normal bar content fades out when locked.
    Item {
        anchors.fill: parent
        opacity: islandState.locked ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}