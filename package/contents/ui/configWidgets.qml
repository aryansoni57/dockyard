import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
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

    // A widget switch that hides itself when it does not match the search box.
    // `keywords` widen the search ("cpu" finds Temperature, "spotify" finds Now playing).
    component WidgetCheck: QQC2.CheckBox {
        property string keywords
        property string optionsPage

        Layout.fillWidth: true
        visible: page.query === "" || (text + " " + keywords).toLowerCase().indexOf(page.query) >= 0
        onToggled: page.beforePreset = null

        QQC2.ToolTip.visible: optionsPage !== "" && hovered
        QQC2.ToolTip.text: i18n("Options on the %1 page", optionsPage)
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay * 2
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
                text: i18n("Drag tiles on the dock to reorder them. Mouse wheel scrolls a crowded dock. Each widget's options are on the pages in the sidebar.")
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
                    text: i18n("Presets:")
                    opacity: 0.6
                    height: minimalBtn.height
                    verticalAlignment: Text.AlignVCenter
                }
                QQC2.Button {
                    id: minimalBtn
                    text: i18n("Minimal")
                    onClicked: page.applyPreset([showStart, showClock, showMedia, showApps])
                }
                QQC2.Button {
                    text: i18n("Everyday")
                    onClicked: page.applyPreset([showStart, showClock, showMedia, showApps, showWeather, showVolume,
                                                  showToggles, showBattery, showNotes])
                }
                QQC2.Button {
                    text: i18n("Monitor")
                    onClicked: page.applyPreset([showStart, showClock, showStats, showTemperature, showNetwork,
                                                  showStorage, showBattery, showMedia])
                }
                QQC2.Button {
                    text: i18n("All off")
                    onClicked: page.applyPreset([])
                }
                QQC2.Button {
                    visible: page.beforePreset !== null
                    flat: true
                    icon.name: "edit-undo"
                    text: i18n("Undo preset")
                    onClicked: page.undoPreset()
                }
            }
        }

        QQC2.Switch {
            text: i18n("Opaque dock bar")
            checked: page.cfg_barOpaque
            onToggled: page.cfg_barOpaque = checked
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.text: i18n("Solid instead of frosted glass. Changes the dock bar when it is a desktop widget, and switches the Glass Plasma theme to Glass (opaque) if that is your theme. Run install-all.sh once to install both.")
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
            WidgetCheck { id: showClock; text: i18n("Clock"); keywords: "time weather"; optionsPage: i18n("Weather") }
            WidgetCheck { id: showDate; text: i18n("Date") }
            WidgetCheck { id: showDayNumber; text: i18n("Day number") }
            WidgetCheck { id: showClockStyle; text: i18n("Clock styles"); keywords: "flip analog segment"; optionsPage: i18n("Clock & Calendar") }
            WidgetCheck { id: showCalendar; text: i18n("Calendar (next event)"); keywords: "ical plane meeting"; optionsPage: i18n("Clock & Calendar") }
            WidgetCheck { id: showWorldClocks; text: i18n("World clocks"); keywords: "time zone"; optionsPage: i18n("Clock & Calendar") }
            WidgetCheck { id: showDayProgress; text: i18n("Day progress") }
            WidgetCheck { id: showMonthProgress; text: i18n("Month progress") }
            WidgetCheck { id: showYearProgress; text: i18n("Year progress") }
        }

        Card {
            title: i18n("Productivity")
            columns: 2
            WidgetCheck { id: showPomodoro; text: i18n("Pomodoro"); keywords: "focus timer" }
            WidgetCheck { id: showTimer; text: i18n("Timer"); keywords: "countdown" }
            WidgetCheck { id: showStopwatch; text: i18n("Stopwatch") }
            WidgetCheck { id: showTodos; text: i18n("Todos"); keywords: "tasks list" }
            WidgetCheck { id: showNotes; text: i18n("Notes") }
        }

        Card {
            title: i18n("System")
            columns: 2
            WidgetCheck { id: showStats; text: i18n("CPU and RAM"); keywords: "memory usage"; optionsPage: i18n("System") }
            WidgetCheck { id: showTemperature; text: i18n("CPU temperature"); optionsPage: i18n("System") }
            WidgetCheck { id: showNetwork; text: i18n("Network speed"); keywords: "download upload"; optionsPage: i18n("System") }
            WidgetCheck { id: showStorage; text: i18n("Disk usage"); keywords: "storage" }
            WidgetCheck { id: showScript; text: i18n("Script output"); keywords: "custom command shell"; optionsPage: i18n("System") }
            WidgetCheck { id: showBattery; text: i18n("Battery"); keywords: "power"; optionsPage: i18n("System") }
            WidgetCheck { id: showVolume; text: i18n("Volume slider"); keywords: "sound audio" }
            WidgetCheck { id: showToggles; text: i18n("Quick toggles"); keywords: "wifi bluetooth dnd night"; optionsPage: i18n("System") }
            WidgetCheck { id: showTray; text: i18n("System tray") }
        }

        Card {
            title: i18n("Apps, media and weather")
            columns: 2
            WidgetCheck { id: showStart; text: i18n("Application launcher"); keywords: "start menu"; optionsPage: i18n("Apps") }
            WidgetCheck { id: showApps; text: i18n("Pinned apps"); keywords: "dock taskbar"; optionsPage: i18n("Apps") }
            WidgetCheck { id: showMedia; text: i18n("Now playing"); keywords: "music spotify mpris" }
            WidgetCheck { id: showWeather; text: i18n("Weather"); optionsPage: i18n("Weather") }
            WidgetCheck { id: showRecycleBin; text: i18n("Recycle bin"); keywords: "trash" }
            WidgetCheck { id: showScreenshot; text: i18n("Screenshot capture") }
        }
    }
}
