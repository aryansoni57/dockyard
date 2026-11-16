import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import ".."

Sheet {
    id: pg
    title: "Appearance"
    subtitle: "Changes apply as you click"
    iconName: "appearance"
    Exec { id: sh }
    property string active: ""
    readonly property var looks: [
        { id: "dev.aryan.dockyard", name: "Dockyard Night", c0: "#3a0f3c", c1: "#171025", win: "#2a1230", bar: "#ec4f86", night: true },
        { id: "dev.aryan.dockyard.day", name: "Dockyard Day", c0: "#ffd9e6", c1: "#dccbff", win: "#fff7fb", bar: "#ec4f86", night: false },
        { id: "org.kde.breezedark.desktop", name: "Breeze Dark", c0: "#1b2b3d", c1: "#101820", win: "#232629", bar: "#3daee9", night: true },
        { id: "org.kde.breeze.desktop", name: "Breeze", c0: "#b9d4ee", c1: "#e3eef8", win: "#eff0f1", bar: "#3daee9", night: false }
    ]
    Component.onCompleted: sh.run("kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage", (o) => active = o.trim())

    Card {
        SettingRow {
            iconName: "auto"
            label: "Sync with system theme"
            caption: Theme.sync ? "This app follows the system's dark or light scheme and accent colour. Change them in System Settings." : "Choose this app's mode and accent colour below."
            last: true
            Toggle { checked: Theme.sync; Accessible.name: "Sync with system theme"; onToggled: Theme.setSync(checked) }
        }
    }

    // ---- Mode: three preview cards ----
    Card {
        title: "Mode"
        description: Theme.sync ? "Locked while synced with the system theme." : "Auto follows the clock: day from 07:00, night from 19:00."
        enabled: !Theme.sync
        opacity: Theme.sync ? 0.5 : 1
        padded: true
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s3
            Repeater {
                model: [
                    { id: "night", n: "Night", i: "moon", bg: "#1a1220", fg: "#2b2131", ink: "#f6eff6" },
                    { id: "day", n: "Day", i: "sun", bg: "#f4eff3", fg: "#ffffff", ink: "#1f1622" },
                    { id: "auto", n: "Auto", i: "auto", bg: "", fg: "", ink: "" }
                ]
                delegate: QQC2.AbstractButton {
                    id: mc
                    required property var modelData
                    readonly property bool sel: Theme.mode === modelData.id
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 128
                    focusPolicy: Qt.TabFocus
                    Accessible.name: modelData.n
                    onClicked: Theme.setMode(modelData.id)
                    component Mini: Rectangle {
                        property color bg
                        property color fg
                        property color ink
                        color: bg
                        Rectangle { x: 8; y: 8; width: parent.width * 0.28; height: parent.height - 16; radius: 4; color: Qt.rgba(1, 1, 1, 0.0); border.width: 0
                            Column { spacing: 4; Repeater { model: 4; Rectangle { required property int index; width: 22 - index * 3; height: 3; radius: 1.5; color: index === 0 ? Theme.accent : ink; opacity: index === 0 ? 1 : 0.35 } } } }
                        Rectangle { x: parent.width * 0.36; y: 8; width: parent.width * 0.64 - 8; height: parent.height - 16; radius: 5; color: fg
                            Rectangle { x: 6; y: 6; width: parent.width * 0.5; height: 4; radius: 2; color: ink; opacity: 0.7 }
                            Rectangle { x: 6; y: 14; width: parent.width - 12; height: 3; radius: 1.5; color: ink; opacity: 0.2 }
                            Rectangle { x: 6; y: 21; width: parent.width * 0.7; height: 3; radius: 1.5; color: ink; opacity: 0.2 }
                            Rectangle { anchors { right: parent.right; bottom: parent.bottom; margins: 6 } width: 14; height: 8; radius: 4; color: Theme.accent }
                        }
                    }
                    background: Rectangle {
                        radius: Theme.rCard - 2
                        color: mc.hovered && !mc.sel ? Theme.hover : "transparent"
                        border.width: mc.sel ? 2 : 1
                        border.color: mc.sel ? Theme.accent : Theme.line
                        FocusRing { shown: mc.visualFocus; round: Theme.rCard - 2 }
                    }
                    contentItem: ColumnLayout {
                        spacing: 8
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                clip: true
                                color: "transparent"
                                border.width: 1
                                border.color: Theme.line
                                Mini { anchors.fill: parent; anchors.margins: 1; radius: 7; visible: mc.modelData.id !== "auto"; bg: mc.modelData.bg; fg: mc.modelData.fg; ink: mc.modelData.ink }
                                Item {
                                    visible: mc.modelData.id === "auto"
                                    anchors.fill: parent; anchors.margins: 1
                                    Mini { width: parent.width; height: parent.height; radius: 7; bg: "#f4eff3"; fg: "#ffffff"; ink: "#1f1622" }
                                    Item {
                                        width: parent.width / 2; height: parent.height; x: parent.width / 2; clip: true
                                        Mini { x: -parent.x; width: parent.parent.width; height: parent.height; radius: 7; bg: "#1a1220"; fg: "#2b2131"; ink: "#f6eff6" }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            spacing: 6
                            Layout.alignment: Qt.AlignHCenter
                            Ico { name: mc.modelData.i; size: 15; color: mc.sel ? Theme.accentInk : Theme.ink2 }
                            QQC2.Label { text: mc.modelData.n; color: mc.sel ? Theme.ink : Theme.ink2; font.pixelSize: Theme.fsSmall; font.weight: mc.sel ? Font.DemiBold : Font.Medium }
                        }
                    }
                    padding: 8
                    bottomPadding: 10
                }
            }
        }
    }

    // ---- Accent ----
    Card {
        title: "Accent colour"
        description: Theme.sync ? "Locked while synced with the system theme." : "Used for selection, switches and focus, here and in the modules opened from this app."
        enabled: !Theme.sync
        opacity: Theme.sync ? 0.5 : 1
        padded: true
        Flow {
            Layout.fillWidth: true
            spacing: Theme.s3
            Repeater {
                model: Theme.accents
                delegate: QQC2.AbstractButton {
                    id: sw
                    required property var modelData
                    readonly property bool sel: Theme.accent.toString() === modelData.c
                    width: 40; height: 40
                    focusPolicy: Qt.TabFocus
                    onClicked: {
                        Theme.setAccent(modelData.c);
                        // Systemwide: KDE stores the accent in kdeglobals and re-colours Plasma, apps and the panel.
                        sh.run("python3 '" + Qt.resolvedUrl("../apply-accent.py").toString().replace("file://", "") + "' '" + modelData.c + "'; plasma-apply-colorscheme --accent-color '" + modelData.c + "' \"$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)\"; dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0; sh '" + Qt.resolvedUrl("../clear-dock-accent.sh").toString().replace("file://", "") + "'; sh '" + Qt.resolvedUrl("../../theme/apply-accent-all.sh").toString().replace("file://", "") + "' '" + modelData.c + "'",
                               (o, e, code) => pg.toast(code === 0 ? modelData.n + " accent, applied systemwide" : "Accent could not be applied", code === 0 ? "check" : "close"));
                    }
                    Accessible.name: modelData.n
                    Tip { text: sw.modelData.n; shown: sw.hovered }
                    background: Item {
                        Rectangle { anchors.fill: parent; radius: 20; color: "transparent"; border.width: 2; border.color: sw.modelData.c; opacity: sw.sel ? 1 : 0; Behavior on opacity { NumberAnimation { duration: Theme.fast } } }
                        Rectangle {
                            anchors.centerIn: parent
                            width: sw.sel ? 28 : (sw.hovered ? 34 : 32); height: width; radius: width / 2
                            color: sw.modelData.c
                            Behavior on width { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
                            Ico { anchors.centerIn: parent; name: "check"; size: 16; color: Theme.lum(sw.modelData.c) > 0.58 ? "#1c1218" : "#ffffff"; visible: sw.sel }
                        }
                        FocusRing { shown: sw.visualFocus; round: 20 }
                    }
                }
            }
        }
    }

    // ---- Global theme ----
    Card {
        title: "Global theme"
        description: "Sets colours, Plasma style, window decorations, icons and cursors together."
        padded: true
        GridLayout {
            Layout.fillWidth: true
            columns: width > 560 ? 4 : 2
            columnSpacing: Theme.s3
            rowSpacing: Theme.s3
            Repeater {
                model: pg.looks
                delegate: QQC2.AbstractButton {
                    id: tile
                    required property var modelData
                    readonly property bool sel: pg.active === modelData.id
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 128
                    focusPolicy: Qt.TabFocus
                    Accessible.name: modelData.name
                    onClicked: {
                        // Kvantum follows the look: a Dockyard Kvantum theme flips between night and Day, keeping solid or Glass.
                        const kvBase = modelData.night ? "Dockyard" : "DockyardDay";
                        const kvSwitch = modelData.id.indexOf("dockyard") >= 0
                            ? "; kv=$(kreadconfig6 --file Kvantum/kvantum.kvconfig --group General --key theme); case \"$kv\" in Dockyard|DockyardDay) kvantummanager --set " + kvBase + " ;; DockyardGlass|DockyardDayGlass) kvantummanager --set " + kvBase + "Glass ;; esac"
                            : "";
                        const iconSwitch = "; sh '" + Qt.resolvedUrl("../../package/contents/scripts/icon-tone.sh").toString().replace("file://", "") + "' " + (modelData.night ? "night" : "day");
                        sh.run("lookandfeeltool -a '" + modelData.id + "'" + kvSwitch + iconSwitch);
                        pg.active = modelData.id;
                        if (modelData.id.indexOf("dockyard") >= 0) Theme.setMode(modelData.night ? "night" : "day");
                        pg.toast("Applying " + modelData.name, "appearance");
                    }
                    background: Item {
                        Rectangle {
                            id: pv
                            width: parent.width; height: 92; radius: 12
                            border.width: tile.sel ? 2 : 1
                            border.color: tile.sel ? Theme.accent : Theme.line
                            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: tile.modelData.c0 } GradientStop { position: 1; color: tile.modelData.c1 } }
                            Rectangle { x: 16; y: 12; width: parent.width * 0.55; height: 46; radius: 6; color: tile.modelData.win; opacity: 0.94
                                Rectangle { x: 6; y: 6; width: 20; height: 3; radius: 1.5; color: tile.modelData.bar } }
                            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 70; width: parent.width * 0.6; height: 12; radius: 6; color: tile.modelData.win; opacity: 0.88
                                Row { anchors.centerIn: parent; spacing: 4; Repeater { model: 4; Rectangle { width: 5; height: 5; radius: 1.5; color: tile.modelData.bar; opacity: 0.8 } } } }
                            Rectangle {
                                visible: tile.sel
                                anchors { right: parent.right; top: parent.top; margins: 8 }
                                width: 20; height: 20; radius: 10; color: Theme.accent
                                Ico { anchors.centerIn: parent; name: "check"; size: 13; color: Theme.accentFg }
                            }
                            scale: tile.hovered && !tile.sel && Theme.motion ? 1.02 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.fast } }
                        }
                        QQC2.Label { y: 100; width: parent.width; text: tile.modelData.name; color: tile.sel ? Theme.ink : Theme.ink2; font.pixelSize: Theme.fsSmall; font.weight: tile.sel ? Font.DemiBold : Font.Medium; elide: Text.ElideRight }
                        FocusRing { shown: tile.visualFocus; round: 12; height: 92; anchors.fill: undefined; width: parent.width + 6; x: -3; y: -3 }
                    }
                }
            }
        }
    }

    // ---- Into the details ----
    Card {
        title: "Details"
        SettingRow { iconName: "palette"; label: "Colors"; caption: "Colour scheme for apps and windows"; clickable: true; onClicked: pg.openKcm("kcm_colors") }
        SettingRow { iconName: "shapes"; label: "Icons"; caption: "Icon theme"; clickable: true; onClicked: pg.openKcm("kcm_icons") }
        SettingRow { iconName: "type"; label: "Fonts"; caption: "Interface, document and fixed-width fonts"; clickable: true; onClicked: pg.openKcm("kcm_fonts") }
        SettingRow { iconName: "cursor"; label: "Cursors"; caption: "Pointer theme and size"; clickable: true; onClicked: pg.openKcm("kcm_cursortheme") }
        SettingRow { iconName: "deco"; label: "Window decorations"; caption: "Title bar style and buttons"; clickable: true; last: true; onClicked: pg.openKcm("kcm_kwindecoration") }
    }
}
