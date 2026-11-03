// Meta+1..9 for the Dockyard plasmoid (dev.aryan.dock).
// Plasma 6.8 gives these keys only to the stock Task Manager, and QML cannot
// register global shortcuts. So this script owns them and passes each press on
// through plasmashell's scripting API: it writes "<index>:<time>" to the dock's
// taskShortcut setting, which the dock watches. The time makes each press a change.

function notifyDock(index) {
    const script = "for (const c of panels().concat(desktops()))"
        + " for (const w of c.widgets('dev.aryan.dock')) {"
        + " w.currentConfigGroup = ['General'];"
        + " w.writeConfig('taskShortcut', '" + index + ":' + Date.now()); }";
    callDBus("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", "evaluateScript", script);
}

for (let n = 1; n <= 9; ++n) {
    registerShortcut("Dockyard App " + n, "Dockyard: Activate App " + n, "Meta+" + n, () => notifyDock(n - 1));
}
