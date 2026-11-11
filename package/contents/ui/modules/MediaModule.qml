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
    // With no player the tile shows idleText/idleIcon and a launch button instead.
    property color accent: Kirigami.Theme.highlightColor
    property string idleText
    property string idleIcon: "folder-music-symbolic"
    property bool launchable: false

    signal launchRequested

    readonly property real inner: height - padding * 2

    implicitWidth: row.implicitWidth + padding * 2

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: media.padding
        spacing: media.padding

        Kirigami.ShadowedImage {
            id: art
            visible: !!media.player && (status === Image.Ready || !!media.player.artUrl)
            Layout.preferredWidth: media.inner
            Layout.preferredHeight: media.inner
            source: media.player?.artUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            radius: media.inner * 0.22
            sourceSize: Qt.size(media.inner * 2, media.inner * 2)
        }

        // Stands in for the art when the player sends none.
        Rectangle {
            visible: !art.visible
            Layout.preferredWidth: media.inner
            Layout.preferredHeight: media.inner
            radius: media.inner * 0.22
            color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
            Kirigami.Icon {
                anchors.centerIn: parent
                width: parent.width * (isMask ? 0.5 : 0.8)
                height: width
                source: media.idleIcon
                isMask: media.idleIcon.endsWith("-symbolic")
                color: media.player ? Kirigami.Theme.textColor : media.accent
                opacity: media.player ? 0.6 : 1
            }
        }

        ColumnLayout {
            // Fixed, so the tile keeps its width as the title changes; long titles elide.
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
            spacing: 0

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: media.player?.track || (media.player ? i18n("Nothing playing") : (media.idleText || i18n("No player")))
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, media.inner * 0.36)
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: text !== "" && media.inner >= Kirigami.Units.gridUnit * 1.5
                text: media.player ? media.player.artist : (media.launchable ? i18n("Click to open") : "")
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
            enabled: media.player ? media.player.canControl : media.launchable
            scale: pressed ? 0.94 : 1
            onClicked: media.player ? media.player.PlayPause() : media.launchRequested()

            Behavior on scale {
                NumberAnimation { duration: 80 }
            }

            background: Rectangle {
                radius: width / 2
                color: media.accent
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
