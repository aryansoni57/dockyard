// Run by dockyard-settings through KWin scripting: bring the open Dockyard Settings window to the front.
// KWin does not honor a focus request from a background window, but its own scripts can.
for (const w of workspace.windowList()) {
    if (w.caption === "Dockyard Settings") {
        w.minimized = false;
        workspace.activeWindow = w;
    }
}
