# r/unixporn post

Images: `docs/screenshots/desktop.png` (full desktop, 1920x1080) and `docs/screenshots/dock.png` (the dock, close up).

## Title

```text
[KDE] Dockyard: a glass dock plasmoid for Plasma 6 with 26 optional tiles
```

Flair: pick the screenshot flair that matches the post type in the submit form. Check the sidebar rules before posting.

## Top-level comment (post this right after submitting)

```text
**Dockyard** is a dock I wrote as a plasmoid for KDE Plasma 6. It runs inside plasmashell, so there is no extra process. Every tile is optional.

Repo, install steps and changelog: https://github.com/aryansoni57/dockyard

**Details**

- Distro: CachyOS, kernel 7.3.1-1-cachyos
- Session: Plasma 6.8.2 on Wayland, Qt 6.12.0, KWin 6.8.2
- Display: 1920x1080 laptop panel at 125% scale
- Dock: Dockyard (`dev.aryan.dock`), in the repo
- Plasma style: `glass`, also in the repo (`theme/glass`)
- Application style: Kvantum, Utterly-Nord
- Window decorations: Willow Dark (Aurorae)
- Icons: Tela-dark
- Cursor: capitaine-cursors
- Wallpaper: Iron Man red glow, 3440x1440
- Desktop widgets: Petik clock (`com.Petik.clock`), Vector Clock (`org.zayronxio.vector.clock`), NowPlaying (`org.ruiny.NowPlaying`)

**Tiles in the dock, left to right**

Start, now playing, pinned apps with running dots, quick toggles (Wi-Fi, Bluetooth, Do Not Disturb, Night Light), volume, weather, notes, todos, clock, tray, battery.

The full list also has system stats, Pomodoro, timer, stopwatch, world clocks, temperature, network speed, storage, calendar, month/day/year progress, date, recycle bin, screenshot and more clock styles.

**Other things it does**

- Meta opens a launcher with search. It also does maths: type `12*8` and Enter copies the answer.
- Meta+1 to Meta+9 open or switch to the dock apps, left to right.
- Meta+V opens clipboard history.
- Each tile opens its own popup over the tile you tapped.
- Todos can be completed, restored and deleted. Notes keeps several notes in one tile.
- Wi-Fi networks can be connected, disconnected and forgotten from the quick settings flyout.

Install:

    git clone https://github.com/aryansoni57/dockyard
    cd dockyard
    ./install-all.sh --apply-theme

It depends on some private Plasma APIs, so it can break between Plasma releases. Feedback and tile ideas are welcome.
```

## Before posting

- `desktop.png` shows the game launchers on the right edge of the desktop and the Notes tile text ("Workick implem..."). Crop or clear them if you don't want them shown.
- The font is whatever your system default resolves to (Noto Sans). It wasn't set in `kdeglobals`, so it's left out of the details.
- The three desktop widgets are listed by plugin id. Replace them with their display names if you know them.
- Post the images as a gallery: `desktop.png` first, `dock.png` second.
