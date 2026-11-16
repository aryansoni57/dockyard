import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import ".."

Sheet {
    id: pg
    title: "Bluetooth"
    subtitle: !on ? "Off" : connectedCount ? connectedCount + " device" + (connectedCount > 1 ? "s" : "") + " connected" : "On, nothing connected"
    iconName: "bluetooth"
    Exec { id: sh }
    property bool on: false
    property var devices: []
    property bool loaded: false
    property string busy: ""
    property var nearby: []
    property bool scanning: false
    property bool scanned: false
    readonly property int connectedCount: devices.filter(d => d.connected).length
    function glyph(kind) {
        if (/audio|head/.test(kind)) return "headphones";
        if (/keyboard/.test(kind)) return "keyboard";
        if (/mouse|tablet/.test(kind)) return "mouse";
        if (/phone/.test(kind)) return "phone";
        if (/computer/.test(kind)) return "display";
        return "bluetooth";
    }
    function load() {
        sh.run("bluetoothctl show", (o) => on = /Powered: yes/.test(o));
        sh.run("bluetoothctl devices Paired", (o) => {
            const list = o.split("\n").map(l => l.match(/^Device\s+(\S+)\s+(.*)$/)).filter(m => m).map(m => ({ mac: m[1], name: m[2], connected: false, kind: "", battery: -1 }));
            devices = list;
            loaded = true;
            list.forEach((d, i) => sh.run("bluetoothctl info " + d.mac, (info) => {
                const copy = devices.slice();
                if (copy[i]) copy[i] = Object.assign({}, copy[i], {
                    connected: /Connected: yes/.test(info),
                    kind: ((info.match(/Icon:\s*(\S+)/) || [0, ""])[1]),
                    battery: parseInt((info.match(/Battery Percentage:.*\((\d+)\)/) || [0, "-1"])[1])
                });
                devices = copy;
            }));
        });
    }
    Component.onCompleted: load()
    Timer { id: later; interval: 1500; onTriggered: { pg.busy = ""; pg.load(); } }

    // Scan for 8 s, then list devices that are not paired yet.
    function scan() {
        scanning = true;
        sh.run("bluetoothctl --timeout 8 scan on >/dev/null 2>&1; bluetoothctl devices", (o) => {
            const paired = devices.map(d => d.mac);
            const list = o.split("\n").map(l => l.match(/^Device\s+(\S+)\s+(.*)$/)).filter(m => m && paired.indexOf(m[1]) < 0 && m[2].replace(/-/g, ":") !== m[1])
                .map(m => ({ mac: m[1], name: m[2] }));
            nearby = list;
            scanning = false;
            scanned = true;
        });
    }
    function pair(d) {
        busy = d.mac;
        sh.run("bluetoothctl pair " + d.mac + " && bluetoothctl trust " + d.mac + " && bluetoothctl connect " + d.mac, (o, e, code) => {
            pg.toast(code === 0 ? "Paired with " + d.name : "Could not pair with " + d.name + " (put it in pairing mode and try again)", code === 0 ? "bluetooth" : "alert");
            nearby = nearby.filter(x => x.mac !== d.mac);
            later.restart();
        });
    }
    function forget(d) {
        sh.run("bluetoothctl remove " + d.mac, (o, e, code) => { pg.toast(code === 0 ? "Removed " + d.name : "Could not remove " + d.name, code === 0 ? "check" : "alert"); later.restart(); });
    }

    actions: [
        Btn { text: pg.scanning ? "Scanning…" : "Scan for devices"; iconName: "refresh"; quiet: true; enabled: pg.on && !pg.scanning; onClicked: pg.scan() },
        Btn { text: "Advanced"; quiet: true; onClicked: pg.openKcm("kcm_bluetooth") }
    ]

    Card {
        SettingRow {
            iconName: "bluetooth"
            iconTone: pg.on ? "accent" : "neutral"
            label: "Bluetooth"
            caption: pg.on ? "Visible to paired devices" : "Turn on to use headphones, mice and keyboards"
            last: true
            Toggle { checked: pg.on; Accessible.name: "Bluetooth"; onToggled: sh.run("bluetoothctl power " + (checked ? "on" : "off"), () => later.restart()) }
        }
    }

    Card {
        title: "Paired devices"
        Repeater {
            model: pg.devices
            delegate: SettingRow {
                id: dr
                required property var modelData
                required property int index
                iconName: pg.glyph(modelData.kind)
                iconTone: modelData.connected ? "solid" : "neutral"
                label: modelData.name
                caption: (modelData.connected ? "Connected" : "Not connected") + (modelData.battery >= 0 ? "  ·  Battery " + modelData.battery + "%" : "")
                last: index === pg.devices.length - 1
                hoverEnabled: true
                Btn { text: "Forget"; small: true; quiet: true; enabled: pg.busy === ""; onClicked: pg.forget(dr.modelData) }
                Btn {
                    small: true
                    primary: !dr.modelData.connected && dr.hovered
                    enabled: pg.on && pg.busy === ""
                    text: pg.busy === dr.modelData.mac ? "Working…" : dr.modelData.connected ? "Disconnect" : "Connect"
                    onClicked: {
                        pg.busy = dr.modelData.mac;
                        sh.run("bluetoothctl " + (dr.modelData.connected ? "disconnect " : "connect ") + dr.modelData.mac, (o, e, code) => {
                            pg.toast((code === 0 ? (dr.modelData.connected ? "Disconnected " : "Connected ") : "Could not reach ") + dr.modelData.name, code === 0 ? "bluetooth" : "alert");
                            later.restart();
                        });
                    }
                }
            }
        }
        Item {
            visible: !pg.loaded
            Layout.fillWidth: true
            implicitHeight: 2 * 58
            Column {
                anchors { fill: parent; margins: Theme.s4 + 2 }
                spacing: 22
                Repeater { model: 2; Row { spacing: 14; Skeleton { width: 34; height: 34; radius: 10 } Column { spacing: 8; anchors.verticalCenter: parent.verticalCenter; Skeleton { width: 150; height: 10 } Skeleton { width: 90; height: 8 } } } }
            }
        }
        EmptyState {
            visible: pg.loaded && pg.devices.length === 0
            Layout.fillWidth: true
            Layout.margins: Theme.s6
            iconName: "pair"
            title: "No paired devices"
            body: "Put your device in pairing mode, then choose Scan for devices."
        }
    }

    Card {
        visible: pg.on && (pg.scanning || pg.scanned)
        title: "Nearby devices"
        description: pg.scanning ? "Scanning for 8 seconds…" : (pg.nearby.length ? pg.nearby.length + " found" : "")
        Repeater {
            model: pg.nearby
            delegate: SettingRow {
                id: nb
                required property var modelData
                required property int index
                iconName: "bluetooth"
                label: modelData.name
                caption: modelData.mac
                last: index === pg.nearby.length - 1
                hoverEnabled: true
                Btn { text: pg.busy === nb.modelData.mac ? "Pairing…" : "Pair"; small: true; primary: nb.hovered; enabled: pg.busy === ""; onClicked: pg.pair(nb.modelData) }
            }
        }
        EmptyState {
            visible: pg.scanned && !pg.scanning && pg.nearby.length === 0
            Layout.fillWidth: true
            Layout.margins: Theme.s6
            iconName: "pair"
            title: "Nothing new nearby"
            body: "Make sure the device is in pairing mode, then scan again."
        }
    }
}
