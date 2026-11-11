# Plan: roadmap

What is left to build in Dockyard, by phase. Visual rules: `docs/STYLE.md`. Architecture: `docs/PLAN.md`.

## Phase 1: dock feel

| Item | What | Status |
| --- | --- | --- |
| Widget gallery | "Widgets…" in the dock context menu opens `popups/GalleryPanel.qml`: search, categories, tap a card to add or remove a tile, "N in bar" counter. | Done |
| Drop to pin | Drop a `.desktop` file on the Apps row to pin it. Other files still open in the app they are dropped on. | Done |
| Icon magnify | `appMagnify`: icons near the pointer grow, up to 1.25×. | Done |
| Drag to reorder tiles | Already in `main.qml` (`DragHandler` on the tile row). | Done before |
| Overflow scroll | Already in `main.qml` (wheel and edge buttons). | Done before |

## Phase 2: detail popups

- Temperature: 10-minute line graph with a hover tooltip, list of sensors (CPU, GPU, board, battery).
- Storage: used and free per mount, "Scan now" for the largest folders, results cached 5 minutes.
- Network: live up/down sparkline, SSID, IP address.
- Battery: time left, power profile picker (`powerprofilesctl`).
- Weather: hourly strip, 7-day forecast, sunrise and sunset (Open-Meteo already returns them).

## Phase 3: new modules, no key

- Clipboard history tile and popup (`ClipboardService` exists).
- Brightness slider (`brightnesscontrolplugin`).
- Light/dark theme toggle (`plasma-apply-colorscheme`).
- Keyboard layout indicator and switcher.
- Recent files, Downloads and Folders tile.
- Quick toggles: Airplane, Hotspot (`nmcli`), Microphone mute, Keep Awake, Desktop icons.
- Screen Time: per-app usage logged from KWin active-window events, day and week chart.
- Currency and unit conversion in the launcher search.

## Phase 4: online modules, need a key

- GitHub activity and unread notifications.
- Stock and crypto ticker.
- Move `planeApiKey` from plain config to KWallet.

## Phase 5: quality and distribution

- Translations: extract script and `.pot` file.
- CI: `qmllint` and a `plasmoidviewer` smoke test.
- Multi-monitor: one config per dock, tested.
- Auto-hide and dodge-windows setting.
- KDE Store release: version bump, current description in `metadata.json`, `.plasmoid` built on tag.
- Detect the battery sensor without settings.

## Order

Phase 1 first, then Phase 2 (data is mostly wired), then Phase 3 one module at a time. Phase 5 CI can run in parallel.
