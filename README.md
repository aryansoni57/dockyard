# Dockyard

**A smart dock for KDE Plasma 6 that runs inside `plasmashell`.**

`Plasma 6` · `plasmoid` · plugin id `dev.aryan.dock`

---

## Contents

- [Features](#features)
- [Install](#install)
- [Run](#run)
- [Layout](#layout)
- [Notes](#notes)

## Features

| Group | Modules |
| --- | --- |
| Time | clock, world clocks, pomodoro, timer, stopwatch |
| System | CPU/memory stats, temperature, network, disk, battery |
| Media | now playing (MPRIS) |
| Info | weather, todos |
| Apps | pinned apps with running dots; Meta+1 to Meta+9 open or switch to them |
| Quick toggles | Wi-Fi, Bluetooth, Do Not Disturb, Night Light, mute |
| Script | output of your own shell command, refreshed on a timer |

Click a tile to open its detail popup. Right-click the dock and choose Widgets… to add or remove tiles.

> [!NOTE]
> Pinned apps and quick toggles are off by default. Turn them on in the widget settings; the launcher list and toggle list are comma-separated text fields there.

## Install

Install, then add "Dock" to a panel via Add Widgets:

```bash
./install.sh
```

`install.sh` also installs and enables the Dockyard Shortcuts KWin script for Meta+1 to Meta+9.
It clears those keys from the stock Task Manager's plasmashell entries. If you add a Task Manager to a panel later,
set its keys again in System Settings > Shortcuts.

Or install the plasmoid and both glass desktop themes (Glass and Glass (opaque)) together, then restart plasmashell
(`--apply-theme` also activates the theme, `--apply-global` also installs and activates the Dockyard Kvantum, color scheme, Aurorae and look-and-feel set, and `--no-restart` skips the restart). `--apply-global` saves your current choices first; run `theme/restore-global.sh` to undo it:

```bash
./install-all.sh
```

## Run

Test without installing:

```bash
plasmoidviewer -a package
```

## Layout

```text
package/
  metadata.json            plugin id dev.aryan.dock
  contents/config/main.xml config keys
  contents/ui/main.qml     shared data sources + compact/full views
  contents/ui/modules/     one dumb view per module
kwin-script/               KWin script that owns Meta+1..9 and tells the dock
```

Data sources (sensors, MPRIS, clock) live once in `main.qml` and feed every module.

### Adding a module

1. Add a new file in `modules/`.
2. Add a `show<Name>` key in `main.xml`.
3. Add a checkbox in `configWidgets.qml`. Put the module's own options on the settings page it belongs to (`configApps.qml`, `configClock.qml`, `configWeather.qml` or `configSystem.qml`).

## Notes

> [!WARNING]
> Dockyard depends on private and internal Plasma APIs. They can change between Plasma releases.

**Private and internal Plasma APIs**

| API | Used for | Status |
| --- | --- | --- |
| `org.kde.plasma.private.mpris` | now playing | Private Plasma API. It can change between Plasma releases. |
| `org.kde.plasma.private.brightnesscontrolplugin` | Night Light | Private Plasma API. It can change between Plasma releases. |
| `org.kde.notificationmanager` | Do Not Disturb | Plasma-internal, not a stable public API. |

**Shell commands**

Quick toggles run shell commands: `nmcli`, `bluetoothctl`, `rfkill`, `wpctl`, and `busctl`. Missing tools hide their toggle state; nothing else breaks.

**Performance**

Hidden modules stop their sensors and timers, so they cost nothing.

**Opaque dock bar.** A switch on the Widgets settings page makes the dock bar solid and swaps the Plasma theme between `glass` and `glass-opaque`. It leaves any other theme alone.

## License

GPL-2.0-or-later. See [LICENSE](LICENSE).
