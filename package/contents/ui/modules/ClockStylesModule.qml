import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Clock styles tile: one tile, many looks,
// picked by `style` (config clockStyle). Only the chosen style is loaded.
// One Timer drives every style: 100 ms while a sweeping second hand is shown,
// otherwise once a second; it stops while the tile is hidden.
//
// Styles: digital, flip, worldanalog, classic, classicdark, minimal, week,
// worldlist, worldtime, today, segment.
Tile {
    id: tile

    property string style: "digital"
    property var zones: ["America/New_York", "Europe/London", "Asia/Tokyo"]
    // WeatherSource from main.qml (null when not wired).
    property var weatherSource: null

    property date now: new Date()

    readonly property real inner: height - padding * 2
    readonly property bool sweep: style === "classic" || style === "classicdark" || style === "minimal"
    readonly property var weather: weatherSource ? weatherSource.current : null

    readonly property string timeFormat: Qt.locale().timeFormat(Locale.ShortFormat).replace(/'[^']*'/g, "")
    readonly property bool twelveHour: /[aA]/.test(timeFormat)

    readonly property color red: "#FF3B30"
    readonly property color blue: "#0A84FF"
    readonly property color orange: "#FF9F0A"
    readonly property color sunColor: "#FFD60A"
    readonly property color moonColor: "#A9A6F5"

    // Square for the round faces; otherwise the style's own width plus padding.
    readonly property real hPad: padding * 1.4
    implicitWidth: sweep ? height
                         : Math.ceil((loader.item ? loader.item.implicitWidth : height) + hPad * 2)

    Timer {
        interval: tile.sweep ? 100 : 1000
        running: tile.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: tile.now = new Date()
    }

    // Hidden tile used only for its time-zone maths (same as the popup does).
    WorldClocksModule {
        id: zoneMath
        visible: false
        zones: []
        now: tile.now
    }

    // ---- Helpers ----

    function hourText(d, utc) {
        const h = utc ? d.getUTCHours() : d.getHours();
        if (!twelveHour)
            return String(h).padStart(2, "0");
        return String(h % 12 === 0 ? 12 : h % 12);
    }
    function minuteText(d, utc) {
        return String(utc ? d.getUTCMinutes() : d.getMinutes()).padStart(2, "0");
    }
    function ampm(d, utc) {
        return (utc ? d.getUTCHours() : d.getHours()) < 12 ? "AM" : "PM";
    }

    // Two-word cities get initials, known ones their airport-style code.
    readonly property var codes: ({
        "America/New_York": "NYC", "America/Los_Angeles": "LAX", "Europe/London": "LON",
        "Asia/Tokyo": "TYO", "Asia/Hong_Kong": "HKG", "Asia/Singapore": "SIN",
        "Australia/Sydney": "SYD", "Europe/Paris": "PAR", "Asia/Kolkata": "DEL",
        "Asia/Dubai": "DXB", "Asia/Shanghai": "SHA", "UTC": "UTC"
    })
    function codeOf(zone) {
        if (codes[zone] !== undefined)
            return codes[zone];
        return zoneMath.cityName(zone).replace(/ /g, "").slice(0, 3).toUpperCase();
    }

    // {name, code, known, d (shifted Date: read with getUTC*), diff (minutes vs local), day}
    function zoneInfo(zone) {
        const off = zoneMath.offsetIn(zone);
        const t = tile.now.getTime();
        const localOff = -tile.now.getTimezoneOffset();
        const known = off !== null;
        const d = new Date(t + (known ? off : localOff) * 60000);
        const localD = new Date(t + localOff * 60000);
        const dayDiff = Math.round((Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate())
                                  - Date.UTC(localD.getUTCFullYear(), localD.getUTCMonth(), localD.getUTCDate())) / 86400000);
        const h = d.getUTCHours();
        return {
            name: zoneMath.cityName(zone),
            code: codeOf(zone),
            known: known,
            d: d,
            diff: known ? off - localOff : 0,
            day: dayDiff,
            daytime: h >= 6 && h < 18
        };
    }
    function diffText(min) {
        if (min === 0)
            return "0h";
        const sign = min < 0 ? "−" : "+";
        const a = Math.abs(min);
        const h = Math.floor(a / 60), m = a % 60;
        return sign + h + "h" + (m ? String(m).padStart(2, "0") : "");
    }
    function dayWord(n) {
        return n === 0 ? i18n("Today") : n > 0 ? i18n("Tomorrow") : i18n("Yesterday");
    }
    function zoneTime(info) {
        return info.known ? hourText(info.d, true) + ":" + minuteText(info.d, true) : "--:--";
    }

    // ---- Shared bits ----

    // Sun (day) or crescent moon (night) marker.
    component DayDot: Canvas {
        id: dot
        property bool daytime: true
        implicitWidth: Math.round(tile.inner * 0.22)
        implicitHeight: implicitWidth
        onDaytimeChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const r = Math.min(width, height) / 2;
            ctx.fillStyle = daytime ? tile.sunColor : tile.moonColor;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, r * (daytime ? 0.8 : 0.9), 0, Math.PI * 2);
            ctx.fill();
            if (!daytime) {
                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath();
                ctx.arc(width / 2 + r * 0.5, height / 2 - r * 0.35, r * 0.75, 0, Math.PI * 2);
                ctx.fill();
            }
        }
    }

    component Txt: PlasmaComponents.Label {
        property real size: 0.3
        font.pixelSize: Math.max(7, Math.round(tile.inner * size))
        font.features: { "tnum": 1 }
        color: Kirigami.Theme.textColor
    }

    // Weather icon + temperature (hidden without data).
    component WeatherBit: Row {
        property real size: 0.3
        visible: tile.weather !== null
        spacing: tile.inner * 0.08
        Kirigami.Icon {
            width: Math.round(tile.inner * parent.size * 1.25)
            height: width
            anchors.verticalCenter: parent.verticalCenter
            source: tile.weather !== null && tile.weatherSource ? tile.weatherSource.iconFor(tile.weather.code) : ""
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            size: parent.size
            text: tile.weather !== null ? tile.weather.temp + "°" : ""
            font.weight: Font.DemiBold
        }
    }

    Loader {
        id: loader
        anchors.fill: parent
        anchors.leftMargin: tile.sweep ? Math.round(tile.padding * 0.6) : tile.hPad
        anchors.rightMargin: anchors.leftMargin
        // Round faces get a slimmer margin so they read at dock height.
        anchors.topMargin: tile.sweep ? Math.round(tile.padding * 0.6) : tile.padding
        anchors.bottomMargin: anchors.topMargin
        sourceComponent: ({
            digital: digitalComp, flip: flipComp, worldanalog: worldAnalogComp,
            classic: analogComp, classicdark: analogComp, minimal: analogComp,
            week: weekComp, worldlist: worldListComp, worldtime: worldTimeComp,
            today: todayComp, segment: segmentComp
        })[tile.style] ?? digitalComp
    }

    // 1. Clock: big time, grey seconds, AM/PM, date underneath.
    Component {
        id: digitalComp
        Item {
            implicitWidth: col.implicitWidth
            Column {
                id: col
                anchors.verticalCenter: parent.verticalCenter
                spacing: -tile.inner * 0.04
                Row {
                    Txt {
                        id: big
                        size: 0.62
                        text: tile.hourText(tile.now) + ":" + tile.minuteText(tile.now)
                        font.weight: Font.Bold
                    }
                    Txt {
                        anchors.baseline: big.baseline
                        size: 0.44
                        text: ":" + String(tile.now.getSeconds()).padStart(2, "0")
                        font.weight: Font.Bold
                        opacity: 0.45
                    }
                    Txt {
                        visible: tile.twelveHour
                        anchors.baseline: big.baseline
                        leftPadding: tile.inner * 0.08
                        size: 0.28
                        text: tile.ampm(tile.now)
                        font.weight: Font.Bold
                    }
                }
                Txt {
                    size: 0.3
                    text: Qt.locale().dayName(tile.now.getDay(), Locale.ShortFormat) + " "
                          + tile.now.getDate() + " " + Qt.locale().monthName(tile.now.getMonth(), Locale.ShortFormat)
                    opacity: 0.55
                }
            }
        }
    }

    // 2. Flip clock: split-flap cards, flips each minute.
    Component {
        id: flipComp
        Item {
            readonly property string hh: tile.twelveHour
                ? String(tile.now.getHours() % 12 === 0 ? 12 : tile.now.getHours() % 12).padStart(2, "0")
                : String(tile.now.getHours()).padStart(2, "0")
            readonly property string mm: tile.minuteText(tile.now)
            implicitWidth: flipRow.implicitWidth
            Row {
                id: flipRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: tile.inner * 0.08
                FlipDigit { height: tile.inner; digit: parent.parent.hh[0] }
                FlipDigit { height: tile.inner; digit: parent.parent.hh[1] }
                Item { width: tile.inner * 0.12; height: 1 }
                FlipDigit { height: tile.inner; digit: parent.parent.mm[0] }
                FlipDigit { height: tile.inner; digit: parent.parent.mm[1] }
                Txt {
                    visible: tile.twelveHour
                    anchors.bottom: parent.bottom
                    leftPadding: tile.inner * 0.04
                    size: 0.26
                    text: tile.ampm(tile.now)
                    font.weight: Font.Bold
                    opacity: 0.55
                }
            }
        }
    }

    // 3. World clocks: small analog faces with city codes.
    Component {
        id: worldAnalogComp
        Item {
            implicitWidth: waRow.implicitWidth
            Row {
                id: waRow
                anchors.centerIn: parent
                spacing: tile.inner * 0.4
                Repeater {
                    model: tile.zones.slice(0, 3)
                    Column {
                        id: waCol
                        required property var modelData
                        readonly property var info: tile.zoneInfo(modelData)
                        spacing: tile.inner * 0.02
                        AnalogFace {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.round(tile.inner * 0.72)
                            height: width
                            hours: waCol.info.d.getUTCHours()
                            minutes: waCol.info.d.getUTCMinutes()
                            showSeconds: false
                            ticks: "quarters"
                            faceColor: waCol.info.daytime ? "#F2F2F7" : "#1C1C1E"
                            tickColor: waCol.info.daytime ? Qt.alpha("black", 0.3) : Qt.alpha("white", 0.35)
                            hourHandColor: waCol.info.daytime ? "#1C1C1E" : "white"
                            minuteHandColor: hourHandColor
                            hubColor: tile.orange
                            rimColor: waCol.info.daytime ? "transparent" : Qt.alpha("white", 0.15)
                        }
                        Txt {
                            anchors.horizontalCenter: parent.horizontalCenter
                            size: 0.24
                            text: waCol.info.code
                            font.weight: Font.Bold
                            opacity: 0.6
                        }
                    }
                }
            }
        }
    }

    // 4-6. Analog Classic (white), Classic Dark, Minimal.
    Component {
        id: analogComp
        Item {
            implicitWidth: tile.inner
            AnalogFace {
                readonly property bool dark: tile.style === "classicdark"
                readonly property bool minimal: tile.style === "minimal"
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width
                hours: tile.now.getHours()
                minutes: tile.now.getMinutes()
                seconds: tile.now.getSeconds() + tile.now.getMilliseconds() / 1000
                ticks: minimal ? "hours" : "minutes"
                numerals: !minimal
                faceColor: minimal ? "#2C2C2E" : dark ? "#0A0A0A" : "white"
                rimColor: minimal ? "transparent" : dark ? Qt.alpha("white", 0.18) : Qt.alpha("black", 0.25)
                tickColor: minimal ? Qt.alpha("white", 0.4) : dark ? Qt.alpha("white", 0.45) : Qt.alpha("black", 0.45)
                majorTickColor: minimal ? "white" : dark ? Qt.alpha("white", 0.8) : Qt.alpha("black", 0.8)
                numeralColor: dark ? "white" : "black"
                hourHandColor: minimal ? "white" : tile.blue
                minuteHandColor: minimal || dark ? "white" : "#1C1C1E"
                secondHandColor: minimal ? tile.orange : tile.red
                hubColor: minimal ? tile.orange : dark ? "white" : "#1C1C1E"
                hubRing: minimal
            }
        }
    }

    // 7. 7 Days: month and weather, then today and the next six days.
    Component {
        id: weekComp
        Item {
            implicitWidth: weekRow.implicitWidth
            Row {
                id: weekRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: tile.inner * 0.3
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Txt {
                        size: 0.36
                        text: Qt.locale().monthName(tile.now.getMonth(), Locale.LongFormat)
                        font.weight: Font.Bold
                    }
                    WeatherBit { size: 0.3 }
                }
                Row {
                    spacing: tile.inner * 0.06
                    Repeater {
                        model: 7
                        Rectangle {
                            id: cell
                            required property int index
                            readonly property date day: new Date(tile.now.getFullYear(), tile.now.getMonth(), tile.now.getDate() + index)
                            width: Math.round(tile.inner * 0.95)
                            height: tile.inner
                            radius: height * 0.24
                            color: index === 0 ? tile.blue : "transparent"
                            Column {
                                anchors.centerIn: parent
                                spacing: -tile.inner * 0.04
                                Txt {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    size: 0.3
                                    text: Qt.locale().dayName(cell.day.getDay(), Locale.ShortFormat)
                                    color: cell.index === 0 ? "white" : Kirigami.Theme.textColor
                                    opacity: cell.index === 0 ? 0.95 : 0.55
                                }
                                Txt {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    size: 0.44
                                    text: cell.day.getDate()
                                    color: cell.index === 0 ? "white" : Kirigami.Theme.textColor
                                    font.weight: Font.Bold
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 8. World clock list: dot, city, hour difference, time.
    Component {
        id: worldListComp
        Item {
            readonly property var infos: tile.zones.slice(0, 3).map(z => tile.zoneInfo(z))
            readonly property real rowSize: Math.min(0.34, 0.92 / Math.max(1, infos.length))
            implicitWidth: grid.implicitWidth
            GridLayout {
                id: grid
                anchors.verticalCenter: parent.verticalCenter
                flow: GridLayout.TopToBottom
                rows: Math.max(1, parent.infos.length)
                rowSpacing: 0
                columnSpacing: tile.inner * 0.16
                Repeater {
                    model: grid.parent.infos
                    DayDot {
                        required property var modelData
                        daytime: modelData.daytime
                        Layout.preferredWidth: Math.round(tile.inner * grid.parent.rowSize * 0.75)
                        Layout.preferredHeight: Layout.preferredWidth
                    }
                }
                Repeater {
                    model: grid.parent.infos
                    Txt {
                        required property var modelData
                        size: grid.parent.rowSize
                        text: modelData.name
                        font.weight: Font.DemiBold
                        Layout.rightMargin: tile.inner * 0.2
                    }
                }
                Repeater {
                    model: grid.parent.infos
                    Txt {
                        required property var modelData
                        Layout.alignment: Qt.AlignRight
                        size: grid.parent.rowSize
                        text: modelData.known ? tile.diffText(modelData.diff) : ""
                        opacity: 0.55
                    }
                }
                Repeater {
                    model: grid.parent.infos
                    Txt {
                        required property var modelData
                        Layout.alignment: Qt.AlignRight
                        size: grid.parent.rowSize
                        text: tile.zoneTime(modelData) + (tile.twelveHour && modelData.known ? " " + tile.ampm(modelData.d, true) : "")
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }

    // 9. World time: one city, big digits, day and offset.
    Component {
        id: worldTimeComp
        Item {
            readonly property var info: tile.zoneInfo(tile.zones.length > 0 ? tile.zones[0] : "UTC")
            implicitWidth: wtLeft.implicitWidth + tile.inner * 0.9 + wtRight.implicitWidth
            Column {
                id: wtLeft
                anchors.verticalCenter: parent.verticalCenter
                spacing: tile.inner * 0.02
                Row {
                    spacing: tile.inner * 0.12
                    DayDot {
                        anchors.verticalCenter: parent.verticalCenter
                        daytime: wtLeft.parent.info.daytime
                        width: Math.round(tile.inner * 0.28)
                        height: width
                    }
                    Txt {
                        size: 0.38
                        text: wtLeft.parent.info.name
                        font.weight: Font.Bold
                    }
                }
                Txt {
                    size: 0.28
                    text: tile.dayWord(wtLeft.parent.info.day)
                          + (wtLeft.parent.info.known ? ", " + tile.diffText(wtLeft.parent.info.diff) : "")
                    opacity: 0.55
                }
            }
            Row {
                id: wtRight
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                Txt {
                    id: wtBig
                    size: 0.66
                    text: tile.zoneTime(wtRight.parent.info)
                    font.weight: Font.Bold
                }
                Txt {
                    visible: tile.twelveHour && wtRight.parent.info.known
                    anchors.baseline: wtBig.baseline
                    leftPadding: tile.inner * 0.06
                    size: 0.28
                    text: tile.ampm(wtRight.parent.info.d, true)
                    font.weight: Font.Bold
                }
            }
        }
    }

    // 10. Today: red weekday + date | time + weather.
    Component {
        id: todayComp
        Item {
            implicitWidth: tdLeft.implicitWidth + tdRight.implicitWidth + tile.inner * 1.0
            Column {
                id: tdLeft
                anchors.verticalCenter: parent.verticalCenter
                Txt {
                    size: 0.28
                    text: Qt.locale().dayName(tile.now.getDay(), Locale.LongFormat).toUpperCase()
                    color: tile.red
                    font.weight: Font.DemiBold
                    font.letterSpacing: tile.inner * 0.02
                }
                Txt {
                    size: 0.5
                    text: Qt.locale().monthName(tile.now.getMonth(), Locale.ShortFormat) + " " + tile.now.getDate()
                    font.weight: Font.Bold
                }
            }
            Rectangle {
                x: tdLeft.implicitWidth + (parent.width - tdLeft.implicitWidth - tdRight.implicitWidth) / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: tile.inner * 0.85
                color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
            }
            Column {
                id: tdRight
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                Row {
                    anchors.right: parent.right
                    Txt {
                        id: tdTime
                        size: 0.46
                        text: tile.hourText(tile.now) + ":" + tile.minuteText(tile.now)
                        font.weight: Font.Bold
                    }
                    Txt {
                        visible: tile.twelveHour
                        anchors.baseline: tdTime.baseline
                        leftPadding: tile.inner * 0.05
                        size: 0.24
                        text: tile.ampm(tile.now)
                        font.weight: Font.Bold
                    }
                }
                WeatherBit {
                    anchors.right: parent.right
                    size: 0.28
                    opacity: 0.8
                }
            }
        }
    }

    // 11. Segment clock: weekday pill and date over seven-segment digits.
    Component {
        id: segmentComp
        Item {
            readonly property string digits: (tile.twelveHour
                ? String(tile.now.getHours() % 12 === 0 ? 12 : tile.now.getHours() % 12).padStart(2, "0")
                : String(tile.now.getHours()).padStart(2, "0")) + tile.minuteText(tile.now)
            implicitWidth: Math.max(segHead.implicitWidth, segRow.implicitWidth)
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: tile.inner * 0.08
                Row {
                    id: segHead
                    spacing: tile.inner * 0.12
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: pillText.implicitWidth + tile.inner * 0.22
                        height: pillText.implicitHeight * 0.95
                        radius: height / 2
                        color: "transparent"
                        border.width: 1
                        border.color: tile.red
                        Txt {
                            id: pillText
                            anchors.centerIn: parent
                            size: 0.2
                            text: Qt.locale().dayName(tile.now.getDay(), Locale.LongFormat).toUpperCase()
                            color: tile.red
                            font.weight: Font.DemiBold
                        }
                    }
                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 0.27
                        text: tile.now.getDate() + " " + Qt.locale().monthName(tile.now.getMonth(), Locale.ShortFormat).toUpperCase()
                        font.weight: Font.Bold
                    }
                }
                Row {
                    id: segRow
                    spacing: tile.inner * 0.12
                    Repeater {
                        model: 4
                        SevenSegment {
                            required property int index
                            height: Math.round(tile.inner * 0.6)
                            digit: Number(segRow.parent.parent.digits[index])
                            onColor: Kirigami.Theme.textColor
                            offColor: Qt.alpha(Kirigami.Theme.textColor, 0.12)
                        }
                    }
                }
            }
        }
    }
}
