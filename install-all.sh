#!/usr/bin/env bash
# Install everything: plasmoid + glass desktop theme, then restart plasmashell.
# Usage: ./install-all.sh [--apply-theme] [--no-restart]
set -euo pipefail
cd "$(dirname "$0")"

apply=0
restart=1
for a in "$@"; do
    case "$a" in
        --apply-theme) apply=1 ;;
        --no-restart) restart=0 ;;
        *) echo "unknown option: $a" >&2; exit 1 ;;
    esac
done

./install.sh

themes="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/desktoptheme"
mkdir -p "$themes"
rm -rf "$themes/glass"
cp -r theme/glass "$themes/glass"
echo "Installed theme: $themes/glass"

if [ "$apply" = 1 ]; then
    plasma-apply-desktoptheme glass
fi

if [ "$restart" = 1 ]; then
    systemctl --user restart plasma-plasmashell
fi
