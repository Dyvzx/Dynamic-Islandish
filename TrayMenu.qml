import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root
    required property var theme
    required property var menuHandle
    required property bool open
    required property var anchorItem
    // The Item to map coordinates into (usually the PanelWindow root)
    property var coordinateSpace: null

    signal closeRequested()

    visible: open && menuHandle !== null
    enabled: visible

    QsMenuOpener {
        id: menuOpener
        menu: root.menuHandle
    }

    readonly property point _anchorPos: {
        if (!root.anchorItem || typeof root.anchorItem.mapToItem !== "function")
            return Qt.point(0, 0)
        var space = root.coordinateSpace || root.parent
        return root.anchorItem.mapToItem(
            space,
            0,
            root.anchorItem.height + 8
        )
    }

    x: _anchorPos.x
    y: _anchorPos.y

    readonly property real contentWidth:
        Math.max(180, menuColumn.implicitWidth + 16)
    readonly property real contentHeight:
        Math.max(12, menuColumn.implicitHeight + 12)

    width: contentWidth
    height: contentHeight

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: 14
        color: root.theme.colBg
        border.color: "#2a2a2c"
        border.width: 1

        Rectangle {
            anchors.fill: parent
            anchors.margins: -6
            radius: parent.radius + 6
            color: "#000000"
            opacity: 0.25
            z: -1
        }
    }

    Column {
        id: menuColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 2

        Repeater {
            model: menuOpener.children

            delegate: TrayMenuEntry {
                required property var modelData
                width: menuColumn.width
                theme: root.theme
                entry: modelData
                depth: 0
                onTriggered: root.closeRequested()
            }
        }
    }

    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 140 } }
}