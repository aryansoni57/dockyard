import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// A titled card holding a grid of controls. Hides itself when every child is hidden.
ColumnLayout {
    id: card

    property string title
    property string subtitle
    property int columns: 1
    default property alias content: grid.data
    readonly property bool anyVisible: {
        for (let i = 0; i < grid.children.length; i++) {
            if (grid.children[i].visible)
                return true;
        }
        return false;
    }

    visible: anyVisible
    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    QQC2.Label {
        text: card.title.toUpperCase()
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
        opacity: 0.55
        Layout.leftMargin: Kirigami.Units.smallSpacing
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: inner.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: Kirigami.Units.cornerRadius * 2
        color: Qt.alpha(Kirigami.Theme.textColor, 0.04)
        border.width: 1
        border.color: Qt.alpha(Kirigami.Theme.textColor, 0.1)

        ColumnLayout {
            id: inner
            x: Kirigami.Units.largeSpacing
            y: Kirigami.Units.largeSpacing
            width: parent.width - Kirigami.Units.largeSpacing * 2
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                visible: card.subtitle !== ""
                text: card.subtitle
                opacity: 0.6
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            GridLayout {
                id: grid
                Layout.fillWidth: true
                columns: card.columns
                columnSpacing: Kirigami.Units.largeSpacing * 2
                rowSpacing: Kirigami.Units.smallSpacing
            }
        }
    }
}
