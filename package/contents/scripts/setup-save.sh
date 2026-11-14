#!/bin/sh
# Capture where every window is, per monitor, for a new App Setup.
# Usage: setup-save.sh <applet id of the dock>
# A KWin script reads the windows and hands them to the dock's `pendingSetup` setting.
case "$1" in ''|*[!0-9]*) exit 1 ;; esac
command -v qdbus6 >/dev/null 2>&1 || exit 1
here=$(dirname "$0")
out="${XDG_RUNTIME_DIR:-/tmp}/dockyard-setup-save.js"
sed "s/__ID__/$1/" "$here/setup-save.js" > "$out" || exit 1
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript dockyardsave >/dev/null 2>&1
id=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$out" dockyardsave)
[ -n "$id" ] || exit 1
qdbus6 org.kde.KWin "/Scripting/Script$id" org.kde.kwin.Script.run >/dev/null 2>&1
sleep 1
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript dockyardsave >/dev/null 2>&1
exit 0
