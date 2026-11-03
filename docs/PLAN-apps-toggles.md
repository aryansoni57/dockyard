# Plan: Apps and Quick Toggles

Planned by Opus. Verified on this machine: Plasma 6.8.2, Wayland. Rules: `docs/STYLE.md`, architecture in `docs/PLAN.md`.

## Mechanisms

- Apps: `org.kde.taskmanager` `TasksModel` (props `launcherList`, `groupMode`, `sortMode`, `separateLaunchers`, `launchInPlace`, `hideActivatedLaunchers`, `filter*`; methods `makeModelIndex`, `requestNewInstance`, `requestActivate`; roles `AppName`, `IsLauncher`, `HasLauncher`, `decoration`, `display`). Created in `main.qml` inside a `Loader` with `active: root.cfg.showApps`.
- Toggles: `components/ToggleSource.qml`, state and actions, created once in `main.qml`. The module is a dumb view.

| Toggle | Read | Change |
| --- | --- | --- |
| Wi-Fi | poll `nmcli radio wifi` | `nmcli radio wifi on` / `off` |
| Bluetooth | poll `bluetoothctl show \| grep -m1 Powered` | on: `rfkill unblock bluetooth; sleep 1; bluetoothctl power on`; off: `bluetoothctl power off` |
| Mute | poll `wpctl get-volume @DEFAULT_AUDIO_SINK@`, contains `[MUTED]` | `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` |
| Do Not Disturb | `NotificationManager.Settings { live: true }` (push) | set `notificationsInhibitedUntil`, then `save()` |
| Night Light | KWin `enabled` property via poll; on = available and not `NightLightInhibitor.inhibited` | `NightLightInhibitor.toggleInhibition()` |

Rejected: D-Bus `Inhibit` from one-shot `busctl` (released when the call ends); `kwriteconfig6` for Night Light (changes user settings permanently).

## Config keys (`package/contents/config/main.xml`, General group)

```xml
<entry name="showApps" type="Bool"><default>false</default></entry>
<entry name="appLaunchers" type="String">
    <default>preferred://browser,applications:org.kde.dolphin.desktop,applications:org.kde.konsole.desktop,applications:systemsettings.desktop</default>
</entry>
<entry name="showToggles" type="Bool"><default>false</default></entry>
<entry name="toggleItems" type="String"><default>wifi,bluetooth,dnd,nightlight,mute</default></entry>
```

`String`, not `StringList`, so a `TextField` alias works (same as `worldZones`).

## Set A: `package/contents/ui/modules/AppsModule.qml` (new)

- Imports: `QtQuick`, `QtQuick.Controls as QQC2`, `org.kde.kirigami as Kirigami`. No `org.kde.taskmanager`, no `org.kde.plasma.plasmoid`.
- Root `Item { id: apps }`, NOT `Tile` (STYLE.md: app icons sit loose, no tile). Comment that.
- `property var tasks: null`; `readonly property real iconSize: Math.round(height * 0.72)`; `implicitWidth: row.implicitWidth`.
- `Row { id: row; anchors.verticalCenter: parent.verticalCenter; spacing: Kirigami.Units.smallSpacing }` containing `Repeater { model: apps.tasks }`. Use `Row`, not `RowLayout` (invisible delegates are skipped).
- Delegate `Item`: `required property int index`, `required property var model` (read roles as `model.IsLauncher`; roles cannot be required properties). `visible: model.IsLauncher || model.HasLauncher`, `width: apps.iconSize`, `height: apps.height`.
- `Kirigami.Icon { anchors.centerIn: parent; width/height: apps.iconSize; source: model.decoration }`, `scale: tap.pressed ? 0.94 : 1` with 80 ms `Behavior`, faint rounded `Rectangle` behind at `Qt.alpha(Kirigami.Theme.textColor, 0.08)` while hovered.
- Running dot: `Rectangle { width: 4; height: 4; radius: 2; color: Kirigami.Theme.highlightColor; anchors.horizontalCenter: parent.horizontalCenter; y: Math.round(parent.height - (parent.height - apps.iconSize) / 4 - 2); visible: !model.IsLauncher }`.
- `HoverHandler { id: hover }`, `TapHandler { id: tap; acceptedButtons: Qt.LeftButton | Qt.MiddleButton; onTapped: (eventPoint, button) => { const idx = apps.tasks.makeModelIndex(index); if (button === Qt.MiddleButton || model.IsLauncher) apps.tasks.requestNewInstance(idx); else apps.tasks.requestActivate(idx); } }`.
- Tooltip: `QQC2.ToolTip.visible: hover.hovered`, `.text: model.AppName || model.display || ""`, `.delay: Kirigami.Units.toolTipDelay`.
- Accept: `/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml <file>` no syntax errors (warnings about missing imports are fine); `grep -c 'org.kde.plasma.plasmoid'` returns 0; no `Tile` root.

## Set B: `package/contents/ui/components/ToggleSource.qml` (new)

- Imports: `QtQuick`, `org.kde.plasma.plasma5support as Plasma5Support`, `org.kde.notificationmanager as NotificationManager`, `org.kde.plasma.private.brightnesscontrolplugin as Brightness`. Same style as `components/WeatherSource.qml`; executable pattern as in `modules/TimerModule.qml`.
- Root `Item { id: src }`; `property bool active: false`; `property var keys: []`.
- State bools (default false): `wifiAvailable, wifiOn, btAvailable, btOn, muteAvailable, muted, nightAvailable`; `property date clock: new Date()`.
- Exact poll command:
  ```qml
  readonly property string pollCmd: "echo wifi=$(nmcli radio wifi 2>/dev/null); echo bt=$(bluetoothctl show 2>/dev/null | grep -m1 Powered); echo vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null); echo night=$(busctl --user get-property org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight enabled 2>/dev/null)"
  ```
  Expected output: `wifi=enabled`, `bt= Powered: yes`, `vol=Volume: 0.35`, `night=b true`.
- `parse(out)`: per line, split at first `=`, trim value `v`: wifi: `wifiAvailable = v !== ""`, `wifiOn = v === "enabled"`; bt: `btAvailable = v !== ""`, `btOn = v.indexOf("yes") >= 0`; vol: `muteAvailable = v !== ""`, `muted = v.indexOf("[MUTED]") >= 0`; night: `nightAvailable = v.indexOf("true") >= 0`. End: `clock = new Date()`.
- ```qml
  Plasma5Support.DataSource { id: exec; engine: "executable"; connectedSources: []
      onNewData: (sourceName, data) => { disconnectSource(sourceName); if (sourceName === src.pollCmd) src.parse(data["stdout"] || ""); } }
  function run(cmd) { exec.disconnectSource(cmd); exec.connectSource(cmd); }
  ```
- Poll `Timer { interval: 5000; repeat: true; triggeredOnStart: true; running: src.active; onTriggered: src.run(src.pollCmd) }`; one-shot `Timer { id: refresh }` plus `function schedulePoll(ms) { refresh.interval = ms; refresh.restart(); }` that runs `pollCmd`.
- DND: `NotificationManager.Settings { id: notif; live: src.active }`; `readonly property bool dndOn: active && ((notif.notificationsInhibitedUntil > clock) || notif.notificationsInhibitedByApplication)`.
- Night: `readonly property bool nightOn: active && nightAvailable && !Brightness.NightLightInhibitor.inhibited` (only reference the singleton behind `active`).
- `toggle(key)`: `wifi`: `run("nmcli radio wifi " + (wifiOn ? "off" : "on")); wifiOn = !wifiOn; schedulePoll(800)`. `bluetooth`: `run(btOn ? "bluetoothctl power off" : "rfkill unblock bluetooth; sleep 1; bluetoothctl power on"); btOn = !btOn; schedulePoll(1500)`. `mute`: `run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"); muted = !muted; schedulePoll(800)`. `dnd`: if on: `notif.notificationsInhibitedUntil = undefined; notif.revokeApplicationInhibitions();` else `const d = new Date(); d.setFullYear(d.getFullYear() + 1); notif.notificationsInhibitedUntil = d;`; then `notif.save(); clock = new Date();`. `nightlight`: `if (nightAvailable) Brightness.NightLightInhibitor.toggleInhibition();`.
- Output: `readonly property var items: keys.map(k => itemFor(k)).filter(i => i !== null)`; `itemFor(k)` returns `{ key, label, icon, on, available }` or `null`:

| key | label | icon on / off | on | available |
| --- | --- | --- | --- | --- |
| `wifi` | Wi-Fi | `network-wireless-symbolic` / `network-wireless-disconnected-symbolic` | `wifiOn` | `wifiAvailable` |
| `bluetooth` | Bluetooth | `network-bluetooth-symbolic` / `network-bluetooth-inactive-symbolic` | `btOn` | `btAvailable` |
| `dnd` | Do Not Disturb | `notifications-disabled-symbolic` / `notifications-symbolic` | `dndOn` | `active` |
| `nightlight` | Night Light | `redshift-status-on-symbolic` / `redshift-status-off-symbolic` | `nightOn` | `nightAvailable` |
| `mute` | Mute | `audio-volume-muted-symbolic` / `audio-volume-high-symbolic` | `muted` | `muteAvailable` |

- Accept: qmllint no syntax errors; running `pollCmd` in a shell prints four `key=` lines; toggle strings match exactly. NEVER run any toggle command while testing.

## Set C: `package/contents/ui/modules/QuickTogglesModule.qml` (new)

- Imports: `QtQuick`, `QtQuick.Controls as QQC2`, `org.kde.kirigami as Kirigami`, `"../components"`. No `org.kde.plasma.plasmoid`.
- Root `Tile { id: qt }`; `property var items: []`; `signal toggled(string key)`; `readonly property real inner: height - padding * 2`; `implicitWidth: row.implicitWidth + padding * 2`.
- `Row { id: row; anchors.centerIn: parent; spacing: qt.inner * 0.18 }` with `Repeater { model: qt.items }`.
- Delegate `QQC2.AbstractButton`, `required property var modelData`: `width/height: qt.inner`; `enabled: modelData.available`; `opacity: enabled ? 1 : 0.4`; `scale: pressed ? 0.94 : 1` with 80 ms `Behavior`; `onClicked: qt.toggled(modelData.key)`; `background: Rectangle { radius: width / 2; color: modelData.on ? Qt.alpha(Kirigami.Theme.highlightColor, 0.2) : Qt.alpha(Kirigami.Theme.textColor, 0.1); border.width: 1; border.color: modelData.on ? Kirigami.Theme.highlightColor : "transparent" }`; `contentItem: Kirigami.Icon { source: modelData.icon; isMask: true; color: modelData.on ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor; implicitWidth: qt.inner * 0.5; implicitHeight: qt.inner * 0.5 }`; tooltip `QQC2.ToolTip.visible: hovered`, `.text: modelData.label + (modelData.on ? " · on" : " · off")`.
- Accept: qmllint no syntax errors; no plasmoid import.

## Set D: wiring and docs (after A, B, C exist)

`main.xml`: add the four entries.

`main.qml`: `import org.kde.taskmanager as TaskManager`; add
```qml
readonly property var appLaunchers: cfg.appLaunchers.split(",").map(s => s.trim()).filter(s => s !== "")
Loader {
    id: tasksLoader
    active: root.cfg.showApps
    sourceComponent: Component {
        TaskManager.TasksModel {
            launcherList: root.appLaunchers
            groupMode: TaskManager.TasksModel.GroupApplications
            sortMode: TaskManager.TasksModel.SortManual
            separateLaunchers: false
            launchInPlace: true
            hideActivatedLaunchers: true
            filterByVirtualDesktop: false
            filterByScreen: false
            filterByActivity: false
        }
    }
}
ToggleSource {
    id: toggles
    active: root.cfg.showToggles
    keys: root.cfg.toggleItems.split(",").map(s => s.trim()).filter(s => s !== "")
}
```
at root level near the sensors (import `components` the way main.qml already does). In the compact row: `Modules.AppsModule { Layout.fillHeight: true; visible: root.cfg.showApps; tasks: tasksLoader.item }` right after `Modules.MediaModule`; `Modules.QuickTogglesModule { Layout.fillHeight: true; visible: root.cfg.showToggles; items: toggles.items; onToggled: key => toggles.toggle(key) }` after `Modules.StorageModule`, before Battery.

`configGeneral.qml`: aliases `cfg_showApps`, `cfg_showToggles` (`.checked`), `cfg_appLaunchers`, `cfg_toggleItems` (`.text`); two checkboxes ("Pinned apps", "Quick toggles"); two TextFields ("Pinned apps:" placeholder `preferred://browser,applications:org.kde.dolphin.desktop`; "Toggles:" placeholder `wifi,bluetooth,dnd,nightlight,mute`).

Docs: `README.md` module list plus note that `brightnesscontrolplugin` and `notificationmanager` are Plasma-internal APIs; `docs/PLAN.md` mark these done and note the Apps no-tile exception.

Acceptance: scratch copy of `package` in the scratchpad with `showApps` and `showToggles` set true; `timeout 20 plasmoidviewer -a <copy> -f horizontal 2>&1 | grep -iE 'qml|TypeError|ReferenceError|not installed|Cannot assign|unavailable|Error'` has no lines naming our files and none saying a module is not installed. Taskmanager / Wayland window-management warnings not naming our files are expected in the viewer (running dots only show inside plasmashell). Also run with repo defaults (both off): no errors. Do not click toggles.
