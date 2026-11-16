import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import ".."

Sheet {
    id: pg
    title: "Power"
    subtitle: (meta[profile] || { n: "" }).n + (battery >= 0 ? "  ·  Battery " + battery + "%" : "")
    iconName: "power"
    Exec { id: sh }
    property string profile: ""
    property var profiles: []
    property int battery: -1
    property string batState: ""
    readonly property var meta: ({
        "power-saver": { n: "Power Saver", d: "Longer battery life, cooler and quieter", i: "leaf" },
        "balanced": { n: "Balanced", d: "Everyday speed and battery", i: "gauge" },
        "performance": { n: "Performance", d: "Full speed, more heat and fan", i: "bolt" }
    })
    Component.onCompleted: {
        pkRead();
        sh.run("powerprofilesctl get", (o) => profile = o.trim());
        sh.run("powerprofilesctl list", (o) => profiles = (o.match(/^[* ] [a-z][\w-]*:$/gm) || []).map(s => s.replace(/[*:\s]/g, "")).sort((a, b) => ["power-saver", "balanced", "performance"].indexOf(a) - ["power-saver", "balanced", "performance"].indexOf(b)));
        // Every battery: average charge, and "Charging" if any is charging.
        sh.run("for b in /sys/class/power_supply/BAT*; do [ -r \"$b/capacity\" ] && echo \"$(cat $b/capacity) $(cat $b/status)\"; done 2>/dev/null", (o) => {
            const rows = o.trim().split("\n").filter(l => l).map(l => l.split(" "));
            if (!rows.length) { battery = -1; return; }
            battery = Math.round(rows.reduce((a, r) => a + parseInt(r[0]), 0) / rows.length);
            batState = rows.some(r => r[1] === "Charging") ? "Charging" : (rows[0][1] || "");
        });
    }

    Card {
        visible: pg.battery >= 0
        padded: true
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s4
            Chip { iconName: pg.batState === "Charging" ? "bolt" : "battery"; box: 44; tone: "accent" }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                RowLayout {
                    QQC2.Label { text: pg.battery + "%"; color: Theme.ink; font.pixelSize: Theme.fsH2 + 2; font.weight: Font.DemiBold; font.features: { "tnum": 1 } }
                    QQC2.Label { text: pg.batState; color: Theme.ink3; font.pixelSize: Theme.fsSmall; Layout.fillWidth: true; Layout.alignment: Qt.AlignBottom; bottomPadding: 3 }
                }
                Meter { Layout.fillWidth: true; implicitHeight: 8; value: pg.battery / 100; fill: pg.battery <= 15 ? Theme.bad : pg.batState === "Charging" ? Theme.ok : Theme.accent }
            }
        }
    }

    Card {
        title: "Power profile"
        description: "How hard the processor and graphics may work."
        padded: true
        GridLayout {
            Layout.fillWidth: true
            columns: pg.width > 600 ? Math.max(1, pg.profiles.length) : 1
            columnSpacing: Theme.s3
            rowSpacing: Theme.s3
            Repeater {
                model: pg.profiles
                delegate: QQC2.AbstractButton {
                    id: pc
                    required property string modelData
                    readonly property bool sel: pg.profile === modelData
                    readonly property var m: pg.meta[modelData] || { n: modelData, d: "", i: "power" }
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 116
                    focusPolicy: Qt.TabFocus
                    Accessible.name: m.n
                    onClicked: sh.run("powerprofilesctl set " + modelData, () => { pg.profile = modelData; pg.toast(pc.m.n + " profile", pc.m.i); })
                    background: Rectangle {
                        radius: Theme.rCard - 2
                        color: pc.sel ? Theme.accentSoft : (pc.hovered ? Theme.hover : "transparent")
                        border.width: pc.sel ? 2 : 1
                        border.color: pc.sel ? Theme.accent : Theme.line
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                        FocusRing { shown: pc.visualFocus; round: Theme.rCard - 2 }
                    }
                    contentItem: ColumnLayout {
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            Chip { iconName: pc.m.i; box: 36; tone: pc.sel ? "solid" : "neutral" }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                width: 18; height: 18; radius: 9
                                color: pc.sel ? Theme.accent : "transparent"
                                border.width: pc.sel ? 0 : 1.5
                                border.color: Theme.ink4
                                Ico { anchors.centerIn: parent; visible: pc.sel; name: "check"; size: 12; color: Theme.accentFg }
                            }
                        }
                        Item { Layout.fillHeight: true }
                        QQC2.Label { text: pc.m.n; color: Theme.ink; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold; Layout.fillWidth: true }
                        QQC2.Label { text: pc.m.d; color: Theme.ink3; font.pixelSize: Theme.fsCaption; Layout.fillWidth: true; elide: Text.ElideRight }
                    }
                    padding: 14
                }
            }
        }
        EmptyState { visible: pg.profiles.length === 0; Layout.fillWidth: true; iconName: "power"; title: "No power profiles"; body: "power-profiles-daemon is not running." }
    }

    // ---- Screen, sleep, lid and power button (powerdevilrc), per power source ----
    property string src: "AC"
    property var pv: ({})
    readonly property var srcNames: pg.battery >= 0 ? ["Plugged in", "On battery"] : ["Plugged in"]
    readonly property var timeOpts: [{ t: "Never", v: -1 }, { t: "1 minute", v: 60 }, { t: "2 minutes", v: 120 }, { t: "5 minutes", v: 300 }, { t: "10 minutes", v: 600 },
                                     { t: "15 minutes", v: 900 }, { t: "30 minutes", v: 1800 }, { t: "1 hour", v: 3600 }]
    readonly property var lidOpts: [{ t: "Do nothing", v: 0 }, { t: "Sleep", v: 1 }, { t: "Hibernate", v: 2 }, { t: "Shut down", v: 8 }, { t: "Lock screen", v: 32 }, { t: "Turn off screen", v: 64 }]
    readonly property var btnOpts: [{ t: "Do nothing", v: 0 }, { t: "Sleep", v: 1 }, { t: "Hibernate", v: 2 }, { t: "Shut down", v: 8 }, { t: "Show logout screen", v: 16 }, { t: "Lock screen", v: 32 }, { t: "Turn off screen", v: 64 }]
    // key: [group, key, default for AC, default for battery]
    readonly property var pkeys: ({
        dim: ["Display", "DimDisplayIdleTimeoutSec", 300, 120],
        off: ["Display", "TurnOffDisplayIdleTimeoutSec", 600, 300],
        sleep: ["SuspendAndShutdown", "AutoSuspendIdleTimeoutSec", 900, 600],
        lid: ["SuspendAndShutdown", "LidAction", 1, 1],
        btn: ["SuspendAndShutdown", "PowerButtonAction", 16, 16]
    })
    function pkRead() {
        const profile = pg.src, bat = profile !== "AC";
        let cmd = "";
        Object.keys(pkeys).forEach(k => { const d = pkeys[k]; cmd += "echo " + k + "=$(kreadconfig6 --file powerdevilrc --group " + profile + " --group " + d[0] + " --key " + d[1] + " --default " + (bat ? d[3] : d[2]) + "); "; });
        // The idle switches: an off switch means "Never", whatever the stored timeout is.
        cmd += "echo dimOn=$(kreadconfig6 --file powerdevilrc --group " + profile + " --group Display --key DimDisplayWhenIdle --default true); ";
        cmd += "echo offOn=$(kreadconfig6 --file powerdevilrc --group " + profile + " --group Display --key TurnOffDisplayWhenIdle --default true); ";
        cmd += "echo sleepAct=$(kreadconfig6 --file powerdevilrc --group " + profile + " --group SuspendAndShutdown --key AutoSuspendAction --default 1)";
        sh.run(cmd, (o) => {
            const m = {};
            o.trim().split("\n").forEach(l => { const i = l.indexOf("="); if (i > 0) m[l.slice(0, i)] = l.slice(i + 1); });
            pv = {
                dim: m.dimOn === "false" ? -1 : parseInt(m.dim), off: m.offOn === "false" ? -1 : parseInt(m.off),
                sleep: m.sleepAct === "0" ? -1 : parseInt(m.sleep), lid: parseInt(m.lid), btn: parseInt(m.btn)
            };
        });
    }
    function pkWrite(k, v) {
        const d = pkeys[k], profile = pg.src;
        const w = (grp, key, val, type) => "kwriteconfig6 --file powerdevilrc --group " + profile + " --group " + grp + " --key " + key + (type ? " --type " + type : "") + " " + val + "; ";
        let cmd = "";
        if (k === "dim") cmd = w("Display", "DimDisplayWhenIdle", v >= 0 ? "true" : "false", "bool") + (v >= 0 ? w("Display", d[1], v) : "");
        else if (k === "off") cmd = w("Display", "TurnOffDisplayWhenIdle", v >= 0 ? "true" : "false", "bool") + (v >= 0 ? w("Display", d[1], v) : "");
        else if (k === "sleep") cmd = w("SuspendAndShutdown", "AutoSuspendAction", v >= 0 ? 1 : 0) + (v >= 0 ? w("SuspendAndShutdown", d[1], v) : "");
        else cmd = w(d[0], d[1], v);
        sh.run(cmd + "qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement reparseConfiguration", () => pg.pkRead());
        pg.toast("Power setting saved", "check");
    }
    // A stored value that is not one of the presets still shows, as its own entry.
    function withValue(opts, v) { return opts.some(o => o.v === v) || isNaN(v) ? opts : opts.concat([{ t: v >= 60 ? Math.round(v / 60) + " minutes" : v + " s", v: v }]); }
    onSrcChanged: pkRead()

    Card {
        title: "Screen, sleep and buttons"
        description: "Applies to the selected power source."
        SettingRow {
            visible: pg.srcNames.length > 1
            iconName: "power"
            label: "Power source"
            Segmented { model: pg.srcNames; currentIndex: pg.src === "AC" ? 0 : 1; onPicked: (i) => { currentIndex = i; pg.src = i === 0 ? "AC" : "Battery"; } }
        }
        Repeater {
            model: [
                { k: "dim", n: "Dim screen", i: "sun", o: "time" }, { k: "off", n: "Turn off screen", i: "display", o: "time" }, { k: "sleep", n: "Sleep", i: "moon", o: "time" },
                { k: "lid", n: "When the lid is closed", i: "laptop", o: "lid" }, { k: "btn", n: "When the power button is pressed", i: "power", o: "btn" }
            ]
            delegate: SettingRow {
                id: pr
                required property var modelData
                required property int index
                iconName: Theme.icons.indexOf(modelData.i) >= 0 ? modelData.i : "power"
                label: modelData.n
                visible: modelData.o !== "lid" || pg.hasLid
                Combo {
                    id: pcb
                    Layout.preferredWidth: 180
                    readonly property var opts: pg.withValue(pr.modelData.o === "time" ? pg.timeOpts : pr.modelData.o === "lid" ? pg.lidOpts : pg.btnOpts, pg.pv[pr.modelData.k])
                    model: opts; textRole: "t"; valueRole: "v"
                    currentIndex: pg.pv[pr.modelData.k] === undefined ? -1 : indexOfValue(pg.pv[pr.modelData.k])
                    onActivated: pg.pkWrite(pr.modelData.k, currentValue)
                }
            }
        }
    }

    property bool hasLid: false
    Timer { running: true; interval: 10; onTriggered: sh.run("qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement isLidPresent", (o) => pg.hasLid = o.trim() === "true") }

    Card {
        title: "Sleep and lock"
        SettingRow { iconName: "timer"; label: "Energy saving"; caption: "Screen off, sleep and brightness timeouts"; clickable: true; onClicked: pg.openKcm("kcm_powerdevilprofilesconfig") }
        SettingRow { iconName: "lock"; label: "Lock screen"; caption: "When to lock and what it shows"; clickable: true; last: true; onClicked: pg.openKcm("kcm_screenlocker") }
    }
}
