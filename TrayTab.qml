import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root
    required property var theme
    required property var island

    // ---- Signal out to DynamicIsland ----
    signal menuRequested(var sniItem, var anchor)
    signal menuDismissed()

    property var openMenuItem: null

    function closeMenu() {
        if (openMenuItem === null) return
        openMenuItem = null
        root.menuDismissed()
    }

    // ---- When the island collapses, drop the menu + selected state ----
    Connections {
        target: root.island
        ignoreUnknownSignals: true
        function onIsExpandedChanged() {
            if (root.island && root.island.isExpanded === false)
                root.closeMenu()
        }
    }

    Row {
        id: trayRow
        spacing: 6
        anchors.centerIn: parent

        property var hiddenApps: []

        function isHidden(appId) {
            if (!appId) return false
            var id = String(appId).toLowerCase()
            for (var i = 0; i < hiddenApps.length; i++)
                if (id.indexOf(hiddenApps[i].toLowerCase()) !== -1) return true
            return false
        }

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayItem
                required property var modelData
                width: 34
                height: 34

                readonly property bool isOpen:
                    root.openMenuItem === trayItem.modelData

                // Only show the "selected" accent while the cursor is
                // physically over this icon (matches the hover look).
                readonly property bool accentOn:
                    trayItem.isOpen && itemHover.hovered

                visible: {
                    if (!modelData) return false
                    var id = modelData.id ? String(modelData.id) : ""
                    return id !== "" && !trayRow.isHidden(id)
                }

                HoverHandler { id: itemHover }

                // ---- Outer glow ring (only while hovered + menu open) ----
                Rectangle {
                    id: glowRing
                    anchors.centerIn: parent
                    width: 34
                    height: 34
                    radius: 12
                    color: "transparent"
                    border.width: 1.5
                    border.color: root.theme.mediaColor

                    visible: trayItem.accentOn
                    opacity: 0

                    SequentialAnimation on opacity {
                        running: trayItem.accentOn
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.55; duration: 900; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 0.15; duration: 900; easing.type: Easing.InOutQuad }
                    }

                    // Softer, wider halo behind the ring
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 8
                        height: parent.height + 8
                        radius: width / 2
                        color: root.theme.mediaColor
                        opacity: 0.12
                        z: -1
                    }
                }

                // ---- Hover / selected pill ----
                Rectangle {
                    anchors.fill: parent
                    radius: 10

                    color: trayItem.accentOn
                        ? Qt.rgba(root.theme.mediaColor.r,
                                  root.theme.mediaColor.g,
                                  root.theme.mediaColor.b, 0.18)
                        : (itemHover.hovered
                            ? Qt.rgba(1, 1, 1, 0.08)
                            : "transparent")
                    border.width: 1
                    border.color: trayItem.accentOn
                        ? Qt.rgba(root.theme.mediaColor.r,
                                  root.theme.mediaColor.g,
                                  root.theme.mediaColor.b, 0.55)
                        : (itemHover.hovered
                            ? Qt.rgba(1, 1, 1, 0.14)
                            : "transparent")

                    Behavior on color        { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }
                }

                // ---- Icon ----
                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: (trayItem.modelData && trayItem.modelData.icon) ? trayItem.modelData.icon : ""
                    sourceSize.width: 20
                    sourceSize.height: 20
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: source !== "" && status !== Image.Error
                    scale: itemHover.hovered ? 1.12 : 1.0
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                // ---- Fallback initial ----
                Rectangle {
                    anchors.centerIn: parent
                    width: 22; height: 22; radius: 7
                    visible: !trayIcon.visible

                    color: trayItem.accentOn
                        ? Qt.rgba(root.theme.mediaColor.r,
                                  root.theme.mediaColor.g,
                                  root.theme.mediaColor.b, 0.20)
                        : (itemHover.hovered ? "#2a2a2c" : "#1c1c1e")
                    border.width: 1
                    border.color: trayItem.accentOn
                        ? root.theme.mediaColor
                        : "#2a2a2c"

                    Behavior on color        { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    Text {
                        anchors.centerIn: parent
                        text: (trayItem.modelData && trayItem.modelData.id)
                              ? String(trayItem.modelData.id).charAt(0).toUpperCase() : "?"
                        color: trayItem.accentOn
                            ? root.theme.mediaColor
                            : root.theme.colFg
                        font { family: root.theme.fontFamily; pixelSize: 11; bold: true }
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                }

                // ============================================================
                // INTERACTION LOGIC
                // ============================================================
                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function(mouse) {
                        var item = trayItem.modelData
                        if (!item) return

                        if (mouse.button === Qt.LeftButton) {
                            if (item.activate) item.activate()
                        } else if (mouse.button === Qt.RightButton) {
                            if (item.hasMenu && item.menu) {
                                if (root.openMenuItem === item) {
                                    root.openMenuItem = null
                                    root.menuDismissed()
                                } else {
                                    root.openMenuItem = item
                                    root.menuRequested(item, trayItem)
                                }
                            } else if (item.activate) {
                                item.activate()
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            if (item.secondaryActivate) item.secondaryActivate()
                        }
                    }
                }

                // ---- Tooltip: only while the cursor is over the icon ----
                Rectangle {
                    id: trayTooltip
                    visible: trayMouse.containsMouse
                             && trayItem.visible
                             && !trayMouse.pressed

                    color: trayItem.accentOn ? "#1c1c1e" : "#161618"
                    radius: 8
                    border.color: trayItem.accentOn
                        ? Qt.rgba(root.theme.mediaColor.r,
                                  root.theme.mediaColor.g,
                                  root.theme.mediaColor.b, 0.55)
                        : "#2a2a2c"
                    border.width: 1

                    anchors.top: parent.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: tipText.width + 20
                    height: tipText.height + 10
                    z: 10

                    Behavior on border.color { ColorAnimation { duration: 180 } }
                    Behavior on color        { ColorAnimation { duration: 180 } }

                    // Caret
                    Rectangle {
                        width: 8; height: 8
                        rotation: 45
                        color: parent.color
                        border.color: parent.border.color
                        border.width: parent.border.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: -4
                        z: -1
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                    }

                    Text {
                        id: tipText
                        anchors.centerIn: parent
                        text: {
                            if (!trayItem.modelData) return "Tray"
                            if (trayItem.modelData.tooltip) return String(trayItem.modelData.tooltip)
                            if (trayItem.modelData.title)   return String(trayItem.modelData.title)
                            if (trayItem.modelData.id)      return String(trayItem.modelData.id)
                            return "Tray"
                        }
                        color: trayItem.accentOn
                            ? root.theme.mediaColor
                            : root.theme.colFg
                        font {
                            family: root.theme.fontFamily
                            pixelSize: 11
                            bold: trayItem.accentOn
                        }
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                }
            }
        }
    }

    // ---- Empty state ----
    Rectangle {
        anchors.centerIn: parent
        visible: {
            var items = SystemTray.items
            return !items || items.count === 0
        }
        width: emptyText.width + 24
        height: 30
        radius: 15
        color: "#12ffffff"
        border.color: "#1affffff"
        border.width: 1

        Text {
            id: emptyText
            anchors.centerIn: parent
            text: "No tray items"
            color: root.theme.colMuted
            font { family: root.theme.fontFamily; pixelSize: 12 }
        }
    }
}