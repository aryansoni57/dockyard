#!/bin/sh
# Prints "epoch<TAB>path" for the files used most recently by any app, newest first,
# from the activity manager's history (the same database recent-files.sh reads).
# The launcher uses it to say how long ago each recent file was used.
db="${XDG_DATA_HOME:-$HOME/.local/share}/kactivitymanagerd/resources/database"
[ -r "$db" ] || exit 0
command -v python3 >/dev/null || exit 0
python3 - "$db" <<'PY'
import os, sqlite3, sys, urllib.parse
try:
    con = sqlite3.connect("file:" + urllib.parse.quote(sys.argv[1]) + "?mode=ro", uri=True, timeout=1)
    rows = con.execute(
        "SELECT targettedResource, MAX(end) AS t, MAX(start) AS s FROM ResourceEvent"
        " GROUP BY targettedResource ORDER BY s DESC LIMIT 60").fetchall()
except Exception:
    sys.exit(0)
for res, end, start in rows:
    path = urllib.parse.unquote(res[7:]) if res.startswith("file://") else res
    if not path.startswith("/") or not os.path.exists(path):
        continue
    print("%d\t%s" % (max(start or 0, end or 0), path))
PY
