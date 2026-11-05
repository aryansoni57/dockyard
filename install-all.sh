#!/usr/bin/env bash
# Install everything: plasmoid + glass desktop themes (frosted and opaque), then restart plasmashell.
# Usage: ./install-all.sh [--apply-theme] [--apply-global] [--no-restart]
#   --apply-theme   activate the Plasma desktop theme glass
#   --apply-global  install and activate the Dockyard set: Kvantum, color scheme, Aurorae
#                   and look-and-feel. Saves your current choices first (see theme/install-global.sh).
set -euo pipefail
cd "$(dirname "$0")"

apply=0
global=0
restart=1
for a in "$@"; do
    case "$a" in
        --apply-theme) apply=1 ;;
        --apply-global) global=1 ;;
        --no-restart) restart=0 ;;
        *) echo "unknown option: $a" >&2; exit 1 ;;
    esac
done

./install.sh

themes="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/desktoptheme"
mkdir -p "$themes"
for t in glass glass-opaque; do
    rm -rf "$themes/$t"
    cp -r "theme/$t" "$themes/$t"
    echo "Installed theme: $themes/$t"
done

if [ "$apply" = 1 ]; then
    plasma-apply-desktoptheme glass
fi

if [ "$global" = 1 ]; then
    theme/install-global.sh
fi

if [ "$restart" = 1 ]; then
    systemctl --user restart plasma-plasmashell
fi
