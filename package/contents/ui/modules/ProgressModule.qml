import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"
import "../components/progress.js" as Progress

// Month / Day / Year progress (demo video 0:21): a 13-column dot matrix, filled
// dots for time elapsed, a small caption bottom-left and the percent bottom-right.
Tile {
    id: tile

    property date now
    property string kind: "day" // month | day | year

    readonly property int cols: kind === "year" ? 13 : 10
    readonly property real inner: height - padding * 2
    readonly property int rows: Math.ceil(total / cols)
    readonly property real pitch: Math.min(inner * 0.2, inner * 0.58 / rows)

    readonly property int total: Progress.total(kind, now)
    readonly property real fraction: Progress.fraction(kind, now)
    readonly property int percent: Math.floor(fraction * 100)
    readonly property int filled: Math.round(fraction * total)
    readonly property string caption: Progress.caption(kind, now)

    implicitWidth: cols * pitch + padding * 2 + Kirigami.Units.largeSpacing

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: tile.padding
        anchors.leftMargin: tile.padding + Kirigami.Units.smallSpacing
        anchors.rightMargin: tile.padding + Kirigami.Units.smallSpacing
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Grid {
                anchors.verticalCenter: parent.verticalCenter
                columns: tile.cols
                spacing: tile.pitch * 0.28

                Repeater {
                    model: tile.total

                    Rectangle {
                        required property int index
                        width: tile.pitch * 0.72
                        height: width
                        radius: width / 2
                        color: index < tile.filled
                            ? Kirigami.Theme.textColor
                            : Qt.alpha(Kirigami.Theme.textColor, 0.15)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: tile.inner * 0.36

            PlasmaComponents.Label {
                text: tile.caption
                font.pixelSize: Math.max(8, tile.inner * 0.3)
                opacity: 0.6
            }
            Item {
                Layout.fillWidth: true
            }
            PlasmaComponents.Label {
                text: tile.percent + "%"
                font.pixelSize: Math.max(9, tile.inner * 0.32)
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
            }
        }
    }
}
