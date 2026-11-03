import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Edits a comma-separated config string as a list of rows: reorder, remove, add.
// Bind `value` to the cfg_ property and write `edited` back to it.
ColumnLayout {
    id: editor

    property string value
    property string placeholder
    property string emptyText
    // Optional per-item icon and label; default is the raw item.
    property var iconFor: null
    property var labelFor: null
    // Optional check on the text typed in the add field; returns "" or an error message.
    property var validate: null
    // Optional cleanup of typed text before it is checked and added.
    property var normalize: null
    // When set, items are added from this list (minus those already in) instead of typed.
    property var choices: []
    readonly property var freeChoices: choices.filter(c => items.indexOf(c) < 0)

    signal edited(string value)

    readonly property var items: value.split(",").map(s => s.trim()).filter(s => s !== "")
    readonly property string typed: normalize ? normalize(newItem.text.trim()) : newItem.text.trim()
    readonly property string addError: typed === "" ? ""
        : items.indexOf(typed) >= 0 ? i18n("Already in the list")
        : validate ? validate(typed) : ""

    function commit(list) {
        edited(list.join(","));
    }
    function move(from, to) {
        const list = items.slice();
        list.splice(to, 0, list.splice(from, 1)[0]);
        commit(list);
    }
    function add() {
        if (choices.length > 0) {
            if (picker.currentIndex >= 0)
                commit(items.concat([freeChoices[picker.currentIndex]]));
            return;
        }
        const t = typed;
        if (t === "" || addError !== "")
            return;
        commit(items.concat([t]));
        newItem.text = "";
    }

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    QQC2.Label {
        visible: editor.items.length === 0 && editor.emptyText !== ""
        text: editor.emptyText
        opacity: 0.6
        Layout.fillWidth: true
    }

    Repeater {
        model: editor.items

        Rectangle {
            id: itemRow
            required property string modelData
            required property int index

            Layout.fillWidth: true
            implicitHeight: rowLayout.implicitHeight + Kirigami.Units.smallSpacing * 2
            radius: Kirigami.Units.cornerRadius
            color: hover.hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.06) : "transparent"

            HoverHandler { id: hover }

            RowLayout {
                id: rowLayout
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.smallSpacing
                anchors.rightMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    text: itemRow.index + 1
                    opacity: 0.45
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: Kirigami.Units.gridUnit
                }
                Kirigami.Icon {
                    visible: editor.iconFor !== null
                    source: editor.iconFor ? editor.iconFor(itemRow.modelData) : ""
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                }
                QQC2.Label {
                    text: editor.labelFor ? editor.labelFor(itemRow.modelData) : itemRow.modelData
                    elide: Text.ElideRight
                    Layout.fillWidth: true

                    QQC2.ToolTip.visible: editor.labelFor !== null && hover.hovered
                    QQC2.ToolTip.text: itemRow.modelData
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
                QQC2.ToolButton {
                    icon.name: "arrow-up"
                    enabled: itemRow.index > 0
                    onClicked: editor.move(itemRow.index, itemRow.index - 1)
                    QQC2.ToolTip.text: i18n("Move up")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
                QQC2.ToolButton {
                    icon.name: "arrow-down"
                    enabled: itemRow.index < editor.items.length - 1
                    onClicked: editor.move(itemRow.index, itemRow.index + 1)
                    QQC2.ToolTip.text: i18n("Move down")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
                QQC2.ToolButton {
                    icon.name: "list-remove"
                    onClicked: editor.commit(editor.items.filter((_, i) => i !== itemRow.index))
                    QQC2.ToolTip.text: i18n("Remove")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing

        QQC2.ComboBox {
            id: picker
            visible: editor.choices.length > 0
            enabled: editor.freeChoices.length > 0
            model: editor.freeChoices.map(c => editor.labelFor ? editor.labelFor(c) : c)
            Layout.fillWidth: true
        }
        QQC2.TextField {
            id: newItem
            visible: editor.choices.length === 0
            Layout.fillWidth: true
            placeholderText: editor.placeholder
            // Take Enter here, or the settings dialog treats it as OK and closes.
            Keys.onReturnPressed: event => {
                event.accepted = true;
                editor.add();
            }
            Keys.onEnterPressed: event => {
                event.accepted = true;
                editor.add();
            }
        }
        QQC2.Button {
            icon.name: "list-add"
            text: i18n("Add")
            enabled: editor.choices.length > 0 ? editor.freeChoices.length > 0
                : newItem.text.trim() !== "" && editor.addError === ""
            onClicked: editor.add()
        }
    }
    QQC2.Label {
        visible: editor.addError !== ""
        text: editor.addError
        color: Kirigami.Theme.negativeTextColor
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
    }
}
