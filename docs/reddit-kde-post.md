# r/kde post

Images: `docs/screenshots/desktop.png` and `docs/screenshots/dock.png`. Use the real screenshots, not the animated reel, which is a mock-up.

## Title

```text
I made Dockyard, a dock plasmoid for Plasma 6 with optional tiles (clock, media, todos, weather and more)
```

## Body

```text
Hi r/kde,

I built a dock as a Plasma 6 plasmoid and wanted to share it. It runs inside plasmashell, so there is no extra process, and you add it to a panel from Add Widgets.

Each feature is its own tile, and you turn on only the ones you want:

- Start tile with a launcher (Meta opens it, and it does quick maths in the search box)
- Pinned apps with running dots, plus Meta+1 to Meta+9 to open or switch to them
- Now playing (MPRIS), volume, battery, weather
- Clock, world clocks, calendar, Pomodoro, timer, stopwatch
- Todos and notes (several notes in one tile)
- CPU, memory, network speed, temperature, storage
- Quick toggles for Wi-Fi, Bluetooth, Do Not Disturb and Night Light, with a flyout to connect to networks
- Clipboard history on Meta+V

Each tile opens its own popup over the tile you tapped. It also ships with a glass Plasma style, but it works with any theme.

I'm on Plasma 6.8.2 (Wayland, CachyOS). I haven't tested other Plasma versions or X11, so tell me if something breaks.

One thing to know: it uses a few private Plasma APIs (MPRIS, brightness control and the notification manager), so a Plasma update can break it.

Source and install steps: https://github.com/aryansoni57/dockyard

I'd like feedback, and ideas for tiles I should add.
```

## Before posting

- Read the sidebar rules first; they were not checked.
- If the subreddit asks for a flair, pick the one for your own project or a Plasma widget.
- Post the two screenshots as a gallery, with `desktop.png` first.
- Reply to comments in the first hour or two, since that helps the post.
