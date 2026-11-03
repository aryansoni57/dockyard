# Plan: hover names and click actions

Goal: every tile shows its name on hover, and clicking any tile does something useful. Rules: `docs/STYLE.md`, architecture in `docs/PLAN.md`.

## Current state

Tiles that already react to a click: Media, Pomodoro, Timer, Stopwatch (their buttons), Todos, Notes, Stats and Clock (open the popup), Weather (opens settings), Recycle Bin, Screenshot, Quick Toggles (their buttons), Apps (per icon, with an app-name tooltip).

Tiles that do nothing on click: Temperature, Network, Storage, Battery, Volume, Date, Day Number, Month/Day/Year Progress, World Clocks. No tile except Apps has a hover tooltip.

## Hover name

One mechanism, in `components/Tile.qml`, so no module repeats it:

- New `property string title` on `Tile`.
- A `QQC2.ToolTip` shown while the tile is hovered, after `Kirigami.Units.toolTipDelay`, text = `title`. Hidden when `title` is empty.
- `main.qml` sets `title` on each module. Names follow the demo video's widget names: "System Stats", "Temperature", "Network", "Storage", "Battery", "Volume", "Date", "Day Number", "Month Progress", "Day Progress", "Year Progress", "World Clocks", "Weather", "Clock", "Notes", "Todos", "Pomodoro", "Timer", "Stopwatch", "Now Playing", "Quick Toggles", "Recycle Bin", "Screenshot Capture".
- Tooltips that carry a live value (for example "Storage · 92% used") are optional; start with plain names.
- Tiles with inner buttons (Quick Toggles, Screenshot) keep their own per-button tooltips; the tile name shows on the tile padding.
- Apps keeps its per-icon tooltip and gets no tile name.

## Click actions

Two kinds: launch a KDE tool, or open the dock popup (`root.expanded`, `fullRepresentation`). Commands go through the existing `ShellRunner`.

| Tile | Click does | Needs |
| --- | --- | --- |
| Stats | `plasma-systemmonitor` | System Monitor |
| Temperature | `plasma-systemmonitor` | System Monitor |
| Network | `systemsettings kcm_networkmanagement` | none |
| Storage | `filelight /`, falling back to `xdg-open /` | Filelight (optional) |
| Battery | `systemsettings kcm_powerdevilprofilesconfig` | none |
| Volume | tile body toggles mute (`wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle`); the slider still sets the level | none |
| Weather | no location set: open settings. Location set: `xdg-open https://wttr.in/<lat>,<lon>` | browser |
| Clock | popup (as now) | none |
| Date, Day Number | popup, with a new month grid section | none |
| Month, Day, Year Progress | popup, with a new "Progress" section: three `InfoRow`s with progress bars | none |
| World Clocks | popup, with a new section listing each zone and its time | none |
| Pomodoro, Timer, Stopwatch | tile body toggles start/pause (the round buttons keep working) | none |
| Media, Todos, Notes, Quick Toggles, Recycle Bin, Screenshot, Apps | unchanged | none |

Popup sections for Calendar, Progress and World Clocks are new. The popup stays a single `fullRepresentation`; each section is shown only when its widget is enabled, like Notes and Todos. Optional follow-up: scroll the popup to the section of the tile that was clicked.

## Work split

1. `Tile.qml`: `title` property and tooltip. `main.qml`: set `title` on every module.
2. Launch actions: add `signal`/handler wiring in `main.qml` for Stats, Temperature, Network, Storage, Battery, Weather. Add the mute-on-click to `VolumeModule.qml` (tile body only, never the slider).
3. Timer-type tiles: body click toggles start/pause in `PomodoroModule.qml`, `TimerModule.qml`, `StopwatchModule.qml`.
4. Popup sections: Calendar month grid, Progress rows, World Clocks list in the `fullRepresentation` in `main.qml`, plus click wiring for Date, Day Number, Progress tiles and World Clocks. Section content that needs a computed value (month grid) goes in a small component under `components/`.

Steps 1 and 2–4 touch the same file (`main.qml`), so do them in order, not in parallel.

## Verification

1. Load check: `./install.sh`, restart Plasma, then `journalctl --user | grep dev.aryan.dock` shows no errors.
2. Hover each tile: its name appears after the tooltip delay.
3. Click each tile in the table and confirm the action. Tools that are not installed must fail quietly (no error dialog, no crash).
4. Drag-to-reorder still works: a drag must not count as a click on release.
5. Click on a button or slider inside a tile still does only that button's job.

## Decisions to confirm

- External tools assumed: System Monitor (ships with Plasma), Filelight (may be missing). Fallback is `xdg-open /`.
- Weather click: browser forecast page versus a popup section. The plan uses the browser page because the popup has no forecast UI yet.
- Stats and Clock currently open the popup; the plan changes Stats to System Monitor and keeps Clock as the popup.
- Tooltip text is plain names; live values are a later polish step.
