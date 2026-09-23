import QtQuick

QtObject {
    id: islandState

    property bool locked: false

    property bool islandHidden: false
    property bool revealedWhileHidden: false

    // ---- Feature toggles (set from MediaTab, read from DynamicIsland) ----
    property bool mediaPopupsEnabled: true
    property bool notificationsEnabled: true

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

    function toggleMediaPopups() {
        mediaPopupsEnabled = !mediaPopupsEnabled
    }

    function toggleNotifications() {
        notificationsEnabled = !notificationsEnabled
    }

    function rightClickHideOrWrap() {
        if (islandHidden) {
            revealedWhileHidden = false
            locked = false
            if (island && island.isExpanded !== undefined)
                island.isExpanded = false
        } else {
            if (island && island.isExpanded !== undefined)
                island.isExpanded = false
        }
    }
}