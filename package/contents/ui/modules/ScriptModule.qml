import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Script tile: runs the user's shell command on a timer. The first line of its
// stdout shows big, the second small, and the whole output is the tooltip.
Tile {
    id: root

    property bool active
    property string command
    property string label
    property string iconName
    property int intervalSeconds: 60

    property string output
    property string errorOutput
    property int exitCode: 0
    property bool busy: false

    // Timed out so a hung command cannot hold the tile; exit code 124 means it did.
    readonly property string wrapped: command.trim() === ""
        ? "" : "timeout -k 2 30 sh -c '" + command.trim().replace(/'/g, "'\\''") + "'"
    readonly property var lines: output.split("\n")
    readonly property bool failed: exitCode !== 0
    readonly property real inner: height - padding * 2

    function refresh() {
        if (!active || wrapped === "" || busy)
            return;
        busy = true;
        shell.run(wrapped);
    }

    onWrappedChanged: {
        output = "";
        errorOutput = "";
        exitCode = 0;
        busy = false;
        refresh();
    }

    hoverName: failed ? (errorOutput || output) : (output || label)
    implicitWidth: Math.round(height * 2.9)

    ShellRunner {
        id: shell
        onFinished: (cmd, out, code, err) => {
            // A reply for a command the user has since replaced.
            if (cmd !== root.wrapped)
                return;
            root.busy = false;
            root.output = out.trim();
            root.errorOutput = err.trim();
            root.exitCode = code;
        }
    }

    Timer {
        interval: Math.max(5, root.intervalSeconds) * 1000
        running: root.active && root.wrapped !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Column {
        anchors.fill: parent
        anchors.margins: root.padding
        anchors.leftMargin: root.padding * 1.3
        anchors.rightMargin: root.padding * 1.3
        spacing: root.inner * 0.02

        Item {
            width: parent.width
            height: root.inner * 0.3

            Kirigami.Icon {
                id: icon
                width: parent.height
                height: width
                source: root.failed ? "dialog-warning" : (root.iconName || "utilities-terminal")
            }
            PlasmaComponents.Label {
                anchors.left: icon.right
                anchors.leftMargin: root.inner * 0.08
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.label || i18n("Script")
                elide: Text.ElideRight
                opacity: 0.7
                font.pixelSize: Math.max(7, root.inner * 0.22)
            }
        }

        PlasmaComponents.Label {
            width: parent.width
            text: root.wrapped === "" ? i18n("No command")
                : root.failed ? (root.exitCode === 124 ? i18n("Timed out") : i18n("Error"))
                : root.output !== "" ? root.lines[0]
                : root.busy ? "…" : i18n("No output")
            elide: Text.ElideRight
            font.pixelSize: Math.max(10, root.inner * 0.3)
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }

        PlasmaComponents.Label {
            width: parent.width
            text: root.failed ? i18n("Exit code %1", root.exitCode) : (root.lines[1] ?? "")
            elide: Text.ElideRight
            opacity: 0.6
            font.pixelSize: Math.max(7, root.inner * 0.18)
        }
    }
}
