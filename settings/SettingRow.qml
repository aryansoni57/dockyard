import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

// One row of a Card: optional icon chip, label and caption on the left, controls on the right.
// clickable rows get hover, focus, a chevron (or `trailingIcon`) and emit clicked().
QQC2.AbstractButton {
    id: r
    property string label
    property string caption: ""
    property string iconName: ""
    property string iconTone: "neutral"
    property string value: ""
    property bool last: false
    property bool clickable: false
    property string trailingIcon: "chevron-right"
    default property alias controls: slot.data
    Layout.fillWidth: true
    implicitHeight: Math.max(iconName !== "" ? 60 : 54, Math.max(txt.implicitHeight, slot.implicitHeight) + 22)
    hoverEnabled: clickable
    focusPolicy: clickable ? Qt.TabFocus : Qt.NoFocus
    Accessible.name: label
    padding: 0
    background: Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: Theme.rCard - 4
        color: r.clickable && r.down ? Theme.press : (r.clickable && r.hovered ? Theme.hover : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        FocusRing { shown: r.visualFocus; round: Theme.rCard - 4; anchors.margins: -1 }
    }
    contentItem: Item {}
    RowLayout {
        id: lay
        anchors { fill: parent; leftMargin: Theme.s4 + 2; rightMargin: Theme.s4 }
        spacing: Theme.s3 + 2
        Chip { visible: r.iconName !== ""; iconName: r.iconName; tone: r.iconTone; box: 34 }
        ColumnLayout {
            id: txt
            Layout.fillWidth: true
            spacing: 2
            QQC2.Label { text: r.label; color: Theme.ink; font.pixelSize: Theme.fsBody; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
            QQC2.Label { visible: r.caption !== ""; text: r.caption; color: Theme.ink3; font.pixelSize: Theme.fsCaption; Layout.fillWidth: true; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight }
        }
        RowLayout { id: slot; spacing: Theme.s2 + 2 }
        QQC2.Label { visible: r.value !== ""; text: r.value; color: Theme.ink2; font.pixelSize: Theme.fsSmall; font.features: { "tnum": 1 } }
        Ico { visible: r.clickable && r.trailingIcon !== ""; name: r.trailingIcon; size: 16; color: r.hovered ? Theme.ink2 : Theme.ink3 }
    }
    Rectangle {
        visible: !r.last
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: lay.anchors.leftMargin + (r.iconName !== "" ? 34 + lay.spacing : 0); rightMargin: Theme.s4 }
        height: 1
        color: Theme.line
    }
}
