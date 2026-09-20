import QtQuick

QtObject {
    id: islandState

    property bool locked: false

    // When true, the island hides while a fullscreen app has focus.
    property bool autoHideOnFullscreen: false

    property int topBarHeight: 40
    property int islandHeight: 44

    readonly property int lockedBarHeight: 2
    readonly property int lockedIslandHeight: 14

    function toggleLock() {
        locked = !locked
    }

    function toggleAutoHide() {
        autoHideOnFullscreen = !autoHideOnFullscreen
    }
}