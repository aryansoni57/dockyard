import QtQuick
import org.kde.kirigami as Kirigami
import "../components"

// Clipboard tile: a clipboard glyph with the number of entries Klipper holds.
// Tap opens the history popup; Meta+V keeps Klipper's own menu.
Tile {
    id: tile

    property int count: 0

    readonly property real inner: height - padding * 2

    implicitWidth: height

    Kirigami.Icon {
        anchors.centerIn: parent
        width: Math.round(tile.inner * 0.62)
        height: width
        source: "edit-paste-symbolic"
        isMask: true
        color: Kirigami.Theme.textColor
        opacity: 0.9
    }

    Rectangle {
        visible: tile.count > 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: tile.padding * 0.5
        width: Math.max(height, badgeText.implicitWidth + height * 0.5)
        height: tile.inner * 0.4
        radius: height / 2
        color: Qt.alpha(Kirigami.Theme.textColor, 0.16)

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: tile.count > 99 ? "99+" : tile.count
            color: Kirigami.Theme.textColor
            font.pixelSize: parent.height * 0.62
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }
    }
}
