import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Stopwatch tile (docs/PLAN.md, "Time modules"): big mm:ss.t, round play/pause
// and a reset. Elapsed time is the sum of Date.now() deltas, never tick counts.
Tile {
    id: sw

    property real baseMs: 0      // elapsed before the current run
    property bool running: false
    property real startedAt: 0   // Date.now() value at the start of the current run
    property real clock: Date.now() // refreshed by the tick timer

    readonly property real inner: height - padding * 2
    readonly property real elapsedMs: running ? baseMs + (clock - startedAt) : baseMs
    // QML has no effectiveVisible, so walk the parents: hidden anywhere means no ticks.
    readonly property bool onScreen: sw.isOnScreen()

    implicitWidth: layout.implicitWidth + padding * 2

    function isOnScreen() {
        let item = sw;
        while (item) {
            if (!item.visible)
                return false;
            item = item.parent;
        }
        return true;
    }

    function toggle() {
        if (running) {
            baseMs += Date.now() - startedAt;
            running = false;
            return;
        }
        clock = Date.now();
        startedAt = clock;
        running = true;
    }

    function reset() {
        running = false;
        baseMs = 0;
    }

    function pad(n) {
        return String(n).padStart(2, "0");
    }

    // mm:ss.t, tenths truncated.
    function fmt(ms) {
        const t = Math.floor(ms / 100);
        const minutes = Math.floor(t / 600);
        const seconds = Math.floor(t / 10) % 60;
        return pad(minutes) + ":" + pad(seconds) + "." + (t % 10);
    }

    // Only ticks while visible and running; costs nothing otherwise.
    Timer {
        interval: 100
        repeat: true
        running: sw.onScreen && sw.running
        onTriggered: sw.clock = Date.now()
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        height: sw.inner
        spacing: sw.inner * 0.22

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignVCenter
            text: sw.fmt(sw.elapsedMs)
            font.pixelSize: sw.inner * 0.5
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }

        QQC2.AbstractButton {
            id: resetButton
            Layout.preferredWidth: sw.inner * 0.5
            Layout.preferredHeight: sw.inner * 0.5
            Layout.alignment: Qt.AlignVCenter
            enabled: sw.running || sw.baseMs > 0
            scale: pressed ? 0.94 : 1
            onClicked: sw.reset()

            Behavior on scale {
                NumberAnimation { duration: 80 }
            }

            background: Rectangle {
                radius: width / 2
                color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                opacity: resetButton.enabled ? 1 : 0.4
            }
            contentItem: Kirigami.Icon {
                source: "view-refresh"
                isMask: true
                color: Kirigami.Theme.textColor
                implicitWidth: sw.inner * 0.26
                implicitHeight: sw.inner * 0.26
            }
        }

        QQC2.AbstractButton {
            id: playButton
            Layout.preferredWidth: sw.inner * 0.72
            Layout.preferredHeight: sw.inner * 0.72
            Layout.alignment: Qt.AlignVCenter
            scale: pressed ? 0.94 : 1
            onClicked: sw.toggle()

            Behavior on scale {
                NumberAnimation { duration: 80 }
            }

            background: Rectangle {
                radius: width / 2
                color: Kirigami.Theme.highlightColor
            }
            contentItem: Kirigami.Icon {
                source: sw.running ? "media-playback-pause" : "media-playback-start"
                isMask: true
                color: Kirigami.Theme.highlightedTextColor
                implicitWidth: sw.inner * 0.3
                implicitHeight: sw.inner * 0.3
            }
        }
    }
}
