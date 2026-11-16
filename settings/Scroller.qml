import QtQuick
import QtQuick.Controls as QQC2

// Thin overlay scrollbar that shows while scrolling or hovered.
QQC2.ScrollBar {
    id: sb
    padding: 3
    minimumSize: 0.08
    contentItem: Rectangle {
        implicitWidth: sb.hovered || sb.pressed ? 8 : 5
        implicitHeight: 5
        radius: width / 2
        color: sb.pressed ? Theme.ink3 : Theme.ink4
        opacity: sb.policy === QQC2.ScrollBar.AlwaysOn || (sb.active && sb.size < 1) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.slow } }
        Behavior on implicitWidth { NumberAnimation { duration: Theme.fast } }
    }
    background: Item {}
}
