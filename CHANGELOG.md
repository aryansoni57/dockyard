# Changelog

Notable changes to Dockyard. Newest first.

## Unreleased

### Added

- Tiles open their own popup view over the tapped tile: clock, calendar, world clocks, progress, media, notes and todos. The Start tile opens the launcher over itself.
- `tilePopups` setting, a kill switch for the per-tile popup. When it is off, popups use Plasma's centred popup as before. It defaults to off.
- The first search match in the launcher is highlighted, and Enter launches it. A math query still copies its result.
- Tapping the Volume tile outside the slider opens the audio settings (`kcm_pulseaudio`).
- Discord is part of the default dock apps.

### Changed

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
