import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.private.brightnesscontrolplugin as Brightness

// Quick toggle state and actions (docs/PLAN-apps-toggles.md, Set B). Polls
// Wi-Fi, Bluetooth, mute and Night Light with one read-only shell command every
// 5 s while `active`; Do Not Disturb is pushed by NotificationManager. The
// quick-toggles module is a dumb view over `items`; `toggle(key)` does the work.
Item {
    id: src

    property bool active: false
    property var keys: []

    property bool wifiAvailable: false
    property bool wifiOn: false
    property bool btAvailable: false
    property bool btOn: false
    property bool muteAvailable: false
    property bool muted: false
    property bool nightAvailable: false
    // Quick Share (rquickshare): available when installed, on while it is running.
    property bool qsAvailable: false
    property bool qsOn: false

    // Extra state for the quick settings flyout.
    property string ssid: ""
    property string btDevice: ""
    property int volume: 0
    // [{ id, label, value 0-100, max, internal }], one per display with brightness control
    property var displays: []
    property int displayIndex: 0
    // [{ ssid, signal, secure, known, active }] and [{ mac, name, icon, connected, battery }],
    // filled by scanNetworks() / scanDevices() while a detail view is open.
    property var networks: []
    property var devices: []
    property bool scanning: false
    property string netStatus: ""

    // Refreshed on each poll; DND compares its expiry against this.
    property date clock: new Date()

    readonly property string pollCmd: "echo wifi=$(timeout 2 nmcli radio wifi 2>/dev/null); echo bt=$(timeout 2 bluetoothctl show 2>/dev/null | grep -m1 Powered); echo vol=$(timeout 2 wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null); echo qs=$(if pgrep -x rquickshare >/dev/null; then echo on; elif command -v rquickshare >/dev/null; then echo off; fi); echo night=$(timeout 2 busctl --user get-property org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight enabled 2>/dev/null); echo ssid=$(timeout 2 nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep -m1 '^yes:' | cut -d: -f2-); echo btdev=$(timeout 2 bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-); for d in $(timeout 2 busctl --user get-property org.kde.ScreenBrightness /org/kde/ScreenBrightness org.kde.ScreenBrightness DisplaysDBusNames 2>/dev/null | cut -d' ' -f3- | tr -d '\"'); do p=/org/kde/ScreenBrightness/$d; i=org.kde.ScreenBrightness.Display; g() { timeout 2 busctl --user get-property org.kde.ScreenBrightness $p $i $1 2>/dev/null | cut -d' ' -f2- | tr -d '\"'; }; echo disp=$d~$(g Label)~$(g Brightness)~$(g MaxBrightness)~$(g IsInternal); done"

    property bool dragging: false

    function parse(out) {
        const lines = out.split("\n");
        const found = [];
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const eq = line.indexOf("=");
            if (eq < 0)
                continue;
            const k = line.substring(0, eq);
            const v = line.substring(eq + 1).trim();
            if (k === "wifi") {
                wifiAvailable = v !== "";
                wifiOn = v === "enabled";
            } else if (k === "bt") {
                btAvailable = v !== "";
                btOn = v.indexOf("yes") >= 0;
            } else if (k === "vol") {
                muteAvailable = v !== "";
                muted = v.indexOf("[MUTED]") >= 0;
                const m = v.match(/([0-9.]+)/);
                if (m !== null && !dragging)
                    volume = Math.round(parseFloat(m[1]) * 100);
            } else if (k === "qs") {
                qsAvailable = v !== "";
                qsOn = v === "on";
            } else if (k === "night") {
                nightAvailable = v.indexOf("true") >= 0;
            } else if (k === "ssid") {
                ssid = v;
            } else if (k === "btdev") {
                btDevice = v;
            } else if (k === "disp") {
                const f = v.split("~");
                const max = parseInt(f[3]) || 1;
                found.push({ id: f[0], label: f[1] || f[0], value: Math.round((parseInt(f[2]) || 0) * 100 / max),
                             max: max, internal: f[4] === "true" });
            }
        }
        // Keep a display mid-drag as the user left it.
        if (!dragging || found.length !== displays.length)
            displays = found;
        if (displayIndex >= displays.length)
            displayIndex = 0;
        clock = new Date();
    }

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            const out = data["stdout"] || "";
            if (sourceName === src.pollCmd)
                src.parse(out);
            else if (sourceName === src.networksCmd)
                src.parseNetworks(out);
            else if (sourceName === src.devicesCmd)
                src.parseDevices(out);
            else if (sourceName.indexOf("nmcli dev wifi connect") === 0 || sourceName.indexOf("nmcli con up") === 0)
                src.finishConnect(sourceName, out + (data["stderr"] || ""));
            else if (sourceName.indexOf("nmcli con down") === 0 || sourceName.indexOf("nmcli con delete") === 0)
                src.finishManage(out + (data["stderr"] || ""));
        }
    }

    function run(cmd) {
        exec.disconnectSource(cmd);
        exec.connectSource(cmd);
    }

    Timer {
        interval: 5000
        repeat: true
        triggeredOnStart: true
        running: src.active
        onTriggered: src.run(src.pollCmd)
    }

    // One-shot re-read shortly after a change, so the tile catches up fast.
    Timer {
        id: refresh
        onTriggered: src.run(src.pollCmd)
    }

    function schedulePoll(ms) {
        refresh.interval = ms;
        refresh.restart();
    }

    NotificationManager.Settings {
        id: notif
        live: src.active
    }

    readonly property bool dndOn: active && ((notif.notificationsInhibitedUntil > clock) || notif.notificationsInhibitedByApplication)
    readonly property bool nightOn: active && nightAvailable && !Brightness.NightLightInhibitor.inhibited

    function toggle(key) {
        if (key === "wifi") {
            run("nmcli radio wifi " + (wifiOn ? "off" : "on"));
            wifiOn = !wifiOn;
            schedulePoll(800);
        } else if (key === "bluetooth") {
            run(btOn ? "bluetoothctl power off" : "rfkill unblock bluetooth; sleep 1; bluetoothctl power on");
            btOn = !btOn;
            schedulePoll(1500);
        } else if (key === "mute") {
            run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle");
            muted = !muted;
            schedulePoll(800);
        } else if (key === "quickshare") {
            // On opens the app so this device can be found; off quits it.
            run(qsOn ? "pkill -x rquickshare" : "(rquickshare >/dev/null 2>&1 &)");
            qsOn = !qsOn;
            schedulePoll(1500);
        } else if (key === "dnd") {
            if (dndOn) {
                notif.notificationsInhibitedUntil = undefined;
                notif.revokeApplicationInhibitions();
            } else {
                const d = new Date();
                d.setFullYear(d.getFullYear() + 1);
                notif.notificationsInhibitedUntil = d;
            }
            notif.save();
            clock = new Date();
        } else if (key === "nightlight") {
            if (nightAvailable)
                Brightness.NightLightInhibitor.toggleInhibition();
        }
    }

    function itemFor(k) {
        if (k === "wifi")
            return { key: k, label: "Wi-Fi", icon: wifiOn ? "wifi" : "wifi-off", on: wifiOn, available: wifiAvailable, detail: true };
        if (k === "bluetooth")
            return { key: k, label: "Bluetooth", icon: btOn ? "bluetooth" : "bluetooth-off", on: btOn, available: btAvailable, detail: true };
        if (k === "dnd")
            return { key: k, label: "Do Not Disturb", icon: "moon-dnd", on: dndOn, available: active };
        if (k === "nightlight")
            return { key: k, label: "Night Light", icon: "night-light", on: nightOn, available: nightAvailable };
        if (k === "quickshare")
            return { key: k, label: "Quick Share", icon: "share", on: qsOn, available: qsAvailable };
        if (k === "mute")
            return { key: k, label: "Mute", icon: muted ? "speaker-muted" : "speaker", on: muted, available: muteAvailable };
        return null;
    }

    readonly property var items: keys.map(k => itemFor(k)).filter(i => i !== null)
    // The four toggles the flyout and the status strip always show.
    readonly property var stripItems: ["wifi", "bluetooth", "dnd", "nightlight"].map(k => itemFor(k))

    // ---- volume and brightness ----

    function setVolume(v) {
        volume = v;
        muted = false;
        run("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.round(v) + "%");
    }

    function setBrightness(v) {
        const d = displays[displayIndex];
        if (!d)
            return;
        const next = displays.slice();
        next[displayIndex] = Object.assign({}, d, { value: v });
        displays = next;
        run("busctl --user call org.kde.ScreenBrightness /org/kde/ScreenBrightness/" + d.id
            + " org.kde.ScreenBrightness.Display SetBrightness iu " + Math.round(v * d.max / 100) + " 0");
    }

    // ---- Wi-Fi networks ----

    readonly property string networksCmd: "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null; echo '@@known'; nmcli -t -f NAME,TYPE con show 2>/dev/null | grep ':802-11-wireless' | cut -d: -f1"

    function scanNetworks() {
        scanning = true;
        netStatus = "";
        run(networksCmd);
    }

    function parseNetworks(out) {
        const parts = out.split("@@known");
        const known = (parts[1] || "").split("\n").map(l => l.trim()).filter(l => l !== "");
        const seen = {};
        const list = [];
        for (const line of parts[0].split("\n")) {
            if (line.trim() === "")
                continue;
            // nmcli escapes ":" inside fields as "\:".
            const f = line.replace(/\\:/g, "\u0001").split(":").map(x => x.replace(/\u0001/g, ":"));
            const name = f[1];
            if (!name || seen[name])
                continue;
            seen[name] = true;
            list.push({ ssid: name, signal: parseInt(f[2]) || 0, secure: (f[3] || "") !== "" && f[3] !== "--",
                        known: known.indexOf(name) >= 0, active: f[0] === "*" });
        }
        list.sort((a, b) => (b.active - a.active) || (b.known - a.known) || (b.signal - a.signal));
        networks = list;
        scanning = false;
    }

    function quote(t) {
        return "'" + String(t).replace(/'/g, "'\\''") + "'";
    }

    // Saved network: bring it up. New one: connect with the password.
    function connectNetwork(name, password) {
        netStatus = i18nc("Wi-Fi connect status", "Connecting…");
        if (password === undefined)
            run("nmcli con up id " + quote(name) + " 2>&1");
        else
            run("nmcli dev wifi connect " + quote(name) + " password " + quote(password) + " 2>&1");
    }

    function disconnectNetwork(name) {
        netStatus = i18nc("Wi-Fi connect status", "Disconnecting…");
        run("nmcli con down id " + quote(name) + " 2>&1");
    }

    // Drop the saved profile (and its password).
    function forgetNetwork(name) {
        netStatus = "";
        run("nmcli con delete id " + quote(name) + " 2>&1");
    }

    function finishManage(out) {
        netStatus = out.indexOf("successfully") >= 0 ? "" : i18nc("Wi-Fi connect status", "Could not change network");
        scanNetworks();
        schedulePoll(1500);
    }

    function finishConnect(cmd, out) {
        const ok = out.indexOf("successfully") >= 0;
        netStatus = ok ? "" : (out.indexOf("Secrets were required") >= 0 || out.indexOf("password") >= 0
            ? i18nc("Wi-Fi connect status", "Wrong password") : i18nc("Wi-Fi connect status", "Could not connect"));
        scanNetworks();
        schedulePoll(1500);
    }

    // ---- Bluetooth devices ----

    readonly property string devicesCmd: "for m in $(bluetoothctl devices Paired 2>/dev/null | cut -d' ' -f2); do echo \"dev=$m|$(bluetoothctl info $m 2>/dev/null | grep -E 'Name:|Connected:|Icon:|Battery Percentage' | tr '\\n' ';')\"; done"

    function scanDevices() {
        scanning = true;
        run(devicesCmd);
    }

    function parseDevices(out) {
        const list = [];
        for (const line of out.split("\n")) {
            if (line.indexOf("dev=") !== 0)
                continue;
            const bar = line.indexOf("|");
            const mac = line.substring(4, bar);
            const info = line.substring(bar + 1);
            const pick = re => { const m = info.match(re); return m ? m[1].trim() : ""; };
            const bat = info.match(/\((\d+)\)/);
            list.push({ mac: mac, name: pick(/Name:\s*([^;]*)/) || mac, icon: pick(/Icon:\s*([^;]*)/),
                        connected: pick(/Connected:\s*([^;]*)/) === "yes", battery: bat ? parseInt(bat[1]) : -1 });
        }
        list.sort((a, b) => b.connected - a.connected);
        devices = list;
        scanning = false;
    }

    function toggleDevice(mac, connected) {
        run("bluetoothctl " + (connected ? "disconnect " : "connect ") + mac);
        devices = devices.map(d => d.mac === mac ? Object.assign({}, d, { connected: !connected }) : d);
        schedulePoll(2500);
    }
}
