# Plan: easy widgets batch

Goal: add the no-key, no-account widgets to the dock as new tiles. Visual rules: `docs/STYLE.md`.

## Widgets

| Module | Data | Notes |
| --- | --- | --- |
| Temperature | sensor `cpu/all/averageTemperature` | Value in °C, ring or number tile |
| Network | sensors `network/all/download`, `network/all/upload` (bytes/s) | Compact units (`1.2M`), up/down arrows |
| Storage | sensors `disk/all/used`, `disk/all/total` | Ring showing used % plus `used / total` label |
| Battery | sensor from setting `batteryPercentSensor` (default `power/SerialNumber/chargePercentage`) | The ID contains a device-specific part, so it is configurable. Blue tile with wave fill is optional; ring is enough |
| Weather | Open-Meteo, no key | Needs `latitude` and `longitude` settings. Refresh every 30 min |
| Pomodoro | local timer | 25/5 min cycles, KDE notification at the end, red accent per STYLE.md |
| Timer | local timer | Presets 1/5/10/25 min, click to start/pause |
| Stopwatch | local timer | Start/pause/reset |
| World Clocks | local | Up to 3 zones from setting `worldZones` (comma-separated IANA names) |
| Todos | persisted in settings | Setting `todosJson`; add, tick, clear done |

Out of this batch: Apps and Quick Toggles (medium effort), Calendar (needs iCal parsing), anything that needs a key.

## Architecture

Existing rule: data sources live once in `main.qml`; modules stay dumb views. Exceptions are modules that own local state (Pomodoro, Timer, Stopwatch, Todos, World Clocks, Weather). They keep their timers and state inside their own file and run only while visible.

Each module is one file in `package/contents/ui/modules/<Name>Module.qml`:

- Root is `Tile` (`../components/Tile.qml`). Clock is the only exception.
- `implicitWidth` is set from content plus `padding * 2`. Height comes from the layout (`Layout.fillHeight: true`).
- Declares `signal clicked()` only if the tile does something on click. `Tile` already has it.
- Inputs are plain `property` values. No imports of `org.kde.plasma.plasmoid`.
- Style: `Kirigami.Units`, `Kirigami.Theme` colors, `font.features: { "tnum": 1 }` for numbers, secondary text at `opacity: 0.6`.

## Work split

Three independent file sets, so nothing collides:

1. **Hardware views** (props from `main.qml`): `TemperatureModule`, `NetworkModule`, `StorageModule`, `BatteryModule`
2. **Time modules** (self-contained): `PomodoroModule`, `TimerModule`, `StopwatchModule`, `WorldClocksModule`
3. **Data modules**: `WeatherModule`, `TodosModule`

Each author tests its files in a small standalone harness, not in Plasma.

## Wiring (done after the modules exist)

Shared files, edited once, not in parallel: `main.qml`, `config/main.xml`, `ui/configGeneral.qml`.

- `main.xml`: a `show<Name>` Bool per module (all default `false` except Battery), plus `batteryPercentSensor`, `latitude`, `longitude`, `worldZones`, `todosJson`.
- `main.qml`: sensors for Temperature, Network, Storage, Battery; one `Modules.<Name>` per tile in the compact row, before the clock.
- `configGeneral.qml`: a checkbox per module and fields for the new settings.

## Verification

1. `plasmoidviewer -a package -f horizontal` with every module enabled: no QML errors in the log.
2. Screenshot of the dock row.
3. Install and restart Plasma, then check `journalctl --user -u plasma-plasmashell` for `dev.aryan.dock`.

## Known limits

- Many tiles make a wide dock; all new ones are off by default.
- Battery sensor ID is device-specific until we auto-detect it.
- Weather needs coordinates set by hand.
