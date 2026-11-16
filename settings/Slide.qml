import QtQuick
import QtQuick.Controls as QQC2

// Slider: 6 px track, accent fill, white knob that grows while dragged.
QQC2.Slider {
    id: s
    implicitWidth: 220
    implicitHeight: 28
    padding: 0
    leftPadding: 9
    rightPadding: 9
    focusPolicy: Qt.TabFocus
    background: Rectangle {
        x: s.leftPadding; y: s.topPadding + s.availableHeight / 2 - 3
        width: s.availableWidth; height: 6; radius: 3
        color: Theme.track
        opacity: s.enabled ? 1 : 0.45
        Rectangle { width: Math.max(6, s.visualPosition * parent.width); height: parent.height; radius: 3; color: Theme.accent }
    }
    handle: Rectangle {
        x: s.leftPadding + s.visualPosition * s.availableWidth - width / 2
        y: s.topPadding + s.availableHeight / 2 - height / 2
        width: 18; height: 18; radius: 9
        color: "#ffffff"
        border.width: 1
        border.color: Theme.dark ? "transparent" : Theme.a("#000000", 0.12)
        scale: s.pressed && Theme.motion ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: Theme.fast } }
        Rectangle { anchors.centerIn: parent; width: 6; height: 6; radius: 3; color: Theme.accent; opacity: s.pressed ? 1 : 0; Behavior on opacity { NumberAnimation { duration: Theme.fast } } }
        FocusRing { shown: s.visualFocus; round: 9 }
    }
}
