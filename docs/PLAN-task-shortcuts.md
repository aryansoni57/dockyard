# Plan: Meta+1 to Meta+9 for dock apps

Goal: Meta+N opens or switches to the Nth app icon in the Apps module, like the Plasma Task Manager does.

## Mechanism

On Plasma 6.8 the stock Task Manager registers Meta+1..9 itself, from its C++ backend (`org.kde.plasma.taskmanager.so`, KGlobalAccel, component `plasmashell`, actions `activate task manager entry N`). plasmashell does not pass these keys to other applets. QML has no API to register a global shortcut.

So a KWin script owns the keys and relays each press:

1. `kwin-script/contents/code/main.js` calls `registerShortcut` for "Dockyard App 1".."9" (Meta+1..9).
2. On a press it calls `org.kde.PlasmaShell.evaluateScript` over D-Bus. The script finds every `dev.aryan.dock` widget in panels and desktops and writes `taskShortcut = "<index>:<time>"` (General group). The time makes each press a change.
3. `main.qml` watches `Plasmoid.configuration.taskShortcut` and calls `activateTaskAtIndex(index)`.

Rejected:
- `X-Plasma-Provides: org.kde.plasma.multitasking` plus `activateTaskAtIndex` on the root item. That was the Plasma 5 path. Tested on 6.8: never called.
- `Plasmoid.globalShortcut`: one shortcut per applet, already used for the launcher.
- Importing the Task Manager's `Backend` type: its QML module loads only with that applet's plugin.

## activateTaskAtIndex

Works on the `TasksModel` in `tasksLoader`, not the view. Index order matches the icons left to right.

- Apps module off, no model, or index out of range: do nothing.
- Launcher: `requestNewInstance`.
- One window: active then `requestToggleMinimized`, else `requestActivate`.
- Group: activate the child after the active one, wrapping; none active means child 0.

## Install

`install.sh` installs or upgrades the KWin script, sets `dockyardshortcutsEnabled=true` in `kwinrc`, and calls `KWin reconfigure`. It also clears Meta+1..9 from the plasmashell Task Manager entries with `KGlobalAccel.setForeignShortcutKeys`, so only one action owns each key. If a stock Task Manager is added later, its keys must be set again in System Settings.

## Test

1. `./install.sh`, then `systemctl --user restart plasma-plasmashell`.
2. Apps module on, with 3 or more pinned apps.
3. Meta+1 on a launcher that is not running: it opens.
4. Meta+1 again: it focuses. Again while focused: it minimises.
5. Two windows of one app: Meta+N cycles between them.
6. Meta+9 with fewer than 9 icons: nothing happens.
7. Reorder icons by drag: the numbers follow the new order.
