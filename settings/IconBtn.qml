import QtQuick
import QtQuick.Controls as QQC2

// Square ghost button holding one line icon, with a tooltip.
QQC2.AbstractButton {
    id: b
    property string iconName
    property string tip: ""
    property int box: 32
    property int glyph: 18
    property bool active: false
    property color tint: active ? Theme.accentInk : (hovered ? Theme.ink : Theme.ink2)
    implicitWidth: box
    implicitHeight: box
    focusPolicy: Qt.TabFocus
    Accessible.name: tip
    scale: b.down && Theme.motion ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: 80 } }
    contentItem: Item { Ico { anchors.centerIn: parent; name: b.iconName; size: b.glyph; color: b.tint; opacity: b.enabled ? 1 : 0.45 } }
    background: Rectangle {
        radius: Theme.rCtl
        color: b.active ? Theme.accentSoft : (b.down ? Theme.press : (b.hovered ? Theme.hover : "transparent"))
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        FocusRing { shown: b.visualFocus; round: Theme.rCtl }
    }
    Tip { text: b.tip; shown: b.hovered }
}
