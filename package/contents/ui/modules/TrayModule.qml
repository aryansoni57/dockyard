import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.plasma.private.systemtray as SystemTray
import "../components"

// System tray tile: one glass tile with a row of StatusNotifier icons, the same
// ones Plasma's own tray shows. Left click activates an item, right click opens
// its menu, middle click is its secondary action. Items talk over D-Bus
// (org.kde.StatusNotifierItem) through busctl. Menus are read from the item's
// com.canonical.dbusmenu object and shown as a native menu, as Plasma's tray
// does; most apps ignore the ContextMenu call, which is only the fallback.
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

    // Menu state: the item it belongs to, and the objects built for it.
    property Item menuEntry: null
    property string menuService: ""
    property string menuPath: ""
    property var menuObjects: []

    function openMenu(entry) {
        const slash = entry.source.indexOf("/");
        if (slash < 0)
            return;
        const service = entry.source.slice(0, slash);
        const path = entry.source.slice(slash);
        menuEntry = entry;
        menuService = service;
        // Prints the menu path on the first line, then the layout as JSON.
        menuLoader.run("m=$(busctl --user get-property '" + service + "' '" + path
                       + "' org.kde.StatusNotifierItem Menu 2>/dev/null | cut -d'\"' -f2); echo \"$m\"; "
                       + "[ -n \"$m\" ] || exit 0; "
                       + "busctl --user call '" + service + "' \"$m\" com.canonical.dbusmenu AboutToShow i 0 >/dev/null 2>&1; "
                       + "busctl --user --json=short call '" + service + "' \"$m\" com.canonical.dbusmenu GetLayout iias -- 0 -1 0");
    }

    function menuEvent(id) {
        shell.run("busctl --user call '" + menuService + "' '" + menuPath + "' com.canonical.dbusmenu Event isvu "
                  + id + " clicked s '' 0 >/dev/null 2>&1");
    }

    // The menu opens away from the screen edge the dock sits on.
    function menuPlacement() {
        switch (Plasmoid.location) {
        case PlasmaCore.Types.TopEdge:
            return PlasmaExtras.Menu.BottomPosedLeftAlignedPopup;
        case PlasmaCore.Types.LeftEdge:
            return PlasmaExtras.Menu.RightPosedTopAlignedPopup;
        case PlasmaCore.Types.RightEdge:
            return PlasmaExtras.Menu.LeftPosedTopAlignedPopup;
        default:
            return PlasmaExtras.Menu.TopPosedLeftAlignedPopup;
        }
    }

    // Shows one level of a dbusmenu. Plasma's menu has no cascading submenus,
    // so a submenu entry swaps in its children, with a Back entry on top.
    function showNodes(children, parentChildren) {
        trayMenu.clearMenuItems();
        for (const o of menuObjects) {
            if (o && typeof o.destroy === "function")
                o.destroy();
        }
        menuObjects = [];
        const add = o => {
            menuObjects.push(o);
            trayMenu.addMenuItem(o);
        };
        if (parentChildren) {
            add(menuItem.createObject(tile, { text: i18n("Back"), icon: "go-previous", back: parentChildren }));
            add(menuItem.createObject(tile, { separator: true }));
        }
        for (const child of children) {
            const node = child.data;
            const props = node[1];
            const prop = (k, d) => props[k] !== undefined ? props[k].data : d;
            if (!prop("visible", true))
                continue;
            const label = String(prop("label", "")).replace(/__|_/g, m => m === "__" ? "_" : "");
            if (prop("type", "standard") === "separator") {
                add(menuItem.createObject(tile, { separator: true }));
            } else if (node[2].length > 0) {
                add(menuItem.createObject(tile, {
                    text: label + "  \u203A",
                    icon: prop("icon-name", ""),
                    enabled: prop("enabled", true),
                    sub: node[2],
                    up: children
                }));
            } else {
                const toggle = prop("toggle-type", "");
                add(menuItem.createObject(tile, {
                    text: label,
                    icon: prop("icon-name", ""),
                    enabled: prop("enabled", true),
                    checkable: toggle !== "",
                    checked: toggle !== "" && prop("toggle-state", 0) === 1,
                    itemId: node[0]
                }));
            }
        }
        trayMenu.visualParent = menuEntry;
        trayMenu.placement = menuPlacement();
        trayMenu.openRelative();
    }

    ShellRunner {
        id: menuLoader
        onFinished: (cmd, out) => {
            const entry = tile.menuEntry;
            if (!entry)
                return;
            const nl = out.indexOf("\n");
            const path = (nl < 0 ? out : out.slice(0, nl)).trim();
            let layout = null;
            try {
                layout = path !== "" && nl >= 0 ? JSON.parse(out.slice(nl + 1)).data[1] : null;
            } catch (e) {
                layout = null;
            }
            if (!layout || layout[2].length === 0) {
                // No dbusmenu: let the app show its own menu, if it has one.
                const p = entry.mapToGlobal(entry.width / 2, entry.height);
                tile.call(entry.source, "ContextMenu", p.x, p.y);
                return;
            }
            tile.menuPath = path;
            tile.showNodes(layout[2], null);
        }
    }

    PlasmaExtras.Menu {
        id: trayMenu
    }

    Component {
        id: menuItem
        PlasmaExtras.MenuItem {
            id: mi
            property int itemId: -1
            property var sub: null      // children to show when this entry is a submenu
            property var up: null       // the level this entry belongs to
            property var back: null     // set on the Back entry: the level to return to
            onClicked: {
                // Reopen on the next tick: the menu is still closing from this click.
                if (sub)
                    Qt.callLater(() => tile.showNodes(sub, up));
                else if (back)
                    Qt.callLater(() => tile.showNodes(back, null));
                else if (itemId >= 0)
                    tile.menuEvent(itemId);
            }
        }
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
                            tile.openMenu(entry);
                        else if (mouse.button === Qt.MiddleButton)
                            tile.call(entry.source, "SecondaryActivate", p.x, p.y);
                        else
                            tile.call(entry.source, "Activate", p.x, p.y);
                    }
                }

                PlasmaComponents.ToolTip {
                    visible: area.containsMouse && entry.name !== ""
                    text: entry.name
                    delay: Kirigami.Units.toolTipDelay
                }
            }
        }
    }
}
