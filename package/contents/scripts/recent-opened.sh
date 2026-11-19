#!/bin/sh
# Prints the files and folders opened most recently by any app as "title<TAB>url"
# lines, newest first, from the activity manager's history. $1 is how many (default 3).
n="${1:-3}"
db="${XDG_DATA_HOME:-$HOME/.local/share}/kactivitymanagerd/resources/database"
[ -r "$db" ] || exit 0
command -v python3 >/dev/null || exit 0
python3 - "$db" "$n" <<'PY'
import os, sqlite3, sys, urllib.parse
db, limit = sys.argv[1], int(sys.argv[2])
try:
    con = sqlite3.connect("file:" + urllib.parse.quote(db) + "?mode=ro", uri=True, timeout=1)
    rows = con.execute(
        "SELECT e.targettedResource, MAX(e.start) AS t, i.title FROM ResourceEvent e"
        " LEFT JOIN ResourceInfo i ON i.targettedResource = e.targettedResource"
        " GROUP BY e.targettedResource ORDER BY t DESC LIMIT 60").fetchall()
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
    if n >= limit:
        break
PY
