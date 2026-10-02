import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root
    required property var theme
    required property var entry
    property int depth: 0

    signal triggered()

    readonly property bool isSeparator:
        entry && entry.isSeparator === true

    readonly property bool hasSubmenu:
        entry && entry.hasChildren === true

    readonly property bool isEnabled:
        !entry || entry.enabled !== false

    property bool submenuOpen: false

    implicitHeight: isSeparator ? 9 : 30
    width: parent ? parent.width : 200

    Rectangle {
        visible: root.isSeparator
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        height: 1
        color: "#2a2a2c"
    }

    Rectangle {
        id: rowBg
        visible: !root.isSeparator
        anchors.fill: parent
        radius: 8
        color: (rowHover.hovered && root.isEnabled)
            ? "#18ffffff"
            : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 6 + root.depth * 12
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Item {
                id: checkMark
                width: 14; height: 14
                anchors.verticalCenter: parent.verticalCenter
                visible: root.entry
                    && (root.entry.checkState === Qt.Checked
                        || root.entry.checkState === Qt.PartiallyChecked)

                Rectangle {
                    anchors.fill: parent
                    radius: root.entry && root.entry.isRadio === true ? 7 : 3
                    color: "#2a2a2c"
                    border.color: root.theme.mediaColor
                    border.width: 1

                    Rectangle {
                        anchors.centerIn: parent
                        width: 7; height: 7
                        radius: root.entry && root.entry.isRadio === true ? 4 : 2
                        color: root.theme.mediaColor
                    }
                }
            }

            Image {
                id: entryIcon
                width: 16; height: 16
                anchors.verticalCenter: parent.verticalCenter
                source: root.entry && root.entry.icon ? root.entry.icon : ""
                sourceSize.width: 16
                sourceSize.height: 16
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: source !== "" && status === Image.Ready
            }

            Text {
                id: entryText
                anchors.verticalCenter: parent.verticalCenter
                text: root.entry ? (root.entry.text || "") : ""
                color: root.isEnabled
                    ? root.theme.colFg
                    : root.theme.colMuted
                font {
                    family: root.theme.fontFamily
                    pixelSize: 12
                    bold: false
                }
                elide: Text.ElideRight
                width: Math.max(0, rowBg.width
                       - (6 + root.depth * 12)
                       - 6
                       - (entryIcon.visible ? entryIcon.width + 8 : 0)
                       - (root.hasSubmenu ? 18 : 0)
                       - (checkMark.visible ? checkMark.width + 8 : 0))
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.hasSubmenu
                text: "\uF105"
                color: root.theme.colMuted
                font { family: root.theme.fontFamily; pixelSize: 11 }
            }
        }
    }

    HoverHandler {
        id: rowHover
        enabled: !root.isSeparator && root.isEnabled
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.isSeparator && root.isEnabled
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        onClicked: {
            if (root.hasSubmenu) {
                root.submenuOpen = !root.submenuOpen
                return
            }
            if (root.entry && root.entry.triggered)
                root.entry.triggered()
            root.triggered()
        }
    }

    Loader {
        id: entryLoader
        active: root.submenuOpen && root.hasSubmenu
        anchors.left: parent.right
        anchors.leftMargin: 4
        anchors.top: parent.top
        source: "TraySubmenu.qml"

        onLoaded: {
            item.theme = root.theme
            item.parentEntry = root.entry
            item.depth = root.depth + 1
        }
    }

    // Re-emit the submenu's triggered signal through this entry
    Connections {
        target: entryLoader.item
        ignoreUnknownSignals: true
        function onTriggered() { root.triggered() }
    }
}