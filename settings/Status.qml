import QtQuick

// Live system readouts for the sidebar and the overview, with the same commands the pages use.
// refresh() polls everything; setters run the command and refresh shortly after.
Item {
    id: st
    property bool active: true

    property bool wifiOn: false
    property string ssid: ""
    property int wifiSignal: 0
    property bool wired: false
    property bool btOn: false
    property int btConnected: 0
    property string btName: ""
    property real volume: 0
    property bool muted: false
    property string sinkName: ""
    property string profile: ""
    property var profiles: []
    property var outputs: []
    property real brightness: -1
    property string displayLine: ""
    property int battery: -1
    property string batteryState: ""

    // About this machine, read once.
    property var about: ({})

    readonly property var profileNames: ({ "power-saver": "Power Saver", "balanced": "Balanced", "performance": "Performance" })

    Exec { id: sh }
    Timer { interval: 10000; repeat: true; running: st.active; onTriggered: st.refresh() }
    Timer { id: soon; interval: 900; onTriggered: st.refresh() }
    Component.onCompleted: { refresh(); readAbout(); }

    function parseVol(o) { return { v: parseFloat((o.match(/Volume:\s*([\d.]+)/) || [0, 0])[1]), m: o.indexOf("MUTED") >= 0 }; }
    function refresh() {
        sh.run("nmcli radio wifi", (o) => wifiOn = o.trim() === "enabled");
        sh.run("nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi list --rescan no", (o) => {
            const l = o.split("\n").find(x => x.indexOf("yes:") === 0);
            if (l) { const p = l.split(":"); ssid = p[1]; wifiSignal = parseInt(p[2]) || 0; } else { ssid = ""; wifiSignal = 0; }
        });
        sh.run("nmcli -t -f TYPE,STATE dev", (o) => wired = /^ethernet:connected$/m.test(o));
        sh.run("bluetoothctl show", (o) => btOn = /Powered: yes/.test(o));
        sh.run("bluetoothctl devices Connected", (o) => {
            const m = o.split("\n").map(l => l.match(/^Device\s+\S+\s+(.*)$/)).filter(x => x);
            btConnected = m.length; btName = m.length ? m[0][1] : "";
        });
        sh.run("wpctl get-volume @DEFAULT_AUDIO_SINK@", (o) => { const p = parseVol(o); volume = p.v; muted = p.m; });
        sh.run("wpctl inspect @DEFAULT_AUDIO_SINK@", (o) => sinkName = ((o.match(/node\.description = "([^"]*)"/) || [0, ""])[1]));
        sh.run("powerprofilesctl get", (o) => profile = o.trim());
        sh.run("powerprofilesctl list", (o) => profiles = (o.match(/^[* ] [a-z][\w-]*:$/gm) || []).map(s => s.replace(/[*:\s]/g, "")).sort((a, b) => ["power-saver", "balanced", "performance"].indexOf(a) - ["power-saver", "balanced", "performance"].indexOf(b)));
        sh.run("kscreen-doctor -j", (o) => {
            try { outputs = JSON.parse(o).outputs.filter(x => x.connected && x.enabled); } catch (e) { outputs = []; }
            const b = outputs.find(x => x.brightness !== undefined);
            brightness = b ? b.brightness : -1;
            const first = outputs[0];
            if (first) {
                const m = (first.modes || []).find(x => x.id === first.currentModeId);
                displayLine = m ? m.size.width + " × " + m.size.height + " · " + Math.round(m.refreshRate) + " Hz" : first.name;
            } else displayLine = "";
        });
        sh.run("cat /sys/class/power_supply/BAT*/capacity /sys/class/power_supply/BAT*/status 2>/dev/null", (o) => {
            const p = o.trim().split("\n");
            battery = p[0] ? parseInt(p[0]) : -1; batteryState = p[1] || "";
        });
    }
    function readAbout() {
        const cmd = "echo host=$(cat /proc/sys/kernel/hostname); . /etc/os-release; echo os=$PRETTY_NAME; echo kernel=$(uname -r);"
            + " echo cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2); echo cores=$(nproc);"
            + " echo mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print t\" \"a}' /proc/meminfo);"
            + " echo disk=$(df -kP / | awk 'NR==2{print $2\" \"$3}'); echo up=$(cut -d. -f1 /proc/uptime);"
            + " echo plasma=$(plasmashell --version 2>/dev/null | awk '{print $2}'); echo user=$(id -un)";
        sh.run(cmd, (o) => {
            const r = {};
            o.split("\n").forEach(l => { const i = l.indexOf("="); if (i > 0) r[l.slice(0, i)] = l.slice(i + 1).trim(); });
            about = r;
        });
    }

    function setWifi(on) { wifiOn = on; sh.run("nmcli radio wifi " + (on ? "on" : "off"), () => soon.restart()); }
    function setBt(on) { btOn = on; sh.run("bluetoothctl power " + (on ? "on" : "off"), () => soon.restart()); }
    function setVolume(v) { volume = v; sh.run("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ " + v.toFixed(2)); }
    function toggleMute() { muted = !muted; sh.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", () => soon.restart()); }
    function setBrightness(v) {
        brightness = v;
        outputs.filter(x => x.brightness !== undefined).forEach(x => sh.run("kscreen-doctor output." + x.name + ".brightness." + Math.round(v * 100)));
    }
    function setProfile(p) { profile = p; sh.run("powerprofilesctl set " + p, () => soon.restart()); }
    function nextProfile() {
        if (!profiles.length) return "";
        const p = profiles[(profiles.indexOf(profile) + 1) % profiles.length];
        setProfile(p);
        return p;
    }
}
