import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Temperature tile: big degrees number over a small "CPU" caption.
Tile {
    id: root

    property real temp // degrees C

    readonly property real contentHeight: height - padding * 2

    implicitWidth: Math.max(number.implicitWidth, caption.implicitWidth) + padding * 2

    Item {
        anchors.centerIn: parent
        width: Math.max(number.implicitWidth, caption.implicitWidth)
        height: root.contentHeight

        PlasmaComponents.Label {
            id: number
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            text: Math.round(root.temp) + "°"
            font.pixelSize: Math.max(10, root.height * 0.36)
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }
        PlasmaComponents.Label {
            id: caption
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: "CPU"
            font.pixelSize: Math.max(8, root.height * 0.16)
            opacity: 0.6
        }
    }
}
