import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Weather tile: current temperature and today's high/low from Open-Meteo
// (no API key). Data comes from the shared WeatherSource in main.qml.
// Any failure shows "--°" and waits for the next tick; nothing throws.
Tile {
    id: weather

    // WeatherSource from main.qml (null when not wired).
    property var weatherSource: null

    readonly property bool hasLocation: weatherSource ? weatherSource.hasLocation : false
    readonly property var current: weatherSource ? weatherSource.current : null
    readonly property real inner: height - padding * 2

    implicitWidth: Math.min(Kirigami.Units.gridUnit * 9,
                            hasLocation ? content.implicitWidth : setLabel.implicitWidth)
                   + padding * 2

    function iconFor(code) {
        return weatherSource ? weatherSource.iconFor(code) : "";
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
