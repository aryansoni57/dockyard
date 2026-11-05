pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Todos popup: progress on top, open todos, completed ones folded away, and the
// input at the bottom, next to the dock. Tap the circle to complete or restore,
// tap the text to edit it. Delete shows on hover.
ColumnLayout {
    id: panel

    property var applet

    readonly property var items: applet.todoItems()
    readonly property var openRows: rows(false)
    readonly property var doneRows: rows(true)
    readonly property bool allDone: items.length > 0 && openRows.length === 0
    readonly property color barColor: allDone ? "#30D158" : Kirigami.Theme.highlightColor
    property bool showDone: false
    property int editing: -1

    function rows(done) {
        const out = [];
        for (let i = 0; i < items.length; ++i) {
            if (!!items[i].done === done)
                out.push({ index: i, text: items[i].text, done: done });
        }
        return out;
    }
    function add() {
        applet.addTodo(input.text);
        input.text = "";
        input.forceActiveFocus();
    }

    spacing: Kirigami.Units.largeSpacing

    // The popup window activates after this is built, so take focus a beat later.
    Timer {
        interval: 120
        running: true
        onTriggered: input.forceActiveFocus()
    }

    component TodoRow: Item {
        id: row

        required property var modelData
        readonly property bool editing: panel.editing === modelData.index

        Layout.fillWidth: true
        implicitHeight: Math.max(Kirigami.Units.gridUnit * 2, label.implicitHeight + Kirigami.Units.largeSpacing)

        HoverHandler { id: rowHover }
        Rectangle {
            anchors.fill: parent
            radius: Kirigami.Units.cornerRadius
            color: Qt.alpha(Kirigami.Theme.textColor, rowHover.hovered && !row.editing ? 0.06 : 0)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.largeSpacing

            QQC2.AbstractButton {
                id: check
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                onClicked: panel.applet.toggleTodo(row.modelData.index)

                contentItem: Item {}
                background: Rectangle {
                    radius: width / 2
                    color: row.modelData.done ? Kirigami.Theme.highlightColor
                        : Qt.alpha(Kirigami.Theme.highlightColor, check.hovered ? 0.2 : 0)
                    border.width: 1.5
                    border.color: row.modelData.done || check.hovered ? Kirigami.Theme.highlightColor
                        : Qt.alpha(Kirigami.Theme.textColor, 0.5)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: parent.width * 0.7
                        height: width
                        visible: row.modelData.done
                        source: Qt.resolvedUrl("../../icons/check.svg")
                        isMask: true
                        color: Kirigami.Theme.highlightedTextColor
                    }
                }
            }
            PlasmaComponents.Label {
                id: label
                visible: !row.editing
                Layout.fillWidth: true
                text: row.modelData.text
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                font.strikeout: row.modelData.done
                opacity: row.modelData.done ? 0.5 : 1

                HoverHandler {
                    enabled: !row.modelData.done
                    cursorShape: Qt.IBeamCursor
                }
                TapHandler {
                    enabled: !row.modelData.done
                    onTapped: panel.editing = row.modelData.index
                }
            }
            PlasmaComponents.TextField {
                id: editField
                visible: row.editing
                Layout.fillWidth: true
                onVisibleChanged: {
                    if (visible) {
                        text = row.modelData.text;
                        forceActiveFocus();
                        selectAll();
                    }
                }
                onEditingFinished: {
                    if (row.editing) {
                        panel.editing = -1;
                        panel.applet.editTodo(row.modelData.index, text);
                    }
                }
                Keys.onEscapePressed: event => {
                    panel.editing = -1;
                    input.forceActiveFocus();
                }
            }
            PlasmaComponents.ToolButton {
                visible: !row.editing
                opacity: rowHover.hovered ? 1 : 0
                icon.name: "edit-delete-remove"
                text: i18n("Delete")
                display: PlasmaComponents.AbstractButton.IconOnly
                onClicked: panel.applet.deleteTodo(row.modelData.index)

                PlasmaComponents.ToolTip {
                    text: i18n("Delete")
                }
            }
        }
    }

    // Title and progress.
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: i18n("Todos")
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                font.weight: Font.DemiBold
            }
            PlasmaComponents.Label {
                visible: panel.items.length > 0
                text: i18n("%1 of %2 done", panel.doneRows.length, panel.items.length)
                opacity: 0.6
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.features: { "tnum": 1 }
            }
        }
        Rectangle {
            visible: panel.items.length > 0
            Layout.fillWidth: true
            implicitHeight: Kirigami.Units.smallSpacing
            radius: height / 2
            color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

            Rectangle {
                width: parent.width * panel.doneRows.length / Math.max(1, panel.items.length)
                height: parent.height
                radius: height / 2
                color: panel.barColor

                Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.InOutCubic }
                }
            }
        }
    }

    // Nothing open: say so instead of showing an empty gap.
    ColumnLayout {
        visible: panel.openRows.length === 0
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.largeSpacing * 2
        Layout.bottomMargin: Kirigami.Units.largeSpacing * 2
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            source: Qt.resolvedUrl("../../icons/check.svg")
            isMask: true
            color: panel.allDone ? "#30D158" : Kirigami.Theme.textColor
            opacity: panel.allDone ? 1 : 0.4
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: panel.allDone ? i18n("All done") : i18n("Nothing to do")
            font.weight: Font.DemiBold
        }
        PlasmaComponents.Label {
            visible: !panel.allDone
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: i18n("Type below and press Enter.")
            opacity: 0.6
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        }
    }

    QQC2.ScrollView {
        id: scroll
        visible: panel.items.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(list.implicitHeight, Kirigami.Units.gridUnit * 14)
        contentWidth: availableWidth
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
        clip: true

        ColumnLayout {
            id: list
            width: scroll.availableWidth
            spacing: 0

            Repeater {
                model: panel.openRows
                delegate: TodoRow {}
            }

            // Completed section, folded by default.
            RowLayout {
                visible: panel.doneRows.length > 0
                Layout.fillWidth: true
                spacing: 0

                QQC2.AbstractButton {
                    id: fold
                    Layout.fillWidth: true
                    implicitHeight: Kirigami.Units.gridUnit * 2
                    onClicked: panel.showDone = !panel.showDone

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            source: panel.showDone ? "go-down-symbolic" : "go-next-symbolic"
                            opacity: 0.6
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: i18n("Completed (%1)", panel.doneRows.length)
                            opacity: fold.hovered ? 1 : 0.6
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            font.weight: Font.DemiBold
                        }
                    }
                }
                PlasmaComponents.ToolButton {
                    visible: panel.showDone
                    text: i18n("Clear")
                    onClicked: panel.applet.clearDoneTodos()
                }
            }
            Repeater {
                model: panel.showDone ? panel.doneRows : []
                delegate: TodoRow {}
            }
        }
    }

    // Pill input with a round add button (docs/STYLE.md).
    PlasmaComponents.TextField {
        id: input
        Layout.fillWidth: true
        implicitHeight: Kirigami.Units.gridUnit * 2.4
        leftPadding: Kirigami.Units.largeSpacing * 2
        rightPadding: height
        placeholderText: i18n("Add a todo")
        onAccepted: panel.add()

        background: Rectangle {
            radius: height / 2
            color: Qt.alpha(Kirigami.Theme.textColor, 0.06)
            border.width: 1
            border.color: input.activeFocus ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.12)
        }

        QQC2.AbstractButton {
            id: addButton
            anchors.right: parent.right
            anchors.rightMargin: Kirigami.Units.smallSpacing
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height - Kirigami.Units.largeSpacing
            height: width
            enabled: input.text.trim() !== ""
            onClicked: panel.add()

            contentItem: Item {}
            background: Rectangle {
                radius: width / 2
                color: addButton.enabled ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.1)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    source: "list-add-symbolic"
                    isMask: true
                    color: addButton.enabled ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                }
            }
        }
    }
}
