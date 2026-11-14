# Dockyard Day theme set

The light counterpart of the dark Dockyard set. The dock's Day and night look (Settings, System) switches between the two at sunrise and sunset. `theme/gen.py` writes both sets from one script; the Day values sit in its `if DAY:` blocks. The dark tokens are in `docs/mockups/theme-desktop-tokens.md`; the light values follow the light theme in `docs/mockups/dockyard-dashboard.html` and the "Light styles" column of `docs/STYLE.md`.

## Files

| Output | Path | Notes |
| --- | --- | --- |
| Plasma theme, frosted | `theme/glass-day/` | Light glass for popups, notifications, tooltips and panels. Same 9-slice frames, radii and blur masks as `glass` |
| Plasma theme, solid | `theme/glass-day-opaque/` | Every surface at 0.96, for the Opaque dock bar switch |
| Plasma theme, islands | `glass-day-islands` (built at runtime) | `layout-theme.sh islands` copies the installed `glass-day` and clears the panel background, as it does for `glass` |
| KDE color scheme | `theme/color-schemes/DockyardDay.colors` | All groups plus `[WM]` and `[Colors:Header][Inactive]` |
| Kvantum, solid windows | `theme/kvantum/DockyardDay/` | Glass menus and tooltips |
| Kvantum, translucent windows | `theme/kvantum/DockyardDayGlass/` | `translucent_windows=true` |
| Aurorae decoration | `theme/aurorae/DockyardDay/` | Light titlebar, ink buttons, full-height flush close button that turns red with a white glyph |
| Look-and-feel | `theme/look-and-feel/dev.aryan.dockyard.day/` | Selects DockyardDay, glass-day, Kvantum style and the DockyardDay decoration. Light splash. No icons, cursor or layout |
| Contrast check | `theme/contrast.py` | Checks every text color on every surface; exits 1 on a failure |

## Color

| Token | Value | Used for |
| --- | --- | --- |
| Plasma glass fill | `#F8F8FB` | Every Plasma surface; matches the mockup's light panel `rgba(248,248,251,.8)` |
| Glass alpha: dialogs, widgets | `0.82` | `dialogs/background.svg`, `widgets/background.svg` |
| Glass alpha: panel | `0.78` | `widgets/panel-background.svg` |
| Glass alpha: tooltip | `0.88` | `widgets/tooltip.svg`. The dark set's tooltip is nearly clear; dark ink needs a denser ground |
| Glass alpha: no blur / solid | `0.94` / `0.96` | Base and `opaque/`, `solid/` fallbacks |
| Rim | black at 10% | 1 px edge on every glass surface (dark: white at 14%) |
| Window | `#EFF0F4` | `[Colors:Window]`, Kvantum `window.color` |
| View | `#FFFFFF`, alternate `#F4F5F8` | Lists and text areas |
| Header (title bar) | `#E6E7ED`, inactive `#EFF0F4` | `[Colors:Header]`, `[WM]`, Aurorae |
| Button | `#FFFFFF`, alternate `#F6F7FA` | Raised white controls |
| Line | `#D5D7DF` | Kvantum `mid.color` |
| Window edge | `#C4C6CF` | Aurorae 1 px side and bottom border |
| Ink | `#1C1C1E` | Primary text everywhere |
| Ink 2, apps | `#5C5E66` | `ForegroundInactive` in the color scheme |
| Ink 2, Plasma glass | `#4B4D55` | `ForegroundInactive` in `glass-day/colors`; darker so it passes on glass over a black wallpaper |
| Accent | `#0A7AFF` | Focus rings, checked boxes and radios, slider fill, progress, `DecorationFocus` |
| Accent as text | `#0058C4` | `ForegroundActive` |
| Selection | `#0064D6` | Selection, menu highlight, selected rows; white text on it is 5.5:1 |
| Link / visited | `#0058C4` / `#8A3FB5` | |
| Negative / neutral / positive | `#C8102E` / `#9A4A00` / `#157030` | Darker than the dark set's system hues so they pass as text |
| Complementary | `#16161A`, white ink | Stays dark, as in Breeze Light |
| Close hover | `#E0242E`, pressed `#B81D26` | White glyph, 4.7:1 |
| Window shadow | rgb(24,26,48), peak 26% active, 15% inactive | Cooler and softer than the dark set's black 38% |

## Controls (Kvantum)

Same radii and spacing as the dark set: buttons, combos and line edits 10 px, tabs 8 px, frames 12 px, menus 12 px, tooltips 10 px, rows and menu items 6 px, scrollbar 4 px.

| Element | Normal | Hover | Pressed | Toggled |
| --- | --- | --- | --- | --- |
| Button, combo | white, rim 13% | rim 22% | `#E6E8EE`, rim 18% | accent 16%, accent rim 60% |
| Line edit | white, rim 14% | | | accent rim 85% when focused |
| Tab | clear | black 4% | black 7% | white, rim 10% |
| Row (item view) | clear | black 5% | selection, white text | selection, white text |
| Menu item | clear | selection, white text | | |
| Menu / tooltip | glass 88% / 90%, rim 12% | | | |
| Scrollbar | black 28% | 45% | 50% | |
| Slider groove / progress track | black 12% / 10% | | | accent fill |
| Checkbox, radio | white, rim 32% | rim 48% | | accent with white mark |
| Slider knob | white with a 22% ring | 32% ring | | |

## Contrast

`python3 theme/contrast.py` checks every `Foreground*` key against `BackgroundNormal` and `BackgroundAlternate` in every group of both color files (AA, 4.5:1), the decoration colors against their ground (3:1), and the `[WM]` title colors. It also checks ink and secondary ink on each translucent surface composited over black and over white. All 314 checks pass. The lowest text results are 4.55:1 (accent on the dark Complementary group), 4.63:1 (secondary ink on a Kvantum menu over black) and 4.69:1 (secondary ink on the frosted panel over black).

## Install and apply

```sh
python3 theme/gen.py                       # writes the dark and Day sets
theme/install-global.sh --no-apply         # copies both sets (and glass-day, glass-day-opaque)
./install-all.sh --no-restart              # plasmoid plus all four glass Plasma themes
theme/install-global.sh --day              # apply the Day set globally (first run saves a baseline)
theme/install-global.sh                    # apply the dark set globally (same as before)
theme/restore-global.sh                    # back to the setup saved before Dockyard
sh package/contents/scripts/day-night.sh DockyardDay   # switch a Dockyard desktop to Day
sh package/contents/scripts/day-night.sh Dockyard      # and back
```

`day-night.sh` applies the color scheme. When the scheme is `Dockyard` or `DockyardDay` it also swaps the Plasma theme (keeping frosted, opaque or islands), the Kvantum theme (keeping solid or translucent windows) and the Aurorae decoration, each only when a Dockyard one is active. If `DockyardDay` is not installed it falls back to `BreezeLight`. Open Qt apps pick up a new Kvantum theme only after a restart.
