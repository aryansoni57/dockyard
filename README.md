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
| Apps | pinned apps with running dots |
| Quick toggles | Wi-Fi, Bluetooth, Do Not Disturb, Night Light, mute |

Click the dock to open the detail popup.

> [!NOTE]
> Pinned apps and quick toggles are off by default. Turn them on in the widget settings; the launcher list and toggle list are comma-separated text fields there.

## Install

Install, then add "Dock" to a panel via Add Widgets:

```bash
./install.sh
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
```

Data sources (sensors, MPRIS, clock) live once in `main.qml` and feed every module.

### Adding a module

1. Add a new file in `modules/`.
2. Add a `show<Name>` key in `main.xml`.
3. Add a checkbox in `configGeneral.qml`.

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
