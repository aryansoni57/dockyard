import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Notes tile (demo video 0:12): a small yellow-topped note, the first line as
// the title, the rest as a two-line preview, and an edit icon on the right.
// The note itself is edited in the popup.
Tile {
    id: tile

    property string text

    readonly property real inner: height - padding * 2
    readonly property var lines: text.split("\n").filter(l => l.trim() !== "")
    readonly property string title: lines.length > 0 ? lines[0] : i18n("Notes")
    readonly property string preview: lines.length > 1 ? lines.slice(1).join(" ") : i18n("Click to write")

    implicitWidth: Math.round(height * 3.4)

    RowLayout {
        anchors.fill: parent
        anchors.margins: tile.padding
        spacing: Kirigami.Units.smallSpacing * 1.5

        // Paper with a yellow header strip.
        Rectangle {
            Layout.preferredWidth: tile.inner * 0.9
            Layout.preferredHeight: tile.inner * 0.9
            Layout.alignment: Qt.AlignVCenter
            radius: width * 0.14
            color: Qt.alpha(Kirigami.Theme.textColor, 0.06)
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
            clip: true

            Rectangle {
                width: parent.width
                height: parent.height * 0.26
                color: "#FFCC00"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: tile.title
                elide: Text.ElideRight
                font.pixelSize: Math.max(9, tile.inner * 0.3)
                font.weight: Font.DemiBold
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: tile.preview
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                opacity: 0.6
                font.pixelSize: Math.max(7, tile.inner * 0.2)
            }
        }

        Kirigami.Icon {
            Layout.preferredWidth: tile.inner * 0.3
            Layout.preferredHeight: tile.inner * 0.3
            Layout.alignment: Qt.AlignVCenter
            source: "document-edit-symbolic"
            isMask: true
            color: Kirigami.Theme.textColor
            opacity: 0.7
        }
    }
}
