import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Microphone tile (website "Microphone"): two round buttons, one mutes the default
// microphone and one mutes the default speakers. Muted turns the button red.
// Reads and sets both through wpctl.
Tile {
    id: tile

    property bool active: true
    property bool micMuted: false
    property bool speakerMuted: false

    readonly property real inner: height - padding * 2

    implicitWidth: row.implicitWidth + padding * 2

    ShellRunner {
        id: shell
        onFinished: (cmd, out) => {
            if (cmd.indexOf("get-volume") < 0)
                return;
            const muted = out.indexOf("[MUTED]") >= 0;
            if (cmd.indexOf("SOURCE") >= 0)
                tile.micMuted = muted;
            else
                tile.speakerMuted = muted;
        }
    }

    function refresh() {
        shell.run("wpctl get-volume @DEFAULT_AUDIO_SOURCE@");
        shell.run("wpctl get-volume @DEFAULT_AUDIO_SINK@");
    }

    Timer {
        interval: 3000
        repeat: true
        triggeredOnStart: true
        running: tile.active && tile.visible
        onTriggered: tile.refresh()
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: tile.inner * 0.16

        Repeater {
            model: [
                { id: "SOURCE", icon: "microphone", off: "microphone-off", tip: i18n("Microphone") },
                { id: "SINK", icon: "speaker", off: "speaker-muted", tip: i18n("Speakers") }
            ]

            QQC2.AbstractButton {
                id: button
                required property var modelData
                readonly property bool muted: modelData.id === "SOURCE" ? tile.micMuted : tile.speakerMuted
                Layout.preferredWidth: tile.inner * 0.72
                Layout.preferredHeight: tile.inner * 0.72
                scale: pressed ? 0.92 : 1
                onClicked: {
                    shell.run("wpctl set-mute @DEFAULT_AUDIO_" + modelData.id + "@ toggle");
                    tile.refresh();
                }

                PlasmaComponents.ToolTip {
                    visible: parent.hovered
                    text: button.modelData.tip
                    delay: 600
                }
                Behavior on scale {
                    NumberAnimation { duration: 80 }
                }

                background: Rectangle {
                    radius: width / 2
                    color: button.muted ? Qt.alpha("#FF453A", button.hovered ? 0.35 : 0.25)
                                        : Qt.alpha(Kirigami.Theme.textColor, button.hovered ? 0.2 : 0.12)
                }
                contentItem: Kirigami.Icon {
                    source: Qt.resolvedUrl("../../icons/" + (button.muted ? button.modelData.off : button.modelData.icon) + ".svg")
                    isMask: true
                    color: button.muted ? "#FF453A" : Kirigami.Theme.textColor
                    implicitWidth: tile.inner * 0.36
                    implicitHeight: tile.inner * 0.36
                }
            }
        }
    }
}
