pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Notes popup: the list of notes on the left, the open note as a plain page on the
// right. Yellow ties it to the Notes tile. Notes are saved as you type, and a
// deleted note can be brought back until the undo strip times out.
RowLayout {
    id: panel

    property var applet

    readonly property color accent: "#FFCC00"
    readonly property int wordCount: {
        const t = editor.text.trim();
        return t === "" ? 0 : t.split(/\s+/).length;
    }
    property var deleted: null // { index, note } of the last deleted note

    function preview(note) {
        const lines = note.text.split("\n").filter(l => l.trim() !== "");
        return lines.slice(1).join(" ");
    }
    function writeHere() {
        editor.forceActiveFocus();
        editor.cursorPosition = editor.length;
    }
    // Shows the current note; typing writes it back.
    function sync() {
        const t = applet.notes[applet.noteIndex].text;
        if (editor.text !== t)
            editor.text = t;
    }

    spacing: 0

    Component.onCompleted: sync()

    // The popup window activates after this is built, so take focus a beat later.
    Timer {
        interval: 120
        running: true
        onTriggered: panel.writeHere()
    }

    Connections {
        target: panel.applet
        function onNoteIndexChanged() { panel.sync(); }
        function onNotesChanged() { if (!editor.activeFocus) panel.sync(); }
    }

    // Note list.
    ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 11
        Layout.maximumWidth: Kirigami.Units.gridUnit * 11
        Layout.fillHeight: true
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: i18n("Notes")
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                font.weight: Font.DemiBold
            }
            PlasmaComponents.ToolButton {
                icon.name: "list-add"
                text: i18n("New note")
                display: PlasmaComponents.AbstractButton.IconOnly
                onClicked: {
                    panel.applet.addNote();
                    panel.writeHere();
                }

                PlasmaComponents.ToolTip {
                    text: i18n("New note")
                }
            }
        }

        QQC2.ScrollView {
            id: listScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            clip: true

            Column {
                width: listScroll.availableWidth - Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.smallSpacing / 2

                Repeater {
                    // The count, not the list: typing must not rebuild the rows.
                    model: panel.applet.notes.length

                    delegate: Rectangle {
                        id: row
                        required property int index
                        readonly property var note: panel.applet.notes[index] ?? { text: "" }
                        readonly property bool picked: index === panel.applet.noteIndex

                        width: parent.width
                        height: rowText.implicitHeight + Kirigami.Units.largeSpacing * 1.5
                        radius: Kirigami.Units.cornerRadius
                        color: picked ? Qt.alpha(panel.accent, 0.16)
                            : Qt.alpha(Kirigami.Theme.textColor, rowHover.hovered ? 0.06 : 0)

                        Column {
                            id: rowText
                            anchors.verticalCenter: parent.verticalCenter
                            x: Kirigami.Units.largeSpacing
                            width: parent.width - Kirigami.Units.largeSpacing * 2

                            PlasmaComponents.Label {
                                width: parent.width
                                text: panel.applet.noteTitle(row.note)
                                elide: Text.ElideRight
                                font.weight: Font.DemiBold
                                opacity: row.note.text.trim() === "" ? 0.6 : 1
                            }
                            PlasmaComponents.Label {
                                visible: text !== ""
                                width: parent.width
                                text: panel.preview(row.note)
                                elide: Text.ElideRight
                                opacity: 0.6
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            }
                        }
                        HoverHandler { id: rowHover }
                        TapHandler {
                            onTapped: {
                                panel.applet.selectNote(row.index);
                                panel.writeHere();
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
    }

    // The open note.
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

            PlasmaComponents.TextArea {
                id: editor
                background: null
                placeholderText: i18n("Start writing")
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    if (text !== panel.applet.notes[panel.applet.noteIndex].text)
                        panel.applet.setNoteText(panel.applet.noteIndex, text);
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: panel.deleted !== null ? i18n("Note deleted")
                    : panel.wordCount > 0 ? i18np("%1 word", "%1 words", panel.wordCount) : ""
                opacity: 0.6
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.features: { "tnum": 1 }
            }
            PlasmaComponents.ToolButton {
                visible: panel.deleted !== null
                text: i18n("Undo")
                onClicked: {
                    panel.applet.restoreNote(panel.deleted.index, panel.deleted.note);
                    panel.deleted = null;
                    panel.writeHere();
                }
            }
            PlasmaComponents.ToolButton {
                visible: panel.deleted === null
                icon.name: "edit-delete"
                text: i18n("Delete note")
                display: PlasmaComponents.AbstractButton.IconOnly
                onClicked: {
                    const i = panel.applet.noteIndex;
                    panel.deleted = { index: i, note: panel.applet.notes[i] };
                    panel.applet.deleteNote(i);
                    panel.sync();
                    undoTimeout.restart();
                }

                PlasmaComponents.ToolTip {
                    text: i18n("Delete note")
                }
            }
        }
    }

    Timer {
        id: undoTimeout
        interval: 6000
        onTriggered: panel.deleted = null
    }
}
