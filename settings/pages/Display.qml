import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import ".."

Sheet {
    id: pg
    title: "Display"
    subtitle: outputs.length === 1 ? "1 screen connected" : outputs.length + " screens connected"
    iconName: "display"
    Exec { id: sh }
    // Apply a display change, then ask to keep it; no answer in 15 s runs `undo`.
    property string undoCmd: ""
    function trial(doCmd, undo, what) {
        undoCmd = undo;
        sh.run(doCmd, () => { load(); keepBox.message = what; keepBox.begin(); });
    }
    Confirm {
        id: keepBox
        title: "Keep these display settings?"
        onKeep: { pg.undoCmd = ""; pg.toast("Display settings kept", "check"); }
        onRevert: { sh.run(pg.undoCmd, () => pg.load()); pg.toast("Display settings reverted", "display"); }
    }
    property var outputs: []
    property int selIdx: 0
    property bool loaded: false

    function load() {
        sh.run("kscreen-doctor -j", (o) => {
            try { outputs = JSON.parse(o).outputs.filter(x => x.connected); } catch (e) { outputs = []; }
            if (selIdx >= outputs.length) selIdx = 0;
            loaded = true;
        });
    }
    // Nearest edge-to-edge (or aligned) position next to the other screens, within 120 px; never negative.
    function snapped(o, x, y, w, h) {
        let bx = x, by = y, dx = 120, dy = 120;
        outputs.forEach(q => {
            if (q.name === o.name || !q.enabled) return;
            const qs = cur(q).size, qw = qs.width / q.scale, qh = qs.height / q.scale;
            [q.pos.x + qw, q.pos.x - w, q.pos.x, q.pos.x + qw - w].forEach(c => { if (Math.abs(c - x) < dx) { dx = Math.abs(c - x); bx = c; } });
            [q.pos.y, q.pos.y + qh - h, q.pos.y + qh, q.pos.y - h].forEach(c => { if (Math.abs(c - y) < dy) { dy = Math.abs(c - y); by = c; } });
        });
        return { x: Math.max(0, Math.round(bx)), y: Math.max(0, Math.round(by)) };
    }
    function cur(o) { return (o.modes || []).find(m => m.id === o.currentModeId) || { size: { width: 1920, height: 1080 }, refreshRate: 60 }; }
    Component.onCompleted: load()

    actions: Btn { text: "Refresh"; iconName: "refresh"; quiet: true; onClicked: pg.load() }

    // ---- Arrangement ----
    Card {
        title: "Arrangement"
        description: pg.outputs.length > 1 ? "Pick a screen to change it." : ""
        Item {
            id: area
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            // Dotted desk the screens sit on.
            Grid {
                anchors.fill: parent
                anchors.margins: 14
                columns: Math.floor(width / 18)
                spacing: 16
                clip: true
                Repeater { model: Math.floor(area.width / 18) * Math.floor(area.height / 18); Rectangle { width: 2; height: 2; radius: 1; color: Theme.ink4; opacity: 0.5 } }
            }
            readonly property real bw: Math.max(1, Math.max.apply(null, pg.outputs.map(o => o.pos.x + pg.cur(o).size.width / o.scale).concat([1])))
            readonly property real bh: Math.max(1, Math.max.apply(null, pg.outputs.map(o => o.pos.y + pg.cur(o).size.height / o.scale).concat([1])))
            readonly property real k: Math.min((width - 120) / bw, (height - 60) / bh)
            readonly property real ox: (width - bw * k) / 2
            readonly property real oy: (height - bh * k) / 2
            Repeater {
                model: pg.outputs
                delegate: QQC2.AbstractButton {
                    id: mon
                    required property var modelData
                    required property int index
                    readonly property var sz: pg.cur(modelData).size
                    readonly property bool sel: pg.selIdx === index
                    x: area.ox + modelData.pos.x * area.k + 3
                    y: area.oy + modelData.pos.y * area.k + 3
                    width: sz.width / modelData.scale * area.k - 6
                    height: sz.height / modelData.scale * area.k - 6
                    focusPolicy: Qt.TabFocus
                    onClicked: pg.selIdx = index
                    // Drag a screen to move it. It snaps to the edges of the other screens when released.
                    DragHandler {
                        id: dh
                        target: mon
                        onActiveChanged: {
                            if (active) { pg.selIdx = mon.index; return; }
                            const k = area.k;
                            const w = mon.sz.width / mon.modelData.scale, h = mon.sz.height / mon.modelData.scale;
                            const p = pg.snapped(mon.modelData, Math.round((mon.x - 3 - area.ox) / k), Math.round((mon.y - 3 - area.oy) / k), w, h);
                            sh.run("kscreen-doctor output." + mon.modelData.name + ".position." + p.x + "," + p.y, () => pg.load());
                        }
                    }
                    background: Rectangle {
                        radius: 10
                        opacity: mon.modelData.enabled ? 1 : 0.5
                        gradient: Gradient {
                            GradientStop { position: 0; color: mon.sel ? Theme.mix(Theme.card, Theme.accent, 0.35) : Theme.cardHi }
                            GradientStop { position: 1; color: mon.sel ? Theme.mix(Theme.card, Theme.accent, 0.18) : Theme.well }
                        }
                        border.width: mon.sel ? 2 : 1
                        border.color: mon.sel ? Theme.accent : Theme.wellRim
                        FocusRing { shown: mon.visualFocus; round: 10 }
                    }
                    contentItem: ColumnLayout {
                        spacing: 2
                        Item { Layout.fillHeight: true }
                        QQC2.Label { text: mon.modelData.name; color: Theme.ink; font.pixelSize: Theme.fsSmall; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter }
                        QQC2.Label { text: mon.sz.width + " × " + mon.sz.height; color: Theme.ink3; font.pixelSize: Theme.fsCaption; Layout.alignment: Qt.AlignHCenter; font.features: { "tnum": 1 } }
                        Item { Layout.fillHeight: true }
                    }
                }
            }
            EmptyState { visible: pg.loaded && pg.outputs.length === 0; anchors.centerIn: parent; width: 300; iconName: "display"; title: "No screens found"; body: "kscreen-doctor did not report any connected output." }
            Skeleton { visible: !pg.loaded; anchors.centerIn: parent; width: 220; height: 124; radius: 10 }
        }
    }

    // ---- Selected screen ----
    Repeater {
        model: pg.outputs.length ? [pg.outputs[pg.selIdx]] : []
        delegate: Card {
            id: dc
            required property var modelData
            title: modelData.name
            description: [pg.cur(modelData).size.width + " × " + pg.cur(modelData).size.height, Math.round(pg.cur(modelData).refreshRate) + " Hz", Math.round(modelData.scale * 100) + "% scale"].join("  ·  ")
            trailing: Toggle {
                checked: dc.modelData.enabled
                Accessible.name: "Screen enabled"
                Tip { text: dc.modelData.enabled ? "Turn this screen off" : "Turn this screen on"; shown: parent.hovered }
                onToggled: sh.run("kscreen-doctor output." + dc.modelData.name + (checked ? ".enable" : ".disable"), () => pg.load())
            }
            SettingRow {
                iconName: "display"
                label: "Resolution and refresh"
                Combo {
                    model: dc.modelData.modes; textRole: "name"; valueRole: "id"
                    Component.onCompleted: currentIndex = indexOfValue(dc.modelData.currentModeId)
                    onActivated: pg.trial("kscreen-doctor output." + dc.modelData.name + ".mode." + currentValue, "kscreen-doctor output." + dc.modelData.name + ".mode." + dc.modelData.currentModeId, "Mode set to " + currentText + ".")
                }
            }
            SettingRow {
                iconName: "scale"
                label: "Scale"
                caption: "Size of text and controls"
                Segmented {
                    readonly property var steps: [1, 1.25, 1.5, 1.75, 2]
                    model: steps.map(s => Math.round(s * 100) + "%")
                    currentIndex: { let b = 0; steps.forEach((s, i) => { if (Math.abs(s - dc.modelData.scale) < Math.abs(steps[b] - dc.modelData.scale)) b = i; }); return b; }
                    onPicked: (i) => { currentIndex = i; pg.trial("kscreen-doctor output." + dc.modelData.name + ".scale." + steps[i], "kscreen-doctor output." + dc.modelData.name + ".scale." + dc.modelData.scale, "Scale set to " + Math.round(steps[i] * 100) + "%."); }
                }
            }
            SettingRow {
                iconName: "rotate"
                label: "Rotation"
                Segmented {
                    readonly property var rots: ["none", "right", "inverted", "left"]
                    model: ["0°", "90°", "180°", "270°"]
                    currentIndex: Math.max(0, [1, 8, 4, 2].indexOf(dc.modelData.rotation))
                    onPicked: (i) => { currentIndex = i; pg.trial("kscreen-doctor output." + dc.modelData.name + ".rotation." + rots[i], "kscreen-doctor output." + dc.modelData.name + ".rotation." + rots[Math.max(0, [1, 8, 4, 2].indexOf(dc.modelData.rotation))], "Rotation set to " + ["0°", "90°", "180°", "270°"][i] + "."); }
                }
            }
            SettingRow {
                iconName: "sun"
                label: "Brightness"
                Slide {
                    id: bs
                    Layout.preferredWidth: 200
                    from: 5; to: 100; stepSize: 5; value: Math.round(dc.modelData.brightness * 100)
                    onPressedChanged: if (!pressed) sh.run("kscreen-doctor output." + dc.modelData.name + ".brightness." + Math.round(value))
                }
                QQC2.Label { text: Math.round(bs.value) + "%"; color: Theme.ink2; font.pixelSize: Theme.fsSmall; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight; font.features: { "tnum": 1 } }
            }
            SettingRow {
                visible: pg.outputs.length > 1
                iconName: "display"
                label: "Primary screen"
                caption: dc.modelData.priority === 1 ? "Panels and new windows open here" : "Make this the screen panels and new windows use"
                Btn { text: dc.modelData.priority === 1 ? "Primary" : "Make primary"; small: true; primary: dc.modelData.priority !== 1; enabled: dc.modelData.priority !== 1; onClicked: sh.run("kscreen-doctor output." + dc.modelData.name + ".priority.1", () => { pg.load(); pg.toast(dc.modelData.name + " is now primary", "display"); }) }
            }
            SettingRow {
                visible: pg.outputs.length > 1
                iconName: "display"
                label: "Mirror"
                caption: "Show another screen's picture on this one"
                Combo {
                    id: mc
                    readonly property var others: pg.outputs.filter(x => x.name !== dc.modelData.name).map(x => x.name)
                    model: ["Off"].concat(others)
                    currentIndex: { const src = pg.outputs.find(x => x.id === dc.modelData.replicationSource); return src ? Math.max(0, others.indexOf(src.name) + 1) : 0; }
                    Layout.preferredWidth: 180
                    onActivated: (i) => pg.trial("kscreen-doctor output." + dc.modelData.name + ".mirror." + (i === 0 ? "none" : others[i - 1]), "kscreen-doctor output." + dc.modelData.name + ".mirror.none", i === 0 ? "Mirroring turned off." : dc.modelData.name + " now mirrors " + others[i - 1] + ".")
                }
            }
            SettingRow {
                visible: dc.modelData.vrrPolicy !== undefined
                iconName: "gauge"
                label: "Adaptive sync"
                caption: "Variable refresh rate, for games and smoother video"
                Combo {
                    readonly property var pol: ["never", "always", "automatic"]
                    model: ["Never", "Always", "Automatic"]
                    currentIndex: Math.max(0, Math.min(2, dc.modelData.vrrPolicy))
                    Layout.preferredWidth: 180
                    onActivated: (i) => sh.run("kscreen-doctor output." + dc.modelData.name + ".vrrpolicy." + pol[i], () => { pg.load(); pg.toast("Adaptive sync: " + currentText, "check"); })
                }
            }
            SettingRow {
                visible: dc.modelData.hdr !== undefined
                iconName: "sun"
                label: "High dynamic range (HDR)"
                caption: "Brighter highlights on screens that support it"
                last: true
                Toggle { checked: dc.modelData.hdr === true; onToggled: sh.run("kscreen-doctor output." + dc.modelData.name + ".hdr." + (checked ? "enable" : "disable"), () => pg.load()) }
            }
        }
    }

    Card {
        title: "More"
        SettingRow { iconName: "night-light"; label: "Night light"; caption: "Warmer colours in the evening"; clickable: true; onClicked: pg.openKcm("kcm_nightlight") }
        SettingRow { iconName: "sliders"; label: "Display configuration"; caption: "Arrange screens, HDR, overscan and more"; clickable: true; last: true; onClicked: pg.openKcm("kcm_kscreen") }
    }
}
