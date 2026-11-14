// KWin script, loaded by setup-tile.sh with __CFG__ replaced by JSON:
//   {"apps": ["org.kde.dolphin", ...], "layout": "side" | "grid" | "main" | "saved", "gap": 8,
//    "screen": {"x": 0, "y": 0, "width": 1920, "height": 1080},
//    "windows": [{"app", "output", "fx", "fy", "fw", "fh"}, ...]}   (layout "saved" only)
// A "saved" setup puts each window back on the monitor it was on, at the same place there.
// Finds the first window of each app (by desktop file name or window class), moves it to the
// current desktop, and tiles them across the work area of the screen the dock is on (setting
// a window's geometry inside that area also moves it to that screen). `screen` is the dock's
// screen geometry; without it the active screen is used. Apps with no window yet are skipped; setup-tile.sh runs this again a few times while they start.
(function () {
    const cfg = __CFG__;
    const norm = s => String(s || "").toLowerCase().replace(/\.desktop$/, "");
    const saved = cfg.layout === "saved" && Array.isArray(cfg.windows) && cfg.windows.length > 0 ? cfg.windows : null;
    const ids = saved ? saved.map(e => norm(e.app)) : cfg.apps.map(norm);
    const n = ids.length;
    const gap = cfg.gap || 8;
    const placed = [];   // windows already tiled: each is placed once, then left alone
    const taken = [];    // taken[k] is the window in app k's slot

    // The screen the dock is on, found by the centre of its geometry. With two monitors the
    // active screen can be the other one, so a setup would otherwise land away from the dock.
    function targetOutput() {
        if (cfg.screen) {
            const cx = cfg.screen.x + cfg.screen.width / 2;
            const cy = cfg.screen.y + cfg.screen.height / 2;
            const hit = workspace.screens.find(o => cx >= o.geometry.x && cx < o.geometry.x + o.geometry.width
                && cy >= o.geometry.y && cy < o.geometry.y + o.geometry.height);
            if (hit)
                return hit;
        }
        return workspace.activeScreen;
    }

    // Slot i belongs to app i whatever order the windows appear in, so a late window
    // takes its own place and never shifts the ones already there.
    function slot(i) {
        if (saved) {
            // Back on the same monitor (by name), at the same fractions of it. A monitor that
            // is gone falls back to the dock's own.
            const e = saved[i];
            const out = workspace.screens.find(o => o.name === e.output) || targetOutput();
            const og = out.geometry;
            return { x: Math.round(og.x + e.fx * og.width), y: Math.round(og.y + e.fy * og.height),
                     width: Math.round(e.fw * og.width), height: Math.round(e.fh * og.height) };
        }
        const area = workspace.clientArea(KWin.PlacementArea, targetOutput(), workspace.currentDesktop);
        const X = area.x + gap, Y = area.y + gap, W = area.width - gap * 2, H = area.height - gap * 2;
        const r = (x, y, w, h) => ({ x: Math.round(x), y: Math.round(y), width: Math.round(w), height: Math.round(h) });
        if (n === 1)
            return r(X, Y, W, H);
        if (cfg.layout === "grid") {
            const cols = n <= 4 ? 2 : 3;
            const rows = Math.ceil(n / cols);
            const cw = (W - gap * (cols - 1)) / cols;
            const ch = (H - gap * (rows - 1)) / rows;
            return r(X + (i % cols) * (cw + gap), Y + Math.floor(i / cols) * (ch + gap), cw, ch);
        }
        if (cfg.layout === "main") {
            // The first app takes the left 60%, the rest stack on the right.
            const mw = (W - gap) * 0.6;
            if (i === 0)
                return r(X, Y, mw, H);
            const rest = n - 1;
            const rh = (H - gap * (rest - 1)) / rest;
            return r(X + mw + gap, Y + (i - 1) * (rh + gap), W - mw - gap, rh);
        }
        const cw = (W - gap * (n - 1)) / n;
        return r(X + i * (cw + gap), Y, cw, H);
    }

    // Tiles a window if it is the first one found for one of the apps. Returns true if it did.
    function place(w) {
        if (!w.normalWindow || placed.indexOf(w) >= 0)
            return false;
        const names = [w.desktopFileName, w.resourceClass, w.resourceName].map(norm);
        // The first app (in order) with this name whose slot is still free.
        const i = ids.findIndex((id, k) => names.indexOf(id) >= 0 && !taken[k]);
        if (i < 0)
            return false;
        w.minimized = false;
        w.fullScreen = false;
        w.setMaximize(false, false);
        w.desktops = [workspace.currentDesktop];
        w.frameGeometry = slot(i);
        if (workspace.raiseWindow)
            workspace.raiseWindow(w);
        taken[i] = w;
        placed.push(w);
        return true;
    }

    // Windows that exist now, then every one that opens until the dock unloads this script.
    // Once a window is placed it is never touched again, so moving it sticks.
    for (const w of workspace.windowList())
        place(w);
    workspace.windowAdded.connect(place);
})();
