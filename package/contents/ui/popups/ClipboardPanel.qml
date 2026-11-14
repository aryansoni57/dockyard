pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import "../components"
import "../components/motion.js" as Motion

// Clipboard popup, after the AvdanOS clipboard list: a search field, then Klipper's history
// as rounded cards, newest first. Each card shows its text (or image) and, at the bottom
// right, Copy (puts it back on the clipboard) and Remove. Clear history empties the list.
ColumnLayout {
    id: panel

    property var applet
    readonly property var history: applet.clipboardHistory

    spacing: 0
    implicitHeight: header.implicitHeight + searchField.implicitHeight + Kirigami.Units.largeSpacing * 3
        + (list.count > 0 ? Math.min(list.contentHeight, Kirigami.Units.gridUnit * 20)
                          : placeholder.implicitHeight + Kirigami.Units.largeSpacing * 2)

    RowLayout {
        id: header
        Layout.fillWidth: true
        Layout.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: "edit-paste-symbolic"
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: i18n("Clipboard")
            font.weight: Font.DemiBold
        }
        PlasmaComponents.ToolButton {
            enabled: !!panel.history && panel.history.sourceCount > 0
            icon.name: "edit-clear-history-symbolic"
            text: i18n("Clear history")
            onClicked: panel.history.clearHistory()
        }
    }

    Kirigami.SearchField {
        id: searchField
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.largeSpacing
        Layout.rightMargin: Kirigami.Units.largeSpacing
        Layout.bottomMargin: Kirigami.Units.smallSpacing
        placeholderText: i18n("Search history")
        Keys.onEscapePressed: event => {
            if (text !== "") {
                text = "";
            } else {
                event.accepted = false;
            }
        }
        Component.onCompleted: forceActiveFocus()
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: count > 0
        clip: true
        interactive: contentHeight > height
        spacing: Kirigami.Units.smallSpacing
        leftMargin: Kirigami.Units.largeSpacing
        rightMargin: Kirigami.Units.largeSpacing
        bottomMargin: Kirigami.Units.largeSpacing

        model: KItemModels.KSortFilterProxyModel {
            sourceModel: panel.history
            filterRoleName: "display"
            filterRegularExpression: RegExp(searchField.text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i")
        }

        delegate: Rectangle {
            id: card

            required property int index
            required property var model
            required property var uuid
            required property int type
            required property var decoration
            required property size imageSize

            readonly property bool isImage: type === 4
            property bool copied: false

            width: list.width - list.leftMargin - list.rightMargin
            implicitHeight: body.implicitHeight + Kirigami.Units.smallSpacing * 2
            height: implicitHeight
            radius: Kirigami.Units.gridUnit * 0.6
            color: Qt.alpha(Kirigami.Theme.textColor, cardHover.hovered ? 0.1 : 0.055)
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.09)

            Behavior on color {
                ColorAnimation { duration: Motion.ms(120, Kirigami.Units.longDuration) }
            }

            HoverHandler { id: cardHover }
            // Tap anywhere on the card puts it back on the clipboard.
            TapHandler {
                onTapped: card.copyBack()
            }

            function copyBack() {
                panel.history.moveToTop(card.uuid);
                card.copied = true;
                resetCopied.restart();
            }
            Timer {
                id: resetCopied
                interval: 1400
                onTriggered: card.copied = false
            }

            ColumnLayout {
                id: body
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing + 2
                spacing: 0

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    visible: !card.isImage
                    text: String(card.model.display || "")
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }
                Image {
                    Layout.alignment: Qt.AlignLeft
                    visible: card.isImage
                    source: card.isImage ? card.decoration : ""
                    sourceSize.height: Kirigami.Units.gridUnit * 5
                    fillMode: Image.PreserveAspectFit
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: card.copied ? i18n("Copied") : ""
                        opacity: 0.6
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                    PlasmaComponents.ToolButton {
                        icon.name: card.copied ? "dialog-ok-apply-symbolic" : "edit-copy-symbolic"
                        display: QQC2.AbstractButton.IconOnly
                        text: i18n("Copy")
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing
                        implicitHeight: implicitWidth
                        PlasmaComponents.ToolTip.text: text
                        PlasmaComponents.ToolTip.visible: hovered
                        onClicked: card.copyBack()
                    }
                    PlasmaComponents.ToolButton {
                        icon.name: "edit-delete-symbolic"
                        display: QQC2.AbstractButton.IconOnly
                        text: i18n("Remove")
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing
                        implicitHeight: implicitWidth
                        PlasmaComponents.ToolTip.text: text
                        PlasmaComponents.ToolTip.visible: hovered
                        onClicked: panel.history.remove(card.uuid)
                    }
                }
            }
        }
    }

    Kirigami.PlaceholderMessage {
        id: placeholder
        Layout.fillWidth: true
        Layout.margins: Kirigami.Units.largeSpacing
        visible: list.count === 0
        icon.name: "edit-paste-symbolic"
        text: searchField.text !== "" ? i18n("Nothing matches") : i18n("Clipboard is empty")
        explanation: searchField.text !== "" ? "" : i18n("Things you copy show up here")
    }
}
