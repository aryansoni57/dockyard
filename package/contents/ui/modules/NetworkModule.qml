import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Network tile: download and upload rates, one per row, arrows on the left.
Tile {
    id: root

    property real down // bytes per second
    property real up   // bytes per second

    readonly property real contentHeight: height - padding * 2
    readonly property real fontSize: Math.max(8, height * 0.24)
    readonly property real arrowWidth: arrowSizer.implicitWidth
    // Widest value we expect ("888.8G"), so the tile width does not jump.
    readonly property real valueWidth: valueSizer.implicitWidth

    implicitWidth: arrowWidth + Kirigami.Units.smallSpacing + valueWidth + padding * 2

    // Compact rate: B, K, M, G. One decimal below 10, none from 10 up.
    function formatRate(bytes) {
        var units = ["B", "K", "M", "G"];
        var v = Math.max(0, bytes || 0);
        var i = 0;
        while (v >= 1023.95 && i < units.length - 1) {
            v /= 1024;
            i++;
        }
        if (i === 0)
            return Math.round(v) + units[i];
        var text = v < 9.95 ? v.toFixed(1) : Math.round(v).toString();
        return text + units[i];
    }

    PlasmaComponents.Label {
        id: arrowSizer
        visible: false
        text: "↓"
        font.pixelSize: root.fontSize
    }
    PlasmaComponents.Label {
        id: valueSizer
        visible: false
        text: "888.8G"
        font.pixelSize: root.fontSize
        font.features: { "tnum": 1 }
    }

    Item {
        anchors.centerIn: parent
        width: root.arrowWidth + Kirigami.Units.smallSpacing + root.valueWidth
        height: root.contentHeight

        PlasmaComponents.Label {
            anchors.left: parent.left
            anchors.top: parent.top
            width: root.arrowWidth
            height: parent.height / 2
            verticalAlignment: Text.AlignVCenter
            text: "↓"
            font.pixelSize: root.fontSize
        }
        PlasmaComponents.Label {
            anchors.right: parent.right
            anchors.top: parent.top
            width: root.valueWidth
            height: parent.height / 2
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: root.formatRate(root.down)
            font.pixelSize: root.fontSize
            font.features: { "tnum": 1 }
        }

        PlasmaComponents.Label {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: root.arrowWidth
            height: parent.height / 2
            verticalAlignment: Text.AlignVCenter
            text: "↑"
            font.pixelSize: root.fontSize
        }
        PlasmaComponents.Label {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: root.valueWidth
            height: parent.height / 2
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: root.formatRate(root.up)
            font.pixelSize: root.fontSize
            font.features: { "tnum": 1 }
        }
    }
}
