import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

// Short confirmation that rises from the bottom of the deck and fades after a moment.
Item {
    id: t
    property real bottomGap: 20
    property string text
    property string iconName: "check"
    property bool up: false
    width: pillBox.width
    height: pillBox.height
    y: parent.height - (up ? height + bottomGap : -8)
    opacity: up ? 1 : 0
    visible: opacity > 0
    z: 50
    Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: Theme.dur } }
    function show(msg, icon) { text = msg; iconName = icon || "check"; up = true; hide.restart(); }
    Timer { id: hide; interval: 2800; onTriggered: t.up = false }
    Rectangle {
        id: pillBox
        width: Math.min(row.implicitWidth + 28, (t.parent ? t.parent.width : 600) - 48)
        height: 40
        radius: 20
        color: Theme.dark ? "#f3ebf2" : "#241a28"
        RowLayout {
            id: row
            anchors.centerIn: parent
            width: parent.width - 28
            spacing: 9
            Ico { name: t.iconName; size: 16; color: Theme.dark ? "#241a28" : "#f6eff6" }
            QQC2.Label { text: t.text; color: Theme.dark ? "#241a28" : "#f6eff6"; font.pixelSize: Theme.fsSmall; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
        }
        MouseArea { anchors.fill: parent; onClicked: t.up = false }
    }
}
