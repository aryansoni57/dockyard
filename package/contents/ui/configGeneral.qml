import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_showStart: showStart.checked
    property alias cfg_showClock: showClock.checked
    property alias cfg_showStats: showStats.checked
    property alias cfg_showMedia: showMedia.checked
    property alias cfg_statsInterval: statsInterval.value

    property alias cfg_showTemperature: showTemperature.checked
    property alias cfg_showNetwork: showNetwork.checked
    property alias cfg_showStorage: showStorage.checked
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
    property string cfg_clockStyle
    property alias cfg_showNotes: showNotes.checked
    property alias cfg_showVolume: showVolume.checked
    property alias cfg_showRecycleBin: showRecycleBin.checked
    property alias cfg_showScreenshot: showScreenshot.checked
    property alias cfg_showTray: showTray.checked

    property alias cfg_showCalendar: showCalendar.checked
    property alias cfg_calendarSource: calendarSource.text
    property alias cfg_planeUrl: planeUrl.text
    property alias cfg_planeWorkspace: planeWorkspace.text
    property alias cfg_planeApiKey: planeApiKey.text
    property alias cfg_batteryDevice: batteryDevice.text
    property alias cfg_latitude: latitude.text
    property alias cfg_longitude: longitude.text
    property alias cfg_fahrenheit: fahrenheit.checked
    property alias cfg_worldZones: worldZones.text
    property alias cfg_appLaunchers: appLaunchers.text
    property alias cfg_appsFromTaskManager: appsFromTaskManager.checked
    property string cfg_toggleItems
    property string cfg_toggleStyle

    // Every widget switch, for the counter and the presets.
    readonly property var switches: [showStart, showClock, showStats, showMedia, showTemperature, showNetwork,
        showStorage, showBattery, showWeather, showPomodoro, showTimer, showStopwatch, showWorldClocks,
        showTodos, showApps, showToggles, showMonthProgress, showDayProgress, showYearProgress,
        showDate, showDayNumber, showClockStyle, showNotes, showVolume, showRecycleBin, showScreenshot, showTray, showCalendar]
    readonly property int enabledCount: switches.filter(c => c.checked).length

    function applyPreset(on) {
        for (let i = 0; i < switches.length; i++)
            switches[i].checked = on.indexOf(switches[i]) >= 0;
    }

    readonly property var toggleKeys: [
        { key: "wifi", label: i18n("Wi-Fi") },
        { key: "bluetooth", label: i18n("Bluetooth") },
        { key: "dnd", label: i18n("Do Not Disturb") },
        { key: "nightlight", label: i18n("Night Light") },
        { key: "mute", label: i18n("Mute") }
    ]
    readonly property var clockStyles: [
        { value: "digital", text: i18n("Clock (seconds and date)") },
        { value: "flip", text: i18n("Flip clock") },
        { value: "worldanalog", text: i18n("World clocks (analog)") },
        { value: "classic", text: i18n("Analog classic") },
        { value: "classicdark", text: i18n("Analog classic dark") },
        { value: "minimal", text: i18n("Analog minimal") },
        { value: "week", text: i18n("7 days") },
        { value: "worldlist", text: i18n("World clock (list)") },
        { value: "worldtime", text: i18n("World time (first zone)") },
        { value: "today", text: i18n("Today") },
        { value: "segment", text: i18n("Segment clock") }
    ]

    function toggleOn(key) {
        return cfg_toggleItems.split(",").map(k => k.trim()).indexOf(key) >= 0;
    }
    function setToggle(key, on) {
        const have = cfg_toggleItems.split(",").map(k => k.trim()).filter(k => k !== "");
        const next = toggleKeys.map(t => t.key).filter(k => k === key ? on : have.indexOf(k) >= 0);
        cfg_toggleItems = next.join(",");
    }

    function setLocation(lat, lon, name) {
        latitude.text = Number(lat).toFixed(4);
        longitude.text = Number(lon).toFixed(4);
        locationStatus.text = name;
    }

    function getJson(url, onDone) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            try {
                if (xhr.status !== 200)
                    throw new Error(xhr.status);
                onDone(JSON.parse(xhr.responseText));
            } catch (e) {
                locationStatus.text = i18n("Lookup failed");
            }
        };
        locationStatus.text = i18n("Looking up…");
        xhr.open("GET", url);
        xhr.send();
    }

    function searchCity() {
        getJson("https://geocoding-api.open-meteo.com/v1/search?count=1&name="
                + encodeURIComponent(cityField.text.trim()), function (d) {
            if (!d.results || d.results.length === 0) {
                locationStatus.text = i18n("City not found");
                return;
            }
            var r = d.results[0];
            setLocation(r.latitude, r.longitude,
                        r.name + (r.country ? ", " + r.country : ""));
        });
    }

    function detectLocation() {
        getJson("https://ipapi.co/json/", function (d) {
            if (d.latitude === undefined || d.longitude === undefined)
                throw new Error("no coordinates");
            setLocation(d.latitude, d.longitude,
                        (d.city || "") + (d.country_name ? ", " + d.country_name : ""));
        });
    }

    // A titled card holding a grid of controls.
    component Group: ColumnLayout {
        id: group

        property string title
        property int columns: 2
        default property alias content: grid.data
        readonly property bool anyVisible: {
            for (let i = 0; i < grid.children.length; i++) {
                if (grid.children[i].visible)
                    return true;
            }
            return false;
        }

        visible: anyVisible
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            text: group.title.toUpperCase()
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
            opacity: 0.55
            Layout.leftMargin: Kirigami.Units.smallSpacing
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: grid.implicitHeight + Kirigami.Units.largeSpacing * 2
            radius: Kirigami.Units.cornerRadius * 2
            color: Qt.alpha(Kirigami.Theme.textColor, 0.04)
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.1)

            GridLayout {
                id: grid
                x: Kirigami.Units.largeSpacing
                y: Kirigami.Units.largeSpacing
                width: parent.width - Kirigami.Units.largeSpacing * 2
                columns: group.columns
                columnSpacing: Kirigami.Units.largeSpacing * 2
                rowSpacing: Kirigami.Units.smallSpacing
            }
        }
    }

    // A widget switch that hides itself when it does not match the search box.
    component WidgetCheck: QQC2.CheckBox {
        Layout.fillWidth: true
        visible: search.text.trim() === ""
            || text.toLowerCase().indexOf(search.text.trim().toLowerCase()) >= 0
    }

    // A label + field row inside a card.
    component Field: RowLayout {
        property string label
        default property alias field: holder.data

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            text: parent.label
            Layout.preferredWidth: Kirigami.Units.gridUnit * 9
            opacity: 0.8
        }
        RowLayout {
            id: holder
            Layout.fillWidth: true
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
                text: i18n("Drag tiles on the dock to reorder them. Mouse wheel scrolls a crowded dock.")
                opacity: 0.6
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Kirigami.SearchField {
                id: search
                Layout.fillWidth: true
                placeholderText: i18n("Search widgets")
            }
            RowLayout {
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    text: i18n("Presets:")
                    opacity: 0.6
                }
                QQC2.Button {
                    text: i18n("Minimal")
                    onClicked: page.applyPreset([showClock, showMedia, showApps])
                }
                QQC2.Button {
                    text: i18n("Everyday")
                    onClicked: page.applyPreset([showClock, showMedia, showApps, showWeather, showVolume,
                                                  showToggles, showBattery, showNotes])
                }
                QQC2.Button {
                    text: i18n("Monitor")
                    onClicked: page.applyPreset([showClock, showStats, showTemperature, showNetwork,
                                                  showStorage, showBattery, showMedia])
                }
                QQC2.Button {
                    text: i18n("All off")
                    onClicked: page.applyPreset([])
                }
            }
        }

        Group {
            title: i18n("Time and date")
            WidgetCheck { id: showClock; text: i18n("Clock") }
            WidgetCheck { id: showDate; text: i18n("Date") }
            WidgetCheck { id: showDayNumber; text: i18n("Day number") }
            WidgetCheck { id: showClockStyle; text: i18n("Clock styles") }
            WidgetCheck { id: showCalendar; text: i18n("Calendar (next event)") }
            WidgetCheck { id: showWorldClocks; text: i18n("World clocks") }
            WidgetCheck { id: showDayProgress; text: i18n("Day progress") }
            WidgetCheck { id: showMonthProgress; text: i18n("Month progress") }
            WidgetCheck { id: showYearProgress; text: i18n("Year progress") }
        }

        Group {
            title: i18n("Productivity")
            WidgetCheck { id: showPomodoro; text: i18n("Pomodoro") }
            WidgetCheck { id: showTimer; text: i18n("Timer") }
            WidgetCheck { id: showStopwatch; text: i18n("Stopwatch") }
            WidgetCheck { id: showTodos; text: i18n("Todos") }
            WidgetCheck { id: showNotes; text: i18n("Notes") }
        }

        Group {
            title: i18n("System")
            WidgetCheck { id: showStats; text: i18n("CPU and RAM") }
            WidgetCheck { id: showTemperature; text: i18n("CPU temperature") }
            WidgetCheck { id: showNetwork; text: i18n("Network speed") }
            WidgetCheck { id: showStorage; text: i18n("Disk usage") }
            WidgetCheck { id: showBattery; text: i18n("Battery") }
            WidgetCheck { id: showVolume; text: i18n("Volume slider") }
            WidgetCheck { id: showToggles; text: i18n("Quick toggles") }
            WidgetCheck { id: showTray; text: i18n("System tray") }
        }

        Group {
            title: i18n("Apps, media and weather")
            WidgetCheck { id: showStart; text: i18n("Application launcher") }
            WidgetCheck { id: showApps; text: i18n("Pinned apps") }
            WidgetCheck { id: showMedia; text: i18n("Now playing") }
            WidgetCheck { id: showWeather; text: i18n("Weather") }
            WidgetCheck { id: showRecycleBin; text: i18n("Recycle bin") }
            WidgetCheck { id: showScreenshot; text: i18n("Screenshot capture") }
        }

        // Options appear only for the widgets that use them.
        Group {
            title: i18n("Quick toggles")
            columns: 3
            visible: showToggles.checked
            QQC2.CheckBox {
                Layout.columnSpan: 3
                text: i18n("Show as a status strip (opens the quick settings flyout)")
                checked: page.cfg_toggleStyle !== "toggles"
                onToggled: page.cfg_toggleStyle = checked ? "strip" : "toggles"
            }
            Repeater {
                model: page.toggleKeys
                QQC2.CheckBox {
                    required property var modelData
                    text: modelData.label
                    checked: page.toggleOn(modelData.key)
                    onToggled: page.setToggle(modelData.key, checked)
                }
            }
        }

        Group {
            title: i18n("Pinned apps")
            columns: 1
            visible: showApps.checked
            QQC2.CheckBox {
                id: appsFromTaskManager
                text: i18n("Use the pinned apps of the Task Manager")
            }
            Field {
                label: i18n("Own list:")
                enabled: !appsFromTaskManager.checked
                QQC2.TextField {
                    id: appLaunchers
                    Layout.fillWidth: true
                    placeholderText: "preferred://browser,applications:org.kde.dolphin.desktop"
                }
            }
        }

        Group {
            title: i18n("Weather and location")
            columns: 1
            visible: showWeather.checked || showClock.checked || showClockStyle.checked
            Field {
                label: i18n("Find city:")
                QQC2.TextField {
                    id: cityField
                    Layout.fillWidth: true
                    placeholderText: i18n("e.g. Mumbai")
                    onAccepted: if (text.trim() !== "") page.searchCity()
                }
                QQC2.Button {
                    text: i18n("Search")
                    enabled: cityField.text.trim() !== ""
                    onClicked: page.searchCity()
                }
            }
            Field {
                label: i18n("Coordinates:")
                QQC2.TextField {
                    id: latitude
                    Layout.fillWidth: true
                    placeholderText: i18n("Latitude")
                    validator: DoubleValidator { bottom: -90; top: 90 }
                }
                QQC2.TextField {
                    id: longitude
                    Layout.fillWidth: true
                    placeholderText: i18n("Longitude")
                    validator: DoubleValidator { bottom: -180; top: 180 }
                }
            }
            Field {
                label: ""
                QQC2.Button {
                    icon.name: "mark-location"
                    text: i18n("Detect my location")
                    onClicked: page.detectLocation()
                }
                QQC2.Label {
                    id: locationStatus
                    opacity: 0.7
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
            QQC2.CheckBox {
                id: fahrenheit
                text: i18n("Show temperatures in Fahrenheit")
            }
        }

        Group {
            title: i18n("Clock style")
            columns: 1
            QQC2.Switch {
                Layout.fillWidth: true
                text: i18n("Show the clock style tile on the dock")
                checked: showClockStyle.checked
                onToggled: showClockStyle.checked = checked
            }
            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                opacity: showClockStyle.checked ? 1 : 0.5

                Repeater {
                    model: page.clockStyles

                    QQC2.AbstractButton {
                        id: chip
                        required property var modelData
                        readonly property bool picked: modelData.value === page.cfg_clockStyle
                        padding: Kirigami.Units.largeSpacing
                        topPadding: Kirigami.Units.smallSpacing * 1.5
                        bottomPadding: Kirigami.Units.smallSpacing * 1.5
                        text: modelData.text
                        onClicked: {
                            page.cfg_clockStyle = modelData.value;
                            showClockStyle.checked = true;
                        }

                        background: Rectangle {
                            radius: Kirigami.Units.cornerRadius * 2
                            color: chip.picked ? Qt.alpha(Kirigami.Theme.highlightColor, 0.2)
                                : Qt.alpha(Kirigami.Theme.textColor, chip.hovered ? 0.1 : 0.05)
                            border.width: 1
                            border.color: chip.picked ? Kirigami.Theme.highlightColor
                                : Qt.alpha(Kirigami.Theme.textColor, 0.12)
                        }
                        contentItem: QQC2.Label {
                            text: chip.text
                            color: chip.picked ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                            font.weight: chip.picked ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }
        }

        Group {
            title: i18n("World clocks")
            columns: 1
            visible: showWorldClocks.checked || showClockStyle.checked
            Field {
                label: i18n("Time zones:")
                QQC2.TextField {
                    id: worldZones
                    Layout.fillWidth: true
                    placeholderText: "America/New_York,Europe/London,Asia/Tokyo"
                }
            }
        }

        Group {
            title: i18n("Sensors")
            columns: 1
            visible: showStats.checked || showTemperature.checked || showNetwork.checked || showBattery.checked
            Field {
                label: i18n("Refresh every:")
                QQC2.SpinBox {
                    id: statsInterval
                    from: 500
                    to: 60000
                    stepSize: 500
                    textFromValue: (v, locale) => i18n("%1 ms", v)
                    valueFromText: (t, locale) => parseInt(t) || 2000
                }
            }
            Field {
                label: i18n("Calendar (iCal URL or .ics file):")
                visible: showCalendar.checked
                QQC2.TextField {
                    id: calendarSource
                    Layout.fillWidth: true
                    placeholderText: "https://calendar.google.com/calendar/ical/.../basic.ics"
                }
            }
            Field {
                label: i18n("Plane URL (change for self-hosted):")
                visible: showCalendar.checked
                QQC2.TextField {
                    id: planeUrl
                    Layout.fillWidth: true
                    placeholderText: "https://api.plane.so"
                }
            }
            Field {
                label: i18n("Plane workspace slug:")
                visible: showCalendar.checked
                QQC2.TextField {
                    id: planeWorkspace
                    Layout.fillWidth: true
                    placeholderText: "my-workspace"
                }
            }
            Field {
                label: i18n("Plane API key:")
                visible: showCalendar.checked
                QQC2.TextField {
                    id: planeApiKey
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    placeholderText: "plane_api_..."
                }
            }
            Field {
                label: i18n("Battery device:")
                visible: showBattery.checked
                QQC2.TextField {
                    id: batteryDevice
                    Layout.fillWidth: true
                    placeholderText: "SerialNumber"
                }
            }
        }
    }
}
