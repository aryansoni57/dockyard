import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"
import "../components/accent"

// Now Playing variants (website "Now Playing (compact)", "Mini", "Bar"). `variant`:
//   mini    - album art with a play/pause button over it
//   compact - small art, one-line title, play/pause
//   bar     - slim strip: title and artist, prev / play / next, no art
Item {
    id: media
    property real padding: Math.round(height * 0.14)

    property string variant: "compact"
    property var player
    property bool playing
    property color accent: DockAccent.color
    // 0..1 track position, or -1 to hide the line.
    property real progress: -1

    readonly property real inner: height - padding * 2
    readonly property bool hasPlayer: !!player

    implicitWidth: variant === "mini" ? height
                 : padding * 2 + (variant === "compact" ? inner + Kirigami.Units.gridUnit * 6 + inner * 0.9 + padding * 2
                                                        : Kirigami.Units.gridUnit * 7 + inner * 2.6 + padding * 2)

    component Art: Item {
        Kirigami.ShadowedImage {
            id: img
            anchors.fill: parent
            visible: media.hasPlayer && (status === Image.Ready || !!media.player.artUrl)
            source: media.player?.artUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            radius: height * 0.22
            sourceSize: Qt.size(height * 2, height * 2)
        }
        Rectangle {
            anchors.fill: parent
            visible: !img.visible
            radius: height * 0.22
            color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
            Kirigami.Icon {
                anchors.centerIn: parent
                width: parent.width * 0.5
                height: width
                source: "folder-music-symbolic"
                isMask: true
                color: Kirigami.Theme.textColor
                opacity: 0.78
            }
        }
    }

    component RoundButton: QQC2.AbstractButton {
        id: b
        property string iconName
        property bool filled: false
        scale: pressed ? 0.92 : 1
        Behavior on scale {
            NumberAnimation { duration: 80 }
        }
        background: Rectangle {
            radius: width / 2
            color: b.filled ? media.accent : Qt.alpha(Kirigami.Theme.textColor, b.hovered ? 0.2 : 0.1)
            opacity: b.enabled ? 1 : 0.5
        }
        contentItem: Item {
            Kirigami.Icon {
                anchors.centerIn: parent
                width: b.width * 0.48
                height: width
                source: b.iconName
                isMask: true
                color: b.filled ? "white" : Kirigami.Theme.textColor
            }
        }
    }

    readonly property string playIcon: playing ? "media-playback-pause" : "media-playback-start"
    readonly property string title: player?.track || (player ? i18n("Nothing playing") : i18n("No player"))

    // Mini: art with the button in its corner.
    Item {
        visible: media.variant === "mini"
        anchors.fill: parent
        anchors.margins: media.padding

        Art {
            anchors.fill: parent
        }
        RoundButton {
            width: parent.height * 0.5
            height: width
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            iconName: media.playIcon
            filled: true
            enabled: media.player?.canControl ?? false
            onClicked: media.player.PlayPause()
        }
    }

    RowLayout {
        visible: media.variant === "compact"
        anchors.fill: parent
        anchors.margins: media.padding
        spacing: media.padding

        Art {
            Layout.preferredWidth: media.inner
            Layout.preferredHeight: media.inner
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: media.title
            elide: Text.ElideRight
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, media.inner * 0.34)
            font.weight: Font.Medium
        }
        RoundButton {
            Layout.preferredWidth: media.inner * 0.9
            Layout.preferredHeight: media.inner * 0.9
            iconName: media.playIcon
            filled: true
            enabled: media.player?.canControl ?? false
            onClicked: media.player.PlayPause()
        }
    }

    RowLayout {
        visible: media.variant === "bar"
        anchors.fill: parent
        anchors.margins: media.padding
        anchors.leftMargin: media.padding * 1.4
        spacing: media.padding * 0.8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: media.title
                elide: Text.ElideRight
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, media.inner * 0.34)
                font.weight: Font.Medium
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: media.player?.artist ?? ""
                elide: Text.ElideRight
                opacity: 0.78
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, media.inner * 0.26)
            }
        }
        RoundButton {
            Layout.preferredWidth: media.inner * 0.7
            Layout.preferredHeight: media.inner * 0.7
            iconName: "media-skip-backward"
            enabled: media.player?.canGoPrevious ?? false
            onClicked: media.player.Previous()
        }
        RoundButton {
            Layout.preferredWidth: media.inner * 0.9
            Layout.preferredHeight: media.inner * 0.9
            iconName: media.playIcon
            filled: true
            enabled: media.player?.canControl ?? false
            onClicked: media.player.PlayPause()
        }
        RoundButton {
            Layout.preferredWidth: media.inner * 0.7
            Layout.preferredHeight: media.inner * 0.7
            iconName: "media-skip-forward"
            enabled: media.player?.canGoNext ?? false
            onClicked: media.player.Next()
        }
    }

    // Progress line along the bottom edge.
    Rectangle {
        visible: media.progress >= 0
        x: media.padding * 1.3
        width: parent.width - media.padding * 2.6
        y: parent.height - media.padding * 0.55
        height: 2.5
        radius: height / 2
        color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
        Rectangle {
            width: parent.width * Math.max(0, media.progress)
            height: parent.height
            radius: height / 2
            color: media.accent
        }
    }
}
