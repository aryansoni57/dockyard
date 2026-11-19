import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"
import "../components/accent"

// Battery looks (website "Battery Core", "Battery Dots", "Battery Gauge"). `variant`:
//   core  - solid tile filled from the bottom to the charge level, percent on top
//   dots  - ten dots, lit up to the charge level
//   gauge - half-circle arc with the percent underneath
// Green while charging, red under 20%, accent otherwise.
Item {
    id: tile
    property real padding: Math.round(height * 0.14)
    property real radius: height * 0.24

    property string variant: "core"
    property real percent
    property bool charging

    readonly property real inner: height - padding * 2
    readonly property color level: charging ? Kirigami.Theme.positiveTextColor
        : (percent < 20 ? Kirigami.Theme.negativeTextColor : DockAccent.color)

    implicitWidth: variant === "dots" ? Math.round(height * 2.2) : variant === "gauge" ? Math.round(height * 1.5) : height

    // Core: the fill rises like liquid inside the tile.
    Item {
        visible: tile.variant === "core"
        anchors.fill: parent
        anchors.margins: 1

        Rectangle {
            id: fill
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * Math.max(0.04, Math.min(1, tile.percent / 100))
            radius: tile.radius - 1
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(tile.level, 1.15) }
                GradientStop { position: 1; color: Qt.darker(tile.level, 1.15) }
            }
            opacity: 0.85
            Behavior on height {
                NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
            }
        }
        Column {
            anchors.centerIn: parent
            PlasmaComponents.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(tile.percent) + "%"
                font.pixelSize: tile.inner * 0.34
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
            }
            Kirigami.Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: tile.charging
                width: tile.inner * 0.22
                height: width
                source: "battery-charging"
                isMask: true
                color: Kirigami.Theme.textColor
            }
        }
    }

    // Dots.
    Column {
        visible: tile.variant === "dots"
        anchors.centerIn: parent
        spacing: tile.inner * 0.12

        Row {
            spacing: tile.inner * 0.1
            Repeater {
                model: 10
                Rectangle {
                    required property int index
                    width: tile.inner * 0.17
                    height: width
                    radius: width / 2
                    color: index < Math.round(tile.percent / 10) ? tile.level : Qt.alpha(Kirigami.Theme.textColor, 0.18)
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }
            }
        }
        PlasmaComponents.Label {
            text: Math.round(tile.percent) + "%" + (tile.charging ? "  ⚡" : "")
            font.pixelSize: tile.inner * 0.3
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }
    }

    // Gauge.
    Item {
        visible: tile.variant === "gauge"
        anchors.fill: parent
        anchors.margins: tile.padding

        Canvas {
            id: arc
            anchors.top: parent.top
            width: parent.width
            height: parent.height * 0.65
            property real value: tile.percent
            property color level: tile.level
            property color track: Qt.alpha(Kirigami.Theme.textColor, 0.18)
            onValueChanged: requestPaint()
            onLevelChanged: requestPaint()
            onTrackChanged: requestPaint()
            onWidthChanged: requestPaint()
            onPaint: {
                const c = getContext("2d");
                c.reset();
                const lw = Math.max(3, height * 0.18);
                const r = Math.min(width / 2, height) - lw / 2 - 1;
                const cx = width / 2, cy = height - lw / 2;
                c.lineWidth = lw;
                c.lineCap = "round";
                c.strokeStyle = track;
                c.beginPath();
                c.arc(cx, cy, r, Math.PI, 2 * Math.PI);
                c.stroke();
                c.strokeStyle = level;
                c.beginPath();
                c.arc(cx, cy, r, Math.PI, Math.PI + Math.max(0.02, value / 100) * Math.PI);
                c.stroke();
            }
        }
        PlasmaComponents.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: Math.round(tile.percent) + "%"
            font.pixelSize: tile.inner * 0.34
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }
    }
}
