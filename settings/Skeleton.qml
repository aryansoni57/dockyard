import QtQuick

// Placeholder block with a soft sweep, shown while something loads.
Rectangle {
    id: k
    radius: 8
    color: Theme.a(Theme.ink, Theme.dark ? 0.06 : 0.055)
    clip: true
    Rectangle {
        width: k.width * 0.5
        height: k.height
        visible: Theme.motion
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.a(Theme.ink, 0) }
            GradientStop { position: 0.5; color: Theme.a(Theme.ink, Theme.dark ? 0.06 : 0.05) }
            GradientStop { position: 1; color: Theme.a(Theme.ink, 0) }
        }
        NumberAnimation on x { from: -k.width * 0.5; to: k.width; duration: 1300; loops: Animation.Infinite; running: Theme.motion && k.visible }
    }
}
