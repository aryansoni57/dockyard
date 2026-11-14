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

    // {temp, code, max, min, uv, rain} from the last good response, or null.
    // uv is today's peak index and rain today's peak chance of rain, in percent.
    property var current: null
    // Next 12 hours: [{hour, temp, code, rain}], hour as 0..23 in the place's own time.
    property var hourly: []
    // Next 5 days: [{date, code, max, min, rain, uv}], date as a Date at local midnight.
    property var daily: []
    // "HH:mm" in the place's own time, or "".
    property string sunrise: ""
    property string sunset: ""
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

    // Plain-words condition for a WMO weather code.
    function describe(code) {
        if (code === 0) return i18n("Clear");
        if (code === 1) return i18n("Mostly clear");
        if (code === 2) return i18n("Partly cloudy");
        if (code === 3) return i18n("Overcast");
        if (code === 45 || code === 48) return i18n("Fog");
        if (code >= 51 && code <= 57) return i18n("Drizzle");
        if (code >= 61 && code <= 67) return i18n("Rain");
        if (code >= 71 && code <= 77) return i18n("Snow");
        if (code >= 80 && code <= 82) return i18n("Showers");
        if (code >= 85 && code <= 86) return i18n("Snow showers");
        if (code >= 95 && code <= 99) return i18n("Thunderstorm");
        return "";
    }

    // Runs a request queued while busy, once the previous one has finished.
    function drain() {
        if (pending) {
            pending = false;
            refresh();
        }
    }

    // Fills hourly, daily, sunrise and sunset. A missing field leaves its list empty;
    // the tiles that only need `current` keep working.
    function parseForecast(d) {
        try {
            const hours = [];
            const h = d.hourly;
            // Both "now" and the hourly times are in the place's own zone ("2026-11-13T14:15").
            const nowHour = String(d.current.time).slice(0, 13);
            let start = h.time.findIndex(t => String(t).slice(0, 13) >= nowHour);
            if (start < 0)
                start = 0;
            for (let i = start; i < Math.min(start + 12, h.time.length); ++i) {
                hours.push({
                    hour: parseInt(String(h.time[i]).slice(11, 13), 10),
                    temp: Math.round(h.temperature_2m[i]),
                    code: h.weather_code[i],
                    rain: h.precipitation_probability?.[i] ?? 0
                });
            }
            hourly = hours;
        } catch (e) {
            hourly = [];
        }
        try {
            const days = [];
            const dd = d.daily;
            for (let i = 0; i < Math.min(5, dd.time.length); ++i) {
                const p = String(dd.time[i]).split("-");
                days.push({
                    date: new Date(parseInt(p[0], 10), parseInt(p[1], 10) - 1, parseInt(p[2], 10)),
                    code: dd.weather_code[i],
                    max: Math.round(dd.temperature_2m_max[i]),
                    min: Math.round(dd.temperature_2m_min[i]),
                    rain: dd.precipitation_probability_max?.[i] ?? 0,
                    uv: Math.round(dd.uv_index_max?.[i] ?? 0)
                });
            }
            daily = days;
            sunrise = String(dd.sunrise?.[0] ?? "").slice(11, 16);
            sunset = String(dd.sunset?.[0] ?? "").slice(11, 16);
        } catch (e) {
            daily = [];
            sunrise = "";
            sunset = "";
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
                + "&hourly=temperature_2m,weather_code,precipitation_probability"
                + "&daily=temperature_2m_max,temperature_2m_min,weather_code,uv_index_max,precipitation_probability_max,sunrise,sunset"
                + "&forecast_days=5"
                + "&timezone=auto"
                + (fahrenheit ? "&temperature_unit=fahrenheit" : "");

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            src.busy = false;
            if (xhr.status !== 200) {
                src.current = null;
                src.hourly = [];
                src.daily = [];
                src.drain();
                return;
            }
            try {
                const d = JSON.parse(xhr.responseText);
                src.current = {
                    temp: Math.round(d.current.temperature_2m),
                    code: d.current.weather_code,
                    max: Math.round(d.daily.temperature_2m_max[0]),
                    min: Math.round(d.daily.temperature_2m_min[0]),
                    uv: Math.round(d.daily.uv_index_max?.[0] ?? 0),
                    rain: d.daily.precipitation_probability_max?.[0] ?? 0
                };
                src.parseForecast(d);
                src.lastFetch = Date.now();
            } catch (e) {
                src.current = null;
                src.hourly = [];
                src.daily = [];
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
