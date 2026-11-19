import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Claude usage tile: the 5-hour session as a ring, with 5h and 7d bars beside it.
// Numbers come from scripts/claude-usage.py, which asks Anthropic's usage endpoint
// with the token Claude Code keeps in ~/.claude/.credentials.json.
Tile {
    id: root

    property bool active
    property int intervalSeconds: 120

    property bool ok: false
    property string error: ""
    property var five: null
    property var week: null
    property bool busy: false
    property real nowMs: Date.now()

    readonly property real inner: height - padding * 2
    readonly property string script: Qt.resolvedUrl("../../scripts/claude-usage.py").toString().replace("file://", "")
    readonly property string cmd: "timeout -k 2 20 python3 '" + script + "'"
    readonly property bool hasData: five !== null || week !== null
    readonly property color claude: "#D97757"

    function heat(p) { return p >= 90 ? "#FF453A" : p >= 70 ? "#FF9F0A" : root.claude; }

    function resetIn(b) {
        if (!b || !b.resetsAt)
            return "";
        const s = Math.floor((Date.parse(b.resetsAt) - nowMs) / 1000);
        if (isNaN(s))
            return "";
        if (s <= 0)
            return "0m";
        const d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600), m = Math.ceil((s % 3600) / 60);
        return d > 0 ? d + "d " + h + "h" : h > 0 ? h + "h " + m + "m" : m + "m";
    }

    function problem(e) {
        return ({
            no_credentials: i18n("Sign in with `claude` to see usage"),
            auth_expired: i18n("Claude login expired: run `claude` once"),
            rate_limited: i18n("Rate limited, showing last numbers"),
            network: i18n("Offline, showing last numbers"),
            server_error: i18n("Claude is not answering"),
            bad_response: i18n("Unexpected answer from Claude")
        })[e] || e;
    }

    function refresh(force) {
        if (!active || busy)
            return;
        busy = true;
        shell.run(cmd + (force ? " --force" : ""));
    }

    hoverName: !hasData ? i18n("Claude usage") + ": " + (problem(error) || "…")
        : i18n("Claude usage") + "\n" + i18n("5h resets in %1", resetIn(five) || "?")
          + "\n" + i18n("Week resets in %1", resetIn(week) || "?")
          + (ok ? "" : "\n" + problem(error))
    implicitWidth: Math.round(height * 2.7)

    ShellRunner {
        id: shell
        onFinished: (c, out, code, err) => {
            root.busy = false;
            try {
                const d = JSON.parse(out.trim());
                root.ok = d.ok === true;
                root.error = d.error || "";
                root.five = d.five || null;
                root.week = d.week || null;
            } catch (e) {
                root.ok = false;
                root.error = "bad_response";
            }
            root.nowMs = Date.now();
        }
    }

    Timer {
        interval: Math.max(60, root.intervalSeconds) * 1000
        running: root.active
        repeat: true
        onTriggered: root.refresh(false)
    }
    // First fetch, a beat after creation: a command sent while the tile is still being built is
    // dropped by ShellRunner's data source. Runs again each time the tile is switched on.
    Timer {
        interval: 600
        running: root.active
        onTriggered: root.refresh(false)
    }
    // Keeps the "resets in" text moving between fetches.
    Timer {
        interval: 30000
        running: root.active
        repeat: true
        onTriggered: root.nowMs = Date.now()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.padding
        anchors.rightMargin: root.padding * 1.4
        spacing: root.inner * 0.2

        RingGauge {
            Layout.preferredWidth: root.inner
            Layout.preferredHeight: root.inner
            Layout.alignment: Qt.AlignVCenter
            value: root.five ? root.five.used : 0
            text: root.five ? "" : "–"
            suffix: "%"
            label: "5h"
            accent: root.five ? root.heat(root.five.used) : root.claude
            opacity: root.ok || root.hasData ? 1 : 0.55
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: root.inner * 0.14

            Repeater {
                model: [
                    { name: "5h", b: root.five },
                    { name: "7d", b: root.week }
                ]

                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: root.inner * 0.1

                    PlasmaComponents.Label {
                        text: modelData.name
                        opacity: 0.78
                        font.pixelSize: Math.max(7, root.inner * 0.2)
                        font.weight: Font.DemiBold
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(3, root.inner * 0.07)
                        radius: height / 2
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.15)

                        Rectangle {
                            width: parent.width * (modelData.b ? modelData.b.used : 0) / 100
                            height: parent.height
                            radius: height / 2
                            color: modelData.b ? root.heat(modelData.b.used) : root.claude
                        }
                    }
                    PlasmaComponents.Label {
                        text: modelData.b ? modelData.b.used + "%" : "–"
                        font.pixelSize: Math.max(7, root.inner * 0.2)
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }
    }
}
