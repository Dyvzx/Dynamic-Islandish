import QtQuick

Text {
    id: compactClock
    required property var theme

    color: "#ffffff"
    font {
        family: theme.fontFamily
        pixelSize: 13
        bold: true
    }

    function fmt() {
        var now = new Date()
        var adj = new Date(now.getTime() - 6 * 60 * 60 * 1000)
        return Qt.formatDateTime(now, "hh:mm AP") + " / " +
               Qt.formatDateTime(adj, "hh:mm AP")
    }
    text: fmt()

    Timer {
        interval: 1000
        running: compactClock.visible
        repeat: true
        onTriggered: compactClock.text = compactClock.fmt()
    }
}