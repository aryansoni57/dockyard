import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Media tile (docs/STYLE.md, "Icons and widget content"): rounded album art,
// title over artist, flat prev/next around a filled accent play button.
Tile {
    id: media

    property var player
    property bool playing

    readonly property real inner: height - padding * 2

    implicitWidth: row.implicitWidth + padding * 2

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: media.padding
        spacing: media.padding

        Kirigami.ShadowedImage {
            Layout.preferredWidth: media.inner
            Layout.preferredHeight: media.inner
            visible: source.toString() !== ""
            source: media.player?.artUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            radius: media.inner * 0.22
            sourceSize: Qt.size(media.inner * 2, media.inner * 2)
        }

        ColumnLayout {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
            spacing: 0

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: media.player?.track ?? ""
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, media.inner * 0.36)
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: text !== "" && media.inner >= Kirigami.Units.gridUnit * 1.5
                text: media.player?.artist ?? ""
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, media.inner * 0.3)
                opacity: 0.6
                elide: Text.ElideRight
            }
        }

        PlasmaComponents.ToolButton {
            Layout.preferredWidth: media.inner * 0.8
            Layout.preferredHeight: media.inner * 0.8
            icon.name: "media-skip-backward"
            display: QQC2.AbstractButton.IconOnly
            enabled: media.player?.canGoPrevious ?? false
            onClicked: media.player.Previous()
        }

        QQC2.AbstractButton {
            id: playButton
            Layout.preferredWidth: media.inner * 0.8
            Layout.preferredHeight: media.inner * 0.8
            enabled: media.player?.canControl ?? false
            scale: pressed ? 0.94 : 1
            onClicked: media.player.PlayPause()

            Behavior on scale {
                NumberAnimation { duration: 80 }
            }

            background: Rectangle {
                radius: width / 2
                color: Kirigami.Theme.highlightColor
                opacity: playButton.enabled ? 1 : 0.4
            }
            contentItem: Kirigami.Icon {
                source: media.playing ? "media-playback-pause" : "media-playback-start"
                isMask: true
                color: "white"
                implicitWidth: media.inner * 0.4
                implicitHeight: media.inner * 0.4
            }
        }

        PlasmaComponents.ToolButton {
            Layout.preferredWidth: media.inner * 0.8
            Layout.preferredHeight: media.inner * 0.8
            icon.name: "media-skip-forward"
            display: QQC2.AbstractButton.IconOnly
            enabled: media.player?.canGoNext ?? false
            onClicked: media.player.Next()
        }
    }
}
