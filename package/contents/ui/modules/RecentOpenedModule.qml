import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"
import "../components/accent"

// Recently Opened tile (website "Recently Opened"): the last three files or folders
// you opened in any app, from KDE's activity history. Click a row to open it.
Tile {
    id: tile

    property bool active: true
    property var items: [] // [{ title, url }]

    readonly property real inner: height - padding * 2

    implicitWidth: Math.round(height * 3)

    ShellRunner {
        id: shell
        onFinished: (cmd, out) => {
            if (cmd.indexOf("recent-opened") < 0)
                return;
            const list = [];
            for (const line of out.split("\n")) {
                const t = line.indexOf("\t");
                if (t > 0)
                    list.push({ title: line.slice(0, t), url: line.slice(t + 1) });
            }
            tile.items = list;
        }
    }
    ShellRunner {
        id: opener
    }

    Timer {
        interval: 15000
        repeat: true
        triggeredOnStart: true
        running: tile.active && tile.visible
        onTriggered: shell.run("sh '" + Qt.resolvedUrl("../../scripts/recent-opened.sh").toString().replace("file://", "") + "' 3")
    }

    Column {
        anchors.fill: parent
        anchors.margins: tile.padding
        anchors.leftMargin: tile.padding * 1.3
        anchors.rightMargin: tile.padding * 1.3
        spacing: tile.inner * 0.03

        PlasmaComponents.Label {
            text: i18n("Recently opened")
            opacity: 0.7
            font.pixelSize: Math.max(7, tile.inner * 0.2)
            font.weight: Font.DemiBold
        }

        Repeater {
            model: tile.items

            QQC2.AbstractButton {
                id: row
                required property var modelData
                width: parent.width
                height: tile.inner * 0.24
                onClicked: opener.run("xdg-open '" + modelData.url.replace(/'/g, "'\\''") + "'")

                background: Rectangle {
                    radius: height / 3
                    color: Qt.alpha(Kirigami.Theme.textColor, row.hovered ? 0.12 : 0)
                }
                contentItem: PlasmaComponents.Label {
                    text: row.modelData.title
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Math.max(7, tile.inner * 0.2)
                }
            }
        }
    }
}
