import QtQuick

QtObject {
    id: islandState

    property bool locked: false

    // When true, the island collapses to a small reveal strip and the
    // reserved top-bar space shrinks to the minimum.
    property bool islandHidden: false

    // Set to true when the user clicks the reveal strip to bring the
    // island back temporarily. Reset to false when they click away.
    property bool revealedWhileHidden: false

    // Single source of truth for "is the island currently collapsed
    // (bar + island both shrink)". Both PanelWindows read this.
    readonly property bool collapsed:
        (islandHidden && !revealedWhileHidden) || locked

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
    }

    function revealIsland() {
        revealedWhileHidden = true
    }

    function hideIslandAgain() {
        revealedWhileHidden = false
    }
}