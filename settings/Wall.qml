import QtQuick

// Accent-tinted ribbon backdrop. Night and day layers crossfade.
Item {
    id: w
    clip: true
    component Layer: Item {
        id: l
        property color bg0
        property color bg1
        property var ribbons
        anchors.fill: parent
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: l.bg0 } GradientStop { position: 1; color: l.bg1 } } }
        Repeater {
            model: l.ribbons
            Rectangle {
                required property var modelData
                width: w.width * modelData.w
                height: w.height * modelData.h
                x: w.width * modelData.x
                y: w.height * modelData.y
                rotation: -28
                radius: height / 2
                opacity: modelData.o
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0) }
                    GradientStop { position: 0.35; color: modelData.c1 }
                    GradientStop { position: 0.7; color: modelData.c2 }
                    GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0) }
                }
            }
        }
    }
    // Ribbons take the accent hue, with a small shift between the two ends of each.
    function hh(d) { return ((Theme.hue + d) % 1 + 1) % 1; }
    function c(d, s, l) { return Qt.hsla(hh(d), s * Theme.tint, l, 1); }
    Layer {
        opacity: Theme.dark ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 500 } }
        bg0: w.c(0, 0.60, 0.10); bg1: w.c(0, 0.65, 0.07)
        ribbons: [
            { x: -0.3, y: 0.15, w: 1.5, h: 0.14, o: 0.55, c1: w.c(0, 0.65, 0.42), c2: w.c(0.02, 0.95, 0.65) },
            { x: -0.1, y: 0.62, w: 1.3, h: 0.07, o: 0.5, c1: w.c(0.02, 1, 0.74), c2: w.c(-0.06, 0.65, 0.5) },
            { x: 0.3, y: -0.1, w: 1.0, h: 0.24, o: 0.42, c1: w.c(-0.07, 0.7, 0.4), c2: w.c(0.03, 0.65, 0.52) }
        ]
    }
    Layer {
        opacity: Theme.dark ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 500 } }
        bg0: w.c(0, 0.80, 0.96); bg1: w.c(-0.04, 0.70, 0.94)
        ribbons: [
            { x: -0.3, y: 0.15, w: 1.5, h: 0.14, o: 0.6, c1: w.c(0, 1, 0.80), c2: w.c(0.04, 1, 0.82) },
            { x: -0.1, y: 0.62, w: 1.3, h: 0.07, o: 0.55, c1: w.c(-0.06, 1, 0.82), c2: w.c(0, 1, 0.80) },
            { x: 0.3, y: -0.1, w: 1.0, h: 0.24, o: 0.5, c1: w.c(-0.05, 1, 0.86), c2: w.c(0.03, 1, 0.85) }
        ]
    }
}
