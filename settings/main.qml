import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import dev.dockyard.kcmhost

// Dockyard Settings. Two planes: a glass rail (navigation, on KWin blur) and a solid deck (content).
QQC2.ApplicationWindow {
    id: root
    title: "Dockyard Settings"
    visible: true
    width: 1180
    height: 780
    minimumWidth: 720
    minimumHeight: 520
    color: "transparent"
    // Our own title bar: KWin's window decoration cannot be blurred, so draw it inside the blurred area.
    flags: Qt.Window | Qt.FramelessWindowHint
    readonly property int titleH: 38

    // The rail collapses to icons when the user asks for it or the window gets narrow.
    readonly property bool narrowWin: width < 940
    readonly property bool compact: Theme.store.rail || narrowWin
    // Quick pages we built ourselves; every other System Settings category follows below them.
    readonly property var sections: [
        { name: "Appearance", icon: "appearance", page: "Appearance", blurb: "Mode, accent and global theme" },
        { name: "Display", icon: "display", page: "Display", blurb: "Monitors, scale and brightness" },
        { name: "Sound", icon: "sound", page: "Sound", blurb: "Output, volume and microphone" },
        { name: "Network", icon: "network", page: "Network", blurb: "Wi-Fi and connections" },
        { name: "Bluetooth", icon: "bluetooth", page: "Bluetooth", blurb: "Paired devices" },
        { name: "Power", icon: "power", page: "Power", blurb: "Profiles, battery and sleep" }
    ]
    // Line icons for the System Settings categories, so the rail reads as one set.
    readonly property var groupIcons: ({
        "input-devices": "input-devices", "hardware": "hardware", "network": "globe", "appearance": "brush",
        "applications": "windows", "workspace": "workspace", "security-privacy": "shield", "regionalsettings": "clock",
        "system-administration": "cpu", "personalization": "user", "info": "info", "other": "dots"
    })
    function groupIcon(id) { return groupIcons[id] || "dots"; }

    KcmModel { id: kcms }
    Status { id: sys; active: root.active }
    readonly property alias kcmModel: kcms
    readonly property var groups: kcms.groups
    // Words the search matches on our quick pages (KDE modules are searched through KcmModel).
    readonly property var index: [
        [0, "Theme", "global theme look and feel dockyard breeze night day"], [0, "Accent colour", "accent color highlight"], [0, "Night, day or auto", "dark light mode"],
        [1, "Resolution and refresh", "mode monitor screen hz"], [1, "Scale", "dpi zoom hidpi"], [1, "Rotation", "orientation portrait"], [1, "Brightness", "backlight"],
        [2, "Output device", "speakers headphones"], [2, "Volume", "mute loudness"], [2, "Microphone", "input mic"],
        [3, "Wi-Fi", "wireless wlan connect"], [3, "Networks", "ssid password"],
        [4, "Bluetooth", "pair devices headphones"],
        [5, "Power profile", "battery performance saver balanced"]
    ]

    // ---- Routing ----
    property string viewKind: "home"
    property int viewIndex: -1
    property string viewGroup: ""
    property string viewKcm: ""
    property string viewKey: "home"
    property var pending: null
    property var history: []
    property bool goingBack: false

    // Applies a page, then runs fn once the module has finished saving (a KAuth save is asynchronous), or after 6 s.
    function applyThen(pg, fn) {
        pg.apply();
        let n = 0;
        const t = Qt.createQmlObject('import QtQuick; Timer { interval: 200; repeat: true; running: true }', root);
        t.triggered.connect(() => {
            n += 1;
            if (!pg.dirty || n >= 30) { t.stop(); t.destroy(); if (fn) fn(); }
        });
    }
    function dirtyPage() { return loader.item && loader.item.dirty === true ? loader.item : null; }
    // Runs fn now, or after the user decides what to do with unsaved changes.
    function guard(fn) {
        if (dirtyPage()) { pending = fn; leaveDialog.open(); } else fn();
    }
    function routeOf() { return { kind: viewKind, arg: viewKind === "native" ? viewIndex : viewKind === "group" ? viewGroup : viewKcm }; }
    function go(kind, a, margs) {
        // Same module already open: hand it the new arguments instead of reloading it.
        if (kind === "kcm" && margs && margs.length && viewKind === "kcm" && viewKcm === a && loader.item && loader.item.activate) {
            loader.item.activate(margs);
            return;
        }
        guard(() => {
            if (!goingBack && viewKey !== "") { const h = history.slice(-20); h.push(routeOf()); history = h; }
            goingBack = false;
            searchPal.close();
            viewKind = kind;
            const ctx = { app: root, sys: sys };
            if (kind === "home") {
                viewKey = "home"; viewIndex = -1;
                loader.setSource(Qt.resolvedUrl("pages/Home.qml"), ctx);
            } else if (kind === "native") {
                viewIndex = a; viewKey = "native:" + a;
                loader.setSource(Qt.resolvedUrl("pages/" + sections[a].page + ".qml"), ctx);
                remember({ k: "native", page: a, label: sections[a].name, sub: "Quick settings", icon: sections[a].icon });
            } else if (kind === "group") {
                viewGroup = a; viewKey = "group:" + a;
                const g = groups.find(x => x.id === a);
                loader.setSource(Qt.resolvedUrl("pages/Group.qml"), Object.assign(ctx, { groupId: a, groupName: g ? g.name : a, iconName: groupIcon(a) }));
            } else {
                viewKcm = a;
                const m = kcms.info(a);
                if (m.group) { viewGroup = m.group; viewKey = "group:" + m.group; } else viewKey = "kcm:" + a;
                loader.setSource(Qt.resolvedUrl("pages/Kcm.qml"), Object.assign(ctx, { moduleId: a, moduleArgs: margs || [], title: m.name || a, backLabel: m.groupName || "", moduleIcon: m.icon || "", subName: m.subName || "", comment: m.comment || "" }));
                if (m.name) remember({ k: "kcm", id: a, label: m.name, sub: m.groupName, icon: m.icon });
            }
        });
    }
    function goBack() {
        // Inside a module's own sub-page: go up one level first.
        if (loader.item && loader.item.up && loader.item.up()) return;
        if (!history.length) return;
        const h = history.slice(); const r = h.pop(); history = h;
        goingBack = true;
        go(r.kind, r.arg);
        goingBack = false;
    }
    function openKcm(id, margs) { go("kcm", id, margs); }
    function search(q) { searchPal.openWith(q || ""); }
    function show(i) { go("native", i); }

    // Recently opened pages and modules, newest first, persisted.
    readonly property var recent: { try { return JSON.parse(Theme.store.recent); } catch (e) { return []; } }
    function remember(e) {
        const key = x => x.k === "kcm" ? "k:" + x.id : "n:" + x.page;
        const list = recent.filter(x => key(x) !== key(e));
        list.unshift(e);
        Theme.store.recent = JSON.stringify(list.slice(0, 8));
    }

    function statusOf(i) {
        switch (i) {
        case 0: return Theme.mode === "auto" ? "Auto" : Theme.dark ? "Night" : "Day";
        case 1: return sys.outputs.length > 1 ? sys.outputs.length + " screens" : (sys.displayLine.split(" · ")[0] || "").replace(" × ", "×");
        case 2: return sys.muted ? "Muted" : Math.round(sys.volume * 100) + "%";
        case 3: return sys.wired ? "Wired" : !sys.wifiOn ? "Off" : (sys.ssid || "On");
        case 4: return !sys.btOn ? "Off" : sys.btConnected ? sys.btConnected + " on" : "On";
        case 5: return sys.battery >= 0 && sys.batteryState === "Discharging" ? sys.battery + "%" : (sys.profileNames[sys.profile] || "");
        }
        return "";
    }

    function toast(text, icon) { toaster.show(text, icon || "check"); }

    function syncScheme() {
        kcms.applyScheme({ paper: Theme.deck, paperAlt: Theme.card, ink: Theme.ink, ink2: Theme.ink2, field: Theme.well,
                           accent: Theme.accent, accentInk: Theme.accentInk, bad: Theme.bad, ok: Theme.ok, neutral: Theme.neutral });
    }
    Connections { target: Theme; function onDarkChanged() { root.syncScheme(); } function onAccentChanged() { root.syncScheme(); } }
    Component.onCompleted: {
        syncScheme();
        kcms.setBlur(root, true);
        kcms.watchBackButton();
        const args = Qt.application.arguments.slice(1);
        const c = args.find(x => /^cmd:/.test(x));
        if (c) { cmdFile = c.slice(4); cmdPoll.start(); }
        handleArgs(args);
        history = [];
    }
    // Deep links: kcm_<id>, a quick page name (sound), group:<id>, or search:<text>.
    function handleArgs(raw) {
        // systemsettings:kcm_x links (plasma-open-settings) arrive as a URL; a bare module name gets its kcm_ prefix.
        const args = raw.map(x => { if (!/^systemsettings:/.test(x)) return x; const n = x.replace(/^systemsettings:\/*/, ""); return kcms.indexOfId("kcm_" + n) >= 0 ? "kcm_" + n : n; });
        const a = args.find(x => /^kcm_/.test(x));
        const q = args.find(x => sections.some(s => s.name.toLowerCase() === x.toLowerCase()));
        const g = args.find(x => /^group:/.test(x));
        // Module arguments: `kcm_x arg:foo arg:bar` or System Settings' own `kcm_x --args foo bar`.
        const ai = args.indexOf("--args");
        const margs = args.filter(x => /^arg:/.test(x)).map(x => x.slice(4)).concat(ai >= 0 ? args.slice(ai + 1).filter(x => !/^(cmd|search|group|arg):/.test(x)) : []);
        if (a) openKcm(a, margs);
        else if (q) go("native", sections.findIndex(s => s.name.toLowerCase() === q.toLowerCase()));
        else if (g) go("group", g.slice(6));
        else go("home");
        const sq = args.find(x => /^search:/.test(x));
        if (sq) Qt.callLater(() => search(sq.slice(7)));
    }
    // Single instance: a second launch (dockyard-settings kcm_x) writes its arguments to this file
    // and exits; we poll it, jump to the page and raise the window.
    property string cmdFile: ""
    property string cmdSeen: ""
    Timer {
        id: cmdPoll
        interval: 400
        repeat: true
        onTriggered: {
            const x = new XMLHttpRequest();
            x.open("GET", "file://" + root.cmdFile);
            x.onreadystatechange = () => {
                if (x.readyState !== XMLHttpRequest.DONE) return;
                const line = (x.responseText || "").trim();
                if (line === "" || line === root.cmdSeen) return;
                root.cmdSeen = line;
                root.handleArgs(line.split(/\s+/).slice(1));
                root.show(); root.raise(); root.requestActivate();
            };
            x.send();
        }
    }
    Shortcut { sequences: ["Ctrl+F", "Ctrl+K", "/"]; onActivated: searchPal.openWith("") }
    Shortcut { sequences: ["Alt+Left", "Back"]; onActivated: root.goBack() }
    // Mouse side button = back, wherever the pointer is (also over embedded module windows).
    Connections { target: kcms; function onBackRequested() { root.goBack(); } }
    Shortcut { sequence: "Alt+Home"; onActivated: root.go("home") }
    Shortcut { sequence: "Ctrl+\\"; onActivated: Theme.store.rail = !Theme.store.rail }
    onClosing: (close) => { if (dirtyPage()) { close.accepted = false; pending = () => Qt.quit(); leaveDialog.open(); } }

    // ---- Backdrop: KWin blur, a faint ribbon layer and the glass tint ----
    Wall { anchors.fill: parent; opacity: Theme.dark ? 0.32 : 0.45 }
    Rectangle { anchors.fill: parent; color: Theme.glass; Behavior on color { ColorAnimation { duration: Theme.slow } } }


    // ---- Title bar (blurred glass, drag to move, double-click to maximise) ----
    Item {
        id: titleBar
        z: 500
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: root.titleH
        Rectangle { anchors.fill: parent; color: Theme.dark ? Qt.rgba(0, 0, 0, 0.16) : Qt.rgba(1, 1, 1, 0.30) }
        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Theme.line }
        DragHandler {
            target: null
            acceptedButtons: Qt.LeftButton
            onActiveChanged: if (active) root.startSystemMove()
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton
            onDoubleTapped: root.visibility === Window.Maximized ? root.showNormal() : root.showMaximized()
        }
        QQC2.Label {
            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
            text: root.title
            color: Theme.ink2
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        Row {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            component WinBtn: QQC2.AbstractButton {
                id: wb
                property string kind
                property bool isClose: false
                width: isClose ? 52 : 44
                height: titleBar.height
                focusPolicy: Qt.NoFocus
                Accessible.name: kind
                background: Rectangle { color: wb.isClose ? (wb.down ? "#c43a3f" : wb.hovered ? "#e5484d" : "transparent") : (wb.down ? Theme.press : wb.hovered ? Theme.hover : "transparent") }
                contentItem: Item {
                    Canvas {
                        anchors.centerIn: parent
                        width: 12; height: 12
                        property color c: wb.isClose && wb.hovered ? "#ffffff" : Theme.ink2
                        onCChanged: requestPaint()
                        Component.onCompleted: requestPaint()
                        onPaint: {
                            const g = getContext("2d");
                            g.clearRect(0, 0, 12, 12);
                            g.strokeStyle = c; g.lineWidth = 1.4; g.lineCap = "round"; g.lineJoin = "round";
                            g.beginPath();
                            if (wb.kind === "min") { g.moveTo(1.5, 6); g.lineTo(10.5, 6); }
                            else if (wb.kind === "max") { g.rect(1.5, 1.5, 9, 9); }
                            else if (wb.kind === "restore") { g.rect(1.5, 3.5, 7, 7); g.moveTo(3.5, 3.5); g.lineTo(3.5, 1.5); g.lineTo(10.5, 1.5); g.lineTo(10.5, 8.5); g.lineTo(8.5, 8.5); }
                            else { g.moveTo(1.5, 1.5); g.lineTo(10.5, 10.5); g.moveTo(10.5, 1.5); g.lineTo(1.5, 10.5); }
                            g.stroke();
                        }
                    }
                }
            }
            WinBtn { kind: "min"; onClicked: root.showMinimized() }
            WinBtn { kind: root.visibility === Window.Maximized ? "restore" : "max"; onClicked: root.visibility === Window.Maximized ? root.showNormal() : root.showMaximized() }
            WinBtn { kind: "close"; isClose: true; onClicked: root.close() }
        }
    }

    // ---- Resize edges (a frameless window has none of its own) ----
    component Edge: Item {
        property int edges
        property alias cursor: ma.cursorShape
        MouseArea { id: ma; anchors.fill: parent; acceptedButtons: Qt.NoButton }
        DragHandler { target: null; onActiveChanged: if (active) root.startSystemResize(parent.edges) }
        z: 600
    }
    Edge { anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 6; bottomMargin: 6 } width: 5; edges: Qt.LeftEdge; cursor: Qt.SizeHorCursor; visible: root.visibility !== Window.Maximized }
    Edge { anchors { right: parent.right; top: parent.top; bottom: parent.bottom; topMargin: 6; bottomMargin: 6 } width: 5; edges: Qt.RightEdge; cursor: Qt.SizeHorCursor; visible: root.visibility !== Window.Maximized }
    Edge { anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: 6; rightMargin: 6 } height: 4; edges: Qt.TopEdge; cursor: Qt.SizeVerCursor; visible: root.visibility !== Window.Maximized }
    Edge { anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 6; rightMargin: 6 } height: 5; edges: Qt.BottomEdge; cursor: Qt.SizeVerCursor; visible: root.visibility !== Window.Maximized }
    Edge { anchors { left: parent.left; top: parent.top } width: 8; height: 8; edges: Qt.LeftEdge | Qt.TopEdge; cursor: Qt.SizeFDiagCursor; visible: root.visibility !== Window.Maximized }
    Edge { anchors { right: parent.right; top: parent.top } width: 8; height: 8; edges: Qt.RightEdge | Qt.TopEdge; cursor: Qt.SizeBDiagCursor; visible: root.visibility !== Window.Maximized }
    Edge { anchors { left: parent.left; bottom: parent.bottom } width: 8; height: 8; edges: Qt.LeftEdge | Qt.BottomEdge; cursor: Qt.SizeBDiagCursor; visible: root.visibility !== Window.Maximized }
    Edge { anchors { right: parent.right; bottom: parent.bottom } width: 8; height: 8; edges: Qt.RightEdge | Qt.BottomEdge; cursor: Qt.SizeFDiagCursor; visible: root.visibility !== Window.Maximized }
    // 1 px rim, since there is no frame
    Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Theme.wellRim; z: 700; enabled: false }

    // ---- Rail ----
    component SectionLabel: Item {
        id: sl
        property string text
        width: parent ? parent.width : 0
        height: root.compact ? 17 : 30
        QQC2.Label {
            visible: !root.compact
            anchors { left: parent.left; leftMargin: 12; bottom: parent.bottom; bottomMargin: 6 }
            text: sl.text
            color: Theme.ink3
            font.pixelSize: Theme.fsMicro
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
            font.capitalization: Font.AllUppercase
        }
        Rectangle { visible: root.compact; anchors.centerIn: parent; width: 24; height: 1; color: Theme.line }
    }
    component NavItem: QQC2.AbstractButton {
        id: nb
        property string rowKey
        property string rowIcon
        property string rowText
        property string rowStatus: ""
        readonly property bool isCur: root.viewKey === rowKey
        onIsCurChanged: if (isCur) navCol.cur = nb
        Component.onCompleted: if (isCur) navCol.cur = nb
        width: navCol.width
        height: 38
        focusPolicy: Qt.TabFocus
        Accessible.name: rowText
        background: Rectangle {
            radius: Theme.rCtl
            color: nb.isCur ? "transparent" : (nb.down ? Theme.press : (nb.hovered ? Theme.hover : "transparent"))
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            FocusRing { shown: nb.visualFocus; round: Theme.rCtl; anchors.margins: -1 }
        }
        contentItem: RowLayout {
            spacing: 11
            Item { Layout.fillWidth: root.compact; Layout.preferredWidth: root.compact ? 0 : 3 }
            Ico { name: nb.rowIcon; size: 18; color: nb.isCur ? Theme.accentInk : (nb.hovered ? Theme.ink : Theme.ink2) }
            QQC2.Label {
                visible: !root.compact
                Layout.fillWidth: true
                text: nb.rowText
                elide: Text.ElideRight
                color: nb.isCur || nb.hovered ? Theme.ink : Theme.a(Theme.ink, 0.84)
                font.pixelSize: Theme.fsSmall + 0.5
                font.weight: nb.isCur ? Font.DemiBold : Font.Normal
            }
            QQC2.Label {
                visible: !root.compact && nb.rowStatus !== ""
                Layout.maximumWidth: 92
                text: nb.rowStatus
                elide: Text.ElideRight
                color: nb.isCur ? Theme.ink2 : Theme.ink3
                font.pixelSize: Theme.fsCaption
                font.features: { "tnum": 1 }
            }
            Item { Layout.fillWidth: root.compact; Layout.preferredWidth: root.compact ? 0 : 4 }
        }
        Tip { text: nb.rowText + (nb.rowStatus ? "  ·  " + nb.rowStatus : ""); shown: root.compact && nb.hovered }
    }

    RowLayout {
        anchors { fill: parent; topMargin: root.titleH }
        spacing: 0

        Item {
            id: rail
            Layout.fillHeight: true
            Layout.preferredWidth: root.compact ? 68 : 264
            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: root.compact ? 10 : 8; topMargin: 12; bottomMargin: 12 }
                spacing: 10

                // Brand
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    spacing: 10
                    Item { visible: root.compact; Layout.fillWidth: true }
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.leftMargin: root.compact ? 0 : 4
                        radius: 10
                        gradient: Gradient {
                            GradientStop { position: 0; color: Qt.lighter(Theme.accent, 1.18) }
                            GradientStop { position: 1; color: Theme.accent }
                        }
                        // A tiny dock: three tiles on a bar.
                        Rectangle { x: 7; y: 20; width: 18; height: 5; radius: 2.5; color: Theme.accentFg; opacity: 0.95 }
                        Repeater { model: 3; Rectangle { required property int index; x: 8 + index * 6; y: 12; width: 4; height: 6; radius: 1.5; color: Theme.accentFg; opacity: 0.8 } }
                    }
                    ColumnLayout {
                        visible: !root.compact
                        spacing: 0
                        Layout.fillWidth: true
                        QQC2.Label { text: "Dockyard"; color: Theme.ink3; font.pixelSize: Theme.fsMicro; font.weight: Font.Medium }
                        QQC2.Label { text: "Settings"; color: Theme.ink; font.pixelSize: Theme.fsTitle; font.weight: Font.DemiBold; font.letterSpacing: -0.2 }
                    }
                    IconBtn { visible: !root.compact; iconName: "sidebar"; tip: "Collapse sidebar  (Ctrl+\\)"; onClicked: Theme.store.rail = true }
                    Item { visible: root.compact; Layout.fillWidth: true }
                }

                // Search: opens the palette
                QQC2.AbstractButton {
                    id: searchBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    focusPolicy: Qt.TabFocus
                    Accessible.name: "Search settings"
                    onClicked: searchPal.openWith("")
                    background: Rectangle {
                        radius: Theme.rCtl
                        color: searchBtn.hovered ? Theme.a(Theme.ink, Theme.dark ? 0.09 : 0.07) : Theme.a(Theme.ink, Theme.dark ? 0.06 : 0.05)
                        border.width: 1
                        border.color: Theme.a(Theme.ink, Theme.dark ? 0.07 : 0.08)
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                        FocusRing { shown: searchBtn.visualFocus; round: Theme.rCtl }
                    }
                    contentItem: RowLayout {
                        spacing: 8
                        Item { Layout.fillWidth: root.compact; Layout.preferredWidth: root.compact ? 0 : 3 }
                        Ico { name: "search"; size: 17; color: Theme.ink2 }
                        QQC2.Label { visible: !root.compact; text: "Search"; color: Theme.ink3; font.pixelSize: Theme.fsSmall; Layout.fillWidth: true }
                        Kbd { visible: !root.compact; text: "Ctrl K" }
                        Item { Layout.fillWidth: root.compact; Layout.preferredWidth: root.compact ? 0 : 2 }
                    }
                    Tip { text: "Search  (Ctrl+K)"; shown: root.compact && searchBtn.hovered }
                }

                Flickable {
                    id: navFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 2
                    clip: true
                    contentHeight: navCol.height + 8
                    boundsBehavior: Flickable.StopAtBounds
                    QQC2.ScrollBar.vertical: Scroller {}
                    SmoothWheel { view: navFlick; parent: navFlick }

                    // Selection pill glides between rows.
                    Rectangle {
                        id: pill
                        visible: navCol.cur !== null && navCol.cur.isCur === true
                        width: navCol.width
                        height: 38
                        radius: Theme.rCtl
                        y: navCol.cur ? navCol.cur.y : 0
                        color: Theme.accentSoft
                        Behavior on y { enabled: Theme.motion; NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
                        Rectangle { x: 0; anchors.verticalCenter: parent.verticalCenter; width: 3; height: 16; radius: 1.5; color: Theme.accent; visible: !root.compact }
                    }
                    Column {
                        id: navCol
                        property Item cur: null
                        width: navFlick.width
                        spacing: 2
                        NavItem { rowKey: "home"; rowIcon: "home"; rowText: "Overview"; onClicked: root.go("home") }
                        SectionLabel { text: "Quick settings" }
                        Repeater {
                            model: root.sections
                            delegate: NavItem {
                                required property int index
                                required property var modelData
                                rowKey: "native:" + index
                                rowIcon: modelData.icon
                                rowText: modelData.name
                                rowStatus: root.statusOf(index)
                                onClicked: root.go("native", index)
                            }
                        }
                        SectionLabel { text: "System Settings" }
                        Repeater {
                            model: root.groups
                            delegate: NavItem {
                                required property var modelData
                                rowKey: "group:" + modelData.id
                                rowIcon: root.groupIcon(modelData.id)
                                rowText: modelData.name
                                onClicked: root.go("group", modelData.id)
                            }
                        }
                    }
                }

                // Footer: night / day / auto, and expand when collapsed.
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.line }
                // Follow the system colour scheme and accent; the mode switch below is locked while this is on.
                RowLayout {
                    visible: !root.compact
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    spacing: 10
                    QQC2.Label { text: "Sync with system theme"; color: Theme.ink2; font.pixelSize: Theme.fsSmall; Layout.fillWidth: true; elide: Text.ElideRight }
                    Toggle { checked: Theme.sync; Accessible.name: "Sync with system theme"; onToggled: Theme.setSync(checked) }
                }
                Segmented {
                    visible: !root.compact
                    enabled: !Theme.sync
                    opacity: Theme.sync ? 0.45 : 1
                    Layout.fillWidth: true
                    stretch: true
                    model: [{ t: "Night", i: "moon" }, { t: "Day", i: "sun" }, { t: "Auto", i: "auto" }]
                    currentIndex: ["night", "day", "auto"].indexOf(Theme.mode)
                    onPicked: (i) => Theme.setMode(["night", "day", "auto"][i])
                }
                ColumnLayout {
                    visible: root.compact
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    IconBtn {
                        Layout.alignment: Qt.AlignHCenter
                        box: 40
                        enabled: !Theme.sync
                        iconName: Theme.sync ? "auto" : Theme.mode === "auto" ? "auto" : Theme.mode === "day" ? "sun" : "moon"
                        tip: Theme.sync ? "Following the system theme" : "Mode: " + Theme.mode + " (click to change)"
                        onClicked: Theme.setMode({ night: "day", day: "auto", auto: "night" }[Theme.mode])
                    }
                    IconBtn {
                        visible: !root.narrowWin
                        Layout.alignment: Qt.AlignHCenter
                        box: 40
                        iconName: "sidebar"
                        tip: "Expand sidebar  (Ctrl+\\)"
                        onClicked: Theme.store.rail = false
                    }
                }
            }
        }

        // ---- Deck ----
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Rectangle {
                id: deck
                anchors { fill: parent; topMargin: 8; rightMargin: 8; bottomMargin: 8 }
                radius: Theme.rDeck
                color: Theme.deck
                border.width: 1
                border.color: Theme.deckRim
                Behavior on color { ColorAnimation { duration: Theme.slow } }

                Loader {
                    id: loader
                    anchors.fill: parent
                    anchors.margins: 1
                    clip: true
                    transform: Translate { id: slideIn; y: 0 }
                    onLoaded: if (Theme.motion) enter.restart()
                    ParallelAnimation {
                        id: enter
                        NumberAnimation { target: loader; property: "opacity"; from: 0; to: 1; duration: Theme.dur; easing.type: Easing.OutCubic }
                        NumberAnimation { target: slideIn; property: "y"; from: 10; to: 0; duration: Theme.slow; easing.type: Easing.OutCubic }
                    }
                }
                Connections {
                    target: loader.item
                    ignoreUnknownSignals: true
                    function onOpenKcm(id) { root.openKcm(id); }
                    function onOpenPage(i) { root.go("native", i); }
                    function onOpenGroup(id) { root.go("group", id); }
                    function onBack() { root.go("group", root.viewGroup); }
                    function onToast(text, icon) { root.toast(text, icon); }
                }

                Toast { id: toaster; anchors.horizontalCenter: parent.horizontalCenter; bottomGap: loader.item && loader.item.footerHeight ? loader.item.footerHeight + 12 : 20 }
            }
        }
    }

    SearchPalette { id: searchPal; app: root; kcms: kcms }

    // ---- Unsaved changes ----
    QQC2.Popup {
        id: leaveDialog
        modal: true
        anchors.centerIn: parent
        width: Math.min(420, root.width - 48)
        padding: 24
        closePolicy: QQC2.Popup.CloseOnEscape
        onClosed: if (root.pending) root.pending = null
        QQC2.Overlay.modal: Rectangle { color: Theme.scrim }
        background: Rectangle { radius: Theme.rCard + 2; color: Theme.card; border.width: 1; border.color: Theme.wellRim }
        enter: Transition { ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dur }
            NumberAnimation { property: "scale"; from: Theme.motion ? 0.96 : 1; to: 1; duration: Theme.dur; easing.type: Easing.OutCubic } } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.fast } }
        contentItem: ColumnLayout {
            spacing: 6
            Chip { iconName: "alert"; tone: "accent"; box: 40; Layout.bottomMargin: 10 }
            QQC2.Label { text: "Apply changes to " + (root.dirtyPage() ? root.dirtyPage().title : "this page") + "?"; color: Theme.ink; font.pixelSize: Theme.fsTitle + 1; font.weight: Font.DemiBold; wrapMode: Text.Wrap; Layout.fillWidth: true }
            QQC2.Label { text: "You changed settings on this page that are not applied yet. Apply them, or discard them and continue."; color: Theme.ink2; font.pixelSize: Theme.fsSmall; wrapMode: Text.Wrap; Layout.fillWidth: true }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 18
                spacing: 8
                Btn { text: "Cancel"; quiet: true; onClicked: { root.pending = null; leaveDialog.close(); } }
                Item { Layout.fillWidth: true }
                Btn { text: "Discard"; danger: true; onClicked: { const p = root.pending; root.pending = null; leaveDialog.close(); const pg = root.dirtyPage(); if (pg) pg.discard(); if (p) p(); } }
                Btn { id: applyBtn; text: "Apply"; primary: true; focus: true; onClicked: { const p = root.pending; root.pending = null; leaveDialog.close(); const pg = root.dirtyPage(); if (pg) root.applyThen(pg, p); else if (p) p(); } }
            }
        }
    }
}
