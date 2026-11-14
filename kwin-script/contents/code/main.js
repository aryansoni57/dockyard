// Meta+1..9 for the Dockyard plasmoid (dev.aryan.dock).
// Plasma 6.8 gives these keys only to the stock Task Manager, and QML cannot
// register global shortcuts. So this script owns them and passes each press on
// through plasmashell's scripting API: it writes "<index>:<time>" to the dock's
// taskShortcut setting, which the dock watches. The time makes each press a change.

function notifyDock(index) {
    // With a dock on each monitor, write to one dock only: the dock on the screen where the
    // focused window is, else the first dock found. Otherwise every dock would act on the
    // press, and the second one would toggle the window back (minimise it again).
    const g = workspace.activeScreen ? workspace.activeScreen.geometry : null;
    const cx = g ? Math.round(g.x + g.width / 2) : 0;
    const cy = g ? Math.round(g.y + g.height / 2) : 0;
    const script = "var hit = null, first = null;"
        + " for (const c of panels().concat(desktops()))"
        + " for (const w of c.widgets('dev.aryan.dock')) {"
        + " if (!first) first = w;"
        + " const r = screenGeometry(c.screen);"
        + " if (!hit && r.x <= " + cx + " && " + cx + " < r.x + r.width && r.y <= " + cy + " && " + cy + " < r.y + r.height) hit = w; }"
        + " const target = hit || first;"
        + " if (target) { target.currentConfigGroup = ['General'];"
        + " target.writeConfig('taskShortcut', '" + index + ":' + Date.now()); }";
    callDBus("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", "evaluateScript", script);
}

for (let n = 1; n <= 9; ++n) {
    registerShortcut("Dockyard App " + n, "Dockyard: Activate App " + n, "Meta+" + n, () => notifyDock(n - 1));
}
