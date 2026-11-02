# Dock Style Reference

Nov 2, 2026 · @Aryan · Live doc: https://claude.ai/artifact/RRnbwdGRhryYz2gdvK77JD

## Sources

Values below were sampled from reference screenshots of a similar dock: pixel values from the transparent per-widget tiles, layout values estimated. Use it as a reference for our own design, not a spec to copy.

## Dock shape and layout

The dock is one rounded glass bar that holds a row of separate rounded tiles. Each widget is its own tile, and app icons sit loose between tiles with no tile behind them.

- **Two widths.** Pill: hugs its content, centered, with screen showing on both sides. Full-width: runs edge to edge with the same corner radius.
- **Position.** Bottom by default. At the top, popups open downward (for-founders shot).
- **Margin.** It floats about 6–8 px off the screen edge, never flush.
- **Height.** About 1 icon + 10 px. Tiles fill the bar height minus about 4 px of padding top and bottom.
- **Corner radius.** The bar uses about 25% of its height. Tiles use about 24% of theirs (36 px on a 148 px tile image). The two are close, so tiles look concentric with the bar.
- **Gap.** About 4–6 px between tiles. There are no divider lines; the gaps are the dividers.
- **Order** (left to right in every example): data tiles (streaks, AI usage, revenue), then the app icon group in the middle, then more data tiles, then the clock tile pinned at the far right.
- **Tile widths vary by content:** a square for battery and the clock; 2–3× height for stats; 4–6× height for sparkline and media tiles.
- **App icons.** Native full-color app icons at about 70% of bar height. A 4 px accent-blue dot under the icon marks a running app; there is no dot when the app is pinned only.
- **Edit mode** (demo-poster): every tile gets a red circular minus badge on its top-right corner.

## Glass material

The glass has two layers: a bar that blurs and bends the wallpaper, and very faint tiles on top that mostly just add an edge. Tile values below were sampled from the transparent tile images; bar values are estimated from screenshots.

| Layer | Dark styles | Light styles |
| --- | --- | --- |
| Tile fill | white at 5.5% alpha (`#FFFFFF0E`) | black at 4.3% alpha (`#0000000B`) |
| Tile border, about 2 px | white at 13–14% (`#FFFFFF23`) | black at 8–9% (`#00000016`) |
| Tile top edge | brighter: white at 13–15%, a top-lit highlight | same as the sides |
| Bar fill | dark tint, about 40–60% over the blur | white, about 70–85% |
| Bar edge | 1 px light rim, brightest on top | 1 px dark rim, about 8% |

- **Blur.** Strong, on the order of 20–30 px: wallpaper shapes under the bar become soft color fields.
- **Refraction.** On the Glass and iOS Glass styles, wallpaper edges near the bar's rounded ends curve with the glass, like a lens. A flat blur doesn't do this; it needs a displacement shader.
- **Shadow.** Very soft and low: about 0 4px 16px black at 20–30%. Popups use a stronger one.
- **Tiles never use opaque backgrounds,** except the clock tile and colored status tiles (see Themes).

## Themes and color

The page names six styles but shows five. Across all of them only the bar changes; tile layout, icons and accents stay the same.

| Style | Bar | Text |
| --- | --- | --- |
| Glass | Dark smoky glass, wallpaper visible, refraction on | White |
| iOS Glass | Clearer glass, more wallpaper color shows through | White |
| White | Near-opaque frosted white | Near-black |
| Midnight | Deep navy tint, low transparency | White |
| Black | Almost opaque black | White |

**Text colors**

- Primary: pure white (dark) or `#1C1C1E`-ish near-black (light).
- Secondary labels ("today", "week", "followers", "CPU"): the primary color at about 55–60% opacity.
- Tertiary text (popup timestamps, footers): about 40%.

**Accents** (Apple-style system colors)

| Use | Color |
| --- | --- |
| Rings, selection, running-app dot, links | Blue, about `#0A84FF` |
| Up deltas, sparklines, Stripe chart | Green, about `#30D158` |
| Focus timer outline and button, clock tile header | Red, about `#FF3B30` |
| Time badges in Todos | Amber |
| Calendar legend | Purple, green, blue, indigo, orange and cyan dots |

- **Fixed-color tiles:** the clock tile is always a red top band (time) over a black bottom (day and date), plus a gray weather circle. The battery tile is a solid blue gradient with a wavy fill line at the charge level.
- **Third-party logos keep their brand color** (Stripe purple, Claude orange, X black). They are the only saturated color in most tiles.

## Typography

Type is a single neo-grotesque sans in two weights, and contrast comes from size and opacity rather than color. The reference uses Segoe UI Variable for app UI and SF Pro Display for marketing. On KDE the closest choices are Inter or the system default.

| Role | Size, relative to bar height | Weight | Example |
| --- | --- | --- | --- |
| Hero number | About 40% | Bold (700) | `$2,980`, `25:00`, `12.5K`, `8,214` |
| Clock tile time | About 30% | Semibold | `15:09` |
| Label | About 18–20% | Medium (500) | "Net revenue", "Session" |
| Caption | About 15% | Regular at 55% opacity | "followers", "visitors · 7 days" |
| Popup row | 13–14 px | Regular, value right-aligned | "Last 7 days ... $2,980" |
| Popup section header | 11 px, uppercase, tracked | Semibold at 50% opacity | "USAGE", "NET REVENUE" |

- **Numbers** use tabular figures so values don't jiggle as they update. Units are compact (`41.8K`, `5h 48m`), and deltas carry a small triangle (`▲ 31%`) in green.
- **Pairs.** Most tiles stack a big number over a small caption, left-aligned; ring tiles center the number and label inside the ring.
- **No all-caps in tiles.** Uppercase appears only in popup section headers and calendar weekdays.

## Icons and widget content

Every tile follows one pattern: an optional brand mark on the left, the number, then a tiny visual on the right. The tile anatomies seen:

| Tile type | Layout | Examples |
| --- | --- | --- |
| Ring | One or two circular gauges, number and label centered inside. Track: primary at 15%. Arc: blue, about 10% of the ring diameter thick, round caps, starting at 12 o'clock. | CPU/RAM, Screen Time count |
| Sparkline | Label top-left, value top-right, delta under the value, smooth 1.5 px line across the bottom with a dot at the latest point | Net revenue, Visitors |
| Brand stat | Rounded-square brand logo (about 70% of tile height), big number, caption below | X followers, Gmail unread, Linear assigned |
| Progress bars | Label + reset time + percent on one row, thin 3 px bar below (green, track at 15%) | Claude session/weekly usage |
| Heatmap | Header row of stats, then a 3 × 13 grid of rounded 4 px squares in 4 green shades on a gray base | GitHub streaks |
| Control | Pill buttons (circle, about 75% of tile height) at 10–15% fill; active ones in blue at 20% with a blue border | Quick toggles, media controls |
| Media | Album art in a rounded square, title + artist, prev/play/next. Play is a filled blue circle; the others are flat. Thin progress line under the tile | Now playing |
| Status color | Whole tile one solid color | Battery (blue with a wave), clock (red over black) |

- **System icons** are thin, monoline, rounded (SF Symbols-like), in the text color. App icons are full color.
- **Charts** have no axes, grid lines or labels in the dock; detail lives in the popup.

## Popups and panels

Clicking a tile opens a popup that is opaque, not glass, and shares the dock's color scheme. It floats just above (or below, when docked on top) the tile's left edge, with about 8 px clearance.

- **Size and shape.** About 260–300 px wide, corner radius about 14 px, background `#1C1C1E` dark or `#FFFFFF` light, strong soft shadow (about 0 12px 40px black at 40%).
- **Header row.** Brand logo (24 px rounded square) + name + a small gray pill tag (plan name or account, e.g. "Max 5x", "Northwind Goods") + a close × on the right.
- **Body.** Grouped list sections. Each section has an uppercase 11 px header on a slightly darker band, then rows about 32–36 px tall with a label on the left, a value on the right, and hairline dividers at about 6% opacity.
- **Emphasis.** The key row's value is bold white; other values are gray at 60%.
- **Charts in popups** fill the width, still without axes, under a section header like "LAST 14 DAYS".
- **Footer.** Small gray note on the left ("Your key stays on this PC · every 5 min") and a secondary pill button on the right ("Refresh", or red-tinted "Disconnect").
- **Large panels** (calendar, widget gallery) use the same surface at 20–24 px radius, with inner cards in a second surface step (about `#2C2C2E` dark). Day cells are rounded squares; today gets a 2 px blue outline and blue number.
- **Inputs** at the bottom of a panel are pill-shaped fields with a round + button.

## Motion

The static images show almost no motion; the site's demo video was not reviewed. Treat these as suggested values for our build, not observations:

| Interaction | Suggested motion |
| --- | --- |
| Hover on a tile | Fill alpha +4%, 120 ms ease-out. No scale. |
| Press | Scale 0.97, 80 ms |
| Popup open | Fade + 6 px slide from the dock side + scale from 0.98, 180 ms ease-out |
| Popup close | Fade only, 120 ms |
| Value change | Count up over 400 ms with tabular figures, so width stays stable |
| Ring / bar change | Animate the arc length, 300 ms ease-in-out |

To keep idle cost near zero, nothing animates while the user isn't interacting, except the progress line on media and the focus timer's seconds.

## Mapping to our Plasma 6 plasmoid

Most of the look is reachable in plain QML inside `plasmashell`. Only true refraction needs work outside the plasmoid.

| Element | How to get it in Plasma 6 |
| --- | --- |
| Pill / full-width bar | Panel settings: Floating, width "Fit content" (pill) or "Fill width" (full) |
| Bar blur | KWin Blur effect, on by default for translucent panels. Strength in System Settings → Desktop Effects → Blur |
| Bar tint and radius | Plasma Style (panel background SVG), or `Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground` + our own `Rectangle` behind a transparent panel |
| Tile | `Rectangle { radius: height * 0.24; color: Qt.alpha(Kirigami.Theme.textColor, 0.055); border.width: 1; border.color: Qt.alpha(Kirigami.Theme.textColor, 0.13) }` |
| Gaps and padding | `Kirigami.Units.smallSpacing` (4 px) between tiles, `largeSpacing` (8 px) inside |
| Text opacities | Primary `Kirigami.Theme.textColor`; secondary with `opacity: 0.6`; tertiary `0.4` |
| Accents | `Kirigami.Theme.highlightColor` for blue; `positiveTextColor`, `negativeTextColor` and `neutralTextColor` for green, red and amber, so they follow the user's color scheme |
| Numbers | `font.features: { "tnum": 1 }` for tabular figures |
| Rings | `Shape` + `PathAngleArc` with `capStyle: ShapePath.RoundCap` |
| Sparklines | `Shape` with a `PathPolyline`, or `Canvas`; redraw only when data changes |
| Popup | `fullRepresentation`. Plasma draws the dialog chrome; style the inside with grouped `ColumnLayout` sections |
| Motion | `Behavior on opacity/scale` with `Kirigami.Units.shortDuration` (about 150 ms) and `longDuration` |
| Refraction | Not available in QML. Needs a custom KWin effect (C++ + GLSL displacement shader) applied to the panel window. Treat it as a separate later project |

Light and dark styles come free: every color above comes from `Kirigami.Theme`, so the tiles flip with the user's color scheme.
