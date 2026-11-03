import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../components"

// Screenshot Capture tile (demo video 0:27): three round buttons for window,
// region and full-screen capture, tinted blue, green and purple. Uses spectacle.
Tile {
    id: tile

    readonly property real inner: height - padding * 2
    readonly property var actions: [
        { icon: "window", flag: "-a", color: "#0A84FF", tip: i18n("Active window") },
        { icon: "transform-crop", flag: "-r", color: "#30D158", tip: i18n("Region") },
        { icon: "view-fullscreen", flag: "-f", color: "#BF5AF2", tip: i18n("Full screen") }
    ]

    implicitWidth: row.implicitWidth + padding * 2

    ShellRunner {
        id: shell
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: tile.inner * 0.16

        Repeater {
            model: tile.actions

            QQC2.AbstractButton {
                id: button
                required property var modelData
                Layout.preferredWidth: tile.inner * 0.72
                Layout.preferredHeight: tile.inner * 0.72
                scale: pressed ? 0.92 : 1
                onClicked: shell.run("spectacle -b " + modelData.flag)

                QQC2.ToolTip.text: modelData.tip
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: 600

                Behavior on scale {
                    NumberAnimation { duration: 80 }
                }

                background: Rectangle {
                    radius: width / 2
                    color: Qt.alpha(button.modelData.color, button.hovered ? 0.3 : 0.2)
                }
                contentItem: Kirigami.Icon {
                    source: button.modelData.icon
                    isMask: true
                    color: button.modelData.color
                    implicitWidth: tile.inner * 0.36
                    implicitHeight: tile.inner * 0.36
                }
            }
        }
    }
}
