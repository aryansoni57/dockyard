import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"
import "../components/accent"

// Top CPU / Top RAM tile (website "Top CPU", "Top RAM"): the three hungriest
// processes with their share. mode is "cpu" or "ram". CPU comes from a second
// top frame, since the first one only shows each process's average since launch.
Tile {
    id: tile

    property bool active: true
    property string mode: "cpu"
    property var rows: []

    readonly property real inner: height - padding * 2
    readonly property bool isCpu: mode === "cpu"

    implicitWidth: Math.round(height * 2.5)

    ShellRunner {
        id: shell
        onFinished: (cmd, out) => {
            const list = [];
            for (const line of out.split("\n")) {
                const t = line.trim();
                const cut = t.lastIndexOf(" ");
                if (cut <= 0)
                    continue;
                list.push({ name: t.slice(0, cut).trim(), value: parseFloat(t.slice(cut + 1)) || 0 });
            }
            tile.rows = list.slice(0, 3);
        }
    }

    Timer {
        interval: 4000
        repeat: true
        triggeredOnStart: true
        running: tile.active && tile.visible
        onTriggered: shell.run(tile.isCpu
            ? "top -b -n 2 -d 0.5 -o %CPU | awk '/^top -/{f++} f==2 && /^ *[0-9]+ /{print $12, $9}' | head -3"
            : "ps -eo comm:20,pmem --sort=-pmem --no-headers | head -3")
    }

    Column {
        anchors.fill: parent
        anchors.margins: tile.padding
        anchors.leftMargin: tile.padding * 1.3
        anchors.rightMargin: tile.padding * 1.3
        spacing: tile.inner * 0.05

        PlasmaComponents.Label {
            text: tile.isCpu ? i18n("Top CPU") : i18n("Top RAM")
            opacity: 0.7
            font.pixelSize: Math.max(7, tile.inner * 0.2)
            font.weight: Font.DemiBold
        }

        Repeater {
            model: tile.rows

            Item {
                required property var modelData
                width: parent.width
                height: tile.inner * 0.22

                PlasmaComponents.Label {
                    anchors.left: parent.left
                    anchors.right: pct.left
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.modelData.name
                    elide: Text.ElideRight
                    font.pixelSize: Math.max(7, tile.inner * 0.2)
                }
                PlasmaComponents.Label {
                    id: pct
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(parent.modelData.value) + "%"
                    color: parent.modelData.value >= 50 ? "#FF453A" : DockAccent.color
                    font.pixelSize: Math.max(7, tile.inner * 0.2)
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }
            }
        }
    }
}
