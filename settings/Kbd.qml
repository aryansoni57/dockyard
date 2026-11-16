import QtQuick

// Keyboard hint, e.g. "Ctrl K".
Rectangle {
    id: k
    property string text
    implicitWidth: t.implicitWidth + 10
    implicitHeight: 20
    radius: 5
    color: "transparent"
    border.width: 1
    border.color: Theme.a(Theme.ink, Theme.dark ? 0.14 : 0.16)
    Text { id: t; anchors.centerIn: parent; text: k.text; color: Theme.ink3; font.pixelSize: Theme.fsMicro - 0.5; font.weight: Font.Medium }
}
