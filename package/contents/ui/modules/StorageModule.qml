import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Disk tile: used-percent ring labelled DISK, with "used / total" in GiB beside it.
Tile {
    id: root

    property real used  // bytes
    property real total // bytes

    readonly property real gib: 1073741824
    readonly property real contentHeight: height - padding * 2
    readonly property real percent: total > 0 ? Math.max(0, Math.min(100, used / total * 100)) : 0

    implicitWidth: ring.width + Kirigami.Units.largeSpacing + usage.implicitWidth + padding * 2

    RingGauge {
        id: ring
        x: root.padding
        y: root.padding
        height: root.contentHeight
        width: height
        value: root.percent
        label: "DISK"
    }

    PlasmaComponents.Label {
        id: usage
        anchors.left: ring.right
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.used / root.gib) + " / " + Math.round(root.total / root.gib) + "G"
        font.pixelSize: Math.max(8, root.height * 0.2)
        font.features: { "tnum": 1 }
        opacity: 0.6
    }
}
