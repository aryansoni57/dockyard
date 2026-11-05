# Reel source

Source for `docs/dockyard-reel.mp4` (1080 × 1920, 30 fps). The shot list is in `docs/storyboard-reel.md`.

- `reel.html`: the whole scene. `render(t)` draws the frame at `t` seconds, with no CSS transitions, so every frame is exact. Open it in a browser and call `render(5)` in the console to look at a moment.
- `icons.js`: the SVGs in `assets/` as data URIs. CSS masks don't load `file://` SVGs, so the tile icons come from here. Rebuild it with `python3 docs/reel/build-icons.py` after changing an SVG.
- `render.mjs`: drives headless Chromium and pipes frames to ffmpeg.
- `assets/`: Inter, the dock's own icons from `package/contents/icons`, and app icons copied from the system icon theme.

## Render

Needs Node, ffmpeg, `playwright-core` and a Playwright Chromium.

```bash
PLAYWRIGHT_CORE=/path/to/node_modules/playwright-core/index.mjs node docs/reel/render.mjs video docs/dockyard-reel.mp4
```

Check single frames before a full render:

```bash
PLAYWRIGHT_CORE=/path/to/node_modules/playwright-core/index.mjs node docs/reel/render.mjs stills 3.6,13.4,22.6 /tmp
```

## Edit

- Tiles: the `TILES` array (width, caption, HTML). Order on the dock is array order.
- Montage panels: the `panel(...)` calls.
- Timing: `T0`, `STEP`, `FALL`, `MDUR` under "timing".
- Camera: `FAR`, `TRK`, `OVER`, `ENDC` and `cam(t)`.
