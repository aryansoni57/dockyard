import QtQuick

// Open-Meteo current weather (no API key). One instance lives in main.qml and
// feeds the clock and weather tiles. Refreshes every 30 minutes while `active`,
// and at once when location or units change. A request made while one is in
// flight runs after it. Any failure sets `current` to null and waits for the
// next tick; nothing throws.
Item {
    id: src

    property real latitude
    property real longitude
    property bool fahrenheit: false
    property bool active: true

    readonly property bool hasLocation: latitude !== 0 || longitude !== 0
    readonly property int intervalMs: 30 * 60 * 1000

    // {temp, code, max, min} from the last good response, or null.
    property var current: null
    property double lastFetch: 0
    property bool busy: false
    property bool pending: false

    // Location and units of the last request sent.
    property real fetchedLat: 0
    property real fetchedLon: 0
    property bool fetchedF: false

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

    // Runs a request queued while busy, once the previous one has finished.
    function drain() {
        if (pending) {
            pending = false;
            refresh();
        }
    }

    function refresh() {
        if (!hasLocation)
            return;
        if (busy) {
            pending = true;
            return;
        }

        busy = true;
        fetchedLat = latitude;
        fetchedLon = longitude;
        fetchedF = fahrenheit;
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
            src.busy = false;
            if (xhr.status !== 200) {
                src.current = null;
                src.drain();
                return;
            }
            try {
                const d = JSON.parse(xhr.responseText);
                src.current = {
                    temp: Math.round(d.current.temperature_2m),
                    code: d.current.weather_code,
                    max: Math.round(d.daily.temperature_2m_max[0]),
                    min: Math.round(d.daily.temperature_2m_min[0])
                };
                src.lastFetch = Date.now();
            } catch (e) {
                src.current = null;
            }
            src.drain();
        };

        try {
            xhr.open("GET", url);
            xhr.send();
        } catch (e) {
            busy = false;
            current = null;
            drain();
        }
    }

    Component.onCompleted: if (active) refresh()
    onLatitudeChanged: if (active) refresh()
    onLongitudeChanged: if (active) refresh()
    onFahrenheitChanged: if (active) refresh()
    onActiveChanged: {
        if (active && (Date.now() - lastFetch > intervalMs
                       || fetchedLat !== latitude
                       || fetchedLon !== longitude
                       || fetchedF !== fahrenheit))
            refresh();
    }

    Timer {
        interval: src.intervalMs
        repeat: true
        running: src.active && src.hasLocation
        onTriggered: src.refresh()
    }
}
