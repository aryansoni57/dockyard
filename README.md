# plasma-dock
Plasma 6 plasmoid: a smart dock that runs inside `plasmashell`.

Modules: clock, CPU/memory stats, now playing (MPRIS). Click the dock to open the detail popup.

## Layout

```
package/
  metadata.json            plugin id dev.aryan.dock
  contents/config/main.xml config keys
  contents/ui/main.qml     shared data sources + compact/full views
  contents/ui/modules/     one dumb view per module
```

Data sources (sensors, MPRIS, clock) live once in `main.qml` and feed every module.
Add a module: new file in `modules/`, a `show<Name>` key in `main.xml`, a checkbox in `configGeneral.qml`.

## Run

Test without installing:

```bash
plasmoidviewer -a package
```

Install, then add "Dock" to a panel via Add Widgets:

```bash
./install.sh
```

## Notes

- `org.kde.plasma.private.mpris` is a private Plasma API. It can change between Plasma releases.
- Hidden modules stop their sensors and timers, so they cost nothing.
