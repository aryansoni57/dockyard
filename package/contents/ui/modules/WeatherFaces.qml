import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"
import "../components/accent"

// Weather faces (website "Weather Details", "Today & Forecast", "Weather Status",
// "Hourly", "Sunrise & Sunset"). Content for the Weather tile, five faces chosen by `variant`:
// details, forecast, status, hourly, sun. Data comes from the shared WeatherSource.
Item {
    id: tile
    property real padding: Math.round(height * 0.14)
    property real radius: height * 0.24

    property string variant: "details"
    property var weatherSource: null

    readonly property var current: weatherSource ? weatherSource.current : null
    readonly property var hourly: weatherSource ? weatherSource.hourly : []
    readonly property var daily: weatherSource ? weatherSource.daily : []
    readonly property string sunrise: weatherSource ? weatherSource.sunrise : ""
    readonly property string sunset: weatherSource ? weatherSource.sunset : ""
    readonly property real inner: height - padding * 2
    readonly property real small: Math.max(7, inner * 0.2)

    implicitWidth: Math.round(height * ({ details: 2.3, forecast: 3.4, status: 2.4, hourly: 3.6, sun: 2.6 }[variant] ?? 2.4))

    function icon(code) { return weatherSource ? weatherSource.iconFor(code) : ""; }
    function pad(n) { return (n < 10 ? "0" : "") + n; }
    function hourLabel(h) { return pad(h) + ":00"; }
    function minutes(hhmm) {
        const p = String(hhmm).split(":");
        return p.length === 2 ? parseInt(p[0], 10) * 60 + parseInt(p[1], 10) : -1;
    }
    // 0..1 position of now between sunrise and sunset, clamped.
    readonly property real sunPos: {
        const a = minutes(sunrise), b = minutes(sunset);
        if (a < 0 || b <= a)
            return 0;
        const d = new Date();
        return Math.max(0, Math.min(1, (d.getHours() * 60 + d.getMinutes() - a) / (b - a)));
    }

    PlasmaComponents.Label {
        anchors.centerIn: parent
        visible: tile.current === null
        text: tile.weatherSource && tile.weatherSource.hasLocation ? "--°" : i18n("Set location")
        opacity: 0.78
        font.pixelSize: tile.small
    }

    // Details: temperature, wind, rain chance, UV.
    Row {
        visible: tile.current !== null && tile.variant === "details"
        anchors.fill: parent
        anchors.margins: tile.padding
        anchors.leftMargin: tile.padding * 1.3
        spacing: tile.inner * 0.2

        Column {
            anchors.verticalCenter: parent.verticalCenter
            PlasmaComponents.Label {
                text: tile.current ? tile.current.temp + "°" : ""
                font.pixelSize: tile.inner * 0.5
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
            }
            PlasmaComponents.Label {
                text: tile.current ? "H " + tile.current.max + "°  L " + tile.current.min + "°" : ""
                font.pixelSize: tile.small
                opacity: 0.78
                font.features: { "tnum": 1 }
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: tile.inner * 0.04
            Repeater {
                model: tile.current ? [
                    { icon: "weather-windy", text: tile.current.wind + " km/h" },
                    { icon: "weather-showers", text: tile.current.rain + "%" },
                    { icon: "weather-clear", text: "UV " + tile.current.uv }
                ] : []
                Row {
                    required property var modelData
                    spacing: 4
                    Kirigami.Icon { width: tile.small; height: width; source: parent.modelData.icon }
                    PlasmaComponents.Label {
                        text: parent.modelData.text
                        font.pixelSize: tile.small
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }
    }

    // Today and the next three days.
    Row {
        visible: tile.current !== null && tile.variant === "forecast"
        anchors.fill: parent
        anchors.margins: tile.padding
        spacing: 0

        Repeater {
            model: tile.daily.slice(0, 4)
            Column {
                required property var modelData
                required property int index
                width: parent.width / 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: tile.inner * 0.03
                PlasmaComponents.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: index === 0 ? i18n("Today") : Qt.locale().dayName(modelData.date.getDay(), Locale.ShortFormat)
                    font.pixelSize: tile.small
                    font.weight: Font.DemiBold
                    opacity: 0.78
                }
                Kirigami.Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: tile.inner * 0.34; height: width
                    source: tile.icon(modelData.code)
                }
                PlasmaComponents.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.max + "° " + modelData.min + "°"
                    font.pixelSize: tile.small
                    font.features: { "tnum": 1 }
                }
            }
        }
    }

    // Status: condition in words, big temperature.
    Row {
        visible: tile.current !== null && tile.variant === "status"
        anchors.fill: parent
        anchors.margins: tile.padding
        anchors.leftMargin: tile.padding * 1.3
        spacing: tile.inner * 0.12

        Kirigami.Icon {
            anchors.verticalCenter: parent.verticalCenter
            width: tile.inner * 0.62; height: width
            source: tile.current ? tile.icon(tile.current.code) : ""
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            PlasmaComponents.Label {
                text: tile.current ? tile.current.temp + "°" : ""
                font.pixelSize: tile.inner * 0.46
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
            }
            PlasmaComponents.Label {
                text: tile.current && tile.weatherSource ? tile.weatherSource.describe(tile.current.code) : ""
                font.pixelSize: tile.small
                opacity: 0.78
            }
        }
    }

    // Hourly: next six hours.
    Row {
        visible: tile.current !== null && tile.variant === "hourly"
        anchors.fill: parent
        anchors.margins: tile.padding
        spacing: 0

        Repeater {
            model: tile.hourly.slice(0, 6)
            Column {
                required property var modelData
                width: parent.width / 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: tile.inner * 0.03
                PlasmaComponents.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.hour
                    font.pixelSize: tile.small
                    opacity: 0.7
                    font.features: { "tnum": 1 }
                }
                Kirigami.Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: tile.inner * 0.34; height: width
                    source: tile.icon(modelData.code)
                }
                PlasmaComponents.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.temp + "°"
                    font.pixelSize: tile.small
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }
            }
        }
    }

    // Sunrise and sunset: an arc with the sun's position and the two times.
    Item {
        visible: tile.variant === "sun" && tile.sunrise !== ""
        anchors.fill: parent
        anchors.margins: tile.padding
        anchors.leftMargin: tile.padding * 1.3
        anchors.rightMargin: tile.padding * 1.3

        Canvas {
            id: arc
            width: parent.width
            height: parent.height * 0.5
            property real pos: tile.sunPos
            property color line: Qt.alpha(Kirigami.Theme.textColor, 0.25)
            property color sun: DockAccent.color
            onPosChanged: requestPaint()
            onLineChanged: requestPaint()
            onSunChanged: requestPaint()
            onWidthChanged: requestPaint()
            onPaint: {
                const c = getContext("2d");
                c.reset();
                const r = Math.min(width / 2 - 4, height - 4);
                const cx = width / 2, cy = height - 2;
                c.lineWidth = 2;
                c.strokeStyle = line;
                c.beginPath();
                c.arc(cx, cy, r, Math.PI, 2 * Math.PI);
                c.stroke();
                const a = Math.PI + pos * Math.PI;
                c.fillStyle = sun;
                c.beginPath();
                c.arc(cx + r * Math.cos(a), cy + r * Math.sin(a), 4, 0, 2 * Math.PI);
                c.fill();
            }
        }
        PlasmaComponents.Label {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            text: "↑ " + tile.sunrise
            font.pixelSize: tile.small
            font.features: { "tnum": 1 }
        }
        PlasmaComponents.Label {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: "↓ " + tile.sunset
            font.pixelSize: tile.small
            font.features: { "tnum": 1 }
        }
    }
}
