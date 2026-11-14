import QtQuick
import QtQuick.Shapes
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "motion.js" as Motion

// Three nested rings, after the AvdanOS resource gauge: CPU outside, RAM in the middle,
// disk inside. Same look as RingGauge (15% track, round caps, arc from 12 o'clock).
// The CPU percent sits in the centre when there is room for it.
Item {
    id: rings

    property real cpu   // 0..100
    property real mem   // 0..100
    property real disk  // 0..100
    property color cpuColor: Kirigami.Theme.highlightColor
    property color memColor: "#30D158"
    property color diskColor: "#FF9F0A"

    readonly property real thickness: Math.max(2, width * 0.075)
    // Distance from one ring's centre line to the next ring in.
    readonly property real pitch: thickness * 1.6
    readonly property real outerRadius: (width - thickness) / 2

    implicitWidth: height
    implicitHeight: Kirigami.Units.iconSizes.medium

    // One ring: a faint full track and the value arc over it.
    component Ring: Shape {
        id: ring
        property real radius
        property real value
        property color color

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        Behavior on value {
            NumberAnimation {
                duration: Motion.ms(Motion.enterMs, Kirigami.Units.longDuration)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.enter
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.alpha(Kirigami.Theme.textColor, 0.15)
            strokeWidth: rings.thickness
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.radius
                radiusY: ring.radius
                startAngle: 0
                sweepAngle: 360
            }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: ring.color
            strokeWidth: rings.thickness
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.radius
                radiusY: ring.radius
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(100, ring.value)) / 100
            }
        }
    }

    Ring {
        radius: rings.outerRadius
        value: rings.cpu
        color: rings.cpuColor
    }
    Ring {
        radius: rings.outerRadius - rings.pitch
        value: rings.mem
        color: rings.memColor
    }
    Ring {
        radius: rings.outerRadius - rings.pitch * 2
        value: rings.disk
        color: rings.diskColor
    }

    PlasmaComponents.Label {
        anchors.centerIn: parent
        // Inside the third ring is about 40% of the width; below that the number would not fit.
        visible: rings.width >= Kirigami.Units.gridUnit * 2.4
        text: Math.round(rings.cpu)
        font.pixelSize: Math.max(8, rings.width * 0.2)
        font.weight: Font.Bold
        font.features: { "tnum": 1 }
    }
}
