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

Apps and Quick Toggles are done (see `docs/PLAN-apps-toggles.md`). Out of this batch: Calendar (needs iCal parsing), anything that needs a key.

## Architecture

Existing rule: data sources live once in `main.qml`; modules stay dumb views. Exceptions are modules that own local state (Pomodoro, Timer, Stopwatch, Todos, World Clocks, Weather). They keep their timers and state inside their own file and run only while visible.

Each module is one file in `package/contents/ui/modules/<Name>Module.qml`:

- Root is `Tile` (`../components/Tile.qml`). Clock is a Tile now. Apps is the only exception (loose icons, no tile, per STYLE.md).
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

## Reference: demo video analysis

Source: a 140s demo video of a similar dock, analysed from frames sampled every 3s. Items marked (inferred) were not seen directly. Timestamps are approximate.

### Screens

1. **Desktop + dock** — bottom-centre pill that grows as widgets are added; pinned app icons; context menus.
2. **All Widgets gallery** (3–39s) — modal with search and category sidebar (Clocks, Productivity, System, Apps & Files, Media & Audio, AI, Analytics, Social, Stocks, Finance, Weather, Online & Mail). Header counter "N in bar" goes 3 → 15 as widgets are pinned.
3. **Wallpapers picker** (45–51s) — tabs Nature, Landscape, Cozy, Dark, Gradient, Cars; thumbnail grid; picking one changes the wallpaper.
4. **Storage detail** (66s) — used/free and percentage; "Scan now / Not now"; nothing is measured until the scan is started; results cached 5 minutes.
5. **Temperature detail** (99–102s) — 10-minute line graph with hover tooltip (value + time); sensor list (CPU, Board, Chassis, Battery, Graphics); CPU and memory load.
6. **Bluetooth card** (108s) — on/off toggle; "No paired devices" state; link to system Bluetooth settings.
7. **Quick Toggles panel** (114–117s) — switches: Wi-Fi, Bluetooth, Hotspot, Airplane, Microphone, Camera, Keep Awake, Desktop Icons, Display Mode.
8. **Screen Time detail** (129–132s) — Day/Week tabs; hourly bar chart with hover tooltip; Most Used (Apps / Websites tabs); longest focus; app switches; first use; daily-summary toggle.
9. **Context menus** — dock menu: Widgets…, Settings, Task Manager, Close, Logout. Dock-item menu: Unpin, Close.

### Widget catalog

- **Clocks:** digital, flip, world clocks, analog (classic, dark, minimal), segment, date, day number, clock + weather, 7-day strip.
- **Productivity:** Screen Time, Focus/Pomodoro (cycle count, countdown), Timer, Stopwatch, Todos, Notes, Calendar, Currency converter.
- **System:** CPU/RAM stats, Battery, Tray, Language, Quick Toggles, Brightness slider, Theme toggle, Temperature, Network speed, Month/Day/Year progress, Storage.
- **Apps & Files:** Apps grid, Recently Opened, Recycle Bin, Search, Commands, Recent Screenshots, Downloads, Screenshot Capture, Folders.
- **Media:** Now Playing (full, mini, bar) with prev/pause/next; speaker volume slider.
- **AI usage:** ChatGPT, Gemini, Grok, DeepSeek balance, GLM, OpenCode (session + weekly), Cursor.
- **Social / analytics:** DataFast chart, X, TikTok, YouTube, GitHub activity and unread, LeetCode, Gmail.
- **Finance / weather:** stock ticker, chart, watchlist; BTC/USD metric; forecast, hourly, sunrise/sunset.
- **Other:** Wallpaper Gallery.

### Gestures and interactions

- Click a widget in the gallery to pin it (inferred); scroll the gallery vertically; X closes modals.
- Tab switching inside modals (wallpaper categories, Screen Time Apps/Websites).
- Right-click on the dock opens the dock menu; right-click on an item opens Unpin/Close (inferred).
- Click a widget to open its detail modal (Storage, Temperature, Screen Time); expander arrow opens a card (Bluetooth).
- Hover a chart for a value/time tooltip.
- Media: click Next, track changes.
- Toggle switches (Bluetooth, Quick Toggles); start Focus timer and Stopwatch with Play, then live countdown/count-up.
- Drag a desktop file onto the dock to pin it (inferred): icon magnifies on approach, filename tooltip shown.
- Dock scrolls horizontally when it overflows (inferred).
- Not seen: keyboard shortcuts, swipe gestures.
