pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker
import org.kde.plasma.private.sessions as Sessions
import org.kde.kirigami as Kirigami
import "../components"
import "../components/motion.js" as Motion

// Dashboard start panel, after the AvdanOS home dashboard: weather, today's agenda and
// device batteries across the top, your pinned apps on the left, "Pick up where you left
// off" on the right (the track you were playing and the files you used last), and a
// footer with you, settings, all apps, power, and disk space. Shown instead of the
// Lumen launcher when `startStyle` is "dashboard". "All apps" opens the Lumen launcher.
Item {
    id: panel

    // The PlasmoidItem.
    property var applet
    signal closeRequested()
    signal classicRequested(string query)

    focus: true
    onVisibleChanged: if (visible) forceActiveFocus()

    // Typing anywhere jumps to the launcher and starts searching.
    Keys.onPressed: event => {
        if (event.text.length > 0 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            panel.classicRequested(event.text);
            event.accepted = true;
        }
    }

    readonly property var cfg: Plasmoid.configuration
    readonly property color accent: applet ? applet.accent : Kirigami.Theme.highlightColor
    readonly property var weather: applet.weatherSource
    readonly property var favList: cfg.launcherFavorites.split(",").map(s => s.trim()).filter(s => s !== "")
    // The design (docs/mockups/dockyard-dashboard.html) is in pixels at 18 px per grid unit;
    // px() scales it with the user's font size and display scale.
    readonly property real gu: Kirigami.Units.gridUnit
    function px(n) {
        return Math.round(n * gu / 18);
    }
    readonly property bool darkTheme: Kirigami.Theme.textColor.hslLightness > 0.5
    readonly property real secondary: 0.62
    readonly property color hairline: Qt.alpha(Kirigami.Theme.textColor, darkTheme ? 0.11 : 0.08)
    readonly property color fill: Qt.alpha(Kirigami.Theme.textColor, darkTheme ? 0.055 : 0.04)
    readonly property color btnFill: Qt.alpha(Kirigami.Theme.textColor, darkTheme ? 0.08 : 0.05)
    readonly property color btnFillHover: Qt.alpha(Kirigami.Theme.textColor, darkTheme ? 0.14 : 0.09)
    readonly property color trackColor: Qt.alpha(Kirigami.Theme.textColor, darkTheme ? 0.14 : 0.1)
    readonly property color good: darkTheme ? "#30d158" : "#28a745"
    readonly property color low: darkTheme ? "#ff453a" : "#e0352b"
    readonly property var dotColors: [panel.accent, "#bf5af2", "#ff9f0a"]

    implicitWidth: px(1040)
    implicitHeight: body.implicitHeight

    // ---- data ----
    Kicker.SimpleFavoritesModel {
        id: favs
        favorites: panel.favList
    }
    Kicker.RecentUsageModel {
        id: recent
        shownItems: Kicker.RecentUsageModel.OnlyDocs
    }
    Sessions.SessionManagement {
        id: sm
    }

    property string userName: ""
    property string realName: ""
    ShellRunner {
        id: userRunner
        onFinished: (cmd, out) => {
            const lines = out.split("\n");
            panel.realName = (lines[0] || "").trim();
            panel.userName = (lines[1] || "").trim();
        }
    }

    // [{kind, name, percent, charging}]: this machine's battery, then devices.sh's list.
    property var devices: []
    ShellRunner {
        id: devicesRunner
        onFinished: (cmd, out) => {
            const list = [];
            if (panel.applet.hasBattery)
                list.push({ kind: "laptop", name: i18n("This computer"), percent: Math.round(panel.applet.batteryPercent), charging: panel.applet.batteryCharging });
            for (const line of out.split("\n")) {
                const f = line.split("\t");
                if (f.length >= 4)
                    list.push({ kind: f[0], name: f[1], percent: parseInt(f[2], 10), charging: f[3] === "1" });
            }
            panel.devices = list.slice(0, 3);
        }
    }
    function iconForKind(kind) {
        switch (kind) {
        case "laptop": return "computer-laptop-symbolic";
        case "mouse": return "input-mouse-symbolic";
        case "keyboard": return "input-keyboard-symbolic";
        case "headset": case "headphones": return "audio-headset-symbolic";
        case "gaming-input": return "input-gamepad-symbolic";
        case "phone": case "smartphone": return "smartphone-symbolic";
        case "tablet": return "tablet-symbolic";
        default: return "battery-symbolic";
        }
    }

    // Today's items from scripts/next-event.py: [{title, start, end, allDay, kind}].
    property var agenda: []
    property string agendaState: "idle" // idle | none | ok | error
    readonly property bool calendarSet: cfg.calendarSource.trim() !== ""
        || (cfg.planeWorkspace.trim() !== "" && cfg.planeApiKey.trim() !== "")
    ShellRunner {
        id: agendaRunner
        onFinished: (cmd, out) => {
            try {
                const r = JSON.parse(out);
                if (r.ok !== true) {
                    panel.agendaState = "error";
                    return;
                }
                panel.agenda = (r.items || []).map(i => ({ title: i.title, allDay: i.allDay, start: new Date(i.start), end: new Date(i.end) }));
                panel.agendaState = "ok";
            } catch (e) {
                panel.agendaState = "error";
            }
        }
    }

    // When each recent file was used: {path: epoch seconds}.
    property var recentTimes: ({})
    ShellRunner {
        id: timesRunner
        onFinished: (cmd, out) => {
            const map = {};
            for (const line of out.split("\n")) {
                const i = line.indexOf("\t");
                if (i > 0)
                    map[line.slice(i + 1)] = parseInt(line.slice(0, i), 10);
            }
            panel.recentTimes = map;
        }
    }
    function agoText(epoch) {
        if (!epoch)
            return "";
        const secs = Math.max(0, Date.now() / 1000 - epoch);
        if (secs < 60)
            return i18n("just now");
        if (secs < 3600)
            return i18n("%1 min ago", Math.floor(secs / 60));
        if (secs < 86400)
            return i18n("%1h ago", Math.floor(secs / 3600));
        if (secs < 7 * 86400)
            return i18n("%1d ago", Math.floor(secs / 86400));
        return Qt.formatDate(new Date(epoch * 1000), "d MMM");
    }
    function scriptPath(name) {
        return Qt.resolvedUrl("../../scripts/" + name).toString().replace("file://", "");
    }

    Component.onCompleted: {
        userRunner.run("getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1; echo \"$USER\"");
        devicesRunner.run("sh '" + scriptPath("devices.sh") + "'");
        timesRunner.run("sh '" + scriptPath("recent-times.sh") + "'");
        panel.forceActiveFocus();
        if (calendarSet) {
            const arg = JSON.stringify({
                ical: cfg.calendarSource.trim(),
                plane: { url: cfg.planeUrl.trim(), workspace: cfg.planeWorkspace.trim(), key: cfg.planeApiKey.trim() }
            });
            agendaRunner.run("python3 '" + scriptPath("next-event.py") + "' '" + arg.replace(/'/g, "'\\''") + "'");
        }
    }

    // ---- right-click menus ----
    // Pinned app: unpin (the dock's app row follows, as in the launcher).
    property string pinMenuId: ""
    function unpinApp(id) {
        if (id === "")
            return;
        Plasmoid.configuration.launcherFavorites = favList.filter(f => f !== id).join(",");
        const docked = cfg.appLaunchers.split(",").map(s => s.trim()).filter(s => s !== "");
        Plasmoid.configuration.appLaunchers = docked.filter(d => d !== id).join(",");
    }
    PlasmaExtras.Menu {
        id: pinMenu
        PlasmaExtras.MenuItem {
            text: i18n("Open")
            icon: "document-open"
            onClicked: {
                if (!panel.applet.launchPinned(panel.pinMenuId))
                    panel.applet.activateApp(panel.pinMenuId);
                panel.closeRequested();
            }
        }
        PlasmaExtras.MenuItem {
            text: i18n("Unpin")
            icon: "window-unpin"
            onClicked: panel.unpinApp(panel.pinMenuId)
        }
    }
    // App Setup: run, rename, delete.
    property int setupMenuIndex: -1
    PlasmaExtras.Menu {
        id: setupMenu
        PlasmaExtras.MenuItem {
            text: i18n("Run")
            icon: "media-playback-start"
            onClicked: {
                panel.applet.runSetup(panel.applet.appSetups[panel.setupMenuIndex]);
                panel.closeRequested();
            }
        }
        PlasmaExtras.MenuItem {
            text: i18n("Rename…")
            icon: "edit-rename"
            onClicked: {
                const s = panel.applet.appSetups[panel.setupMenuIndex];
                renameField.text = s ? s.name : "";
                renamePopup.open();
                renameField.forceActiveFocus();
                renameField.selectAll();
            }
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            text: i18n("Delete")
            icon: "edit-delete"
            onClicked: panel.applet.removeSetup(panel.setupMenuIndex)
        }
    }
    QQC2.Popup {
        id: renamePopup
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        modal: true
        padding: panel.px(14)
        ColumnLayout {
            spacing: panel.px(10)
            Section { text: i18n("Rename setup") }
            QQC2.TextField {
                id: renameField
                Layout.preferredWidth: panel.px(260)
                onAccepted: {
                    panel.applet.renameSetup(panel.setupMenuIndex, text);
                    renamePopup.close();
                }
            }
        }
    }

    // Recent file: open, show its folder, copy its path, forget it.
    property int fileMenuIndex: -1
    property string fileMenuPath: ""
    ShellRunner { id: fileRunner }
    function shq(t) {
        return "'" + String(t).replace(/'/g, "'\\''") + "'";
    }
    PlasmaExtras.Menu {
        id: fileMenu
        PlasmaExtras.MenuItem {
            text: i18n("Open")
            icon: "document-open"
            onClicked: {
                recent.trigger(panel.fileMenuIndex, "", null);
                panel.closeRequested();
            }
        }
        PlasmaExtras.MenuItem {
            text: i18n("Open containing folder")
            icon: "folder-open"
            onClicked: {
                fileRunner.run("xdg-open " + panel.shq(panel.fileMenuPath.replace(/\/[^\/]*$/, "")) + " >/dev/null 2>&1 &");
                panel.closeRequested();
            }
        }
        PlasmaExtras.MenuItem {
            text: i18n("Copy path")
            icon: "edit-copy"
            onClicked: fileRunner.run("printf %s " + panel.shq(panel.fileMenuPath) + " | wl-copy")
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            text: i18n("Remove from recent")
            icon: "edit-delete"
            onClicked: recent.trigger(panel.fileMenuIndex, "_kicker_forget", null)
        }
    }

    // Now-playing card: click the art or title to bring the player forward; right-click for controls.
    function raisePlayer() {
        const pl = applet.mediaPlayer;
        if (!pl)
            return;
        if (pl.canRaise && typeof pl.Raise === "function")
            pl.Raise();
        else if (applet.spotifyPlayer === pl || String(pl.identity).toLowerCase() === "spotify")
            applet.launch("spotify-launcher");
        panel.closeRequested();
    }
    PlasmaExtras.Menu {
        id: playerMenu
        PlasmaExtras.MenuItem {
            text: panel.applet.mediaPlaying ? i18n("Pause") : i18n("Play")
            icon: panel.applet.mediaPlaying ? "media-playback-pause" : "media-playback-start"
            onClicked: panel.applet.mediaPlayer && panel.applet.mediaPlayer.PlayPause()
        }
        PlasmaExtras.MenuItem {
            text: i18n("Next track")
            icon: "media-skip-forward"
            enabled: panel.applet.mediaPlayer ? panel.applet.mediaPlayer.canGoNext : false
            onClicked: panel.applet.mediaPlayer.Next()
        }
        PlasmaExtras.MenuItem {
            text: i18n("Previous track")
            icon: "media-skip-backward"
            enabled: panel.applet.mediaPlayer ? panel.applet.mediaPlayer.canGoPrevious : false
            onClicked: panel.applet.mediaPlayer.Previous()
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            text: i18n("Open player")
            icon: "window"
            onClicked: panel.raisePlayer()
        }
    }

    // New event: Google Calendar's own "create event" page opens with the fields filled in.
    // Writing to a Google calendar directly would need a Google login for the dock, so the
    // last click (Save) stays in the browser.
    function pad2(n) {
        return (n < 10 ? "0" : "") + n;
    }
    function openEventPopup() {
        const d = new Date();
        const start = new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours() + 1, 0);
        const end = new Date(start.getTime() + 3600000);
        evTitle.text = "";
        evDate.text = start.getFullYear() + "-" + pad2(start.getMonth() + 1) + "-" + pad2(start.getDate());
        evStart.text = pad2(start.getHours()) + ":" + pad2(start.getMinutes());
        evEnd.text = pad2(end.getHours()) + ":" + pad2(end.getMinutes());
        eventPopup.open();
        evTitle.forceActiveFocus();
    }
    // "20261114T180000" from the date and time fields, or "" when they are not valid.
    function evStamp(dateText, timeText) {
        const d = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateText.trim());
        const t = /^(\d{1,2}):(\d{2})$/.exec(timeText.trim());
        if (!d || !t || +t[1] > 23 || +t[2] > 59 || +d[2] < 1 || +d[2] > 12 || +d[3] < 1 || +d[3] > 31)
            return "";
        return d[1] + d[2] + d[3] + "T" + pad2(+t[1]) + t[2] + "00";
    }
    readonly property string evFrom: evStamp(evDate.text, evStart.text)
    readonly property string evTo: evStamp(evDate.text, evEnd.text)
    readonly property bool evValid: evTitle.text.trim() !== "" && evFrom !== "" && evTo !== "" && evTo > evFrom
    function createEvent() {
        if (!evValid)
            return;
        const url = "https://calendar.google.com/calendar/render?action=TEMPLATE&text=" + encodeURIComponent(evTitle.text.trim())
            + "&dates=" + evFrom + "/" + evTo;
        fileRunner.run("xdg-open " + shq(url) + " >/dev/null 2>&1 &");
        eventPopup.close();
        panel.closeRequested();
    }
    QQC2.Popup {
        id: eventPopup
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        modal: true
        padding: panel.px(16)
        ColumnLayout {
            spacing: panel.px(10)
            Section { text: i18n("New event") }
            QQC2.TextField {
                id: evTitle
                Layout.preferredWidth: panel.px(300)
                placeholderText: i18n("Title")
                onAccepted: panel.createEvent()
            }
            RowLayout {
                spacing: panel.px(8)
                QQC2.TextField {
                    id: evDate
                    Layout.preferredWidth: panel.px(120)
                    placeholderText: "YYYY-MM-DD"
                    onAccepted: panel.createEvent()
                }
                QQC2.TextField {
                    id: evStart
                    Layout.preferredWidth: panel.px(72)
                    placeholderText: "HH:MM"
                    onAccepted: panel.createEvent()
                }
                PlasmaComponents.Label { text: "–" }
                QQC2.TextField {
                    id: evEnd
                    Layout.preferredWidth: panel.px(72)
                    placeholderText: "HH:MM"
                    onAccepted: panel.createEvent()
                }
            }
            Small {
                text: i18n("Opens Google Calendar with these filled in. Press Save there.")
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: panel.px(8)
                Pill { text: i18n("Cancel"); onClicked: eventPopup.close() }
                Pill {
                    text: i18n("Open in Google Calendar")
                    enabled: panel.evValid
                    opacity: enabled ? 1 : 0.5
                    onClicked: panel.createEvent()
                }
            }
        }
    }

    // ---- pieces ----
    function secText(sec) {
        const s = Math.max(0, Math.floor(sec));
        return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
    }
    // "dashboard-spec.odt" -> "ODT"; a name with no dot gets "FILE".
    function extOf(name) {
        const n = String(name || "");
        const i = n.lastIndexOf(".");
        return i > 0 && i < n.length - 1 ? n.slice(i + 1, i + 5).toUpperCase() : "FILE";
    }
    function extColor(ext) {
        const palette = ["#2a7de1", "#c2185b", "#2e9e5b", "#e07b00", "#7b4fd1", "#d03b3b"];
        let h = 0;
        for (const ch of ext)
            h = (h * 31 + ch.charCodeAt(0)) % 997;
        return palette[h % palette.length];
    }
    // The folder a recent file sits in, for "5 min ago · Documents".
    function folderOf(url) {
        const parts = decodeURIComponent(String(url || "").replace(/^file:\/\//, "")).split("/").filter(p => p !== "");
        return parts.length >= 2 ? parts[parts.length - 2] : "";
    }
    // This computer opens power settings, a phone or tablet opens KDE Connect, anything
    // else (mouse, headset, controller) opens Bluetooth settings.
    function openDevice(kind) {
        if (kind === "laptop")
            applet.launch("systemsettings kcm_powerdevilprofilesconfig");
        else if (kind === "phone" || kind === "smartphone" || kind === "tablet")
            applet.launch("kdeconnect-app");
        else
            applet.launch("systemsettings kcm_bluetooth");
        closeRequested();
    }
    function openWidgetSettings() {
        panel.closeRequested();
        Plasmoid.internalAction("configure").trigger();
    }

    // A glass card: faint fill, hairline border, top-lit edge on dark themes.
    component Card: Rectangle {
        id: card
        radius: panel.px(18)
        color: cardHover.hovered ? Qt.alpha(Kirigami.Theme.textColor, panel.darkTheme ? 0.09 : 0.07) : panel.fill
        border.width: 1
        border.color: panel.hairline

        Behavior on color {
            ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
        HoverHandler { id: cardHover }
        Rectangle {
            visible: panel.darkTheme
            x: card.radius
            y: 1
            width: card.width - card.radius * 2
            height: 1
            color: Qt.alpha("white", 0.09)
        }
    }
    component Section: PlasmaComponents.Label {
        font.pixelSize: panel.px(14)
        font.weight: Font.DemiBold
    }
    component Eyebrow: PlasmaComponents.Label {
        font.pixelSize: panel.px(12)
        font.weight: Font.Medium
        opacity: panel.secondary
    }
    component Small: PlasmaComponents.Label {
        font.pixelSize: panel.px(12)
        opacity: panel.secondary
        font.features: { "tnum": 1 }
    }
    // Pill button: Open, Set location, Add calendar.
    component Pill: QQC2.AbstractButton {
        id: pill
        implicitHeight: panel.px(32)
        implicitWidth: label.implicitWidth + panel.px(28)
        hoverEnabled: true
        scale: down ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }
        background: Rectangle {
            radius: height / 2
            color: pill.hovered ? panel.btnFillHover : panel.btnFill
            border.width: 1
            border.color: panel.hairline
        }
        contentItem: PlasmaComponents.Label {
            id: label
            text: pill.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: panel.px(13)
            font.weight: Font.DemiBold
        }
    }
    // An empty state: icon in a rounded square, a bold line and a hint, optional button.
    component Empty: ColumnLayout {
        property string iconName
        property string title
        property string hint
        property string action
        signal activated()

        spacing: panel.px(4)
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: panel.px(40)
            Layout.preferredHeight: panel.px(40)
            Layout.bottomMargin: panel.px(2)
            radius: panel.px(12)
            color: panel.btnFill
            Kirigami.Icon {
                anchors.centerIn: parent
                width: panel.px(20)
                height: width
                source: parent.parent.iconName
                isMask: true
                color: Kirigami.Theme.textColor
                opacity: panel.secondary
            }
        }
        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            text: parent.title
            font.pixelSize: panel.px(13)
            font.weight: Font.DemiBold
        }
        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: panel.px(220)
            text: parent.hint
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: panel.px(12)
            opacity: panel.secondary
        }
        Pill {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: panel.px(8)
            visible: parent.action !== ""
            text: parent.action
            onClicked: parent.activated()
        }
    }
    // One pinned app: icon on a rounded tile that lifts on hover, label under it.
    component PinCell: QQC2.AbstractButton {
        id: cell
        property var iconSource
        property string name
        hoverEnabled: true
        implicitHeight: panel.px(52) + panel.px(8) * 2 + panel.px(8) + panel.px(16)
        background: Rectangle {
            radius: panel.px(14)
            color: cell.hovered ? panel.fill : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        contentItem: Column {
            spacing: panel.px(8)
            topPadding: panel.px(8)
            Rectangle {
                id: tileBox
                anchors.horizontalCenter: parent.horizontalCenter
                width: panel.px(52)
                height: width
                radius: Math.round(width * 0.27)
                color: Qt.alpha(Kirigami.Theme.textColor, panel.darkTheme ? 0.07 : 0.05)
                border.width: 1
                border.color: panel.hairline
                scale: cell.down ? 0.94 : 1
                // Lifts 2 px on hover, springing; a transform, because the Column owns y.
                transform: Translate {
                    y: cell.hovered && !cell.down ? -panel.px(2) : 0
                    Behavior on y {
                        NumberAnimation { duration: Motion.ms(Motion.elasticMs, Kirigami.Units.longDuration); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.elastic }
                    }
                }
                Behavior on scale { NumberAnimation { duration: 80 } }
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: panel.px(36)
                    height: width
                    source: cell.iconSource
                }
            }
            PlasmaComponents.Label {
                width: parent.width
                text: cell.name
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: panel.px(12)
                font.weight: Font.Medium
            }
        }
    }
    // Footer button with an icon and, optionally, a label.
    component FooterButton: QQC2.AbstractButton {
        id: fb
        property string iconName
        property string tip
        property bool danger: false
        implicitHeight: panel.px(40)
        implicitWidth: text !== "" ? row.implicitWidth + panel.px(28) : panel.px(40)
        hoverEnabled: true
        scale: down ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }
        PlasmaComponents.ToolTip.text: tip
        PlasmaComponents.ToolTip.visible: hovered && tip !== ""
        background: Rectangle {
            radius: panel.px(12)
            color: fb.hovered ? panel.btnFillHover : panel.btnFill
            border.width: 1
            border.color: panel.hairline
        }
        contentItem: Item {
            Row {
                id: row
                anchors.centerIn: parent
                spacing: panel.px(8)
                Kirigami.Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    width: panel.px(18)
                    height: width
                    source: fb.iconName
                    isMask: true
                    color: fb.danger && fb.hovered ? panel.low : Kirigami.Theme.textColor
                }
                PlasmaComponents.Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: fb.text !== ""
                    text: fb.text
                    font.pixelSize: panel.px(13)
                    font.weight: Font.Medium
                }
            }
        }
    }

    ColumnLayout {
        id: body
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: panel.px(24)
            spacing: panel.px(24)

            // ---- top row ----
            RowLayout {
                Layout.fillWidth: true
                spacing: panel.px(12)

                // Weather.
                Card {
                    id: weatherCard
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: panel.px(188)
                    RiseIn { order: 0 }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: panel.px(16)
                        spacing: 0
                        visible: panel.weather.current !== null

                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 0
                                Eyebrow { text: i18n("Weather") }
                                PlasmaComponents.Label {
                                    Layout.topMargin: panel.px(4)
                                    text: panel.weather.current ? panel.weather.current.temp + "°" : ""
                                    font.pixelSize: panel.px(44)
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: -panel.px(1.5)
                                    font.features: { "tnum": 1 }
                                }
                            }
                            Item { Layout.fillWidth: true }
                            RowLayout {
                                Layout.alignment: Qt.AlignTop
                                spacing: panel.px(8)
                                ColumnLayout {
                                    spacing: 0
                                    PlasmaComponents.Label {
                                        Layout.alignment: Qt.AlignRight
                                        text: panel.weather.current ? panel.weather.describe(panel.weather.current.code) : ""
                                        font.pixelSize: panel.px(13)
                                        font.weight: Font.Medium
                                    }
                                    Small {
                                        Layout.alignment: Qt.AlignRight
                                        text: panel.weather.current ? i18n("H %1° · L %2°", panel.weather.current.max, panel.weather.current.min) : ""
                                    }
                                }
                                Kirigami.Icon {
                                    Layout.preferredWidth: panel.px(36)
                                    Layout.preferredHeight: panel.px(36)
                                    source: panel.weather.current ? panel.weather.iconFor(panel.weather.current.code) : ""
                                }
                            }
                        }
                        Item { Layout.fillHeight: true }
                        ListView {
                            id: hourly
                            Layout.fillWidth: true
                            Layout.preferredHeight: panel.px(70)
                            Layout.leftMargin: -panel.px(8)
                            Layout.rightMargin: -panel.px(8)
                            leftMargin: panel.px(8)
                            rightMargin: panel.px(8)
                            orientation: ListView.Horizontal
                            spacing: panel.px(4)
                            clip: true
                            interactive: contentWidth > width
                            boundsBehavior: Flickable.StopAtBounds
                            snapMode: ListView.SnapToItem
                            model: panel.weather.hourly

                            // A vertical wheel scrolls the strip sideways.
                            WheelHandler {
                                onWheel: event => {
                                    hourly.contentX = Math.max(-hourly.leftMargin, Math.min(hourly.contentWidth - hourly.width + hourly.rightMargin,
                                        hourly.contentX - (event.angleDelta.y + event.angleDelta.x) / 2));
                                }
                            }
                            delegate: Rectangle {
                                id: hr
                                required property var modelData
                                required property int index
                                width: panel.px(44)
                                height: hourly.height
                                radius: panel.px(10)
                                color: hr.index === 0 ? panel.fill : "transparent"

                                Column {
                                    anchors.centerIn: parent
                                    spacing: panel.px(4)
                                    PlasmaComponents.Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: hr.index === 0 ? i18n("Now") : String(hr.modelData.hour)
                                        font.pixelSize: panel.px(12)
                                        font.weight: hr.index === 0 ? Font.DemiBold : Font.Normal
                                        opacity: hr.index === 0 ? 1 : panel.secondary
                                    }
                                    Kirigami.Icon {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: panel.px(20)
                                        height: width
                                        source: panel.weather.iconFor(hr.modelData.code)
                                    }
                                    PlasmaComponents.Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: hr.modelData.temp + "°"
                                        font.pixelSize: panel.px(13)
                                        font.weight: Font.DemiBold
                                        font.features: { "tnum": 1 }
                                    }
                                }
                            }
                        }
                    }
                    Empty {
                        anchors.centerIn: parent
                        visible: panel.weather.current === null
                        iconName: "mark-location-symbolic"
                        title: i18n("No weather yet")
                        hint: panel.weather.hasLocation ? i18n("Weather could not be loaded.") : i18n("Set a location in the widget settings.")
                        action: panel.weather.hasLocation ? "" : i18n("Set location")
                        onActivated: panel.openWidgetSettings()
                    }
                }

                // Today.
                Card {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: panel.px(188)
                    RiseIn { order: 1 }

                    // New event. Sits above the card's content, top right.
                    QQC2.AbstractButton {
                        id: addEvent
                        z: 2
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: panel.px(10)
                        anchors.rightMargin: panel.px(10)
                        implicitWidth: panel.px(26)
                        implicitHeight: panel.px(26)
                        hoverEnabled: true
                        onClicked: panel.openEventPopup()
                        PlasmaComponents.ToolTip.text: i18n("New event")
                        PlasmaComponents.ToolTip.visible: hovered
                        background: Rectangle {
                            radius: width / 2
                            color: addEvent.hovered ? panel.btnFillHover : panel.btnFill
                        }
                        contentItem: Item {
                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: panel.px(14)
                                height: width
                                source: "list-add-symbolic"
                                isMask: true
                                color: Kirigami.Theme.textColor
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: panel.px(16)
                        spacing: panel.px(12)
                        visible: panel.agenda.length > 0

                        RowLayout {
                            Layout.fillWidth: true
                            Section { text: i18n("Today") }
                            Item { Layout.fillWidth: true }
                            Small { Layout.rightMargin: panel.px(30); text: Qt.formatDate(panel.applet.now, "ddd d MMM") }
                        }
                        Repeater {
                            model: panel.agenda.slice(0, 3)
                            delegate: RowLayout {
                                id: ev
                                required property var modelData
                                required property int index
                                readonly property bool past: ev.modelData.end <= panel.applet.now && !ev.modelData.allDay
                                readonly property bool current: !ev.modelData.allDay && ev.modelData.start <= panel.applet.now && panel.applet.now < ev.modelData.end
                                Layout.fillWidth: true
                                spacing: panel.px(10)

                                Rectangle {
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: panel.px(4)
                                    Layout.preferredWidth: panel.px(8)
                                    Layout.preferredHeight: panel.px(8)
                                    radius: width / 2
                                    color: panel.dotColors[ev.index % panel.dotColors.length]
                                    opacity: ev.past ? 0.5 : 1
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Small {
                                        text: ev.modelData.allDay ? i18n("All day")
                                            : Qt.formatTime(ev.modelData.start, "HH:mm") + " – " + Qt.formatTime(ev.modelData.end, "HH:mm")
                                    }
                                    PlasmaComponents.Label {
                                        Layout.fillWidth: true
                                        text: ev.modelData.title
                                        elide: Text.ElideRight
                                        font.pixelSize: panel.px(13)
                                        font.weight: ev.past ? Font.Normal : Font.Medium
                                        opacity: ev.past ? panel.secondary : 1
                                    }
                                }
                                Rectangle {
                                    visible: ev.current
                                    Layout.alignment: Qt.AlignTop
                                    implicitWidth: nowText.implicitWidth + panel.px(14)
                                    implicitHeight: panel.px(18)
                                    radius: height / 2
                                    color: Qt.alpha(panel.accent, 0.2)
                                    PlasmaComponents.Label {
                                        id: nowText
                                        anchors.centerIn: parent
                                        text: i18n("Now")
                                        color: panel.darkTheme ? Qt.lighter(panel.accent, 1.35) : Qt.darker(panel.accent, 1.3)
                                        font.pixelSize: panel.px(11)
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                    Empty {
                        anchors.centerIn: parent
                        visible: panel.agenda.length === 0
                        iconName: "view-calendar-symbolic"
                        title: !panel.calendarSet ? i18n("No calendar")
                            : panel.agendaState === "error" ? i18n("Calendar unavailable")
                            : panel.agendaState === "ok" ? i18n("Nothing planned today") : i18n("Today")
                        hint: !panel.calendarSet ? i18n("Add a calendar in the widget settings.")
                            : panel.agendaState === "error" ? i18n("Check the calendar address.") : ""
                        action: !panel.calendarSet ? i18n("Add calendar") : ""
                        onActivated: panel.openWidgetSettings()
                    }
                }

                // Devices.
                Card {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: panel.px(188)
                    RiseIn { order: 2 }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: panel.px(16)
                        spacing: panel.px(8)
                        visible: panel.devices.length > 0

                        Repeater {
                            model: panel.devices
                            delegate: ColumnLayout {
                                id: dev
                                required property var modelData
                                readonly property bool lowBattery: dev.modelData.percent < 20
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                Layout.alignment: Qt.AlignVCenter
                                spacing: panel.px(4)

                                // Tap a device to open the settings that manage it.
                                HoverHandler {
                                    id: devHover
                                    cursorShape: Qt.PointingHandCursor
                                }
                                TapHandler {
                                    onTapped: panel.openDevice(dev.modelData.kind)
                                }
                                opacity: devHover.hovered ? 0.8 : 1

                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.bottomMargin: panel.px(4)
                                    Layout.preferredWidth: panel.px(52)
                                    Layout.preferredHeight: panel.px(52)
                                    radius: width / 2
                                    color: panel.btnFill
                                    border.width: 1
                                    border.color: panel.hairline
                                    Kirigami.Icon {
                                        anchors.centerIn: parent
                                        width: panel.px(24)
                                        height: width
                                        source: panel.iconForKind(dev.modelData.kind)
                                        isMask: true
                                        color: Kirigami.Theme.textColor
                                    }
                                }
                                Small {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: dev.modelData.name
                                }
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 2
                                    Kirigami.Icon {
                                        visible: dev.modelData.charging
                                        Layout.preferredWidth: panel.px(14)
                                        Layout.preferredHeight: panel.px(14)
                                        source: "battery-charging-symbolic"
                                        isMask: true
                                        color: panel.good
                                    }
                                    PlasmaComponents.Label {
                                        text: dev.modelData.percent + "%"
                                        font.pixelSize: panel.px(15)
                                        font.weight: Font.DemiBold
                                        font.features: { "tnum": 1 }
                                        color: dev.lowBattery ? panel.low : Kirigami.Theme.textColor
                                    }
                                }
                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: 2
                                    Layout.preferredWidth: panel.px(64)
                                    Layout.preferredHeight: panel.px(4)
                                    radius: height / 2
                                    color: panel.trackColor
                                    Rectangle {
                                        width: parent.width * Math.max(0, Math.min(100, dev.modelData.percent)) / 100
                                        height: parent.height
                                        radius: height / 2
                                        color: dev.lowBattery ? panel.low : panel.good
                                    }
                                }
                            }
                        }
                    }
                    Empty {
                        anchors.centerIn: parent
                        visible: panel.devices.length === 0
                        iconName: "preferences-system-bluetooth-symbolic"
                        title: i18n("No devices")
                        hint: i18n("Paired Bluetooth and KDE Connect devices show their battery here.")
                    }
                }
            }

            // ---- middle ----
            RowLayout {
                Layout.fillWidth: true
                spacing: panel.px(24)

                // Pinned apps.
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: panel.px(12)
                    RiseIn { order: 3 }

                    Section { text: i18n("Pinned Apps") }
                    Flow {
                        id: pinFlow
                        Layout.fillWidth: true
                        Layout.leftMargin: -panel.px(8)
                        Layout.rightMargin: -panel.px(8)
                        spacing: panel.px(4)
                        readonly property int columns: 6
                        readonly property real cellWidth: Math.floor((width - spacing * (columns - 1)) / columns)

                        Repeater {
                            model: favs
                            delegate: PinCell {
                                required property var model
                                required property int index
                                visible: index < pinFlow.columns * 2
                                width: pinFlow.cellWidth
                                iconSource: model.decoration
                                name: model.display
                                readonly property string pinId: model.favoriteId ?? panel.favList[index] ?? ""
                                // AbstractButton also fires clicked() for the right button; rightDown stops that.
                                property bool rightDown: false
                                Timer { id: pinRightTimer; interval: 300; onTriggered: parent.rightDown = false }
                                TapHandler {
                                    acceptedButtons: Qt.RightButton
                                    onPressedChanged: {
                                        if (pressed) { parent.rightDown = true; pinRightTimer.stop(); }
                                        else pinRightTimer.restart();
                                    }
                                    onTapped: eventPoint => {
                                        panel.pinMenuId = parent.pinId;
                                        pinMenu.visualParent = parent;
                                        pinMenu.open(eventPoint.position.x, eventPoint.position.y);
                                    }
                                }
                                onClicked: {
                                    if (rightDown)
                                        return;
                                    if (!panel.applet.launchPinned(pinId))
                                        favs.trigger(index, "", null);
                                    panel.closeRequested();
                                }
                            }
                        }
                    }

                    // App Setups: saved sets of apps that open and tile together.
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: panel.px(12)
                        Section { text: i18n("App Setups") }
                        Item { Layout.fillWidth: true }
                        QQC2.AbstractButton {
                            id: saveBtn
                            implicitHeight: panel.px(28)
                            implicitWidth: saveRow.implicitWidth + panel.px(20)
                            hoverEnabled: true
                            onClicked: panel.applet.saveCurrentSetup()
                            background: Rectangle {
                                radius: panel.px(8)
                                color: saveBtn.hovered ? panel.btnFill : "transparent"
                            }
                            contentItem: Row {
                                id: saveRow
                                spacing: panel.px(4)
                                anchors.centerIn: parent
                                Kirigami.Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: panel.px(14)
                                    height: width
                                    source: "list-add-symbolic"
                                    isMask: true
                                    color: Kirigami.Theme.textColor
                                    opacity: saveBtn.hovered ? 1 : panel.secondary
                                }
                                PlasmaComponents.Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: i18n("Save current")
                                    font.pixelSize: panel.px(12)
                                    font.weight: Font.Medium
                                    opacity: saveBtn.hovered ? 1 : panel.secondary
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: panel.px(12)
                        visible: panel.applet.appSetups.length > 0

                        Repeater {
                            model: panel.applet.appSetups.slice(0, 4)
                            delegate: QQC2.AbstractButton {
                                id: setupBtn
                                required property var modelData
                                required property int index
                                readonly property var appList: modelData.apps.slice(0, 4)
                                readonly property string layoutKey: modelData.layout || "side"
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitHeight: panel.px(84) + panel.px(8) + panel.px(16)
                                hoverEnabled: true
                                onClicked: {
                                    if (rightDown)
                                        return;
                                    panel.applet.runSetup(modelData);
                                    panel.closeRequested();
                                }
                                property bool rightDown: false
                                Timer { id: setupRightTimer; interval: 300; onTriggered: setupBtn.rightDown = false }
                                TapHandler {
                                    acceptedButtons: Qt.RightButton
                                    onPressedChanged: {
                                        if (pressed) { setupBtn.rightDown = true; setupRightTimer.stop(); }
                                        else setupRightTimer.restart();
                                    }
                                    onTapped: eventPoint => {
                                        panel.setupMenuIndex = setupBtn.index;
                                        setupMenu.visualParent = setupBtn;
                                        setupMenu.open(eventPoint.position.x, eventPoint.position.y);
                                    }
                                }
                                PlasmaComponents.ToolTip.text: modelData.apps.join(", ")
                                PlasmaComponents.ToolTip.visible: hovered
                                background: null
                                contentItem: Column {
                                    spacing: panel.px(8)
                                    transform: Translate {
                                        y: setupBtn.hovered && !setupBtn.down ? -panel.px(2) : 0
                                        Behavior on y {
                                            NumberAnimation { duration: Motion.ms(Motion.elasticMs, Kirigami.Units.longDuration); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.elastic }
                                        }
                                    }
                                    Rectangle {
                                        id: thumb
                                        width: parent.width
                                        height: panel.px(84)
                                        radius: panel.px(14)
                                        color: setupBtn.hovered ? Qt.alpha(Kirigami.Theme.textColor, panel.darkTheme ? 0.09 : 0.07) : panel.fill
                                        border.width: 1
                                        border.color: panel.hairline

                                        // A saved setup: a small map of the monitors with each window where it
                                        // was, on its own monitor.
                                        Item {
                                            id: mini
                                            anchors.fill: parent
                                            anchors.margins: panel.px(6)
                                            visible: setupBtn.layoutKey === "saved"
                                            readonly property var outs: setupBtn.modelData.outputs || []
                                            readonly property real minX: outs.length ? Math.min(...outs.map(o => o.x)) : 0
                                            readonly property real minY: outs.length ? Math.min(...outs.map(o => o.y)) : 0
                                            readonly property real totalW: outs.length ? Math.max(...outs.map(o => o.x + o.width)) - minX : 1
                                            readonly property real totalH: outs.length ? Math.max(...outs.map(o => o.y + o.height)) - minY : 1
                                            readonly property real k: Math.min(width / totalW, height / totalH)
                                            readonly property real offX: (width - totalW * k) / 2
                                            readonly property real offY: (height - totalH * k) / 2

                                            Repeater {
                                                model: mini.outs
                                                delegate: Rectangle {
                                                    required property var modelData
                                                    x: mini.offX + (modelData.x - mini.minX) * mini.k
                                                    y: mini.offY + (modelData.y - mini.minY) * mini.k
                                                    width: modelData.width * mini.k
                                                    height: modelData.height * mini.k
                                                    radius: panel.px(4)
                                                    color: "transparent"
                                                    border.width: 1
                                                    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.3)
                                                }
                                            }
                                            Repeater {
                                                model: setupBtn.modelData.windows || []
                                                delegate: Rectangle {
                                                    id: miniWin
                                                    required property var modelData
                                                    readonly property var out: mini.outs.find(o => o.name === modelData.output) || null
                                                    visible: out !== null
                                                    x: out ? mini.offX + (out.x - mini.minX + modelData.fx * out.width) * mini.k : 0
                                                    y: out ? mini.offY + (out.y - mini.minY + modelData.fy * out.height) * mini.k : 0
                                                    width: out ? modelData.fw * out.width * mini.k : 0
                                                    height: out ? modelData.fh * out.height * mini.k : 0
                                                    radius: panel.px(3)
                                                    color: Qt.alpha(panel.accent, 0.22)
                                                    border.width: 1
                                                    border.color: Qt.alpha(panel.accent, 0.7)
                                                    Kirigami.Icon {
                                                        anchors.centerIn: parent
                                                        width: Math.min(panel.px(16), parent.width - 2, parent.height - 2)
                                                        height: width
                                                        visible: width >= panel.px(8)
                                                        source: miniWin.modelData.app
                                                        fallback: "application-x-executable"
                                                    }
                                                }
                                            }
                                        }

                                        // One pane per app, arranged as the setup will tile them.
                                        Repeater {
                                            model: setupBtn.layoutKey === "saved" ? [] : setupBtn.appList
                                            delegate: Rectangle {
                                                id: pane
                                                required property string modelData
                                                required property int index
                                                readonly property int n: setupBtn.appList.length
                                                readonly property real pad: panel.px(6)
                                                readonly property real gap: panel.px(4)
                                                readonly property real iw: thumb.width - pad * 2
                                                readonly property real ih: thumb.height - pad * 2
                                                readonly property var r: {
                                                    const L = setupBtn.layoutKey;
                                                    if (n === 1)
                                                        return { x: 0, y: 0, w: iw, h: ih };
                                                    if (L === "grid") {
                                                        const cols = 2, rows = Math.ceil(n / cols);
                                                        const cw = (iw - gap) / cols, ch = (ih - gap * (rows - 1)) / rows;
                                                        return { x: (index % cols) * (cw + gap), y: Math.floor(index / cols) * (ch + gap), w: cw, h: ch };
                                                    }
                                                    if (L === "main") {
                                                        const mw = (iw - gap) * 0.6;
                                                        if (index === 0)
                                                            return { x: 0, y: 0, w: mw, h: ih };
                                                        const rest = n - 1, rh = (ih - gap * (rest - 1)) / rest;
                                                        return { x: mw + gap, y: (index - 1) * (rh + gap), w: iw - mw - gap, h: rh };
                                                    }
                                                    const cw = (iw - gap * (n - 1)) / n;
                                                    return { x: index * (cw + gap), y: 0, w: cw, h: ih };
                                                }
                                                x: pad + r.x
                                                y: pad + r.y
                                                width: r.w
                                                height: r.h
                                                radius: panel.px(8)
                                                color: panel.btnFill
                                                Kirigami.Icon {
                                                    anchors.centerIn: parent
                                                    width: Math.min(panel.px(26), parent.width - panel.px(6), parent.height - panel.px(6))
                                                    height: width
                                                    source: pane.modelData
                                                    fallback: "application-x-executable"
                                                }
                                            }
                                        }
                                    }
                                    RowLayout {
                                        width: parent.width
                                        PlasmaComponents.Label {
                                            Layout.fillWidth: true
                                            text: setupBtn.modelData.name
                                            elide: Text.ElideRight
                                            font.pixelSize: panel.px(12)
                                            font.weight: Font.Medium
                                        }
                                        Small { text: i18n("%1 apps", setupBtn.modelData.apps.length) }
                                    }
                                }
                            }
                        }
                        Item { Layout.fillWidth: true; Layout.preferredWidth: 1; visible: panel.applet.appSetups.length < 4 }
                    }
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        visible: panel.applet.appSetups.length === 0
                        text: i18n("Open the apps you want together, then Save current. Click a setup later to start and tile them.")
                        wrapMode: Text.Wrap
                        opacity: panel.secondary
                        font.pixelSize: panel.px(12)
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    color: panel.hairline
                }

                // Pick up where you left off.
                ColumnLayout {
                    id: pickCol
                    Layout.preferredWidth: panel.px(352)
                    Layout.maximumWidth: panel.px(352)
                    Layout.alignment: Qt.AlignTop
                    spacing: panel.px(12)
                    RiseIn { order: 4 }

                    readonly property var player: panel.applet.mediaPlayer
                    readonly property bool hasTrack: player !== null && player.track !== ""

                    // Plasma's player model does not refresh a browser's position, so ask the player
                    // itself once a second while it plays (and once when the panel opens).
                    property real position: 0   // microseconds
                    property real trackLength: player && player.length > 0 ? player.length : lengthFromPlayer
                    property real lengthFromPlayer: 0
                    ShellRunner {
                        id: posRunner
                        onFinished: (cmd, out) => {
                            const f = out.trim().split(/\s+/);
                            if (f.length >= 2) {
                                pickCol.position = parseInt(f[0], 10) || 0;
                                pickCol.lengthFromPlayer = parseInt(f[1], 10) || 0;
                            }
                        }
                    }
                    Timer {
                        interval: 1000
                        repeat: true
                        running: pickCol.hasTrack && panel.applet.mediaPlaying
                        triggeredOnStart: true
                        onTriggered: posRunner.run("sh '" + panel.scriptPath("mpris-position.sh") + "' '" + String(pickCol.player.identity).replace(/'/g, "") + "'")
                    }
                    Component.onCompleted: if (hasTrack && !panel.applet.mediaPlaying)
                        posRunner.run("sh '" + panel.scriptPath("mpris-position.sh") + "' '" + String(player.identity).replace(/'/g, "") + "'")
                    readonly property int fileCount: Math.min(2, recent.count)

                    Section { text: i18n("Pick up where you left off") }

                    // Continue listening.
                    Card {
                        Layout.fillWidth: true
                        visible: pickCol.hasTrack
                        implicitHeight: listen.implicitHeight + panel.px(26)

                        // Left click on the card (not its buttons, which sit above this) raises the player;
                        // right click opens the controls menu.
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    playerMenu.visualParent = parent;
                                    playerMenu.open(mouse.x, mouse.y);
                                } else {
                                    panel.raisePlayer();
                                }
                            }
                        }

                        ColumnLayout {
                            id: listen
                            anchors.fill: parent
                            anchors.leftMargin: panel.px(14)
                            anchors.rightMargin: panel.px(14)
                            anchors.topMargin: panel.px(12)
                            anchors.bottomMargin: panel.px(14)
                            spacing: panel.px(10)

                            Eyebrow { text: panel.applet.mediaPlaying ? i18n("Now playing") : i18n("Continue listening") }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: panel.px(12)

                                Rectangle {
                                    Layout.preferredWidth: panel.px(48)
                                    Layout.preferredHeight: panel.px(48)
                                    radius: panel.px(10)
                                    color: panel.btnFill
                                    clip: true
                                    Image {
                                        anchors.fill: parent
                                        source: pickCol.player && pickCol.player.artUrl ? pickCol.player.artUrl : ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: status === Image.Ready
                                    }
                                    Kirigami.Icon {
                                        anchors.centerIn: parent
                                        width: panel.px(22)
                                        height: width
                                        source: "audio-x-generic-symbolic"
                                        isMask: true
                                        color: Kirigami.Theme.textColor
                                        opacity: panel.secondary
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    PlasmaComponents.Label {
                                        Layout.fillWidth: true
                                        text: pickCol.player ? pickCol.player.track : ""
                                        elide: Text.ElideRight
                                        font.pixelSize: panel.px(14)
                                        font.weight: Font.DemiBold
                                    }
                                    Small {
                                        Layout.fillWidth: true
                                        text: pickCol.player ? pickCol.player.artist : ""
                                        elide: Text.ElideRight
                                    }
                                }
                                // Play: a filled accent circle, as the media tile in STYLE.md.
                                QQC2.AbstractButton {
                                    id: play
                                    implicitWidth: panel.px(36)
                                    implicitHeight: panel.px(36)
                                    hoverEnabled: true
                                    scale: down ? 0.94 : hovered ? 1.06 : 1
                                    Behavior on scale {
                                        NumberAnimation { duration: Motion.ms(Motion.elasticMs, Kirigami.Units.longDuration); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.elastic }
                                    }
                                    onClicked: pickCol.player.PlayPause()
                                    PlasmaComponents.ToolTip.text: panel.applet.mediaPlaying ? i18n("Pause") : i18n("Play")
                                    PlasmaComponents.ToolTip.visible: hovered
                                    background: Rectangle {
                                        radius: width / 2
                                        color: panel.accent
                                    }
                                    contentItem: Item {
                                        Kirigami.Icon {
                                            anchors.centerIn: parent
                                            width: panel.px(16)
                                            height: width
                                            source: panel.applet.mediaPlaying ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                                            isMask: true
                                            color: "white"
                                        }
                                    }
                                }
                                QQC2.AbstractButton {
                                    id: nextBtn
                                    implicitWidth: panel.px(32)
                                    implicitHeight: panel.px(32)
                                    hoverEnabled: true
                                    enabled: pickCol.player ? pickCol.player.canGoNext : false
                                    opacity: enabled ? 1 : 0.4
                                    onClicked: pickCol.player.Next()
                                    PlasmaComponents.ToolTip.text: i18n("Next track")
                                    PlasmaComponents.ToolTip.visible: hovered
                                    background: Rectangle {
                                        radius: panel.px(10)
                                        color: nextBtn.hovered ? panel.btnFillHover : "transparent"
                                    }
                                    contentItem: Item {
                                        Kirigami.Icon {
                                            anchors.centerIn: parent
                                            width: panel.px(18)
                                            height: width
                                            source: "media-skip-forward-symbolic"
                                            isMask: true
                                            color: Kirigami.Theme.textColor
                                            opacity: panel.secondary + 0.2
                                        }
                                    }
                                }
                            }
                            // Progress: elapsed time, and the bar and total when the player reports a length.
                            RowLayout {
                                Layout.fillWidth: true
                                visible: pickCol.position > 0 || pickCol.trackLength > 0
                                spacing: panel.px(8)
                                Small { text: panel.secText(pickCol.position / 1000000) }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 3
                                    radius: 2
                                    color: panel.trackColor
                                    visible: pickCol.trackLength > 0
                                    Rectangle {
                                        height: parent.height
                                        radius: 2
                                        opacity: 0.85
                                        color: Kirigami.Theme.textColor
                                        width: pickCol.trackLength > 0
                                            ? parent.width * Math.max(0, Math.min(1, pickCol.position / pickCol.trackLength)) : 0
                                    }
                                }
                                Item { Layout.fillWidth: true; visible: pickCol.trackLength <= 0 }
                                Small { visible: pickCol.trackLength > 0; text: panel.secText(pickCol.trackLength / 1000000) }
                            }
                        }
                    }

                    // The files used last.
                    Repeater {
                        model: recent
                        delegate: Card {
                            id: fileCard
                            required property var model
                            required property int index
                            readonly property string ext: panel.extOf(fileCard.model.display)
                            readonly property string folder: panel.folderOf(fileCard.model.url)
                            readonly property string when: panel.agoText(panel.recentTimes[decodeURIComponent(String(fileCard.model.url || "").replace(/^file:\/\//, ""))])
                            visible: index < 2
                            Layout.fillWidth: true
                            Layout.preferredHeight: visible ? fileLayout.implicitHeight + panel.px(26) : 0

                            // The Open pill is an AbstractButton, which also clicks on a right click.
                            property bool rightDown: false
                            Timer { id: fileRightTimer; interval: 300; onTriggered: fileCard.rightDown = false }
                            TapHandler {
                                acceptedButtons: Qt.RightButton
                                onPressedChanged: {
                                    if (pressed) { fileCard.rightDown = true; fileRightTimer.stop(); }
                                    else fileRightTimer.restart();
                                }
                                onTapped: eventPoint => {
                                    panel.fileMenuIndex = fileCard.index;
                                    panel.fileMenuPath = decodeURIComponent(String(fileCard.model.url || "").replace(/^file:\/\//, ""));
                                    fileMenu.visualParent = fileCard;
                                    fileMenu.open(eventPoint.position.x, eventPoint.position.y);
                                }
                            }

                            ColumnLayout {
                                id: fileLayout
                                anchors.fill: parent
                                anchors.leftMargin: panel.px(14)
                                anchors.rightMargin: panel.px(14)
                                anchors.topMargin: panel.px(12)
                                anchors.bottomMargin: panel.px(14)
                                spacing: panel.px(10)

                                Eyebrow { text: fileCard.index === 0 ? i18n("Continue editing") : i18n("Recent file") }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: panel.px(12)

                                    // A page with a coloured type badge.
                                    Item {
                                        Layout.preferredWidth: panel.px(40)
                                        Layout.preferredHeight: panel.px(48)
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: panel.px(36)
                                            height: panel.px(44)
                                            radius: panel.px(6)
                                            color: "white"
                                            border.width: 1
                                            border.color: Qt.alpha("black", 0.1)
                                            Column {
                                                x: panel.px(8)
                                                y: panel.px(14)
                                                spacing: panel.px(4)
                                                Repeater {
                                                    model: 3
                                                    Rectangle { width: panel.px(20); height: 2; color: "#c9ccd4" }
                                                }
                                            }
                                        }
                                        Rectangle {
                                            x: -2
                                            y: parent.height - height - 2
                                            width: extLabel.implicitWidth + panel.px(8)
                                            height: panel.px(15)
                                            radius: 4
                                            color: panel.extColor(fileCard.ext)
                                            Text {
                                                id: extLabel
                                                anchors.centerIn: parent
                                                text: fileCard.ext
                                                color: "white"
                                                font.pixelSize: panel.px(9)
                                                font.weight: Font.Bold
                                            }
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        PlasmaComponents.Label {
                                            Layout.fillWidth: true
                                            text: fileCard.model.display
                                            elide: Text.ElideRight
                                            font.pixelSize: panel.px(14)
                                            font.weight: Font.DemiBold
                                        }
                                        Small {
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            text: [fileCard.when, fileCard.folder].filter(t => t !== "").join(" · ") || (fileCard.model.description || "")
                                        }
                                    }
                                    Pill {
                                        text: i18n("Open")
                                        onClicked: {
                                            if (fileCard.rightDown)
                                                return;
                                            recent.trigger(fileCard.index, "", null);
                                            panel.closeRequested();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        Layout.preferredHeight: panel.px(188)
                        visible: !pickCol.hasTrack && recent.count === 0
                        Empty {
                            anchors.centerIn: parent
                            iconName: "document-open-recent-symbolic"
                            title: i18n("Nothing to pick up yet")
                            hint: i18n("Music you play and files you open show up here.")
                        }
                    }
                }
            }
        }

        // ---- footer ----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: panel.px(72)
            color: Qt.alpha(Kirigami.Theme.textColor, panel.darkTheme ? 0.035 : 0.03)
            RiseIn { order: 6 }

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: panel.hairline
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: panel.px(24)
                anchors.rightMargin: panel.px(24)
                spacing: panel.px(16)

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: panel.px(12)
                    Rectangle {
                        Layout.preferredWidth: panel.px(40)
                        Layout.preferredHeight: panel.px(40)
                        radius: width / 2
                        color: panel.accent
                        PlasmaComponents.Label {
                            anchors.centerIn: parent
                            text: (panel.realName || panel.userName || "?").charAt(0).toUpperCase()
                            color: "white"
                            font.pixelSize: panel.px(16)
                            font.weight: Font.DemiBold
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: panel.realName || panel.userName
                            elide: Text.ElideRight
                            font.pixelSize: panel.px(14)
                            font.weight: Font.DemiBold
                        }
                        Small {
                            Layout.fillWidth: true
                            text: panel.userName
                            elide: Text.ElideRight
                        }
                    }
                }

                RowLayout {
                    spacing: panel.px(8)
                    FooterButton {
                        iconName: "configure-symbolic"
                        text: i18n("Settings")
                        onClicked: {
                            panel.applet.launch("systemsettings");
                            panel.closeRequested();
                        }
                    }
                    FooterButton {
                        iconName: "view-app-grid-symbolic"
                        text: i18n("All apps")
                        onClicked: panel.classicRequested("")
                    }
                    FooterButton {
                        iconName: "system-shutdown-symbolic"
                        tip: i18n("Shut down…")
                        danger: true
                        enabled: sm.canShutdown
                        onClicked: {
                            panel.closeRequested();
                            sm.requestShutdown();
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: panel.px(12)
                    Item { Layout.fillWidth: true }
                    visible: panel.applet.diskTotal > 0

                    RowLayout {
                        Layout.preferredWidth: panel.px(264)
                        Layout.maximumWidth: panel.px(264)
                        spacing: panel.px(12)
                        Kirigami.Icon {
                            Layout.preferredWidth: panel.px(18)
                            Layout.preferredHeight: panel.px(18)
                            source: "drive-harddisk-symbolic"
                            isMask: true
                            color: Kirigami.Theme.textColor
                            opacity: panel.secondary
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: panel.px(6)
                            RowLayout {
                                Layout.fillWidth: true
                                PlasmaComponents.Label {
                                    text: i18n("Storage")
                                    font.pixelSize: panel.px(12)
                                    font.weight: Font.DemiBold
                                }
                                Item { Layout.fillWidth: true }
                                Small {
                                    text: i18n("%1 used of %2",
                                        Math.round(panel.applet.diskUsed / 1073741824) + " GB",
                                        Math.round(panel.applet.diskTotal / 1073741824) + " GB")
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: panel.px(4)
                                radius: height / 2
                                color: panel.trackColor
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, panel.applet.diskUsed / Math.max(1, panel.applet.diskTotal)))
                                    height: parent.height
                                    radius: height / 2
                                    color: panel.accent
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
