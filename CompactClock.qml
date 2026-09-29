import QtQuick

Item {
    id: compactClock
    required property var theme

    // ---- Fixed footprint (matches CavaVisualizer) ----
    implicitWidth: 142
    implicitHeight: 24

    function fmt() {
        var now = new Date()
        var adj = new Date(now.getTime() - 6 * 60 * 60 * 1000)
        return Qt.formatDateTime(now, "hh:mm AP") + " / " +
               Qt.formatDateTime(adj, "hh:mm AP")
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        color: "#ffffff"
        font {
            family: compactClock.theme.fontFamily
            pixelSize: 13
            bold: true
        }
        text: compactClock.fmt()
    }

    Timer {
        interval: 1000
        running: compactClock.visible
        repeat: true
        onTriggered: clockText.text = compactClock.fmt()
    }
}