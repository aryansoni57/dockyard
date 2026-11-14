#!/bin/sh
# Tile the windows of an App Setup with a KWin script that stays loaded to catch apps
# that are still starting. It places each window once and never moves it again.
# Usage: setup-tile.sh '<json>'  with {"apps": ["org.kde.dolphin", ...], "layout": "side|grid|main"}
#        setup-tile.sh --stop    unload the script (the dock does this after a while)
if [ "$1" = "--stop" ]; then
    qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript dockyardsetup >/dev/null 2>&1
    exit 0
fi
[ -n "$1" ] || exit 1
command -v qdbus6 >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1 || exit 1
here=$(dirname "$0")
out="${XDG_RUNTIME_DIR:-/tmp}/dockyard-setup-tile.js"
python3 - "$here/setup-tile.js" "$out" "$1" <<'PY'
import json, sys
tpl, out, cfg = sys.argv[1:4]
json.loads(cfg)  # refuse anything that is not JSON
open(out, "w", encoding="utf-8").write(open(tpl, encoding="utf-8").read().replace("__CFG__", cfg))
PY
[ $? -eq 0 ] || exit 1
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript dockyardsetup >/dev/null 2>&1
id=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$out" dockyardsetup)
[ -n "$id" ] || exit 1
qdbus6 org.kde.KWin "/Scripting/Script$id" org.kde.kwin.Script.run >/dev/null 2>&1
exit 0
