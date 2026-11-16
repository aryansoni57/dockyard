import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

// Centered icon, title, body and an optional row of buttons, for empty lists and errors.
ColumnLayout {
    id: e
    property string iconName: "info"
    property string title
    property string body: ""
    property string tone: "neutral"
    default property alias actions: act.data
    spacing: Theme.s2
    Chip { iconName: e.iconName; box: 48; tone: e.tone; Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: Theme.s2 }
    QQC2.Label { text: e.title; color: Theme.ink; font.pixelSize: Theme.fsTitle; font.weight: Font.DemiBold; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap }
    QQC2.Label { visible: e.body !== ""; text: e.body; color: Theme.ink3; font.pixelSize: Theme.fsSmall; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap }
    RowLayout { id: act; visible: children.length > 0; spacing: Theme.s2; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: Theme.s3 }
}
