import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import ".."

Sheet {
    id: pg
    title: "Sound"
    subtitle: muted ? "Output muted" : "Volume " + Math.round(vol * 100) + "%"
    iconName: "sound"
    Exec { id: sh }
    property var sinks: []
    property string defSink: ""
    property var sources: []
    property string defSource: ""
    property real vol: 0
    property bool muted: false
    property real micVol: 0
    property real balance: 0          // -1 left .. 1 right, from the default output's channel volumes
    property var apps: []             // playing streams: { idx, name, vol, muted }
    property bool micMuted: false
    function parse(o) { return { v: parseFloat((o.match(/Volume:\s*([\d.]+)/) || [0, 0])[1]), m: o.indexOf("MUTED") >= 0 }; }
    function load() {
        // One call fills both the device list and the balance (Exec keys callbacks by command text).
        sh.run("pactl -f json list sinks", (o) => {
            try {
                const l = JSON.parse(o);
                if (JSON.stringify(l.map(x => x.name)) !== JSON.stringify(sinks.map(x => x.name))) sinks = l;
                const sk = l.find(x => x.name === defSink) || l[0];
                const lv = parseInt(sk.volume["front-left"].value_percent), rv = parseInt(sk.volume["front-right"].value_percent);
                balance = Math.max(lv, rv) > 0 ? (rv - lv) / Math.max(lv, rv) : 0;
            } catch (e) { sinks = []; balance = 0; }
        });
        sh.run("pactl -f json list sink-inputs", (o) => {
            try {
                apps = JSON.parse(o).map(i => {
                    const ch = Object.keys(i.volume || {});
                    const v = ch.length ? Math.max.apply(null, ch.map(c => parseInt(i.volume[c].value_percent))) / 100 : 1;
                    const pr = i.properties || {};
                    return { idx: i.index, name: pr["application.name"] || pr["media.name"] || "Stream", detail: pr["media.name"] || "", icon: pr["application.icon_name"] || "", vol: v, muted: i.mute === true };
                });
            } catch (e) { apps = []; }
        });
        sh.run("pactl -f json list sources", (o) => { try { { const l = JSON.parse(o).filter(x => !/\.monitor$/.test(x.name)); if (JSON.stringify(l.map(x => x.name)) !== JSON.stringify(sources.map(x => x.name))) sources = l; } } catch (e) { sources = []; } });
        sh.run("pactl get-default-source", (o) => defSource = o.trim());
        sh.run("pactl get-default-sink", (o) => defSink = o.trim());
        sh.run("wpctl get-volume @DEFAULT_AUDIO_SINK@", (o) => { const p = parse(o); vol = p.v; muted = p.m; });
        sh.run("wpctl get-volume @DEFAULT_AUDIO_SOURCE@", (o) => { const p = parse(o); micVol = p.v; micMuted = p.m; });
    }
    Component.onCompleted: load()
    // Streams come and go; keep the application list current while the page is open.
    Timer { interval: 3000; repeat: true; running: pg.visible; onTriggered: pg.load() }
    function setBalance(b) {
        // Keep the louder channel at the current volume and lower the other one.
        const v = Math.round(Math.max(0.01, vol) * 100);
        const l = Math.round(v * (1 - Math.max(0, b))), r = Math.round(v * (1 + Math.min(0, b)));
        sh.run("pactl set-sink-volume @DEFAULT_SINK@ " + l + "% " + r + "%");
    }

    // Big level control: mute button, slider, percentage.
    component Level: RowLayout {
        id: lv
        property string glyph
        property string glyphOff
        property bool off
        property real level
        property real ceiling: 1
        signal moved(real v)
        signal muteClicked()
        Layout.fillWidth: true
        spacing: Theme.s3
        QQC2.AbstractButton {
            id: mb
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            focusPolicy: Qt.TabFocus
            Accessible.name: lv.off ? "Unmute" : "Mute"
            onClicked: lv.muteClicked()
            Tip { text: lv.off ? "Unmute" : "Mute"; shown: mb.hovered }
            background: Rectangle {
                radius: 14
                color: lv.off ? Theme.badSoft : (mb.hovered ? Theme.a(Theme.accent, 0.28) : Theme.accentSoft)
                Behavior on color { ColorAnimation { duration: Theme.fast } }
                FocusRing { shown: mb.visualFocus; round: 14 }
            }
            contentItem: Item { Ico { anchors.centerIn: parent; name: lv.off ? lv.glyphOff : lv.glyph; size: 22; color: lv.off ? Theme.bad : Theme.accentInk } }
        }
        Slide {
            id: sl
            Layout.fillWidth: true
            from: 0; to: lv.ceiling; stepSize: 0.01
            opacity: lv.off ? 0.45 : 1
            Binding on value { when: !sl.pressed; value: lv.level }
            onMoved: lv.moved(value)
        }
        QQC2.Label {
            text: Math.round(sl.value * 100) + "%"
            color: lv.off ? Theme.ink3 : Theme.ink
            font.pixelSize: Theme.fsTitle
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
            Layout.preferredWidth: 52
            horizontalAlignment: Text.AlignRight
        }
    }

    Card {
        title: "Output"
        description: vol > 1 ? "Above 100% can distort." : ""
        SettingRow {
            iconName: "headphones"
            label: "Device"
            Combo {
                Layout.preferredWidth: Math.min(320, pg.width * 0.4)
                model: pg.sinks; textRole: "description"; valueRole: "name"
                currentIndex: count > 0 ? indexOfValue(pg.defSink) : -1
                onActivated: { sh.run("pactl set-default-sink '" + currentValue + "'", () => pg.load()); pg.toast("Output: " + currentText, "headphones"); }
            }
        }
        Item {
            Layout.fillWidth: true
            implicitHeight: 76
            Level {
                anchors { fill: parent; leftMargin: Theme.s4 + 2; rightMargin: Theme.s4 + 2 }
                glyph: "sound"; glyphOff: "sound-off"
                off: pg.muted; level: pg.vol; ceiling: 1.5
                onMoved: (v) => sh.run("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ " + v.toFixed(2))
                onMuteClicked: { pg.muted = !pg.muted; sh.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", () => pg.load()); }
            }
        }
        SettingRow {
            iconName: "headphones"
            label: "Balance"
            caption: Math.abs(pg.balance) < 0.02 ? "Centered" : (pg.balance < 0 ? "Left " : "Right ") + Math.round(Math.abs(pg.balance) * 100) + "%"
            last: true
            RowLayout {
                spacing: Theme.s2
                QQC2.Label { text: "L"; color: Theme.ink3; font.pixelSize: Theme.fsCaption }
                Slide {
                    id: bal
                    Layout.preferredWidth: 200
                    from: -1; to: 1; stepSize: 0.05
                    Binding on value { when: !bal.pressed; value: pg.balance }
                    onPressedChanged: if (!pressed) { if (Math.abs(value) < 0.05) value = 0; pg.setBalance(value); }
                }
                QQC2.Label { text: "R"; color: Theme.ink3; font.pixelSize: Theme.fsCaption }
            }
        }
    }

    Card {
        visible: pg.apps.length > 0
        title: "Applications"
        description: "Volume for each app that is playing sound."
        Repeater {
            model: pg.apps
            delegate: SettingRow {
                id: ar
                required property var modelData
                required property int index
                iconName: "sound"
                label: modelData.name
                caption: modelData.detail
                last: index === pg.apps.length - 1
                RowLayout {
                    spacing: Theme.s3
                    Slide {
                        id: asl
                        Layout.preferredWidth: 170
                        from: 0; to: 1; stepSize: 0.01
                        opacity: ar.modelData.muted ? 0.45 : 1
                        Binding on value { when: !asl.pressed; value: ar.modelData.vol }
                        onMoved: sh.run("pactl set-sink-input-volume " + ar.modelData.idx + " " + Math.round(value * 100) + "%")
                    }
                    QQC2.Label { text: Math.round(asl.value * 100) + "%"; color: Theme.ink2; font.pixelSize: Theme.fsSmall; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight; font.features: { "tnum": 1 } }
                    IconBtn { iconName: ar.modelData.muted ? "sound-off" : "sound"; tip: ar.modelData.muted ? "Unmute" : "Mute"; onClicked: sh.run("pactl set-sink-input-mute " + ar.modelData.idx + " toggle", () => pg.load()) }
                }
            }
        }
    }

    Card {
        title: "Input"
        SettingRow {
            visible: pg.sources.length > 0
            iconName: "mic"
            label: "Device"
            Combo {
                Layout.preferredWidth: Math.min(320, pg.width * 0.4)
                model: pg.sources; textRole: "description"; valueRole: "name"
                currentIndex: count > 0 ? indexOfValue(pg.defSource) : -1
                onActivated: { sh.run("pactl set-default-source '" + String(currentValue).replace(/'/g, "'\\''") + "'", () => pg.load()); pg.toast("Input: " + currentText, "mic"); }
            }
        }
        Item {
            Layout.fillWidth: true
            implicitHeight: 76
            Level {
                anchors { fill: parent; leftMargin: Theme.s4 + 2; rightMargin: Theme.s4 + 2 }
                glyph: "mic"; glyphOff: "mic-off"
                off: pg.micMuted; level: pg.micVol
                onMoved: (v) => sh.run("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + v.toFixed(2))
                onMuteClicked: { pg.micMuted = !pg.micMuted; sh.run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", () => pg.load()); }
            }
        }
    }

    Card {
        title: "More"
        SettingRow { iconName: "sliders"; label: "Advanced audio"; caption: "Per-app volume, profiles and device configuration"; clickable: true; last: true; onClicked: pg.openKcm("kcm_pulseaudio") }
    }
}
