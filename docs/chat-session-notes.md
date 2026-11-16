# Session notes: AvdanOS research vs Dockyard

Working directory: `/run/data/Development/plasma-dock`
Research source: `/run/data/Development/avdanos/research/` (`features.md`, `agy.log`, `shots/`)

## 1. Request: check the research folder for ideas to build alongside Dockyard

The research folder holds `features.md`, a 779-line analysis of four AvdanOS concept videos:

| Video | ID | Length | Focus |
| --- | --- | --- | --- |
| Introducing AvdanOS (Concept) | `tXFEiw1aJTw` | 3:32 | Dock islands, start dashboard, Files, radial text menu, Lale browser |
| Introducing AvdanOS Pro | `woMGr7Ip2Jk` | 2:40 | Render pill, resource gauges, desktops, clipboard, radial file menu, notification hub |
| Introducing AvdanOS Remastered (4K HDR) | `pISedVNfJkI` | 4:06 | Liquid glass, App Setups presets, lock screen, weather squircle, activity hub |
| Introducing AvdanUX: First Look (Vapor) | `aVBQQVsqoSA` | 0:40 | Spatial glass, icon weights, floating islands |

The doc also includes animation tables, color and radius values, and an easing guide:
- Enter / popups: `cubic-bezier(0.16, 1.0, 0.3, 1.0)`, 350–450 ms
- Elastic feedback: `cubic-bezier(0.34, 1.56, 0.64, 1.0)`, 250–320 ms
- Snapping: `cubic-bezier(0.2, 0.0, 0.0, 1.0)`, 380–420 ms
- Theme morph: `ease-in-out`, 700–800 ms

### Dockyard's existing modules (checked against the code)

- `main.xml` has 29 `show*` flags: Start, Clock, Stats, Media, Temperature, Network, Storage, Script, Battery, Weather, Pomodoro, Timer, Stopwatch, WorldClocks, Todos, Apps, Toggles, Calendar, the month/day/year progress tiles, Date, ClockStyle, DayNumber, Notes, Volume, RecycleBin, Screenshot, Notifications, Tray.
- `NotificationService.qml:97,114` sets `showJobs: false`.
- `WeatherSource.qml:67-68` requests only current conditions and today's high/low from Open-Meteo.
- `AppsModule.qml:182` already uses `TaskManager.VirtualDesktopInfo`, for the window context menu.
- `ClipboardService.qml` loads Klipper's `KlipperInterface`, but the dock has no visible clipboard UI.
- `RingGauge` is used by TemperatureModule, BatteryModule and StatsModule.
- `CalendarModule` reads one next event through `scripts/next-event.py`.

### The 12 ideas, by effort

**Easy**
1. Job progress pill (Pro video render pill). Use the `showJobs` flag.
2. Weather upgrade: hourly strip, UV index, 5-day forecast, rain chance.
3. Virtual desktops tile: dots on the dock, thumbnails in a popup.
4. Concentric CPU/RAM/disk rings for the Stats tile.
5. Motion pass: the research easing curves on popups and tiles.

**Medium**
6. Clipboard history tile/popup, using Klipper's history model.
7. Device battery card: phone via KDE Connect, peripherals via UPower.
8. "Pick up where you left off": recent files (KActivities) and the paused MPRIS track.
9. Collapsible apps chevron for pinned apps that are not running.
10. Day/night look on sunrise and sunset times.

**Bigger**
11. Island layout: the bar split into floating glass pills.
12. App Setups: saved multi-app layouts, tiled through the existing KWin script.

Partly present already: the whole-day agenda. `next-event.py` returns only the next event.

**Left out on purpose** (needs compositor or file-manager work): radial menus, tab merging, the drag-and-drop pill, liquid refraction, lock screen.

### Not verified
- Each feasibility note comes from reading code. None were tested on a running Plasma session.
- The research doc's numbers and claims about AvdanOS come from the doc itself. I did not re-watch the videos.

## 2. Request: a web mockup of how this could look

### Built
- File: `/run/data/Development/plasma-dock/docs/mockups/dockyard-next.html`
- Published (private): https://claude.ai/artifact/UcBV9RaHXB699FXRRZwfCA (version 1, icon "dock")
- Only the owner can open the link until it is shared, through the page's Share menu.

### What the mockup contains
- A mock desktop with the dock. The stage scales to fit the window and is 1680×720 in design units.
- Tile popups open over the tapped tile, with the research enter curve and rows rising 40 ms apart.
- Popups for jobs, weather, desktops, clipboard, devices, stats, clock, start/presets, and media.
- Switches: **Island layout** (dock splits into glass pills) and **Day look** (light palette, toast "Sunrise 06:52").
- Live job progress and CPU ring updates.
- Apps chevron collapses non-running app icons.
- Desktop dots switch desktops; "+" adds one (toast only).
- Preset clicks show a toast ("Opening Research: 3 apps, tiled side by side").
- Feature list below the stage grouped Easy / Medium / Bigger. Each **Show** button runs the feature on the dock.
- Accessibility: focus-visible outlines, Escape closes popups, and reduced-motion disables animation.
- Tested at 1440×900 with a screenshot and dock width check. The clipped-dock bug was fixed by scaling the stage.

### Mockup caveats
- Fonts load from Google Fonts (Inter, JetBrains Mono).
- All values are examples: Wi-Fi name, job list, device batteries, weather, agenda.
- The mock dock omits the media tile and one app icon to fit.
- Nothing in the real dock was changed.

## 3. Other events in the session
- Ran `/model claude-haiku-5-5`. Output: "Set model to `claude-haiku-5-5`."
- Caveman mode was active for the replies. Files written for the user are plain text.

## 4. Git state
- Nothing committed or pushed.
- Repository already had uncommitted work when the session started. It is not part of this session. Files there: `CHANGELOG.md`, `package/contents/config/main.xml`, `configSystem.qml`, `configWidgets.qml`, `main.qml`, `GalleryPanel.qml`, and new files `NotificationCard.qml`, `NotificationService.qml`, `NotificationsModule.qml`, `NotificationsPanel.qml`.
- New from this session: `docs/mockups/dockyard-next.html` and this file, `docs/chat-session-notes.md`.

## 5. Open choice
The next step to build is undecided. Options from the session: the job progress pill or the weather upgrade, both on the Easy list.
