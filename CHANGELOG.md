# Changelog

Notable changes to Dockyard. Newest first.

## Unreleased

### Added

- Dashboard right-click menus: a pinned app offers Open and Unpin (the dock's app row follows), an App Setup offers Run, Rename and Delete, a recent file offers Open, Open containing folder, Copy path and Remove from recent, and the Continue listening card offers Play or Pause, Next, Previous and Open player. Left-clicking that card's art or title brings the player forward.
- New event: a "+" on the dashboard's Today card asks for a title, date and times, then opens Google Calendar's create-event page with them filled in. Press Save there. The dock cannot write to Google Calendar itself, and an iCal link is read-only.
- Save current in the dashboard's App Setups row now remembers where every window is, on each monitor: the setup shows a small map of your monitors, and clicking it puts each window back on its own monitor at the same place (fractions of the monitor, found by monitor name; a monitor that is gone falls back to the dock's). Tiled layouts still work for setups you make by hand.
- Two docks, one per monitor: only one of them shows notification toasts and the day and night notice (the one on the primary screen, else the lowest applet id), instead of every dock repeating them. Meta+1 to Meta+9 reach only the dock on the focused window's screen. App Setups tile on the dock's own screen.
- App Setups: named sets of apps that open and tile together. Make them on the new App Setups settings page, or click Save current in the dashboard's App Setups row to turn the windows you have open into one. Clicking a setup opens or raises each app and tiles them side by side, in a grid, or one large with the rest stacked, with a one-off KWin script (`setup-tile.sh`). Apps that are slow to start are tiled by later passes over about 14 seconds.
- Island layout (`dockLayout`, Widgets page, Dock bar): the dock splits into floating glass pills, one for the tiles before the apps, one for the apps, one for the tiles after. A Plasma panel draws its own background, so turning islands on also applies a `glass-islands` Plasma theme (a copy of Glass with no panel background) when a Dockyard theme is active; Bar puts Glass back. The pills slide when tiles come and go.
- Day and night look (`dayNightLook`, System page, off by default): the Plasma color scheme switches to a day scheme at sunrise and back to a night scheme at sunset, with a notification. The times come from the weather location (so set one), compared with this machine's clock. Day defaults to BreezeLight and night to Dockyard; pick others on the System page.
- A chevron at the end of the apps row hides the pinned apps that are not running and shows them again (`appsCollapsed`, remembered). The icons fade out and the rest glide together. Meta+1 to Meta+9 still count the hidden apps, and pinning an app expands the row.
- Start style (`startStyle`, Apps page): switch the Start tile and Meta between the Lumen launcher and a dashboard after the AvdanOS home screen. The dashboard has weather with an hourly strip, today's agenda, device batteries, pinned apps, a pick-up-where-you-left-off column (the track you were playing, the files you used last), and a footer with settings, all apps, power and disk space. All apps opens the Lumen launcher. The agenda reads the dock's calendar settings.
- The launcher's Recent list is now Continue: a track left paused comes first, one tap resumes it, and each recent file says how long ago you used it ("5 min ago", "2h ago").
- Battery popup lists other devices' batteries: mice, keyboards, headsets and controllers from UPower, and phones over KDE Connect when one is paired and reachable. `showDevices` on the System page turns it off. Nothing shows when there is no such device.
- Clipboard history tile (`showClipboard`, off by default): a clipboard glyph with the number of entries Klipper holds. Tap it for a searchable list of what you copied, as cards with Copy and Remove, and Clear history. It reads the same Klipper history as Meta+V.
- Stats tile shows CPU, RAM and disk as three nested rings (`statsConcentric`, on by default; off keeps CPU and RAM side by side). Tap it for a popup with two-minute CPU and memory graphs and the disk usage bar. It used to open System Monitor; the popup has a button for that.
- Weather popup: tap the Weather tile for the next 12 hours, a plain rain hint, five days with their ranges, sunrise and sunset, and a UV ring. It replaces the wttr.in link. The tile and the clock keep working as before.
- Job progress pill (`showJobs`): a tile that shows only while a file copy or other KDE job runs, with the app icon, a progress bar and the percent, or "N jobs" when several run. Tap it for the job list, with pause and stop buttons.
- Notifications: the dock now runs Plasma's notification server. Before, a setup with the dock and no stock Notifications widget showed no notifications at all, because nothing in plasmashell owned `org.freedesktop.Notifications`. New notifications pop up in the screen corner by the dock, with their action buttons. Hover to keep one on screen. A Notifications tile (`showNotifications`) shows a bell with the missed count. Tap it for the history, Do Not Disturb, Clear all, and Plasma's notification settings. `notificationPopups` on the System page turns the popups off and keeps the history. Per-app rules from System Settings > Notifications still apply. Right-click a notification to open it, run its actions, copy its text, configure that app's notifications, or dismiss it. Right-click the bell for Do Not Disturb (1 hour, 4 hours, until tomorrow, until turned off), Clear All, and Configure.
- Widget gallery: right-click the dock and choose Widgets… to add or remove tiles from a searchable grid grouped by category. The header shows how many tiles are on the dock.
- Drop a `.desktop` file on the dock's apps to pin it.
- `appMagnify` setting on the Apps page: icons near the pointer grow.
- Dockyard look for the whole desktop: a Kvantum style (`Dockyard`, solid windows with glass menus and tooltips, and `DockyardGlass`, translucent windows), a KDE color scheme, an Aurorae titlebar with monochrome buttons, and a look-and-feel package. `./install-all.sh --apply-global` installs and applies them. It saves your current choices first, and `theme/restore-global.sh` puts them back.
- Meta+1 to Meta+9 open or switch to the app icons in the Apps module, left to right. A launcher opens, a window is focused or minimised, and an app with several windows cycles through them. A KWin script installed by `install.sh` owns the keys, because Plasma 6.8 gives them only to the stock Task Manager.
- Tiles open their own popup view over the tapped tile: clock, calendar, world clocks, progress, media, notes and todos. The Start tile opens the launcher over itself.
- `tilePopups` setting, a kill switch for the per-tile popup. When it is off, popups use Plasma's centred popup as before. It defaults to off.
- The first search match in the launcher is highlighted, and Enter launches it. A math query still copies its result.
- Tapping the Volume tile outside the slider opens the audio settings (`kcm_pulseaudio`).
- Discord is part of the default dock apps.
- Right-click an app in the dock for a menu: New Window, the app's own `.desktop` actions (such as New Private Window), Pin or Unpin, Minimize or Restore, Maximize or Unmaximize, Keep Above Others, and Close.
- Script tile shows the output of your own shell command, run on a timer (`scriptCommand`, `scriptInterval`). The first line shows big, the second small, and the full output is the tooltip. Set `scriptClickCommand` to run something else on click. A command that hangs stops after 30 seconds.
- Opaque dock bar switch on the Widgets settings page (`barOpaque`). It makes the bar solid and swaps the Plasma theme between `glass` and `glass-opaque`. It leaves any other theme alone.
- Quick Share toggle in the quick toggles and the quick settings flyout, shown when `rquickshare` is installed. On opens the app so nearby devices can find you, and off quits it.

### Changed

- The Notes tile keeps several notes. The popup shows a chip per note, a button for a new one and a delete button. The tile shows the selected note and a count when there is more than one. An old single note becomes the first note (`notesJson`, `notesCurrent`).
- The Todos popup lists every todo, open ones first and a Completed section below. Tap the circle to complete or restore a todo, and the bin button to delete it. The list scrolls when long.
- The Todos tile fits its header and two rows inside the tile height, so long text or tall fonts no longer run past the bottom.
- Settings are split into five pages. Widgets turns tiles on and off. Apps, Clock & Calendar, Weather and System hold each tile's options, so the options are no longer at the bottom of one long page.
- City search lists every match (several cities share a name) and remembers the chosen place name (`locationName`).
- World clock zones and your own pinned-app list are edited as lists with reorder and remove, not as comma-separated text. Zones are picked from the ones the tile supports. Editing the pinned list keeps the launcher pins in step.
- The System page finds the battery sensor and shows a live reading. Sensor refresh is a choice of intervals instead of a millisecond box.
- The launcher's grid or list view and `tilePopups` can now be set in Settings.
- Presets keep the launcher on, and a preset can be undone.
- Enter in the city search or a list's add field no longer closes the settings dialog.
- `install-all.sh` installs both glass themes, `glass` and `glass-opaque`, and takes `--apply-global` for the Dockyard desktop set.
- The quick settings flyout fits an odd number of cards by giving the last card the full row.

- Pinning or unpinning an app in the launcher also updates the dock app row. Reordering apps on the dock writes the same order back to the launcher pins.
- The launcher search clears when the Start menu closes.
- Clicking a tile no longer opens one generic Dock panel. Each tile opens the view that fits it. The System section of that panel is gone, since the Stats tile already opens System Monitor.
- `Tile` emits `clicked(Item source)`, so a handler can anchor a popup to the tile that was tapped. Handlers that take no argument still work.

### Fixed

- Right-clicking a pinned app, setup card or recent file's Open button on the dashboard no longer also runs its left-click action.
- Pressing Esc on the dashboard no longer switches to the launcher as if it were typed text.

### Notes

- The per-tile popup is created on first use. If it cannot be created, the dock falls back to the centred popup instead of failing.
- The Meta key opens the launcher over the Start tile. It falls back to the centred popup when the Start tile is hidden or `tilePopups` is off.

## Earlier

- Win key opens the launcher and focuses search.
- Renamed to Dockyard. Added the power flyout, widgets and the glass theme.
- First version: plasmoid with clock, stats, media and 10 widget tiles.
