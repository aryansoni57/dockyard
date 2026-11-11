import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager
import org.kde.pipewire as PipeWire
import "../components"

// Pinned and running apps (docs/STYLE.md): app icons sit loose between tiles,
// with no tile behind them. A small accent dot marks a running app.
// The tasks model is created in main.qml and passed in; this module is a view.
Item {
    id: apps

    property var tasks: null
    // Icons near the pointer grow, largest under it.
    property bool magnify: false
    // Hovering a window preview fades every other window out (KWin's highlight effect).
    property bool peek: false

    // Emitted when an icon was dragged to a new place, after the model has moved.
    signal moved()
    // Emitted after a pin or unpin; `id` is the launcher entry that changed.
    signal pinChanged(string id, bool pinned)

    property var menuApp: null
    // The dock's own right-click actions (Plasmoid.contextualActions), shown at the
    // bottom of the app menu so it carries everything the dock menu has.
    property var dockActions: []

    // Pins every dropped .desktop file. True when the drop held one, so the
    // caller does not also open the files in an app.
    function pinUrls(urls) {
        let pinned = false;
        for (const u of urls) {
            const url = u.toString();
            if (!url.endsWith(".desktop"))
                continue;
            pinned = true;
            if (launcherIdFor(url) !== "")
                continue;
            tasks.requestAddLauncher(url);
            pinChanged(launcherIdFor(url), true);
        }
        return pinned;
    }

    // Pointer x over the icon row, for the magnify effect; NaN when away.
    property real pointerX: NaN
    function launcherIdFor(url) {
        // The launcherList entry that matches this app, or "" when it is not pinned.
        const pos = tasks.launcherPosition(url);
        return pos >= 0 ? tasks.launcherList[pos] : "";
    }

    // Left click: launch a launcher, cycle the windows of a group, otherwise
    // activate the window, or minimise it when it is already the active one.
    function activateTask(index, model) {
        const idx = tasks.makeModelIndex(index);
        if (model.IsLauncher) {
            tasks.requestNewInstance(idx);
            return;
        }
        const children = tasks.rowCount(idx);
        if (!model.IsGroupParent || children === 0) {
            if (model.IsMinimized || !model.IsActive)
                tasks.requestActivate(idx);
            else
                tasks.requestToggleMinimized(idx);
            return;
        }
        let next = 0;
        for (let i = 0; i < children; ++i) {
            if (tasks.data(tasks.makeModelIndex(index, i), TaskManager.AbstractTasksModel.IsActive)) {
                next = (i + 1) % children;
                break;
            }
        }
        tasks.requestActivate(tasks.makeModelIndex(index, next));
    }

    // Mouse wheel over the icons: activate the next or previous running app.
    property real wheelAccum: 0
    function cycleTasks(step) {
        const running = [];
        let current = -1;
        for (let i = 0; i < tasks.count; ++i) {
            const idx = tasks.makeModelIndex(i);
            if (tasks.data(idx, TaskManager.AbstractTasksModel.IsLauncher))
                continue;
            let active = tasks.data(idx, TaskManager.AbstractTasksModel.IsActive);
            const children = tasks.rowCount(idx);
            for (let c = 0; !active && c < children; ++c)
                active = tasks.data(tasks.makeModelIndex(i, c), TaskManager.AbstractTasksModel.IsActive);
            if (active)
                current = running.length;
            running.push(i);
        }
        if (running.length === 0)
            return;
        const n = running.length;
        const target = current < 0 ? (step > 0 ? 0 : n - 1) : (current + step + n) % n;
        tasks.requestActivate(tasks.makeModelIndex(running[target]));
    }
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            apps.wheelAccum += event.angleDelta.y;
            while (Math.abs(apps.wheelAccum) >= 120) {
                apps.cycleTasks(apps.wheelAccum > 0 ? -1 : 1);
                apps.wheelAccum -= apps.wheelAccum > 0 ? 120 : -120;
            }
        }
    }

    // .desktop actions (jump list) and recent files of the app under the right-click menu.
    // One run prints both lists, split by a "#recent" line.
    ListModel { id: actionModel }
    ListModel { id: recentModel }
    ShellRunner {
        id: lister
        onFinished: (cmd, out) => {
            actionModel.clear();
            recentModel.clear();
            let recent = false;
            for (const line of out.split("\n")) {
                if (line === "#recent") {
                    recent = true;
                    continue;
                }
                const f = line.split("\t");
                if (recent && f.length >= 2 && f[0] !== "")
                    recentModel.append({ label: f[0], url: f[1] });
                else if (!recent && f.length >= 3 && f[0] !== "" && f[0] !== "New Window")
                    actionModel.append({ label: f[0], iconName: f[1], exec: f.slice(2).join("\t") });
            }
            // Open only now, so the menu is sized for the final item list.
            appMenu.visualParent = apps.menuApp;
            appMenu.placement = apps.menuPlacement();
            appMenu.openRelative();
        }
    }
    ShellRunner { id: launcherRunner }
    readonly property string actionsScript: Qt.resolvedUrl("../../scripts/desktop-actions.sh").toString().replace("file://", "")
    readonly property string recentScript: Qt.resolvedUrl("../../scripts/recent-files.sh").toString().replace("file://", "")
    function openMenu(app) {
        menuApp = app;
        tipVisible = false;
        hoveredApp = null;
        const url = "'" + String(app.model.LauncherUrlWithoutIcon).replace(/'/g, "") + "'";
        lister.run("sh '" + actionsScript + "' " + url + "; echo '#recent'; sh '" + recentScript + "' " + url);
    }
    // The menu opens away from the screen edge the dock sits on.
    function menuPlacement() {
        switch (Plasmoid.location) {
        case PlasmaCore.Types.TopEdge:
            return PlasmaExtras.Menu.BottomPosedLeftAlignedPopup;
        case PlasmaCore.Types.LeftEdge:
            return PlasmaExtras.Menu.RightPosedTopAlignedPopup;
        case PlasmaCore.Types.RightEdge:
            return PlasmaExtras.Menu.LeftPosedTopAlignedPopup;
        default:
            return PlasmaExtras.Menu.TopPosedLeftAlignedPopup;
        }
    }
    // The launcher's desktop file id, as "org.kde.kate.desktop"; "" for other urls.
    function desktopId(url) {
        const u = String(url);
        return u.startsWith("applications:") ? u.substring(13) : "";
    }
    function menuIdx() {
        return tasks.makeModelIndex(menuApp.index);
    }
    // The click that dismisses the menu can land on an icon below it; that click must not activate.
    property double menuClosedAt: 0
    readonly property bool menuOpen: appMenu.status !== PlasmaExtras.Menu.Closed
    readonly property bool menuRunning: menuApp !== null && !menuApp.model.IsLauncher

    TaskManager.VirtualDesktopInfo { id: desktops }

    // Hover card: app name plus a live thumbnail of each window.
    component TipCard: Item {
        id: card
        property var entry: null
        property var windows: []
        property bool shown: false

        function refresh() {
            const a = entry;
            const out = [];
            if (a && !a.model.IsLauncher) {
                const R = TaskManager.AbstractTasksModel;
                const idx = apps.tasks.makeModelIndex(a.index);
                const n = apps.tasks.rowCount(idx);
                if (a.model.IsGroupParent && n > 0) {
                    for (let c = 0; c < n && c < 4; ++c) {
                        const ci = apps.tasks.makeModelIndex(a.index, c);
                        const ids = apps.tasks.data(ci, R.WinIdList);
                        out.push({ title: apps.tasks.data(ci, 0) || "", wid: ids && ids.length ? String(ids[0]) : "", child: c });
                    }
                } else {
                    const ids = apps.tasks.data(idx, R.WinIdList);
                    out.push({ title: apps.tasks.data(idx, 0) || "", wid: ids && ids.length ? String(ids[0]) : "", child: -1 });
                }
            }
            windows = out;
        }

        // The card stays open while the pointer is on it.
        HoverHandler {
            onHoveredChanged: apps.cardHovered(hovered)
        }

        implicitWidth: layout.implicitWidth + Kirigami.Units.largeSpacing * 2
        implicitHeight: layout.implicitHeight + Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            id: layout
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: card.entry ? (card.entry.model.AppName || card.entry.model.display || "") : ""
                font.bold: true
                Layout.maximumWidth: Kirigami.Units.gridUnit * 14
                elide: Text.ElideRight
            }
            RowLayout {
              spacing: Kirigami.Units.smallSpacing
              Repeater {
                model: card.shown ? card.windows : []
                delegate: Item {
                    id: win
                    required property var modelData
                    implicitWidth: col.implicitWidth
                    implicitHeight: col.implicitHeight

                    HoverHandler {
                        id: winHover
                        onHoveredChanged: apps.peekWindow(hovered ? win.modelData.wid : "")
                    }
                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.margins: -Kirigami.Units.smallSpacing
                        radius: Kirigami.Units.cornerRadius
                        color: Qt.alpha(Kirigami.Theme.highlightColor, 0.25)
                        border.width: 1
                        border.color: Qt.alpha(Kirigami.Theme.highlightColor, 0.7)
                        opacity: winHover.hovered ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    // Click raises that window; middle click closes it.
                    TapHandler {
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onTapped: (eventPoint, button) => {
                            const a = card.entry;
                            if (!a)
                                return;
                            const idx = win.modelData.child >= 0
                                ? apps.tasks.makeModelIndex(a.index, win.modelData.child)
                                : apps.tasks.makeModelIndex(a.index);
                            if (button === Qt.MiddleButton)
                                apps.tasks.requestClose(idx);
                            else
                                apps.tasks.requestActivate(idx);
                            apps.tipVisible = false;
                            apps.hoveredApp = null;
                        }
                    }

                    ColumnLayout {
                    id: col
                    anchors.fill: parent
                    spacing: 2
                    Rectangle {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 8
                        radius: Kirigami.Units.cornerRadius
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.08)
                        clip: true

                        TaskManager.ScreencastingRequest {
                            id: cast
                            uuid: win.modelData.wid
                        }
                        PipeWire.PipeWireSourceItem {
                            id: pw
                            readonly property real ratio: streamSize.height > 0 ? streamSize.width / streamSize.height : 1.6
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height * ratio)
                            height: width / ratio
                            nodeId: cast.nodeId
                            objectSerial: cast.objectSerial
                            visible: cast.nodeId > 0
                        }
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: Kirigami.Units.iconSizes.large
                            height: width
                            source: card.entry ? card.entry.model.decoration : ""
                            visible: !pw.visible
                        }
                    }
                    QQC2.Label {
                        text: win.modelData.title
                        elide: Text.ElideRight
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 14
                        visible: text !== ""
                        opacity: 0.8
                    }
                    }
                }
              }
            }
        }
    }

    // The icon under the pointer. Cleared after a short delay so moving between
    // icons does not close and reopen the card.
    property var hoveredApp: null
    property bool tipVisible: false
    onTipVisibleChanged: if (!tipVisible) peekWindow("")
    ShellRunner { id: peekRunner }
    property string peekedWid: ""
    function peekWindow(wid) {
        if (wid === peekedWid || (!peek && wid !== ""))
            return;
        peekedWid = wid;
        peekRunner.run("busctl --user call org.kde.KWin /org/kde/KWin/HighlightWindow org.kde.KWin.HighlightWindow highlightWindows as "
                       + (wid !== "" ? "1 '" + wid.replace(/'/g, "") + "'" : "0"));
    }
    function hideTip() {
        peekWindow("");
        tipOpen.stop();
        hoverClear.stop();
        tipVisible = false;
        hoveredApp = null;
    }
    // The thumbnail card must not live while icons are dragged or removed: its
    // PipeWire items outlive the delegate they were opened for and crash plasmashell.
    property bool dragging: false
    Connections {
        target: apps.tasks
        ignoreUnknownSignals: true
        function onRowsAboutToBeRemoved() { apps.hideTip(); }
        function onRowsAboutToBeMoved() { apps.hideTip(); }
    }
    function setHovered(a, on) {
        if (dragging)
            return;
        if (on) {
            hoverClear.stop();
            hoveredApp = a;
            if (!tipVisible)
                tipOpen.restart();
        } else if (hoveredApp === a) {
            hoverClear.restart();
        }
    }
    function cardHovered(on) {
        if (on)
            hoverClear.stop();
        else
            hoverClear.restart();
    }
    Timer {
        id: tipOpen
        interval: Kirigami.Units.toolTipDelay
        onTriggered: apps.tipVisible = apps.hoveredApp !== null && appMenu.status === PlasmaExtras.Menu.Closed
    }
    Timer {
        id: hoverClear
        interval: 250
        onTriggered: {
            tipOpen.stop();
            apps.tipVisible = false;
            apps.hoveredApp = null;
        }
    }
    TipCard {
        id: card
        entry: apps.hoveredApp
        shown: apps.tipVisible
        onEntryChanged: refresh()
    }
    PlasmaCore.Dialog {
        visualParent: apps.hoveredApp
        location: Plasmoid.location
        type: PlasmaCore.Dialog.Tooltip
        flags: Qt.WindowDoesNotAcceptFocus | Qt.ToolTip
        hideOnWindowDeactivate: false
        visible: apps.tipVisible && apps.hoveredApp !== null
        mainItem: card
    }

    // The app menu is a native Plasma menu (PlasmaExtras.Menu, a QMenu), so it looks
    // exactly like the dock's own right-click menu and the stock Task Manager's.
    PlasmaExtras.Menu {
        id: appMenu
        onStatusChanged: if (status === PlasmaExtras.Menu.Closed) apps.menuClosedAt = Date.now()

        PlasmaExtras.MenuItem {
            text: i18n("New Window")
            icon: "window-new"
            onClicked: apps.tasks.requestNewInstance(apps.menuIdx())
        }
        // Jump list actions go here.
        PlasmaExtras.MenuItem {
            id: recentItem
            text: i18n("Recent Files")
            icon: "document-open-recent"
            visible: recentModel.count > 0
            readonly property PlasmaExtras.Menu sub: PlasmaExtras.Menu {
                visualParent: recentItem.action
            }
        }
        PlasmaExtras.MenuItem { id: actionsEnd; separator: true }

        PlasmaExtras.MenuItem {
            readonly property bool pinned: appMenu.status !== PlasmaExtras.Menu.Closed && apps.menuApp !== null
                && apps.launcherIdFor(apps.menuApp.model.LauncherUrlWithoutIcon) !== ""
            text: pinned ? i18n("Unpin from dock") : i18n("Pin to dock")
            icon: pinned ? "window-unpin" : "pin"
            onClicked: {
                const url = apps.menuApp.model.LauncherUrlWithoutIcon;
                if (pinned) {
                    const id = apps.launcherIdFor(url);
                    apps.tasks.requestRemoveLauncher(url);
                    apps.pinChanged(id, false);
                } else {
                    apps.tasks.requestAddLauncher(url);
                    apps.pinChanged(apps.launcherIdFor(url), true);
                }
            }
        }
        PlasmaExtras.MenuItem {
            text: i18n("Edit Application…")
            icon: "kmenuedit"
            visible: apps.menuApp !== null && apps.desktopId(apps.menuApp.model.LauncherUrlWithoutIcon) !== ""
            onClicked: launcherRunner.run("setsid -f kmenuedit / '" + apps.desktopId(apps.menuApp.model.LauncherUrlWithoutIcon).replace(/'/g, "") + "' >/dev/null 2>&1")
        }

        PlasmaExtras.MenuItem {
            id: desktopItem
            text: i18n("Move to Desktop")
            icon: "virtual-desktops"
            visible: apps.menuRunning && desktops.numberOfDesktops > 1
            readonly property PlasmaExtras.Menu sub: PlasmaExtras.Menu {
                id: desktopMenu
                visualParent: desktopItem.action

                PlasmaExtras.MenuItem {
                    text: i18n("All Desktops")
                    checkable: true
                    checked: apps.menuApp !== null && apps.menuApp.model.IsOnAllVirtualDesktops === true
                    onClicked: apps.tasks.requestVirtualDesktops(apps.menuIdx(), checked ? [] : [desktops.currentDesktop])
                }
                PlasmaExtras.MenuItem { separator: true }
                PlasmaExtras.MenuItem { id: desktopsEnd; separator: true }
                PlasmaExtras.MenuItem {
                    text: i18n("New Desktop")
                    icon: "list-add"
                    onClicked: apps.tasks.requestNewVirtualDesktop(apps.menuIdx())
                }
            }
        }

        // Window controls, like the stock Task Manager's More submenu.
        PlasmaExtras.MenuItem {
            id: moreItem
            text: i18n("More")
            icon: "view-more-symbolic"
            visible: apps.menuRunning
            readonly property PlasmaExtras.Menu sub: PlasmaExtras.Menu {
                visualParent: moreItem.action

                PlasmaExtras.MenuItem {
                    text: i18n("Move")
                    icon: "transform-move"
                    enabled: apps.menuRunning && apps.menuApp.model.IsMovable !== false
                    onClicked: apps.tasks.requestMove(apps.menuIdx())
                }
                PlasmaExtras.MenuItem {
                    text: i18n("Resize")
                    icon: "transform-scale"
                    enabled: apps.menuRunning && apps.menuApp.model.IsResizable !== false
                    onClicked: apps.tasks.requestResize(apps.menuIdx())
                }
                PlasmaExtras.MenuItem {
                    readonly property bool on: apps.menuRunning && apps.menuApp.model.IsMinimized === true
                    text: on ? i18n("Restore") : i18n("Minimize")
                    icon: on ? "window-restore" : "window-minimize"
                    enabled: apps.menuRunning && apps.menuApp.model.IsMinimizable !== false
                    onClicked: apps.tasks.requestToggleMinimized(apps.menuIdx())
                }
                PlasmaExtras.MenuItem {
                    text: i18n("Maximize")
                    icon: "window-maximize"
                    checkable: true
                    checked: apps.menuRunning && apps.menuApp.model.IsMaximized === true
                    enabled: apps.menuRunning && apps.menuApp.model.IsMaximizable !== false
                    onClicked: apps.tasks.requestToggleMaximized(apps.menuIdx())
                }
                PlasmaExtras.MenuItem {
                    text: i18n("Fullscreen")
                    icon: "view-fullscreen"
                    checkable: true
                    checked: apps.menuRunning && apps.menuApp.model.IsFullScreen === true
                    enabled: apps.menuRunning && apps.menuApp.model.IsFullScreenable !== false
                    onClicked: apps.tasks.requestToggleFullScreen(apps.menuIdx())
                }
                PlasmaExtras.MenuItem {
                    text: i18n("Shade")
                    icon: "window-shade"
                    checkable: true
                    checked: apps.menuRunning && apps.menuApp.model.IsShaded === true
                    enabled: apps.menuRunning && apps.menuApp.model.IsShadeable !== false
                    onClicked: apps.tasks.requestToggleShaded(apps.menuIdx())
                }
                PlasmaExtras.MenuItem { separator: true }
                PlasmaExtras.MenuItem {
                    text: i18n("Keep Above Others")
                    icon: "window-keep-above"
                    checkable: true
                    checked: apps.menuRunning && apps.menuApp.model.IsKeepAbove === true
                    onClicked: apps.tasks.requestToggleKeepAbove(apps.menuIdx())
                }
                PlasmaExtras.MenuItem {
                    text: i18n("Keep Below Others")
                    icon: "window-keep-below"
                    checkable: true
                    checked: apps.menuRunning && apps.menuApp.model.IsKeepBelow === true
                    onClicked: apps.tasks.requestToggleKeepBelow(apps.menuIdx())
                }
            }
        }
        PlasmaExtras.MenuItem {
            text: apps.menuRunning && apps.menuApp.model.IsGroupParent === true ? i18n("Close All") : i18n("Close")
            icon: "window-close"
            visible: apps.menuRunning
            onClicked: apps.tasks.requestClose(apps.menuIdx())
        }

        PlasmaExtras.MenuItem { id: dockStart; separator: true }
        // The dock's own actions go here.
        PlasmaExtras.MenuItem {
            id: configureItem
            readonly property var act: Plasmoid.internalAction("configure")
            text: act ? act.text : ""
            icon: "configure"
            visible: act !== null && act.enabled
            onClicked: act.trigger()
        }
        PlasmaExtras.MenuItem {
            readonly property var act: Plasmoid.containment ? Plasmoid.containment.internalAction("add widgets") : null
            text: act ? act.text : ""
            icon: "view-app-grid-symbolic"
            visible: act !== null && act.enabled
            onClicked: act.trigger()
        }
        PlasmaExtras.MenuItem {
            readonly property var act: Plasmoid.containment ? Plasmoid.containment.internalAction("configure") : null
            text: act ? act.text : ""
            icon: "document-edit"
            visible: act !== null && act.enabled
            onClicked: act.trigger()
        }
    }

    // Dynamic entries, each added before its anchor item.
    Instantiator {
        model: actionModel
        delegate: PlasmaExtras.MenuItem {
            required property string label
            required property string iconName
            required property string exec
            text: label
            icon: iconName
            onClicked: launcherRunner.run("setsid -f " + exec.replace(/%[a-zA-Z%]/g, "").trim() + " >/dev/null 2>&1")
        }
        onObjectAdded: (i, o) => appMenu.addMenuItem(o, recentItem)
        onObjectRemoved: (i, o) => appMenu.removeMenuItem(o)
    }
    Instantiator {
        model: recentModel
        delegate: PlasmaExtras.MenuItem {
            required property string label
            required property string url
            text: label
            onClicked: apps.tasks.requestOpenUrls(apps.menuIdx(), [url])
        }
        onObjectAdded: (i, o) => recentItem.sub.addMenuItem(o)
        onObjectRemoved: (i, o) => recentItem.sub.removeMenuItem(o)
    }
    Instantiator {
        model: desktops.numberOfDesktops
        delegate: PlasmaExtras.MenuItem {
            required property int index
            readonly property var desktopId: desktops.desktopIds[index]
            text: (index + 1) + ". " + (desktops.desktopNames[index] || "")
            checkable: true
            checked: apps.menuRunning && apps.menuApp.model.IsOnAllVirtualDesktops !== true
                && (apps.menuApp.model.VirtualDesktops || []).indexOf(desktopId) >= 0
            onClicked: apps.tasks.requestVirtualDesktops(apps.menuIdx(), [desktopId])
        }
        onObjectAdded: (i, o) => desktopMenu.addMenuItem(o, desktopsEnd)
        onObjectRemoved: (i, o) => desktopMenu.removeMenuItem(o)
    }
    Instantiator {
        model: apps.dockActions
        delegate: PlasmaExtras.MenuItem {
            required property var modelData
            text: modelData.text
            icon: modelData.icon && modelData.icon.name ? modelData.icon.name : ""
            onClicked: modelData.trigger()
        }
        onObjectAdded: (i, o) => appMenu.addMenuItem(o, configureItem)
        onObjectRemoved: (i, o) => appMenu.removeMenuItem(o)
    }

    SlideOnMove {}

    readonly property real iconSize: Math.round(height * 0.72)

    implicitWidth: row.implicitWidth

    HoverHandler {
        enabled: apps.magnify
        onPointChanged: apps.pointerX = hovered && !apps.dragging ? point.position.x - row.x : NaN
        onHoveredChanged: if (!hovered) apps.pointerX = NaN
    }

    // Drops between icons, or on an empty row: pin dropped .desktop files.
    DropArea {
        anchors.fill: parent
        keys: ["text/uri-list"]
        onDropped: drop => {
            if (drop.hasUrls && apps.pinUrls(drop.urls))
                drop.accept(Qt.CopyAction);
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Kirigami.Units.smallSpacing

        Repeater {
            model: apps.tasks

            // Invisible delegates are skipped by Row, so Row is used instead of RowLayout.
            Item {
                id: app

                required property int index
                required property var model

                width: apps.iconSize
                height: apps.height

                // 1 far from the pointer, up to 1.25 right under it. It grows from the centre,
                // which keeps it inside the dock height.
                readonly property real zoom: {
                    if (!apps.magnify || isNaN(apps.pointerX))
                        return 1;
                    const d = Math.abs(apps.pointerX - (x + width / 2)) / (apps.iconSize * 1.6);
                    return 1 + 0.25 * Math.max(0, 1 - d * d);
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width * 0.24
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.08)
                    visible: hover.hovered
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width * 0.24
                    color: Qt.alpha(Kirigami.Theme.highlightColor, 0.35)
                    visible: app.model.IsDemandingAttention === true
                    SequentialAnimation on opacity {
                        running: app.model.IsDemandingAttention === true
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.3; to: 1; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1; to: 0.3; duration: 700; easing.type: Easing.InOutSine }
                    }
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: apps.iconSize
                    height: apps.iconSize
                    source: app.model.decoration
                    scale: (reorder.active ? 1.12 : tap.pressed ? 0.94 : 1) * app.zoom
                    opacity: reorder.active ? 0.8 : 1

                    Behavior on scale {
                        NumberAnimation { duration: 80 }
                    }
                }

                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: Kirigami.Theme.highlightColor
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.round(parent.height - (parent.height - apps.iconSize) / 4 - 2)
                    visible: !app.model.IsLauncher
                }

                SlideOnMove {}

                HoverHandler {
                    id: hover
                    onHoveredChanged: apps.setHovered(app, hovered)
                }

                // Drag one icon sideways to reorder it. It swaps with a neighbour once the
                // pointer crosses that neighbour's midpoint. This handler is exclusive, so
                // the dock-level tile reorder never sees a press that starts on an icon.
                DragHandler {
                    id: reorder
                    target: null
                    acceptedButtons: Qt.LeftButton
                    dragThreshold: Kirigami.Units.gridUnit * 0.6

                    onActiveChanged: {
                        apps.dragging = active;
                        if (active)
                            apps.hideTip();
                        else {
                            // move() only reorders the view; this writes the new pin
                            // order into launcherList, which main.qml then saves.
                            apps.tasks.syncLaunchers();
                            apps.moved();
                        }
                    }
                    onCentroidChanged: {
                        if (!active)
                            return;
                        const p = app.mapToItem(row, centroid.position.x, centroid.position.y);
                        const other = row.childAt(p.x, p.y);
                        if (!other || other === app || other.index === undefined)
                            return;
                        const mid = other.x + other.width / 2;
                        const forward = other.x > app.x;
                        if (forward ? p.x <= mid : p.x >= mid)
                            return;
                        apps.tasks.move(app.index, other.index);
                    }
                }

                TapHandler {
                    id: tap
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onTapped: (eventPoint, button) => {
                        if (apps.menuOpen || Date.now() - apps.menuClosedAt < 400)
                            return;
                        if (button === Qt.MiddleButton || (Qt.application.keyboardModifiers & Qt.ShiftModifier))
                            apps.tasks.requestNewInstance(apps.tasks.makeModelIndex(app.index));
                        else
                            apps.activateTask(app.index, app.model);
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: {
                        apps.openMenu(app);

                    }
                }

                // Files dropped on an icon open in that app; .desktop files are pinned instead. Hovering a drag over a
                // running app raises its window.
                DropArea {
                    anchors.fill: parent
                    onDropped: drop => {
                        if (drop.hasUrls && !apps.pinUrls(drop.urls))
                            apps.tasks.requestOpenUrls(apps.tasks.makeModelIndex(app.index), drop.urls);
                        drop.accept();
                    }
                    onContainsDragChanged: {
                        if (containsDrag && !app.model.IsLauncher)
                            raiseTimer.restart();
                        else
                            raiseTimer.stop();
                    }
                    Timer {
                        id: raiseTimer
                        interval: 600
                        onTriggered: apps.tasks.requestActivate(apps.tasks.makeModelIndex(app.index))
                    }
                }
            }
        }
    }
}
