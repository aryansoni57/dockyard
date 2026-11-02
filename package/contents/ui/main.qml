import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.private.mpris as Mpris
import "modules" as Modules
import "components"

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
        running: root.cfg.showClock
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
        sensorId: root.cfg.showStats ? "cpu/all/usage" : ""
        updateRateLimit: root.cfg.statsInterval
    }

    Sensors.Sensor {
        id: memSensor
        sensorId: root.cfg.showStats ? "memory/physical/usedPercent" : ""
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

    Plasmoid.icon: "preferences-desktop-panel"
    toolTipMainText: Qt.formatDate(root.now, Qt.locale().dateFormat(Locale.LongFormat))
    toolTipSubText: root.playing ? i18n("Playing: %1", root.player.track) : ""

    compactRepresentation: Item {
        id: dock

        // Bar padding around the tiles: thin inside a panel, roomier on the desktop.
        readonly property real inset: root.onDesktop ? Kirigami.Units.smallSpacing * 1.5 : 2

        Layout.minimumWidth: row.implicitWidth + (root.onDesktop ? inset * 2 : 0)
        Layout.preferredWidth: Layout.minimumWidth
        Layout.minimumHeight: root.onDesktop ? Kirigami.Units.gridUnit * 3 : -1

        // On the desktop the bar keeps a fixed dock height, centered in the
        // widget's area, instead of stretching tiles to the whole widget.
        Item {
            id: bar
            anchors.centerIn: parent
            width: root.onDesktop ? row.implicitWidth + dock.inset * 2 : parent.width
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

        RowLayout {
            id: row
            anchors.fill: bar
            anchors.margins: root.onDesktop ? dock.inset : 0
            anchors.topMargin: dock.inset
            anchors.bottomMargin: dock.inset
            spacing: Kirigami.Units.smallSpacing

            Modules.StatsModule {
                Layout.fillHeight: true
                visible: root.cfg.showStats
                cpu: cpuSensor.value ?? 0
                mem: memSensor.value ?? 0
                onClicked: root.expanded = !root.expanded
            }
            Modules.MediaModule {
                Layout.fillHeight: true
                visible: root.showMedia
                player: root.player
                playing: root.playing
                onClicked: root.expanded = !root.expanded
            }
            Modules.WeatherModule {
                Layout.fillHeight: true
                visible: root.cfg.showWeather
                latitude: Number(root.cfg.latitude) || 0
                longitude: Number(root.cfg.longitude) || 0
                fahrenheit: root.cfg.fahrenheit
            }
            Modules.PomodoroModule {
                Layout.fillHeight: true
                visible: root.cfg.showPomodoro
            }
            Modules.TimerModule {
                Layout.fillHeight: true
                visible: root.cfg.showTimer
            }
            Modules.StopwatchModule {
                Layout.fillHeight: true
                visible: root.cfg.showStopwatch
            }
            Modules.WorldClocksModule {
                Layout.fillHeight: true
                visible: root.cfg.showWorldClocks
                zones: root.cfg.worldZones.split(",").map(z => z.trim()).filter(z => z !== "")
                now: root.now
            }
            Modules.TodosModule {
                Layout.fillHeight: true
                visible: root.cfg.showTodos
                json: root.cfg.todosJson
                onJsonEdited: json => Plasmoid.configuration.todosJson = json
            }
            Modules.TemperatureModule {
                Layout.fillHeight: true
                visible: root.cfg.showTemperature
                temp: tempSensor.value ?? 0
            }
            Modules.NetworkModule {
                Layout.fillHeight: true
                visible: root.cfg.showNetwork
                down: netDownSensor.value ?? 0
                up: netUpSensor.value ?? 0
            }
            Modules.StorageModule {
                Layout.fillHeight: true
                visible: root.cfg.showStorage
                used: diskUsedSensor.value ?? 0
                total: diskTotalSensor.value ?? 0
            }
            Modules.BatteryModule {
                Layout.fillHeight: true
                visible: root.hasBattery
                percent: batteryPercentSensor.value ?? 0
                charging: (batteryRateSensor.value ?? 0) > 0
            }
            // Clock is pinned at the far right.
            Modules.ClockModule {
                Layout.fillHeight: true
                visible: root.cfg.showClock
                now: root.now
                onClicked: root.expanded = !root.expanded
            }
        }
    }

    fullRepresentation: ColumnLayout {
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
