import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Language tile (website "Language"): the active keyboard layout as a big
// three-letter code. Click switches to the next layout. Uses KDE's keyboard D-Bus.
Tile {
    id: tile

    property bool active: true
    property var layouts: [] // [{ code, name }]
    property int current: 0

    readonly property real inner: height - padding * 2
    readonly property string code: layouts.length > current ? layouts[current].code : "--"

    implicitWidth: height

    ShellRunner {
        id: shell
        onFinished: (cmd, out) => {
            if (cmd.indexOf("getLayoutsList") >= 0) {
                const list = [];
                const re = /\('([^']*)',\s*'([^']*)',\s*'([^']*)'\)/g;
                let m;
                while ((m = re.exec(out)) !== null)
                    list.push({ code: m[1], name: m[2] });
                tile.layouts = list;
            } else if (cmd.indexOf("getLayout ") >= 0 || cmd.endsWith("getLayout")) {
                const n = out.match(/uint32\s+(\d+)/);
                if (n)
                    tile.current = parseInt(n[1]);
            }
        }
    }

    readonly property string bus: "gdbus call --session --dest org.kde.keyboard --object-path /Layouts --method org.kde.KeyboardLayouts."

    function refresh() {
        shell.run(bus + "getLayoutsList");
        shell.run(bus + "getLayout");
    }

    Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: tile.active && tile.visible
        onTriggered: tile.refresh()
    }

    onClicked: {
        if (layouts.length < 2)
            return;
        const next = (current + 1) % layouts.length;
        current = next;
        shell.run(bus + "setLayout " + next);
    }

    PlasmaComponents.Label {
        anchors.centerIn: parent
        text: tile.code.toUpperCase().slice(0, 3)
        font.pixelSize: Math.max(10, tile.inner * 0.42)
        font.weight: Font.Bold
    }
}
