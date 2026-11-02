#!/usr/bin/env bash
# Install or upgrade the plasmoid for the current user.
set -euo pipefail
cd "$(dirname "$0")"

if kpackagetool6 -t Plasma/Applet -s dev.aryan.dock >/dev/null 2>&1; then
    kpackagetool6 -t Plasma/Applet -u package
else
    kpackagetool6 -t Plasma/Applet -i package
fi

echo "Installed. Restart plasmashell to reload: systemctl --user restart plasma-plasmashell"
