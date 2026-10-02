import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root
    required property var theme
    property var parentEntry
    property int depth: 0

    signal triggered()

    QsMenuOpener {
        id: submenuOpener
        menu: root.parentEntry ? root.parentEntry.menu : null
    }

    implicitWidth: submenuColumn.implicitWidth + 16
    implicitHeight: submenuColumn.implicitHeight + 12

    Rectangle {
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
        id: submenuColumn
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: submenuOpener.children

            delegate: TrayMenuEntry {
                required property var modelData
                width: submenuColumn.width
                theme: root.theme
                entry: modelData
                depth: root.depth
                onTriggered: root.triggered()
            }
        }
    }
}
