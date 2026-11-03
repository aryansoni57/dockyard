#!/bin/sh
# Prints the pinned launchers of the first Task Manager applet (icon-only or
# classic) found in the Plasma config, comma-separated, or nothing if none.
f="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"
[ -r "$f" ] || exit 0
awk '
/^\[/ { sec = $0; ing = (base != "" && sec == base "[Configuration][General]"); next }
/^plugin=org\.kde\.plasma\.(icontasks|taskmanager)$/ { base = sec }
ing && /^launchers=/ { sub(/^launchers=/, ""); print; exit }
' "$f"
