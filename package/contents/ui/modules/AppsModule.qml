import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
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

    // Emitted when an icon was dragged to a new place, after the model has moved.
    signal moved()
    // Emitted after a pin or unpin; `id` is the launcher entry that changed.
    signal pinChanged(string id, bool pinned)

    property var menuApp: null
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

    // .desktop actions (jump list) of the app under the right-click menu.
    ListModel { id: actionModel }
    ShellRunner {
        id: lister
        onFinished: (cmd, out) => {
            actionModel.clear();
            for (const line of out.split("\n")) {
                const f = line.split("\t");
                if (f.length >= 3 && f[0] !== "" && f[0] !== "New Window")
                    actionModel.append({ label: f[0], iconName: f[1], exec: f.slice(2).join("\t") });
            }
            // Popup only now, so the menu is sized for the final item list.
            appMenu.popup();
        }
    }
    ShellRunner { id: launcherRunner }
    readonly property string actionsScript: Qt.resolvedUrl("../../scripts/desktop-actions.sh").toString().replace("file://", "")
    Instantiator {
        model: actionModel
        delegate: QQC2.MenuItem {
            required property string label
            required property string iconName
            required property string exec
            text: label
            icon.name: iconName
            onTriggered: launcherRunner.run("setsid -f " + exec.replace(/%[a-zA-Z%]/g, "").trim() + " >/dev/null 2>&1")
        }
        onObjectAdded: (i, o) => appMenu.insertItem(1 + i, o)
        onObjectRemoved: (i, o) => appMenu.removeItem(o)
    }

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

                    HoverHandler { id: winHover }
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
    function hideTip() {
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
        onTriggered: apps.tipVisible = apps.hoveredApp !== null && !appMenu.visible
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

    QQC2.Menu {
        id: appMenu
        popupType: QQC2.Popup.Window

        QQC2.MenuItem {
            text: i18n("New Window")
            icon.name: "window-new"
            onTriggered: apps.tasks.requestNewInstance(apps.tasks.makeModelIndex(apps.menuApp.index))
        }
        QQC2.MenuSeparator {}

        QQC2.MenuItem {
            id: pinItem
            property bool pinned: false
            Connections {
                target: appMenu
                function onAboutToShow() {
                    pinItem.pinned = apps.menuApp !== null && apps.launcherIdFor(apps.menuApp.model.LauncherUrlWithoutIcon) !== "";
                }
            }
            text: pinned ? i18n("Unpin from dock") : i18n("Pin to dock")
            icon.name: pinned ? "window-unpin" : "pin"
            onTriggered: {
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
        QQC2.MenuSeparator {
            visible: apps.menuApp !== null && !apps.menuApp.model.IsLauncher
            height: visible ? implicitHeight : 0
        }
        QQC2.MenuItem {
            readonly property bool on: apps.menuApp !== null && apps.menuApp.model.IsMinimized === true
            text: on ? i18n("Restore") : i18n("Minimize")
            icon.name: on ? "window-restore" : "window-minimize"
            visible: apps.menuApp !== null && !apps.menuApp.model.IsLauncher
            height: visible ? implicitHeight : 0
            onTriggered: apps.tasks.requestToggleMinimized(apps.tasks.makeModelIndex(apps.menuApp.index))
        }
        QQC2.MenuItem {
            readonly property bool on: apps.menuApp !== null && apps.menuApp.model.IsMaximized === true
            text: on ? i18n("Unmaximize") : i18n("Maximize")
            icon.name: on ? "window-restore" : "window-maximize"
            visible: apps.menuApp !== null && !apps.menuApp.model.IsLauncher
            height: visible ? implicitHeight : 0
            onTriggered: apps.tasks.requestToggleMaximized(apps.tasks.makeModelIndex(apps.menuApp.index))
        }
        QQC2.MenuItem {
            readonly property bool on: apps.menuApp !== null && apps.menuApp.model.IsKeepAbove === true
            text: i18n("Keep Above Others")
            icon.name: "window-keep-above"
            checkable: true
            checked: on
            visible: apps.menuApp !== null && !apps.menuApp.model.IsLauncher
            height: visible ? implicitHeight : 0
            onTriggered: apps.tasks.requestToggleKeepAbove(apps.tasks.makeModelIndex(apps.menuApp.index))
        }
        QQC2.MenuItem {
            text: i18n("Close")
            icon.name: "window-close"
            visible: apps.menuApp !== null && !apps.menuApp.model.IsLauncher
            height: visible ? implicitHeight : 0
            onTriggered: apps.tasks.requestClose(apps.tasks.makeModelIndex(apps.menuApp.index))
        }
    }

    SlideOnMove {}

    readonly property real iconSize: Math.round(height * 0.72)

    implicitWidth: row.implicitWidth

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
                    scale: reorder.active ? 1.12 : tap.pressed ? 0.94 : 1
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
                        if (button === Qt.MiddleButton || (Qt.application.keyboardModifiers & Qt.ShiftModifier))
                            apps.tasks.requestNewInstance(apps.tasks.makeModelIndex(app.index));
                        else
                            apps.activateTask(app.index, app.model);
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: {
                        apps.menuApp = app;
                        apps.tipVisible = false;
                        apps.hoveredApp = null;
                        actionModel.clear();
                        lister.run("sh '" + apps.actionsScript + "' '" + app.model.LauncherUrlWithoutIcon + "'");

                    }
                }

                // Files dropped on an icon open in that app. Hovering a drag over a
                // running app raises its window.
                DropArea {
                    anchors.fill: parent
                    onDropped: drop => {
                        if (drop.hasUrls)
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
