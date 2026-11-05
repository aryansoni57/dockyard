#!/bin/sh
# Prints the [Desktop Action] entries of an app's .desktop file as
# "name<TAB>icon<TAB>exec" lines, for the dock's right-click menu.
# $1 is a launcher url: "applications:id.desktop" or "file:///path/id.desktop".
case "$1" in
    applications:*) id="${1#applications:}" ;;
    file://*) f="${1#file://}" ;;
    *) exit 0 ;;
esac
if [ -z "$f" ]; then
    for d in "${XDG_DATA_HOME:-$HOME/.local/share}" $(echo "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" | tr : ' '); do
        if [ -f "$d/applications/$id" ]; then f="$d/applications/$id"; break; fi
    done
fi
[ -r "$f" ] || exit 0
awk '
/^\[Desktop Action / { inact = 1; n = $0; sub(/^\[Desktop Action /, "", n); sub(/\]$/, "", n); order[++cnt] = n; next }
/^\[/ { inact = 0 }
inact && /^Name=/ { sub(/^Name=/, ""); name[n] = $0 }
inact && /^Icon=/ { sub(/^Icon=/, ""); icon[n] = $0 }
inact && /^Exec=/ { sub(/^Exec=/, ""); ex[n] = $0 }
END { for (i = 1; i <= cnt; i++) { k = order[i]; if (name[k] != "" && ex[k] != "") printf "%s\t%s\t%s\n", name[k], icon[k], ex[k] } }
' "$f"
