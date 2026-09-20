import QtQuick
import Quickshell.Services.SystemTray

Item {
    id: root
    required property var theme
    required property var island

    Row {
        id: trayRow
        spacing: 8
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
                width: 24
                height: 24

                visible: {
                    if (!modelData) return false
                    var id = modelData.id ? String(modelData.id) : ""
                    return id !== "" && !trayRow.isHidden(id)
                }

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
                }
                Text {
                    anchors.centerIn: parent
                    visible: !trayIcon.visible
                    text: (trayItem.modelData && trayItem.modelData.id)
                          ? String(trayItem.modelData.id).charAt(0).toUpperCase() : "?"
                    color: root.theme.colFg
                    font { family: root.theme.fontFamily; pixelSize: 12; bold: true }
                }

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
                            if (item.hasMenu && item.display) {
                                var pt = trayItem.mapToItem(root.island.contentItem, 0, trayItem.height + 2)
                                item.display(root.island, pt.x, pt.y)
                            } else if (item.activate) {
                                item.activate()
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            if (item.secondaryActivate) item.secondaryActivate()
                        }
                    }
                }

                Rectangle {
                    id: trayTooltip
                    visible: trayMouse.containsMouse && trayItem.visible && !trayMouse.pressed
                    color: "#2a2a2a"
                    radius: 4
                    border.color: root.theme.colMuted
                    border.width: 1
                    anchors.top: parent.bottom
                    anchors.topMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: tipText.width + 12
                    height: tipText.height + 6
                    z: 10

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
                        color: root.theme.colFg
                        font { family: root.theme.fontFamily; pixelSize: 11 }
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: {
            var items = SystemTray.items
            return !items || items.count === 0
        }
        text: "No tray items"
        color: root.theme.colMuted
        font { family: root.theme.fontFamily; pixelSize: 12 }
    }
}