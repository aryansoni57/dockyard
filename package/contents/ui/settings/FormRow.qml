import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// A label + field row inside a card, with an optional hint under the field.
GridLayout {
    id: row

    property string label
    property string hint
    default property alias field: holder.data

    Layout.fillWidth: true
    columns: 2
    columnSpacing: Kirigami.Units.largeSpacing
    rowSpacing: Kirigami.Units.smallSpacing / 2

    QQC2.Label {
        text: row.label
        opacity: 0.8
        horizontalAlignment: Text.AlignRight
        wrapMode: Text.Wrap
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    }
    RowLayout {
        id: holder
        Layout.fillWidth: true
    }
    Item {
        visible: row.hint !== ""
        implicitWidth: 1
    }
    QQC2.Label {
        visible: row.hint !== ""
        text: row.hint
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        opacity: 0.6
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
}
