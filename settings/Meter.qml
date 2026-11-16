import QtQuick

// Thin horizontal gauge (memory, disk, battery). value 0..1.
Rectangle {
    id: m
    property real value: 0
    property color fill: value > 0.9 ? Theme.bad : Theme.accent
    implicitHeight: 6
    radius: height / 2
    color: Theme.track
    Rectangle {
        width: Math.max(m.height, Math.min(1, m.value) * m.width)
        height: m.height
        radius: m.radius
        color: m.fill
        Behavior on width { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
    }
}
