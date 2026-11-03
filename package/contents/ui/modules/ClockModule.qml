import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Clock tile (docs/STYLE.md, "Fixed-color tiles"; demo video 0:06): a red top
// band with the time over a black bottom with the weekday and day number, plus
// a light weather circle with the temperature when a location is set.
// The colors are fixed, so the tile reads the same on light and dark themes.
Tile {
    id: clock

    property date now
    // WeatherSource from main.qml (null when not wired).
    property var weatherSource: null

    readonly property string timeFormat: Qt.locale().timeFormat(Locale.ShortFormat).replace(/'[^']*'/g, "")
    readonly property bool twelveHour: /[aA]/.test(timeFormat)
    readonly property var weather: weatherSource ? weatherSource.current : null
    readonly property real band: height * 0.5

    color: "#000000"
    border.color: Qt.alpha("white", 0.14)
    implicitWidth: Math.round(height * 1.12)

    // Red band; the second rectangle squares off its lower corners.
    Rectangle {
        id: top
        width: parent.width
        height: clock.band
        radius: clock.radius
        color: "#FF3B30"
    }
    Rectangle {
        y: clock.band - clock.radius
        width: parent.width
        height: clock.radius
        color: "#FF3B30"
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: (clock.band - height) / 2
        spacing: clock.height * 0.03

        PlasmaComponents.Label {
            id: timeText
            text: Qt.formatTime(clock.now, clock.twelveHour ? "h:mm" : "HH:mm")
            color: "white"
            font.pixelSize: Math.max(10, clock.height * 0.3)
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }
        PlasmaComponents.Label {
            visible: clock.twelveHour
            anchors.baseline: timeText.baseline
            text: Qt.formatTime(clock.now, "AP")
            color: "white"
            font.pixelSize: Math.max(6, clock.height * 0.15)
            font.weight: Font.DemiBold
        }
    }

    Column {
        x: clock.padding * 1.1
        y: clock.band + (clock.height - clock.band - height) / 2

        PlasmaComponents.Label {
            text: Qt.locale().dayName(clock.now.getDay(), Locale.ShortFormat)
            color: "white"
            opacity: 0.8
            font.pixelSize: Math.max(7, clock.height * 0.17)
            font.weight: Font.DemiBold
        }
        PlasmaComponents.Label {
            text: clock.now.getDate()
            color: "white"
            font.pixelSize: Math.max(9, clock.height * 0.26)
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }
    }

    Rectangle {
        visible: clock.weather !== null
        width: clock.height * 0.36
        height: width
        radius: width / 2
        x: clock.width - width - clock.padding * 0.9
        y: clock.band + (clock.height - clock.band - height) / 2
        color: Qt.alpha("white", 0.88)

        PlasmaComponents.Label {
            anchors.centerIn: parent
            text: clock.weather !== null ? clock.weather.temp + "°" : ""
            color: "#1C1C1E"
            font.pixelSize: Math.max(6, parent.width * 0.4)
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }
    }
}
