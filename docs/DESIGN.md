# Dockyard Settings: design

The settings app (`settings/`) uses two planes:

- **Glass rail** (left): translucent, on KWin blur-behind with a faint ribbon backdrop. It holds navigation only.
- **Solid deck** (right): one opaque rounded surface (`Theme.deck`, 20 px radius, 8 px off the window edge). All content sits on it, and embedded System Settings modules render straight onto it, because the colour scheme we hand them (`KcmModel.applyScheme`) uses the same deck colour.

## Layout

- **Rail**, 264 px: brand mark, a search field that opens the palette, Overview, *Quick settings* (our six pages, each with a live readout such as volume or SSID), *System Settings* (categories from `KcmModel.groups`), and a Night/Day/Auto switch. It collapses to a 68 px icon rail with tooltips when the window is narrower than 940 px, or with Ctrl+\\. A selection pill glides between rows.
- **Overview**: greeting and host, four quick tiles (Wi-Fi, Bluetooth, Night mode, power profile), volume and brightness, *This computer* (CPU, memory, storage, Plasma and kernel, uptime), *Recently opened*, and every category.
- **Pages** (`Sheet`): an icon chip, a 28 px title and a summary line, header actions, then titled `Card` groups of `SettingRow`s. Content is at most 800 px wide (920 for category pages, 980 for Overview).
- **Category page**: modules grouped by their System Settings sub-category, in two columns when wide.
- **Module page**: back arrow, breadcrumb (category › sub-category), module icon and title, and an "open in a separate window" button. The module fills the deck. An Apply bar (Defaults · status · Reset · Apply, with a lock icon when the change needs authorisation) tints with the accent while there are unsaved changes. There is a skeleton while loading and an error state with Retry.
- **Search palette** (Ctrl+K, Ctrl+F, /): recent pages when empty, otherwise Dockyard matches then System Settings modules (ranked in C++). Up/Down move, Enter opens.

## Tokens (`Theme.qml`)

- **Colour**: night and day sets with a slight plum tint: `glass`, `deck`, `card`, `cardHi`, `raise`, `well`, hairlines (`line`, `cardRim`, `wellRim`), `hover`/`press`, ink at 100/70/50/32 %, and `ok`/`neutral`/`bad`. Auto switches at 07:00 and 19:00.
- **Accent**: user-picked (8 swatches). `accentFg` is chosen by luminance for text on fills, `accentInk` is lifted at night and deepened by day for text on surfaces, and `accentSoft`/`accentLine` are tints.
- **Type**: 11 overline, 12 caption, 13 control, 14 label, 16 card/dialog title, 20 module title, 28 page title, 34 greeting. Tabular figures for values.
- **Spacing**: 4 px grid (`s1`…`s10`). **Radii**: 7 small, 10 controls, 16 cards, 20 deck.
- **Motion**: 120/180/280 ms ease-out (`fast`, `dur`, `slow`). All motion is off when Plasma animations are off (`Kirigami.Units.longDuration`).
- **Icons**: one line set in `settings/icons` (24 px grid, 1.8 px round stroke), tinted through `Ico`. Module icons from the icon theme stay in full colour.

## Components

`Ico`, `Chip`, `Btn` (secondary, primary, quiet, danger; optional icon), `IconBtn`, `Toggle`, `Slide`, `Segmented` (sliding thumb, icon segments, stretch), `Combo`, `Card`, `SettingRow` (icon, caption, value, clickable with chevron), `Meter`, `EmptyState`, `Skeleton`, `Toast`, `Tip`, `Kbd`, `FocusRing` (2 px accent ring on keyboard focus), `Scroller`, `SearchPalette`, `Status` (live readouts).

## Deep links

`dockyard-settings kcm_<id>` · `dockyard-settings sound` (any quick page) · `group:<id>` · `search:<text>`.
