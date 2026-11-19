import QtQuick
import org.kde.kirigami as Kirigami
import "../components"

// Show Desktop tile (website "Show Desktop"): hides every window, click again to
// bring them back. Triggers KWin's own Show Desktop shortcut action.
Tile {
    id: tile

    readonly property real inner: height - padding * 2

    implicitWidth: height

    ShellRunner {
        id: shell
    }

    onClicked: shell.run("qdbus6 org.kde.kglobalaccel /component/kwin invokeShortcut 'Show Desktop'")

    Kirigami.Icon {
        anchors.centerIn: parent
        width: Math.round(tile.inner * 0.6)
        height: width
        source: Qt.resolvedUrl("../../icons/desktop-icons.svg")
        isMask: true
        color: Kirigami.Theme.textColor
        opacity: 0.9
    }
}
