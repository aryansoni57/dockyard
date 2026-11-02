import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import "../components"

// Pomodoro tile (docs/PLAN.md, "Time modules"): 25 min focus, 5 min break, red
// accent while focusing. Times come from timestamps, so ticks never drift.
// The tick timer runs only while the tile is shown and the cycle is running.
Tile {
    id: pomo

    property int focusMs: 25 * 60 * 1000
    property int breakMs: 5 * 60 * 1000
    property string phase: "focus" // "focus" or "break"
    property bool running: false
    property real leftMs: 25 * 60 * 1000 // time left while paused
    property real endAt: 0               // Date.now() value when the running phase ends
    property real clock: Date.now()      // refreshed by the tick timer
    property int completed: 0            // finished focus sessions

    readonly property bool focusing: phase === "focus"
    readonly property real inner: height - padding * 2
    readonly property color accent: focusing ? "#FF3B30" : Kirigami.Theme.positiveTextColor
    readonly property real shownMs: running ? Math.max(0, endAt - clock) : leftMs
    // QML has no effectiveVisible, so walk the parents: hidden anywhere means no ticks.
    readonly property bool onScreen: pomo.isOnScreen()

    implicitWidth: layout.implicitWidth + padding * 2

    function isOnScreen() {
        let item = pomo;
        while (item) {
            if (!item.visible)
                return false;
            item = item.parent;
        }
        return true;
    }

    function phaseMs(p) {
        return p === "focus" ? focusMs : breakMs;
    }

    function setPhase(p) {
        phase = p;
        leftMs = phaseMs(p);
    }

    function toggle() {
        if (running) {
            leftMs = Math.max(0, endAt - Date.now());
            running = false;
            return;
        }
        if (leftMs <= 0)
            leftMs = phaseMs(phase);
        clock = Date.now();
        endAt = clock + leftMs;
        running = true;
    }

    // Skip moves to the next phase without counting or notifying.
    function skip() {
        running = false;
        setPhase(focusing ? "break" : "focus");
    }

    // Phase ran out: count focus, notify, and wait (paused) on the next phase.
    function finishPhase() {
        const wasFocus = focusing;
        running = false;
        if (wasFocus)
            completed += 1;
        notify(wasFocus ? "Focus over" : "Break over");
        setPhase(wasFocus ? "break" : "focus");
    }

    function notify(text) {
        const cmd = 'notify-send -a Dock "Pomodoro" "' + text + '"';
        exec.disconnectSource(cmd);
        exec.connectSource(cmd);
    }

    function mmss(ms) {
        const s = Math.ceil(ms / 1000);
        return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
    }

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: disconnectSource(sourceName)
    }

    // Only ticks while visible and running; costs nothing otherwise.
    Timer {
        interval: 250
        repeat: true
        running: pomo.onScreen && pomo.running
        onTriggered: {
            pomo.clock = Date.now();
            if (pomo.clock >= pomo.endAt)
                pomo.finishPhase();
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        height: pomo.inner
        spacing: pomo.inner * 0.22

        Column {
            Layout.alignment: Qt.AlignVCenter

            PlasmaComponents.Label {
                text: pomo.mmss(pomo.shownMs)
                font.pixelSize: pomo.inner * 0.5
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
            }
            Row {
                spacing: pomo.inner * 0.15

                PlasmaComponents.Label {
                    text: pomo.focusing ? "Focus" : "Break"
                    color: pomo.accent
                    font.pixelSize: pomo.inner * 0.22
                    font.weight: Font.Medium
                }
                PlasmaComponents.Label {
                    text: (pomo.completed % 4) + "/4"
                    font.pixelSize: pomo.inner * 0.22
                    font.features: { "tnum": 1 }
                    opacity: 0.6
                }
            }
        }

        QQC2.AbstractButton {
            id: skipButton
            Layout.preferredWidth: pomo.inner * 0.5
            Layout.preferredHeight: pomo.inner * 0.5
            Layout.alignment: Qt.AlignVCenter
            scale: pressed ? 0.94 : 1
            onClicked: pomo.skip()

            Behavior on scale {
                NumberAnimation { duration: 80 }
            }

            background: Rectangle {
                radius: width / 2
                color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
            }
            contentItem: Kirigami.Icon {
                source: "media-skip-forward"
                isMask: true
                color: Kirigami.Theme.textColor
                implicitWidth: pomo.inner * 0.26
                implicitHeight: pomo.inner * 0.26
            }
        }

        QQC2.AbstractButton {
            id: playButton
            Layout.preferredWidth: pomo.inner * 0.72
            Layout.preferredHeight: pomo.inner * 0.72
            Layout.alignment: Qt.AlignVCenter
            scale: pressed ? 0.94 : 1
            onClicked: pomo.toggle()

            Behavior on scale {
                NumberAnimation { duration: 80 }
            }

            background: Rectangle {
                radius: width / 2
                color: pomo.accent
            }
            contentItem: Kirigami.Icon {
                source: pomo.running ? "media-playback-pause" : "media-playback-start"
                isMask: true
                color: Kirigami.Theme.highlightedTextColor
                implicitWidth: pomo.inner * 0.3
                implicitHeight: pomo.inner * 0.3
            }
        }
    }
}
