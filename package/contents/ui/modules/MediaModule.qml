import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import "../components"
import "../components/accent"

// Media tile (docs/STYLE.md, "Icons and widget content"): rounded album art,
// title over artist, flat prev/next around a filled accent play button.
Tile {
    id: media

    property var player
    property bool playing
    // With no player the tile shows idleText/idleIcon and a launch button instead.
    property color accent: DockAccent.color
    property string idleText
    property string idleIcon: "folder-music-symbolic"
    property bool launchable: false
    // default, compact, mini or bar (see MediaFaces).
    property string style: "default"
    // Thin progress line for the track (config: mediaProgress).
    property bool showProgress: true

    // Track position. Plasma's player model does not refresh a browser's position, so the
    // player is asked directly (scripts/mpris-position.sh) every few seconds while it plays,
    // and the line is moved on by the clock in between.
    property real basePos: 0 // microseconds at baseAt
    property real lengthUs: 0
    property double baseAt: Date.now()
    property double nowMs: Date.now()
    readonly property real trackLength: player && player.length > 0 ? player.length : lengthUs
    readonly property real progress: trackLength > 0
        ? Math.max(0, Math.min(1, (basePos + (playing ? (nowMs - baseAt) * 1000 : 0)) / trackLength)) : 0
    readonly property bool tracking: showProgress && !!player && visible
    readonly property string trackKey: player ? String(player.track) + "|" + String(player.identity) : ""

    function pollPosition() {
        if (player)
            posRunner.run("sh '" + Qt.resolvedUrl("../../scripts/mpris-position.sh").toString().replace("file://", "")
                          + "' '" + String(player.identity).replace(/'/g, "") + "'");
    }
    onTrackKeyChanged: {
        basePos = 0;
        lengthUs = 0;
        baseAt = Date.now();
        if (tracking)
            pollPosition();
    }
    onPlayingChanged: if (tracking) pollPosition()

    ShellRunner {
        id: posRunner
        onFinished: (cmd, out) => {
            const f = out.trim().split(/\s+/);
            if (f.length < 2)
                return;
            media.basePos = parseInt(f[0], 10) || 0;
            media.lengthUs = parseInt(f[1], 10) || 0;
            media.baseAt = Date.now();
            media.nowMs = media.baseAt;
        }
    }
    Timer {
        interval: 3000
        repeat: true
        running: media.tracking && media.playing
        triggeredOnStart: true
        onTriggered: media.pollPosition()
    }
    Timer {
        interval: 500
        repeat: true
        running: media.tracking && media.playing
        onTriggered: media.nowMs = Date.now()
    }

    // Extras for the dock tile (off in the popup list): right-click menu to pick which player the
    // tile follows, middle-click play/pause, scroll for next/previous.
    property bool menuEnabled: false
    property var players: []
    property var pinned: null

    signal launchRequested
    signal pinRequested(var player)
    signal pauseAllRequested()

    readonly property real inner: height - padding * 2

    implicitWidth: style !== "default" ? faces.implicitWidth : row.implicitWidth + padding * 2

    RowLayout {
        id: row
        visible: media.style === "default"
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
                opacity: media.player ? 0.78 : 1
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
                opacity: 0.78
                elide: Text.ElideRight
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: media.inner * 0.08
                Layout.preferredHeight: Math.max(2, media.inner * 0.07)
                visible: media.showProgress && !!media.player && media.trackLength > 0
                radius: height / 2
                color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
                Rectangle {
                    width: parent.width * media.progress
                    height: parent.height
                    radius: height / 2
                    color: media.accent
                }
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
                opacity: playButton.enabled ? 1 : 0.5
            }
            // The glyph is drawn smaller than the button, and the play triangle is nudged right: its
            // visual weight sits left of its bounding box, so a centred triangle looks off to the left.
            contentItem: Item {
                Kirigami.Icon {
                    readonly property real glyph: Math.round(playButton.width * 0.48)
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: media.playing ? 0 : Math.round(glyph * 0.07)
                    width: glyph
                    height: glyph
                    source: media.playing ? "media-playback-pause" : "media-playback-start"
                    isMask: true
                    color: "white"
                }
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

    MediaFaces {
        id: faces
        anchors.fill: parent
        visible: media.style !== "default"
        variant: media.style
        player: media.player
        playing: media.playing
        padding: media.padding
        progress: media.showProgress && media.trackLength > 0 ? media.progress : -1
    }

    TapHandler {
        enabled: media.menuEnabled
        acceptedButtons: Qt.RightButton
        // Plasma opens the dock's own applet menu on every right click; opening ours a beat
        // later closes that one (as the notifications tile does).
        onTapped: openLater.restart()
    }
    Timer {
        id: openLater
        interval: 80
        onTriggered: {
            menu.placement = Plasmoid.location === PlasmaCore.Types.TopEdge
                ? PlasmaExtras.Menu.BottomPosedLeftAlignedPopup : PlasmaExtras.Menu.TopPosedLeftAlignedPopup;
            menu.openRelative();
        }
    }
    TapHandler {
        enabled: media.menuEnabled
        acceptedButtons: Qt.MiddleButton
        onTapped: if (media.player && media.player.canControl) media.player.PlayPause()
    }
    WheelHandler {
        property double last: 0
        enabled: media.menuEnabled
        onWheel: event => {
            const now = Date.now();
            if (!media.player || now - last < 400)
                return;
            last = now;
            if (event.angleDelta.y > 0 && media.player.canGoNext)
                media.player.Next();
            else if (event.angleDelta.y < 0 && media.player.canGoPrevious)
                media.player.Previous();
        }
    }

    PlasmaExtras.Menu {
        id: menu
        visualParent: media

        PlasmaExtras.MenuItem {
            text: i18n("Follow automatically")
            checkable: true
            checked: media.pinned === null
            onClicked: media.pinRequested(null)
        }
        PlasmaExtras.MenuItem {
            id: pauseItem
            text: i18n("Pause all")
            icon: "media-playback-pause"
            enabled: media.players.some(p => p.playbackStatus === Mpris.PlaybackStatus.Playing)
            onClicked: media.pauseAllRequested()
        }
        PlasmaExtras.MenuItem { separator: true }
    }
    // One entry per player below the fixed ones.
    Instantiator {
        model: media.menuEnabled ? media.players : []
        delegate: PlasmaExtras.MenuItem {
            required property var modelData
            text: modelData.identity + (modelData.track ? " — " + modelData.track : "")
            checkable: true
            checked: media.pinned === modelData
            onClicked: media.pinRequested(modelData)
        }
        onObjectAdded: (index, object) => menu.addMenuItem(object)
        onObjectRemoved: (index, object) => menu.removeMenuItem(object)
    }
}
