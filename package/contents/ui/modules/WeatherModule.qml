import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Weather tile: current temperature and today's high/low from Open-Meteo
// (no API key). Refreshes every 30 minutes, and only while visible.
// Any failure shows "--°" and waits for the next tick; nothing throws.
Tile {
    id: weather

    property real latitude
    property real longitude
    property bool fahrenheit: false

    readonly property bool hasLocation: latitude !== 0 || longitude !== 0
    readonly property real inner: height - padding * 2
    readonly property int intervalMs: 30 * 60 * 1000

    // {temp, code, max, min} from the last good response, or null.
    property var current: null
    property double lastFetch: 0
    property bool busy: false

    implicitWidth: Math.min(Kirigami.Units.gridUnit * 9,
                            hasLocation ? content.implicitWidth : setLabel.implicitWidth)
                   + padding * 2

    function iconFor(code) {
        if (code === 0) return "weather-clear";
        if (code <= 2) return "weather-few-clouds";
        if (code === 3) return "weather-overcast";
        if (code === 45 || code === 48) return "weather-fog";
        if (code >= 51 && code <= 67) return "weather-showers";
        if (code >= 71 && code <= 77) return "weather-snow";
        if (code >= 80 && code <= 82) return "weather-showers";
        if (code >= 85 && code <= 86) return "weather-snow";
        if (code >= 95 && code <= 99) return "weather-storm";
        return "weather-none";
    }

    function refresh() {
        if (!hasLocation || busy)
            return;

        busy = true;
        var xhr = new XMLHttpRequest();
        var url = "https://api.open-meteo.com/v1/forecast"
                + "?latitude=" + latitude.toFixed(4)
                + "&longitude=" + longitude.toFixed(4)
                + "&current=temperature_2m,weather_code"
                + "&daily=temperature_2m_max,temperature_2m_min"
                + "&timezone=auto"
                + (fahrenheit ? "&temperature_unit=fahrenheit" : "");

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            weather.busy = false;
            if (xhr.status !== 200) {
                weather.current = null;
                return;
            }
            try {
                const d = JSON.parse(xhr.responseText);
                weather.current = {
                    temp: Math.round(d.current.temperature_2m),
                    code: d.current.weather_code,
                    max: Math.round(d.daily.temperature_2m_max[0]),
                    min: Math.round(d.daily.temperature_2m_min[0])
                };
                weather.lastFetch = Date.now();
            } catch (e) {
                weather.current = null;
            }
        };

        try {
            xhr.open("GET", url);
            xhr.send();
        } catch (e) {
            busy = false;
            current = null;
        }
    }

    Component.onCompleted: refresh()
    onLatitudeChanged: refresh()
    onLongitudeChanged: refresh()
    onFahrenheitChanged: refresh()
    onVisibleChanged: {
        if (visible && Date.now() - lastFetch > intervalMs)
            refresh();
    }

    Timer {
        interval: weather.intervalMs
        repeat: true
        running: weather.visible && weather.hasLocation
        onTriggered: weather.refresh()
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: weather.padding
        spacing: weather.padding
        visible: weather.hasLocation

        Kirigami.Icon {
            Layout.preferredWidth: weather.inner
            Layout.preferredHeight: weather.inner
            visible: weather.current !== null
            source: weather.current !== null ? weather.iconFor(weather.current.code) : ""
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: weather.current !== null ? weather.current.temp + "°" : "--°"
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, weather.inner * 0.5)
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: weather.current !== null && weather.inner >= Kirigami.Units.gridUnit * 1.5
                text: weather.current !== null
                      ? "H " + weather.current.max + "° L " + weather.current.min + "°"
                      : ""
                font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, weather.inner * 0.2)
                font.features: { "tnum": 1 }
                opacity: 0.6
                elide: Text.ElideRight
            }
        }
    }

    PlasmaComponents.Label {
        id: setLabel
        anchors.fill: parent
        anchors.margins: weather.padding
        visible: !weather.hasLocation
        text: "Set location"
        font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, weather.inner * 0.2)
        opacity: 0.6
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
