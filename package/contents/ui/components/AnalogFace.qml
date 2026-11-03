import QtQuick

// Round analog clock face for the clock-style tile. The face (ticks) is a Canvas
// drawn once per size or color change; the hands are plain rotated rectangles,
// so a moving second hand costs a transform, not a repaint.
// Set `hours`, `minutes`, `seconds` (fractional seconds give a sweeping hand).
Item {
    id: face

    property real hours: 0
    property real minutes: 0
    property real seconds: 0

    property color faceColor: "white"
    property color rimColor: "transparent"
    property color tickColor: Qt.alpha("black", 0.55)
    property color majorTickColor: tickColor
    property color numeralColor: "black"
    property color hourHandColor: "black"
    property color minuteHandColor: "black"
    property color secondHandColor: "#FF3B30"
    property color hubColor: hourHandColor

    // "minutes": 60 rim ticks; "hours": 12 ticks, longer at 12/3/6/9;
    // "quarters": only 12/3/6/9; "none".
    property string ticks: "minutes"
    property bool numerals: false
    property bool showSeconds: true
    // Hub drawn as a ring (hollow centre), like the minimal face.
    property bool hubRing: false

    readonly property real diameter: Math.min(width, height)
    readonly property real r: diameter / 2

    implicitWidth: 40
    implicitHeight: 40

    Rectangle {
        anchors.centerIn: parent
        width: face.diameter
        height: width
        radius: width / 2
        color: face.faceColor
        border.width: face.rimColor.a > 0 ? Math.max(1, face.diameter * 0.02) : 0
        border.color: face.rimColor
        antialiasing: true
    }

    Canvas {
        id: tickCanvas
        anchors.centerIn: parent
        width: face.diameter
        height: width
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const r = width / 2;
            if (face.ticks === "none" || r <= 0)
                return;
            ctx.translate(r, r);
            ctx.lineCap = "round";
            const step = face.ticks === "minutes" ? 60 : 12;
            for (let i = 0; i < step; i++) {
                const hourIdx = face.ticks === "minutes" ? i / 5 : i;
                const isHour = face.ticks !== "minutes" || i % 5 === 0;
                const isQuarter = isHour && hourIdx % 3 === 0;
                if (face.ticks === "quarters" && !isQuarter)
                    continue;
                // Rim ticks under numerals would collide with them.
                if (face.numerals && isQuarter && face.ticks === "minutes")
                    continue;
                let len, w, col;
                if (face.ticks === "minutes") {
                    len = isHour ? r * 0.12 : r * 0.07;
                    w = isHour ? Math.max(1, r * 0.035) : Math.max(0.6, r * 0.018);
                    col = isHour ? face.majorTickColor : face.tickColor;
                } else {
                    len = isQuarter ? r * 0.2 : r * 0.12;
                    w = Math.max(1, r * (isQuarter ? 0.06 : 0.045));
                    col = isQuarter ? face.majorTickColor : face.tickColor;
                }
                const a = i / step * Math.PI * 2;
                const out = r * 0.9;
                ctx.strokeStyle = col;
                ctx.lineWidth = w;
                ctx.beginPath();
                ctx.moveTo(Math.sin(a) * out, -Math.cos(a) * out);
                ctx.lineTo(Math.sin(a) * (out - len), -Math.cos(a) * (out - len));
                ctx.stroke();
            }
        }

        Connections {
            target: face
            function onTicksChanged() { tickCanvas.requestPaint(); }
            function onTickColorChanged() { tickCanvas.requestPaint(); }
            function onMajorTickColorChanged() { tickCanvas.requestPaint(); }
            function onNumeralsChanged() { tickCanvas.requestPaint(); }
        }
        onWidthChanged: requestPaint()
    }

    // 12 / 3 / 6 / 9.
    Repeater {
        model: face.numerals ? [12, 3, 6, 9] : []

        Text {
            required property int modelData
            required property int index
            readonly property real a: index * Math.PI / 2
            readonly property real dist: face.r * 0.68
            x: face.width / 2 + Math.sin(a) * dist - width / 2
            y: face.height / 2 - Math.cos(a) * dist - height / 2
            text: modelData
            color: face.numeralColor
            font.pixelSize: Math.max(5, face.r * 0.3)
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }
    }

    component Hand: Rectangle {
        id: hand
        property real handAngle
        property real length
        property real tail: 0
        width: Math.max(1, face.r * 0.06)
        height: length + tail
        radius: width / 2
        antialiasing: true
        x: face.width / 2 - width / 2
        y: face.height / 2 - length
        transform: Rotation {
            origin.x: hand.width / 2
            origin.y: hand.length
            angle: hand.handAngle
        }
    }

    Hand {
        handAngle: (face.hours % 12 + face.minutes / 60) * 30
        length: face.r * 0.5
        width: Math.max(1.5, face.r * 0.1)
        color: face.hourHandColor
    }
    Hand {
        handAngle: (face.minutes + face.seconds / 60) * 6
        length: face.r * 0.76
        width: Math.max(1.2, face.r * 0.075)
        color: face.minuteHandColor
    }
    Hand {
        visible: face.showSeconds
        handAngle: face.seconds * 6
        length: face.r * 0.82
        tail: face.r * 0.16
        width: Math.max(0.8, face.r * 0.03)
        color: face.secondHandColor
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.max(3, face.r * (face.hubRing ? 0.2 : 0.14))
        height: width
        radius: width / 2
        color: face.hubRing ? face.faceColor : face.hubColor
        border.width: face.hubRing ? Math.max(1, width * 0.3) : 0
        border.color: face.hubColor
        antialiasing: true
    }
}
