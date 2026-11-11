import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls
import "settings"

// Which tiles are on the dock. Each tile's own options live on the other pages.
KCM.SimpleKCM {
    id: page

    property alias cfg_showStart: showStart.checked
    property alias cfg_showClock: showClock.checked
    property alias cfg_showStats: showStats.checked
    property alias cfg_showMedia: showMedia.checked
    property alias cfg_showTemperature: showTemperature.checked
    property alias cfg_showNetwork: showNetwork.checked
    property alias cfg_showStorage: showStorage.checked
    property alias cfg_showScript: showScript.checked
    property alias cfg_showBattery: showBattery.checked
    property alias cfg_showWeather: showWeather.checked
    property alias cfg_showPomodoro: showPomodoro.checked
    property alias cfg_showTimer: showTimer.checked
    property alias cfg_showStopwatch: showStopwatch.checked
    property alias cfg_showWorldClocks: showWorldClocks.checked
    property alias cfg_showTodos: showTodos.checked
    property alias cfg_showApps: showApps.checked
    property alias cfg_showToggles: showToggles.checked
    property alias cfg_showMonthProgress: showMonthProgress.checked
    property alias cfg_showDayProgress: showDayProgress.checked
    property alias cfg_showYearProgress: showYearProgress.checked
    property alias cfg_showDate: showDate.checked
    property alias cfg_showDayNumber: showDayNumber.checked
    property alias cfg_showClockStyle: showClockStyle.checked
    property alias cfg_showNotes: showNotes.checked
    property alias cfg_showVolume: showVolume.checked
    property alias cfg_showRecycleBin: showRecycleBin.checked
    property alias cfg_showScreenshot: showScreenshot.checked
    property alias cfg_showTray: showTray.checked
    property alias cfg_showCalendar: showCalendar.checked
    property bool cfg_tilePopups
    property bool cfg_barOpaque
    property string cfg_accentColor
    property bool cfg_syncSystemAccent

    // Every widget switch, for the counter and the presets.
    readonly property var switches: [showStart, showClock, showStats, showMedia, showTemperature, showNetwork,
        showStorage, showScript, showBattery, showWeather, showPomodoro, showTimer, showStopwatch, showWorldClocks,
        showTodos, showApps, showToggles, showMonthProgress, showDayProgress, showYearProgress,
        showDate, showDayNumber, showClockStyle, showNotes, showVolume, showRecycleBin, showScreenshot, showTray, showCalendar]
    readonly property int enabledCount: switches.filter(c => c.checked).length
    readonly property int matchCount: switches.filter(c => c.visible).length
    readonly property string query: search.text.trim().toLowerCase()

    // The set before the last preset, so a preset can be undone.
    property var beforePreset: null

    function applyPreset(on) {
        beforePreset = switches.filter(c => c.checked);
        for (let i = 0; i < switches.length; i++)
            switches[i].checked = on.indexOf(switches[i]) >= 0;
    }
    function undoPreset() {
        const was = beforePreset;
        beforePreset = null;
        for (let i = 0; i < switches.length; i++)
            switches[i].checked = was.indexOf(switches[i]) >= 0;
    }

    // Category colors for the icon badges (docs/STYLE.md accents).
    readonly property color timeAccent: "#FF9F0A"
    readonly property color workAccent: "#FF453A"
    readonly property color systemAccent: "#0A84FF"
    readonly property color appsAccent: "#30D158"

    // A widget row that hides itself when it does not match the search box.
    // `keywords` widen the search ("cpu" finds Temperature, "spotify" finds Now playing).
    component WidgetCheck: WidgetRow {
        property string keywords
        property string optionsPage

        visible: page.query === "" || (text + " " + description + " " + keywords).toLowerCase().indexOf(page.query) >= 0
        onToggled: page.beforePreset = null

        QQC2.ToolTip.visible: optionsPage !== "" && hovered
        QQC2.ToolTip.text: i18n("Options on the %1 page", optionsPage)
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay * 2
    }

    // Preset chip: a small pill, like the category chips in the gallery.
    component Chip: QQC2.AbstractButton {
        id: chip
        leftPadding: Kirigami.Units.largeSpacing * 1.5
        rightPadding: Kirigami.Units.largeSpacing * 1.5
        topPadding: Kirigami.Units.smallSpacing * 1.5
        bottomPadding: Kirigami.Units.smallSpacing * 1.5
        implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
        implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
        hoverEnabled: true
        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Icon {
                visible: chip.icon.name !== ""
                source: chip.icon.name
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            QQC2.Label {
                id: chipLabel
                text: chip.text
            }
        }
        background: Rectangle {
            radius: height / 2
            color: Qt.alpha(Kirigami.Theme.textColor, chip.down ? 0.16 : chip.hovered ? 0.11 : 0.06)
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.08)
        }
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing * 1.5

        // Header: counter, search and presets.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true

                QQC2.Label {
                    text: i18n("Widgets in the dock")
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.3
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                Rectangle {
                    implicitWidth: countLabel.implicitWidth + Kirigami.Units.largeSpacing * 1.5
                    implicitHeight: countLabel.implicitHeight + Kirigami.Units.smallSpacing
                    radius: height / 2
                    color: Qt.alpha(Kirigami.Theme.highlightColor, 0.18)

                    QQC2.Label {
                        id: countLabel
                        anchors.centerIn: parent
                        text: i18n("%1 of %2 on", page.enabledCount, page.switches.length)
                        color: Kirigami.Theme.highlightColor
                        font.weight: Font.DemiBold
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                }
            }
            QQC2.Label {
                text: i18n("Turn widgets on to add them to the dock. Drag tiles on the dock to reorder them.")
                opacity: 0.6
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Kirigami.SearchField {
                id: search
                Layout.fillWidth: true
                placeholderText: i18n("Search widgets")
            }
            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    text: i18n("Presets")
                    opacity: 0.55
                    height: minimalBtn.height
                    verticalAlignment: Text.AlignVCenter
                    rightPadding: Kirigami.Units.smallSpacing
                }
                Chip {
                    id: minimalBtn
                    text: i18n("Minimal")
                    onClicked: page.applyPreset([showStart, showClock, showMedia, showApps])
                }
                Chip {
                    text: i18n("Everyday")
                    onClicked: page.applyPreset([showStart, showClock, showMedia, showApps, showWeather, showVolume,
                                                  showToggles, showBattery, showNotes])
                }
                Chip {
                    text: i18n("Monitor")
                    onClicked: page.applyPreset([showStart, showClock, showStats, showTemperature, showNetwork,
                                                  showStorage, showBattery, showMedia])
                }
                Chip {
                    text: i18n("All off")
                    onClicked: page.applyPreset([])
                }
                Chip {
                    visible: page.beforePreset !== null
                    icon.name: "edit-undo"
                    text: i18n("Undo preset")
                    onClicked: page.undoPreset()
                }
            }
        }

        Kirigami.PlaceholderMessage {
            visible: page.matchCount === 0
            Layout.fillWidth: true
            icon.name: "edit-find"
            text: i18n("No widget matches “%1”", search.text.trim())
        }

        Card {
            title: i18n("Time and date")
            columns: 2
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: 0
            WidgetCheck { id: showClock; iconName: "preferences-system-time-symbolic"; accent: page.timeAccent; description: i18n("Time with today’s weather"); text: i18n("Clock"); keywords: "time weather"; optionsPage: i18n("Weather") }
            WidgetCheck { id: showDate; iconName: "view-calendar-day-symbolic"; accent: page.timeAccent; description: i18n("Weekday and date"); text: i18n("Date") }
            WidgetCheck { id: showDayNumber; iconName: "view-calendar-symbolic"; accent: page.timeAccent; description: i18n("Today as one big number"); text: i18n("Day number") }
            WidgetCheck { id: showClockStyle; iconName: "clock-symbolic"; accent: page.timeAccent; description: i18n("Flip, analog or segment face"); text: i18n("Clock styles"); keywords: "flip analog segment"; optionsPage: i18n("Clock & Calendar") }
            WidgetCheck { id: showCalendar; iconName: "view-calendar-agenda-symbolic"; accent: page.timeAccent; description: i18n("Your next event"); text: i18n("Calendar (next event)"); keywords: "ical plane meeting"; optionsPage: i18n("Clock & Calendar") }
            WidgetCheck { id: showWorldClocks; iconName: "globe-symbolic"; accent: page.timeAccent; description: i18n("Up to three time zones"); text: i18n("World clocks"); keywords: "time zone"; optionsPage: i18n("Clock & Calendar") }
            WidgetCheck { id: showDayProgress; iconName: "view-calendar-timeline-symbolic"; accent: page.timeAccent; description: i18n("How much of today is gone"); text: i18n("Day progress") }
            WidgetCheck { id: showMonthProgress; iconName: "view-calendar-month-symbolic"; accent: page.timeAccent; description: i18n("How much of the month is gone"); text: i18n("Month progress") }
            WidgetCheck { id: showYearProgress; iconName: "view-calendar-year-symbolic"; accent: page.timeAccent; description: i18n("How much of the year is gone"); text: i18n("Year progress") }
        }

        Card {
            title: i18n("Productivity")
            columns: 2
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: 0
            WidgetCheck { id: showPomodoro; iconName: "chronometer-symbolic"; accent: page.workAccent; description: i18n("25 / 5 minute focus cycles"); text: i18n("Pomodoro"); keywords: "focus timer" }
            WidgetCheck { id: showTimer; iconName: "chronometer-start-symbolic"; accent: page.workAccent; description: i18n("Countdown with presets"); text: i18n("Timer"); keywords: "countdown" }
            WidgetCheck { id: showStopwatch; iconName: "chronometer-lap-symbolic"; accent: page.workAccent; description: i18n("Start, pause and reset"); text: i18n("Stopwatch") }
            WidgetCheck { id: showTodos; iconName: "view-task-symbolic"; accent: page.workAccent; description: i18n("A quick task list"); text: i18n("Todos"); keywords: "tasks list" }
            WidgetCheck { id: showNotes; iconName: "note-symbolic"; accent: page.workAccent; description: i18n("Several quick notes"); text: i18n("Notes") }
        }

        Card {
            title: i18n("System")
            columns: 2
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: 0
            WidgetCheck { id: showStats; iconName: "cpu-symbolic"; accent: page.systemAccent; description: i18n("Live CPU and memory rings"); text: i18n("CPU and RAM"); keywords: "memory usage"; optionsPage: i18n("System") }
            WidgetCheck { id: showTemperature; iconName: "temperature-normal-symbolic"; accent: page.systemAccent; description: i18n("CPU heat and load"); text: i18n("CPU temperature"); optionsPage: i18n("System") }
            WidgetCheck { id: showNetwork; iconName: "network-wireless-symbolic"; accent: page.systemAccent; description: i18n("Download and upload speed"); text: i18n("Network speed"); keywords: "download upload"; optionsPage: i18n("System") }
            WidgetCheck { id: showStorage; iconName: "drive-harddisk-symbolic"; accent: page.systemAccent; description: i18n("Used space on your disk"); text: i18n("Disk usage"); keywords: "storage" }
            WidgetCheck { id: showScript; iconName: "utilities-terminal-symbolic"; accent: page.systemAccent; description: i18n("Your own command, on a timer"); text: i18n("Script output"); keywords: "custom command shell"; optionsPage: i18n("System") }
            WidgetCheck { id: showBattery; iconName: "battery-good-symbolic"; accent: page.systemAccent; description: i18n("Charge level and charging"); text: i18n("Battery"); keywords: "power"; optionsPage: i18n("System") }
            WidgetCheck { id: showVolume; iconName: "audio-volume-high-symbolic"; accent: page.systemAccent; description: i18n("Output level slider"); text: i18n("Volume slider"); keywords: "sound audio" }
            WidgetCheck { id: showToggles; iconName: "network-wireless-connected-symbolic"; accent: page.systemAccent; description: i18n("Wi-Fi, Bluetooth, Do Not Disturb"); text: i18n("Quick toggles"); keywords: "wifi bluetooth dnd night"; optionsPage: i18n("System") }
            WidgetCheck { id: showTray; iconName: "preferences-desktop-notification-symbolic"; accent: page.systemAccent; description: i18n("Status icons from apps"); text: i18n("System tray") }
        }

        Card {
            title: i18n("Apps, media and weather")
            columns: 2
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: 0
            WidgetCheck { id: showStart; iconName: "start-here-kde-symbolic"; accent: page.appsAccent; description: i18n("Start menu with search"); text: i18n("Application launcher"); keywords: "start menu"; optionsPage: i18n("Apps") }
            WidgetCheck { id: showApps; iconName: "view-app-grid-symbolic"; accent: page.appsAccent; description: i18n("Your apps, with running dots"); text: i18n("Pinned apps"); keywords: "dock taskbar"; optionsPage: i18n("Apps") }
            WidgetCheck { id: showMedia; iconName: "media-playback-start-symbolic"; accent: page.appsAccent; description: i18n("Player controls, or a Spotify launcher"); text: i18n("Now playing"); keywords: "music spotify mpris" }
            WidgetCheck { id: showWeather; iconName: "weather-few-clouds-symbolic"; accent: page.appsAccent; description: i18n("Current conditions"); text: i18n("Weather"); optionsPage: i18n("Weather") }
            WidgetCheck { id: showRecycleBin; iconName: "user-trash-symbolic"; accent: page.appsAccent; description: i18n("Trash at a glance"); text: i18n("Recycle bin"); keywords: "trash" }
            WidgetCheck { id: showScreenshot; iconName: "spectacle-symbolic"; accent: page.appsAccent; description: i18n("Capture the screen or a region"); text: i18n("Screenshot capture") }
        }

        Card {
            title: i18n("Dock bar")
            visible: page.query === ""
            WidgetRow {
                text: i18n("Opaque dock bar")
                description: i18n("Solid instead of frosted glass")
                iconName: "preferences-desktop-theme-global-symbolic"
                accent: "#8E8E93"
                checked: page.cfg_barOpaque
                onToggled: page.cfg_barOpaque = checked
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: i18n("Changes the dock bar when it is a desktop widget, and switches the Glass Plasma theme to Glass (opaque) if that is your theme. Run install-all.sh once to install both.")
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay * 2
            }
            FormRow {
                label: i18n("Accent color")
                hint: i18n("Colors the dock's buttons and highlights. Reset follows your Plasma theme.")
                KQuickControls.ColorButton {
                    color: /^#[0-9a-fA-F]{6}$/.test(page.cfg_accentColor) ? page.cfg_accentColor : Kirigami.Theme.highlightColor
                    showAlphaChannel: false
                    onAccepted: page.cfg_accentColor = Qt.color(color).toString().toLowerCase()
                }
                QQC2.Button {
                    text: i18n("Reset")
                    icon.name: "edit-undo"
                    enabled: page.cfg_accentColor !== ""
                    onClicked: page.cfg_accentColor = ""
                }
            }
            FormRow {
                label: i18n("System theme")
                hint: i18n("Also sets the Plasma accent color and the Dockyard Plasma theme colors (volume pop-up and more), so apps and Plasma follow. Changing it restarts plasmashell. Reset puts the originals back. Kvantum-styled widgets keep their blue.")
                QQC2.CheckBox {
                    text: i18n("Sync accent with the system")
                    checked: page.cfg_syncSystemAccent
                    onToggled: page.cfg_syncSystemAccent = checked
                }
            }
        }
    }
}
