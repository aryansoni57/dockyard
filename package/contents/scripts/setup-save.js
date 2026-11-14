// KWin script, loaded by setup-save.sh with __ID__ replaced by the dock's applet id.
// Records every normal window on the current desktop: its app, the monitor it is on and its
// place on that monitor (as fractions of the monitor, so a changed resolution still fits).
// The result goes to the dock through plasmashell's scripting API, into its `pendingSetup`
// setting, which the dock turns into a saved App Setup.
(function () {
    const outputs = workspace.screens.map(o => ({
        name: o.name,
        x: o.geometry.x, y: o.geometry.y, width: o.geometry.width, height: o.geometry.height
    }));
    const windows = [];
    for (const w of workspace.windowList()) {
        if (!w.normalWindow || w.minimized || w.skipTaskbar || !w.output)
            continue;
        if (!w.onAllDesktops && w.desktops.indexOf(workspace.currentDesktop) < 0)
            continue;
        const app = w.desktopFileName || w.resourceClass;
        if (!app)
            continue;
        const g = w.frameGeometry;
        const og = w.output.geometry;
        windows.push({
            app: String(app).replace(/\.desktop$/, ""),
            output: w.output.name,
            fx: (g.x - og.x) / og.width,
            fy: (g.y - og.y) / og.height,
            fw: g.width / og.width,
            fh: g.height / og.height
        });
    }
    const payload = JSON.stringify({ outputs: outputs, windows: windows });
    const script = "for (const c of panels().concat(desktops()))"
        + " for (const w of c.widgets('dev.aryan.dock'))"
        + " if (w.id == " + __ID__ + ") { w.currentConfigGroup = ['General'];"
        + " w.writeConfig('pendingSetup', " + JSON.stringify(payload) + "); }";
    callDBus("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", "evaluateScript", script);
})();
