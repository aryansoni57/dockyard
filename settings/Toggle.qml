import QtQuick
import QtQuick.Controls as QQC2

// On/off switch. The knob carries a tiny check when on.
QQC2.Switch {
    id: t
    focusPolicy: Qt.TabFocus
    implicitWidth: 42
    implicitHeight: 24
    padding: 0
    spacing: 0
    indicator: Rectangle {
        width: 42; height: 24; radius: 12
        color: t.checked ? Theme.accent : Theme.track
        opacity: t.enabled ? 1 : 0.45
        Behavior on color { ColorAnimation { duration: Theme.dur } }
        Rectangle {
            width: 18; height: 18; radius: 9; y: 3
            x: t.checked ? 21 : 3
            color: "#ffffff"
            Behavior on x { NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic } }
            Ico { anchors.centerIn: parent; name: "check"; size: 12; color: Theme.accent; opacity: t.checked ? 1 : 0; Behavior on opacity { NumberAnimation { duration: Theme.fast } } }
        }
        FocusRing { shown: t.visualFocus; round: 12 }
    }
    contentItem: Item {}
}
