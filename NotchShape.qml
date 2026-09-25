import QtQuick

Item {
    id: root

    property color fillColor:   "#0a0a0a"
    property color strokeColor: "#1c1c1e"
    property real  strokeWidth: 1
    property real  bottomRadius: 22
    property real  fillet: 10

    implicitWidth:  300
    implicitHeight: 36

    onWidthChanged:        canvas.requestPaint()
    onHeightChanged:       canvas.requestPaint()
    onFillColorChanged:    canvas.requestPaint()
    onStrokeColorChanged:  canvas.requestPaint()
    onStrokeWidthChanged:  canvas.requestPaint()
    onBottomRadiusChanged: canvas.requestPaint()
    onFilletChanged:       canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            var w = width
            var h = height
            var sw = root.strokeWidth
            var f  = Math.max(1, Math.min(root.fillet,
                                          Math.min(w, h) / 2))
            var br = Math.max(0, Math.min(root.bottomRadius,
                                          Math.min(w, h) / 2))

            var inset = sw / 2
            var x0 = inset + f
            var y0 = inset
            var x1 = w - inset - f
            var y1 = h - inset

            var xL = x0 - f
            var xR = x1 + f

            ctx.beginPath()
            ctx.moveTo(xL, y0)
            ctx.quadraticCurveTo(x0, y0, x0, y0 + f)
            ctx.lineTo(x0, y1 - br)
            ctx.quadraticCurveTo(x0, y1, x0 + br, y1)
            ctx.lineTo(x1 - br, y1)
            ctx.quadraticCurveTo(x1, y1, x1, y1 - br)
            ctx.lineTo(x1, y0 + f)
            ctx.quadraticCurveTo(x1, y0, xR, y0)
            ctx.closePath()

            ctx.fillStyle = root.fillColor
            ctx.fill()

            if (sw > 0) {
                ctx.lineWidth = sw
                ctx.strokeStyle = root.strokeColor
                ctx.lineJoin = "round"
                ctx.lineCap = "round"
                ctx.stroke()
            }
        }
    }
}
