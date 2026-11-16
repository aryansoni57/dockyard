#!/bin/sh
# Clear the Dockyard dock's own accent color so it follows the system accent again.
# Writes through plasmashell, which owns the applet config while it runs.
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
function clear(list) {
    for (var i = 0; i < list.length; ++i) {
        var ws = list[i].widgets();
        for (var j = 0; j < ws.length; ++j) {
            if (ws[j].type === "dev.aryan.dock") {
                ws[j].currentConfigGroup = ["General"];
                ws[j].writeConfig("accentColor", "");
            }
        }
    }
}
clear(panels());
clear(desktops());
' >/dev/null 2>&1
exit 0
