import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

// A titled group: optional title, description and trailing controls above one rounded surface.
// Rows (SettingRow) go straight in; set padded for free-form content with an inner margin.
ColumnLayout {
    id: c
    property string title: ""
    property string description: ""
    property bool padded: false
    property alias trailing: trail.data
    property alias surface: surf
    default property alias content: col.data
    Layout.fillWidth: true
    spacing: Theme.s2 + 2

    RowLayout {
        visible: c.title !== "" || trail.children.length > 0
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 2
        Layout.minimumHeight: 28
        spacing: Theme.s3
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            QQC2.Label { visible: c.title !== ""; text: c.title; color: Theme.ink; font.pixelSize: Theme.fsBody + 1; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
            QQC2.Label { visible: c.description !== ""; text: c.description; color: Theme.ink3; font.pixelSize: Theme.fsCaption; Layout.fillWidth: true; wrapMode: Text.Wrap }
        }
        RowLayout { id: trail; spacing: Theme.s2; Layout.alignment: Qt.AlignBottom }
    }
    Rectangle {
        id: surf
        Layout.fillWidth: true
        implicitHeight: col.implicitHeight + (c.padded ? Theme.s5 * 2 : 0)
        radius: Theme.rCard
        color: Theme.card
        border.width: 1
        border.color: Theme.cardRim
        ColumnLayout {
            id: col
            x: c.padded ? Theme.s5 : 0
            y: c.padded ? Theme.s5 : 0
            width: parent.width - (c.padded ? Theme.s5 * 2 : 0)
            spacing: 0
        }
    }
}
