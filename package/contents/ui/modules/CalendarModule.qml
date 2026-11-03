import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Calendar tile: today's date in a small box (red weekday over the day number),
// then an accent bar, the next item's title and "time · in 1h 26m". The item comes
// from scripts/next-event.py: the next event of an iCal URL or .ics file and/or the
// next due date of an open Plane issue assigned to you, whichever is sooner.
Tile {
    id: tile

    property date now
    property string source: ""
    property string planeUrl: ""
    property string planeWorkspace: ""
    property string planeKey: ""
    readonly property bool planeOn: planeWorkspace.trim() !== "" && planeKey.trim() !== ""
    readonly property bool configured: source.trim() !== "" || planeOn

    readonly property real inner: height - padding * 2
    readonly property string script: Qt.resolvedUrl("../../scripts/next-event.py").toString().replace("file://", "")

    property bool ok: false
    property string error: ""
    property bool hasEvent: false
    property string title: ""
    property date start
    property date end
    property bool allDay: false
    property string kind: "event"
    property string extra: ""

    readonly property string headline: !configured ? i18n("Add a calendar")
        : !ok ? i18n("Calendar unavailable")
        : hasEvent ? title : i18n("No upcoming events")

    readonly property string detail: {
        if (!configured)
            return i18n("Widget settings, Calendar");
        if (!ok)
            return error === "fetch" ? i18n("Can't read the calendar") : i18n("Check the calendar address");
        if (!hasEvent)
            return i18n("Nothing in the next 60 days");
        const sameDay = start.toDateString() === now.toDateString();
        const day = sameDay ? "" : Qt.locale().dayName(start.getDay(), Locale.ShortFormat) + " ";
        const mins = Math.round((start - now) / 60000);
        let when;
        if (mins <= 0)
            when = i18n("now");
        else {
            const d = Math.floor(mins / 1440), h = Math.floor(mins % 1440 / 60), m = mins % 60;
            when = i18n("in %1", d > 0 ? d + "d " + h + "h" : h > 0 ? h + "h " + m + "m" : m + "m");
        }
        if (kind === "plane")
            return i18n("Due %1", sameDay ? i18n("today") : day.trim()) + (extra !== "" ? " · " + extra : "");
        return (allDay ? day + i18n("All day") : day + Qt.formatTime(start, Qt.locale().timeFormat(Locale.ShortFormat))) + " · " + when;
    }

    implicitWidth: Math.round(height * 4.1)

    ShellRunner {
        id: shell
        onFinished: (cmd, out) => {
            try {
                const r = JSON.parse(out);
                tile.ok = r.ok === true;
                tile.error = r.error || "";
                tile.hasEvent = tile.ok && !r.none;
                if (tile.hasEvent) {
                    tile.title = r.title;
                    tile.start = new Date(r.start);
                    tile.end = new Date(r.end);
                    tile.allDay = r.allDay;
                    tile.kind = r.kind || "event";
                    tile.extra = r.extra || "";
                }
            } catch (e) {
                tile.ok = false;
                tile.error = "fetch";
            }
        }
    }
    function refresh() {
        const cfg = JSON.stringify({
            ical: source.trim(),
            plane: { url: planeUrl.trim(), workspace: planeWorkspace.trim(), key: planeKey.trim() }
        });
        shell.run("python3 '" + script + "' '" + cfg.replace(/'/g, "'\\''") + "'");
    }
    onSourceChanged: refresh()
    onPlaneUrlChanged: refresh()
    onPlaneWorkspaceChanged: refresh()
    onPlaneKeyChanged: refresh()
    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: tile.refresh()
    }

    Row {
        anchors.fill: parent
        anchors.margins: tile.padding
        spacing: tile.inner * 0.2

        Rectangle {
            id: dayBox
            width: tile.inner
            height: tile.inner
            radius: tile.inner * 0.26
            color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.55)
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

            Column {
                anchors.centerIn: parent
                spacing: -tile.inner * 0.02

                PlasmaComponents.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.locale().dayName(tile.now.getDay(), Locale.ShortFormat).toUpperCase()
                    color: "#FF3B30"
                    font.pixelSize: Math.max(7, tile.inner * 0.2)
                    font.weight: Font.DemiBold
                }
                PlasmaComponents.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tile.now.getDate()
                    font.pixelSize: Math.max(10, tile.inner * 0.5)
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                }
            }
        }

        Rectangle {
            visible: tile.hasEvent
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(2, tile.inner * 0.055)
            height: tile.inner * 0.4
            radius: width / 2
            color: tile.kind === "plane" ? "#3F76FF" : "#FF9F0A"
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - dayBox.width - parent.spacing * (tile.hasEvent ? 2 : 1)
                   - (tile.hasEvent ? Math.max(2, tile.inner * 0.055) : 0)
            spacing: tile.inner * 0.04

            PlasmaComponents.Label {
                width: parent.width
                text: tile.headline
                elide: Text.ElideRight
                font.weight: Font.Bold
                font.pixelSize: Math.max(9, tile.inner * 0.3)
            }
            PlasmaComponents.Label {
                width: parent.width
                text: tile.detail
                elide: Text.ElideRight
                opacity: 0.6
                font.pixelSize: Math.max(8, tile.inner * 0.23)
                font.features: { "tnum": 1 }
            }
        }
    }
}
