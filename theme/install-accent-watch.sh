#!/usr/bin/env bash
# Install the user units that run apply-accent-all.sh when the system accent changes
# (System Settings, the Dockyard Settings picker, or plasma-apply-colorscheme --accent-color).
# Usage: theme/install-accent-watch.sh [off]
set -euo pipefail
d="$(cd "$(dirname "$0")" && pwd)"
units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
if [ "${1:-on}" = off ]; then
    systemctl --user disable --now dockyard-accent.path 2>/dev/null || true
    rm -f "$units/dockyard-accent.path" "$units/dockyard-accent.service"
    systemctl --user daemon-reload
    echo "Accent watcher removed."
    exit 0
fi
mkdir -p "$units"
cp "$d/systemd/dockyard-accent.path" "$units/"
sed "s|@DIR@|$d|" "$d/systemd/dockyard-accent.service" > "$units/dockyard-accent.service"
systemctl --user daemon-reload
systemctl --user enable --now dockyard-accent.path
echo "Accent watcher on: Dockyard re-colours itself when the system accent changes. Undo: $d/install-accent-watch.sh off"
