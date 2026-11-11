pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../settings"

// Widget gallery: every tile the dock can show, grouped by category. Tap a card
// to add it to the dock or take it off. Each tile's options stay in Settings.
ColumnLayout {
    id: panel

    property var applet

    signal settingsRequested()

    // key: the show<Name> config entry. keywords widen the search.
    readonly property var widgets: [
        { key: "showClock", name: i18n("Clock"), icon: "preferences-system-time-symbolic", desc: i18n("Time with today’s weather"), cat: "time", keywords: "time weather" },
        { key: "showDate", name: i18n("Date"), icon: "view-calendar-day-symbolic", desc: i18n("Weekday and date"), cat: "time", keywords: "" },
        { key: "showDayNumber", name: i18n("Day number"), icon: "view-calendar-symbolic", desc: i18n("Today as one big number"), cat: "time", keywords: "" },
        { key: "showClockStyle", name: i18n("Clock styles"), icon: "clock-symbolic", desc: i18n("Flip, analog or segment face"), cat: "time", keywords: "flip analog segment" },
        { key: "showCalendar", name: i18n("Calendar"), icon: "view-calendar-agenda-symbolic", desc: i18n("Your next event"), cat: "time", keywords: "ical plane meeting event" },
        { key: "showWorldClocks", name: i18n("World clocks"), icon: "globe-symbolic", desc: i18n("Up to three time zones"), cat: "time", keywords: "time zone" },
        { key: "showDayProgress", name: i18n("Day progress"), icon: "view-calendar-timeline-symbolic", desc: i18n("How much of today is gone"), cat: "time", keywords: "" },
        { key: "showMonthProgress", name: i18n("Month progress"), icon: "view-calendar-month-symbolic", desc: i18n("How much of the month is gone"), cat: "time", keywords: "" },
        { key: "showYearProgress", name: i18n("Year progress"), icon: "view-calendar-year-symbolic", desc: i18n("How much of the year is gone"), cat: "time", keywords: "" },
        { key: "showPomodoro", name: i18n("Pomodoro"), icon: "chronometer-symbolic", desc: i18n("25 / 5 minute focus cycles"), cat: "productivity", keywords: "focus timer" },
        { key: "showTimer", name: i18n("Timer"), icon: "chronometer-start-symbolic", desc: i18n("Countdown with presets"), cat: "productivity", keywords: "countdown" },
        { key: "showStopwatch", name: i18n("Stopwatch"), icon: "chronometer-lap-symbolic", desc: i18n("Start, pause and reset"), cat: "productivity", keywords: "" },
        { key: "showTodos", name: i18n("Todos"), icon: "view-task-symbolic", desc: i18n("A quick task list"), cat: "productivity", keywords: "tasks list" },
        { key: "showNotes", name: i18n("Notes"), icon: "note-symbolic", desc: i18n("Several quick notes"), cat: "productivity", keywords: "" },
        { key: "showStats", name: i18n("CPU and RAM"), icon: "cpu-symbolic", desc: i18n("Live CPU and memory rings"), cat: "system", keywords: "memory usage stats" },
        { key: "showTemperature", name: i18n("Temperature"), icon: "temperature-normal-symbolic", desc: i18n("CPU heat and load"), cat: "system", keywords: "cpu" },
        { key: "showNetwork", name: i18n("Network speed"), icon: "network-wireless-symbolic", desc: i18n("Download and upload speed"), cat: "system", keywords: "download upload" },
        { key: "showStorage", name: i18n("Disk usage"), icon: "drive-harddisk-symbolic", desc: i18n("Used space on your disk"), cat: "system", keywords: "storage" },
        { key: "showBattery", name: i18n("Battery"), icon: "battery-good-symbolic", desc: i18n("Charge level and charging"), cat: "system", keywords: "power" },
        { key: "showVolume", name: i18n("Volume"), icon: "audio-volume-high-symbolic", desc: i18n("Output level slider"), cat: "system", keywords: "sound audio" },
        { key: "showToggles", name: i18n("Quick toggles"), icon: "network-wireless-connected-symbolic", desc: i18n("Wi-Fi, Bluetooth, Do Not Disturb"), cat: "system", keywords: "wifi bluetooth dnd night" },
        { key: "showTray", name: i18n("System tray"), icon: "preferences-desktop-notification-symbolic", desc: i18n("Status icons from apps"), cat: "system", keywords: "" },
        { key: "showScript", name: i18n("Script output"), icon: "utilities-terminal-symbolic", desc: i18n("Your own command, on a timer"), cat: "system", keywords: "custom command shell" },
        { key: "showStart", name: i18n("App launcher"), icon: "start-here-kde-symbolic", desc: i18n("Start menu with search"), cat: "apps", keywords: "start menu" },
        { key: "showApps", name: i18n("Pinned apps"), icon: "view-app-grid-symbolic", desc: i18n("Your apps, with running dots"), cat: "apps", keywords: "dock taskbar" },
        { key: "showMedia", name: i18n("Now playing"), icon: "media-playback-start-symbolic", desc: i18n("Player controls, or a Spotify launcher"), cat: "apps", keywords: "music spotify mpris" },
        { key: "showWeather", name: i18n("Weather"), icon: "weather-few-clouds-symbolic", desc: i18n("Current conditions"), cat: "apps", keywords: "" },
        { key: "showRecycleBin", name: i18n("Recycle bin"), icon: "user-trash-symbolic", desc: i18n("Trash at a glance"), cat: "apps", keywords: "trash" },
        { key: "showScreenshot", name: i18n("Screenshot"), icon: "spectacle-symbolic", desc: i18n("Capture the screen or a region"), cat: "apps", keywords: "capture" }
    ]
    readonly property var accents: ({ time: "#FF9F0A", productivity: "#FF453A", system: "#0A84FF", apps: "#30D158" })
    readonly property var categories: [
        { id: "", name: i18n("All") },
        { id: "time", name: i18n("Clocks") },
        { id: "productivity", name: i18n("Productivity") },
        { id: "system", name: i18n("System") },
        { id: "apps", name: i18n("Apps & Media") }
    ]

    property string category: ""
    readonly property string query: search.text.trim().toLowerCase()
    // Re-read when a switch changes, since config values are not bindable per key.
    property int revision: 0
    readonly property int onCount: {
        revision;
        return widgets.filter(w => applet.cfg[w.key]).length;
    }
    readonly property var shown: widgets.filter(w => (category === "" || w.cat === category)
        && (query === "" || (w.name + " " + w.desc + " " + w.keywords).toLowerCase().indexOf(query) >= 0))

    function toggle(key) {
        applet.cfg[key] = !applet.cfg[key];
        revision++;
    }

    spacing: Kirigami.Units.largeSpacing

    // The popup window activates after this is built, so take focus a beat later.
    Timer {
        interval: 120
        running: true
        onTriggered: search.forceActiveFocus()
    }

    RowLayout {
        Layout.fillWidth: true

        Kirigami.Heading {
            text: i18n("Widgets")
            level: 2
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
                text: i18n("%1 in bar", panel.onCount)
                color: Kirigami.Theme.highlightColor
                font.weight: Font.DemiBold
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.features: { "tnum": 1 }
            }
        }
        PlasmaComponents.ToolButton {
            icon.name: "configure"
            display: QQC2.AbstractButton.IconOnly
            text: i18n("Widget options")
            onClicked: panel.settingsRequested()
            QQC2.ToolTip.text: text
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }

    Kirigami.SearchField {
        id: search
        Layout.fillWidth: true
        placeholderText: i18n("Search widgets")
        Keys.onEscapePressed: event => {
            if (text !== "")
                text = "";
            else
                event.accepted = false;
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Repeater {
            model: panel.categories

            QQC2.AbstractButton {
                id: chip
                required property var modelData
                readonly property bool current: panel.category === modelData.id

                implicitWidth: chipLabel.implicitWidth + Kirigami.Units.largeSpacing * 2
                implicitHeight: chipLabel.implicitHeight + Kirigami.Units.smallSpacing * 2
                onClicked: panel.category = modelData.id

                contentItem: QQC2.Label {
                    id: chipLabel
                    text: chip.modelData.name
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: chip.current ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                }
                background: Rectangle {
                    radius: height / 2
                    color: chip.current ? Kirigami.Theme.highlightColor
                        : Qt.alpha(Kirigami.Theme.textColor, chip.hovered ? 0.12 : 0.06)
                }
            }
        }
    }

    QQC2.ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        GridView {
            id: grid
            readonly property int columns: 2
            cellWidth: Math.floor(width / columns)
            cellHeight: Kirigami.Units.gridUnit * 3
            clip: true
            model: panel.shown

            delegate: Item {
                id: cell
                required property var modelData

                width: grid.cellWidth
                height: grid.cellHeight

                WidgetRow {
                    anchors.fill: parent
                    anchors.margins: 1
                    text: cell.modelData.name
                    description: cell.modelData.desc
                    iconName: cell.modelData.icon
                    accent: panel.accents[cell.modelData.cat]
                    readonly property bool on: { panel.revision; return !!panel.applet.cfg[cell.modelData.key]; }
                    checked: on
                    onToggled: {
                        panel.toggle(cell.modelData.key);
                        checked = Qt.binding(() => on); // the tap broke the binding
                    }
                }
            }
        }
    }

    Kirigami.PlaceholderMessage {
        visible: panel.shown.length === 0
        Layout.fillWidth: true
        icon.name: "edit-find"
        text: i18n("No widget matches “%1”", search.text.trim())
    }
}
