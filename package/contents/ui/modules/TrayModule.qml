import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.systemtray as SystemTray
import "../components"

// System tray tile: one glass tile with a row of StatusNotifier icons, the same
// ones Plasma's own tray shows. Left click activates an item, right click opens
// its menu, middle click is its secondary action. Items talk over D-Bus
// (org.kde.StatusNotifierItem) through busctl.
Tile {
    id: tile

    property bool active: true

    readonly property real inner: height - padding * 2
    readonly property real iconSize: Math.round(inner * 0.5)

    // Passive items (effectiveStatus 0) are hidden, as in Plasma's tray.
    implicitWidth: Math.max(Math.round(height * 1.2), row.implicitWidth + padding * 2)

    ShellRunner {
        id: shell
    }

    // "org.kde.StatusNotifierItem-123-1/StatusNotifierItem" -> service and object path.
    function call(source, method, x, y) {
        const slash = source.indexOf("/");
        if (slash < 0)
            return;
        const service = source.slice(0, slash);
        const path = source.slice(slash);
        shell.run("busctl --user call '" + service + "' '" + path + "' org.kde.StatusNotifierItem "
                  + method + " ii " + Math.round(x) + " " + Math.round(y) + " >/dev/null 2>&1");
    }

    SystemTray.StatusNotifierModel {
        id: trayModel
    }

    Row {
        id: row
        anchors.centerIn: parent
        height: tile.inner
        spacing: tile.inner * 0.12

        Repeater {
            model: tile.active ? trayModel : null

            delegate: Item {
                id: entry
                required property var model
                readonly property string source: model.DataEngineSource ?? ""
                readonly property bool shown: model.canRender && model.effectiveStatus > 0
                readonly property string name: model.ToolTipTitle || model.Title || model.Id || ""

                visible: shown
                width: shown ? tile.iconSize + tile.inner * 0.1 : 0
                height: tile.inner

                Rectangle {
                    anchors.centerIn: parent
                    width: tile.iconSize + tile.inner * 0.12
                    height: width
                    radius: width * 0.3
                    color: Qt.alpha(Kirigami.Theme.textColor, area.pressed ? 0.18 : area.containsMouse ? 0.1 : 0)
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: tile.iconSize
                    height: tile.iconSize
                    source: entry.model.effectiveStatus === 2 && entry.model.AttentionIconName
                        ? entry.model.AttentionIconName
                        : (entry.model.IconName || entry.model.Icon)
                    fallback: "application-x-executable"
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                        const p = entry.mapToGlobal(entry.width / 2, entry.height);
                        if (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && entry.model.ItemIsMenu))
                            tile.call(entry.source, "ContextMenu", p.x, p.y);
                        else if (mouse.button === Qt.MiddleButton)
                            tile.call(entry.source, "SecondaryActivate", p.x, p.y);
                        else
                            tile.call(entry.source, "Activate", p.x, p.y);
                    }
                }

                QQC2.ToolTip {
                    visible: area.containsMouse && entry.name !== ""
                    text: entry.name
                    delay: Kirigami.Units.toolTipDelay
                }
            }
        }
    }
}
