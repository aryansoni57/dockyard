import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.private.mpris as Mpris
import org.kde.taskmanager as TaskManager
import "modules" as Modules
import "components"
import "launcher" as Launcher
import "components/progress.js" as Progress

// Data sources live here, once, and are shared by every module.
// Modules stay dumb views; cross-module automations hook in at this level.
// Visual rules: docs/STYLE.md.
PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration

    property date now: new Date()
    readonly property var player: mpris.currentPlayer
    readonly property bool playing: player !== null
        && player.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property bool showMedia: cfg.showMedia && player !== null
    // On the desktop there is no panel, so the widget draws its own dock bar.
    readonly property bool onDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar

    // Always show the tile row; the detail view opens as a popup.
    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: onDesktop ? PlasmaCore.Types.NoBackground : PlasmaCore.Types.DefaultBackground

    // Fire on each minute boundary instead of polling every second.
    Timer {
        running: root.cfg.showClock || root.cfg.showCalendar || root.cfg.showMonthProgress || root.cfg.showDayProgress
                 || root.cfg.showYearProgress || root.cfg.showDate || root.cfg.showDayNumber
        repeat: true
        triggeredOnStart: true
        interval: 60000 - (Date.now() % 60000) + 50
        onTriggered: {
            root.now = new Date();
            interval = 60000 - (Date.now() % 60000) + 50;
        }
    }

    Sensors.Sensor {
        id: cpuSensor
        sensorId: root.cfg.showStats || root.cfg.showTemperature ? "cpu/all/usage" : ""
        updateRateLimit: root.cfg.statsInterval
    }

    Sensors.Sensor {
        id: memSensor
        sensorId: root.cfg.showStats || root.cfg.showTemperature ? "memory/physical/usedPercent" : ""
        updateRateLimit: root.cfg.statsInterval
    }

    readonly property string batteryPath: "power/" + (cfg.batteryDevice || "SerialNumber")

    Sensors.Sensor {
        id: tempSensor
        sensorId: root.cfg.showTemperature ? "cpu/all/averageTemperature" : ""
        updateRateLimit: root.cfg.statsInterval
    }
    Sensors.Sensor {
        id: netDownSensor
        sensorId: root.cfg.showNetwork ? "network/all/download" : ""
        updateRateLimit: root.cfg.statsInterval
    }
    Sensors.Sensor {
        id: netUpSensor
        sensorId: root.cfg.showNetwork ? "network/all/upload" : ""
        updateRateLimit: root.cfg.statsInterval
    }
    Sensors.Sensor {
        id: diskUsedSensor
        sensorId: root.cfg.showStorage ? "disk/all/used" : ""
        updateRateLimit: 30000
    }
    Sensors.Sensor {
        id: diskTotalSensor
        sensorId: root.cfg.showStorage ? "disk/all/total" : ""
        updateRateLimit: 30000
    }
    Sensors.Sensor {
        id: batteryPercentSensor
        sensorId: root.cfg.showBattery ? root.batteryPath + "/chargePercentage" : ""
        updateRateLimit: 10000
    }
    Sensors.Sensor {
        id: batteryRateSensor
        sensorId: root.cfg.showBattery ? root.batteryPath + "/chargeRate" : ""
        updateRateLimit: 10000
    }

    // A battery sensor with no value means no battery (desktop PC): hide the tile.
    readonly property bool hasBattery: cfg.showBattery && batteryPercentSensor.value !== undefined

    // Todos live in the widget config; popup and tile both edit it through here.
    function todoItems() {
        try {
            const list = JSON.parse(cfg.todosJson);
            return Array.isArray(list) ? list : [];
        } catch (e) {
            return [];
        }
    }
    function addTodo(text) {
        const t = text.trim();
        if (t === "") return;
        const list = todoItems();
        list.push({ text: t, done: false });
        Plasmoid.configuration.todosJson = JSON.stringify(list);
    }
    function clearDoneTodos() {
        Plasmoid.configuration.todosJson = JSON.stringify(todoItems().filter(i => !i.done));
    }

    Mpris.Mpris2Model {
        id: mpris
    }

    // Pinned apps and running windows. Created only when shown.
    // Pinned apps come from the Task Manager panel applet when asked (and found);
    // otherwise from the appLaunchers setting.
    property string taskManagerLaunchers: ""
    readonly property bool followTaskManager: cfg.showApps && cfg.appsFromTaskManager
    readonly property var appLaunchers: (followTaskManager && taskManagerLaunchers !== ""
        ? taskManagerLaunchers : cfg.appLaunchers).split(",").map(s => s.trim()).filter(s => s !== "")

    ShellRunner {
        id: launcherReader
        onFinished: (cmd, out) => {
            const v = out.trim();
            if (v !== root.taskManagerLaunchers)
                root.taskManagerLaunchers = v;
        }
    }
    Timer {
        interval: 30000
        repeat: true
        triggeredOnStart: true
        running: root.followTaskManager
        onTriggered: launcherReader.run("sh '" + Qt.resolvedUrl("../scripts/taskmanager-launchers.sh").toString().replace("file://", "") + "'")
    }
    Loader {
        id: tasksLoader
        active: root.cfg.showApps
        sourceComponent: Component {
            TaskManager.TasksModel {
                launcherList: root.appLaunchers
                groupMode: TaskManager.TasksModel.GroupApplications
                sortMode: TaskManager.TasksModel.SortManual
                separateLaunchers: false
                launchInPlace: true
                hideActivatedLaunchers: true
                filterByVirtualDesktop: false
                filterByScreen: false
                filterByActivity: false
            }
        }
    }

    // Shared by the clock and weather tiles. Polls only while one of them is shown.
    WeatherSource {
        id: sharedWeather
        active: root.cfg.showClock || root.cfg.showWeather
                || (root.cfg.showClockStyle && (root.cfg.clockStyle === "week" || root.cfg.clockStyle === "today"))
        latitude: Number(root.cfg.latitude) || 0
        longitude: Number(root.cfg.longitude) || 0
        fahrenheit: root.cfg.fahrenheit
    }

    // Wi-Fi, Bluetooth, Do Not Disturb, Night Light, Mute. Created only when shown,
    // so the Brightness plugin import is not loaded otherwise.
    Loader {
        id: togglesLoader
        active: root.cfg.showToggles
        // Loaded by URL so a missing plugin only fails this loader, not the applet.
        source: "components/ToggleSource.qml"
        onLoaded: item.active = true
    }
    Binding {
        target: togglesLoader.item
        property: "keys"
        value: root.cfg.toggleItems.split(",").map(s => s.trim()).filter(s => s !== "")
        when: togglesLoader.item !== null
    }

    ShellRunner {
        id: shell
    }

    // Run a command detached, so a long-lived app never blocks the runner.
    function launch(cmd) {
        shell.run("(" + cmd + ") >/dev/null 2>&1 &");
    }

    // Dock context menu (demo video 0:57): Plasma adds Configure and Remove itself.
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Task Manager")
            icon.name: "utilities-system-monitor"
            onTriggered: shell.run("plasma-systemmonitor")
        },
        PlasmaCore.Action {
            text: i18n("System Settings")
            icon.name: "preferences-system"
            onTriggered: shell.run("systemsettings")
        }
    ]

    // Tile order: config holds comma-separated tile keys. Tiles sit in one
    // GridLayout row and each takes its column from its place in this list;
    // keys missing from the list keep their natural order after the listed ones.
    readonly property var tileKeys: ["start", "stats", "media", "apps", "weather", "pomodoro", "timer",
        "stopwatch", "worldclocks", "todos", "temperature", "network", "storage", "quicktoggles",
        "volume", "recyclebin", "screenshot", "notes", "monthprogress", "dayprogress",
        "yearprogress", "date", "daynumber", "battery", "tray", "calendar", "clockstyle", "clock"]
    property var dragOrder: null // full order while a tile is being dragged
    readonly property var order: dragOrder !== null
        ? dragOrder : cfg.tileOrder.split(",").map(k => k.trim()).filter(k => k !== "")
    function colOf(key) {
        const i = order.indexOf(key);
        // Start sits first until it is dragged somewhere else.
        if (i < 0 && key === "start")
            return 0;
        return i >= 0 ? i + 1 : 100 + tileKeys.indexOf(key);
    }
    function fullOrder() {
        return tileKeys.slice().sort((a, b) => colOf(a) - colOf(b));
    }

    // The popup shows either the info panel (most tiles) or the launcher (Start tile).
    property string popupMode: "info"
    // The Meta key: plasmashell activates the applet that provides the launcher menu.
    activationTogglesExpanded: false
    Plasmoid.onActivated: togglePopup("launcher")

    function togglePopup(mode) {
        if (expanded && popupMode === mode) {
            expanded = false;
            return;
        }
        popupMode = mode;
        expanded = true;
    }

    Plasmoid.icon: "preferences-desktop-panel"
    toolTipMainText: Qt.formatDate(root.now, Qt.locale().dateFormat(Locale.LongFormat))
    toolTipSubText: root.playing ? i18n("Playing: %1", root.player.track) : ""

    compactRepresentation: Item {
        id: dock

        // Bar padding around the tiles: thin inside a panel, roomier on the desktop.
        readonly property real inset: root.onDesktop ? Kirigami.Units.smallSpacing * 1.5 : 2

        // Preferred is the full row; the minimum is small so a crowded dock
        // scrolls sideways instead of overflowing the panel.
        Layout.minimumWidth: Kirigami.Units.gridUnit * 6
        Layout.preferredWidth: row.implicitWidth + (root.onDesktop ? inset * 2 : 0)
        Layout.minimumHeight: root.onDesktop ? Kirigami.Units.gridUnit * 3 : -1

        // On the desktop the bar keeps a fixed dock height, centered in the
        // widget's area, instead of stretching tiles to the whole widget.
        Item {
            id: bar
            anchors.centerIn: parent
            // Never wider than the widget, or the overflow is clipped instead of scrollable.
            width: root.onDesktop ? Math.min(row.implicitWidth + dock.inset * 2, dock.width) : parent.width
            height: root.onDesktop ? Kirigami.Units.gridUnit * 3 : parent.height

            // Glass bar (docs/STYLE.md, "Glass material"). Panels draw their own.
            Rectangle {
                visible: root.onDesktop
                anchors.fill: parent
                radius: height * 0.25
                color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.55)
                border.width: 1
                border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
            }
        }

        // The dock scrolls sideways when it is wider than its space: wheel or
        // touchpad anywhere on it, or the edge buttons.
        readonly property bool scrollable: scroller.contentWidth > scroller.width + 1

        WheelHandler {
            target: null
            enabled: dock.scrollable
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const pd = event.pixelDelta.x !== 0 ? event.pixelDelta.x : event.pixelDelta.y;
                const ad = event.angleDelta.x !== 0 ? event.angleDelta.x : event.angleDelta.y;
                // Wheel up / away scrolls toward the start.
                scroller.scrollBy(-(pd !== 0 ? pd : ad));
            }
        }

        Flickable {
            id: scroller
            anchors.fill: bar
            anchors.margins: root.onDesktop ? dock.inset : 0
            anchors.topMargin: dock.inset
            anchors.bottomMargin: dock.inset
            clip: contentWidth > width
            interactive: false // dragging a tile reorders; the wheel scrolls
            contentWidth: row.implicitWidth
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            // Smooth glide for wheel steps and the edge buttons.
            Behavior on contentX {
                enabled: !scroller.dragging && !scroller.flicking
                NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
            }

            function scrollBy(d) {
                contentX = Math.max(0, Math.min(contentWidth - width, contentX + d));
            }

            GridLayout {
                id: row
                rows: 1
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: 0
                width: Math.max(implicitWidth, scroller.width)
                height: scroller.height

                Modules.StartModule {
                    objectName: "start"
                    hoverName: i18n("Start")
                    Layout.column: root.colOf("start")
                    Layout.fillHeight: true
                    visible: root.cfg.showStart
                    onClicked: root.togglePopup("launcher")
                }
                Modules.StatsModule {
                    objectName: "stats"
                    hoverName: i18n("System Stats")
                    Layout.column: root.colOf("stats")
                    Layout.fillHeight: true
                    visible: root.cfg.showStats
                    cpu: cpuSensor.value ?? 0
                    mem: memSensor.value ?? 0
                    onClicked: root.launch("plasma-systemmonitor")
                }
                Modules.MediaModule {
                    objectName: "media"
                    hoverName: i18n("Now Playing")
                    Layout.column: root.colOf("media")
                    Layout.fillHeight: true
                    visible: root.showMedia
                    player: root.player
                    playing: root.playing
                    onClicked: root.togglePopup("info")
                }
                Modules.AppsModule {
                    objectName: "apps"
                    Layout.column: root.colOf("apps")
                    Layout.fillHeight: true
                    visible: root.cfg.showApps
                    tasks: tasksLoader.item
                    onMoved: {
                        // A drag only sticks when the list is ours; the Task Manager owns its own.
                        if (!root.followTaskManager)
                            Plasmoid.configuration.appLaunchers = tasksLoader.item.launcherList.join(",");
                    }
                }
                Modules.WeatherModule {
                    objectName: "weather"
                    hoverName: i18n("Weather")
                    Layout.column: root.colOf("weather")
                    Layout.fillHeight: true
                    visible: root.cfg.showWeather
                    weatherSource: sharedWeather
                    onClicked: {
                        const lat = Number(root.cfg.latitude), lon = Number(root.cfg.longitude);
                        if (lat === 0 && lon === 0)
                            Plasmoid.internalAction("configure").trigger();
                        else
                            root.launch("xdg-open https://wttr.in/" + lat + "," + lon);
                    }
                }
                Modules.PomodoroModule {
                    objectName: "pomodoro"
                    hoverName: i18n("Pomodoro")
                    Layout.column: root.colOf("pomodoro")
                    Layout.fillHeight: true
                    visible: root.cfg.showPomodoro
                }
                Modules.TimerModule {
                    objectName: "timer"
                    hoverName: i18n("Timer")
                    Layout.column: root.colOf("timer")
                    Layout.fillHeight: true
                    visible: root.cfg.showTimer
                }
                Modules.StopwatchModule {
                    objectName: "stopwatch"
                    hoverName: i18n("Stopwatch")
                    Layout.column: root.colOf("stopwatch")
                    Layout.fillHeight: true
                    visible: root.cfg.showStopwatch
                }
                Modules.WorldClocksModule {
                    objectName: "worldclocks"
                    hoverName: i18n("World Clocks")
                    Layout.column: root.colOf("worldclocks")
                    Layout.fillHeight: true
                    visible: root.cfg.showWorldClocks
                    zones: root.cfg.worldZones.split(",").map(z => z.trim()).filter(z => z !== "")
                    now: root.now
                    onClicked: root.togglePopup("info")
                }
                Modules.TodosModule {
                    objectName: "todos"
                    hoverName: i18n("Todos")
                    Layout.column: root.colOf("todos")
                    Layout.fillHeight: true
                    visible: root.cfg.showTodos
                    json: root.cfg.todosJson
                    onJsonEdited: json => Plasmoid.configuration.todosJson = json
                }
                Modules.TemperatureModule {
                    objectName: "temperature"
                    hoverName: i18n("Temperature")
                    Layout.column: root.colOf("temperature")
                    Layout.fillHeight: true
                    visible: root.cfg.showTemperature
                    temp: tempSensor.value ?? 0
                    cpu: cpuSensor.value ?? 0
                    mem: memSensor.value ?? 0
                    onClicked: root.launch("plasma-systemmonitor")
                }
                Modules.NetworkModule {
                    objectName: "network"
                    hoverName: i18n("Network")
                    Layout.column: root.colOf("network")
                    Layout.fillHeight: true
                    visible: root.cfg.showNetwork
                    down: netDownSensor.value ?? 0
                    up: netUpSensor.value ?? 0
                    onClicked: root.launch("systemsettings kcm_networkmanagement")
                }
                Modules.StorageModule {
                    objectName: "storage"
                    hoverName: i18n("Storage")
                    Layout.column: root.colOf("storage")
                    Layout.fillHeight: true
                    visible: root.cfg.showStorage
                    used: diskUsedSensor.value ?? 0
                    total: diskTotalSensor.value ?? 0
                    onClicked: root.launch("filelight / || xdg-open /")
                }
                Modules.QuickTogglesModule {
                    objectName: "quicktoggles"
                    hoverName: i18n("Quick Toggles")
                    Layout.column: root.colOf("quicktoggles")
                    Layout.fillHeight: true
                    visible: root.cfg.showToggles
                    items: togglesLoader.item ? togglesLoader.item.items : []
                    source: togglesLoader.item
                    layoutStyle: root.cfg.toggleStyle
                    edge: Plasmoid.location
                    onToggled: key => togglesLoader.item.toggle(key)
                    onMoreRequested: root.launch("systemsettings")
                }
                Modules.TrayModule {
                    objectName: "tray"
                    hoverName: i18n("System Tray")
                    Layout.column: root.colOf("tray")
                    Layout.fillHeight: true
                    visible: root.cfg.showTray
                    active: root.cfg.showTray
                }
                Modules.VolumeModule {
                    objectName: "volume"
                    hoverName: i18n("Volume")
                    Layout.column: root.colOf("volume")
                    Layout.fillHeight: true
                    visible: root.cfg.showVolume
                    active: root.cfg.showVolume
                }
                Modules.RecycleBinModule {
                    objectName: "recyclebin"
                    hoverName: i18n("Recycle Bin")
                    Layout.column: root.colOf("recyclebin")
                    Layout.fillHeight: true
                    visible: root.cfg.showRecycleBin
                    active: root.cfg.showRecycleBin
                }
                Modules.ScreenshotModule {
                    objectName: "screenshot"
                    hoverName: i18n("Screenshot Capture")
                    Layout.column: root.colOf("screenshot")
                    Layout.fillHeight: true
                    visible: root.cfg.showScreenshot
                }
                Modules.NotesModule {
                    objectName: "notes"
                    hoverName: i18n("Notes")
                    Layout.column: root.colOf("notes")
                    Layout.fillHeight: true
                    visible: root.cfg.showNotes
                    text: root.cfg.notesText
                    onClicked: root.togglePopup("info")
                }
                Modules.ProgressModule {
                    objectName: "monthprogress"
                    hoverName: i18n("Month Progress")
                    Layout.column: root.colOf("monthprogress")
                    Layout.fillHeight: true
                    visible: root.cfg.showMonthProgress
                    kind: "month"
                    now: root.now
                    onClicked: root.togglePopup("info")
                }
                Modules.ProgressModule {
                    objectName: "dayprogress"
                    hoverName: i18n("Day Progress")
                    Layout.column: root.colOf("dayprogress")
                    Layout.fillHeight: true
                    visible: root.cfg.showDayProgress
                    kind: "day"
                    now: root.now
                    onClicked: root.togglePopup("info")
                }
                Modules.ProgressModule {
                    objectName: "yearprogress"
                    hoverName: i18n("Year Progress")
                    Layout.column: root.colOf("yearprogress")
                    Layout.fillHeight: true
                    visible: root.cfg.showYearProgress
                    kind: "year"
                    now: root.now
                    onClicked: root.togglePopup("info")
                }
                Modules.DateModule {
                    objectName: "date"
                    hoverName: i18n("Date")
                    Layout.column: root.colOf("date")
                    Layout.fillHeight: true
                    visible: root.cfg.showDate
                    kind: "long"
                    now: root.now
                    onClicked: root.togglePopup("info")
                }
                Modules.CalendarModule {
                    objectName: "calendar"
                    hoverName: i18n("Calendar")
                    Layout.column: root.colOf("calendar")
                    Layout.fillHeight: true
                    visible: root.cfg.showCalendar
                    now: root.now
                    source: root.cfg.calendarSource
                    planeUrl: root.cfg.planeUrl
                    planeWorkspace: root.cfg.planeWorkspace
                    planeKey: root.cfg.planeApiKey
                    // Nothing set up yet: open Google Calendar settings, where each
                    // calendar's "Secret address in iCal format" lives.
                    onClicked: {
                        if (configured)
                            root.togglePopup("info");
                        else
                            root.launch("xdg-open https://calendar.google.com/calendar/u/0/r/settings");
                    }
                }
                Modules.DateModule {
                    objectName: "daynumber"
                    hoverName: i18n("Day Number")
                    Layout.column: root.colOf("daynumber")
                    Layout.fillHeight: true
                    visible: root.cfg.showDayNumber
                    kind: "number"
                    now: root.now
                    onClicked: root.togglePopup("info")
                }
                Modules.BatteryModule {
                    objectName: "battery"
                    hoverName: i18n("Battery")
                    Layout.column: root.colOf("battery")
                    Layout.fillHeight: true
                    visible: root.hasBattery
                    percent: batteryPercentSensor.value ?? 0
                    charging: (batteryRateSensor.value ?? 0) > 0
                    edge: Plasmoid.location
                    onSettingsRequested: root.launch("systemsettings kcm_powerdevilprofilesconfig")
                }
                Modules.ClockStylesModule {
                    objectName: "clockstyle"
                    hoverName: i18n("Clock")
                    Layout.column: root.colOf("clockstyle")
                    Layout.fillHeight: true
                    visible: root.cfg.showClockStyle
                    style: root.cfg.clockStyle
                    zones: root.cfg.worldZones.split(",").map(z => z.trim()).filter(z => z !== "")
                    weatherSource: sharedWeather
                    onClicked: root.togglePopup("info")
                }
                // Clock is pinned at the far right.
                Modules.ClockModule {
                    objectName: "clock"
                    hoverName: i18n("Clock")
                    Layout.column: root.colOf("clock")
                    Layout.fillHeight: true
                    visible: root.cfg.showClock
                    now: root.now
                    weatherSource: sharedWeather
                    onClicked: root.togglePopup("info")
                }

                // Drag a tile sideways to reorder it. Tiles swap places as the
                // pointer crosses their midpoint; the order is saved on release.
                DragHandler {
                    id: reorder

                    property Item item: null

                    target: null
                    acceptedButtons: Qt.LeftButton
                    dragThreshold: Kirigami.Units.gridUnit * 0.6
                    // Never steal presses from sliders and buttons inside tiles.
                    grabPermissions: PointerHandler.TakeOverForbidden

                    onActiveChanged: {
                        if (active) {
                            const p = centroid.pressPosition;
                            const hit = row.childAt(p.x, p.y);
                            // Icons in the apps group reorder among themselves, not the whole group.
                            item = hit && hit.objectName !== "" && hit.objectName !== "apps" ? hit : null;
                            if (item) {
                                item.opacity = 0.6;
                                root.dragOrder = root.fullOrder();
                            }
                            return;
                        }
                        if (item) {
                            item.opacity = 1;
                            Plasmoid.configuration.tileOrder = root.dragOrder.join(",");
                            root.dragOrder = null;
                        }
                        item = null;
                    }
                    onCentroidChanged: {
                        if (!active || !item)
                            return;
                        const p = centroid.position;
                        const other = row.childAt(p.x, p.y);
                        if (!other || other === item || other.objectName === "")
                            return;
                        const mid = other.x + other.width / 2;
                        const forward = other.x > item.x;
                        if (forward ? p.x <= mid : p.x >= mid)
                            return;
                        const list = root.dragOrder.slice();
                        list.splice(list.indexOf(item.objectName), 1);
                        list.splice(list.indexOf(other.objectName) + (forward ? 1 : 0), 0, item.objectName);
                        root.dragOrder = list;
                    }
                }
            }
        }

        // Edge buttons: shown only on the side that still has content.
        Repeater {
            model: [-1, 1]

            Rectangle {
                required property int modelData
                readonly property bool atEnd: modelData < 0
                    ? scroller.contentX <= 1
                    : scroller.contentX >= scroller.contentWidth - scroller.width - 1

                visible: dock.scrollable && !atEnd
                anchors.verticalCenter: bar.verticalCenter
                x: modelData < 0 ? bar.x + 2 : bar.x + bar.width - width - 2
                width: Kirigami.Units.gridUnit * 1.3
                height: width
                radius: width / 2
                z: 5
                color: Qt.alpha(Kirigami.Theme.backgroundColor, tap.pressed ? 0.95 : 0.8)
                border.width: 1
                border.color: Qt.alpha(Kirigami.Theme.textColor, 0.2)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: parent.width * 0.6
                    height: width
                    source: modelData < 0 ? "go-previous-symbolic" : "go-next-symbolic"
                    isMask: true
                    color: Kirigami.Theme.textColor
                }
                TapHandler {
                    id: tap
                    onTapped: scroller.scrollBy(modelData * scroller.width * 0.6)
                }
            }
        }
    }

    fullRepresentation: Loader {
        // Sizes come from the mode, not the loaded item, so the popup opens at its
        // final size and sits clear of the dock.
        readonly property bool launcher: root.popupMode === "launcher"
        sourceComponent: launcher ? launcherComp : infoComp
        Layout.minimumWidth: launcher ? Kirigami.Units.gridUnit * 36 : Kirigami.Units.gridUnit * 17
        Layout.preferredWidth: launcher ? Kirigami.Units.gridUnit * 38 : Kirigami.Units.gridUnit * 17
        Layout.maximumWidth: launcher ? Kirigami.Units.gridUnit * 38 : Kirigami.Units.gridUnit * 17
        Layout.minimumHeight: launcher ? Kirigami.Units.gridUnit * 24 : (item ? item.Layout.minimumHeight : 0)
        Layout.preferredHeight: launcher ? Kirigami.Units.gridUnit * 24 : -1
        Layout.maximumHeight: launcher ? Kirigami.Units.gridUnit * 24 : -1
    }

    Component {
        id: launcherComp

        Launcher.LauncherPanel {
            applet: root
            onCloseRequested: root.expanded = false
        }
    }

    Component {
        id: infoComp

        ColumnLayout {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 17
        Layout.maximumWidth: Kirigami.Units.gridUnit * 17
        Layout.minimumHeight: implicitHeight
        spacing: 0

        // Header: icon, name, pill tag with today's date.
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: Plasmoid.icon
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }
            PlasmaComponents.Label {
                text: i18n("Dock")
                font.weight: Font.DemiBold
            }
            Rectangle {
                implicitWidth: tag.implicitWidth + Kirigami.Units.largeSpacing
                implicitHeight: tag.implicitHeight + Kirigami.Units.smallSpacing
                radius: height / 2
                color: Qt.alpha(Kirigami.Theme.textColor, 0.1)

                PlasmaComponents.Label {
                    id: tag
                    anchors.centerIn: parent
                    text: Qt.formatDate(root.now, "ddd d MMM")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }
            }
            Item {
                Layout.fillWidth: true
            }
        }

        SectionHeader {
            visible: root.cfg.showClock
            text: i18n("Time")
        }
        InfoRow {
            visible: root.cfg.showClock
            label: i18n("Now")
            value: Qt.formatTime(root.now, Qt.locale().timeFormat(Locale.ShortFormat))
            emphasized: true
        }
        InfoRow {
            visible: root.cfg.showClock
            label: i18n("Date")
            value: Qt.formatDate(root.now, Qt.locale().dateFormat(Locale.LongFormat))
            divider: false
        }

        SectionHeader {
            visible: root.cfg.showDate || root.cfg.showDayNumber
            text: Qt.formatDate(root.now, "MMMM yyyy")
        }
        MonthGrid {
            visible: root.cfg.showDate || root.cfg.showDayNumber
            now: root.now
        }

        SectionHeader {
            visible: root.cfg.showMonthProgress || root.cfg.showDayProgress || root.cfg.showYearProgress
            text: i18n("Progress")
        }
        Repeater {
            model: [
                { kind: "day", show: root.cfg.showDayProgress, label: i18n("Day") },
                { kind: "month", show: root.cfg.showMonthProgress, label: i18n("Month") },
                { kind: "year", show: root.cfg.showYearProgress, label: i18n("Year") }
            ]
            delegate: InfoRow {
                required property var modelData
                visible: modelData.show
                label: modelData.label + " · " + Progress.caption(modelData.kind, root.now)
                value: Math.floor(Progress.fraction(modelData.kind, root.now) * 100) + "%"
                progress: Progress.fraction(modelData.kind, root.now) * 100
            }
        }

        SectionHeader {
            visible: root.cfg.showWorldClocks
            text: i18n("World clocks")
        }
        // Hidden tile used only for its time-zone maths.
        Modules.WorldClocksModule {
            id: zoneMath
            visible: false
            now: root.now
        }
        Repeater {
            model: root.cfg.showWorldClocks
                ? root.cfg.worldZones.split(",").map(z => z.trim()).filter(z => z !== "") : []
            delegate: InfoRow {
                required property var modelData
                label: zoneMath.cityName(modelData)
                value: zoneMath.timeIn(modelData)
            }
        }

        SectionHeader {
            visible: root.cfg.showStats
            text: i18n("System")
        }
        InfoRow {
            visible: root.cfg.showStats
            label: i18n("CPU")
            value: Math.round(cpuSensor.value ?? 0) + "%"
            progress: cpuSensor.value ?? 0
        }
        InfoRow {
            visible: root.cfg.showStats
            label: i18n("Memory")
            value: Math.round(memSensor.value ?? 0) + "%"
            progress: memSensor.value ?? 0
            divider: false
        }

        SectionHeader {
            visible: root.showMedia
            text: i18n("Now playing")
        }
        Modules.MediaModule {
            visible: root.showMedia
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            player: root.player
            playing: root.playing
        }

        SectionHeader {
            visible: root.cfg.showNotes
            text: i18n("Notes")
        }
        PlasmaComponents.TextArea {
            visible: root.cfg.showNotes
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            Layout.preferredHeight: Kirigami.Units.gridUnit * 7
            placeholderText: i18n("Write a note")
            wrapMode: TextEdit.Wrap
            Component.onCompleted: text = root.cfg.notesText
            onTextChanged: {
                if (text !== root.cfg.notesText)
                    Plasmoid.configuration.notesText = text;
            }
        }

        SectionHeader {
            visible: root.cfg.showTodos
            text: i18n("Todos")
        }
        Repeater {
            model: root.cfg.showTodos ? root.todoItems().slice(0, 6) : []
            delegate: InfoRow {
                required property var modelData
                label: modelData.text
                value: modelData.done ? i18n("done") : ""
            }
        }
        RowLayout {
            visible: root.cfg.showTodos
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.TextField {
                id: todoInput
                Layout.fillWidth: true
                placeholderText: i18n("New todo")
                onAccepted: {
                    root.addTodo(text);
                    text = "";
                }
            }
            PlasmaComponents.Button {
                text: i18n("Clear done")
                onClicked: root.clearDoneTodos()
            }
        }
    }
    }
}
