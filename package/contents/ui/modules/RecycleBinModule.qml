import QtQuick
import org.kde.kirigami as Kirigami
import "../components"

// Recycle Bin tile (demo video 0:21): a trash icon with a red count badge.
// Counts entries in the freedesktop trash; click opens it in the file manager.
Tile {
    id: tile

    property bool active: true
    property int count: 0

    readonly property real inner: height - padding * 2

    implicitWidth: height

    ShellRunner {
        id: shell
        onFinished: (cmd, out) => {
            if (cmd.indexOf("Trash/files") >= 0)
                tile.count = parseInt(out) || 0;
        }
    }

    Timer {
        interval: 10000
        repeat: true
        triggeredOnStart: true
        running: tile.active && tile.visible
        onTriggered: shell.run("ls -A \"${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files\" 2>/dev/null | wc -l")
    }

    onClicked: shell.run("xdg-open trash:/")

    Kirigami.Icon {
        anchors.centerIn: parent
        width: tile.inner * 0.78
        height: width
        source: tile.count > 0 ? "user-trash-full" : "user-trash"
    }

    Rectangle {
        visible: tile.count > 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: tile.padding * 0.5
        width: Math.max(height, badgeText.implicitWidth + height * 0.5)
        height: tile.inner * 0.42
        radius: height / 2
        color: "#FF3B30"

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: tile.count > 99 ? "99+" : tile.count
            color: "white"
            font.pixelSize: parent.height * 0.62
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }
    }
}
