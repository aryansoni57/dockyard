import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "../components"
import "../components/accent"

// Battery tile: charge ring labelled BAT. Green accent while charging, red when low.
Tile {
    id: root

    property real percent // 0..100
    property bool charging
    // Screen edge the dock sits on, so the flyout opens away from it.
    property int edge: PlasmaCore.Types.BottomEdge

    // Show other devices' batteries in the flyout.
    property bool showDevices: true
    // default (ring), core, dots or gauge (see BatteryFaces).
    property string style: "default"

    signal settingsRequested()

    readonly property real contentHeight: height - padding * 2
    readonly property real boltSize: Math.max(8, contentHeight * 0.4)
    readonly property color accentColor: charging
        ? Kirigami.Theme.positiveTextColor
        : (percent < 20 ? Kirigami.Theme.negativeTextColor : DockAccent.color)

    implicitWidth: style !== "default" ? faces.implicitWidth
        : ring.width + padding * 2 + (charging ? Kirigami.Units.smallSpacing + boltSize : 0)

    // Tapping the tile toggles the Power & Battery flyout.
    onClicked: flyout.visible = !flyout.visible

    PowerFlyout {
        id: flyout
        accent: DockAccent.color
        visualParent: root
        location: root.edge
        percent: root.percent
        charging: root.charging
        showDevices: root.showDevices
        onSettingsRequested: root.settingsRequested()
    }

    RingGauge {
        id: ring
        visible: root.style === "default"
        x: root.padding
        y: root.padding
        height: root.contentHeight
        width: height
        value: root.percent
        label: "BAT"
        accent: root.accentColor
    }

    Kirigami.Icon {
        id: bolt
        visible: root.charging && root.style === "default"
        source: "battery-charging"
        color: Kirigami.Theme.positiveTextColor
        anchors.left: ring.right
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.verticalCenter: parent.verticalCenter
        width: root.boltSize
        height: root.boltSize
    }

    BatteryFaces {
        id: faces
        anchors.fill: parent
        visible: root.style !== "default"
        variant: root.style
        percent: root.percent
        charging: root.charging
        padding: root.padding
        radius: root.radius
    }
}
