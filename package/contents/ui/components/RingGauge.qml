import QtQuick
import QtQuick.Shapes
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "motion.js" as Motion

// Ring tile content (docs/STYLE.md, "Icons and widget content"):
// 15% track, accent arc from 12 o'clock with round caps, number + label centered.
Item {
    id: ring

    property real value // 0..100
    property string label
    property string suffix: ""
    // Shown in the middle instead of the rounded value, when set (a UV index, say).
    property string text: ""
    property color accent: Kirigami.Theme.highlightColor

    readonly property real thickness: Math.max(2, width * 0.1)
    readonly property real arcRadius: (width - thickness) / 2

    implicitWidth: height
    implicitHeight: Kirigami.Units.iconSizes.medium

    Behavior on value {
        NumberAnimation {
            duration: Motion.ms(300, Kirigami.Units.longDuration)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.enter
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.alpha(Kirigami.Theme.textColor, 0.15)
            strokeWidth: ring.thickness
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.arcRadius
                radiusY: ring.arcRadius
                startAngle: 0
                sweepAngle: 360
            }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: ring.accent
            strokeWidth: ring.thickness
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.arcRadius
                radiusY: ring.arcRadius
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(100, ring.value)) / 100
            }
        }
    }

    Column {
        anchors.centerIn: parent

        PlasmaComponents.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.text !== "" ? ring.text : Math.round(ring.value) + ring.suffix
            font.pixelSize: Math.max(8, ring.height * 0.3)
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }
        PlasmaComponents.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: ring.label !== "" && ring.height >= Kirigami.Units.gridUnit * 2
            text: ring.label
            font.pixelSize: Math.max(6, ring.height * 0.15)
            opacity: 0.6
        }
    }
}
