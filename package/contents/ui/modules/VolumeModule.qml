import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Volume slider tile (demo video 0:15, "Brightness"/"Speakers" style): icon and
// label with the percent on the right, a dark pill slider with a white knob below.
// Reads and sets the default PipeWire sink through wpctl.
Tile {
    id: tile

    property bool active: true
    property real percent: 0
    property bool muted: false
    property string device: ""

    readonly property real inner: height - padding * 2
    readonly property string sink: "@DEFAULT_AUDIO_SINK@"

    implicitWidth: Math.round(height * 3.6)

    ShellRunner {
        id: shell
        onFinished: (cmd, out) => {
            if (cmd.indexOf("inspect") >= 0) {
                const n = out.match(/"([^"]+)"/);
                tile.device = n ? n[1] : "";
                return;
            }
            if (cmd.indexOf("get-volume") < 0)
                return;
            const m = out.match(/Volume:\s*([0-9.]+)/);
            if (m === null)
                return;
            tile.muted = out.indexOf("[MUTED]") >= 0;
            if (!slider.pressed)
                tile.percent = Math.round(parseFloat(m[1]) * 100);
        }
    }

    Timer {
        interval: 3000
        repeat: true
        triggeredOnStart: true
        running: tile.active && tile.visible
        onTriggered: {
            shell.run("wpctl get-volume " + tile.sink);
            shell.run("wpctl inspect " + tile.sink + " 2>/dev/null | grep -m1 node.nick");
        }
    }

    // Send at most one wpctl call per 80 ms while dragging.
    Timer {
        id: apply
        interval: 80
        onTriggered: shell.run("wpctl set-volume " + tile.sink + " " + Math.round(slider.value) + "%")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: tile.padding
        anchors.leftMargin: tile.padding * 1.3
        anchors.rightMargin: tile.padding * 1.3
        spacing: tile.inner * 0.08

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.preferredWidth: tile.inner * 0.3
                Layout.preferredHeight: tile.inner * 0.3
                source: tile.muted || tile.percent === 0 ? "audio-volume-muted-symbolic"
                      : tile.percent < 50 ? "audio-volume-low-symbolic" : "audio-volume-high-symbolic"
                isMask: true
                color: Kirigami.Theme.textColor
            }
            PlasmaComponents.Label {
                text: tile.device !== "" ? tile.device : i18n("Speakers")
                font.pixelSize: Math.max(8, tile.inner * 0.28)
                font.weight: Font.DemiBold
            }
            Item {
                Layout.fillWidth: true
            }
            PlasmaComponents.Label {
                text: tile.muted ? i18n("Muted") : Math.round(slider.value) + "%"
                font.pixelSize: Math.max(7, tile.inner * 0.22)
                font.features: { "tnum": 1 }
                opacity: 0.6
            }
        }

        QQC2.Slider {
            id: slider
            Layout.fillWidth: true
            Layout.preferredHeight: tile.inner * 0.34
            from: 0
            to: 100
            stepSize: 1
            value: tile.percent
            onMoved: {
                tile.percent = value;
                tile.muted = false;
                apply.restart();
            }

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: slider.availableHeight
                radius: height / 2
                color: Qt.alpha(Kirigami.Theme.textColor, 0.15)

                Rectangle {
                    width: Math.max(parent.height, slider.visualPosition * parent.width)
                    height: parent.height
                    radius: height / 2
                    color: Kirigami.Theme.highlightColor
                    opacity: tile.muted ? 0.4 : 1
                }
            }
            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableHeight * 0.86
                height: width
                radius: width / 2
                color: "white"
                border.width: 1
                border.color: Qt.alpha("black", 0.15)
            }
        }
    }
}
