import QtQuick

QtObject {
    id: islandState

    property bool locked: false

    property bool islandHidden: false
    property bool revealedWhileHidden: false

    readonly property bool hiddenByUser:
        islandHidden && !revealedWhileHidden

    readonly property bool lockedDown:
        locked

    readonly property bool collapsed:
        hiddenByUser || lockedDown

    property int topBarHeight: 40
    property int islandHeight: 44

    readonly property int lockedBarHeight: 2
    readonly property int lockedIslandHeight: 14

    // Set from shell.qml so we can control expanded state.
    property var island: null

    function toggleLock() {
        locked = !locked
    }

    function toggleIslandHidden() {
        islandHidden = !islandHidden
        if (!islandHidden)
            revealedWhileHidden = false
        if (islandHidden) locked = false
    }

    function revealIsland() {
        revealedWhileHidden = true
    }

    function hideIslandAgain() {
        revealedWhileHidden = false
    }

    // ---- Right-click: hide or wrap ----
    // hide-island ON  → fully hide (same as hide-island button ON)
    // hide-island OFF → wrap to compact (collapse expanded state)
    function rightClickHideOrWrap() {
        if (islandHidden) {
            // Fully hide: keep islandHidden true, drop any temp reveal,
            // cancel locked mode, and collapse expanded state.
            revealedWhileHidden = false
            locked = false
            if (island && island.isExpanded !== undefined)
                island.isExpanded = false
        } else {
            // Wrap to compact: collapse expanded state only.
            if (island && island.isExpanded !== undefined)
                island.isExpanded = false
        }
    }
}