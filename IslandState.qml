import QtQuick

QtObject {
    id: islandState

    property bool locked: false

    property bool islandHidden: false
    property bool revealedWhileHidden: false

    // "User hid the island from the Media tab"
    readonly property bool hiddenByUser:
        islandHidden && !revealedWhileHidden

    // "Locked into the minimal notch by swiping up"
    readonly property bool lockedDown:
        locked

    // Either state collapses the surface (used for reserved height).
    readonly property bool collapsed:
        hiddenByUser || lockedDown

    property int topBarHeight: 40
    property int islandHeight: 44

    readonly property int lockedBarHeight: 2
    readonly property int lockedIslandHeight: 14

    function toggleLock() {
        locked = !locked
    }

    function toggleIslandHidden() {
        islandHidden = !islandHidden
        if (!islandHidden)
            revealedWhileHidden = false
        // Ensure lock and hide are mutually exclusive.
        if (islandHidden) locked = false
    }

    function revealIsland() {
        // Only meaningful when hiding from the Media tab. Locked mode
        // has its own notch-click to unlock.
        revealedWhileHidden = true
    }

    function hideIslandAgain() {
        revealedWhileHidden = false
    }
}