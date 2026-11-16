import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import dev.dockyard.kcmhost
import ".."

// One System Settings module, hosted in our window: header with breadcrumb, the module edge to edge
// on the deck, and an Apply / Reset / Defaults bar when the module has settings to save.
Item {
    id: pg
    property string moduleId
    property string title: ""
    property string backLabel: ""
    property string moduleIcon: ""
    property string subName: ""
    property string comment: ""
    property var app: null
    property var moduleArgs: []
    property QtObject sys: null
    signal back()
    signal openKcm(string id)
    signal toast(string text, string icon)
    readonly property bool dirty: host.status === 1 && host.module && host.module.needsSave === true
    readonly property var mod: host.status === 1 ? host.module : null
    readonly property int buttons: host.buttons
    readonly property bool footer: mod !== null && (buttons & 4) !== 0
    readonly property real footerHeight: footer ? bar.height : 0
    function apply() { host.save(); }
    // Saves, then reports the real outcome: a save that needs authorization or fails leaves the module dirty.
    property int waited: 0
    function applyAndReport() { apply(); waited = 0; settle.restart(); }
    Timer {
        id: settle
        interval: 250
        repeat: true
        onTriggered: {
            pg.waited += 1;
            if (!pg.dirty) { stop(); pg.toast(pg.title + " applied", "check"); }
            else if (pg.waited >= 24) { stop(); pg.toast(pg.title + " was not applied", "alert"); }
        }
    }
    // Back inside the module: pops its own sub-page. False when already on the first page.
    function up() { if (row.depth > 1) { host.popPage(); return true; } return false; }
    function activate(args) { host.activate(args); }
    readonly property string pageTitle: row.depth > 1 && row.currentItem && row.currentItem.title ? String(row.currentItem.title) : ""
    function discard() { host.load(); }
    Exec { id: sh }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---- Header ----
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            spacing: 12
            IconBtn {
                visible: pg.backLabel !== "" || pg.pageTitle !== ""
                iconName: "arrow-left"
                box: 36
                tip: (pg.pageTitle !== "" ? "Back to " + pg.title : "Back to " + pg.backLabel) + "  (Alt+Left)"
                onClicked: { if (!pg.up()) pg.back(); }
            }
            Kirigami.Icon { source: pg.moduleIcon; visible: pg.moduleIcon !== ""; Layout.preferredWidth: 32; Layout.preferredHeight: 32; Layout.leftMargin: pg.backLabel !== "" ? 2 : 6 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                RowLayout {
                    visible: pg.backLabel !== "" || pg.pageTitle !== ""
                    spacing: 4
                    QQC2.Label {
                        id: crumb
                        text: pg.backLabel
                        color: crumbMouse.containsMouse ? Theme.accentInk : Theme.ink3
                        font.pixelSize: Theme.fsCaption
                        font.weight: Font.Medium
                        MouseArea { id: crumbMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pg.back() }
                    }
                    Ico { visible: pg.subName !== ""; name: "chevron-right"; size: 12; color: Theme.ink4 }
                    QQC2.Label { visible: pg.subName !== ""; text: pg.subName; color: Theme.ink3; font.pixelSize: Theme.fsCaption }
                    Ico { visible: pg.pageTitle !== ""; name: "chevron-right"; size: 12; color: Theme.ink4 }
                    QQC2.Label { visible: pg.pageTitle !== ""; text: pg.title; color: Theme.ink3; font.pixelSize: Theme.fsCaption }
                }
                QQC2.Label { text: pg.pageTitle !== "" ? pg.pageTitle : pg.title; color: Theme.ink; font.pixelSize: Theme.fsH2; font.weight: Font.DemiBold; font.letterSpacing: -0.2; Layout.fillWidth: true; elide: Text.ElideRight }
            }
            // The module's own page actions (e.g. "Install from File…", "Get New…"). The page row has
            // no toolbar here, so they are drawn in this header.
            Repeater {
                model: row.currentItem && row.currentItem.actions ? row.currentItem.actions : []
                delegate: QQC2.Button {
                    id: ab
                    required property var modelData
                    readonly property var kids: modelData.children ? Array.from(modelData.children) : []
                    visible: modelData.visible !== false
                    enabled: modelData.enabled !== false
                    // displayHint IconOnly (1): hide the label, keep it as a tooltip.
                    readonly property bool iconOnly: (modelData.displayHint & 1) !== 0 && icon.name !== ""
                    text: iconOnly ? "" : modelData.text
                    icon.name: modelData.icon ? (modelData.icon.name || String(modelData.icon.source || "")) : ""
                    flat: true
                    checkable: modelData.checkable === true
                    checked: modelData.checked === true
                    QQC2.ToolTip.visible: iconOnly && hovered
                    QQC2.ToolTip.text: modelData.text
                    onClicked: kids.length ? sub.popup(ab, 0, ab.height) : modelData.trigger()
                    QQC2.Menu {
                        id: sub
                        Repeater {
                            model: ab.kids
                            delegate: QQC2.MenuItem {
                                required property var modelData
                                text: modelData.text
                                icon.name: modelData.icon ? (modelData.icon.name || "") : ""
                                enabled: modelData.enabled !== false
                                visible: modelData.visible !== false
                                checkable: modelData.checkable === true
                                checked: modelData.checked === true
                                onTriggered: modelData.trigger()
                            }
                        }
                    }
                }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.line }

        // ---- Module area. Kirigami palette follows our theme so the module matches. ----
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.bottomMargin: pg.footer ? 0 : 6
            clip: true

            Item {
                id: themed
                anchors.fill: parent
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                Kirigami.Theme.backgroundColor: Theme.deck
                Kirigami.Theme.alternateBackgroundColor: Theme.card
                Kirigami.Theme.textColor: Theme.ink
                Kirigami.Theme.disabledTextColor: Theme.ink3
                Kirigami.Theme.highlightColor: Theme.accent
                Kirigami.Theme.highlightedTextColor: Theme.accentFg
                Kirigami.Theme.linkColor: Theme.accentInk
                Kirigami.Theme.focusColor: Theme.accent
                Kirigami.Theme.hoverColor: Theme.accent

                KcmHost {
                    id: host
                    anchors.fill: parent
                    moduleId: pg.moduleId
                    args: pg.moduleArgs
                    onStatusChanged: if (status === 1 && !isWidget && content) { row.clear(); row.push(content); }
                    onPagePushed: (page) => row.push(page)
                    onPageRemoved: row.pop()
                }
                Kirigami.PageRow {
                    id: row
                    anchors.fill: parent
                    visible: host.status === 1 && !host.isWidget
                    globalToolBar.style: Kirigami.ApplicationHeaderStyle.None
                    columnView.columnResizeMode: Kirigami.ColumnView.SingleColumn
                    initialPage: null
                }
                Loader {
                    anchors.fill: parent
                    active: host.status === 1 && host.isWidget
                    sourceComponent: WindowContainer { window: host.nativeWindow }
                }
            }

            // Loading: a skeleton of a settings form.
            Column {
                visible: host.status === 0
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 28 }
                spacing: 18
                Skeleton { width: Math.min(parent.width, 320); height: 14 }
                Repeater {
                    model: 5
                    Row {
                        required property int index
                        spacing: 16
                        Skeleton { width: 140; height: 12; anchors.verticalCenter: parent.verticalCenter }
                        Skeleton { width: Math.min(260, Math.max(80, pg.width - 260)) - index * 18; height: 30; radius: 9 }
                    }
                }
            }

            // Error
            EmptyState {
                visible: host.status === 2
                anchors.centerIn: parent
                width: Math.min(parent.width - 48, 440)
                iconName: "alert"
                tone: "accent"
                title: "This module could not be shown here"
                body: host.errorString
                Btn { text: "Retry"; iconName: "refresh"; onClicked: { const m = host.moduleId; host.moduleId = ""; host.moduleId = m; } }
                Btn { text: "Open in separate window"; iconName: "external"; primary: true; onClicked: sh.run("kcmshell6 " + pg.moduleId) }
            }
        }

        // ---- Apply bar ----
        Rectangle {
            id: bar
            visible: pg.footer
            Layout.fillWidth: true
            Layout.preferredHeight: 62
            color: pg.dirty ? Theme.a(Theme.accent, Theme.dark ? 0.09 : 0.06) : "transparent"
            bottomLeftRadius: Theme.rDeck - 1
            bottomRightRadius: Theme.rDeck - 1
            Behavior on color { ColorAnimation { duration: Theme.dur } }
            Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: pg.dirty ? Theme.accentLine : Theme.line; Behavior on color { ColorAnimation { duration: Theme.dur } } }
            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                spacing: 8
                Btn {
                    visible: (pg.buttons & 2) !== 0
                    quiet: true
                    iconName: "refresh"
                    text: "Defaults"
                    enabled: pg.mod && !pg.mod.representsDefaults
                    onClicked: host.defaults()
                    onHoveredChanged: host.setDefaultsIndicators(hovered)
                    Tip { text: "Reset every setting on this page to its default"; shown: parent.hovered }
                }
                Item { Layout.fillWidth: true }
                RowLayout {
                    spacing: 7
                    opacity: pg.dirty ? 1 : 0
                    visible: opacity > 0 && pg.width > 520
                    Behavior on opacity { NumberAnimation { duration: Theme.dur } }
                    Rectangle { width: 7; height: 7; radius: 3.5; color: Theme.accent }
                    QQC2.Label { text: "Unsaved changes"; color: Theme.ink2; font.pixelSize: Theme.fsSmall }
                    Item { width: 6 }
                }
                Btn { text: "Reset"; enabled: pg.dirty; onClicked: pg.discard() }
                Btn {
                    text: "Apply"
                    iconName: pg.mod && pg.mod.needsAuthorization ? "lock" : ""
                    primary: true
                    enabled: pg.dirty
                    onClicked: pg.applyAndReport()
                }
            }
        }
    }
}
