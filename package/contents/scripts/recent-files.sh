#!/bin/sh
# Prints the files an app opened most recently as "title<TAB>url" lines, newest
# first, from the activity manager's history, for the dock's Recent Files menu.
# $1 is a launcher url: "applications:id.desktop" or "file:///path/id.desktop".
id="${1##*/}"
id="${id#applications:}"
id="${id%.desktop}"
[ -n "$id" ] || exit 0
db="${XDG_DATA_HOME:-$HOME/.local/share}/kactivitymanagerd/resources/database"
[ -r "$db" ] || exit 0
command -v python3 >/dev/null || exit 0
python3 - "$db" "$id" <<'PY'
import os, sqlite3, sys, urllib.parse
db, agent = sys.argv[1], sys.argv[2]
try:
    con = sqlite3.connect("file:" + urllib.parse.quote(db) + "?mode=ro", uri=True, timeout=1)
    rows = con.execute(
        "SELECT e.targettedResource, MAX(e.start) AS t, i.title FROM ResourceEvent e"
        " LEFT JOIN ResourceInfo i ON i.targettedResource = e.targettedResource"
        " WHERE e.initiatingAgent = ? GROUP BY e.targettedResource ORDER BY t DESC LIMIT 40",
        (agent,)).fetchall()
except Exception:
    sys.exit(0)
n = 0
for res, _, title in rows:
    path = urllib.parse.unquote(res[7:]) if res.startswith("file://") else res
    if not path.startswith("/") or not os.path.exists(path):
        continue
    name = title or os.path.basename(path.rstrip("/")) or path
    print(name.replace("\t", " ") + "\t" + "file://" + urllib.parse.quote(path))
    n += 1
    if n == 10:
        break
PY
