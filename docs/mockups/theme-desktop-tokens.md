# Glass desktop theme tokens

Source of truth: the `:root` block at the top of `docs/mockups/theme-desktop.html`. Values match the dock plasmoid (`package/contents/ui/components/Tile.qml`, `RingGauge.qml`, `main.qml`, `docs/STYLE.md`) and the glass-notify Plasma style (`~/.local/share/plasma/desktoptheme/glass-notify/dialogs/background.svg`).

Plasma file paths are relative to the theme folder (`~/.local/share/plasma/desktoptheme/<name>/`), except `colors`, which can also ship as a full color scheme in `~/.local/share/color-schemes/`.

## Color

| Token | Value | Used for | Plasma target |
| --- | --- | --- | --- |
| `--accent` | `#0A84FF` (rgb 10,132,255) | Rings, slider fill, active toggles, running dot, Kvantum focus ring | `colors`: `[Colors:Selection] BackgroundNormal`, `[Colors:View] DecorationFocus`, `DecorationHover`, `[Colors:Window] ForegroundActive`; Kirigami `highlightColor` |
| `--select` | `#0071e3` | Selection, primary buttons. White text on it passes AA (4.7:1). `#0A84FF` gives 3.65:1, so it is for rings only | `colors`: `[Colors:Selection] BackgroundNormal`; Kvantum `highlight.color`, `menuitem` |
| Accent presets | Indigo `#5E5CE6`, Purple `#BF5AF2`, Pink `#FF375F`, Orange `#FF9F0A`, Green `#30D158`, Cyan `#64D2FF` | Tweaks panel | Same keys as `--accent`; one `colors` file per variant |
| `--glass-rgb` | `#16161A` (rgb 22,22,26) | Fill of every glass surface | `colors`: `[Colors:Window] BackgroundNormal`, `[Colors:Tooltip] BackgroundNormal`, `[Colors:View] BackgroundNormal`; SVG `fill` in all background SVGs |
| `--glass-a` | `0.62` | Dialogs, notifications, OSD, tooltip | `fill-opacity="0.62"` in `dialogs/background.svg`, `translucent/dialogs/background.svg`, `widgets/tooltip.svg`, `translucent/widgets/tooltip.svg` |
| `--bar-a` | `0.55` (glass-a minus 0.07) | Top panel, dock bar | `fill-opacity="0.55"` in `widgets/panel-background.svg`, `translucent/widgets/panel-background.svg`; matches dock bar `Qt.alpha(backgroundColor, 0.55)` |
| `--well` | `rgba(0,0,0,.18)` | Recessed launcher rail | Plasmoid QML only (`LauncherPanel.qml` rail) |
| `--rim` | `rgba(255,255,255,.14)` | 1 px border on every glass surface | Stroke `#ffffff` `stroke-opacity="0.14"` in the four background SVGs |
| `--rim-top` | `rgba(255,255,255,.08)` | Top-lit highlight line on panels and tiles | Extra 1 px line in the `top` element of `widgets/panel-background.svg`; `Tile.qml` highlight |
| `--tile` | `rgba(255,255,255,.055)` | Dock tile fill | `Tile.qml` (`Qt.alpha(textColor, 0.055)`) |
| `--tile-hover` | `rgba(255,255,255,.095)` | Tile and row hover | `Tile.qml` hover; `colors` `[Colors:Button] BackgroundAlternate` approx |
| `--tile-rim` | `rgba(255,255,255,.13)` | Dock tile border | `Tile.qml` border |
| `--hairline` | `rgba(255,255,255,.08)` | Dividers inside dialogs | `widgets/line.svg` (stroke `#ffffff`, opacity 0.08) |
| `--control` | `rgba(255,255,255,.12)` | Round buttons, pills, search field | `widgets/button.svg` / `widgets/lineedit.svg` fill; `colors` `[Colors:Button] BackgroundNormal` = `#3D3D40` (flattened over glass) |
| `--control-hover` | `rgba(255,255,255,.17)` | Hovered controls | `widgets/button.svg` `hover-*` elements |
| `--ink` | `#FFFFFF` | Primary text | `colors`: `ForegroundNormal` in Window, View, Button, Tooltip, Complementary |
| `--ink-2` | `rgba(255,255,255,.60)` = `#A2A2A3` flattened | Subtitles, captions | `colors`: `ForegroundInactive` |
| `--ink-3` | `rgba(255,255,255,.40)` = `#737376` flattened for glyphs; text uses `#8E8E93` (AA on glass) | Timestamps, close glyphs, section headers | `colors`: `[Colors:View] ForegroundInactive` alt; QML `opacity: 0.4` |
| `--track` | `rgba(255,255,255,.15)` | Ring and bar tracks | `widgets/slider.svg` groove, `widgets/bar_meter_horizontal.svg` bar-inactive |
| `--red` | `#FF3B30` | Clock band, storage, destructive | `colors`: `ForegroundNegative`; `ClockModule.qml` |
| `--green` | `#30D158` | Positive deltas | `colors`: `ForegroundPositive` |
| `--orange` | `#FF9F0A` | Warnings | `colors`: `ForegroundNeutral` |
| `--yellow` | `#FFCC00` | Notes stripe | `NotesModule.qml` only |
| `--black-tile` | `#000000` | Clock tile lower half | `ClockModule.qml` only |

## Material

| Token | Value | Plasma target |
| --- | --- | --- |
| `--blur` | `28px` | KWin Blur effect strength (System Settings, Desktop Effects, Blur). Blur only shows when the SVG has a `mask-*` set, as `dialogs/background.svg` already does |
| `--saturate` | `160%` | Not available in KWin blur; the KWin "Contrast" effect is the closest. Mockup only |
| `--shadow-panel` | `0 4px 16px rgba(0,0,0,.25)` | `shadow-*` elements in `widgets/panel-background.svg` |
| `--shadow-dialog` | `0 16px 48px rgba(0,0,0,.38), 0 2px 8px rgba(0,0,0,.18)` | `shadow-*` elements in `dialogs/background.svg` (glass-notify has none yet; KWin draws its own) |
| `--shadow-tip` | `0 6px 18px rgba(0,0,0,.32)` | `shadow-*` in `widgets/tooltip.svg` |

## Radius

| Token | Value | Used for | Plasma target |
| --- | --- | --- | --- |
| `--r-xs` | `6px` | Small chips, kbd hints | Mockup only |
| `--r-sm` | `10px` | Tooltip, launcher rail rows, power buttons | Corner arcs in `widgets/tooltip.svg` (r=10); `LauncherPanel.qml` `railRadius` |
| `--r-md` | `12px` | Dock tiles (24% of 48), top panel | Corner arcs in `widgets/panel-background.svg` for a 36 px panel; `Tile.qml` `height * 0.24` |
| `--r-lg` | `14px` | Dock bar (25% of 56), search field, result rows | `main.qml` dock `height * 0.25`; `widgets/lineedit.svg`; `LauncherPanel.qml` `pillRadius` |
| `--r-xl` | `20px` | Dialogs, notifications, OSD | Corner arcs in `dialogs/background.svg` (already r=20 in glass-notify) |
| `--r-pill` | `999px` | Pills, sliders, round toggles | `widgets/button.svg` rounded |

## Spacing

| Token | Value | Kirigami |
| --- | --- | --- |
| `--s1` | `4px` | `Units.smallSpacing`, gap inside the dock bar |
| `--s2` | `8px` | `Units.largeSpacing`, panel margin from screen edge, popup clearance |
| `--s3` | `12px` | Dialog padding |
| `--s4` | `16px` | Screen margin for notifications |
| `--s5` | `24px` | Large gaps |
| `--gu` | `18px` | `Units.gridUnit`; launcher is 38 x 24 gu (684 x 432) |

Fixed sizes: dock bar 56 px, tile 48 px, bar padding 4 px, tile gap 5 px, tile padding 14% (7 px), app icon 72% of tile, running dot 4 px. Top panel 36 px. Notification width 392 px.

The margins in the background SVGs set content padding: use `hint-left-margin` etc. at 12 px for dialogs and 8 px for tooltips.

## Type

| Token | Value | Use |
| --- | --- | --- |
| `--font` | Inter, then Noto Sans | System font in System Settings, Fonts |
| `--t-xs` | `11px` | Uppercase section headers (600, +0.06em), tile captions |
| `--t-sm` | `12px` | Tile labels, tooltip subtitle |
| `--t-md` | `13px` | Body, notification subtitle, rows |
| `--t-lg` | `14px` | Notification and dialog titles (700) |
| `--t-xl` | `17px` | Tile hero numbers (700) |
| Weights | 400 / 500 / 600 / 700 | |

Numbers always use tabular figures (`font-feature-settings: "tnum"` / QML `font.features: { "tnum": 1 }`).

## Motion

| Token | Value | QML |
| --- | --- | --- |
| `--t-color` | `120ms cubic-bezier(.2,.7,.3,1)` | `ColorAnimation { duration: 120; easing.type: Easing.OutCubic }` |
| `--t-press` | `80ms ease-out` | Press scale 0.97 (`Tile.qml`) |
| `--t-open` | `180ms cubic-bezier(.2,.8,.2,1)` | Popup fade + 6 px slide + scale from 0.98 |

## Porting checklist

1. Copy `glass-notify` to a new theme folder. Its `dialogs/background.svg` already holds `--glass-rgb`, `--glass-a`, `--rim` and `--r-xl`.
2. Add `widgets/panel-background.svg` with the same 9-slice layout, fill opacity `0.55`, corner radius 12, plus the `--rim-top` line in the `top` element.
3. Add `widgets/tooltip.svg` with fill opacity `0.62` and radius 10.
4. Write `colors` with the keys listed under Color (flatten alpha values over `#16161A` where a solid color is required).
5. Keep the `mask-*` elements in every SVG so KWin blurs behind them.

## Kvantum, Aurorae and look-and-feel

`theme/gen.py` writes these from the same values as the Plasma theme and the color scheme:

| Output | Path | Notes |
| --- | --- | --- |
| KDE color scheme | `theme/color-schemes/Dockyard.colors` | Plasma `colors` groups plus `[WM]` window colors |
| Kvantum, solid windows | `theme/kvantum/Dockyard/` | Default app style. Menus and tooltips are glass (`popup_blurring`) |
| Kvantum, translucent windows | `theme/kvantum/DockyardGlass/` | Same widgets, `translucent_windows=true`, `reduce_window_opacity=40` |
| Aurorae decoration | `theme/aurorae/Dockyard/` | 34 px titlebar, `#1e1e23`, inactive `#1a1a1f`, monochrome buttons, close hover red, shadow in the padding |
| Look-and-feel | `theme/look-and-feel/dev.aryan.dockyard/` | Defaults select the color scheme, Kvantum style, Aurorae and the glass Plasma theme. Own splash. No icons, cursor, font or layout |

Install and apply with `./install-all.sh --apply-global`. The first run saves your style, color scheme, decoration, look-and-feel, icons, cursor, Kvantum theme, Plasma theme and `~/.config/kdedefaults` to `~/.local/state/dockyard/baseline`. Later runs keep that baseline. `theme/restore-global.sh` puts it all back without running `plasma-apply-lookandfeel`, which would also reset icons, cursor and wallpaper.

Use `library=org.kde.kwin.aurorae`, not `.v2`. The v2 plugin draws this theme offset from the client. KWin keeps a loaded Aurorae theme until the decoration changes, so the installer steps through Breeze to reload it.

The look-and-feel ships its own splash. Lock screen, logout and OSD fall back to Breeze. It cannot select a Kvantum theme, so install through the script.

The Opaque dock bar switch also swaps the Kvantum theme, between `Dockyard` (opaque) and `DockyardGlass` (frosted), but only while Dockyard is the app style.
