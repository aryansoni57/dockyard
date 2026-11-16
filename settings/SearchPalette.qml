import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Search palette (Ctrl+K, Ctrl+F or /): quick pages, their settings, categories and every System Settings module.
// Up and Down move, Enter opens, Esc closes. With no query it shows recent pages.
QQC2.Popup {
    id: p
    property var app
    property var kcms
    property string query: ""
    property int sel: 0
    parent: QQC2.Overlay.overlay
    modal: true
    focus: true
    x: Math.round((parent.width - width) / 2)
    y: Math.round(parent.height * 0.12)
    width: Math.min(600, parent.width - 48)
    height: Math.min(implicitHeight, parent.height * 0.8)
    padding: 0
    QQC2.Overlay.modal: Rectangle { color: Theme.scrim }
    background: Rectangle { radius: Theme.rCard + 2; color: Theme.card; border.width: 1; border.color: Theme.wellRim }
    enter: Transition { ParallelAnimation {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dur }
        NumberAnimation { property: "scale"; from: Theme.motion ? 0.97 : 1; to: 1; duration: Theme.dur; easing.type: Easing.OutCubic } } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.fast } }

    function openWith(q) { query = q; field.text = q; sel = firstItem(); open(); field.forceActiveFocus(); }
    onOpened: field.forceActiveFocus()

    readonly property var hits: {
        const q = query.trim().toLowerCase();
        const out = [];
        const head = (t) => out.push({ kind: "head", label: t });
        if (!q) {
            if (app.recent.length) {
                head("Recent");
                app.recent.forEach(r => out.push(r.k === "kcm" ? { kind: "kcm", id: r.id, label: r.label, sub: r.sub, icon: r.icon }
                                                               : { kind: "native", page: r.page, label: r.label, sub: "Quick settings", icon: app.sections[r.page].icon }));
            }
            head("Quick settings");
            app.sections.forEach((s, i) => out.push({ kind: "native", page: i, label: s.name, sub: s.blurb, icon: s.icon }));
            return out;
        }
        const mine = [];
        app.sections.forEach((s, i) => { if (s.name.toLowerCase().indexOf(q) >= 0) mine.push({ kind: "native", page: i, label: s.name, sub: s.blurb, icon: s.icon }); });
        app.index.forEach(e => { if (e[1] !== app.sections[e[0]].name && (e[1] + " " + e[2]).toLowerCase().indexOf(q) >= 0) mine.push({ kind: "native", page: e[0], label: e[1], sub: app.sections[e[0]].name, icon: app.sections[e[0]].icon }); });
        app.groups.forEach(g => { if (g.name.toLowerCase().indexOf(q) >= 0) mine.push({ kind: "group", id: g.id, label: g.name, sub: g.count + " settings", icon: app.groupIcon(g.id) }); });
        if (mine.length) { head("Dockyard"); mine.forEach(m => out.push(m)); }
        const mods = kcms.search(q);
        if (mods.length) { head("System Settings"); mods.forEach(m => out.push({ kind: "kcm", id: m.kcmId, label: m.name, sub: m.groupName + (m.subName ? " › " + m.subName : ""), icon: m.icon })); }
        return out;
    }
    readonly property int count: hits.filter(h => h.kind !== "head").length
    function firstItem() { for (let i = 0; i < hits.length; i++) if (hits[i].kind !== "head") return i; return -1; }
    function step(d) {
        let i = sel;
        for (let n = 0; n < hits.length; n++) {
            i = (i + d + hits.length) % hits.length;
            if (hits[i].kind !== "head") { sel = i; list.positionViewAtIndex(i, ListView.Contain); return; }
        }
    }
    function activate(h) {
        if (!h || h.kind === "head") return;
        close();
        if (h.kind === "kcm") app.openKcm(h.id); else if (h.kind === "group") app.go("group", h.id); else app.go("native", h.page);
    }
    onHitsChanged: sel = firstItem()

    contentItem: ColumnLayout {
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            Layout.leftMargin: 18
            Layout.rightMargin: 14
            spacing: 12
            Ico { name: "search"; size: 20; color: Theme.ink2 }
            QQC2.TextField {
                id: field
                Layout.fillWidth: true
                placeholderText: "Search settings and modules"
                placeholderTextColor: Theme.ink3
                color: Theme.ink
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentFg
                font.pixelSize: Theme.fsTitle
                background: null
                leftPadding: 0
                onTextEdited: p.query = text
                Keys.onDownPressed: p.step(1)
                Keys.onUpPressed: p.step(-1)
                Keys.onEscapePressed: p.close()
                onAccepted: p.activate(p.hits[p.sel])
            }
            Kbd { text: "Esc" }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.line }
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight + 16, 440)
            Layout.minimumHeight: 60
            clip: true
            topMargin: 8
            bottomMargin: 8
            model: p.hits
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: Scroller {}
            delegate: QQC2.AbstractButton {
                id: d
                required property var modelData
                required property int index
                readonly property bool head: modelData.kind === "head"
                readonly property bool cur: p.sel === index
                width: list.width
                height: head ? 30 : 46
                enabled: !head
                hoverEnabled: true
                onHoveredChanged: if (hovered && !head) p.sel = index
                onClicked: p.activate(modelData)
                background: Rectangle {
                    x: 8; width: parent.width - 16; height: parent.height
                    radius: Theme.rCtl
                    color: !d.head && d.cur ? Theme.accentSoft : "transparent"
                }
                contentItem: Item {
                    QQC2.Label {
                        visible: d.head
                        x: 22; anchors.bottom: parent.bottom; anchors.bottomMargin: 5
                        text: d.modelData.label
                        color: Theme.ink3
                        font.pixelSize: Theme.fsMicro
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.6
                        font.capitalization: Font.AllUppercase
                    }
                    RowLayout {
                        visible: !d.head
                        anchors { fill: parent; leftMargin: 18; rightMargin: 20 }
                        spacing: 12
                        Item {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            Chip { visible: d.modelData.kind !== "kcm"; anchors.centerIn: parent; box: 30; iconName: d.modelData.icon || ""; tone: d.cur ? "solid" : "neutral" }
                            Kirigami.Icon { visible: d.modelData.kind === "kcm"; anchors.centerIn: parent; width: 26; height: 26; source: d.modelData.icon || "" }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            QQC2.Label { text: d.modelData.label || ""; color: Theme.ink; font.pixelSize: Theme.fsBody; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                            QQC2.Label { text: d.modelData.sub || ""; visible: text !== ""; color: Theme.ink3; font.pixelSize: Theme.fsCaption; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                        Ico { visible: d.cur; name: "chevron-right"; size: 16; color: Theme.accentInk }
                    }
                }
            }
        }
        EmptyState {
            visible: p.query.trim() !== "" && p.count === 0
            Layout.fillWidth: true
            Layout.margins: 24
            iconName: "search"
            title: "Nothing matches “" + p.query.trim() + "”"
            body: "Try a shorter word, or a setting name like “wallpaper” or “keyboard”."
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.line }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            Layout.leftMargin: 18
            Layout.rightMargin: 18
            spacing: 14
            QQC2.Label { text: p.query.trim() ? p.count + (p.count === 1 ? " result" : " results") : "Type to search " + p.app.kcmModel.rowCount() + " modules"; color: Theme.ink3; font.pixelSize: Theme.fsCaption; Layout.fillWidth: true }
            RowLayout { spacing: 5; Kbd { text: "↑↓" } QQC2.Label { text: "move"; color: Theme.ink3; font.pixelSize: Theme.fsCaption } }
            RowLayout { spacing: 5; Kbd { text: "Enter" } QQC2.Label { text: "open"; color: Theme.ink3; font.pixelSize: Theme.fsCaption } }
        }
    }
}
