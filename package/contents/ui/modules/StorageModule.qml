import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Storage tile (website "Storage"): a red drive icon and "Storage" with the used
// percent at the right, the free space big underneath, and a thin usage bar that
// turns red when the disk is nearly full.
Tile {
    id: root

    property real used  // bytes
    property real total // bytes

    readonly property real gib: 1073741824
    readonly property real inner: height - padding * 2
    readonly property real percent: total > 0 ? Math.max(0, Math.min(100, used / total * 100)) : 0
    readonly property real freeGib: Math.max(0, (total - used) / gib)
    readonly property color barColor: percent >= 85 ? "#FF453A" : Kirigami.Theme.highlightColor

    implicitWidth: Math.round(height * 2.9)

    Column {
        anchors.fill: parent
        anchors.margins: root.padding
        anchors.leftMargin: root.padding * 1.3
        anchors.rightMargin: root.padding * 1.3
        spacing: root.inner * 0.06

        Item {
            width: parent.width
            height: root.inner * 0.3

            Kirigami.Icon {
                id: drive
                width: parent.height
                height: width
                source: "drive-harddisk"
                color: root.barColor
            }
            PlasmaComponents.Label {
                anchors.left: drive.right
                anchors.leftMargin: root.inner * 0.08
                anchors.verticalCenter: parent.verticalCenter
                text: i18n("Storage")
                opacity: 0.7
                font.pixelSize: Math.max(7, root.inner * 0.22)
            }
            PlasmaComponents.Label {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(root.percent) + "%"
                font.pixelSize: Math.max(7, root.inner * 0.22)
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
        }

        Row {
            spacing: root.inner * 0.08

            PlasmaComponents.Label {
                id: freeText
                text: Math.round(root.freeGib) + " GB"
                font.pixelSize: Math.max(10, root.inner * 0.4)
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
            }
            PlasmaComponents.Label {
                anchors.baseline: freeText.baseline
                text: i18n("free of %1 GB", Math.round(root.total / root.gib))
                opacity: 0.6
                font.pixelSize: Math.max(7, root.inner * 0.2)
            }
        }

        Rectangle {
            width: parent.width
            height: Math.max(3, root.inner * 0.08)
            radius: height / 2
            color: Qt.alpha(Kirigami.Theme.textColor, 0.15)

            Rectangle {
                width: parent.width * root.percent / 100
                height: parent.height
                radius: height / 2
                color: root.barColor

                Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.InOutCubic }
                }
            }
        }
    }
}
