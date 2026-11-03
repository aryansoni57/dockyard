pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Todos tile: "N left" over the first two items, each with a round checkbox.
// `json` is the saved list ([{text, done}]). Changes emit `jsonEdited` so the
// owner can persist them; the owner does not need to write json back.
Tile {
    id: todos

    property string json: "[]"
    property string lastJson: ""
    property int openCount: 0

    readonly property real inner: height - padding * 2
    // Header and two rows share the tile's inner height, so nothing runs past the bottom.
    readonly property real headerH: inner * 0.36
    readonly property real rowH: inner * 0.3

    signal jsonEdited(string json)

    implicitWidth: Math.min(Kirigami.Units.gridUnit * 9, content.implicitWidth) + padding * 2
    clip: true

    ListModel {
        id: items
    }

    function parse(text) {
        var out = [];
        try {
            var arr = JSON.parse(text);
            if (Array.isArray(arr)) {
                for (var i = 0; i < arr.length; ++i) {
                    var it = arr[i];
                    if (it && typeof it === "object")
                        out.push({ text: String(it.text ?? ""), done: !!it.done });
                }
            }
        } catch (e) {
            return [];
        }
        return out;
    }

    function updateCount() {
        var n = 0;
        for (var i = 0; i < items.count; ++i)
            if (!items.get(i).done)
                ++n;
        openCount = n;
    }

    // Rebuild the model from a json string. Does not emit.
    function reload(text) {
        var list = parse(text);
        items.clear();
        for (var i = 0; i < list.length; ++i)
            items.append(list[i]);
        lastJson = text;
        updateCount();
    }

    // Emit the current list. lastJson guards against re-parsing our own output.
    function commit() {
        var out = [];
        for (var i = 0; i < items.count; ++i) {
            var it = items.get(i);
            out.push({ text: it.text, done: it.done });
        }
        var s = JSON.stringify(out);
        lastJson = s;
        updateCount();
        jsonEdited(s);
    }

    function addTodo(text) {
        var t = String(text).trim();
        if (t === "")
            return;
        items.append({ text: t, done: false });
        commit();
    }

    function toggle(index) {
        items.setProperty(index, "done", !items.get(index).done);
        commit();
    }

    function clearDone() {
        var removed = false;
        for (var i = items.count - 1; i >= 0; --i) {
            if (items.get(i).done) {
                items.remove(i);
                removed = true;
            }
        }
        if (removed)
            commit();
    }

    onJsonChanged: {
        if (json !== lastJson)
            reload(json);
    }
    Component.onCompleted: reload(json)

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: todos.padding
        spacing: 0

        PlasmaComponents.Label {
            Layout.fillWidth: true
            Layout.preferredHeight: todos.headerH
            Layout.maximumHeight: todos.headerH
            verticalAlignment: Text.AlignVCenter
            text: todos.openCount + " left"
            font.pixelSize: Math.max(8, Math.round(todos.headerH * 0.8))
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
            elide: Text.ElideRight
        }

        Repeater {
            model: items

            delegate: RowLayout {
                id: row
                required property int index
                required property string text
                required property bool done

                Layout.fillWidth: true
                Layout.preferredHeight: todos.rowH
                Layout.maximumHeight: todos.rowH
                visible: index < 2
                opacity: done ? 0.5 : 1
                spacing: todos.padding * 0.5

                Rectangle {
                    Layout.preferredWidth: todos.rowH * 0.7
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: width / 2
                    color: row.done ? Kirigami.Theme.highlightColor : "transparent"
                    border.width: 1
                    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.5)

                    TapHandler {
                        onTapped: todos.toggle(row.index)
                    }
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignVCenter
                    text: row.text
                    font.pixelSize: Math.max(8, Math.round(todos.rowH * 0.78))
                    font.strikeout: row.done
                    elide: Text.ElideRight
                }
            }
        }
    }
}
