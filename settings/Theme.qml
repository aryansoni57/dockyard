pragma Singleton
import QtQuick
import QtCore
import org.kde.kirigami as Kirigami

// Design tokens for Dockyard Settings: colour (night, day, auto + accent), type scale, spacing,
// radii and motion. See docs/DESIGN.md. Mode, accent, rail and recent pages persist.
QtObject {
    id: t
    property Settings store: Settings {
        location: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/dockyard-settings.conf"
        category: "ui"
        property string mode: "night"
        property string accent: "#ec4f86"
        property bool rail: false
        property bool sync: true     // follow the system colour scheme and accent
        property string recent: "[]"
    }
    property string mode: store.mode
    property int hour: new Date().getHours()
    property Timer tick: Timer { interval: 60000; running: true; repeat: true; onTriggered: t.hour = new Date().getHours() }
    readonly property bool sync: store.sync
    readonly property bool dark: sync ? sysDark : (mode === "night" || (mode === "auto" && (hour >= 19 || hour < 7)))

    // ---- System theme (kdeglobals): window background darkness and the accent ----
    property bool sysDark: true
    property color sysAccent: "#ec4f86"
    property bool sysAccentOk: false
    function readSystem() {
        const x = new XMLHttpRequest();
        const path = String(StandardPaths.writableLocation(StandardPaths.ConfigLocation));
        x.open("GET", (path.indexOf("file:") === 0 ? "" : "file://") + path + "/kdeglobals", false);
        try { x.send(); } catch (e) { return; }
        let sec = "", win = "", accent = "", focus = "";
        (x.responseText || "").split("\n").forEach(l => {
            const m = l.match(/^\[(.+)\]$/);
            if (m) { sec = m[1]; return; }
            if (sec === "General" && /^AccentColor=/.test(l)) accent = l.slice(12);
            if (sec === "Colors:Window" && /^BackgroundNormal=/.test(l)) win = l.slice(17);
            if (sec === "Colors:Window" && /^DecorationFocus=/.test(l)) focus = l.slice(16);
        });
        const rgb = (v) => { const p = v.split(",").map(n => parseInt(n)); return p.length >= 3 && p.every(n => n >= 0 && n <= 255) ? Qt.rgba(p[0] / 255, p[1] / 255, p[2] / 255, 1) : null; };
        const w = rgb(win);
        if (w) sysDark = lum(w) < 0.5;
        const c = rgb(accent) || rgb(focus);
        if (c) { sysAccent = c; sysAccentOk = true; }
    }
    property Timer sysWatch: Timer { interval: 1500; repeat: true; running: store.sync; triggeredOnStart: true; onTriggered: t.readSystem() }

    // The mode and accent are ours to change only while we are not following the system.
    function setMode(m) { if (!store.sync) store.mode = m; }
    function setAccent(c) { if (!store.sync) store.accent = c; }
    function setSync(on) { store.sync = on; if (on) readSystem(); }
    function a(c, al) { return Qt.rgba(c.r, c.g, c.b, al); }
    function mix(a1, a2, k) { const c1 = Qt.color(a1), c2 = Qt.color(a2); return Qt.rgba(c1.r + (c2.r - c1.r) * k, c1.g + (c2.g - c1.g) * k, c1.b + (c2.b - c1.b) * k, 1); }
    // Accent-tinted neutral: the surfaces follow the chosen accent hue (saturation fades out for grey accents).
    readonly property real hue: Math.max(0, accent.hslHue)
    readonly property real tint: Math.min(1, accent.hslSaturation * 1.4)
    function tone(s, l, al) { return Qt.hsla(hue, s * tint, l, al === undefined ? 1 : al); }
    function lum(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b; }

    // ---- Accent ----
    readonly property var accents: [
        { n: "Rose", c: "#ec4f86" }, { n: "Violet", c: "#9b6bff" }, { n: "Dockyard blue", c: "#3b82f6" },
        { n: "Teal", c: "#14b8a6" }, { n: "Amber", c: "#e8a317" }, { n: "Green", c: "#3fb56b" },
        { n: "Coral", c: "#ff7a59" }, { n: "Graphite", c: "#8a8f99" }
    ]
    readonly property color accent: sync && sysAccentOk ? sysAccent : store.accent
    // Text and icons placed on an accent fill: dark on light accents (amber), white otherwise.
    readonly property color accentFg: (0.2126 * accent.r + 0.7152 * accent.g + 0.0722 * accent.b) > 0.58 ? "#1c1218" : "#ffffff"
    readonly property color accentText: accentFg
    // Accent used as text or an icon on our surfaces; lifted at night, deepened by day for contrast.
    readonly property color accentInk: dark ? mix(accent, "#ffffff", 0.32) : mix(accent, "#000000", 0.22)
    readonly property color accentSoft: a(accent, dark ? 0.20 : 0.13)
    readonly property color accentLine: a(accent, dark ? 0.55 : 0.45)

    // ---- Surfaces. Two planes: the glass rail (translucent, blurred) and the solid deck. ----
    readonly property color glass: dark ? tone(0.40, 0.065, 0.70) : tone(0.45, 0.965, 0.74)
    readonly property color deck: dark ? tone(0.26, 0.085) : tone(0.30, 0.96)
    readonly property color deckRim: dark ? Qt.rgba(1, 0.94, 0.98, 0.09) : Qt.rgba(0.2, 0.06, 0.18, 0.10)
    readonly property color card: dark ? tone(0.22, 0.125) : "#ffffff"
    readonly property color cardHi: dark ? tone(0.20, 0.16) : tone(0.30, 0.975)
    readonly property color raise: dark ? tone(0.16, 0.235) : "#ffffff"
    readonly property color well: dark ? tone(0.20, 0.16) : tone(0.26, 0.93)
    readonly property color wellRim: dark ? Qt.rgba(1, 0.94, 0.98, 0.10) : Qt.rgba(0.2, 0.06, 0.18, 0.13)
    readonly property color cardRim: dark ? Qt.rgba(1, 0.94, 0.98, 0.075) : Qt.rgba(0.2, 0.06, 0.18, 0.085)
    readonly property color line: dark ? Qt.rgba(1, 0.94, 0.98, 0.07) : Qt.rgba(0.2, 0.06, 0.18, 0.075)
    readonly property color hover: dark ? Qt.rgba(1, 0.94, 0.98, 0.06) : Qt.rgba(0.2, 0.06, 0.18, 0.05)
    readonly property color press: dark ? Qt.rgba(1, 0.94, 0.98, 0.10) : Qt.rgba(0.2, 0.06, 0.18, 0.09)
    readonly property color track: dark ? Qt.rgba(1, 0.94, 0.98, 0.14) : Qt.rgba(0.2, 0.06, 0.18, 0.13)
    readonly property color scrim: dark ? Qt.rgba(0.02, 0.0, 0.03, 0.62) : Qt.rgba(0.16, 0.06, 0.14, 0.30)
    readonly property color shadow: dark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(0.22, 0.06, 0.2, 0.16)

    // ---- Ink ----
    readonly property color ink: dark ? tone(0.30, 0.95) : tone(0.30, 0.10)
    readonly property color ink2: a(ink, dark ? 0.70 : 0.70)
    readonly property color ink3: a(ink, dark ? 0.50 : 0.54)
    readonly property color ink4: a(ink, dark ? 0.32 : 0.34)

    // ---- Status ----
    readonly property color ok: dark ? "#4fd18b" : "#16804a"
    readonly property color neutral: dark ? "#ffb547" : "#94560a"
    readonly property color bad: dark ? "#ff7272" : "#c0302d"
    readonly property color okSoft: a(ok, dark ? 0.16 : 0.12)
    readonly property color badSoft: a(bad, dark ? 0.16 : 0.10)

    // Kept for the colour scheme we hand to embedded modules (KcmModel.applyScheme).
    readonly property color paper: deck
    readonly property color paperAlt: card
    readonly property color field: well
    readonly property color win: glass
    readonly property color side: "transparent"
    readonly property color fieldRim: wellRim

    // ---- Type scale (px) ----
    readonly property int fsMicro: 11     // overlines, key hints
    readonly property int fsCaption: 12   // captions, secondary rows
    readonly property int fsSmall: 13     // controls, list rows
    readonly property int fsBody: 14      // row labels
    readonly property int fsTitle: 16     // card titles, dialogs
    readonly property int fsH2: 20        // module titles
    readonly property int fsH1: 28        // page titles
    readonly property int fsHero: 34      // overview greeting

    // ---- Spacing (4 px grid) and radii ----
    readonly property int s1: 4
    readonly property int s2: 8
    readonly property int s3: 12
    readonly property int s4: 16
    readonly property int s5: 20
    readonly property int s6: 24
    readonly property int s8: 32
    readonly property int s10: 40
    readonly property int rSm: 7
    readonly property int rCtl: 10
    readonly property int rCard: 16
    readonly property int rDeck: 20

    // Names of our own line icons in settings/icons (see Ico.qml).
    readonly property var icons: ["alert", "appearance", "apps", "arrow-left", "auto", "battery", "bluetooth", "bolt", "brush", "check", "chevron-down", "chevron-left", "chevron-right", "clock", "close", "cpu", "cursor", "deco", "disk", "display", "dots", "external", "gauge", "globe", "hardware", "headphones", "history", "home", "info", "input-devices", "keyboard", "leaf", "lock", "mark", "memory", "mic-off", "mic", "moon", "mouse", "network", "night-light", "pair", "palette", "phone", "plus", "power", "refresh", "rotate", "scale", "search", "shapes", "shield", "sidebar", "sliders", "sound-off", "sound", "sun", "timer", "type", "user", "wifi-0", "wifi-1", "wifi-2", "wifi-3", "wifi-off", "windows", "workspace"]

    // ---- Motion. Follows Plasma's animation speed; zero when animations are off. ----
    readonly property bool motion: Kirigami.Units.longDuration > 1
    readonly property int fast: motion ? 120 : 0
    readonly property int dur: motion ? 180 : 0
    readonly property int slow: motion ? 280 : 0
}
