import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import ".."

// Overview: quick toggles, volume and brightness, this machine, recent pages and every category.
Sheet {
    id: pg
    hero: true
    maxWidth: 980
    readonly property var ab: sys ? sys.about : ({})
    readonly property int hr: Theme.hour
    title: (hr < 5 ? "Good night" : hr < 12 ? "Good morning" : hr < 18 ? "Good afternoon" : "Good evening") + (ab.user ? ", " + ab.user : "")
    subtitle: [ab.host, ab.os].filter(x => x).join("  ·  ")
    readonly property bool wide: width > 820
    function fmtBytes(kb) { const g = kb / 1048576; return g >= 100 ? Math.round(g) + " GB" : g.toFixed(1) + " GB"; }
    function fmtUp(s) { const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60); return (d ? d + "d " : "") + (h ? h + "h " : "") + m + "m"; }

    actions: Btn { text: "Search"; iconName: "search"; onClicked: app.search("") }

    // ---- Quick toggles ----
    component QuickTile: QQC2.AbstractButton {
        id: qt
        property string glyph
        property string label
        property string status
        property bool on: false
        property int page: -1
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.preferredHeight: 104
        focusPolicy: Qt.TabFocus
        Accessible.name: label
        Accessible.role: Accessible.CheckBox
        Accessible.checked: on
        scale: down && Theme.motion ? 0.98 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }
        background: Rectangle {
            radius: Theme.rCard
            color: qt.on ? (qt.hovered ? Qt.lighter(Theme.accent, 1.06) : Theme.accent) : (qt.hovered ? Theme.cardHi : Theme.card)
            border.width: qt.on ? 0 : 1
            border.color: Theme.cardRim
            Behavior on color { ColorAnimation { duration: Theme.dur } }
            FocusRing { shown: qt.visualFocus; round: Theme.rCard }
        }
        contentItem: Item {
            Rectangle {
                x: 2; y: 2
                width: 36; height: 36; radius: 11
                color: qt.on ? Theme.a(Theme.accentFg, 0.18) : Theme.accentSoft
                Ico { anchors.centerIn: parent; name: qt.glyph; size: 20; color: qt.on ? Theme.accentFg : Theme.accentInk }
            }
            ColumnLayout {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 2; bottomMargin: 0 }
                spacing: 0
                QQC2.Label { text: qt.label; color: qt.on ? Theme.accentFg : Theme.ink; font.pixelSize: Theme.fsBody; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                QQC2.Label { text: qt.status; color: qt.on ? Theme.a(Theme.accentFg, 0.78) : Theme.ink3; font.pixelSize: Theme.fsCaption; elide: Text.ElideRight; Layout.fillWidth: true }
            }
        }
        topPadding: 14; leftPadding: 14; rightPadding: 14; bottomPadding: 14
        IconBtn {
            visible: qt.page >= 0
            anchors { right: parent.right; top: parent.top; margins: 10 }
            box: 28; glyph: 16
            iconName: "chevron-right"
            tip: "Open " + qt.label
            tint: qt.on ? Theme.accentFg : Theme.ink3
            onClicked: pg.openPage(qt.page)
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: pg.width > 700 ? 4 : 2
        columnSpacing: Theme.s3
        rowSpacing: Theme.s3
        QuickTile {
            glyph: !sys.wifiOn ? "wifi-off" : sys.wifiSignal > 66 ? "wifi-3" : sys.wifiSignal > 33 ? "wifi-2" : sys.ssid ? "wifi-1" : "network"
            label: "Wi-Fi"
            status: !sys.wifiOn ? "Off" : (sys.ssid || (sys.wired ? "Wired connection" : "Not connected"))
            on: sys.wifiOn
            page: 3
            onClicked: { sys.setWifi(!sys.wifiOn); pg.toast(sys.wifiOn ? "Wi-Fi on" : "Wi-Fi off", sys.wifiOn ? "network" : "wifi-off"); }
        }
        QuickTile {
            glyph: "bluetooth"
            label: "Bluetooth"
            status: !sys.btOn ? "Off" : sys.btConnected ? sys.btName + (sys.btConnected > 1 ? " +" + (sys.btConnected - 1) : "") : "On, nothing connected"
            on: sys.btOn
            page: 4
            onClicked: { sys.setBt(!sys.btOn); pg.toast(sys.btOn ? "Bluetooth on" : "Bluetooth off", "bluetooth"); }
        }
        QuickTile {
            glyph: Theme.dark ? "moon" : "sun"
            label: "Night mode"
            status: Theme.mode === "auto" ? "Auto, " + (Theme.dark ? "night now" : "day now") : Theme.dark ? "On" : "Off"
            on: Theme.dark
            page: 0
            onClicked: Theme.setMode(Theme.dark ? "day" : "night")
        }
        QuickTile {
            readonly property var icons: ({ "power-saver": "leaf", "balanced": "gauge", "performance": "bolt" })
            glyph: icons[sys.profile] || "power"
            label: sys.profileNames[sys.profile] || "Power"
            status: sys.battery >= 0 ? "Battery " + sys.battery + "%" + (sys.batteryState === "Charging" ? ", charging" : "") : "Click to switch profile"
            on: false
            page: 5
            onClicked: { const p = sys.nextProfile(); if (p) pg.toast((sys.profileNames[p] || p) + " profile", icons[p] || "power"); }
        }
    }

    // ---- Levels ----
    Card {
        padded: true
        component Level: RowLayout {
            id: lv
            property string glyph
            property string glyphOff: glyph
            property bool off: false
            property string label
            property string detail
            property real level: 0
            property real ceiling: 1
            readonly property alias current: sl.value
            signal moved(real v)
            signal glyphClicked()
            Layout.fillWidth: true
            spacing: Theme.s3
            IconBtn { iconName: lv.off ? lv.glyphOff : lv.glyph; tip: lv.label; active: !lv.off; box: 36; onClicked: lv.glyphClicked() }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 9
                    Layout.rightMargin: 9
                    QQC2.Label { text: lv.label; color: Theme.ink; font.pixelSize: Theme.fsSmall; font.weight: Font.Medium }
                    QQC2.Label { text: lv.detail; color: Theme.ink3; font.pixelSize: Theme.fsCaption; elide: Text.ElideRight; Layout.fillWidth: true }
                    QQC2.Label { text: lv.off ? "Muted" : Math.round(lv.level * 100) + "%"; color: Theme.ink2; font.pixelSize: Theme.fsCaption; font.features: { "tnum": 1 } }
                }
                Slide {
                    id: sl
                    Layout.fillWidth: true
                    from: 0; to: lv.ceiling; stepSize: 0.01
                    opacity: lv.off ? 0.45 : 1
                    Binding on value { when: !sl.pressed; value: lv.level }
                    onMoved: lv.moved(value)
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.s4
            Level {
                glyph: "sound"; glyphOff: "sound-off"
                label: "Volume"; detail: sys.sinkName
                off: sys.muted; level: sys.volume; ceiling: 1.5
                onMoved: (v) => sys.setVolume(v)
                onGlyphClicked: sys.toggleMute()
            }
            Level {
                id: bright
                visible: sys.brightness >= 0
                glyph: "sun"
                label: "Brightness"; detail: sys.displayLine
                level: sys.brightness
                onMoved: (v) => brightTimer.restart()
                onGlyphClicked: pg.openPage(1)
                Timer { id: brightTimer; interval: 120; onTriggered: sys.setBrightness(Math.max(0.05, bright.current)) }
            }
        }
    }

    // ---- This machine and recent ----
    GridLayout {
        Layout.fillWidth: true
        columns: pg.wide ? 2 : 1
        columnSpacing: Theme.s4
        rowSpacing: Theme.s6
        Card {
            title: "This computer"
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 1
            trailing: Btn { small: true; quiet: true; text: "Details"; onClicked: pg.openGroup("info") }
            SettingRow { iconName: "cpu"; label: pg.ab.cpu || "Processor"; caption: pg.ab.cores ? pg.ab.cores + " threads" : "" }
            SettingRow {
                id: memRow
                iconName: "memory"
                readonly property var m: (pg.ab.mem || "0 0").split(" ").map(Number)
                label: "Memory"
                caption: m[0] ? pg.fmtBytes(m[0] - m[1]) + " of " + pg.fmtBytes(m[0]) + " in use" : ""
                Meter { Layout.preferredWidth: 90; value: memRow.m[0] ? 1 - memRow.m[1] / memRow.m[0] : 0 }
            }
            SettingRow {
                id: diskRow
                iconName: "disk"
                readonly property var d: (pg.ab.disk || "0 0").split(" ").map(Number)
                label: "Storage"
                caption: d[0] ? pg.fmtBytes(d[1]) + " of " + pg.fmtBytes(d[0]) + " used" : ""
                Meter { Layout.preferredWidth: 90; value: diskRow.d[0] ? diskRow.d[1] / diskRow.d[0] : 0 }
            }
            SettingRow {
                iconName: "info"; last: true
                label: "Plasma " + (pg.ab.plasma || "") + "  ·  Linux " + (pg.ab.kernel || "").split("-")[0]
                caption: pg.ab.up ? "Up for " + pg.fmtUp(parseInt(pg.ab.up)) : ""
            }
        }
        Card {
            title: "Recently opened"
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 1
            Repeater {
                model: app.recent.slice(0, 4)
                delegate: SettingRow {
                    required property var modelData
                    required property int index
                    clickable: true
                    iconName: modelData.k === "native" ? app.sections[modelData.page].icon : (modelData.icon || "")
                    label: modelData.label
                    caption: modelData.sub || ""
                    last: index === Math.min(4, app.recent.length) - 1
                    onClicked: modelData.k === "kcm" ? pg.openKcm(modelData.id) : pg.openPage(modelData.page)
                }
            }
            EmptyState {
                visible: app.recent.length === 0
                Layout.fillWidth: true
                Layout.margins: Theme.s6
                iconName: "history"
                title: "Nothing yet"
                body: "Pages and modules you open show up here."
            }
        }
    }

    // ---- All categories ----
    Card {
        title: "All settings"
        description: app.kcmModel.rowCount() + " System Settings modules, hosted right here"
        padded: true
        GridLayout {
            id: cats
            Layout.fillWidth: true
            columns: Math.max(2, Math.floor(width / 210))
            columnSpacing: Theme.s2
            rowSpacing: Theme.s2
            Repeater {
                model: app.groups
                delegate: QQC2.AbstractButton {
                    id: ct
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 56
                    focusPolicy: Qt.TabFocus
                    onClicked: pg.openGroup(modelData.id)
                    background: Rectangle {
                        radius: Theme.rCtl + 2
                        color: ct.down ? Theme.press : (ct.hovered ? Theme.hover : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                        FocusRing { shown: ct.visualFocus; round: Theme.rCtl + 2 }
                    }
                    contentItem: RowLayout {
                        spacing: Theme.s3
                        Chip { iconName: app.groupIcon(ct.modelData.id); box: 36; tone: ct.hovered ? "accent" : "neutral" }
                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            QQC2.Label { text: ct.modelData.name; color: Theme.ink; font.pixelSize: Theme.fsSmall + 0.5; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                            QQC2.Label { text: ct.modelData.count + " settings"; color: Theme.ink3; font.pixelSize: Theme.fsCaption; Layout.fillWidth: true }
                        }
                    }
                    leftPadding: 8; rightPadding: 8
                }
            }
        }
    }
}
