# Dockyard Glass window decoration

A native KDecoration3 plugin (`org.dockyard.glass`) for Plasma 6. Every window gets a translucent title bar, and KWin blurs what's behind it. The Aurorae Dockyard themes can't do this because Aurorae never sets a blur region.

- Title bar 34 px, title left-aligned, buttons on the right. Close sits flush in the top-right corner, fills the full title height and turns red on hover.
- Rounded top corners (10 px). They go square when the window is maximized or tiled against a screen edge.
- 1 px outline, 1 px top highlight and 1 px hairline under the title. Thin translucent side and bottom borders with invisible 4 px resize margins.
- Colours come from the window's colour scheme (`[WM]` colours and the Highlight accent), so Dockyard and Dockyard Day switch automatically.
- Blur covers the title bar and borders, and follows resize, maximize, tiling, shading and scale changes. The two-layer shadow has the window shape cut out, so it never shows through the glass.
- Supported buttons: Close, Maximize/Restore, Minimize, Keep above/below, On all desktops, Context help, Shade, Window menu (app icon), Application menu and Exclude from capture. The order follows your button layout (Window Decorations > Titlebar Buttons).
- Hover animation is 120 ms × `AnimationDurationFactor`. Tooltips, double-click to maximize, drag, right-click window menu, middle-click and wheel are all handled by KWin.

## Install

```sh
./install.sh              # user install: ~/.local/lib/qt6/plugins + env script
./install.sh --activate   # same, and selects it in kwinrc for the next login
```

KWin doesn't search `~/.local/lib/qt6/plugins` by default. `install.sh` writes `~/.config/plasma-workspace/env/dockyard-glass.sh`, which adds that folder to `QT_PLUGIN_PATH` before KWin starts. You must log out and back in once.

If you'd rather not change `QT_PLUGIN_PATH`, `./install-system.sh` copies the plugin into `/usr/lib/qt6/plugins/org.kde.kdecoration3` with sudo. A package update won't touch it.

## Enable

1. Save your work, then log out and back in.
2. Open System Settings > Colors & Themes > Window Decorations, select **Dockyard Glass** and click Apply.
3. Make sure the Blur desktop effect is on (System Settings > Desktop Effects > Blur).

If you used `--activate`, step 2 has already been done for you.

## Switch back

Select **Dockyard** (or **Dockyard Day**) in Window Decorations. Or from a terminal:

```sh
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__Dockyard
```

The terminal change takes effect at your next login. To uninstall, run `./install.sh --uninstall`, or `./install-system.sh --uninstall` if you installed system-wide.

## Settings

The settings live in `~/.config/dockyardglassrc` under `[General]`. KWin re-reads them whenever it reconfigures, for example when you click Apply in Window Decorations.

| Key | Default | Meaning |
| --- | --- | --- |
| TitleOpacityDark | 0.62 | Title bar alpha on a dark scheme |
| TitleOpacityLight | 0.70 | Title bar alpha on a light scheme |
| InactiveOpacityScale | 0.92 | Inactive windows are this much clearer |
| TitleHeight / ButtonWidth | 34 / 34 | Logical pixels |
| CornerRadius | 10 | Top corners; 0 = square |
| BlurBorders | true | Also blur the side and bottom borders |
| TitleHighlight / TitleHairline | true | 1 px top highlight / line under the title |
| ShadowSize / ShadowStrength | 32 / 1.0 | 0 turns the shadow off |
| HoverDuration | 120 | Milliseconds, before AnimationDurationFactor |

Setting either opacity to 1.0 makes the decoration opaque, and no blur is requested.

## Preview and tests

```sh
cmake -S . -B build -G Ninja -DCMAKE_MAKE_PROGRAM=/usr/bin/ninja && /usr/bin/ninja -C build
QT_QPA_PLATFORM=offscreen ./build/glass-harness build/plugins preview
```

The harness never touches KWin. It finds and loads the plugin the same way KWin does (`KPluginMetaData::findPlugins("org.kde.kdecoration3")` and then `KPluginFactory`), and drives it through a mock `DecorationBridge`. It checks borders, the blur region, opacity, shadow, button clicks, tooltips, maximize, resize, tiling and 1.5× scale. Then it writes `preview/*.png` over a fake wallpaper with the blur simulated.
