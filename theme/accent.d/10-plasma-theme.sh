#!/bin/sh
# Plasma desktop themes (glass*, including the opaque and islands variants layout-theme.sh made):
# focus, hover and active colours, and the selection colour.
d="$(cd "$(dirname "$0")" && pwd)"
python3 "$d/../../settings/apply-accent.py" "$ACCENT"
dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0
