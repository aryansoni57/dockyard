import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// World clocks tile (docs/PLAN.md, "Time modules"): up to 3 IANA zones as
// columns of time over city. No timer here: the parent sets `now` once a minute.
Tile {
    id: wc

    property var zones: ["America/New_York", "Europe/London", "Asia/Tokyo"]
    property date now: new Date()

    readonly property real inner: height - padding * 2

    implicitWidth: layout.implicitWidth + padding * 2

    // Last IANA path segment, underscores to spaces: "America/New_York" -> "New York".
    function cityName(zone) {
        return String(zone).split("/").pop().replace(/_/g, " ");
    }

    // QML has no Intl and Date.toLocaleTimeString ignores `timeZone` (checked on
    // qml6 6.12: it prints the local zone), so zones are offset math:
    // [standard offset in minutes, DST rule]. Unknown zones show "--:--".
    readonly property var zoneTable: ({
        "UTC": [0, "none"],
        "America/New_York": [-300, "us"], "America/Toronto": [-300, "us"],
        "America/Chicago": [-360, "us"], "America/Denver": [-420, "us"],
        "America/Los_Angeles": [-480, "us"], "America/Vancouver": [-480, "us"],
        "Europe/London": [0, "eu"], "Europe/Dublin": [0, "eu"], "Europe/Lisbon": [0, "eu"],
        "Europe/Paris": [60, "eu"], "Europe/Berlin": [60, "eu"], "Europe/Madrid": [60, "eu"],
        "Europe/Rome": [60, "eu"], "Europe/Amsterdam": [60, "eu"],
        "Europe/Athens": [120, "eu"], "Europe/Helsinki": [120, "eu"],
        "Europe/Istanbul": [180, "none"], "Europe/Moscow": [180, "none"],
        "Asia/Dubai": [240, "none"], "Asia/Kolkata": [330, "none"],
        "Asia/Singapore": [480, "none"], "Asia/Shanghai": [480, "none"],
        "Asia/Hong_Kong": [480, "none"], "Asia/Tokyo": [540, "none"], "Asia/Seoul": [540, "none"],
        "Australia/Perth": [480, "none"], "Australia/Brisbane": [600, "none"],
        "Australia/Sydney": [600, "au"], "Australia/Melbourne": [600, "au"]
    })

    // Day of month of the nth Sunday (n = 1..) of a 0-based month, in UTC.
    function nthSunday(y, m, n) {
        const firstDow = new Date(Date.UTC(y, m, 1)).getUTCDay();
        return 1 + ((7 - firstDow) % 7) + (n - 1) * 7;
    }

    function lastSunday(y, m) {
        const lastDay = new Date(Date.UTC(y, m + 1, 0)).getUTCDate();
        return lastDay - new Date(Date.UTC(y, m, lastDay)).getUTCDay();
    }

    // Is DST in force at UTC instant t? Rules: US (2nd Sun Mar 2:00 to 1st Sun Nov 2:00
    // local), EU (last Sun Mar to last Sun Oct, 01:00 UTC), AU (1st Sun Oct to 1st Sun
    // Apr, southern hemisphere: DST wraps the new year).
    function dstActive(rule, std, t) {
        const y = new Date(t).getUTCFullYear();
        if (rule === "us") {
            const start = Date.UTC(y, 2, nthSunday(y, 2, 2), 2) - std * 60000;
            const end = Date.UTC(y, 10, nthSunday(y, 10, 1), 2) - (std + 60) * 60000;
            return t >= start && t < end;
        }
        if (rule === "eu") {
            const start = Date.UTC(y, 2, lastSunday(y, 2), 1);
            const end = Date.UTC(y, 9, lastSunday(y, 9), 1);
            return t >= start && t < end;
        }
        if (rule === "au") {
            const start = Date.UTC(y, 9, nthSunday(y, 9, 1), 2) - std * 60000;
            const end = Date.UTC(y, 3, nthSunday(y, 3, 1), 3) - (std + 60) * 60000;
            return t < end || t >= start;
        }
        return false;
    }

    // UTC offset of `zone` in minutes at `now`, or null for an unknown zone.
    function offsetIn(zone) {
        const entry = zoneTable[zone];
        if (entry === undefined)
            return null;
        const t = wc.now.getTime();
        return entry[0] + (dstActive(entry[1], entry[0], t) ? 60 : 0);
    }

    // HH:mm of `now` in `zone`.
    function timeIn(zone) {
        const offsetMin = offsetIn(zone);
        if (offsetMin === null)
            return "--:--";
        const shifted = new Date(wc.now.getTime() + offsetMin * 60000);
        return String(shifted.getUTCHours()).padStart(2, "0") + ":"
             + String(shifted.getUTCMinutes()).padStart(2, "0");
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        height: wc.inner
        spacing: wc.inner * 0.5

        Repeater {
            model: wc.zones.slice(0, 3)

            delegate: Column {
                id: clockColumn
                required property var modelData
                Layout.alignment: Qt.AlignVCenter

                PlasmaComponents.Label {
                    text: wc.timeIn(clockColumn.modelData)
                    font.pixelSize: wc.inner * 0.42
                    font.weight: Font.Medium
                    font.features: { "tnum": 1 }
                }
                PlasmaComponents.Label {
                    text: wc.cityName(clockColumn.modelData)
                    font.pixelSize: wc.inner * 0.2
                    opacity: 0.6
                }
            }
        }
    }
}
