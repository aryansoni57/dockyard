pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"
import "../components/accent"

// Calendar popup: a month grid with a dot per kind of item on each day, and the
// selected day's list beside it. Items come from scripts/next-event.py in range mode
// (iCal events and Plane due dates), one fetch per month shown.
RowLayout {
    id: panel

    property var applet

    readonly property var cfg: applet.cfg
    readonly property bool configured: cfg.calendarSource.trim() !== ""
        || (cfg.planeWorkspace.trim() !== "" && cfg.planeApiKey.trim() !== "")
    readonly property date today: applet.now
    readonly property int firstDay: Qt.locale().firstDayOfWeek % 7 // 0 = Sunday

    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()
    property date selected: new Date(today.getFullYear(), today.getMonth(), today.getDate())
    property var items: []
    property string status: configured ? "loading" : "none" // none | loading | ok | error

    readonly property var kinds: ({
        event: { name: i18n("Events"), color: "#0A84FF" },
        allday: { name: i18n("All day"), color: "#7D7AFF" },
        plane: { name: i18n("Due dates"), color: "#FF9F0A" }
    })

    function kindOf(it) {
        return it.kind === "plane" ? "plane" : it.allDay ? "allday" : "event";
    }
    function pad2(n) {
        return (n < 10 ? "0" : "") + n;
    }
    function dayKey(d) {
        return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate());
    }
    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }
    function shq(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }

    // Items bucketed by day key; multi-day items fall on each day they cover.
    readonly property var byDay: {
        const map = {};
        for (const it of items) {
            const end = it.allDay ? new Date(it.end.getTime() - 1) : it.end;
            const d = new Date(it.start.getFullYear(), it.start.getMonth(), it.start.getDate());
            for (let n = 0; n < 40 && d <= end; ++n) {
                const k = dayKey(d);
                (map[k] = map[k] || []).push(it);
                d.setDate(d.getDate() + 1);
            }
        }
        return map;
    }
    readonly property var dayItems: byDay[dayKey(selected)] || []

    readonly property int monthStart: new Date(viewYear, viewMonth, 1).getDay()
    readonly property int offset: (monthStart - firstDay + 7) % 7
    readonly property int daysInMonth: new Date(viewYear, viewMonth + 1, 0).getDate()
    readonly property int rows: 6 // fixed, so the popup keeps one height in every month

    function shift(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
        load();
    }
    function goToday() {
        const t = new Date(today.getFullYear(), today.getMonth(), today.getDate());
        const moved = viewYear !== t.getFullYear() || viewMonth !== t.getMonth();
        viewYear = t.getFullYear();
        viewMonth = t.getMonth();
        selected = t;
        if (moved)
            load();
    }

    function load() {
        if (!configured)
            return;
        status = "loading";
        // A week of slack either side covers the greyed days a month grid never shows anyway.
        const from = new Date(viewYear, viewMonth, 1 - 7);
        const to = new Date(viewYear, viewMonth + 1, 7);
        const arg = JSON.stringify({
            ical: cfg.calendarSource.trim(),
            plane: { url: cfg.planeUrl.trim(), workspace: cfg.planeWorkspace.trim(), key: cfg.planeApiKey.trim() },
            from: dayKey(from),
            to: dayKey(to)
        });
        const script = Qt.resolvedUrl("../../scripts/next-event.py").toString().replace("file://", "");
        runner.run("python3 " + shq(script) + " " + shq(arg));
    }
    ShellRunner {
        id: runner
        onFinished: (cmd, out) => {
            try {
                const r = JSON.parse(out);
                if (r.ok !== true) {
                    panel.status = "error";
                    return;
                }
                panel.items = (r.items || []).map(i => ({
                    title: i.title, kind: i.kind, allDay: i.allDay, extra: i.extra || "",
                    start: new Date(i.start), end: new Date(i.end)
                }));
                panel.status = "ok";
            } catch (e) {
                panel.status = "error";
            }
        }
    }
    Timer {
        interval: 120
        running: true
        onTriggered: panel.load()
    }

    // New event: Google Calendar's create page opens with the title and day filled in.
    // The last click (Save) stays in the browser, as in the dashboard.
    function createEvent() {
        const t = newTitle.text.trim();
        if (t === "")
            return;
        const s = selected.getFullYear() + pad2(selected.getMonth() + 1) + pad2(selected.getDate());
        const n = new Date(selected.getFullYear(), selected.getMonth(), selected.getDate() + 1);
        const e = n.getFullYear() + pad2(n.getMonth() + 1) + pad2(n.getDate());
        const url = "https://calendar.google.com/calendar/render?action=TEMPLATE&text=" + encodeURIComponent(t)
            + "&dates=" + s + "/" + e;
        opener.run("xdg-open " + shq(url) + " >/dev/null 2>&1 &");
        newTitle.text = "";
    }
    ShellRunner {
        id: opener
    }

    spacing: 0
    Layout.minimumWidth: Kirigami.Units.gridUnit * 34
    Layout.maximumWidth: Kirigami.Units.gridUnit * 34
    Layout.minimumHeight: implicitHeight

    component NavButton: QQC2.AbstractButton {
        id: nb
        property string glyph
        implicitWidth: Kirigami.Units.gridUnit * 1.7
        implicitHeight: Kirigami.Units.gridUnit * 1.7
        contentItem: Kirigami.Icon {
            source: nb.glyph
            width: Kirigami.Units.iconSizes.small
            height: width
        }
        background: Rectangle {
            radius: Kirigami.Units.cornerRadius
            color: Qt.alpha(Kirigami.Theme.textColor, nb.pressed ? 0.16 : nb.hovered ? 0.1 : 0)
        }
    }

    // ---- month pane ----
    ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 21
        Layout.fillWidth: false
        Layout.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: Qt.locale().monthName(panel.viewMonth, Locale.LongFormat) + " " + panel.viewYear
                font.weight: Font.Bold
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.35
                elide: Text.ElideRight
            }
            QQC2.AbstractButton {
                id: todayBtn
                implicitWidth: todayLabel.implicitWidth + Kirigami.Units.largeSpacing * 2
                implicitHeight: Kirigami.Units.gridUnit * 1.7
                onClicked: panel.goToday()
                contentItem: PlasmaComponents.Label {
                    id: todayLabel
                    text: i18n("Today")
                    color: DockAccent.color
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: Kirigami.Units.cornerRadius
                    color: Qt.alpha(DockAccent.color, todayBtn.pressed ? 0.24 : todayBtn.hovered ? 0.16 : 0)
                }
            }
            NavButton {
                glyph: "go-previous-symbolic"
                onClicked: panel.shift(-1)
            }
            NavButton {
                glyph: "go-next-symbolic"
                onClicked: panel.shift(1)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            Repeater {
                model: Object.keys(panel.kinds)

                RowLayout {
                    id: leg
                    required property string modelData
                    spacing: Kirigami.Units.smallSpacing

                    Rectangle {
                        implicitWidth: 7
                        implicitHeight: 7
                        radius: 3.5
                        color: panel.kinds[leg.modelData].color
                    }
                    PlasmaComponents.Label {
                        text: panel.kinds[leg.modelData].name
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        opacity: 0.78
                    }
                }
            }
            Item {
                Layout.fillWidth: true
            }
        }

        GridLayout {
            id: grid
            readonly property real cell: Math.floor((Kirigami.Units.gridUnit * 21 - Kirigami.Units.largeSpacing * 2) / 7)

            Layout.fillWidth: true
            columns: 7
            rowSpacing: 2
            columnSpacing: 0

            Repeater {
                model: 7

                PlasmaComponents.Label {
                    required property int index
                    Layout.preferredWidth: grid.cell
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName((panel.firstDay + index) % 7, Locale.ShortFormat).toUpperCase()
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    font.weight: Font.DemiBold
                    opacity: 0.78
                }
            }

            Repeater {
                model: panel.rows * 7

                Item {
                    id: cellItem
                    required property int index
                    readonly property int day: index - panel.offset + 1
                    readonly property bool inMonth: day >= 1 && day <= panel.daysInMonth
                    readonly property date date: new Date(panel.viewYear, panel.viewMonth, day)
                    readonly property bool isToday: inMonth && panel.sameDay(date, panel.today)
                    readonly property bool isSel: inMonth && panel.sameDay(date, panel.selected)
                    readonly property var list: inMonth ? (panel.byDay[panel.dayKey(date)] || []) : []
                    readonly property var dotKinds: {
                        const seen = [];
                        for (const it of list) {
                            const k = panel.kindOf(it);
                            if (seen.indexOf(k) < 0)
                                seen.push(k);
                        }
                        return seen;
                    }

                    Layout.preferredWidth: grid.cell
                    Layout.preferredHeight: grid.cell

                    Rectangle {
                        anchors.centerIn: parent
                        visible: cellItem.inMonth
                        width: parent.width - 4
                        height: width
                        radius: width * 0.28
                        color: Qt.alpha(Kirigami.Theme.textColor, cellHover.hovered ? 0.1 : 0.05)
                        border.width: cellItem.isSel ? 2 : 0
                        border.color: DockAccent.color

                        HoverHandler {
                            id: cellHover
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            onTapped: panel.selected = cellItem.date
                        }

                        PlasmaComponents.Label {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: cellItem.dotKinds.length > 0 ? -parent.height * 0.1 : 0
                            text: cellItem.day
                            color: cellItem.isToday ? DockAccent.color : Kirigami.Theme.textColor
                            font.weight: cellItem.isToday || cellItem.isSel ? Font.Bold : Font.Normal
                            font.features: { "tnum": 1 }
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: parent.height * 0.14
                            spacing: 3

                            Repeater {
                                model: cellItem.dotKinds

                                Rectangle {
                                    required property string modelData
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: panel.kinds[modelData].color
                                }
                            }
                            PlasmaComponents.Label {
                                visible: cellItem.list.length > 3
                                text: "+" + (cellItem.list.length - 3)
                                font.pixelSize: Math.max(7, Kirigami.Theme.smallFont.pixelSize * 0.8)
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: 0.7
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillHeight: true
        Layout.topMargin: Kirigami.Units.largeSpacing
        Layout.bottomMargin: Kirigami.Units.largeSpacing
        implicitWidth: 1
        color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
    }

    // ---- day pane ----
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: panel.sameDay(panel.selected, panel.today) ? i18n("Today")
                    : Qt.formatDate(panel.selected, "ddd d MMM")
                font.weight: Font.Bold
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.15
                elide: Text.ElideRight
            }
            PlasmaComponents.Label {
                visible: panel.status === "ok"
                text: i18np("%1 event", "%1 events", panel.dayItems.length)
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                opacity: 0.7
            }
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            visible: panel.status !== "ok" || panel.dayItems.length === 0
            wrapMode: Text.Wrap
            opacity: 0.65
            text: panel.status === "none" ? i18n("Add a calendar in the widget settings, Calendar.")
                : panel.status === "loading" ? i18n("Loading…")
                : panel.status === "error" ? i18n("Can't read the calendar. Check its address.")
                : i18n("Nothing on this day.")
        }

        Repeater {
            model: panel.status === "ok" ? panel.dayItems : []

            Item {
                id: evRow
                required property var modelData
                readonly property string kind: panel.kindOf(modelData)

                Layout.fillWidth: true
                implicitHeight: Math.max(Kirigami.Units.gridUnit * 2.2, evText.implicitHeight + Kirigami.Units.smallSpacing * 2)

                RowLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.largeSpacing

                    PlasmaComponents.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3.4
                        text: evRow.modelData.allDay ? i18n("All day")
                            : Qt.formatTime(evRow.modelData.start, Qt.locale().timeFormat(Locale.ShortFormat))
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        font.features: { "tnum": 1 }
                        opacity: 0.65
                    }
                    Rectangle {
                        Layout.preferredWidth: 3
                        Layout.preferredHeight: evText.implicitHeight
                        radius: 1.5
                        color: panel.kinds[evRow.kind].color
                    }
                    ColumnLayout {
                        id: evText
                        Layout.fillWidth: true
                        spacing: 0

                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: evRow.modelData.title
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: evRow.modelData.extra
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            opacity: 0.65
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        // New event on the selected day: Enter or + opens Google Calendar to save it.
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.TextField {
                id: newTitle
                Layout.fillWidth: true
                placeholderText: i18n("New event")
                onAccepted: panel.createEvent()
            }
            NavButton {
                glyph: "list-add-symbolic"
                enabled: newTitle.text.trim() !== ""
                onClicked: panel.createEvent()
            }
        }
    }
}
