pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Weather popup: today's temperature with a UV ring, the next 12 hours, a plain
// rain hint, and five days with their ranges. Data comes from the shared WeatherSource.
ColumnLayout {
    id: panel

    property var applet
    readonly property var source: applet.weatherSource
    readonly property var current: source.current
    readonly property var hourly: source.hourly
    readonly property var daily: source.daily

    spacing: Kirigami.Units.smallSpacing

    // Whole-popup padding; the popup window adds none of its own to this content.
    readonly property real pad: Kirigami.Units.largeSpacing

    function uvLevel(uv) {
        if (uv >= 11) return { text: i18n("Extreme"), color: "#bf5af2" };
        if (uv >= 8) return { text: i18n("Very high"), color: "#ff453a" };
        if (uv >= 6) return { text: i18n("High"), color: "#ff9f0a" };
        if (uv >= 3) return { text: i18n("Moderate"), color: "#ffd60a" };
        return { text: i18n("Low"), color: "#30d158" };
    }
    readonly property var uv: uvLevel(current ? current.uv : 0)

    // First hour in the next 12 with a real chance of rain, or null.
    readonly property var rainHour: {
        for (const h of hourly) {
            if (h.rain >= 50)
                return h;
        }
        return null;
    }
    function hourText(h) {
        return (h < 10 ? "0" : "") + h + ":00";
    }
    readonly property string rainHint: {
        if (rainHour)
            return i18n("Rain likely from %1, %2% chance. Take an umbrella if you head out.", hourText(rainHour.hour), rainHour.rain);
        if (hourly.length > 0)
            return i18n("No rain expected in the next %1 hours.", hourly.length);
        return "";
    }

    // Range bars share one scale, so a warm day sits to the right of a cold one.
    readonly property real rangeMin: daily.length > 0 ? Math.min(...daily.map(d => d.min)) : 0
    readonly property real rangeMax: daily.length > 0 ? Math.max(...daily.map(d => d.max)) : 1
    readonly property real rangeSpan: Math.max(1, rangeMax - rangeMin)

    implicitHeight: content.implicitHeight + pad * 2

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: panel.pad
        spacing: Kirigami.Units.largeSpacing

        // Now.
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing
            visible: panel.current !== null

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Kirigami.Units.iconSizes.large
                source: panel.current ? panel.source.iconFor(panel.current.code) : ""
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents.Label {
                    text: panel.current ? panel.current.temp + "°" : "--°"
                    font.pixelSize: Kirigami.Units.gridUnit * 2.2
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: panel.current
                        ? [panel.source.describe(panel.current.code), i18n("H %1° L %2°", panel.current.max, panel.current.min)]
                            .filter(t => t !== "").join("  ·  ")
                        : ""
                    opacity: 0.6
                    elide: Text.ElideRight
                }
                PlasmaComponents.Label {
                    visible: panel.source.sunrise !== "" && panel.source.sunset !== ""
                    text: i18n("Sunrise %1  ·  Sunset %2", panel.source.sunrise, panel.source.sunset)
                    opacity: 0.6
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                }
            }
            RingGauge {
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3.6
                Layout.preferredWidth: Layout.preferredHeight
                value: Math.min(100, (panel.current ? panel.current.uv : 0) / 11 * 100)
                text: String(panel.current ? panel.current.uv : 0)
                label: i18n("UV")
                accent: panel.uv.color
                PlasmaComponents.ToolTip.text: i18n("UV index: %1", panel.uv.text)
                PlasmaComponents.ToolTip.visible: uvHover.hovered
                HoverHandler { id: uvHover }
            }
        }

        // Hourly strip.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 5.6
            visible: panel.hourly.length > 0
            radius: Kirigami.Units.gridUnit * 0.6
            color: Qt.alpha(Kirigami.Theme.textColor, 0.055)
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.09)

            ListView {
                id: strip
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                orientation: ListView.Horizontal
                clip: true
                interactive: contentWidth > width
                boundsBehavior: Flickable.StopAtBounds
                model: panel.hourly

                // A vertical wheel scrolls the strip sideways.
                WheelHandler {
                    onWheel: event => {
                        strip.contentX = Math.max(0, Math.min(strip.contentWidth - strip.width,
                            strip.contentX - (event.angleDelta.y + event.angleDelta.x) / 2));
                    }
                }

                delegate: ColumnLayout {
                    id: cell
                    required property var modelData
                    required property int index
                    width: Kirigami.Units.gridUnit * 2.9
                    height: strip.height
                    spacing: 0

                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: cell.index === 0 ? i18n("Now") : String(cell.modelData.hour)
                        opacity: 0.6
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                        source: panel.source.iconFor(cell.modelData.code)
                    }
                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: cell.modelData.temp + "°"
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                    }
                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignHCenter
                        // Only a chance worth mentioning, so the strip stays quiet on dry days.
                        text: cell.modelData.rain >= 20 ? cell.modelData.rain + "%" : " "
                        color: "#5ac8fa"
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }

        // Rain hint.
        Rectangle {
            Layout.fillWidth: true
            visible: panel.rainHint !== ""
            implicitHeight: hint.implicitHeight + Kirigami.Units.largeSpacing
            radius: Kirigami.Units.gridUnit * 0.6
            color: Qt.alpha(Kirigami.Theme.textColor, 0.055)
            border.width: 1
            border.color: panel.rainHour ? Qt.alpha("#5ac8fa", 0.35) : Qt.alpha(Kirigami.Theme.textColor, 0.09)

            RowLayout {
                id: hint
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing + 2
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    source: panel.rainHour ? "weather-showers-symbolic" : "weather-clear-symbolic"
                    color: panel.rainHour ? "#5ac8fa" : Kirigami.Theme.textColor
                    isMask: true
                }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: panel.rainHint
                    wrapMode: Text.Wrap
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                }
            }
        }

        // Five days.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            visible: panel.daily.length > 0

            Repeater {
                model: panel.daily

                delegate: RowLayout {
                    id: day
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.6
                        text: day.index === 0 ? i18n("Today") : Qt.formatDate(day.modelData.date, "ddd")
                    }
                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                        source: panel.source.iconFor(day.modelData.code)
                    }
                    PlasmaComponents.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        horizontalAlignment: Text.AlignRight
                        text: day.modelData.min + "°"
                        opacity: 0.6
                        font.features: { "tnum": 1 }
                    }
                    // Where this day's range sits between the coldest and warmest of the five.
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        radius: 2
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.15)

                        Rectangle {
                            height: parent.height
                            radius: 2
                            x: parent.width * (day.modelData.min - panel.rangeMin) / panel.rangeSpan
                            width: Math.max(4, parent.width * (day.modelData.max - day.modelData.min) / panel.rangeSpan)
                            color: panel.applet.accent
                        }
                    }
                    PlasmaComponents.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        text: day.modelData.max + "°"
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            visible: panel.current === null
            text: i18n("Weather is not available right now.")
            opacity: 0.6
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
