import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "settings"

// App Setups: named sets of apps that open and tile together. Saved as JSON in `appSetups`:
// [{"name": "Research", "layout": "side", "apps": ["firefox", "org.kde.kate"]}].
KCM.SimpleKCM {
    id: page

    property string cfg_appSetups

    readonly property var layouts: [
        { key: "side", text: i18n("Side by side") },
        { key: "grid", text: i18n("Grid") },
        { key: "main", text: i18n("One large, others stacked") }
    ]

    // The working copy. The cards read it once; edits write it back to cfg_appSetups
    // without rebuilding the cards, so a text field keeps focus while you type.
    property var setups: []
    property int count: 0
    property bool loaded: false

    function load() {
        let list = [];
        try {
            list = JSON.parse(cfg_appSetups || "[]");
        } catch (e) {
            list = [];
        }
        setups = Array.isArray(list) ? list : [];
        count = setups.length;
        loaded = true;
    }
    function save() {
        cfg_appSetups = JSON.stringify(setups);
    }
    function patch(i, key, value) {
        const next = setups.slice();
        next[i] = Object.assign({}, next[i], { [key]: value });
        setups = next;
        save();
    }
    function add() {
        setups = setups.concat([{ name: i18n("Setup %1", setups.length + 1), layout: "side", apps: [] }]);
        count = setups.length;
        save();
    }
    function remove(i) {
        const next = setups.slice();
        next.splice(i, 1);
        setups = next;
        count = next.length;
        save();
        // The cards read their values once, so rebuild them after a removal.
        rebuild.restart();
    }
    // "applications:org.kde.kate.desktop" or "kate.desktop" -> "org.kde.kate"
    function desktopId(t) {
        return t.replace(/^applications:/, "").replace(/\.desktop$/, "").trim();
    }
    function appName(id) {
        const last = id.split(".").pop().replace(/[-_]/g, " ");
        return last.charAt(0).toUpperCase() + last.slice(1);
    }

    Component.onCompleted: load()
    Timer {
        id: rebuild
        interval: 0
        onTriggered: {
            const keep = page.setups;
            page.count = 0;
            page.count = keep.length;
        }
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing * 1.5

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            opacity: 0.7
            text: i18n("A setup opens its apps (or brings up the ones already running) and tiles them across the screen. Run one from the App Setups row of the Dashboard Start style. There, Save current turns the windows you have open into a setup.")
        }

        Repeater {
            model: page.loaded ? page.count : 0

            delegate: Card {
                id: card
                required property int index
                readonly property var setup: page.setups[index] || ({ name: "", layout: "side", apps: [] })
                title: i18n("Setup %1", index + 1)

                FormRow {
                    label: i18n("Name:")
                    QQC2.TextField {
                        Layout.fillWidth: true
                        Component.onCompleted: text = card.setup.name
                        onTextEdited: page.patch(card.index, "name", text)
                    }
                }
                // Saved with Save current: each window returns to its own monitor and place.
                FormRow {
                    label: i18n("Layout:")
                    visible: card.setup.layout === "saved"
                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: i18n("Saved window positions (%1 windows). Each one goes back to its own monitor.", (card.setup.windows || []).length)
                        }
                        QQC2.Button {
                            text: i18n("Use a tiled layout")
                            onClicked: {
                                page.patch(card.index, "layout", "side");
                                page.patch(card.index, "windows", []);
                                rebuild.restart();
                            }
                        }
                    }
                }
                FormRow {
                    label: i18n("Layout:")
                    visible: card.setup.layout !== "saved"
                    QQC2.ComboBox {
                        Layout.fillWidth: true
                        model: page.layouts.map(l => l.text)
                        Component.onCompleted: currentIndex = Math.max(0, page.layouts.findIndex(l => l.key === card.setup.layout))
                        onActivated: i => page.patch(card.index, "layout", page.layouts[i].key)
                    }
                }
                StringListEditor {
                    Layout.fillWidth: true
                    value: (card.setup.apps || []).join(",")
                    onEdited: v => page.patch(card.index, "apps", v.split(",").map(s => s.trim()).filter(s => s !== ""))
                    iconFor: id => id
                    labelFor: id => page.appName(id)
                    normalize: t => page.desktopId(t)
                    placeholder: i18n("Desktop file name, e.g. firefox or org.kde.kate")
                    emptyText: i18n("No apps yet. Add one below.")
                }
                QQC2.Button {
                    Layout.alignment: Qt.AlignRight
                    icon.name: "edit-delete"
                    text: i18n("Delete setup")
                    onClicked: page.remove(card.index)
                }
            }
        }

        QQC2.Button {
            icon.name: "list-add"
            text: i18n("Add a setup")
            onClicked: page.add()
        }
    }
}
