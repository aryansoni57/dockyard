import QtQuick

// 2 px accent ring drawn 3 px outside its parent, for keyboard focus.
Rectangle {
    property bool shown: false
    property real round: 10
    anchors.fill: parent
    anchors.margins: -3
    radius: round + 3
    color: "transparent"
    border.width: 2
    border.color: Theme.accentInk
    visible: shown
    z: 10
}
