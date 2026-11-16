import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import ".."

Sheet {
    id: pg
    title: "Network"
    subtitle: !wifiOn ? "Wi-Fi is off" : current ? "Connected to " + current.ssid : "Not connected"
    iconName: "network"
    Exec { id: sh }
    property bool wifiOn: false
    property var nets: []
    property bool loaded: false
    property string busy: ""
    property var saved: []
    property var askNet: null
    // Single-quote a value for the shell (an SSID or password may contain a quote).
    function q(v) { return "'" + String(v).replace(/'/g, "'\\''") + "'"; }
    readonly property var current: nets.find(n => n.active) || null
    readonly property var others: nets.filter(n => !n.active)
    function bars(s) { return s > 70 ? "wifi-3" : s > 45 ? "wifi-2" : s > 20 ? "wifi-1" : "wifi-0"; }
    function load() {
        sh.run("nmcli -t -f NAME,TYPE con show", (o) => saved = o.split("\n").filter(l => /:802-11-wireless$/.test(l)).map(l => l.replace(/:802-11-wireless$/, "").replace(/\\:/g, ":")));
        sh.run("nmcli radio wifi", (o) => wifiOn = o.trim() === "enabled");
        sh.run("nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan no", (o) => {
            const seen = {}, list = [];
            o.split("\n").forEach(l => {
                const p = l.split(":");
                if (p.length < 4 || !p[1] || seen[p[1]]) return;
                seen[p[1]] = 1;
                list.push({ active: p[0] === "*", ssid: p[1], signal: parseInt(p[2]), secured: p[3] !== "" });
            });
            nets = list;
            loaded = true;
        });
    }
    // Connect, disconnect, or join with a password. A secured network that is not saved asks for its password first.
    function connect(n, pw, hidden) {
        if (!n.active && n.secured && pw === undefined && saved.indexOf(n.ssid) < 0) { askNet = n; ask.name = n.ssid; ask.askName = false; ask.title = "Join " + n.ssid; ask.message = "This network is secured. Enter its password."; ask.secret = ""; ask.open(); return; }
        busy = n.ssid;
        const cmd = n.active ? "nmcli con down id " + q(n.ssid)
            : "nmcli dev wifi connect " + q(n.ssid) + (pw ? " password " + q(pw) : "") + (hidden ? " hidden yes" : "");
        sh.run(cmd, (o, e, code) => {
            busy = "";
            const msg = (o + e).trim().split("\n").pop();
            pg.toast(code === 0 ? (n.active ? "Disconnected from " + n.ssid : "Connected to " + n.ssid) : (msg || "Could not connect to " + n.ssid), code === 0 ? "check" : "alert");
            load();
        });
    }
    function forget(ssid) {
        sh.run("nmcli con delete id " + q(ssid), (o, e, code) => { pg.toast(code === 0 ? "Forgot " + ssid : ((o + e).trim() || "Could not forget " + ssid), code === 0 ? "check" : "alert"); load(); });
    }
    Ask {
        id: ask
        onAccepted: pg.connect(pg.askNet || { ssid: ask.name, secured: true, active: false }, ask.secret, pg.askNet === null)
    }
    Component.onCompleted: load()
    Timer { id: later; interval: 1500; onTriggered: pg.load() }

    actions: [
        Btn { text: "Hidden network"; iconName: "plus"; quiet: true; enabled: pg.wifiOn; onClicked: { pg.askNet = null; ask.askName = true; ask.nameLabel = "Network name (SSID)"; ask.name = ""; ask.title = "Join a hidden network"; ask.message = "Leave the password empty for an open network."; ask.secret = ""; ask.open(); } },
        Btn { text: "Rescan"; iconName: "refresh"; quiet: true; enabled: pg.wifiOn; onClicked: { sh.run("nmcli dev wifi rescan", () => later.restart()); pg.toast("Scanning for networks", "refresh"); } }
    ]

    // ---- Wi-Fi master switch and the current connection ----
    Card {
        SettingRow {
            iconName: pg.wifiOn ? "network" : "wifi-off"
            iconTone: pg.wifiOn ? "accent" : "neutral"
            label: "Wi-Fi"
            caption: pg.wifiOn ? "Find and join wireless networks" : "Turn on to see networks nearby"
            last: !pg.wifiOn || !pg.current
            Toggle { checked: pg.wifiOn; Accessible.name: "Wi-Fi"; onToggled: sh.run("nmcli radio wifi " + (checked ? "on" : "off"), () => later.restart()) }
        }
        SettingRow {
            visible: pg.wifiOn && pg.current !== null
            iconName: pg.current ? pg.bars(pg.current.signal) : "network"
            iconTone: "solid"
            label: pg.current ? pg.current.ssid : ""
            caption: pg.current ? "Connected  ·  " + pg.current.signal + "% signal  ·  " + (pg.current.secured ? "Secured" : "Open") : ""
            last: true
            Btn { text: pg.busy !== "" && pg.current && pg.busy === pg.current.ssid ? "Working…" : "Disconnect"; small: true; onClicked: pg.connect(pg.current) }
        }
    }

    // ---- Other networks ----
    Card {
        visible: pg.wifiOn
        title: "Networks nearby"
        description: pg.others.length ? pg.others.length + " found" : ""
        Repeater {
            model: pg.others
            delegate: SettingRow {
                id: nr
                required property var modelData
                required property int index
                iconName: pg.bars(modelData.signal)
                label: modelData.ssid
                caption: modelData.signal + "% signal  ·  " + (modelData.secured ? "Secured" : "Open")
                last: index === pg.others.length - 1
                Ico { visible: nr.modelData.secured; name: "lock"; size: 15; color: Theme.ink3 }
                Btn { visible: pg.saved.indexOf(nr.modelData.ssid) >= 0; text: "Forget"; small: true; quiet: true; enabled: pg.busy === ""; onClicked: pg.forget(nr.modelData.ssid) }
                Btn {
                    text: pg.busy === nr.modelData.ssid ? "Connecting…" : "Connect"
                    small: true
                    primary: nr.hovered || pg.busy === nr.modelData.ssid
                    enabled: pg.busy === ""
                    onClicked: pg.connect(nr.modelData)
                }
                hoverEnabled: true
            }
        }
        Item {
            visible: !pg.loaded
            Layout.fillWidth: true
            implicitHeight: 3 * 58
            Column {
                anchors { fill: parent; margins: Theme.s4 + 2 }
                spacing: 22
                Repeater { model: 3; Row { spacing: 14; Skeleton { width: 34; height: 34; radius: 10 } Column { spacing: 8; anchors.verticalCenter: parent.verticalCenter; Skeleton { width: 160; height: 10 } Skeleton { width: 100; height: 8 } } } }
            }
        }
        EmptyState {
            visible: pg.loaded && pg.others.length === 0
            Layout.fillWidth: true
            Layout.margins: Theme.s6
            iconName: "wifi-0"
            title: "No other networks"
            body: "Nothing else is in range right now. Try Rescan."
        }
    }

    EmptyState {
        visible: !pg.wifiOn && pg.loaded
        Layout.fillWidth: true
        Layout.topMargin: Theme.s6
        iconName: "wifi-off"
        title: "Wi-Fi is off"
        body: "Wired and VPN connections are managed in Advanced connections."
    }

    Card {
        title: "More"
        SettingRow { iconName: "globe"; label: "Advanced connections"; caption: "Wired, VPN, hotspot, proxy settings and saved networks"; clickable: true; last: true; onClicked: pg.openKcm("kcm_networkmanagement") }
    }
}
