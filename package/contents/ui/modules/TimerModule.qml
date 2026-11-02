import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import "../components"

// Countdown tile (docs/PLAN.md, "Time modules"): presets 1/5/10/25 min as small
// pills, big mm:ss, round play/pause. Same timestamp model as the Pomodoro tile.
Tile {
    id: tm

    readonly property var presets: [1, 5, 10, 25]
    property int presetIndex: 1
    property bool running: false
    property real leftMs: 5 * 60 * 1000 // time left while paused
    property real endAt: 0              // Date.now() value when the countdown ends
    property real clock: Date.now()     // refreshed by the tick timer

    readonly property real inner: height - padding * 2
    readonly property real shownMs: running ? Math.max(0, endAt - clock) : leftMs
    // QML has no effectiveVisible, so walk the parents: hidden anywhere means no ticks.
    readonly property bool onScreen: tm.isOnScreen()

    implicitWidth: layout.implicitWidth + padding * 2

    function isOnScreen() {
        let item = tm;
        while (item) {
            if (!item.visible)
                return false;
            item = item.parent;
        }
        return true;
    }

    function pick(i) {
        running = false;
        presetIndex = i;
        leftMs = presets[i] * 60000;
    }

    function toggle() {
        if (running) {
            leftMs = Math.max(0, endAt - Date.now());
            running = false;
            return;
        }
        if (leftMs <= 0)
            leftMs = presets[presetIndex] * 60000;
        clock = Date.now();
        endAt = clock + leftMs;
        running = true;
    }

    function finish() {
        running = false;
        leftMs = 0;
        notify("Time is up");
    }

    function notify(text) {
        const cmd = 'notify-send -a Dock "Timer" "' + text + '"';
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
        running: tm.onScreen && tm.running
        onTriggered: {
            tm.clock = Date.now();
            if (tm.clock >= tm.endAt)
                tm.finish();
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        height: tm.inner
        spacing: tm.inner * 0.22

        GridLayout {
            Layout.alignment: Qt.AlignVCenter
            columns: 2
            rowSpacing: tm.inner * 0.08
            columnSpacing: tm.inner * 0.08

            Repeater {
                model: tm.presets

                delegate: QQC2.AbstractButton {
                    id: pill
                    required property var modelData
                    required property int index
                    readonly property bool active: index === tm.presetIndex

                    Layout.preferredWidth: tm.inner * 0.72
                    Layout.preferredHeight: tm.inner * 0.42
                    scale: pressed ? 0.94 : 1
                    onClicked: tm.pick(index)

                    Behavior on scale {
                        NumberAnimation { duration: 80 }
                    }

                    background: Rectangle {
                        radius: height / 2
                        color: pill.active ? Qt.alpha(Kirigami.Theme.highlightColor, 0.2)
                                           : Qt.alpha(Kirigami.Theme.textColor, 0.1)
                        border.width: 1
                        border.color: pill.active ? Kirigami.Theme.highlightColor
                                                  : Qt.alpha(Kirigami.Theme.textColor, 0)
                    }
                    contentItem: PlasmaComponents.Label {
                        text: pill.modelData + "m"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: tm.inner * 0.22
                        font.weight: pill.active ? Font.Bold : Font.Medium
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignVCenter
            text: tm.mmss(tm.shownMs)
            font.pixelSize: tm.inner * 0.5
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }

        QQC2.AbstractButton {
            id: playButton
            Layout.preferredWidth: tm.inner * 0.72
            Layout.preferredHeight: tm.inner * 0.72
            Layout.alignment: Qt.AlignVCenter
            scale: pressed ? 0.94 : 1
            onClicked: tm.toggle()

            Behavior on scale {
                NumberAnimation { duration: 80 }
            }

            background: Rectangle {
                radius: width / 2
                color: Kirigami.Theme.highlightColor
            }
            contentItem: Kirigami.Icon {
                source: tm.running ? "media-playback-pause" : "media-playback-start"
                isMask: true
                color: Kirigami.Theme.highlightedTextColor
                implicitWidth: tm.inner * 0.3
                implicitHeight: tm.inner * 0.3
            }
        }
    }
}
