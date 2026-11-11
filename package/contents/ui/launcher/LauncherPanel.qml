import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.private.kicker as Kicker
import org.kde.plasma.private.sessions as Sessions
import org.kde.kirigami as Kirigami
import "../components"

// Lumen Launcher panel (docs/PLAN-launcher.md): pinned apps, categories, live search,
// recent files and the session buttons. Data comes from the same Kicker models Plasma's
// own launchers use. Shown in the dock popup when the Start tile is clicked.
Item {
    id: panel

    // The PlasmoidItem, which the Kicker models need.
    property var applet
    signal closeRequested()

    readonly property var cfg: Plasmoid.configuration
    // System blue from docs/STYLE.md (so selection matches the dock whatever the theme accent is),
    // unless an accent is picked in settings.
    readonly property color accent: cfg.accentColor !== "" ? cfg.accentColor : "#0A84FF"
    readonly property var favList: cfg.launcherFavorites.split(",").map(s => s.trim()).filter(s => s !== "")
    property string searchText: ""
    readonly property string query: searchText.trim()
    readonly property bool searching: query !== ""
    // A tiny calculator: + - * / % and brackets, no eval. Null when the query is not maths.
    readonly property var calcValue: calc(query)
    function calc(q) {
        if (!/^[\d\s+\-*\/().%,]+$/.test(q) || !/[+\-*\/%]/.test(q.replace(/^\s*-/, "")))
            return null;
        const t = q.replace(/,/g, ".").replace(/\s+/g, "");
        let i = 0;
        function num() {
            if (t[i] === "(") { i++; const v = add(); if (t[i] !== ")") throw 0; i++; return v; }
            const m = /^\d*\.?\d+/.exec(t.slice(i));
            if (!m) throw 0;
            i += m[0].length;
            return parseFloat(m[0]);
        }
        function unary() {
            if (t[i] === "-") { i++; return -unary(); }
            if (t[i] === "+") { i++; return unary(); }
            let v = num();
            while (t[i] === "%") { i++; v /= 100; }
            return v;
        }
        function mul() {
            let v = unary();
            while (t[i] === "*" || t[i] === "/") { const o = t[i++]; const r = unary(); v = o === "*" ? v * r : v / r; }
            return v;
        }
        function add() {
            let v = mul();
            while (t[i] === "+" || t[i] === "-") { const o = t[i++]; const r = mul(); v = o === "+" ? v + r : v - r; }
            return v;
        }
        try {
            const res = add();
            return i === t.length && isFinite(res) ? Math.round(res * 1e8) / 1e8 : null;
        } catch (e) {
            return null;
        }
    }
    function copyResult() {
        clip.text = String(calcValue);
        clip.selectAll();
        clip.copy();
        closeRequested();
    }
    TextEdit {
        id: clip
        visible: false
    }

    // "home" (pinned + recent), "all", or a category row number.
    property var view: "home"
    property string userName: ""
    property string realName: ""
    // Apps across all categories, for the rail and the footer. An app filed under two
    // categories counts twice; close enough for a summary.
    readonly property int appCount: {
        let n = 0;
        for (let i = 0; i < cats.count; i++) {
            const m = cats.modelForRow(i);
            if (m)
                n += m.count;
        }
        return n;
    }
    // Grid cells share each row evenly. As many columns as fit at the button's
    // natural width (at least four), so a narrow popup never squeezes the icons.
    readonly property int cellSpacing: 4
    readonly property real minCellWidth: Kirigami.Units.gridUnit * 5
    function gridColumns(rowWidth) {
        return Math.max(4, Math.floor((rowWidth + cellSpacing) / (minCellWidth + cellSpacing)));
    }
    function cellWidth(rowWidth) {
        const n = gridColumns(rowWidth);
        return Math.floor((rowWidth - cellSpacing * (n - 1)) / n);
    }
    // Shared radii and font sizes, from the launcher mockup.
    readonly property int railRadius: Math.round(Kirigami.Units.gridUnit * 0.55)
    readonly property int pillRadius: Math.round(Kirigami.Units.gridUnit * 0.78)
    readonly property int smallFont: Math.round(Kirigami.Units.gridUnit * 0.6)
    readonly property int bodyFont: Math.round(Kirigami.Units.gridUnit * 0.72)
    readonly property color hairline: Qt.alpha(Kirigami.Theme.textColor, 0.08)

    function matches(name) {
        return !searching || name.toLowerCase().indexOf(query.toLowerCase()) >= 0;
    }
    // The first visible search match, in tree order: highlighted, and launched by Enter.
    property var topApp: null
    function findApp(item) {
        for (const c of item.children) {
            if (c.objectName === "app" && c.visible)
                return c;
            const found = findApp(c);
            if (found)
                return found;
        }
        return null;
    }
    function updateTopApp() {
        const best = searching ? findApp(panel) : null;
        if (topApp && topApp !== best)
            topApp.searchHit = false;
        topApp = best;
        if (best)
            best.searchHit = true;
    }
    function pin(id) {
        if (id === "" || favList.indexOf(id) >= 0)
            return;
        Plasmoid.configuration.launcherFavorites = favList.concat([id]).join(",");
        setDockPinned(id, true);
    }
    function unpin(id) {
        Plasmoid.configuration.launcherFavorites = favList.filter(f => f !== id).join(",");
        setDockPinned(id, false);
    }
    // Keep the dock's app row in step with the launcher's pins.
    function setDockPinned(id, on) {
        const docked = cfg.appLaunchers.split(",").map(s => s.trim()).filter(s => s !== "");
        const next = on ? (docked.indexOf(id) >= 0 ? docked : docked.concat([id])) : docked.filter(d => d !== id);
        Plasmoid.configuration.appLaunchers = next.join(",");
    }
    function close() {
        panel.closeRequested();
    }

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (src, data) => {
            disconnectSource(src);
            const lines = (data["stdout"] || "").split("\n");
            panel.realName = lines[0].trim();
            panel.userName = (lines[1] || "").trim();
        }
    }
    Component.onCompleted: exec.connectSource("getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1; echo \"$USER\"")

    Kicker.RootModel {
        id: cats
        autoPopulate: false
        flat: false
        sorted: true
        showSeparators: false
        showTopLevelItems: false
        showAllApps: false
        showRecentApps: false
        showRecentDocs: false
        showRecentFolders: false
        appletInterface: panel.applet
        Component.onCompleted: refresh()
    }
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

    // Right-click menu for any app: a native Plasma menu, like the dock's own menus,
    // opened where the pointer is.
    property string menuId: ""
    PlasmaExtras.Menu {
        id: appMenu
        onStatusChanged: if (status === PlasmaExtras.Menu.Closed) panel.menuClosedAt = Date.now()

        PlasmaExtras.MenuItem {
            readonly property bool pinned: panel.favList.indexOf(panel.menuId) >= 0
            text: pinned ? i18n("Unpin from launcher") : i18n("Pin to launcher")
            icon: pinned ? "window-unpin" : "pin"
            enabled: panel.menuId !== ""
            onClicked: pinned ? panel.unpin(panel.menuId) : panel.pin(panel.menuId)
        }
        PlasmaExtras.MenuItem { separator: true; visible: panel.uninstallKind !== "" }
        // Shown once uninstall-app.sh has found how the app was installed. The uninstaller
        // runs in a terminal (or Steam's own dialog), which asks before removing anything.
        PlasmaExtras.MenuItem {
            text: panel.uninstallKind === "entry" ? i18n("Remove from Menu…") : i18n("Uninstall…")
            icon: panel.uninstallKind === "entry" ? "edit-delete-remove" : "delete"
            visible: panel.uninstallKind !== ""
            onClicked: {
                uninstaller.run("sh " + panel.quote(panel.uninstallScript) + " run " + panel.quote(panel.menuId));
            }
        }
        PlasmaExtras.MenuItem {
            text: panel.uninstallLabel
            enabled: false
            visible: panel.uninstallKind !== ""
        }
    }

    // How the app under the menu was installed: "pacman", "flatpak", "steam", ... or "".
    property real menuX: 0
    property real menuY: 0
    property string uninstallKind: ""
    property string uninstallLabel: ""
    readonly property string uninstallScript: Qt.resolvedUrl("../../scripts/uninstall-app.sh").toString().replace("file://", "")
    function quote(t) {
        return "'" + String(t).replace(/'/g, "'\\''") + "'";
    }
    ShellRunner {
        id: detector
        onFinished: (cmd, out) => {
            if (cmd.indexOf(panel.quote(panel.menuId)) < 0)
                return; // a reply for an earlier menu
            const f = out.trim().split("\t");
            panel.uninstallKind = f.length >= 2 ? f[0] : "";
            panel.uninstallLabel = f.length >= 2 ? f[1] : "";
            // Open only now: an open menu does not grow when items appear.
            appMenu.open(panel.menuX, panel.menuY);
        }
    }
    // Close only once the script has opened its terminal, so hiding the panel cannot cut it off.
    ShellRunner {
        id: uninstaller
        onFinished: panel.closeRequested()
    }
    // The click that dismisses the menu can land on an app below it; that click must not launch.
    property double menuClosedAt: 0
    function canLaunch() {
        return appMenu.status === PlasmaExtras.Menu.Closed && Date.now() - menuClosedAt > 400;
    }
    function showMenu(id, source, x, y) {
        menuId = id;
        uninstallKind = "";
        uninstallLabel = "";
        appMenu.visualParent = source;
        menuX = x;
        menuY = y;
        if (id !== "")
            detector.run("sh " + quote(uninstallScript) + " detect " + quote(id));
        else
            appMenu.open(x, y);
    }


        Layout.preferredWidth: Kirigami.Units.gridUnit * 42
        Layout.preferredHeight: Kirigami.Units.gridUnit * 24

        Keys.onEscapePressed: {
            if (search.text !== "")
                search.text = "";
            else
                panel.closeRequested();
        }

        // Start typing anywhere to search.
        Keys.onPressed: event => {
            // "/" jumps to the search field, as the key hint in it says.
            if (!search.activeFocus && event.text === "/") {
                search.forceActiveFocus();
                event.accepted = true;
            } else if (!search.activeFocus && event.text.length > 0 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier))) {
                search.forceActiveFocus();
                search.text += event.text;
                event.accepted = true;
            }
        }

        onVisibleChanged: if (visible) { search.text = ""; panel.view = "home"; search.forceActiveFocus(); focusLater.restart(); }

        // The popup window is not active yet when the panel first shows, so focus the
        // search again once it is (and once the show animation has settled).
        Timer {
            id: focusLater
            interval: 120
            onTriggered: search.forceActiveFocus()
        }
        // Start menu closed: clear the query so it opens fresh.
        Connections {
            target: panel.applet
            function onExpandedChanged() {
                if (!panel.applet.expanded)
                    search.text = "";
            }
        }
        Connections {
            target: panel.Window.window
            function onActiveChanged() {
                if (panel.Window.window && panel.Window.window.active && panel.visible && panel.view === "home")
                    search.forceActiveFocus();
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ---------------- rail ----------------
            // A slightly darker band with a hairline on its right edge.
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10.5
                color: Qt.alpha(Qt.darker(Kirigami.Theme.backgroundColor, 1.6), 0.35)

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: panel.hairline
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    anchors.rightMargin: Kirigami.Units.largeSpacing + 1
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.smallSpacing
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        Layout.bottomMargin: Kirigami.Units.largeSpacing
                        spacing: Kirigami.Units.largeSpacing

                        Rectangle {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.9
                            Layout.preferredHeight: width
                            radius: width / 2
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#FF9F0A" }
                                GradientStop { position: 1; color: "#FF375F" }
                            }

                            PlasmaComponents.Label {
                                anchors.centerIn: parent
                                text: (panel.realName || panel.userName || "?").charAt(0).toUpperCase()
                                color: "white"
                                font.pixelSize: panel.bodyFont
                                font.weight: Font.DemiBold
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: panel.realName || panel.userName
                                font.pixelSize: panel.bodyFont
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: panel.userName
                                opacity: 0.5
                                font.pixelSize: panel.smallFont
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // Compact row: monoline icon, label, muted count on the right.
                    component RailButton: QQC2.AbstractButton {
                        id: rb
                        property string iconName
                        property bool current: false
                        property int count: -1
                        Layout.fillWidth: true
                        implicitHeight: Kirigami.Units.gridUnit * 1.85
                        leftPadding: Kirigami.Units.smallSpacing * 2
                        rightPadding: Kirigami.Units.smallSpacing * 2
                        activeFocusOnTab: false
                        hoverEnabled: true

                        background: Rectangle {
                            radius: panel.railRadius
                            color: rb.current ? Qt.alpha(panel.accent, 0.2)
                                 : rb.hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.06) : "transparent"
                        }
                        contentItem: RowLayout {
                            spacing: Kirigami.Units.largeSpacing

                            Kirigami.Icon {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Layout.preferredWidth
                                source: rb.iconName
                                isMask: true
                                color: Kirigami.Theme.textColor
                                opacity: rb.current ? 0.95 : 0.7
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: rb.text
                                elide: Text.ElideRight
                                font.pixelSize: panel.bodyFont
                                font.weight: rb.current ? Font.Medium : Font.Normal
                            }
                            PlasmaComponents.Label {
                                visible: rb.count >= 0
                                text: rb.count
                                opacity: 0.45
                                font.pixelSize: panel.smallFont
                                font.features: { "tnum": 1 }
                            }
                        }
                    }

                    // The categories scroll; the session buttons below always stay visible.
                    QQC2.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: availableWidth
                        clip: true
                        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                        ColumnLayout {
                            width: parent.width
                            spacing: 2

                            RailButton {
                                text: i18n("All apps")
                                iconName: "view-app-grid-symbolic"
                                count: panel.appCount
                                current: panel.view === "all" && !panel.searching
                                onClicked: { search.text = ""; panel.view = "all"; }
                            }
                            // The home view: pinned apps plus recent files.
                            RailButton {
                                text: i18n("Pinned")
                                iconName: "starred-symbolic"
                                count: panel.favList.length
                                current: panel.view === "home" && !panel.searching
                                onClicked: { search.text = ""; panel.view = "home"; }
                            }

                            Repeater {
                                model: cats

                                RailButton {
                                    required property var model
                                    required property int index
                                    visible: model.display !== ""
                                    Layout.preferredHeight: visible ? implicitHeight : 0
                                    text: model.display
                                    iconName: model.decoration
                                    count: { const m = cats.modelForRow(index); return m ? m.count : -1; }
                                    current: panel.view === index && !panel.searching
                                    onClicked: { search.text = ""; panel.view = index; }
                                }
                            }
                        }
                    }

                    // Session buttons: four equal flat buttons under a hairline.
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        Layout.bottomMargin: Kirigami.Units.smallSpacing
                        color: panel.hairline
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: [
                                { icon: "system-lock-screen-symbolic", tip: i18n("Lock screen"), can: sm.canLock, act: "lock" },
                                { icon: "weather-clear-night-symbolic", tip: i18n("Sleep"), can: sm.canSuspend, act: "sleep" },
                                { icon: "system-reboot-symbolic", tip: i18n("Restart…"), can: sm.canReboot, act: "reboot" },
                                { icon: "system-shutdown-symbolic", tip: i18n("Shut down…"), can: sm.canShutdown, act: "shutdown" }
                            ]

                            Item {
                                id: slot
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: pb.implicitHeight

                                QQC2.AbstractButton {
                                    id: pb
                                    readonly property var modelData: slot.modelData
                                    readonly property bool danger: modelData.act === "reboot" || modelData.act === "shutdown"
                                    anchors.centerIn: parent
                                    implicitWidth: Math.round(Kirigami.Units.gridUnit * 1.9)
                                    implicitHeight: implicitWidth
                                    enabled: modelData.can
                                    opacity: enabled ? 1 : 0.35
                                    hoverEnabled: true
                                    activeFocusOnTab: false
                                    PlasmaComponents.ToolTip {
                                        visible: parent.hovered
                                        text: modelData.tip
                                    }

                                    onClicked: {
                                        panel.closeRequested();
                                        if (modelData.act === "lock") sm.lock();
                                        else if (modelData.act === "sleep") sm.suspend();
                                        else if (modelData.act === "reboot") sm.requestReboot();
                                        else sm.requestShutdown();
                                    }

                                    background: Rectangle {
                                        radius: panel.railRadius
                                        color: !pb.hovered ? "transparent"
                                             : pb.danger ? Qt.alpha(Kirigami.Theme.negativeTextColor, 0.16) : Qt.alpha(Kirigami.Theme.textColor, 0.08)
                                    }
                                    // A fixed small icon, so every theme's glyphs come out the same size.
                                    contentItem: Item {
                                        Kirigami.Icon {
                                            anchors.centerIn: parent
                                            width: Kirigami.Units.iconSizes.small
                                            height: width
                                            source: pb.modelData.icon
                                            isMask: true
                                            color: pb.hovered && pb.danger ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                                            opacity: pb.hovered ? 1 : 0.75
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---------------- main ----------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Search pill: icon, field, then the "/" hint and the grid/list toggle inside it.
                QQC2.TextField {
                    id: search
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                    Layout.rightMargin: Kirigami.Units.largeSpacing * 2
                    Layout.topMargin: Kirigami.Units.largeSpacing * 1.5
                    Layout.bottomMargin: Kirigami.Units.smallSpacing
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                    leftPadding: Kirigami.Units.gridUnit * 2.1
                    rightPadding: searchTrail.width + Kirigami.Units.largeSpacing * 1.5
                    placeholderText: i18n("Search apps or type a sum")
                    inputMethodHints: Qt.ImhNoPredictiveText
                    color: Kirigami.Theme.textColor
                    font.pixelSize: panel.bodyFont
                    onTextChanged: {
                        panel.searchText = text;
                        Qt.callLater(panel.updateTopApp);
                    }
                    onAccepted: {
                        if (panel.calcValue !== null)
                            panel.copyResult();
                        else if (panel.topApp)
                            panel.topApp.launched();
                        else {
                            const n = search.nextItemInFocusChain(true);
                            if (n && n !== search && n.launched)
                                n.launched();
                        }
                    }
                    Keys.onDownPressed: search.nextItemInFocusChain(true).forceActiveFocus()

                    background: Rectangle {
                        radius: panel.pillRadius
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.07)
                        border.width: 1
                        border.color: search.activeFocus ? Qt.alpha(panel.accent, 0.7) : panel.hairline
                    }

                    Kirigami.Icon {
                        anchors.left: parent.left
                        anchors.leftMargin: Kirigami.Units.largeSpacing * 1.5
                        anchors.verticalCenter: parent.verticalCenter
                        width: Kirigami.Units.iconSizes.small
                        height: width
                        source: "edit-find-symbolic"
                        isMask: true
                        color: Kirigami.Theme.textColor
                        opacity: 0.55
                    }

                    Row {
                        id: searchTrail
                        anchors.right: parent.right
                        anchors.rightMargin: Kirigami.Units.smallSpacing * 1.5
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Kirigami.Units.smallSpacing

                        KeyCap {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "/"
                            visible: search.text === ""
                        }
                        QQC2.AbstractButton {
                            id: viewToggle
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: Math.round(Kirigami.Units.gridUnit * 1.6)
                            implicitHeight: implicitWidth
                            hoverEnabled: true
                            activeFocusOnTab: false
                            onClicked: Plasmoid.configuration.launcherGridView = !panel.cfg.launcherGridView
                            PlasmaComponents.ToolTip {
                                visible: parent.hovered
                                text: panel.cfg.launcherGridView ? i18n("Show as list") : i18n("Show as grid")
                            }
                            background: Rectangle {
                                radius: panel.railRadius
                                color: viewToggle.hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.1) : "transparent"
                            }
                            contentItem: Item {
                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: Kirigami.Units.iconSizes.small
                                    height: width
                                    source: panel.cfg.launcherGridView ? "view-list-symbolic" : "view-grid-symbolic"
                                    isMask: true
                                    color: Kirigami.Theme.textColor
                                    opacity: viewToggle.hovered ? 0.9 : 0.55
                                }
                            }
                        }
                    }
                }

                QQC2.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: availableWidth
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 2

                        // Calculator, unit converter and shell results from KRunner.
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                            Layout.rightMargin: Kirigami.Units.largeSpacing * 1.5
                            visible: panel.calcValue !== null

                            Heading { text: i18n("Calculator") }
                            AppButton {
                                listMode: true
                                Layout.fillWidth: true
                                iconSource: "accessories-calculator"
                                label: "= " + panel.calcValue
                                note: i18n("Enter copies the result")
                                onLaunched: panel.copyResult()
                            }
                        }

                        // Pinned and recent, only on the home view.
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                            Layout.rightMargin: Kirigami.Units.largeSpacing * 1.5
                            visible: panel.view === "home" && !panel.searching

                            // Pinned heading with a link through to every app.
                            RowLayout {
                                Layout.fillWidth: true

                                Heading { text: i18n("Pinned") }
                                PlasmaComponents.Label {
                                    id: allLink
                                    Layout.topMargin: Kirigami.Units.largeSpacing * 1.25
                                    Layout.bottomMargin: Kirigami.Units.smallSpacing
                                    Layout.rightMargin: Kirigami.Units.smallSpacing
                                    text: i18n("All apps") + " \u203A"
                                    font.pixelSize: panel.smallFont
                                    font.weight: Font.DemiBold
                                    opacity: linkHover.hovered ? 0.95 : 0.6

                                    HoverHandler {
                                        id: linkHover
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                    TapHandler {
                                        onTapped: panel.view = "all"
                                    }
                                }
                            }
                            Flow {
                                id: pinFlow
                                Layout.fillWidth: true
                                spacing: panel.cellSpacing

                                Repeater {
                                    model: favs

                                    AppButton {
                                        required property var model
                                        required property int index
                                        listMode: !panel.cfg.launcherGridView
                                        width: listMode ? pinFlow.width : panel.cellWidth(pinFlow.width)
                                        iconSource: model.decoration
                                        label: model.display
                                        note: model.description || ""
                                        // The row's own id: the model can differ from favList in order and length.
                                        readonly property string pinId: model.favoriteId ?? panel.favList[index] ?? ""
                                        onLaunched: { if (!panel.canLaunch()) return; if (!panel.applet.launchPinned(pinId)) favs.trigger(index, "", null); panel.closeRequested(); }
                                        onMenuRequested: (src, x, y) => panel.showMenu(pinId, src, x, y)
                                    }
                                }
                            }

                            Heading { text: i18n("Recent"); visible: recent.count > 0 }
                            Repeater {
                                model: recent

                                AppButton {
                                    required property var model
                                    required property int index
                                    visible: index < 6
                                    listMode: true
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: visible ? implicitHeight : 0
                                    iconSource: model.decoration
                                    label: model.display
                                    note: model.description || ""
                                    onLaunched: { if (!panel.canLaunch()) return; recent.trigger(index, "", null); panel.closeRequested(); }
                                }
                            }
                        }

                        // Every category: one view for a category, all of them, or the search matches.
                        Repeater {
                            model: cats

                            ColumnLayout {
                                id: section
                                required property var model
                                required property int index
                                readonly property var apps: model.display !== "" ? cats.modelForRow(index) : null
                                readonly property bool wanted: panel.searching || panel.view === "all" || panel.view === index

                                visible: wanted && apps !== null && visibleCount > 0
                                Layout.fillWidth: true
                                Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                                Layout.rightMargin: Kirigami.Units.largeSpacing * 1.5
                                Layout.preferredHeight: visible ? implicitHeight : 0

                                property int visibleCount: 0
                                function recount() {
                                    let n = 0;
                                    // Count matches, not `visible`: a hidden section makes every
                                    // button invisible, so it could never be shown again.
                                    for (let i = 0; i < flow.children.length; i++) {
                                        if (flow.children[i].objectName === "app" && flow.children[i].hit)
                                            n++;
                                    }
                                    visibleCount = n;
                                }

                                Heading {
                                    text: section.model.display
                                    visible: panel.view === "all" || panel.searching
                                }
                                Flow {
                                    id: flow
                                    Layout.fillWidth: true
                                    spacing: panel.cellSpacing
                                    onChildrenChanged: section.recount()

                                    Repeater {
                                        model: section.wanted ? section.apps : null

                                        AppButton {
                                            required property var model
                                            required property int index
                                            objectName: "app"
                                            readonly property bool hit: panel.matches(model.display)
                                            visible: hit
                                            onHitChanged: section.recount()
                                            listMode: !panel.cfg.launcherGridView
                                            width: listMode ? flow.width : panel.cellWidth(flow.width)
                                            height: visible ? implicitHeight : 0
                                            iconSource: model.decoration
                                            label: model.display
                                            note: model.description || ""
                                            onLaunched: { if (!panel.canLaunch()) return; if (!panel.applet.launchPinned(model.favoriteId ?? "")) section.apps.trigger(index, "", null); panel.closeRequested(); }
                                            onMenuRequested: (src, x, y) => panel.showMenu(model.favoriteId ?? "", src, x, y)
                                        }
                                    }
                                }
                            }
                        }

                        PlasmaComponents.Label {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: Kirigami.Units.gridUnit * 3
                            visible: false
                            text: i18n("No results for “%1”", panel.query)
                            opacity: 0.6
                            function anyApp() { return false; }
                        }
                    }
                }

                // ---------------- footer ----------------
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: panel.hairline
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.8)
                    Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                    Layout.rightMargin: Kirigami.Units.largeSpacing * 1.5
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: panel.appCount > 0 ? i18n("%1 applications", panel.appCount) : ""
                        opacity: 0.5
                        font.pixelSize: panel.smallFont
                        elide: Text.ElideRight
                    }
                    KeyCap { text: i18n("Enter") }
                    PlasmaComponents.Label {
                        text: i18n("launch")
                        opacity: 0.5
                        font.pixelSize: panel.smallFont
                        Layout.rightMargin: Kirigami.Units.smallSpacing * 2
                    }
                    KeyCap { text: i18n("Esc") }
                    PlasmaComponents.Label {
                        text: i18n("close")
                        opacity: 0.5
                        font.pixelSize: panel.smallFont
                    }
                }
            }
        }
    component Heading: PlasmaComponents.Label {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.largeSpacing * 1.25
        Layout.bottomMargin: Kirigami.Units.smallSpacing
        Layout.leftMargin: Kirigami.Units.smallSpacing
        font.pixelSize: panel.smallFont
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.6
        opacity: 0.5
    }
    // A small keyboard key, for the search and footer hints.
    component KeyCap: Rectangle {
        property alias text: keyLabel.text
        implicitWidth: Math.max(implicitHeight, keyLabel.implicitWidth + Kirigami.Units.smallSpacing * 2.5)
        implicitHeight: Math.round(Kirigami.Units.gridUnit * 1.05)
        radius: Kirigami.Units.cornerRadius
        color: Qt.alpha(Kirigami.Theme.textColor, 0.08)
        border.width: 1
        border.color: panel.hairline

        PlasmaComponents.Label {
            id: keyLabel
            anchors.centerIn: parent
            font.family: "monospace"
            font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.58)
            opacity: 0.7
        }
    }
}
