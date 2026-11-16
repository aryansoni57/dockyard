#!/bin/sh
# Notification and dialog popups (Glass Notify): the hairline rim around the glass takes the accent.
d="$(cd "$(dirname "$0")/../glass-notify" && pwd)"
dst="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/desktoptheme/glass-notify"
[ -d "$dst" ] || exit 0
for f in dialogs/background.svg translucent/dialogs/background.svg; do
    [ -f "$d/$f" ] || continue
    # Always from the repo copy, so a new accent replaces the old one and the default stays recoverable.
    sed "s|stroke=\"#ffffff\" stroke-opacity=\"0.14\"|stroke=\"$ACCENT\" stroke-opacity=\"0.55\"|g" "$d/$f" > "$dst/$f"
done
