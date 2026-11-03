import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Date tiles (demo video 0:09). "long": weekday over the bold month and day.
// "number": red three-letter weekday over a big day number.
Tile {
    id: tile

    property date now
    property string kind: "long" // long | number

    readonly property bool isNumber: kind === "number"
    readonly property real inner: height - padding * 2

    implicitWidth: isNumber ? height : Math.max(weekday.implicitWidth, day.implicitWidth) + padding * 3

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        PlasmaComponents.Label {
            id: weekday
            Layout.alignment: tile.isNumber ? Qt.AlignHCenter : Qt.AlignLeft
            text: tile.isNumber
                ? Qt.locale().dayName(tile.now.getDay(), Locale.ShortFormat).toUpperCase()
                : Qt.locale().dayName(tile.now.getDay(), Locale.LongFormat)
            color: tile.isNumber ? "#FF3B30" : Kirigami.Theme.textColor
            opacity: tile.isNumber ? 1 : 0.6
            font.pixelSize: Math.max(8, tile.inner * (tile.isNumber ? 0.26 : 0.27))
            font.weight: tile.isNumber ? Font.DemiBold : Font.Normal
        }
        PlasmaComponents.Label {
            id: day
            Layout.alignment: tile.isNumber ? Qt.AlignHCenter : Qt.AlignLeft
            text: tile.isNumber ? tile.now.getDate() : Qt.formatDate(tile.now, "MMMM d")
            font.pixelSize: Math.max(10, tile.inner * (tile.isNumber ? 0.55 : 0.4))
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }
    }
}
