# Changelog

Notable changes to Dockyard. Newest first.

## Unreleased

### Added

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

### Notes

- The per-tile popup is created on first use. If it cannot be created, the dock falls back to the centred popup instead of failing.
- The Meta key opens the launcher over the Start tile. It falls back to the centred popup when the Start tile is hidden or `tilePopups` is off.

## Earlier

- Win key opens the launcher and focuses search.
- Renamed to Dockyard. Added the power flyout, widgets and the glass theme.
- First version: plasmoid with clock, stats, media and 10 widget tiles.
